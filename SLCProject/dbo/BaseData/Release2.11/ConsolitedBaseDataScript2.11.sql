USE SLCProject 
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'A_SegmentCommentId' AND Object_ID = Object_ID(N'[dbo].[SegmentComment]'))
BEGIN
   ALTER TABLE SegmentComment ADD A_SegmentCommentId INT NULL
END
ELSE 
Print 'Alread exists A_SegmentCommentId'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsShowMigrationPopup' AND Object_ID = Object_ID(N'[dbo].[Project]'))
BEGIN
ALTER TABLE Project ADD IsShowMigrationPopup bit 
DEFAULT 0 NOT NULL;
END
ELSE 
Print 'Alread exists IsShowMigrationPopup'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsResolved' AND Object_ID = Object_ID(N'[dbo].[ProjectMigrationException]'))
BEGIN
ALTER TABLE ProjectMigrationException ADD IsResolved BIT DEFAULT 0; 

UPDATE PME
SET PME.IsResolved=1
FROM ProjectMigrationException PME WITH (NOLOCK)

END
ELSE 
Print 'Alread exists IsResolved'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'TrackChangesModeId' AND Object_ID = Object_ID(N'[dbo].[ProjectSummary]'))
BEGIN
ALTER TABLE ProjectSummary ADD TrackChangesModeId TINYINT
END
ELSE 
Print 'Alread exists TrackChangesModeId'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsDeleted' AND Object_ID = Object_ID(N'[dbo].[ImportProjectRequest]'))
BEGIN
ALTER TABLE ImportProjectRequest ADD IsDeleted BIT NOT NULL DEFAULT 0	
END
ELSE 
Print 'Alread exists IsDeleted'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'ModifiedBy' AND Object_ID = Object_ID(N'[dbo].[ProjectMigrationException]'))
BEGIN
ALTER TABLE ProjectMigrationException ADD ModifiedBy int DEFAULT NULL;
END
ELSE 
Print 'Alread exists ModifiedBy'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'ModifiedDate' AND Object_ID = Object_ID(N'[dbo].[ProjectMigrationException]'))
BEGIN
ALTER TABLE ProjectMigrationException ADD ModifiedDate DATETIME2(7) DEFAULT NULL;
END
ELSE 
Print 'Alread exists ModifiedDate'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsPrintMasterNote' AND Object_ID = Object_ID(N'[dbo].[ProjectPrintSetting]'))
BEGIN
ALTER TABLE ProjectPrintSetting
ADD IsPrintMasterNote Bit NOT NULL DEFAULT 0
END
ELSE 
Print 'Alread exists IsPrintMasterNote'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsPrintProjectNote' AND Object_ID = Object_ID(N'[dbo].[ProjectPrintSetting]'))
BEGIN
ALTER TABLE ProjectPrintSetting
ADD IsPrintProjectNote Bit NOT NULL DEFAULT 0
END
ELSE 
Print 'Alread exists IsPrintProjectNote'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsPrintNoteImage' AND Object_ID = Object_ID(N'[dbo].[ProjectPrintSetting]'))
BEGIN
ALTER TABLE ProjectPrintSetting
ADD IsPrintNoteImage Bit NOT NULL DEFAULT 0
END
ELSE 
Print 'Alread exists IsPrintNoteImage'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsPrintIHSLogo' AND Object_ID = Object_ID(N'[dbo].[ProjectPrintSetting]'))
BEGIN
ALTER TABLE ProjectPrintSetting
ADD IsPrintIHSLogo Bit NOT NULL DEFAULT 0
END
ELSE 
Print 'Alread exists IsPrintIHSLogo'
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'LuTrackChangesMode'))
BEGIN
CREATE TABLE LuTrackChangesMode (
    TcModeId TINYINT IDENTITY (1, 1) PRIMARY KEY,
    TcModeName VARCHAR(100) NULL
);
END
ELSE 
Print 'Alread exists LuTrackChangesMode Table'
go

IF (NOT EXISTS (Select 1 FROM LuTrackChangesMode where TcModeName='Track Changes Off - None'))
BEGIN
INSERT INTO LuTrackChangesMode VALUES('Track Changes Off - None');
END
ELSE 
Print 'Alread exists Track Changes Off - None '
go

IF (NOT EXISTS (Select 1 FROM LuTrackChangesMode where TcModeName='Track Changes Across All Sections'))
BEGIN
INSERT INTO LuTrackChangesMode VALUES('Track Changes Across All Sections');
END
ELSE 
Print 'Alread exists rack Changes Across All Sections'
go

IF (NOT EXISTS (Select 1 FROM LuTrackChangesMode where TcModeName='Track Changes By Section'))
BEGIN
INSERT INTO LuTrackChangesMode VALUES('Track Changes By Section');
END
ELSE 
Print 'Alread exists Track Changes By Section'
go

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'SLE_GUID' AND Object_ID = Object_ID(N'[dbo].[ProjectImage]'))
BEGIN
ALTER TABLE ProjectImage
ADD SLE_GUID NVARCHAR(100) NULL
END
ELSE 
Print 'Alread exists SLE_GUID'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'DataMapDateTimeStamp' AND Object_ID = Object_ID(N'[dbo].[ProjectSection]'))
BEGIN
ALTER TABLE ProjectSection 
ADD DataMapDateTimeStamp  DATETIME2 (7)  NULL
END
ELSE 
Print 'Alread exists DataMapDateTimeStamp'
GO

ALTER TABLE ProjectHyperLink
DROP COLUMN ModifiedBy
GO

ALTER TABLE ProjectHyperLink
Add  ModifiedBy int NULL
GO
