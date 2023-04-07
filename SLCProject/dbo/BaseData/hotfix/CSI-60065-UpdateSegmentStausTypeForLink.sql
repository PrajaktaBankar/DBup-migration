Use [SLCProject_SqlSlcOp003]
go

UPDATE PSS SET PSS.SegmentStatusTypeId = 6
from ProjectSegmentStatus PSS WITH(NOLOCK)
INNER JOIN ProjectSegmentLink PSL WITH(NOLOCK) ON 
PSS.SegmentStatusCode = PSL.TargetSegmentStatusCode
Where ISNULL(PSL.IsDeleted,0) = 1 
AND PSS.ProjectId = 9965
AND PSS.SectionId = 15778050
AND PSL.SourceSectionCode  = 10013357
AND PSS.SegmentStatusTypeId = 1


UPDATE PSS SET PSS.SegmentStatusTypeId = 6
from ProjectSegmentStatus PSS WITH(NOLOCK)
INNER JOIN ProjectSegmentLink PSL WITH(NOLOCK) ON 
PSS.SegmentStatusCode = PSL.SourceSegmentStatusCode
Where ISNULL(PSL.IsDeleted,0) = 1 
AND PSS.ProjectId = 9965
AND PSS.SectionId = 15778050
AND PSL.SourceSectionCode  = 10013357
AND PSS.SegmentStatusTypeId = 1