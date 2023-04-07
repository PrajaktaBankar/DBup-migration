USE [SLCProject_SqlSlcOp004]
GO

UPDATE PSS SET PSS.ParentSegmentStatusId = 1421002006
FROM ProjectSegmentStatus PSS WITH(NOLOCK)
WHERE PSS.ProjectId = 20410 AND PSS.SectionId = 26401096  
and PSS.ParentSegmentStatusId = 1473649291
	  


