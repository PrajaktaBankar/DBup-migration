USE [SLCProject]
GO

UPDATE PS
set PS.SegmentDescription=PHL.SegmentDescription
FROM ProjectSegment4005 PHL WITH (NOLOCK)
INNER JOIN ProjectSegment PS WITH (NOLOCK)
	ON PS.SegmentStatusId = PHL.SegmentStatusId
	AND PS.SegmentId = PHL.SegmentId
	AND PS.ProjectId = PHL.ProjectId
	AND PS.SectionId = PHL.SectionId
	AND PS.CustomerId = PHL.CustomerId
WHERE PHL.ProjectId = 4005 

UPDATE PS
set PS.SegmentDescription=PHL.SegmentDescription
FROM ProjectSegment6107 PHL WITH (NOLOCK)
INNER JOIN ProjectSegment PS WITH (NOLOCK)
	ON PS.SegmentStatusId = PHL.SegmentStatusId
	AND PS.SegmentId = PHL.SegmentId
	AND PS.ProjectId = PHL.ProjectId
	AND PS.SectionId = PHL.SectionId
	AND PS.CustomerId = PHL.CustomerId
WHERE PHL.ProjectId = 6107 

DROP TABLE IF EXISTS ProjectSegment4005
DROP TABLE IF EXISTS ProjectSegment6107