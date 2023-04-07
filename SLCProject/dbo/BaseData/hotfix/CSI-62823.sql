USe [SLCProject_SqlSlcOp004]
GO

UPDATE PSS  SET PSS.ParentSegmentStatusId = 0,
PSS.IndentLevel=0
FROM  ProjectSegmentStatus PSS With(NOLOCK)
Where PSS.SegmentStatusId =1317520736

 UPDATE PSS SET ParentSegmentStatusId = 1317520736,IndentLevel=1
 FROM ProjectSegmentStatus PSS WITH(nolock)
 Where PSS.ProjectId = 19138 
 and PSS.SectionId = 24812004 
 AND PSS.SegmentStatusId !=1317520736 