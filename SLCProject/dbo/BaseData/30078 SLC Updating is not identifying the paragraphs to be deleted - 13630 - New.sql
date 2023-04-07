/*
server Name : SLCProject_SqlSlcOp003
Customer Support 30078: SLC - Updating is not identifying the paragraphs to be deleted - 13630
Row Affected - 1
*/

update pss 
set segmentorigin='M' 
FROM ProjectSegmentStatus with (nolock) pss 
where segmentstatusid=143605152


