DECLARE @totalProjects int=0
DECLARE @cnt INT=1
DECLARE @IsArchived INT = 1
DECLARE @ArchiveInitiated INT =1
DECLARE @SLC INT =3 
DECLARE @ArchivedTab INT = 2
DECLARE @ArchiveProjectId INT = 0
DECLARE @IsArchiveExcluded BIT=1
DECLARE @Tenant INT=2
DECLARE @ArchiveServerId INT=1
DECLARE @LastAccessed DATETIME

drop TABLE if EXISTS #ArchivedProjects

SELECT ROW_NUMBER() over(order by p.ProjectId) as RowNumber,
p.CustomerId,u.UserId,p.Name,p.ProjectId,
p.IsOfficeMaster,u.UserId as Archived_By,u.[LastAccessByFullName],
u.[LastAccessed],ps.ProjectAccessTypeId
into #ArchivedProjects 
FROM [dbo].Project p with(NOLOCK) 
INNER JOIN UserFolder u WITH(NOLOCK)
ON u.ProjectId=p.ProjectId
INNER JOIN ProjectSummary ps WITH(NOLOCK)
ON ps.ProjectId=p.ProjectId
WHERE p.IsShowMigrationPopup = 0 AND 
ISNULL(p.IsPermanentDeleted,0)=0 and 
ISNULL(P.isArchived,0)=1


Select top 1 @Tenant = tenantDbServerId from [SLCADMIN].[Authentication].dbo.CustomerTenantDbServer CTD with(nolock)
inner join #ArchivedProjects AP ON CTD.CustomerId = AP.CustomerId

DECLARE @CustomerId INT,
	@IsOfficeMaster INT=0,
	@SlcProdProjectId INT,
	@SlcProjectName NVARCHAR(500),
	@UserId INT,
	@ModifiedByUserName NVARCHAR(500)='',
	@ProjectAccessTypeId INT = NULL

set @ArchiveInitiated=iif(@IsArchiveExcluded=1,null,@ArchiveInitiated)

SELECT @totalProjects=count(1) from #ArchivedProjects
while(@cnt<=@totalProjects)
BEGIN
	
	SELECT @CustomerId=CustomerId,@IsOfficeMaster=IsOfficeMaster,@SlcProjectName=Name,@SlcProdProjectId=ProjectId,
	@ModifiedByUserName=LastAccessByFullName,@ProjectAccessTypeId=ProjectAccessTypeId,@UserId=UserId,
	@LastAccessed=[LastAccessed]
	from #ArchivedProjects where RowNumber=@cnt

	set @ArchiveProjectId = (SELECT top 1 ArchiveProjectId from ARCHIVESERVER01.DE_Projects_Staging.dbo.[ArchiveProject] WITH(NOLOCK) where SLC_CustomerId=@CustomerId and SLC_ProdProjectId=@SlcProdProjectId and SLC_ServerId=@Tenant and Archive_ServerId=@ArchiveServerId)
	IF(ISNULL(@ArchiveProjectId,0)>0)
	BEGIN
			update ap
			set ap.SLC_UserId=@UserId,
				ap.Name=@SlcProjectName,
				ap.IsArchived=@IsArchived,
				ap.InProgressStatusId=@ArchiveInitiated,
				ap.ProcessInitiatedById=@SLC,
				ap.DisplayTabId=@ArchivedTab,
				ap.IsArchiveExcluded=@IsArchiveExcluded,
				ap.Archived_By=@ModifiedByUserName,
				ap.ArchiveTimeStamp=@LastAccessed,
				ap.ProjectAccessTypeId=@ProjectAccessTypeId,
				ap.SLC_ServerId=@Tenant,
				ap.Archive_ServerId=@ArchiveServerId
			from ARCHIVESERVER01.DE_Projects_Staging.dbo.[ArchiveProject] ap WITH(NOLOCK)
			where ArchiveProjectId=@ArchiveProjectId
			and SLC_CustomerId=@CustomerId 
			and SLC_ProdProjectId=@SlcProdProjectId
			--print 'update'
	END
	ELSE
	BEGIN
		INSERT INTO ARCHIVESERVER01.DE_Projects_Staging.dbo.[ArchiveProject] (SLC_CustomerId, SLC_UserId, Name, SLC_ProdProjectId,
		InProgressStatusId, ProcessInitiatedById, DisplayTabId, IsArchived,IsArchiveExcluded,
		IsOfficeMaster,Archived_By,ArchiveTimeStamp,ProjectAccessTypeId,SLC_ServerId,Archive_ServerId)
		VALUES (@customerId, @UserId, @SlcProjectName, @SlcProdProjectId,
		 @ArchiveInitiated, @SLC, @ArchivedTab, @IsArchived,@IsArchiveExcluded,
		 @IsOfficeMaster,@ModifiedByUserName,@LastAccessed,@ProjectAccessTypeId,@Tenant,@ArchiveServerId)

	END
	set @cnt=@cnt+1
END
