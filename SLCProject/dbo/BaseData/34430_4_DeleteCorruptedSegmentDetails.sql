use SLCProject;
--Execute on server 3
--Customer Support 34430: Links Did Not Save Properly and are Missing - Duplicate Link Error Message


-- 61 Records deleted
UPDATE PSL set IsDeleted = 1
from ProjectSegmentLink PSL WITH(NOLOCK) WHERE ProjectId = 6329  and 
convert(varchar, CreateDate, 23) = '2020-02-18'
and (TargetSectionCode = 331 or SourceSectionCode = 331);
