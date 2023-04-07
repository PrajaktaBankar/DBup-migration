
CREATE PROCEDURE [dbo].[sp_ArchiveProject_Arch02]
AS
BEGIN
  
	DECLARE @ErrorCode INT = 0
	DECLARE @Return_Message NVARCHAR(MAX)
	DECLARE @ErrorStep VARCHAR(50)
	DECLARE @NumberRecords int, @RowCount int

	IF OBJECT_ID('tempdb..#tmpArchiveProjects') IS NOT NULL DROP TABLE #tmpArchiveProjects
	CREATE TABLE #tmpArchiveProjects
	(
		RowID					INT IDENTITY(1, 1), 
		SLC_CustomerId			INT NOT NULL,
		SLC_ArchiveProjectId	INT NOT NULL,
		SLC_ProdProjectId		INT NULL,
		SLC_ServerId			INT NULL,
		IsProcessed				BIT NULL DEFAULT ((0))
	)

	INSERT INTO #tmpArchiveProjects (SLC_CustomerId, SLC_ArchiveProjectId, SLC_ProdProjectId, SLC_ServerId, IsProcessed)
	SELECT SLC_CustomerId, ISNULL(SLC_ArchiveProjectId, 0) AS SLC_ArchiveProjectId, SLC_ProdProjectId, SLC_ServerId
		, 0 AS IsProcessed
	FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] AP WITH (NOLOCK)
	WHERE AP.IsArchived = 1 AND AP.InProgressStatusId = 1 --ArchiveInitiated --(SELECT [InProgressStatusId] FROM [DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'ArchiveInitiated')
		AND AP.ProcessInitiatedById = 3--SLC --(SELECT [ProcessInitiatedById] FROM [DE_Projects_Staging].[dbo].[LuProcessInitiatedBy] WHERE [Description] = 'SLC')
		AND AP.DisplayTabId = 2--ArchivedTab
		AND AP.[IsArchiveExcluded] = 0
		AND AP.Archive_ServerId IN (SELECT [ArchiveDbServerId] FROM [SLCADMIN].[Authentication].[dbo].[LuArchiveDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName'))
	ORDER BY SLC_CustomerId, SLC_ArchiveProjectId

	-- Get the number of records in the temporary table
	SET @NumberRecords = @@ROWCOUNT
	SET @RowCount = 1

	-- loop through all records in the temporary table using the WHILE loop construct
	WHILE @RowCount <= @NumberRecords
	BEGIN
		DECLARE @NumberProjects int, @ProjectCount int

		DECLARE @SLC_CustomerId INT, @Old_SLC_ArchiveProjectId INT, @SLC_ProdProjectId INT, @SLC_ServerId INT, @ServerName AS VARCHAR(50)
		--Get next CycleID
		SELECT @SLC_CustomerId = SLC_CustomerId, @Old_SLC_ArchiveProjectId = SLC_ArchiveProjectId, @SLC_ProdProjectId = SLC_ProdProjectId, @SLC_ServerId = SLC_ServerId
		FROM #tmpArchiveProjects WHERE RowID = @RowCount AND IsProcessed = 0

		IF @SLC_ServerId = 1
		BEGIN
			EXECUTE [dbo].[sp_ArchiveProject_SLC01] @SLC_CustomerId, @Old_SLC_ArchiveProjectId, @SLC_ProdProjectId
		END
		ELSE IF @SLC_ServerId = 2
		BEGIN
			EXECUTE [dbo].[sp_ArchiveProject_SLC01] @SLC_CustomerId, @Old_SLC_ArchiveProjectId, @SLC_ProdProjectId
		END
		ELSE IF @SLC_ServerId = 3
		BEGIN
			EXECUTE [dbo].[sp_ArchiveProject_SLC02] @SLC_CustomerId, @Old_SLC_ArchiveProjectId, @SLC_ProdProjectId
		END
		ELSE IF @SLC_ServerId = 4
		BEGIN
			EXECUTE [dbo].[sp_ArchiveProject_SLC03] @SLC_CustomerId, @Old_SLC_ArchiveProjectId, @SLC_ProdProjectId
		END
		ELSE IF @SLC_ServerId = 5
		BEGIN
			EXECUTE [dbo].[sp_ArchiveProject_SLC04] @SLC_CustomerId, @Old_SLC_ArchiveProjectId, @SLC_ProdProjectId
		END
		ELSE IF @SLC_ServerId = 6
		BEGIN
			EXECUTE [dbo].[sp_ArchiveProject_SLC05] @SLC_CustomerId, @Old_SLC_ArchiveProjectId, @SLC_ProdProjectId
		END
		ELSE IF @SLC_ServerId = 8
		BEGIN
			EXECUTE [dbo].[sp_ArchiveProject_SLC07] @SLC_CustomerId, @Old_SLC_ArchiveProjectId, @SLC_ProdProjectId
		END
		
		--Update Processed to 1
		UPDATE U SET U.IsProcessed = 1 FROM #tmpArchiveProjects U WHERE U.SLC_CustomerId = @SLC_CustomerId AND U.SLC_ProdProjectId = @SLC_ProdProjectId;

		SET @RowCount = @RowCount + 1
	END

	DROP TABLE #tmpArchiveProjects
END

GO




