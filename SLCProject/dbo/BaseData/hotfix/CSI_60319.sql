/*
 server name : SLCProject_SqlSlcOp003 ( Server 03)
 Customer Support 60319: SLC- Duplicate links are not allowed error
*/
	
	 update PSL 
	set isdeleted=1
	FROM projectsegmentlink PSL with (nolock)
	where SegmentLinkId=109320088