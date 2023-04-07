--Usage : SELECT * FROM dbo.[udf_GetGTUsedInChoice]('{CH#10007177}&nbsp;and {CH#10007178}&nbsp;<br>', 9527, 3523485, 'GlobalTerm')
--Usage : SELECT * FROM dbo.[udf_GetGTUsedInChoice]('OWNER:{RS#3228}&nbsp; ghgf{CH#111193}&nbsp;', 12275, 5710128, 'GlobalTerm')
--SELECT DISTINCT [value] AS ChoiceCode FROM STRING_SPLIT(dbo.[udf_GetCodeFromFormat]('OWNER:{RS#3228}&nbsp; ghgf{CH#111193}&nbsp;','{CH#'), ',')
CREATE FUNCTION [dbo].[udf_GetGTUsedInChoice](
	@SegmentDescription NVARCHAR(MAX),
	@ProjectId INT,
	@SectionId INT
	 
)
RETURNS  @SegmentGTTbl TABLE(GlobalTermCode INT NULL)
AS
BEGIN
	
	--DECLARE @SegmentDescription NVARCHAR(MAX) = '{CH#10007177}&nbsp;and {CH#10007178}&nbsp;<br>';
	DECLARE @SegmentCH TABLE(ChoiceCode INT NULL);
	DECLARE @OptionJsonList TABLE(RowId INT NULL, OptionJson NVARCHAR(MAX) NULL);
	--DECLARE @ProjectId INT = 9527;
	DECLARE @GTUsedInChoice TABLE(Id INT NULL, OptionTypeName NVARCHAR(50) NULL, [Value] NVARCHAR(MAX) NULL);
	--DECLARE @SegmentGT TABLE(GlobalTermCode INT NULL);

	INSERT INTO @SegmentCH
	SELECT DISTINCT [value] AS ChoiceCode FROM STRING_SPLIT(dbo.[udf_GetCodeFromFormat](@SegmentDescription,'{CH#'), ',')

	INSERT INTO @OptionJsonList
	SELECT ROW_NUMBER() OVER(ORDER BY PSC.SegmentChoiceId DESC) AS RowId, PCO.OptionJson FROM @SegmentCH SC
	LEFT JOIN ProjectSegmentChoice PSC WITH(NOLOCK) ON SC.ChoiceCode = PSC.SegmentChoiceCode
	LEFT JOIN ProjectChoiceOption PCO WITH(NOLOCK) ON PCO.SegmentChoiceId = PSC.SegmentChoiceId
	WHERE PCO.ProjectId = @ProjectId AND PCO.SectionId = @SectionId

	DECLARE @COUNTER INT = (SELECT MAX(RowId) FROM @OptionJsonList);
	DECLARE @OptionJson NVARCHAR(MAX) = '';
	WHILE (@COUNTER != 0)
	BEGIN
 
	 SELECT @OptionJson = OJL.OptionJson
	 FROM @OptionJsonList OJL
		WHERE OJL.RowId = @COUNTER

	 INSERT INTO @GTUsedInChoice
	 SELECT * FROM OPENJSON(@OptionJson)
	  WITH (
	  Id INT '$.Id',
	  OptionTypeName NVARCHAR(50) '$.OptionTypeName',
	  [Value] NVARCHAR(MAX) '$.Value'
	 )
	 WHERE OptionTypeName = 'GlobalTerm'
	
	 SET @COUNTER = @COUNTER -1
	END

	INSERT INTO @SegmentGTTbl
	SELECT DISTINCT PGT.GlobalTermCode FROM @GTUsedInChoice GTUIC
	INNER JOIN ProjectGlobalTerm PGT WITH(NOLOCK) ON PGT.GlobalTermCode = GTUIC.Id
	WHERE PGT.GlobalTermSource = 'U' AND ISNULL(PGT.IsDeleted,0) = 0

	RETURN;

END