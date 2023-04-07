	/*
	server Name : SLCProject_SqlSlcOp004
	Customer Support 30354: Cannot Open Migrated Project
	*/
	
	update pss 
	set isdeleted =1 
	from projectsegmentstatus pss with (Nolock)
	where projectid=302 and CustomerId=1431 and SectionId in (347032) and ParentSegmentStatusId=0 and segmentid=1650348
	
	update pss 
	set isdeleted =1 
	from projectsegmentstatus pss with (Nolock)
	where projectid=302 and CustomerId=1431 and SectionId in (347031) and ParentSegmentStatusId=0 and segmentid=1650349

	update pss 
	set isdeleted =1 
	from projectsegmentstatus pss with (Nolock)
	where projectid=302 and CustomerId=1431 and SectionId in (347031) and ParentSegmentStatusId=0 and segmentstatusid=10219279

	update pss 
	set isdeleted =1 
	from projectsegmentstatus pss with (Nolock)
	where projectid=302 and CustomerId=1431 and SectionId in (347032) and ParentSegmentStatusId=0 and segmentid is null