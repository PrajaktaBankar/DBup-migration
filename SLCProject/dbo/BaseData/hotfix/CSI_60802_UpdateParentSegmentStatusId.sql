/* 
server name : SLCProject_SqlSlcOp004
Customer Support 60802: SLC Paragraphs not turning on - 21628
*/


UPDATE PSS SET PSS.ParentSegmentStatusId=1262466182
FROM ProjectSegmentStatus PSS WITH (nolock)
WHERE PSS.ParentSegmentStatusId =1263970414
and PSS.SectionId=23977211 
AND ISNULL(PSS.IsDeleted,0) = 0