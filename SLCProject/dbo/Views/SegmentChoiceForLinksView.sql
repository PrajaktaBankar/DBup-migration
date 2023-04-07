
CREATE VIEW [dbo].[SegmentChoiceForLinksView]
AS
SELECT
	PSST.CustomerId
   ,PSST.ProjectId
   ,PSST.SectionId
   ,PS.SectionCode
   ,PSST.SegmentStatusId
   ,PSST.SegmentStatusCode
   ,PSST.mSegmentId AS SegmentCode
   ,CH.SegmentChoiceCode
   ,CH.ChoiceTypeId
   ,CHOP.ChoiceOptionCode
   ,CHOP.SortOrder
   ,CHOP.OptionJson
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
	ON PSST.SectionId = PS.SectionId
INNER JOIN SLCMaster..SegmentChoice CH WITH (NOLOCK)
	ON PSST.mSegmentId = CH.SegmentId
INNER JOIN SLCMaster..ChoiceOption CHOP WITH (NOLOCK)
	ON CH.SegmentChoiceId = CHOP.SegmentChoiceId
WHERE PSST.SegmentOrigin = 'M'
UNION ALL
SELECT
	PSST.CustomerId
   ,PSST.ProjectId
   ,PSST.SectionId
   ,PS.SectionCode
   ,PSST.SegmentStatusId
   ,PSST.SegmentStatusCode
   ,PSG.SegmentCode
   ,CH.SegmentChoiceCode
   ,CH.ChoiceTypeId
   ,CHOP.ChoiceOptionCode
   ,CHOP.SortOrder
   ,CHOP.OptionJson

FROM ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
	ON PSST.SectionId = PS.SectionId
INNER JOIN ProjectSegment PSG WITH (NOLOCK)
	ON PSST.SegmentId = PSG.SegmentId
	--ON PSST.SegmentStatusId = PSG.SegmentStatusId AND PSST.SectionId = PSG.SectionId AND PSST.ProjectId = PSG.ProjectId
INNER JOIN ProjectSegmentChoice CH WITH (NOLOCK)
	--ON PSST.SegmentId = CH.SegmentId
	ON PSST.SectionId = CH.SectionId AND PSST.ProjectId = CH.ProjectId AND PSST.CustomerId = CH.CustomerId AND PSST.SegmentStatusId = CH.SegmentStatusId
		AND ISNULL(CH.IsDeleted, 0) = 0
INNER JOIN ProjectChoiceOption CHOP WITH (NOLOCK)
	ON CH.SegmentChoiceId = CHOP.SegmentChoiceId
		AND ISNULL(CHOP.IsDeleted, 0) = 0
WHERE PSST.SegmentOrigin = 'U'

GO


