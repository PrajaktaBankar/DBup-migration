/*
 server name : SLCProject_SqlSlcOp004
 Customer Support 54367: links on when they should not be - Tara Mitchell with Earl Swensson Associates, Inc. - 18821
*/

UPDATE PSS
SET PSS.SegmentStatusTypeId=9
FROM ProjectSegmentStatus PSS with(nolock) 
WHERE PSS.segmentstatusid= 260176652 
AND PSS.SectionId = 5880143 
AND PSS.ProjectId =5094 
AND PSS.CustomerId =1429
