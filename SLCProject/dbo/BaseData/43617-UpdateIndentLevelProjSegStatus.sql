/*
Customer Support 43617: SLC Master Text Update Won't Update
server :3


----for references------------
select * from ProjectSegmentStatus where SegmentStatusId=160276250 and SectionId = 3930956  and projectid=4624
select * from  [SLCMaster]..SegmentStatus where SegmentStatusId=546722
*/


UPDATE PSS
SET PSS.IndentLevel = 6
FROM ProjectSegmentStatus PSS with(nolock) WHERE PSS.SectionId = 3930956 
AND PSS.SegmentStatusId=160276250 and PSS.ProjectId=4624