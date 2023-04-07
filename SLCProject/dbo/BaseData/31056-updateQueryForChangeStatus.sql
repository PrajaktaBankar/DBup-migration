/*
server name : SLCProject_SqlSlcOp004
Customer Support 31056: Duplicate User Paragraphs Appearing In Project  
--For References---------
Same text(Description) but Different entry in  ProjectSegmentStatus table
*/


use SLCProject_SqlSlcOp004

  --(12 rows affected)
  update  PSS
  set IsDeleted=1
  from ProjectSegmentStatus pss WITH(NOLOCK) where  pss.SegmentStatusId in(18192979,18192995,18192981,18192997,18192983,18192999,18192985,18193001,18193003,18192987,18192989,18193007) and  pss.ProjectId=272 and pss.SectionId=311689 
 