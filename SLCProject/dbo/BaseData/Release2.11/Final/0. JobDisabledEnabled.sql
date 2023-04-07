USE MSDB;
GO

-------------START Enabled Job 
UPDATE MSDB.dbo.sysjobs
SET Enabled = 1
WHERE [Name] = 'CopyProjectJob';
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 1
WHERE [Name] = '1-Disable_Drop_old_and_Create_New_SQL_Audit_Logs';
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 1
WHERE [Name] = '2-Disable_Drop_old_and_Create_New_Audit_Specifications';
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 1
WHERE [Name] = 'Daily_database_full_backup_to_Azure_entcloudstorage';
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 1
WHERE [Name] = 'DailyMonitoring';
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 1
WHERE [Name] = 'delete_project';
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 1
WHERE [Name] = 'IndexRebuild_Statistics_Update_Weekly';
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 1
WHERE [Name] = 'Shrink-Logs – SLCProject';
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 1
WHERE [Name] = 'Shrink-Logs for all the SLC databases';
GO

-------------START Enabled Job 


-------------START Disabled Job 
UPDATE MSDB.dbo.sysjobs
SET Enabled = 0
WHERE [Name] = 'CopyProjectJob';
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 0
WHERE [Name] = '1-Disable_Drop_old_and_Create_New_SQL_Audit_Logs';
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 0
WHERE [Name] = '2-Disable_Drop_old_and_Create_New_Audit_Specifications';
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 0
WHERE [Name] = 'Daily_database_full_backup_to_Azure_entcloudstorage';
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 0
WHERE [Name] = 'DailyMonitoring';
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 0
WHERE [Name] = 'delete_project';
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 0
WHERE [Name] = 'IndexRebuild_Statistics_Update_Weekly';
GO

UPDATE MSDB.dbo.sysjobs
SET Enabled = 0
WHERE [Name] = 'Shrink-Logs – SLCProject';
GO


UPDATE MSDB.dbo.sysjobs
SET Enabled = 0
WHERE [Name] = 'Shrink-Logs for all the SLC databases';
GO

-------------START Disabled Job 

