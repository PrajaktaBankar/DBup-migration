/*
server name : SLCMaster_SqlSlcOp001,SLCMaster_SqlSlcOp002,SLCMaster_SqlSlcOp003,SLCMaster_SqlSlcOp004
Row affected 2 for each query
Customer Support 30908: NMS Master Section 00 0110 needs to be re-loaded

FYI - 
select * from segment where sectionid in (2018,3105)
*/

Update S
set SegmentDescription = 'Not Used'
from segment S with (nolock) where sectionid=2018 and segmentid in (369530,369531) -- for English


Update S
set SegmentDescription = 'Sans Objet'
from segment S with (nolock) where sectionid=3105 and segmentid in (369542,369543) -- for French
