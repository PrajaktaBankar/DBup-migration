 --execute on server 2
 --Customer Support 30397: Church Project: Requirement Tag\Report tag appear twice in the report column
 --rows affected 4723
 UPDATE A SET A.IsDeleted=1 from (
 select PSRT.*,
 ROW_NUMBER() OVER(PARTITION BY PSRT.SegmentStatusId,	
 PSRT.RequirementTagId ORDER  BY PSRT.SegmentStatusId,PSRT.mSegmentRequirementTagId DESC) as row_no
  FROM ProjectSegmentRequirementTag PSRT WITH(NOLOCK)  
 inner join Project P WITH(NOLOCK) ON P.ProjectId=PSRT.ProjectId AND P.CustomerId=PSRT.CustomerId
 WHERE  ISNULL(P.IsDeleted,0)=0  and P.CustomerId=2552
 )A WHERE a.row_no>1 
  