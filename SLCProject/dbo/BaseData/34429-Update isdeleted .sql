use SLCProject
--Customer Support 34429: Reference Standard Replaced with {RSTEMP#2163} Error after Migration
--Execute It on server 03

UPDATE t 
set t.IsDeleted=1
from ProjectSegment t WITH(NOLOCK) where SegmentStatusId=305941460

UPDATE t 
set t.IsDeleted=1
from ProjectSegmentStatus t WITH(NOLOCK) where SegmentStatusId=305941460


UPDATE t 
set t.IsDeleted=1
from ProjectSegment t WITH(NOLOCK) where SegmentStatusId=305941457

UPDATE t 
set t.IsDeleted=1
from ProjectSegmentStatus t WITH(NOLOCK) where SegmentStatusId=305941457
 