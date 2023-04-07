USE SLCProject
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'LuProjectOriginType'))
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

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'LuProjectOwnerType'))
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

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'ProjectDefaultPrivacySetting'))
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

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'LuProjectActivityType'))
BEGIN
CREATE Table LuProjectActivityType(
ProjectActivityTypeId TINYINT IDENTITY NOT NULL PRIMARY KEY,
[Name] NVARCHAR(100),
[Description] NVARCHAR(100),
);
END
ELSE
Print 'LuProjectActivityType table already exist' 
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'ProjectActivity'))
BEGIN
CREATE TABLE ProjectActivity(
ActivityId Int IDENTITY NOT NULL PRIMARY KEY,
ProjectId Int,
UserId Int,
CustomerId Int,
ProjectName NVARCHAR(100),
UserEmail NVARCHAR(100),
ProjectActivityTypeId TINYINT FOREIGN KEY  REFERENCES LuProjectActivityType(ProjectActivityTypeId),
CreatedDate DATETIME2(7)
);
END
ELSE
Print 'ProjectActivity Table already exist' 
GO


IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'ActionName' AND Object_ID = Object_ID(N'[dbo].[DeletedProjectLog]'))
BEGIN
   ALTER TABLE DeletedProjectLog ADD ActionName  NVARCHAR (50)  NULL
END
ELSE 
Print 'Alread exists ActionName in table DeletedProjectLog'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'StartTime' AND Object_ID = Object_ID(N'[dbo].[DeletedProjectLog]'))
BEGIN
   ALTER TABLE DeletedProjectLog ADD StartTime   DATETIME2 (7)  NULL
END
ELSE 
Print 'Alread exists StartTime in table DeletedProjectLog'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'EndTime' AND Object_ID = Object_ID(N'[dbo].[DeletedProjectLog]'))
BEGIN
   ALTER TABLE DeletedProjectLog ADD EndTime  DATETIME2 (7)  NULL
END
ELSE 
Print 'Alread exists EndTime in table DeletedProjectLog'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'RecordsDeleted' AND Object_ID = Object_ID(N'[dbo].[DeletedProjectLog]'))
BEGIN
   ALTER TABLE DeletedProjectLog ADD RecordsDeleted  BIGINT   NULL
END
ELSE 
Print 'Alread exists RecordsDeleted in table DeletedProjectLog'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'Duration' AND Object_ID = Object_ID(N'[dbo].[DeletedProjectLog]'))
BEGIN
   ALTER TABLE DeletedProjectLog ADD Duration As (CONVERT([varchar],dateadd(second,datediff(second,[StartTime],[EndTime]),(0)),(108)))
END
ELSE 
Print 'Alread exists Duration in table DeletedProjectLog'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'LockedBy' AND Object_ID = Object_ID(N'[dbo].[Project]'))
BEGIN
   ALTER TABLE Project ADD LockedBy NVARCHAR(500) Default Null;
END
ELSE 
Print 'Alread exists LockedBy column in table Project'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'LockedDate' AND Object_ID = Object_ID(N'[dbo].[Project]'))
BEGIN
ALTER TABLE Project ADD LockedDate DATETIME2 Default Null;
END
ELSE 
Print 'Alread exists LockedDate column in table Project'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'LockedById' AND Object_ID = Object_ID(N'[dbo].[Project]'))
BEGIN
ALTER TABLE Project ADD LockedById int Default Null;
END
ELSE 
Print 'Alread exists LockedById column in table Project'
GO

IF NOT EXISTS (SELECT 1	FROM LuProjectOriginType WHERE [Name] = 'SLC Project')
BEGIN
	INSERT INTO LuProjectOriginType ([Name], [Description], IsActive)
	VALUES ('SLC Project', 'Projects that are created or copied in SLC', 1);
END
ELSE
BEGIN
	PRINT ('SLC Project - already exists in table LuProjectOriginType.');
END
GO

IF NOT EXISTS (SELECT 1	FROM LuProjectOriginType WHERE [Name] = 'Migrated Project')
BEGIN
	INSERT INTO LuProjectOriginType ([Name], [Description], IsActive)
	VALUES ('Migrated Project','Projects that are migrated from SLE into SLC',1);
END
ELSE
BEGIN
	PRINT ('Migrated Project - already exists in table LuProjectOriginType.');
