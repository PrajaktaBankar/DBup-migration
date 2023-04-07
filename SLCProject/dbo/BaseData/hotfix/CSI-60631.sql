Use [SLCProject_SqlSlcOp004]
GO


UPDATE PSS SET PSS.ParentSegmentStatusId =607226513
FROM ProjectSegmentStatus PSS  WITH(NOLOCK)
WHERE ProjectId = 6024
AND SectionId = 12090282
AND ParentSegmentStatusId in (607226586,1183692763)
AND ISNULL(IsDeleted,0)=0	

UPDATE PSS SET PSS.ParentSegmentStatusId = 1198864192
FROM ProjectSegmentStatus PSS  WITH(NOLOCK)
WHERE ProjectId = 6024
AND SectionId = 12090282
AND SegmentStatusId in (607226541)
AND ISNULL(IsDeleted,0)=0