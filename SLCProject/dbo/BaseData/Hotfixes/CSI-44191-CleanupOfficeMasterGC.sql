use SLCProject
go
/*
Customer Support 44191: SLC Fail Message When Creating a New Project
Run on server 2
*/

declare @CustomerID int=341
declare @CopySourceProjectID int=7259



drop table if exists #tmpOfficeMasterGC
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
from dbo.ProjectGlobalTerm with (nolock) where CustomerId=@CustomerID and ProjectId=@CopySourceProjectID and UserGlobalTermId is not null

drop table if exists #tmpCustomerUserGlobalTerm
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
from dbo.UserGlobalTerm with (nolock) where CustomerId=@CustomerID


select og.UserGlobalTermId, og.[name], og.[Value], og.CreatedDate, og.CreatedBy, og.CustomerId, og.Projectid, og.IsDeleted, NULL from #tmpOfficeMasterGC og
left outer join #tmpCustomerUserGlobalTerm cg on cg.UserGlobalTermId=og.UserGlobalTermId
where cg.UserGlobalTermId is null


set identity_insert dbo.userglobalterm on

Insert into dbo.UserGlobalTerm (UserGlobalTermId, [Name], [Value], CreatedDate, CreatedBy, CustomerId, ProjectId, IsDeleted, A_UserGlobalTermId)
select og.UserGlobalTermId, og.[name], og.[Value], og.CreatedDate, og.CreatedBy, og.CustomerId, og.Projectid, og.IsDeleted, NULL from #tmpOfficeMasterGC og
left outer join #tmpCustomerUserGlobalTerm cg on cg.UserGlobalTermId=og.UserGlobalTermId
where cg.UserGlobalTermId is null

set identity_insert dbo.userglobalterm off


