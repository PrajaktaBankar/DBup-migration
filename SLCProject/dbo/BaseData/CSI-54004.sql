--Execute this on Server 5
--Customer Support 54004: SLC User Sees Section 09 9123 Twice as well as Paragraphs Duplicated
--Record will be affected 1102
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
WHERE PSS.ProjectId IN (2787)
AND PS.SourceTag='099123'
AND PS.Description='Interior Painting') AS X
WHERE x.Rowno > 1


