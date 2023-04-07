USE SLCProject
GO

IF EXISTS(SELECT 1 FROM SYS.TABLES WHERE [NAME] = 'ProjectSetting')
BEGIN
	PRINT 'ProjectSetting table already exists.';
END
ELSE
BEGIN
	CREATE TABLE [ProjectSetting] (
	[Id]			INT IDENTITY(1,1) NOT NULL,
	[ProjectId]		INT NOT NULL,
	[CustomerId]	INT NOT NULL,
	[Name]			NVARCHAR(50) NOT NULL,
	[Value]			NVARCHAR(100) NOT NULL,
	[CreatedDate]	DATETIME2(7) NOT NULL,
	[CreatedBy]		INT NOT NULL,
	[ModifiedDate]	DATETIME2(7) NULL,
	[ModifiedBy]	INT default NULL,
	CONSTRAINT [FK_ProjectSetting_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId])
	);
	PRINT 'ProjectSetting table created successfully.';
END
GO

IF EXISTS(SELECT 1 FROM SYS.TABLES WHERE [NAME] = 'CustomerDivision')
BEGIN
	PRINT 'CustomerDivision table already exists.';
END
ELSE
BEGIN
	CREATE TABLE CustomerDivision(          
	[DivisionId]		BIGINT IDENTITY(10000000,1),        
	[DivisionCode]		NVARCHAR(100),
	[DivisionTitle]		NVARCHAR(4000),
	[IsActive]			BIT,         
	[MasterDataTypeId]	INT,
	[FormatTypeId]		INT,
	[IsDeleted]			BIT,
	[CustomerId]		INT,
	[CreatedBy]			INT NULL, 
	[CreatedDate]		DATETIME2 NULL, 
	[ModifiedBy]		INT NULL, 
	[ModifiedDate]		DATETIME2 NULL,
	CONSTRAINT [PK_CustomerDivision] PRIMARY KEY CLUSTERED ([DivisionId] ASC),
	CONSTRAINT [FK_CustomerDivision_LuMasterDataType] FOREIGN KEY (MasterDataTypeId) REFERENCES LuMasterDataType (MasterDataTypeId),
	CONSTRAINT [FK_CustomerDivision_LuFormatType] FOREIGN KEY (FormatTypeId) REFERENCES LuFormatType (FormatTypeId)
	);
	PRINT 'CustomerDivision table created successfully.';
END

IF EXISTS(SELECT 1 FROM SYS.TABLES WHERE [NAME] = 'UserPreference')
BEGIN
	PRINT 'UserPreference table already exists.';
END
ELSE
BEGIN
CREATE TABLE UserPreference 
   (
	UserPreferenceId INT IDENTITY(1,1),
	UserId INT NULL,
	CustomerId INT NOT NULL,
	Name NVARCHAR(100) NOT NULL,
	Value NVARCHAR(500),
	CreatedDate DATETIME2 NOT NULL,
	ModifiedDate DATETIME2 NULL
	CONSTRAINT [PK_UserPreference] PRIMARY KEY CLUSTERED (UserPreferenceId ASC)
  )
  PRINT 'UserPreference table created successfully.';
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsHiddenAllBsdSections' AND Object_ID = Object_ID(N'[dbo].[ProjectSummary]'))
BEGIN
   ALTER TABLE ProjectSummary ADD IsHiddenAllBsdSections BIT DEFAULT 0 ;
END
ELSE 
Print 'Alread exists IsHiddenAllBsdSections'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsHidden' AND Object_ID = Object_ID(N'[dbo].[ProjectSection]'))
BEGIN
   ALTER TABLE ProjectSection ADD IsHidden BIT DEFAULT 0 ;
END
ELSE 
Print 'Alread exists IsHidden'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'SortOrder' AND Object_ID = Object_ID(N'[dbo].[ProjectSection]'))
BEGIN
   ALTER TABLE ProjectSection ADD SortOrder INT ;
END
ELSE 
Print 'Alread exists SortOrder'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsLinkEngineEnabled' AND Object_ID = Object_ID(N'[dbo].[ProjectSummary]'))
BEGIN
	ALTER TABLE ProjectSummary  ADD IsLinkEngineEnabled int NOT NULL DEFAULT(1)
END
ELSE 
Print 'Alread exists IsLinkEngineEnabled'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'TargetParentSectionId' AND Object_ID = Object_ID(N'[dbo].[ImportProjectRequest]'))
BEGIN
   ALTER TABLE ImportProjectRequest  ADD TargetParentSectionId INT DEFAULT 0;
END
ELSE 
Print 'Alread exists TargetParentSectionId'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsCreateFolderStructure' AND Object_ID = Object_ID(N'[dbo].[ImportProjectRequest]'))
BEGIN
  ALTER table ImportProjectRequest ADD IsCreateFolderStructure bit default 0
END
ELSE 
Print 'Alread exists IsCreateFolderStructure'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsDeleted' AND Object_ID = Object_ID(N'[dbo].[ProjectUserTag]'))
BEGIN
   ALTER TABLE ProjectUserTag ADD IsDeleted bit DEFAULT 0 NOT NULL;
END
ELSE 
Print 'Alread exists IsDeleted In ProjectUserTag'
GO

ALTER TABLE ProjectSection ALTER COLUMN SourceTag VARCHAR(18)
GO
