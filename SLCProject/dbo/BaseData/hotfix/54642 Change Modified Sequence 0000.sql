/*
 server name : SLCProject_SqlSlcOp005
 Customer Support 54642: SLC: User Modified Sequence #0000
*/

SELECT
	PSS.SegmentStatusId
   ,PSS.SectionId
   ,PSS.ProjectId INTO #projectsegmentStatus
FROM ProjectSegmentStatus PSS WITH(NOLOCK)
WHERE PSS.SequenceNumber = 0
AND PSS.ProjectId = 1572
AND PSS.CustomerId = 1541
AND PSS.SegmentSource = 'M'
AND PSS.SegmentOrigin = 'U' 

SELECT
	PSS.* INTO #DataToBeFix
FROM ProjectSection PS WITH(NOLOCK)
INNER JOIN #projectsegmentStatus PSS
	ON PS.SectionId = PSS.SectionId
INNER JOIN SLCMaster..Section S WITH(NOLOCK)
	ON PS.mSectionId = S.SectionId
	AND (PS.[Description] = S.[Description])
    AND (PS.SourceTag = S.SourceTag) 
WHERE PSS.ProjectId = 1572
AND PSS.CustomerId = 1541


UPDATE PS
SET PS.IsDeleted = 1
FROM ProjectSegment PS WITH(NOLOCK)
INNER JOIN #DataToBeFix PSS
	ON PS.SegmentStatusId = PSS.SegmentStatusId
	AND PS.SectionId = PSS.SectionId

UPDATE PS
SET PS.SegmentOrigin = 'M'
FROM ProjectSegmentStatus PS WITH(NOLOCK)
INNER JOIN #DataToBeFix PSS
	ON PS.SegmentStatusId = PSS.SegmentStatusId
	AND PS.SectionId = PSS.SectionId
