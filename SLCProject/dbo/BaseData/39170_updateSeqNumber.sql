/*
Customer Support 39170: SLC paragraphs are not in the correct order

server :2

for references 
sequence number mismatch and one segment duplicate.
*/


UPDATE PSS
SET PSS.IsDeleted = 1
FROM ProjectSegmentStatus PSS with(nolock) WHERE PSS.SegmentStatusId=417376155 
and PSS.ProjectId=2106 and PSS.sectionid=2589922


UPDATE PSS
SET PSS.SequenceNumber=26.0000
FROM ProjectSegmentStatus PSS with(nolock) WHERE PSS.SegmentStatusId=399526729 
and ProjectId=2106 and sectionid=2589922





 