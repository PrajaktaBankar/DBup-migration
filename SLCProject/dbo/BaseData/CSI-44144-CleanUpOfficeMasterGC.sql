use SLCProject_SqlSlcOp002
go
/*
Customer Support 44144: SLC User Cannot Create New Project from their Office Master

*/

select [GlobalTermId]
      ,[mGlobalTermId]
      ,[ProjectId]
      ,[CustomerId]
      ,[Name]
      ,[value]
      ,[GlobalTermSource]
      ,[GlobalTermCode]
      ,[CreatedDate]
      ,[CreatedBy]
      ,[ModifiedDate]
      ,[ModifiedBy]
      ,[SLE_GlobalChoiceID]
      ,[UserGlobalTermId]
      ,[IsDeleted]
      ,[A_GlobalTermId]
      ,[GlobalTermFieldTypeId]
      ,[OldValue] 
into #tmpOfficeMasterGC
from dbo.ProjectGlobalTerm with (nolock) where CustomerId=1211 and ProjectId=7248 and UserGlobalTermId is not null

select  [UserGlobalTermId]
      ,[Name]
      ,[Value]
      ,[CreatedDate]
      ,[CreatedBy]
      ,[CustomerId]
      ,[ProjectId]
      ,[IsDeleted]
      ,[A_UserGlobalTermId] 
into #tmpCustomerUserGlobalTerm
from dbo.UserGlobalTerm with (nolock) where CustomerId=1211

--select * from dbo.UserGlobalTerm where CustomerId=1211

--select * from #tmpOfficeMasterGC og
--left outer join #tmpCustomerUserGlobalTerm cg on cg.UserGlobalTermId=og.UserGlobalTermId
--where cg.UserGlobalTermId is null

select og.UserGlobalTermId, og.[name], og.[Value], og.CreatedDate, og.CreatedBy, og.CustomerId, og.Projectid, og.IsDeleted, NULL from #tmpOfficeMasterGC og
left outer join #tmpCustomerUserGlobalTerm cg on cg.UserGlobalTermId=og.UserGlobalTermId
where cg.UserGlobalTermId is null


set identity_insert dbo.userglobalterm on

Insert into dbo.UserGlobalTerm (UserGlobalTermId, [Name], [Value], CreatedDate, CreatedBy, CustomerId, ProjectId, IsDeleted, A_UserGlobalTermId)
select og.UserGlobalTermId, og.[name], og.[Value], og.CreatedDate, og.CreatedBy, og.CustomerId, og.Projectid, og.IsDeleted, NULL from #tmpOfficeMasterGC og
left outer join #tmpCustomerUserGlobalTerm cg on cg.UserGlobalTermId=og.UserGlobalTermId
where cg.UserGlobalTermId is null

set identity_insert dbo.userglobalterm off

--- trying to copy the office master which has records in headerfooterglobaltermusage but not in header
--- This results in FK insert error

SELECT hg.headerid, h.headerid FROM dbo.HeaderFooterGlobalTermUsage hg with (nolock)
	left outer join dbo.Header h (nolock) on h.HeaderId=hg.HeaderId 
WHERE hg.ProjectId=7248 and h.HeaderId is null

delete HeaderFooterGlobalTermUsage 
FROM dbo.HeaderFooterGlobalTermUsage hg
	left outer join dbo.Header h on h.HeaderId=hg.HeaderId 
WHERE hg.ProjectId=7248 and h.HeaderId is null
