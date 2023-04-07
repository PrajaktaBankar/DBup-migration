--Server 5 
--Customer Support 64476: Text code when exporting - Bobbye Moore with Manley Spangler Smith Architects

update ps 
set ps.SegmentDescription = 'Review waterproofing requirements including surface preparation, substrate condition and pretreatment, minimum curing period, forecasted weather conditions, special details and sheet flashings, installation procedures, testing and inspection procedures, and protection and repairs.'
from ProjectSegment ps WITH (NOLOCK) where ps.segmentStatusId = 325559921 and ps.CustomerId = 4205 and ps.ProjectId = 4507

update ps 
set ps.SegmentDescription ='Preinstallation Conference: Conduct conference at Project site.'
from ProjectSegment ps WITH (NOLOCK) where ps.CustomerId = 4205 and ps.ProjectId = 4507 and ps.SegmentStatusId = 325559919



