--Customer Support 44826: SLC duplicate text in section
--Execute this on Server 2
USE SLCProject_SqlSlcOp002
GO
--Record will be affected 726
--Select *
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
WHERE PSS.ProjectId  IN (9253)
AND PS.SourceTag='095100' 
AND PS.Description='Acoustical Ceilings') AS X
WHERE x.Rowno > 1