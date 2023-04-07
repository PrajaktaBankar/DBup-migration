/*
Customer Support 44155: SLC: Corrupt Section - Cannot Open
Server:4

----for reference----
section has corrupted and missmastch data
select ps.IsDeleted,* from ProjectSegmentStatus PSS inner join ProjectSegment ps on pss.SegmentId=ps.SegmentId 
and pss.SectionId=ps.SectionId and PSS.ProjectId=ps.ProjectId where PSS.ProjectId=6662 and PSS.sectionid=7693492
and ps.SegmentDescription='<br>' and PSS.SegmentSource='U' 

select * from dbo.SegmentComment where SectionId=7693492 and projectid=6662
*/



UPDATE PSS
SET PSS.IsDeleted = 1
from ProjectSegmentStatus PSS WITH (NOLOCK) inner join ProjectSegment ps WITH (NOLOCK) on pss.SegmentId=ps.SegmentId 
and pss.SectionId=ps.SectionId and PSS.ProjectId=ps.ProjectId where PSS.ProjectId=6662 and PSS.sectionid=7693492
and ps.SegmentDescription='<br>' and PSS.SegmentSource='U'

UPDATE PC
set PC.IsDeleted=0
from SegmentComment PC WITH (NOLOCK) where PC.SectionId=7693492 and PC.ProjectId=6662