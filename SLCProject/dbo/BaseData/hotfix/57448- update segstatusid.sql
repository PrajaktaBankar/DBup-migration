/*
	server name : SLCProject_SqlSlcOp002
	Customer Support 57448: SLC unselected sections in TOC
*/

update PSS set SegmentStatusTypeId = 6 from ProjectSegmentStatus PSS WITH(NOLOCK) where SegmentStatusId = 804558734
update PSS set SegmentStatusTypeId = 6 from ProjectSegmentStatus PSS WITH(NOLOCK) where SegmentStatusId = 806060700