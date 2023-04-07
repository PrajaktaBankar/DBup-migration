/*
 server name : SLCProject_SqlSlcOp004
 Customer Support 30968: SLC User Cannot Open Sections

 ---For references-----
 SELECT * FROM ProjectSegmentStatus WHERE SectionId = 427878 ORDER BY SequenceNumber 
*/

UPDATE PSS
SET IsDeleted = 1
FROM ProjectSegmentStatus PSS with(nolock) WHERE PSS.SectionId = 427878 
AND PSS.SegmentStatusId in(14008303,14008213)
