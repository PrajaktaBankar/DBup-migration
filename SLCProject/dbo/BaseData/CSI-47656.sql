--Execute on Server 4
--Customer Support 47656: SLC Double Paragraphs

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
WHERE PSS.ProjectId  IN (9265)
AND PS.SourceTag='033000' 
AND PS.Description='Cast-in-Place Concrete') AS X
WHERE x.Rowno > 1