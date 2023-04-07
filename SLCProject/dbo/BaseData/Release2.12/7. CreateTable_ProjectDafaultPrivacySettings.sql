USE SLCProject
GO

if not exists (SELECT * FROM sysobjects
	WHERE name = 'LuProjectOriginType'
	AND xtype = 'U')
BEGIN
CREATE TABLE LuProjectOriginType (
	ProjectOriginTypeId INT IDENTITY (1, 1)
   ,[Name] NVARCHAR(100)
   ,[Description] NVARCHAR(100)
   ,IsActive BIT
   ,CONSTRAINT [PK_LUPROJECTORIGINTYPE] PRIMARY KEY CLUSTERED ([ProjectOriginTypeId] ASC)
);
PRINT 'LuProjectOriginType table created successfully.';
END
ELSE
PRINT 'LuProjectOriginType table already exists.';
GO

if not exists (SELECT * FROM sysobjects
	WHERE name = 'LuProjectOwnerType'
	AND xtype = 'U')
BEGIN
CREATE TABLE LuProjectOwnerType (
	ProjectOwnerTypeId INT IDENTITY (1, 1)
   ,[Name] NVARCHAR(100) NOT NULL
   ,[Description] NVARCHAR(100) NULL
   ,IsActive BIT NOT NULL
   ,SortOrder INT NOT NULL
   ,CONSTRAINT [PK_LUPROJECTOWNERTYPE] PRIMARY KEY CLUSTERED ([ProjectOwnerTypeId] ASC)
);
PRINT 'LuProjectOwnerType table created successfully.';
END
ELSE
PRINT 'LuProjectOwnerType table already exists.';
GO

if not exists (SELECT * FROM sysobjects
	WHERE name = 'ProjectDefaultPrivacySetting'
	AND xtype = 'U')
BEGIN
CREATE TABLE ProjectDefaultPrivacySetting (
	Id INT IDENTITY (1, 1)
   ,CustomerId INT NOT NULL
   ,ProjectAccessTypeId INT NOT NULL
   ,ProjectOwnerTypeId INT NOT NULL
   ,ProjectOriginTypeId INT NOT NULL
   ,IsOfficeMaster BIT NOT NULL
   ,CreatedBy INT NULL
   ,CreatedDate DATETIME2 NULL
   ,ModifiedBy INT NULL
   ,ModifiedDate DATETIME2 NULL
   ,CONSTRAINT [PK_ProjectDefaultPrivacySetting] PRIMARY KEY CLUSTERED ([Id] ASC)
   ,CONSTRAINT [FK_ProjectDefaultPrivacySetting_LuProjectAccessType] FOREIGN KEY (ProjectAccessTypeId) REFERENCES LuProjectAccessType (ProjectAccessTypeId)
   ,CONSTRAINT [FK_ProjectDefaultPrivacySetting_LuProjectOwnerType] FOREIGN KEY (ProjectOwnerTypeId) REFERENCES LuProjectOwnerType (ProjectOwnerTypeId)
   ,CONSTRAINT [FK_ProjectDefaultPrivacySetting_LuProjectOriginType] FOREIGN KEY (ProjectOriginTypeId) REFERENCES LuProjectOriginType (ProjectOriginTypeId)
);
PRINT 'ProjectDefaultPrivacySetting table created successfully.';
END
ELSE
PRINT 'ProjectDefaultPrivacySetting table already exists.';
GO
