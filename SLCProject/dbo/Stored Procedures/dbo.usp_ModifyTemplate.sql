CREATE PROCEDURE [dbo].[usp_ModifyTemplate]  
@TemplateId INT,  
@CustomerId INT,  
@Name varchar(max),  
@ModifiedBy INT,  
@StyleListJson nvarchar(max),
@ApplyTitleStyleToEOS BIT  
AS  
BEGIN
  
DECLARE @PTemplateId INT = @TemplateId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PName varchar(max) = @Name;
DECLARE @PModifiedBy INT = @ModifiedBy;
DECLARE @PStyleListJson nvarchar(max) = @StyleListJson;
DECLARE @PApplyTitleStyleToEOS BIT=@ApplyTitleStyleToEOS

UPDATE T
SET T.Name = @PName
   ,T.ModifiedBy = @PModifiedBy
   ,T.ModifiedDate = GETUTCDATE()
   ,ApplyTitleStyleToEOS=@PApplyTitleStyleToEOS
FROM Template T WITH (NOLOCK)
WHERE T.TemplateId = @PTemplateId
AND T.CustomerId = @PCustomerId

DECLARE @StyleTbl TABLE (
	StyleId INT
   ,Alignment TINYINT
   ,IncludePrevious BIT
   ,CharAfterNumber INT
   ,CharBeforeNumber INT
   ,FontName NVARCHAR(MAX)
   ,FontSize INT
   ,HangingIndent INT
   ,IsDeleted BIT
   ,IsBold BIT
   ,IsItalic BIT
   ,LeftIndent INT
   ,Name NVARCHAR(MAX)
   ,NumberFormat INT
   ,NumberPosition INT
   ,PrintUpperCase BIT
   ,ShowNumber BIT
   ,SpaceBelowParagraph INT
   ,StartAt TINYINT
   ,Strikeout BIT
   ,TopDistance INT
   ,Underline BIT
   ,ModifiedBy INT
   ,ModifiedDate DATETIME2(7)
);

--CONVERT STRING JSONS INTO TABLE  
IF @PStyleListJson != ''
BEGIN
INSERT INTO @StyleTbl (StyleId, Alignment, IncludePrevious, CharAfterNumber, CharBeforeNumber, FontName, FontSize, HangingIndent,
IsDeleted, IsBold, IsItalic, LeftIndent, Name, NumberFormat, NumberPosition, PrintUpperCase, ShowNumber, SpaceBelowParagraph,
StartAt, Strikeout, TopDistance, Underline, ModifiedBy, ModifiedDate)
	SELECT
		StyleId
	   ,Alignment
	   ,IncludePrevious
	   ,CharAfterNumber
	   ,CharBeforeNumber
	   ,FontName
	   ,FontSize
	   ,HangingIndent
	   ,IsDeleted
	   ,IsBold
	   ,IsItalic
	   ,LeftIndent
	   ,Name
	   ,NumberFormat
	   ,NumberPosition
	   ,PrintUpperCase
	   ,ShowNumber
	   ,SpaceBelowParagraph
	   ,StartAt
	   ,Strikeout
	   ,TopDistance
	   ,Underline
	   ,ModifiedBy
	   ,ModifiedDate
	FROM OPENJSON(@PStyleListJson)
	WITH
	(
	StyleId INT '$.StyleId',
	Alignment TINYINT '$.Alignment',
	IncludePrevious BIT '$.IncludePrevious',
	CharAfterNumber INT '$.CharAfterNumber',
	CharBeforeNumber INT '$.CharBeforeNumber',
	FontName NVARCHAR(MAX) '$.FontName',
	FontSize INT '$.FontSize',
	HangingIndent INT '$.HangingIndent',
	IsDeleted BIT '$.IsDeleted',
	IsBold BIT '$.IsBold',
	IsItalic BIT '$.IsItalic',
	LeftIndent INT '$.LeftIndent',
	Name NVARCHAR(MAX) '$.Name',
	NumberFormat INT '$.NumberFormat',
	NumberPosition INT '$.NumberPosition',
	PrintUpperCase BIT '$.PrintUpperCase',
	ShowNumber BIT '$.ShowNumber',
	SpaceBelowParagraph INT '$.SpaceBelowParagraph',
	StartAt TINYINT '$.StartAt',
	Strikeout BIT '$.Strikeout',
	TopDistance INT '$.TopDistance',
	Underline BIT '$.Underline',
	ModifiedBy INT '$.ModifiedBy',
	ModifiedDate DATETIME2(7) '$.ModifiedDate'
	)
END;

--now update style table  

--select *  From @StyleTbl   

UPDATE st
SET st.Alignment = temp_st.Alignment
   ,st.IncludePrevious = temp_st.IncludePrevious
   ,st.CharAfterNumber = temp_st.CharAfterNumber
   ,st.CharBeforeNumber = temp_st.CharBeforeNumber
   ,st.FontName = temp_st.FontName
   ,st.FontSize = temp_st.FontSize
   ,st.HangingIndent = temp_st.HangingIndent
   ,st.IsDeleted = temp_st.IsDeleted
   ,st.IsBold = temp_st.IsBold
   ,st.IsItalic = temp_st.IsItalic
   ,st.LeftIndent = temp_st.LeftIndent
   ,st.Name = temp_st.Name
   ,st.NumberFormat = temp_st.NumberFormat
   ,st.NumberPosition = temp_st.NumberPosition
   ,st.PrintUpperCase = temp_st.PrintUpperCase
   ,st.ShowNumber = temp_st.ShowNumber
   ,st.SpaceBelowParagraph = temp_st.SpaceBelowParagraph
   ,st.StartAt = temp_st.StartAt
   ,st.Strikeout = temp_st.Strikeout
   ,st.TopDistance = temp_st.TopDistance
   ,st.Underline = temp_st.Underline
   ,st.ModifiedBy = temp_st.ModifiedBy
   ,st.ModifiedDate = GETUTCDATE()
FROM @StyleTbl temp_st
INNER JOIN Style st WITH (NOLOCK)
	ON st.StyleId = temp_st.StyleId;

END;
GO
