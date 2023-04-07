USE [SLCProject]
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsContinuousPageNumber' AND Object_ID = Object_ID(N'[dbo].[ProjectPrintSetting]'))
BEGIN
	ALTER TABLE ProjectPrintSetting
	ADD IsContinuousPageNumber BIT NOT NULL DEFAULT 0;
    PRINT 'IsContinuousPageNumber Column Added.';
END
ELSE 
	PRINT 'IsContinuousPageNumber Column already exists.';
GO
