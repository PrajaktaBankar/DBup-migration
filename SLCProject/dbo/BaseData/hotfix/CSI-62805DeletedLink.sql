use [SLCProject_SqlSlcOp004]
go


UPDATE PSS SET PSS.SegmentStatusTypeId = 6 
FROM  ProjectSegmentStatus PSS WITH(NOLOCK)
Where PSS.SegmentStatusId = 501822156

Update PSL SET PSL.IsDeleted = 1 
FROM ProjectSegmentLink PSL WITH(NOLOCK)
 Where SegmentLinkId in( 145651214,377307443)

