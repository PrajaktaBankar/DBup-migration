--Add new Reference standards for existing projects( excluded permenently deleted)
--Project type USA master and Canada Master

--GT List
--• Design Professional’s Project Number
--• Construction Manager
--• Construction Manager’s Project Number
--• Design-Builder’s Project Number
--• Date of Substantial Completion



--Get All non deleted projects into temp table
select ProjectId,CustomerId,MasterDataTypeId into #t from Project p with(nolock) where isnull(IsPermanentDeleted,0)=0
and MasterDataTypeId = 1

--insert into 
insert into ProjectGlobalTerm(mGlobalTermId,ProjectId,CustomerId,[Name],[value],
	GlobalTermSource,GlobalTermCode,CreatedDate,CreatedBy,IsDeleted,GlobalTermFieldTypeId)
select m.GlobalTermId,t.ProjectId,t.CustomerId,m.[Name],m.[Value], 
	'M',m.GlobalTermCode,m.CreateDate,0,0,m.GlobalTermFieldTypeId	
from SLCMaster..GlobalTerm m with(nolock) 
CROSS JOIN #t t
left outer join ProjectGlobalTerm pgt with(nolock)
ON pgt.ProjectId=t.ProjectId
and pgt.mGlobalTermId=m.GlobalTermId
where m.GlobalTermId in(23,24,25,26,27) --IMP Please make sure that the Id's are matching with the SLCMaster Global term List
and pgt.GlobalTermId is null
--order by t.ProjectId,m.GlobalTermId
