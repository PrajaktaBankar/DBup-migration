--Execute this for Server 2
--Customer Support 30318: Can't open project and master project - Amy Barnett with Platt Architecture - 53536

Use SLCProject_SqlSlcOp002

update PSS
set IsDeleted=1 
from ProjectSegmentStatus PSS WITH (NOLOCK)
where SegmentStatusId =206366947 and ProjectId=4376 and CustomerId=1026


update PSS
set IsDeleted=1
from ProjectSegmentStatus PSS WITH (NOLOCK)
where SegmentStatusId =193724669 and ProjectId = 1016 and CustomerId = 1026

