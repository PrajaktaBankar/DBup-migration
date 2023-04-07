USE SLCProject
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsIncludeOrphanParagraph' AND Object_ID = Object_ID(N'[dbo].[ProjectPrintSetting]'))
BEGIN
   ALTER TABLE ProjectPrintSetting ADD IsIncludeOrphanParagraph BIT NOT NULL DEFAULT(0)
END
ELSE 
Print 'Alread exists IsIncludeOrphanParagraph'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsMarkPagesAsBlank' AND Object_ID = Object_ID(N'[dbo].[ProjectPrintSetting]'))
BEGIN
   ALTER TABLE ProjectPrintSetting ADD IsMarkPagesAsBlank BIT NOT NULL DEFAULT(0)
END
ELSE 
Print 'Alread exists IsMarkPagesAsBlank'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsIncludeHeaderFooterOnBlackPages' AND Object_ID = Object_ID(N'[dbo].[ProjectPrintSetting]'))
BEGIN
   ALTER TABLE ProjectPrintSetting ADD IsIncludeHeaderFooterOnBlackPages BIT NOT NULL DEFAULT(0)
END
ELSE 
Print 'Alread exists IsIncludeHeaderFooterOnBlackPages'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'BlankPagesText' AND Object_ID = Object_ID(N'[dbo].[ProjectPrintSetting]'))
BEGIN
   ALTER TABLE ProjectPrintSetting ADD BlankPagesText nvarchar(250) 
END
ELSE 
Print 'Alread exists BlankPagesText'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsDeleted' AND Object_ID = Object_ID(N'[dbo].[PrintRequestDetails]'))
BEGIN
   ALTER TABLE PrintRequestDetails ADD IsDeleted BIT NOT NULL DEFAULT(0)
END
ELSE 
Print 'Alread exists IsDeleted'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsSegmentStatusChangeBySelection' AND Object_ID = Object_ID(N'[dbo].[TrackSegmentStatusType]'))
BEGIN
   ALTER TABLE TrackSegmentStatusType ADD IsSegmentStatusChangeBySelection BIT
END
ELSE 
Print 'Alread exists IsSegmentStatusChangeBySelection'
GO

----------------15/01/2021--------------
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'CurrentStatus' AND Object_ID = Object_ID(N'[dbo].[TrackSegmentStatusType]'))
BEGIN
   ALTER TABLE TrackSegmentStatusType ADD CurrentStatus BIT NULL
END
ELSE 
Print 'Alread exists CurrentStatus'
GO

IF  EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'InitialStatus' AND Object_ID = Object_ID(N'[dbo].[TrackSegmentStatusType]'))
BEGIN
   ALTER TABLE TrackSegmentStatusType ALTER COLUMN  InitialStatus BIT NULL
END
ELSE 
Print 'Alread exists InitialStatus'
GO



