--Customer Support 32615: CH# Errors in Office Master - Duplicate Paragraphs
--Execute this on Server 2

Update X Set IsDeleted = 1
FROM (SELECT
		SectionId
	   ,SegmentStatusId
	   ,ParentSegmentStatusId
	   ,mSegmentStatusId
	   ,mSegmentId
	   ,SegmentSource
	   ,ProjectId 
	   ,IsDeleted 
	   ,ROW_NUMBER() OVER (PARTITION BY SectionId, mSegmentStatusId, mSegmentId, SegmentSource, ProjectId ORDER BY SegmentStatusId ASC) AS Rowno
	FROM ProjectSegmentStatus PSS with (NOLOCK)
	WHERE PSS.ProjectId = 2778
	AND PSS.SectionId = 3375776) AS X
WHERE x.Rowno > 1
