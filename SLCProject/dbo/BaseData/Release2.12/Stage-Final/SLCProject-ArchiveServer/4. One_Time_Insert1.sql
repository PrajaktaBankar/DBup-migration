USE SLCProject
GO

IF NOT EXISTS (SELECT 1	FROM LuUnArchiveRequestStatus WHERE [Name] = 'Queued')
BEGIN
INSERT into LuUnArchiveRequestStatus values('Queued','Queued')
END
ELSE 
Print 'Alread exists "Queued" in LuUnArchiveRequestStatus'
GO

IF NOT EXISTS (SELECT 1	FROM LuUnArchiveRequestStatus WHERE [Name] = 'Running')
BEGIN
INSERT into LuUnArchiveRequestStatus values('Running','Running')
END
ELSE 
Print 'Alread exists "Running" in LuUnArchiveRequestStatus'
GO

IF NOT EXISTS (SELECT 1	FROM LuUnArchiveRequestStatus WHERE [Name] = 'Completed')
BEGIN
INSERT into LuUnArchiveRequestStatus values('Completed','Completed')
END
ELSE 
Print 'Alread exists "Completed" in LuUnArchiveRequestStatus'
GO

IF NOT EXISTS (SELECT 1	FROM LuUnArchiveRequestStatus WHERE [Name] = 'Failed')
BEGIN
INSERT into LuUnArchiveRequestStatus values('Failed','Failed')
END
ELSE 
Print 'Alread exists "Failed" in LuUnArchiveRequestStatus'
GO

IF NOT EXISTS (SELECT 1	FROM LuUnArchiveRequestType WHERE [Name] = 'Active')
BEGIN
INSERT into LuUnArchiveRequestType values('Active','Active')
END
ELSE 
Print 'Alread exists "Active" in LuUnArchiveRequestType'
GO

IF NOT EXISTS (SELECT 1	FROM LuUnArchiveRequestType WHERE [Name] = 'Restore')
BEGIN
INSERT into LuUnArchiveRequestType values('Restore','Restore')
END
ELSE 
Print 'Alread exists "Restore" in LuUnArchiveRequestType'
GO

IF NOT EXISTS (SELECT 1	FROM LuUnArchiveRequestType WHERE [Name] = 'UnArchive')
BEGIN
INSERT into LuUnArchiveRequestType values('UnArchive','UnArchive')
END
ELSE 
Print 'Alread exists "UnArchive" in LuUnArchiveRequestType'
GO