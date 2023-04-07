--Customer Support 32774: Paragraphs repeating multiple time across several projects - (CID = 66594 / AID = 291 / SERVER 2)
--Execute this on Server 2
use SLCProject_SqlSlcOp002
GO
--Record will be affected 7778
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
WHERE PSS.ProjectId  IN (3186,3333,3577,4513,5021,5216,5473)
AND PS.SourceTag='095100' 
AND PS.Description='Acoustical Ceilings') AS X
WHERE x.Rowno > 1


