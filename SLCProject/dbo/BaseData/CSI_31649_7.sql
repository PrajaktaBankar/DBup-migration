--Customer Support 31649: CH# Errors
--Execute this on Server 2 

update ps 
SET ps. SegmentDescription='Electric Operation:  {CH#244389} and hand held tranmitter at ramp doors.' 
from ProjectSegment ps  WITH(NOLOCK) 
where ps.SegmentStatusId  = 250292325 and ps.segmentId=40836272