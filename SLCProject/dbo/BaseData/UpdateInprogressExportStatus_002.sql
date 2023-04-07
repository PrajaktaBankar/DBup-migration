--Execute It On Server 2

--Customer Support 29250: Continuous Export in SLC

select ProjectExportId,FileName,
ProjectId,
ProjectExportTypeId,
CreatedDate,CreatedBy,CreatedByFullName,FileExportTypeId,CustomerId,ProjectName,FileStatus
from projectexport WITH (NOLOCK)
where filestatus='In Progress' 
order by createdDate desc


--10 records should updated
update PE set filestatus='Failed' from projectexport PE WITH (NOLOCK)
where  FileStatus='In Progress' AND
ProjectExportId IN (7132,6962,5304,5101,4271,4135,3890,2173,2172,1962)

