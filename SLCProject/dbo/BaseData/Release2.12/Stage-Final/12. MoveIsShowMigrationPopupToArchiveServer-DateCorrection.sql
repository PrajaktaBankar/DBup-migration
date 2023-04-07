USE SLCProject
GO

DROP TABLE if EXISTS #t
DROP TABLE if EXISTS #Result

SELECT p.ProjectId,p.CustomerId,p.Name,p.IsOfficeMaster,p.IsDeleted,p.IsArchived,u.[LastAccessByFullName],
p.ModifiedDate,p.ModifiedByFullName,u.[LastAccessed]
INTO #t 
FROM [dbo].Project p WITH(NOLOCK) inner join UserFolder u with(nolock)
ON p.ProjectId=u.ProjectId
WHERE p.IsShowMigrationPopup = 1 AND 
ISNULL(p.IsArchived,0)=1


SELECT ap.ArchiveProjectId,t.ProjectId,ap.[SLC_ArchiveProjectId],t.CustomerId,t.IsArchived,t.IsDeleted,t.LastAccessByFullName,
t.ModifiedDate,t.ModifiedByFullName,t.[LastAccessed] into #Result 
from #t t INNER JOIN ARCHIVESERVER01.DE_Projects_Staging.dbo.[ArchiveProject] ap WITH(NOLOCK)
ON t.ProjectId=ap.[SLC_ProdProjectId] AND t.customerId=ap.SLC_CustomerId
INNER JOIN ARCHIVESERVER01.SLCProject.dbo.[Project] p WITH(NOLOCK)
ON ap.[SLC_ArchiveProjectId]=p.ProjectId AND p.customerId=ap.SLC_CustomerId
--WHERE ISNULL(p.IsPermanentDeleted,0)=0


update ap
set ap.ArchiveTimeStamp=iif(r.IsArchived=1,r.[LastAccessed],ap.ArchiveTimeStamp)
from #Result r INNER JOIN ARCHIVESERVER01.DE_Projects_Staging.dbo.[ArchiveProject] ap WITH(NOLOCK)
ON r.ProjectId=ap.[SLC_ProdProjectId] AND r.customerId=ap.SLC_CustomerId
INNER JOIN ARCHIVESERVER01.SLCProject.dbo.[Project] p WITH(NOLOCK)
ON ap.[SLC_ArchiveProjectId]=p.ProjectId AND p.customerId=ap.SLC_CustomerId
