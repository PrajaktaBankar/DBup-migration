


CREATE PROCEDURE [dbo].[sp_ProjectTransferJob]
AS
BEGIN
  
	DECLARE @ErrorCode INT = 0
	DECLARE @Return_Message VARCHAR(1024)
	DECLARE @ErrorStep VARCHAR(50)
	DECLARE @NumberRecords int, @RowCount int
	DECLARE @RequestId AS INT

	IF OBJECT_ID('tempdb..#tmpProjectTransferQueue') IS NOT NULL DROP TABLE #tmpProjectTransferQueue
	CREATE TABLE #tmpProjectTransferQueue
	(
		RowID					INT IDENTITY(1, 1), 
		TransferRequestId		INT NULL,
		ProjectName				NVARCHAR(500) NULL,
		SourceCustomerId		INT NOT NULL,
		SourceProjectId			INT NOT NULL,
		SourceServerId			INT NOT NULL,
		SourceUserId			INT NULL,
		TargetCustomerId		INT NOT NULL,
		TargetProjectId			INT NULL,
		TargetServerId			INT NOT NULL,
		TargetUserId			INT NULL,
		RequestDate				DATETIME NULL,
		StatusId				INT NULL,
		IsProcessed				BIT NULL DEFAULT((0))
	)
	
	DECLARE @IsProjectTransferFailed AS INT = 0

	INSERT INTO #tmpProjectTransferQueue (TransferRequestId,ProjectName,SourceCustomerId,SourceProjectId,SourceServerId,SourceUserId,TargetCustomerId
		,TargetProjectId,TargetServerId,TargetUserId,RequestDate,StatusId,IsProcessed)
	SELECT PT.TransferRequestId,PT.ProjectName,PT.SourceCustomerId,PT.SourceProjectId,PT.SourceServerId,PT.SourceUserId,PT.TargetCustomerId
		,PT.TargetProjectId,PT.TargetServerId,PT.TargetUserId,PT.RequestDate,PT.StatusId,0 AS IsProcessed
	FROM [SLCADMIN].[SLCProjectShare].[dbo].[ProjectTransferQueue] PT WITH (NOLOCK)
	INNER JOIN [SLCADMIN].[Authentication].[dbo].[CustomerTenantDbServer] CS ON CS.CustomerId = PT.TargetCustomerId 
		AND PT.TargetServerId IN (SELECT TenantDbServerId FROM [SLCADMIN].[Authentication].[dbo].[LuTenantDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName'))
	WHERE PT.StatusId = 1 --Project Transfer Queued
		AND PT.TargetServerId IN (SELECT TenantDbServerId FROM [SLCADMIN].[Authentication].[dbo].[LuTenantDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName'))

	-- Get the number of records in the temporary table
	SET @NumberRecords = @@ROWCOUNT
	SET @RowCount = 1

	WHILE @RowCount <= @NumberRecords
	BEGIN
		--Set IsProjectMigrationFailed to 0 to reset it
		SET @IsProjectTransferFailed = 0

		DECLARE @TransferRequestId INT, @ProjectName NVARCHAR(500), @SourceCustomerID INT, @SourceProjectID INT, @SourceServerId INT, @SourceUserId INT, @TargetCustomerID INT, @TargetProjectID INT, @TargetServerId INT, @TargetUserId INT
			,@IsProcessed INT, @SameServerId AS INT = 0, @CustomerName AS NVARCHAR(200), @SourceUserEmail AS NVARCHAR(500), @TargetUserEmail AS NVARCHAR(500)
		--Get next ProjectId
		SELECT @TransferRequestId = TransferRequestId, @ProjectName = ProjectName, @SourceCustomerID = SourceCustomerID, @SourceProjectID = SourceProjectID, @SourceServerId = SourceServerId, @SourceUserId = SourceUserId
			,@TargetCustomerID = TargetCustomerID, @TargetServerId = TargetServerId, @TargetUserId = TargetUserId
		FROM #tmpProjectTransferQueue WHERE RowID = @RowCount AND IsProcessed = 0

		SELECT @SameServerId = TenantDbServerId FROM [SLCADMIN].[Authentication].[dbo].[LuTenantDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName')
		SELECT @CustomerName = [Name] FROM [SLCAdmin].[Authentication].[dbo].[Customer] WITH (NOLOCK) WHERE CustomerId = @TargetCustomerID

		--Insert record into CopyProjectRequest
		INSERT INTO [SLCProject].[dbo].[CopyProjectRequest]
		(SourceProjectId,TargetProjectId,CreatedById,CustomerId,CreatedDate,ModifiedDate,[StatusId],CompletedPercentage,IsNotify,IsDeleted,IsEmailSent,CustomerName,UserName,CopyProjectTypeId
			,TransferRequestId)
		VALUES (@SourceProjectID,0,@TargetUserID,@TargetCustomerID,GETUTCDATE(),NULL,1,0,0,0,0,@CustomerName,'',2,@TransferRequestId);

		----Insert record into ProjectTransferRequest
		--INSERT INTO [SLCProject].[dbo].[ProjectTransferRequest]
		--([SourceCustomerId],[SourceProjectId],[SourceServerId],[TargetCustomerId],[TargetProjectId],[TargetSLCServerId],[ProjectName],[TargetUserId],[RequestDate]
		--	,[ModifiedDate],[StatusId],[IsNotify],[ProgressInPercentage],[EmailFlag],[IsDeleted],[StartTime],[EndTime])
		--VALUES (@SourceCustomerID, @SourceProjectID, @SourceServerID, @TargetCustomerID, NULL, @TargetServerId, @ProjectName, @TargetUserId
		--			,GETUTCDATE(), GETUTCDATE(), 1, NULL, NULL, NULL, 0, NULL, NULL)

		--Call Project Transfer procedure depend on the SLCServer mapping
		IF @SourceServerId = @SameServerId
		BEGIN
			EXECUTE [SLCProject].[dbo].[sp_ProjectTransfer_SameServer] @TransferRequestId, @ProjectName, @SourceCustomerID, @SourceProjectID, @SourceServerId, @TargetCustomerID, @TargetUserId, @TargetServerId, @TargetProjectID OUTPUT
		END
		ELSE IF @SourceServerId = 2
		BEGIN
			EXECUTE [SLCProject].[dbo].[sp_ProjectTransfer_SLCSERVER01] @TransferRequestId, @ProjectName, @SourceCustomerID, @SourceProjectID, @SourceServerId, @TargetCustomerID, @TargetUserId, @TargetServerId, @TargetProjectID OUTPUT
		END
		ELSE IF @SourceServerId = 3
		BEGIN
			EXECUTE [SLCProject].[dbo].[sp_ProjectTransfer_SLCSERVER02] @TransferRequestId, @ProjectName, @SourceCustomerID, @SourceProjectID, @SourceServerId, @TargetCustomerID, @TargetUserId, @TargetServerId, @TargetProjectID OUTPUT
		END
		ELSE IF @SourceServerId = 4
		BEGIN
			EXECUTE [SLCProject].[dbo].[sp_ProjectTransfer_SLCSERVER03] @TransferRequestId, @ProjectName, @SourceCustomerID, @SourceProjectID, @SourceServerId, @TargetCustomerID, @TargetUserId, @TargetServerId, @TargetProjectID OUTPUT
		END
		ELSE IF @SourceServerId = 5
		BEGIN
			EXECUTE [SLCProject].[dbo].[sp_ProjectTransfer_SLCSERVER04] @TransferRequestId, @ProjectName, @SourceCustomerID, @SourceProjectID, @SourceServerId, @TargetCustomerID, @TargetUserId, @TargetServerId, @TargetProjectID OUTPUT
		END
		ELSE IF @SourceServerId = 6
		BEGIN
			EXECUTE [SLCProject].[dbo].[sp_ProjectTransfer_SLCSERVER05] @TransferRequestId, @ProjectName, @SourceCustomerID, @SourceProjectID, @SourceServerId, @TargetCustomerID, @TargetUserId, @TargetServerId, @TargetProjectID OUTPUT
		END
		ELSE IF @SourceServerId = 8
		BEGIN
			EXECUTE [SLCProject].[dbo].[sp_ProjectTransfer_SLCSERVER07] @TransferRequestId, @ProjectName, @SourceCustomerID, @SourceProjectID, @SourceServerId, @TargetCustomerID, @TargetUserId, @TargetServerId, @TargetProjectID OUTPUT
		END

		EXEC [SLCADMIN].[SLCProjectShare].[dbo].[usp_SendEmailTransferProjectJob] @TransferRequestId

		--Update Processed to 1
		UPDATE A
		SET A.IsProcessed = 1
		FROM #tmpProjectTransferQueue A
		WHERE TransferRequestId = @TransferRequestId

		SET @RowCount = @RowCount + 1
	END

	DROP TABLE #tmpProjectTransferQueue;
END