END
GO

IF NOT EXISTS (SELECT 1	FROM LuProjectOriginType WHERE [Name] = 'Transferred Project')
BEGIN
	INSERT INTO LuProjectOriginType ([Name], [Description], IsActive)
	VALUES ('Transferred Project','Transferred Project',1);
END
ELSE
BEGIN
	PRINT ('Transferred Project - already exists in table LuProjectOriginType.');
END
GO

IF NOT EXISTS (SELECT 1	FROM LuProjectOwnerType WHERE [Name] = 'Not Assigned')
BEGIN
	insert into LuProjectOwnerType([Name],[Description],IsActive, SortOrder) 
	values ('Not Assigned','Not Assigned',1, 1);
END
ELSE
BEGIN
	PRINT ('"Not Assigned" type already exists in table LuProjectOwnerType.');
END
GO

IF NOT EXISTS (SELECT 1	FROM LuProjectOwnerType WHERE [Name] = 'User Who Received the Project')
BEGIN
	insert into LuProjectOwnerType([Name],[Description],IsActive, SortOrder) 
	values ('User Who Received the Project','User Who Received the Project',1, 2)
END
ELSE
BEGIN
	PRINT ('"User Who Received the Project" type already exists in table LuProjectOwnerType.');
END
GO

IF NOT EXISTS (SELECT 1	FROM LuProjectOwnerType WHERE [Name] = 'User Who Created the Project')
BEGIN
	insert into LuProjectOwnerType([Name],[Description],IsActive, SortOrder) 
	values ('User Who Created the Project','User Who Created the Project',1,3);
END
ELSE
BEGIN
	PRINT ('"User Who Created the Project" type already exists in table LuProjectOwnerType.');
END
GO

----------Add settings for 'Active Project'--------------------------------------------------------------
DECLARE @AccessTypePublic int = 1;
DECLARE @ProjectOrigineTypeId int;
DECLARE @ProjectOwnerTypeId int;

select @ProjectOrigineTypeId = ProjectOriginTypeId  from LuProjectOriginType WITH(NOLOCK) where [Name] = 'SLC Project';
select @ProjectOwnerTypeId = ProjectOwnerTypeId from LuProjectOwnerType WITH(NOLOCK) where [Name] = 'User Who Created the Project';
DECLARE @IsOfficeMaster bit = 0;

IF NOT EXISTS (SELECT 1	FROM ProjectDefaultPrivacySetting  WITH(NOLOCK) WHERE CustomerId = 0 and ProjectOriginTypeId = @ProjectOrigineTypeId and IsOfficeMaster=@IsOfficeMaster)
BEGIN
	insert into ProjectDefaultPrivacySetting(
	CustomerId,ProjectAccessTypeId,ProjectOwnerTypeId, ProjectOriginTypeId,IsOfficeMaster,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)
	values (0, @AccessTypePublic, @ProjectOwnerTypeId, @ProjectOrigineTypeId, @IsOfficeMaster, null, null, null, null);
END
ELSE
BEGIN
	PRINT ('Active Projects default privacy settings already exists.');
END
GO

----------Add settings for 'Office Master'--------------------------------------------------------------
DECLARE @AccessTypePublic int = 1;
DECLARE @ProjectOrigineTypeId int;
DECLARE @ProjectOwnerTypeId int;

select @ProjectOrigineTypeId = ProjectOriginTypeId  from LuProjectOriginType WITH(NOLOCK) where [Name] = 'SLC Project';
select @ProjectOwnerTypeId = ProjectOwnerTypeId from LuProjectOwnerType WITH(NOLOCK) where [Name] = 'User Who Created the Project';
DECLARE @IsOfficeMaster bit = 1;

IF NOT EXISTS (SELECT 1	FROM ProjectDefaultPrivacySetting  WITH(NOLOCK) WHERE CustomerId = 0 and ProjectOriginTypeId = @ProjectOrigineTypeId and IsOfficeMaster=@IsOfficeMaster)
BEGIN
	insert into ProjectDefaultPrivacySetting(
	CustomerId,ProjectAccessTypeId,ProjectOwnerTypeId, ProjectOriginTypeId,IsOfficeMaster,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)
	values (0,	@AccessTypePublic, @ProjectOwnerTypeId, @ProjectOrigineTypeId, @IsOfficeMaster,	null, null, null, null);
