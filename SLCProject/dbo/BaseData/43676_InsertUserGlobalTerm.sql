use SLCProject
go

/*
Customer Support 43676: Creating project from master fails
Run on server 4
*/

--select * from dbo.UserGlobalTerm with (nolock) where CustomerId=3003 
--select * from dbo.ProjectGlobalTerm with (nolock) where CustomerId=3003  and mGlobalTermId is null
--select * from dbo.ProjectGlobalTerm with (nolock) where CustomerId=3003  and mGlobalTermId is null and projectid=6037
--select * from dbo.UserGlobalTerm where UserGlobalTermid = 787


set identity_insert dbo.userglobalterm on

insert into UserGlobalTerm( [UserGlobalTermId]
      ,[Name]
      ,[Value]
      ,[CreatedDate]
      ,[CreatedBy]
      ,[CustomerId]
      ,[ProjectId]
      ,[IsDeleted]
      ,[A_UserGlobalTermId])
values (787, 'Pursuit Number', 'P67 24', GETUTCDATE(), 340, 3003, NULL, 1, NULL),(788, 'PLD Pursuit Number', '4576', GETUTCDATE(), 340, 3003, NULL, 1, NULL)

set identity_insert dbo.userglobalterm off
