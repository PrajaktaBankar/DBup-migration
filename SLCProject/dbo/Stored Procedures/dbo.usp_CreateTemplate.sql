CREATE PROCEDURE [dbo].[usp_CreateTemplate]  
(  
 @templateJson nvarchar(max)  
)  
AS  
BEGIN
 DECLARE @PtemplateJson nvarchar(max) = @templateJson; 
 declare @CreatedBy INT,  
 @CustomerId INT,  
 @SequenceNumbering BIT,  
 @TitleFormatId INT,  
 @MasterDataTypeId INT,
 @ApplyTitleStyleToEOS BIT
  
  
 --DECLARE @templateStyle TABLE (  
 --[TemplateStyleId] [int] ,  
 --[TemplateId] [int] ,  
 --[StyleId] [int] ,  
 --[Level] [tinyint] ,  
 --[CustomerId] [int]   
                                                                                                                                                               
 --)  
  
 declare @styleJson nvarchar(max)
  
  
 CREATE Table #StyleTbl(  
    RowId INT,  
    Alignment TINYINT,  
 IsBold BIT,  
    CharAfterNumber int ,  
 CharBeforeNumber int ,  
 FontName nvarchar(max) ,  
 FontSize int ,  
 HangingIndent int ,  
 IncludePrevious bit ,  
 IsItalic bit ,  
 LeftIndent int ,  
 NumberFormat int ,  
 NumberPosition int ,  
 PrintUpperCase bit ,  
 ShowNumber bit ,  
 StartAt tinyint ,  
 Strikeout bit ,  
 Name nvarchar(max) ,  
 TopDistance int ,  
 Underline bit ,  
 SpaceBelowParagraph int ,  
 IsSystem bit ,  
 CustomerId int ,  
 IsDeleted bit ,  
 CreatedBy int ,  
 CreateDate datetime2(7) ,  
 ModifiedBy int ,  
 ModifiedDate datetime2(7) ,  
 Level int ,  
 MasterDataTypeId int  
 );
  
 CREATE TABLE #template(  
 [TemplateId] [int],  
 [Name] [nvarchar](1024),  
 [TitleFormatId] [int],  
 [SequenceNumbering] [bit],  
 [CustomerId] [int],  
 [MasterDataTypeId] [int],  
 createdBy int ,  
 TemplateStyle [nvarchar](max),
 ApplyTitleStyleToEOS BIT
 )

INSERT INTO #template ([Name], CustomerId, TitleFormatId, TemplateId, [MasterDataTypeId], [SequenceNumbering], CreatedBy,
TemplateStyle, ApplyTitleStyleToEOS)
	SELECT
		*
	FROM OPENJSON(@PtemplateJson)
	WITH (
	[Name] [NVARCHAR](1024) '$.Name',
	CustomerId INT '$.CustomerId',
	TitleFormatId INT '$.TitleFormatId',
	TemplateId INT '$.TemplateId',
	[MasterDataTypeId] INT '$.MasterDataTypeId',
	SequenceNumbering BIT '$.SequenceNumbering',
	CreatedBy INT '$.CreatedBy',
	TemplateStyle NVARCHAR(MAX) AS JSON,
	ApplyTitleStyleToEOS BIT '$.ApplyTitleStyleToEOS'
	)

--get Style json   
SELECT
	@MasterDataTypeId = MasterDataTypeId
   ,@CreatedBy = CreatedBy
   ,@CustomerId = CustomerId
   ,@styleJson = TemplateStyle
   ,@ApplyTitleStyleToEOS=ApplyTitleStyleToEOS
FROM #template

INSERT INTO #StyleTbl (RowId, Alignment, IsBold, CharAfterNumber, CharBeforeNumber, FontName, FontSize, HangingIndent, IncludePrevious,
IsItalic, LeftIndent, NumberFormat, NumberPosition, PrintUpperCase, ShowNumber, StartAt, Strikeout, Name, TopDistance, Underline, SpaceBelowParagraph,
IsSystem, CustomerId, IsDeleted, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, Level, MasterDataTypeId)
	SELECT
		ROW_NUMBER() OVER (ORDER BY Level) AS RowId
	   ,*
	FROM OPENJSON(@styleJson)
	WITH (
	Alignment TINYINT '$.Style.Alignment',
	IsBold BIT '$.Style.IsBold',
	CharAfterNumber INT '$.Style.CharAfterNumber',
	CharBeforeNumber INT '$.Style.CharBeforeNumber',
	FontName NVARCHAR(MAX) '$.Style.FontName',
	FontSize INT '$.Style.FontSize',
	HangingIndent INT '$.Style.HangingIndent',
	IncludePrevious BIT '$.Style.IncludePrevious',
	IsItalic BIT '$.Style.IsItalic',
	LeftIndent INT '$.Style.LeftIndent',
	NumberFormat INT '$.Style.NumberFormat',
	NumberPosition INT '$.Style.NumberPosition',
	PrintUpperCase BIT '$.Style.PrintUpperCase',
	ShowNumber BIT '$.Style.ShowNumber',
	StartAt TINYINT '$.Style.StartAt',
	Strikeout BIT '$.Style.Strikeout',
	Name NVARCHAR(MAX) '$.Style.Name',
	TopDistance INT '$.Style.TopDistance',
	Underline BIT '$.Style.Underline',
	SpaceBelowParagraph INT '$.Style.SpaceBelowParagraph',
	IsSystem BIT '$.Style.IsSystem',
	CustomerId INT '$.Style.CustomerId',
	IsDeleted BIT '$.Style.IsDeleted',
	CreatedBy INT '$.Style.CreatedBy',
	CreateDate DATETIME2(7) '$.Style.CreateDate',
	ModifiedBy INT '$.Style.ModifiedBy',
	ModifiedDate DATETIME2(7) '$.Style.ModifiedDate',
	Level INT '$.Level',
	MasterDataTypeId INT '$.MasterDataTypeId'
	)

