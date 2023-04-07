/*
server name : SLCProject_SqlSlcOp003
Customer Support 30901: Customer cannot open project - gets the spinning wheel.
--For References---------
-- select IsDeleted,  * from ProjectSegmentStatus  where SectionId=4948473 	
*/

 update PSS
 set PSS.isdeleted=1
 from ProjectSegmentStatus PSS WITH(nolock) 
 where PSS.SegmentStatusId=224965144	