
CREATE VIEW [dbo].[ProjectSegmentStatusView]
AS
SELECT
	PS.SectionId
   ,PS.SectionCode
   ,PS.SourceTag
   ,PSST.SegmentStatusId
   ,PSST.mSegmentStatusId
   ,PSST.ParentSegmentStatusId
   ,PSST.SegmentStatusCode
   ,(CASE
		WHEN PSST.SegmentStatusId IS NOT NULL AND
			PSST_PSG.SegmentId IS NOT NULL THEN PSST_PSG.SegmentCode
		WHEN PSST.SegmentStatusId IS NOT NULL AND
			PSST_MSG.SegmentId IS NOT NULL THEN PSST_MSG.SegmentCode
		ELSE NULL
	END) AS SegmentCode
   ,(CASE
		WHEN PSST.SequenceNumber = 0 AND
			PSST.IndentLevel = 0 AND
			PSST.ParentSegmentStatusId = 0 THEN PS.Description
		WHEN PSST.SegmentStatusId IS NOT NULL AND
			PSST_PSG.SegmentId IS NOT NULL THEN COALESCE(PSST_PSG.BaseSegmentDescription, PSST_PSG.SegmentDescription)
		WHEN PSST.SegmentStatusId IS NOT NULL AND
			PSST_MSG.SegmentId IS NOT NULL THEN PSST_MSG.SegmentDescription
		ELSE NULL
	END) AS SegmentDescription
   ,PSST.SegmentId
   ,PSST.mSegmentId
   ,PSST.SequenceNumber
   ,PSST.IndentLevel
   ,PSST.SegmentSource
   ,PSST.SegmentOrigin
   ,PSST.SegmentStatusTypeId
   ,PSST.IsParentSegmentStatusActive
   ,PSST.SpecTypeTagId
   ,PSST.ProjectId
   ,PSST.CustomerId
   ,(CASE
		WHEN PSST.IsParentSegmentStatusActive = 1 AND
			PSST.SegmentStatusTypeId < 6 THEN 1
		ELSE 0
	END) AS IsSegmentStatusActive
   ,(CASE
		WHEN PSST.IsDeleted = 1 THEN 1
		WHEN PS.IsDeleted = 1 THEN 1
		ELSE 0
	END) AS IsDeleted
   ,ISNULL(PSST_PSG.IsDeleted, 0) AS IsSegmentDeleted
   ,PS.mSectionId
   ,ISNULL(PSST_PSG.IsDeleted, 0) AS IsSegmentDeleted
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
	ON PSST.ProjectId = PS.ProjectId
		AND PSST.SectionId = PS.SectionId
LEFT JOIN ProjectSegment PSST_PSG WITH (NOLOCK)
	--ON PSST.SegmentId = PSST_PSG.SegmentId
	ON PSST.SegmentStatusId = PSST_PSG.SegmentStatusId AND PSST.SectionId = PSST_PSG.SectionId AND PSST.ProjectId = PSST_PSG.ProjectId
		AND PSST.SegmentOrigin = 'U'
LEFT JOIN SLCMaster..Segment PSST_MSG WITH (NOLOCK)
	ON PSST.mSegmentId = PSST_MSG.SegmentId
		AND PSST.SegmentOrigin = 'M'
GO