END
ELSE
BEGIN
	PRINT ('Office Masters default privacy settings already exists.');
END
GO

----------Add settings for 'Migrated Projects'--------------------------------------------------------------
DECLARE @AccessTypePublic int = 1;
DECLARE @ProjectOrigineTypeId int;
DECLARE @ProjectOwnerTypeId int;

select @ProjectOrigineTypeId = ProjectOriginTypeId  from LuProjectOriginType WITH(NOLOCK) where [Name] = 'Migrated Project';
select @ProjectOwnerTypeId = ProjectOwnerTypeId from LuProjectOwnerType WITH(NOLOCK) where [Name] = 'Not Assigned';
DECLARE @IsOfficeMaster bit = 0;
IF NOT EXISTS (SELECT 1	FROM ProjectDefaultPrivacySetting  WITH(NOLOCK) WHERE CustomerId = 0 and ProjectOriginTypeId = @ProjectOrigineTypeId and IsOfficeMaster=@IsOfficeMaster)
BEGIN
	insert into ProjectDefaultPrivacySetting(
	CustomerId,ProjectAccessTypeId,ProjectOwnerTypeId, ProjectOriginTypeId,IsOfficeMaster,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)
	values (0,	@AccessTypePublic,	@ProjectOwnerTypeId,@ProjectOrigineTypeId, @IsOfficeMaster,	null, null, null, null);
END
ELSE
BEGIN
	PRINT ('Migrated Projects default privacy settings already exists.');
END
GO

----------Add settings for 'Migrated Office Master'--------------------------------------------------------------
DECLARE @AccessTypePublic int = 1;
DECLARE @ProjectOrigineTypeId int;
DECLARE @ProjectOwnerTypeId int;

select @ProjectOrigineTypeId = ProjectOriginTypeId  from LuProjectOriginType WITH(NOLOCK) where [Name] = 'Migrated Project';
select @ProjectOwnerTypeId = ProjectOwnerTypeId from LuProjectOwnerType WITH(NOLOCK) where [Name] = 'Not Assigned';
DECLARE @IsOfficeMaster bit = 1;

IF NOT EXISTS (SELECT 1	FROM ProjectDefaultPrivacySetting  WITH(NOLOCK) WHERE CustomerId = 0 and ProjectOriginTypeId = @ProjectOrigineTypeId and IsOfficeMaster=@IsOfficeMaster)
BEGIN
	insert into ProjectDefaultPrivacySetting(
	CustomerId,ProjectAccessTypeId,ProjectOwnerTypeId,ProjectOriginTypeId,IsOfficeMaster,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)
	values (0, @AccessTypePublic, @ProjectOwnerTypeId,	@ProjectOrigineTypeId, @IsOfficeMaster,	null, null, null, null);
END
ELSE
BEGIN
	PRINT ('Migrated Office Masters default privacy settings already exists.');
END
GO

----------Add settings for 'Transferred Projects'--------------------------------------------------------------
DECLARE @AccessTypePublic int = 1;
DECLARE @ProjectOrigineTypeId int;
DECLARE @ProjectOwnerTypeId int;

select @ProjectOrigineTypeId = ProjectOriginTypeId  from LuProjectOriginType WITH(NOLOCK) where [Name] = 'Transferred Project';
select @ProjectOwnerTypeId = ProjectOwnerTypeId from LuProjectOwnerType WITH(NOLOCK) where [Name] = 'User Who Received the Project';
DECLARE @IsOfficeMaster bit = 0;

IF NOT EXISTS (SELECT 1	FROM ProjectDefaultPrivacySetting  WITH(NOLOCK) WHERE CustomerId = 0 and ProjectOriginTypeId = @ProjectOrigineTypeId and IsOfficeMaster=@IsOfficeMaster)
BEGIN
	insert into ProjectDefaultPrivacySetting(
	CustomerId,ProjectAccessTypeId,ProjectOwnerTypeId, ProjectOriginTypeId,IsOfficeMaster,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)
	values (0,	@AccessTypePublic,	@ProjectOwnerTypeId,	@ProjectOrigineTypeId, @IsOfficeMaster,	null, null, null, null);
