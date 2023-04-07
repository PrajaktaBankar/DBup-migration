--Usage : SELECT * FROM dbo.[udf_GetRSUsedInChoice]('{RS#3228}&nbsp;{CH#10010219}&nbsp;', 12275, 5710121)
CREATE FUNCTION [dbo].[udf_GetRSUsedInChoice](
	@SegmentDescription NVARCHAR(MAX),
	@ProjectId INT,
	@SectionId INT	 
)
RETURNS  @SegmentRSTbl TABLE(RSCode INT NULL)
AS
BEGIN
	
	DECLARE @SegmentCH TABLE(ChoiceCode INT NULL);
	DECLARE @OptionJsonList TABLE(RowId INT NULL, OptionJson NVARCHAR(MAX) NULL);
	DECLARE @RSUsedInChoice TABLE(Id INT NULL, OptionTypeName NVARCHAR(50) NULL, [Value] NVARCHAR(MAX) NULL);

	INSERT INTO @SegmentCH
	SELECT DISTINCT [value] AS ChoiceCode FROM STRING_SPLIT(dbo.[udf_GetCodeFromFormat](@SegmentDescription,'{CH#'), ',')

	--INSERT INTO @OptionJsonList
	--SELECT ROW_NUMBER() OVER(ORDER BY PSC.SegmentChoiceId DESC) AS RowId, PCO.OptionJson FROM @SegmentCH SC
	--LEFT JOIN ProjectSegmentChoice PSC WITH(NOLOCK) ON SC.ChoiceCode = PSC.SegmentChoiceCode
	--INNER JOIN ProjectChoiceOption PCO WITH(NOLOCK) ON PCO.SegmentChoiceId = PSC.SegmentChoiceId
	--WHERE PCO.ProjectId = @ProjectId AND PCO.SectionId = @SectionId

	INSERT INTO @OptionJsonList
	SELECT ROW_NUMBER() OVER(ORDER BY PSC.SegmentChoiceId DESC) AS RowId, PCO.OptionJson 
	FROM ProjectSegmentChoice PSC WITH(NOLOCK) INNER JOIN ProjectChoiceOption PCO WITH(NOLOCK) 
	ON PCO.SegmentChoiceId = PSC.SegmentChoiceId 
	AND PCO.SectionId=PSC.SectionId
	inner join @SegmentCH SC
	ON PSC.SectionId=@SectionId 
	AND SC.ChoiceCode = PSC.SegmentChoiceCode
	WHERE PCO.SectionId = @SectionId AND PCO.ProjectId = @ProjectId 

	DECLARE @COUNTER INT = (SELECT MAX(RowId) FROM @OptionJsonList);
	DECLARE @OptionJson NVARCHAR(MAX) = '';
	WHILE (@COUNTER != 0)
	BEGIN
 
	 SELECT @OptionJson = OJL.OptionJson
	 FROM @OptionJsonList OJL
		WHERE OJL.RowId = @COUNTER

	 INSERT INTO @RSUsedInChoice
	 SELECT * FROM OPENJSON(@OptionJson)
	  WITH (
	  Id INT '$.Id',
	  OptionTypeName NVARCHAR(50) '$.OptionTypeName',
	  [Value] NVARCHAR(MAX) '$.Value'
	 )
	 WHERE OptionTypeName = 'ReferenceStandard'
	
	 SET @COUNTER = @COUNTER -1
	END

	INSERT INTO @SegmentRSTbl
	SELECT Id AS RSCode FROM @RSUsedInChoice

	RETURN;

END