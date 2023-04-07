--Execute It On Server 3

--Customer Support 29607: Exported Files list in downloads sits and spins indefinitely ( PPL = 42123 / Admin ID = 827 / SERVER 3 )

select ProjectExportId,FileName,ProjectId,ProjectExportTypeId,CreatedDate,
CreatedBy,CreatedByFullName,FileExportTypeId,CustomerId,ProjectName,FileStatus
from projectexport PE WITH (NOLOCK) 
where filestatus='In Progress'
order by createdDate desc


--11 records should updated
update PE set filestatus='Failed' from projectexport PE WITH (NOLOCK)
where  FileStatus='In Progress' AND
ProjectExportId IN (3763,3723,3722,3721,3720,3706,3607,3600,3434,3288,2664)