/* 
server name : SLCProject_SqlSlcOp004
Customer Support 59558: page break on 0000 - Cynthia Keyser with McFarlin Huitt Panvini - 67671
*/


UPDATE PSS SET PSS.IsPageBreak = 0
FROM ProjectSegmentStatus  PSS  WITH(NOLOCK)
WHERE CustomerId  = 3840
AND ParentSegmentStatusId=0
AND IsPageBreak=1