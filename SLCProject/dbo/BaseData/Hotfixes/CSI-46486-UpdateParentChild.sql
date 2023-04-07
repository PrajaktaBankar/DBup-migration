--Execute this script on server 2
Use [SLCProject]
GO
--2 Rows should affected
UPDATE pss set pss.parentSegmentStatusId = 613167918 , pss.IndentLevel = 5
from ProjectSegmentStatus pss with(nolock) where pss.ProjectId = 10728 
AND pss.SectionId = 12953348 and pss.SegmentStatusId in (613166013, 613167851)