CREATE PROCEDURE [dbo].[usp_GetSectionIdChoiceReferences]    
@projectId INT NULL, @customerId INT NULL, @SectionId INT NULL=NULL
AS    
BEGIN
DECLARE @PprojectId INT = @projectId;
DECLARE @PcustomerId INT = @customerId;
DECLARE @PSectionId INT = @SectionId;

DECLARE @mSectionId int=NULL

SELECT
	@mSectionId = mSectionId
FROM ProjectSection
WHERE ProjectId = @PprojectId
AND CustomerId = @PcustomerId
AND SectionId = @PSectionId

SELECT
	* INTO #TempResult
FROM (SELECT DISTINCT
		ProjSection.Author
	   ,ProjSection.Description AS SectionDescription
	   ,ProjSection.SourceTag AS SourceTag
	   ,PCO.SectionId AS SectionId
	   ,PSS.SegmentStatusId SegmentStatusId
	   ,CAST(CASE
			WHEN PSS.SegmentSource = 'M' AND
				PSS.SegmentOrigin = 'M' AND
				PSS.SegmentId IS NULL THEN ''
			WHEN PSS.SegmentSource = 'M' AND
				PSS.SegmentOrigin = 'U' THEN 'M*'
			WHEN PSS.SegmentSource = 'U' AND
				PSS.SegmentOrigin = 'U' THEN 'U'
			WHEN PSS.SegmentSource = 'M' AND
				PSS.SegmentOrigin = 'M' AND
				PSS.SegmentId IS NOT NULL THEN 'M'
		END AS VARCHAR) AS SegmentOrigin
	   ,PSS.SegmentId
		-- ,dbo.fnGetSegmentDescriptionTextForChoice(PSS.SegmentStatusId) AS SegmentDescription
		--  ,RIGHT('000'+CAST(ISNULL(CAST(PSS.SequenceNumber as INT),0) AS VARCHAR),4)  AS SequenceNumber
	   ,CAST(ProjSegment.SegmentDescription AS VARCHAR) AS SegmentDescription
	   ,CAST(PSS.SequenceNumber AS VARCHAR) AS SequenceNumber

	FROM ProjectChoiceOption PCO  WITH(NOLOCK)
	INNER JOIN ProjectSegmentChoice PSC  WITH(NOLOCK)
		ON PSC.SegmentChoiceId = PCO.SegmentChoiceId
		AND PSC.ProjectId = PCO.ProjectId
		AND PSC.CustomerId = PCO.CustomerId
	INNER JOIN ProjectSegmentStatus PSS  WITH(NOLOCK)
		ON PSS.SegmentId = PSC.SegmentId
		AND PSS.SegmentStatusId = PSC.SegmentStatusId
	INNER JOIN ProjectSegment ProjSegment  WITH(NOLOCK)
		ON ProjSegment.SegmentId = PSS.SegmentId
		AND PSS.SegmentStatusId = ProjSegment.SegmentStatusId
	INNER JOIN ProjectSection ProjSection  WITH(NOLOCK)
		ON ProjSection.SectionId = ProjSegment.SectionId
	WHERE PCO.OptionJson
	LIKE CONCAT('%"Id":', @PSectionId, '%')
	AND PCO.ProjectId = @PprojectId
	AND PCO.CustomerId = @PcustomerId
	AND PSS.SegmentOrigin = 'U'

	UNION

	SELECT DISTINCT
		PS.Author
	   ,PS.Description AS SectionDescription
	   ,PS.SourceTag AS SourceTag
	   ,PS.SectionId AS SectionId
	   ,PSST.SegmentStatusId SegmentStatusId
	   ,CAST(CASE
			WHEN PSST.SegmentSource = 'M' AND
				PSST.SegmentOrigin = 'M' AND
				PSST.SegmentId IS NULL THEN ''
			WHEN PSST.SegmentSource = 'M' AND
				PSST.SegmentOrigin = 'U' THEN 'M*'
			WHEN PSST.SegmentSource = 'U' AND
				PSST.SegmentOrigin = 'U' THEN 'U'
			WHEN PSST.SegmentSource = 'M' AND
				PSST.SegmentOrigin = 'M' AND
				PSST.SegmentId IS NOT NULL THEN 'M'
		END AS VARCHAR) AS SegmentOrigin
	   ,PSST.SegmentId
		-- ,dbo.fnGetSegmentDescriptionTextForChoice(PSST.SegmentStatusId) AS SegmentDescription
		--,RIGHT('000'+CAST(ISNULL(CAST(PSST.SequenceNumber as INT),0) AS VARCHAR),4)  AS SequenceNumber
	   ,CAST(S.SegmentDescription AS VARCHAR) AS SegmentDescription
	   ,CAST(PSST.SequenceNumber AS VARCHAR) AS SequenceNumber
	FROM ProjectSection PS (NOLOCK)
	INNER JOIN ProjectSegmentStatus PSST (NOLOCK)
		ON PS.SectionId = PSST.SectionId
		AND PS.ProjectId = PSST.ProjectId
		AND PS.CustomerId = PSST.CustomerId
	INNER JOIN SLCMaster..Segment S  WITH(NOLOCK)
		ON S.SegmentId = PSST.mSegmentId
	INNER JOIN SLCMaster..SegmentChoice MSC (NOLOCK)
		ON PSST.mSegmentId = MSC.SegmentId
	INNER JOIN SLCMaster..ChoiceOption MCO (NOLOCK)
		ON MSC.SegmentChoiceId = MCO.SegmentChoiceId
	WHERE MCO.OptionJson LIKE CONCAT('%"Id":', @mSectionId, '%')
	AND PS.ProjectId = @PProjectId
	AND PS.CustomerId = @PcustomerId
	AND PSST.SegmentOrigin = 'M') AS X

SELECT DISTINCT
	SectionDescription
   ,SourceTag
   ,SectionId
   ,Author
FROM #TempResult

SELECT
	*
FROM #TempResult
END

GO
