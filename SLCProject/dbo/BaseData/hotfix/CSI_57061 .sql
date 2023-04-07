/*
 server name : SLCProject_SqlSlcOp004
 Customer Support 57061: SLC Import from Project does not list any projects 
*/

DROP TABLE IF EXISTS #UserFolder
select 1 as FolderTypeId,ProjectId,UserId,getutcdate() as LastAccessed, customerId,'Lisa Murray'  as LastAccessByFullName
INTO #UserFolder from Project P WITH(NOLOCK)
where customerid = 1845 --and Projectid <>14493

INSERT INTO UserFolder select * from #UserFolder
