﻿CREATE PROCEDURE [dbo].[sp_UnArchiveMigratedCycles_SyncedMaster]  
AS  
BEGIN  
    
 DECLARE @ErrorCode INT = 0  
 DECLARE @Return_Message VARCHAR(1024)  
 DECLARE @ErrorStep VARCHAR(50)  
 DECLARE @NumberRecords int, @RowCount int  
 DECLARE @RequestId AS INT  
  
 IF OBJECT_ID('tempdb..#tmpUnArchiveCycleIDs') IS NOT NULL DROP TABLE #tmpUnArchiveCycleIDs  
 CREATE TABLE #tmpUnArchiveCycleIDs  
 (  
  RowID     INT IDENTITY(1, 1),   
  CycleID     BIGINT NULL,  
  CustomerID    INT NOT NULL,  
  SubscriptionID   INT NULL,   
  ProjectID    INT NOT NULL,  
  SLC_CustomerId   INT NOT NULL,  
  SLC_UserId    INT NOT NULL,  
  SLC_ArchiveProjectId INT NOT NULL,  
  SLC_ProdProjectId  INT NULL,  
  SLC_ServerId   INT NULL,  
  MigrateStatus   INT NULL,  
  CreatedDate    DATETIME NULL,  
  MovedDate    DATETIME NULL,  
  MigratedDate   DATETIME NULL,  
  IsProcessed    BIT NULL DEFAULT((0)),  
  Archive_ServerId  INT NOT NULL  
 )  
   
 DECLARE @IsProjectMigrationFailed AS INT = 0  
  
 INSERT INTO #tmpUnArchiveCycleIDs (CycleID, CustomerID, SubscriptionID, ProjectID, SLC_CustomerId, SLC_UserId, SLC_ArchiveProjectId, SLC_ProdProjectId, SLC_ServerId, MigrateStatus, MigratedDate, IsProcessed  
  ,Archive_ServerId)  
 SELECT AP.CycleID, AP.LegacyCustomerID, AP.LegacySubscriptionID, AP.LegacyProjectID, AP.SLC_CustomerId, AP.SLC_UserId, AP.SLC_ArchiveProjectId, AP.SLC_ProdProjectId, AP.SLC_ServerId, AP.MigrateStatus  
  ,AP.MigratedDate, 0 AS IsProcessed, AP.Archive_ServerId  
 FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] AP WITH (NOLOCK)  
 INNER JOIN [SLCADMIN].[Authentication].[dbo].[CustomerTenantDbServer] CS ON CS.CustomerId = AP.SLC_CustomerId   
  AND AP.SLC_ServerId IN (SELECT TenantDbServerId FROM [SLCADMIN].[Authentication].[dbo].[LuTenantDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName'))  
 WHERE AP.InProgressStatusId = 3 --UnArchiveInitiated  
  AND AP.ProcessInitiatedById IN (1,2) --SLE or SLEWeb  
  AND AP.MigrateStatus = 1 AND AP.DisplayTabId = 1 --MigratedTab  
  AND AP.IsArchived = 1  
  AND AP.SLC_ServerId IN (SELECT TenantDbServerId FROM [SLCADMIN].[Authentication].[dbo].[LuTenantDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName'))  
  
 -- Get the number of records in the temporary table  
 SET @NumberRecords = @@ROWCOUNT  
 SET @RowCount = 1  
  
 WHILE @RowCount <= @NumberRecords  
 BEGIN  
  --Set IsProjectMigrationFailed to 0 to reset it  
  SET @IsProjectMigrationFailed = 0  
  
  DECLARE @CustomerID INT, @SubscriptionID INT, @SLE_ProjectID INT, @MigrateStatus INT, @MigratedDate DATETIME, @SLC_CustomerId INT, @SLC_UserId INT, @ProjectID INT, @IsProcessed INT, @CycleID BIGINT  
   , @SLC_ServerId INT, @OldSLC_ProjectID INT, @Archive_ServerId INT  
  --Get next CycleID  
  SELECT @CustomerID = CustomerID, @SubscriptionID = SubscriptionID, @SLE_ProjectID = ProjectID, @SLC_CustomerId = SLC_CustomerId, @SLC_UserId = SLC_UserId, @CycleID = CycleID  
   ,@MigrateStatus = MigrateStatus, @ProjectID = SLC_ArchiveProjectId, @OldSLC_ProjectID = ISNULL(SLC_ProdProjectId, 0), @SLC_ServerId = SLC_ServerId, @MigratedDate = MigratedDate, @IsProcessed = IsProcessed  
   ,@Archive_ServerId = Archive_ServerId  
  FROM #tmpUnArchiveCycleIDs WHERE RowID = @RowCount AND IsProcessed = 0  
  
  --Call Unarchive Project for MigratedCycle procedure depend on the ArchiveServer mapping  
  IF @Archive_ServerId = 1  
  BEGIN  
   EXECUTE [SLCProject].[dbo].[sp_UnArchiveMigratedCycles_ArchServer01] @SLC_CustomerId, @SLC_UserId, @ProjectID, @OldSLC_ProjectID, @Archive_ServerId  
  END  
  ELSE IF @Archive_ServerId = 2  
  BEGIN  
   EXECUTE [SLCProject].[dbo].[sp_UnArchiveMigratedCycles_ArchServer02] @SLC_CustomerId, @SLC_UserId, @ProjectID, @OldSLC_ProjectID, @Archive_ServerId  
  END  
  
  --Update Processed to 1  
  UPDATE A  
  SET A.IsProcessed = 1  
  FROM #tmpUnArchiveCycleIDs A  
  WHERE SLC_CustomerId = @SLC_CustomerId AND SLC_ArchiveProjectId = @ProjectID;  
  
  SET @RowCount = @RowCount + 1  
 END  
  
 DROP TABLE #tmpUnArchiveCycleIDs;  
END