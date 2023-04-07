
--Customer Support 65080: SLC Unable to Remove Page Break
--Server 4

update pss 
set pss.IsPageBreak = 0 from ProjectSegmentStatus pss WITH (NOLOCK)
where pss.SegmentStatusId =1499334143

