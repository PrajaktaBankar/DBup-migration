USE [SLCProject]
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'PendingUpdateCount' AND Object_ID = Object_ID(N'[dbo].[ProjectSection]'))
BEGIN
	ALTER TABLE ProjectSection
	ADD PendingUpdateCount INT;
    PRINT 'ProjectSection - PendingUpdateCount Column Added.';
END
ELSE
BEGIN
	PRINT 'ProjectSection - PendingUpdateCount Column already exists.';
END
GO