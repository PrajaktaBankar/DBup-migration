USE SLCProject
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'SegmentStatusTypeIdBeforeSelection' AND Object_ID = Object_ID(N'[dbo].[TrackSegmentStatusType]'))
BEGIN
   ALTER TABLE TrackSegmentStatusType ADD SegmentStatusTypeIdBeforeSelection INT NULL
END
ELSE 
Print 'Alread exists SegmentStatusTypeIdBeforeSelection'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IncludeSectionIdAfterEod' AND Object_ID = Object_ID(N'[dbo].[ProjectPrintSetting]'))
BEGIN
   ALTER TABLE ProjectPrintSetting ADD IncludeSectionIdAfterEod BIT NOT NULL DEFAULT 0 ;
END
ELSE 
Print 'Alread exists IncludeSectionIdAfterEod'
GO

-----------------TABLES----------
IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'FileNameFormatSetting'))
BEGIN

CREATE TABLE FileNameFormatSetting  (
Id INT primary key Identity(1,1) NOT NULL,
FileFormatCategoryId INT NOT NULL,
IncludeAutherSectionId BIT,
Separator NVARCHAR(2),
FormatJsonWithPlaceHolder NVARCHAR(200),
ProjectId INT,
CustomerId INT,
FOREIGN KEY (FileFormatCategoryId) REFERENCES LuExportFileFormatCategory(Id),
FOREIGN KEY (ProjectId) REFERENCES project(ProjectId)
);
END
ELSE
Print 'FileNameFormatSetting Table already exist'
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'LuExportFileFormatCategory'))
BEGIN
create table LuExportFileFormatCategory(
Id INT primary key identity(1,1) NOT NULL,
[Description] nvarchar(100)
);
END
ELSE
Print 'LuExportFileFormatCategory Table already exist'
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'FileNameFormatProperties'))
BEGIN

CREATE TABLE FileNameFormatProperties(
Id INT PRIMARY KEY IDENTITY(1,1),
[Name] NVARCHAR(50),
PlaceHolder NVARCHAR(10),
[Value] NVARCHAR(200),
IsForDocument BIT,
IsForProjectReport BIT,
ProjectId INT,
CustomerId INT,
CreatedBy INT,
CreateDate DATETIME2,
ModifiedBy INT,
ModifiedDate DATETIME2
);
END
ELSE
Print 'FileNameFormatProperties Table already exist'
GO