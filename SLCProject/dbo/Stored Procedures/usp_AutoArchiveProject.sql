CREATE PROCEDURE [dbo].[usp_AutoArchiveProject]
AS
BEGIN

	--Run this script on Archive server

	DECLARE @TableRows AS INT, @Records AS INT, @SLC_CustomerId AS INT, @TenantId AS INT
	DROP TABLE IF EXISTS #Staging_CustomerProjectList
	CREATE TABLE #Staging_CustomerProjectList
	(
		RowNumber INT NOT NULL IDENTITY(1,1),
		CustomerId INT NULL,
		ProjectId INT NULL,
		ProjectName NVARCHAR(500),
		IsOfficeMaster INT NULL,
		UserId INT NULL,
		ProjectAccessTypeId INT NULL,
		TenantId INT NULL,
		OwnerId INT NULL
	)

	SELECT @TenantId = TenantDbServerId FROM [SLCADMIN].[Authentication].[dbo].[LuTenantDbServer] WITH (NOLOCK)
	WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName')
	
	--Insert records for SLC Server, EXCLUDE ISARCHIVED = 1 Records which means they are ArchiveExcluded
	INSERT INTO #Staging_CustomerProjectList
	SELECT A.CustomerId, A.ProjectId, A.[Name] AS ProjectName, A.IsOfficeMaster, A.UserId, B.ProjectAccessTypeId, @TenantId AS TenantId, B.OwnerId
	FROM [dbo].[Project] A WITH (NOLOCK)
	INNER JOIN [dbo].[ProjectSummary] B WITH (NOLOCK) ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId
	INNER JOIN UserFolder D WITH (NOLOCK) ON A.CustomerId = D.CustomerId AND A.ProjectId = D.ProjectId
	LEFT JOIN [SLCADMIN].[Authentication].[dbo].[ShareProject] C WITH (NOLOCK) ON A.CustomerId = C.SharedByCustomerId AND A.ProjectId = C.SharedProjectId
		AND ISNULL(C.IsActive, 0) = 1
	LEFT JOIN [dbo].[DocLibraryMapping] E ON A.CustomerId = E.CustomerId AND A.ProjectId = E.ProjectId AND ISNULL(E.IsDeleted, 0) = 0
	LEFT JOIN [dbo].[ExcludeFromAutoArchive] F ON A.CustomerId = F.CustomerId
	WHERE C.SharedByCustomerId IS NULL AND E.DocMappingId IS NULL AND F.CustomerId IS NULL
		AND ISNULL(A.IsDeleted, 0) = 0 AND ISNULL(A.IsArchived, 0) = 0 AND D.LastAccessed < GETDATE()-180 AND ISNULL(A.IsOfficeMaster, 0) = 0
	

	SELECT @TableRows = COUNT(*) FROM #Staging_CustomerProjectList
	SET @Records = 1

	WHILE @Records <= @TableRows
	BEGIN

		DECLARE @CustomerId AS INT, @IsOfficeMaster AS INT, @SlcProdProjectId AS INT, @SlcProjectName AS NVARCHAR(500), @UserId AS INT, @IsArchiveExcluded AS BIT = 0
		DECLARE @ArchiveServerId AS INT, @ModifiedByUserName AS NVARCHAR(500)='SYSTEM', @ProjectAccessTypeId AS INT, @OwnerId AS INT

		SELECT @ArchiveServerId = ArchiveDbServerId FROM [SLCADMIN].[Authentication].[dbo].[LuArchiveDbServer] WITH (NOLOCK) WHERE IsDefault = 1

		SELECT @CustomerId = CustomerId, @SlcProdProjectId = ProjectId, @SlcProjectName = ProjectName, @IsOfficeMaster = IsOfficeMaster
			,@UserId = UserId, @ProjectAccessTypeId = ProjectAccessTypeId, @OwnerId = OwnerId FROM #Staging_CustomerProjectList WHERE RowNumber = @Records

		--AutoArchive feature -- UnLock Sections before archiving
		UPDATE PS SET PS.IsLocked=0, PS.IsLockedImportSection=0, PS.LockedBy=0, PS.LockedByFullName=''
		FROM [dbo].[ProjectSection] PS WITH (NOLOCK)
		WHERE PS.ProjectId = @SlcProdProjectId AND PS.CustomerId = @CustomerId

		--Insert records into [SLCProject].[dbo].[UserPreference] for Users that are not part of this table yet for Name as IsShowArchiveProjectNotification
		INSERT INTO [dbo].[UserPreference]
		SELECT A.UserId, A.CustomerId, 'IsShowArchiveProjectNotification' AS [Name], 'false' AS [Value], GETUTCDATE() AS CreatedDate, NULL AS ModifiedDate
		FROM [SLCADMIN].[Authentication].[dbo].[User] A WITH (NOLOCK)
		INNER JOIN [SLCADMIN].[Authentication].[dbo].[UserRole] ur WITH(NOLOCK) ON A.UserId = ur.UserId
		LEFT JOIN [dbo].[UserPreference] B WITH (NOLOCK) ON A.CustomerId = B.CustomerId AND A.UserId = B.UserId AND B.[Name] = 'IsShowArchiveProjectNotification'
		WHERE A.CustomerId = @CustomerId AND A.IsActive = 1 AND ISNULL(A.IsDeleted, 0) = 0 AND ur.ModuleId = 4 AND B.UserId IS NULL

		--Update record into UserPreference to True for Name as IsShowArchiveProjectNotification where Project IS NOT Hidden
		IF @ProjectAccessTypeId <> 3
		BEGIN
			UPDATE A SET [Value] = 'true'
			FROM [dbo].[UserPreference] A WITH (NOLOCK)
			WHERE CustomerId = @CustomerId AND [Name] = 'IsShowArchiveProjectNotification'
		END
		ELSE
		BEGIN
			--Update Value to True for Name as IsShowArchiveProjectNotification where User is SystemManager/CustomerAdmin even if the project is of Type Hidden
			UPDATE B SET [Value] = 'true'
			FROM [dbo].[UserPreference] B WITH (NOLOCK)
			INNER JOIN [SLCADMIN].[Authentication].[dbo].[User] A WITH (NOLOCK) ON B.CustomerId = A.CustomerId AND B.UserId = A.UserId
			INNER JOIN [SLCADMIN].[Authentication].[dbo].[UserRole] ur WITH(NOLOCK) ON A.UserId = ur.UserId
			INNER JOIN [SLCADMIN].[Authentication].[dbo].[luRoleType] rt WITH (NOLOCK) ON ur.RoleTypeId = rt.UserRoleTypeId
			WHERE B.[Name] = 'IsShowArchiveProjectNotification' AND B.CustomerId = @CustomerId AND A.IsActive = 1 AND ISNULL(A.IsDeleted, 0) = 0 AND ur.ModuleId = 4
			AND rt.[Name] = 'CustomerAdmin'

			--Update Value to True for Name as IsShowArchiveProjectNotification where User is Owner for the Hidden projects
			UPDATE B SET [Value] = 'true'
			FROM [dbo].[UserPreference] B WITH (NOLOCK)
			WHERE CustomerId = @CustomerId AND UserId = @OwnerId AND [Name] = 'IsShowArchiveProjectNotification'

			--Update Value to True for Name as IsShowArchiveProjectNotification where User is part of Team who is allowed to see Hidden projects
			UPDATE A SET [Value] = 'true'
			FROM [dbo].[UserPreference] A WITH (NOLOCK)
			INNER JOIN [dbo].[UserProjectAccessMapping] AS B WITH(NOLOCK) ON A.CustomerId = B.CustomerId AND A.UserId = B.UserId
			WHERE A.CustomerId = @CustomerId AND B.ProjectId = @SlcProdProjectId AND ISNULL(B.IsActive, 0) = 1 AND A.[Name] = 'IsShowArchiveProjectNotification'

		END

		EXECUTE [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[usp_ArchiveActiveProject] @CustomerId, @IsOfficeMaster, @SlcProdProjectId, @SlcProjectName, @UserId, @IsArchiveExcluded, @TenantId, @ArchiveServerId, @ModifiedByUserName, @ProjectAccessTypeId
 
		SET @Records += 1;
	END
END
GO


