USE SLCProject

GO

/*
 Server name : SLCProject_SqlSlcOp002
 Customer Support 64363: SLC Links Not Working Correctly
*/
update PSS SET SegmentStatusTypeId = 6 , IsParentSegmentStatusActive = 0 FROM ProjectSegmentStatus PSS WITH(NOLOCK) where ProjectId  = 7248 AND SectionId = 8662014;
update PSS SET  IsParentSegmentStatusActive = 1 FROM ProjectSegmentStatus PSS WITH(NOLOCK) WHERE SegmentStatusId = 349271064;