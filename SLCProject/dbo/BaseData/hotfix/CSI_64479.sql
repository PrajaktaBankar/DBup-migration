--Customer Support 64479: Data Fix required for section with hidden level 3 paragraph - 53494/158
--Server 3 

update pss set pss.ParentSegmentStatusId = 1033128980, pss.IsParentSegmentStatusActive = 1  from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 1033128071
update pss set pss.ParentSegmentStatusId = 1033128980  from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId in( 1033128139, 1033128057, 1033127800, 1033128086)