END
ELSE
BEGIN
	PRINT ('Transferred Projects default privacy settings already exists.');
END
GO

----------Add settings for 'Transferred Office Masters'--------------------------------------------------------------
DECLARE @AccessTypePublic int = 1;
DECLARE @ProjectOrigineTypeId int;
DECLARE @ProjectOwnerTypeId int;

select @ProjectOrigineTypeId = ProjectOriginTypeId  from LuProjectOriginType WITH(NOLOCK) where [Name] = 'Transferred Project';
select @ProjectOwnerTypeId = ProjectOwnerTypeId from LuProjectOwnerType WITH(NOLOCK) where [Name] = 'User Who Received the Project';
DECLARE @IsOfficeMaster bit = 1;

IF NOT EXISTS (SELECT 1	FROM ProjectDefaultPrivacySetting  WITH(NOLOCK) WHERE CustomerId = 0 and ProjectOriginTypeId = @ProjectOrigineTypeId and IsOfficeMaster=@IsOfficeMaster)
BEGIN
	insert into ProjectDefaultPrivacySetting(
	CustomerId,ProjectAccessTypeId,ProjectOwnerTypeId, ProjectOriginTypeId,IsOfficeMaster,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)
	values (0,@AccessTypePublic,@ProjectOwnerTypeId,@ProjectOrigineTypeId, @IsOfficeMaster,	null, null, null, null);
END
ELSE
BEGIN
	PRINT ('Transferred Office Masters default privacy settings already exists.');
END
GO

IF NOT EXISTS (SELECT 1	FROM LuProjectActivityType WHERE [Name] = 'Locked')
BEGIN
INSERT INTO LuProjectActivityType ( [Name], [Description])
VALUES ( 'Locked','Locked' )
END 
ELSE 
Print 'Alread exists Locked in LuProjectActivityType'
GO

IF NOT EXISTS (SELECT 1	FROM LuProjectActivityType WHERE [Name] = 'Unlocked')
BEGIN
INSERT INTO LuProjectActivityType ( [Name], [Description])
VALUES ( 'Unlocked','Unlocked' )
END 
ELSE 
Print 'Alread exists Unlocked in LuProjectActivityType'
GO

IF NOT EXISTS (SELECT 1	FROM LuProjectActivityType WHERE [Name] = 'Restored')
BEGIN
INSERT INTO LuProjectActivityType ( [Name], [Description])
VALUES ( 'Restored','Restored' )
END
ELSE 
Print 'Alread exists Restored in LuProjectActivityType'
GO

IF NOT EXISTS (SELECT 1	FROM LuProjectActivityType WHERE [Name] = 'Archived')
BEGIN
INSERT INTO LuProjectActivityType ( [Name], [Description])
VALUES ( 'Archived','Archived' )
END
ELSE
BEGIN
	PRINT ('Already exists Archived in LuProjectActivityType.');
END
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'ProjectLevelTrackChangesLogging'))
BEGIN
CREATE TABLE ProjectLevelTrackChangesLogging (
ProjectChangeId Int IDENTITY NOT NULL PRIMARY KEY,
UserId Int,
ProjectId Int,
CustomerId Int,
UserEmail NVARCHAR(100),
PriviousTrackChangeModeId TINYINT FOREIGN KEY  REFERENCES LuTrackChangesMode(TcModeId),
CurrentTrackChangeModeId TINYINT FOREIGN KEY  REFERENCES LuTrackChangesMode(TcModeId),
CreatedDate DATETIME2(7)  
);
PRINT 'ProjectLevelTrackChangesLogging table created successfully.';
END
ELSE
PRINT 'ProjectLevelTrackChangesLogging table already exists.';
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'SectionLevelTrackChangesLogging'))
BEGIN
CREATE TABLE SectionLevelTrackChangesLogging (
SectionChangeId Int IDENTITY NOT NULL PRIMARY KEY,
UserId Int,
ProjectId Int,
SectionId Int,
CustomerId Int,
UserEmail NVARCHAR(100),
IsTrackChanges BIT,
IsTrackChangeLock BIT,
CreatedDate DATETIME2(7)
);
PRINT 'SectionLevelTrackChangesLogging table created successfully.';
END
ELSE
PRINT 'SectionLevelTrackChangesLogging table already exists.';
GO