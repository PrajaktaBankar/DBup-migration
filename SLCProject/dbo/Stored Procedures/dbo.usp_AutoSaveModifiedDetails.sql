
CREATE PROCEDURE [dbo].[usp_AutoSaveModifiedDetails]  
(@InpSegmentEditedJson NVARCHAR(MAX))      
AS             
BEGIN
DECLARE @PInpSegmentEditedJson NVARCHAR(MAX) = @InpSegmentEditedJson;
BEGIN TRY
DECLARE @LoopCount INT = 1;
SELECT
	@PInpSegmentEditedJson = REPLACE(@PInpSegmentEditedJson, '`', '''');
	CREATE TABLE #TempInpSegmentEditedJson (
		RowId INT NULL
	   ,ProjectId INT NULL
	   ,SectionId INT NULL
	   ,CustomerId INT NULL
	   ,SegmentStatusId BIGINT NULL
	   ,UserId INT NULL
	   ,SegmentDescription NVARCHAR(MAX) NULL
	   ,BaseSegmentDescription NVARCHAR(MAX) NULL
	   ,SegmentAction NVARCHAR(10) NULL
	   ,SegmentId BIGINT NULL
	   ,SegmentSource CHAR(1) NULL
	   ,SegmentOrigin CHAR(1) NULL
	   ,ParentSegmentStatusId BIGINT NULL
	   ,IndentLevel INT NULL
	   ,IsShowAutoNumber BIT NULL
	   ,FormattingJson NVARCHAR(MAX) NULL
	   ,IsPageBreak BIT NULL
	   ,ChoiceListJson NVARCHAR(MAX) NULL
	   ,SpecTypeTagId INT NULL
	   --,ToggleOrigin NVARCHAR(10) NULL
	);

INSERT INTO #TempInpSegmentEditedJson
	SELECT
		*
	FROM OPENJSON(@PInpSegmentEditedJson)
	WITH (
	RowId INT '$.RowId',
	ProjectId INT '$.ProjectId',
	SectionId INT '$.SectionId',
	CustomerId INT '$.CustomerId',
	SegmentStatusId BIGINT '$.SegmentStatusId',
	UserId INT '$.UserId',
	SegmentDescription NVARCHAR(MAX) '$.SegmentDescription',
	BaseSegmentDescription NVARCHAR(MAX) '$.BaseSegmentDescription',
	SegmentAction NVARCHAR(10) '$.SegmentAction',
	SegmentId BIGINT '$.SegmentId',
	SegmentSource CHAR(1) '$.SegmentSource',
	SegmentOrigin CHAR(1) '$.SegmentOrigin',
	ParentSegmentStatusId BIGINT '$.ParentSegmentStatusId',
	IndentLevel INT '$.IndentLevel',
	IsShowAutoNumber BIT '$.IsShowAutoNumber',
	FormattingJson NVARCHAR(MAX) '$.FormattingJson',
	IsPageBreak BIT '$.IsPageBreak',
	ChoiceListJson NVARCHAR(MAX) '$.ChoiceListJson',
	SpecTypeTagId INT '$.SpecTypeTagId'
	--,ToggleOrigin NVARCHAR(10) '$.ToggleOrigin'
	);

	DECLARE @TempInpSegmentEditedJsonCounter INT=(SELECT COUNT(1)	FROM #TempInpSegmentEditedJson)

DECLARE @ProjectId INT;
DECLARE @SectionId INT;
DECLARE @CustomerId INT;
DECLARE @SegmentStatusId BIGINT;
DECLARE @UserId INT;
DECLARE @SegmentDescription NVARCHAR(MAX);
DECLARE @BaseSegmentDescription NVARCHAR(MAX);
DECLARE @SegmentAction NVARCHAR(10);
DECLARE @SegmentId BIGINT;
DECLARE @SegmentSource CHAR(1);
DECLARE @SegmentOrigin CHAR(1);
DECLARE @ParentSegmentStatusId BIGINT;
DECLARE @IndentLevel INT;
DECLARE @IsShowAutoNumber BIT;
DECLARE @FormattingJson NVARCHAR(MAX);
DECLARE @IsPageBreak BIT;
DECLARE @ChoiceListJson NVARCHAR(MAX);
DECLARE @SpecTypeTagId INT;
--DECLARE @ToggleOrigin NVARCHAR(10);

WHILE (@LoopCount <= @TempInpSegmentEditedJsonCounter)
BEGIN

set @ProjectId =0;
set @SectionId =0;
set @CustomerId =0;
set @SegmentStatusId =0;
set @UserId =0;
set @SegmentDescription =null;
set @BaseSegmentDescription =null;
set @SegmentAction =null;
set @SegmentId =0;
set @SegmentSource =null;
set @SegmentOrigin =null;
set @ParentSegmentStatusId =0;
set @IndentLevel =0;
set @IsShowAutoNumber =0;
set @FormattingJson =null;
set @IsPageBreak =0;
set @ChoiceListJson =null;
set @SpecTypeTagId =0;
--set @ToggleOrigin =null;

SELECT
	@ProjectId = ProjectId
   ,@SectionId = SectionId
   ,@CustomerId = CustomerId
   ,@SegmentStatusId = SegmentStatusId
   ,@UserId = UserId
   ,@SegmentDescription = SegmentDescription
   ,@BaseSegmentDescription = BaseSegmentDescription
   ,@SegmentAction = SegmentAction
   ,@SegmentId = SegmentId
   ,@SegmentSource = SegmentSource
   ,@SegmentOrigin = SegmentOrigin
   ,@ParentSegmentStatusId = ParentSegmentStatusId
   ,@IndentLevel = IndentLevel
   ,@IsShowAutoNumber = IsShowAutoNumber
   ,@FormattingJson = FormattingJson
   ,@IsPageBreak = IsPageBreak
   ,@ChoiceListJson = ChoiceListJson
   ,@SpecTypeTagId = SpecTypeTagId
   --,@ToggleOrigin=ToggleOrigin
FROM #TempInpSegmentEditedJson
WHERE RowId = @LoopCount

--IF SEGMENT IS MODIFIED      
IF ISNULL(@SegmentAction,'')= 'Modified'
BEGIN

EXEC usp_ActionOnMasterSegmentModify @ProjectId
									,@SectionId
									,@CustomerId
									,@UserId
									,@SegmentStatusId
									,@SegmentDescription
									,@BaseSegmentDescription
									,@SegmentId
									,@SegmentSource
									,@SegmentOrigin
									,@ParentSegmentStatusId
									,@IndentLevel
									,@IsShowAutoNumber
									,@FormattingJson
									,@IsPageBreak
									,@SpecTypeTagId
--PRINT 'Autosave call'    

IF @SegmentOrigin = 'U'
BEGIN
IF ISNULL(@ChoiceListJson,'[]')!= '[]'
--PRINT 'Autosave call'    
BEGIN
SELECT
	@segmentid = SegmentId
FROM ProjectSegment WITH (NOLOCK)
WHERE ProjectId = @ProjectId AND SectionId = @SectionId AND SegmentStatusId = @SegmentStatusId

--SELECT @ChoiceListJson   
	--IF(@ToggleOrigin NOT IN('M','M*'))
	--BEGIN
		EXEC [usp_CreateUserChoice] @ChoiceListJson
									 ,@SegmentStatusId
									 ,@segmentid
									 ,@SegmentSource
									 ,@SegmentOrigin
	--END
END
END

SELECT
	PSST.SegmentStatusId
   ,PSST.SegmentStatusCode
   ,PSST.SegmentId
   ,PSG.SegmentCode
   ,PSST.SegmentOrigin
   ,CONVERT(BIGINT,PSST.ParentSegmentStatusId) as ParentSegmentStatusId
   ,PSST.IndentLevel
   ,PSST.IsShowAutoNumber
   ,PSST.FormattingJson
   ,PSST.IsPageBreak
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN ProjectSegment PSG WITH (NOLOCK)
	ON PSST.SegmentId = PSG.SegmentId
		AND isnull(PSG.IsDeleted ,0)= 0
WHERE PSST.SegmentStatusId = @SegmentStatusId

END

SET @LoopCount = @LoopCount + 1;
  
END

END TRY
BEGIN CATCH
	insert into BsdLogging..AutoSaveLogging
		values('usp_AutoSaveModifiedDetails',
		getdate(),
		ERROR_MESSAGE(),
		ERROR_NUMBER(),
		ERROR_Severity(),
		ERROR_LINE(),
		ERROR_STATE(),
		ERROR_PROCEDURE(),
		concat('exec usp_AutoSaveModifiedDetails ''',@InpSegmentEditedJson,''''),
		@InpSegmentEditedJson
	)

	DECLARE @AutoSaveLoggingId INT =  (SELECT @@IDENTITY AS [@@IDENTITY]);
    THROW 50010, @AutoSaveLoggingId, 1;
END CATCH

END
GO


