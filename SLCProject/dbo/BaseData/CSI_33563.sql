--Execute this on Server 3
--Customer Support 33563: Grimm and Parker: Reference Standard Paragraphs appear under Section Includes article


Update PSS   
SET PSS.SegmentStatusTypeId = 1 
from ProjectSegmentStatus as PSS  with (nolock)
where PSS.ProjectId = 5575 and PSS.SegmentStatusId =219392170


Update PSS  
SET PSS.SegmentStatusTypeId = 1 
from ProjectSegmentStatus as PSS with (nolock)
where PSS.ProjectId = 5535 and PSS.SegmentStatusId =214663955


Update PSS  
SET PSS.SegmentStatusTypeId = 1  
from ProjectSegmentStatus as PSS with (nolock)
where PSS.ProjectId = 5573 and PSS.SegmentStatusId =215382924

