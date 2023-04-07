/*
Customer Support 38470: SLC Printing Failure
Server :2

----------------------------for reference--------------------------------------
update isdeleted  1 record projectsegment and projectsegmentstatus.
showing RSCode in RSArticle because below csi deleted 1 user reference standard as per customer requirement
Customer Support 38311: SLC User Needs User RS Changed in that CSI
*/



UPDATE PS 
set PS.IsDeleted=1
from ProjectSegment PS WITH(NOLOCK) where PS.SegmentStatusId=383756811 and PS.sectionid=8875595 and PS.projectid=7409

UPDATE PSS 
set PSS.IsDeleted=1
from ProjectSegmentStatus PSS WITH(NOLOCK) where  PSS.SegmentStatusId=383756811 and PSS.sectionid=8875595 and PSS.projectid=7409