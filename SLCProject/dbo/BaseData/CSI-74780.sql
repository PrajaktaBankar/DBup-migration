---Resolved Customer Support 74780: Duplicated data in section - 14820/1401
---Server 4
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
	WHERE PSS.ProjectId = 24263
	AND PSS.SectionId = 29521430) AS X
WHERE x.Rowno > 1

Update projectsegmentStatus set IsDeleted= 0 where projectid=24263 and sectionId=29521430 and SegmentStatusId in (2058847488,2058850640,2058850641)
