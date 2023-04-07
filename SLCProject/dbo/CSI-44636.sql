-- Customer Support 44636: SLC - Duplicated Master Section and Duplicated Master Paragraphs
--Execute this on Server 3
USE SLCProject_SqlSlcOp003
GO

--Record will be affected 1132
--Select X Set IsDeleted = 1
Update X Set IsDeleted = 1
FROM (SELECT
PSS.SectionId
,PSS.SegmentStatusId
,PSS.ParentSegmentStatusId
,PSS.mSegmentStatusId
,PSS.mSegmentId
,PSS.SegmentSource
,PSS.ProjectId
,PSS.IsDeleted
,ROW_NUMBER() OVER (PARTITION BY PSS.SectionId, PSS.mSegmentStatusId, PSS.mSegmentId, PSS.SegmentSource, PSS.ProjectId ORDER BY PSS.SegmentStatusId ASC) AS Rowno
FROM ProjectSegmentStatus PSS with (NOLOCK) INNER JOIN ProjectSection PS WITH (NOLOCK)
ON PSS.ProjectId=PS.ProjectId AND PSS.SectionId=PS.SectionId
WHERE PSS.ProjectId  IN (10046)
AND PS.SourceTag='122400' 
AND PS.Description='Window Shades') AS X
WHERE x.Rowno > 1