--select * from #StyleTbl  


---insert into template  
INSERT INTO Template (CreateDate, CreatedBy, IsDeleted, IsSystem, CustomerId,
Name, SequenceNumbering, TitleFormatId, MasterDataTypeId,ApplyTitleStyleToEOS)
	SELECT
		GETUTCDATE()
	   ,CreatedBy
	   ,0
	   ,0
	   ,CustomerId
	   ,Name
	   ,ISNULL(SequenceNumbering, 0)
	   ,TitleFormatId
	   ,MasterDataTypeId
	   ,ApplyTitleStyleToEOS
	FROM #template

UPDATE #template
SET TemplateId = SCOPE_IDENTITY();

--select * from #template  

---insert into style loop{insert into templateStyle}  
DECLARE @counter INT = 1;
DECLARE @styleId INT = 1;
DECLARE @StyleTblRowCount INT=(SELECT
		COUNT(1)
	FROM #StyleTbl)

WHILE @counter <= @StyleTblRowCount
BEGIN
INSERT INTO Style (Alignment, IsBold, CharAfterNumber, CharBeforeNumber, FontName, FontSize, HangingIndent, IncludePrevious,
IsItalic, LeftIndent, NumberFormat, NumberPosition, PrintUpperCase, ShowNumber, StartAt, Strikeout, Name, TopDistance, Underline, SpaceBelowParagraph,
IsSystem, CustomerId, IsDeleted, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, Level, MasterDataTypeId)
	SELECT
		Alignment
	   ,IsBold
	   ,CharAfterNumber
	   ,CharBeforeNumber
	   ,FontName
	   ,FontSize
	   ,HangingIndent
	   ,IncludePrevious
	   ,ISNULL(IsItalic, 0)
	   ,LeftIndent
	   ,NumberFormat
	   ,ISNULL(NumberPosition, 0)
	   ,PrintUpperCase
	   ,ShowNumber
	   ,ISNULL(StartAt, 0)
	   ,ISNULL(Strikeout, 0)
	   ,TRIM(Name)
	   ,TopDistance
	   ,ISNULL(Underline, 0)
	   ,SpaceBelowParagraph
	   ,ISNULL(IsSystem, 0)
	   ,@CustomerId
	   ,ISNULL(IsDeleted, 0)
	   ,@CreatedBy
	   ,GETUTCDATE()
	   ,ModifiedBy
	   ,ModifiedDate
	   ,Level
	   ,ISNULL(MasterDataTypeId, 1)
	FROM #StyleTbl
	WHERE RowId = @counter;

SET @styleId = SCOPE_IDENTITY();

--insert into templatestyle  
INSERT INTO TemplateStyle (StyleId, TemplateId, Level, CustomerId)
	SELECT
		@styleId
	   ,TemplateId
	   ,(SELECT
				Level
			FROM #StyleTbl
			WHERE RowId = @counter)
		AS Level
	   ,CustomerId
	FROM #template

SET @counter = @counter + 1;
  
  END;

--usp_UpdatestyleParagraphLineSpace  

--select * from template,templateStyle,style  
SELECT
	tm.TemplateId
   ,tm.Name
   ,tm.TitleFormatId
   ,tm.SequenceNumbering
   ,tm.CustomerId
   ,tm.IsSystem
   ,tm.IsDeleted
   ,tm.MasterDataTypeId
   ,tm.CreatedBy
   ,tm.CreateDate
   ,tm.ModifiedBy
   ,tm.ModifiedDate
   ,tm.ApplyTitleStyleToEOS
FROM Template tm WITH (NOLOCK)
INNER JOIN #template t
ON tm.TemplateId=t.TemplateId

SELECT

	ts.TemplateStyleId
   ,ts.TemplateId
   ,ts.StyleId AS ts_StyleId
   ,ts.Level AS ts_Level
   ,ts.CustomerId
   ,st.StyleId
   ,st.Alignment
   ,st.IsBold
   ,st.CharAfterNumber
   ,st.CharBeforeNumber
   ,st.FontName
   ,st.FontSize
   ,st.HangingIndent
   ,st.IncludePrevious
   ,st.IsItalic
   ,st.LeftIndent
   ,st.NumberFormat
   ,st.NumberPosition
   ,st.PrintUpperCase
   ,st.ShowNumber
   ,st.StartAt
   ,st.Strikeout
   ,st.Name
   ,st.TopDistance
   ,st.Underline
   ,st.SpaceBelowParagraph
   ,st.IsSystem
   ,st.CustomerId
   ,st.IsDeleted
   ,st.CreatedBy
   ,st.CreateDate
   ,st.ModifiedBy
   ,st.ModifiedDate
   ,st.Level
   ,st.MasterDataTypeId

FROM TemplateStyle ts WITH (NOLOCK)
INNER JOIN Style st WITH (NOLOCK)
	ON ts.StyleId = st.StyleId
INNER JOIN #template t
ON ts.TemplateId=t.TemplateId

END;
GO