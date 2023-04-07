/*
 User Story 70428: Print and Export: Batch process to terminate long running print and export requests
 add column for below table
*/
use SLCPROJECT

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'PrintFailureReason' AND Object_ID = Object_ID(N'[dbo].[ProjectExport]'))
BEGIN
	ALTER TABLE ProjectExport ADD PrintFailureReason nvarchar(150)
    PRINT 'PrintFailureReason Column Added.';
END
Else 
PRINT 'PrintFailureReason Column already exists.';
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'PrintFailureReason' AND Object_ID = Object_ID(N'[dbo].[PrintRequestDetails]'))
BEGIN
	ALTER TABLE PrintRequestDetails ADD PrintFailureReason nvarchar(150)
    PRINT 'PrintFailureReason Column Added.';
END
Else 
PRINT 'PrintFailureReason Column already exists.';
GO