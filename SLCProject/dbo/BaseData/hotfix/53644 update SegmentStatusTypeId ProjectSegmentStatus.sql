/*
 server name : SLCProject_SqlSlcOp004
 Customer Support 53644: SLC: Phantom Sections Showing In TOC (Links) (Inactive sections are active in 000110 - Table Of Contents section)
*/

UPDATE PSS SET SegmentStatusTypeId = 6
FROM ProjectSegmentStatus PSS 
WHERE SegmentStatusId =639676222  
AND SectionId = 12823255 
AND ProjectId = 10776 
AND CustomerId = 893
