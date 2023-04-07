--Customer Support 60143: Printing Project Notes in a Section
--Server 3 

update pn
SET pn.NoteText ='<p>verify accessory types provided with SFH for all projects. &nbsp;are there circumstances that CG would procure any?</p>' 
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129437 and SegmentstatusId = 863869171


update pn
SET pn.NoteText ='<p>To be used in Patient toilet rooms. Mount on top of backsplash, in accordance with ADA.</p>' 
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15128869 and SegmentstatusId = 863806482

update pn
SET pn.NoteText ='<p>I sent a message to Bluesky Glass to ask about specs on SFH mirrors. &nbsp;It''s a custom sheet mirror product. &nbsp;I feel that this is the more appropriate section vs toilet access.</p>' 
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15128869 and SegmentstatusId = 863806638

