--Execute on Server 2
-- Customer Support 46839: SLC Cannot edit parts of a section

UPDATE pss set pss.ParentSegmentStatusId=631717995,pss.IndentLevel = 5
from ProjectSegmentStatus pss with(nolock) where pss.ProjectId = 11011
AND pss.SectionId = 13327654 and pss.SegmentStatusId in (631721021,631730918)