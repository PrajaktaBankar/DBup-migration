USE SLCProject
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'TrackAcceptRejectHistory'))
BEGIN
CREATE TABLE [dbo].[TrackAcceptRejectHistory](
[TrackHistoryId] [int] primary key IDENTITY(1,1) NOT NULL,
[SectionId] [int] NULL,
[ProjectId] [int] NOT NULL,
[CustomerId] [int] NOT NULL,
[UserId] [int] NOT NULL,
[TrackActionId] [int] NOT NULL,
CreateDate Datetime2 not null default getutcdate(),
FOREIGN KEY (TrackActionId) REFERENCES LuTrackingActions(TrackActionId),
FOREIGN KEY (Sectionid) REFERENCES ProjectSection(SectionId),
FOREIGN KEY (ProjectId) REFERENCES Project(ProjectId)
)
END
ELSE
BEGIN
	Print 'TrackAcceptRejectHistory Table already exist';
END;

GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'LuCopyProjectType'))
BEGIN
CREATE TABLE [dbo].[LuCopyProjectType](
	[CopyProjectTypeId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[CopyProjectTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];
END
ELSE
BEGIN
	Print 'LuCopyProjectType Table already exist';
END;

GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'CopyProjectTypeId' AND Object_ID = Object_ID(N'[dbo].[CopyProjectRequest]'))
BEGIN
  ALTER TABLE CopyProjectRequest ADD CopyProjectTypeId int;
END
ELSE 
BEGIN 
	Print 'Already exists - Column CopyProjectTypeId';
END

GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'TransferRequestId' AND Object_ID = Object_ID(N'[dbo].[CopyProjectRequest]'))
BEGIN
	ALTER TABLE CopyProjectRequest ADD TransferRequestId int;
END
ELSE 
BEGIN 
	Print 'Already exists - Column TransferRequestId';
END

GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsIncomingProject' AND Object_ID = Object_ID(N'[dbo].[Project]'))
BEGIN
	ALTER TABLE Project ADD IsIncomingProject BIT;
END
ELSE 
BEGIN 
	Print 'Already exists - Column IsIncomingProject';
END

GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'TransferredDate' AND Object_ID = Object_ID(N'[dbo].[Project]'))
BEGIN
	ALTER TABLE Project ADD TransferredDate DATETIME2;
END
ELSE 
BEGIN 
	Print 'Already exists - Column TransferredDate';
END

GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'BIM360AccessKey'))
BEGIN
CREATE TABLE BIM360AccessKey
(
AccessKeyId INT IDENTITY(1,1) NOT NULL,
CustomerId INT NOT NULL,
ClientId nvarchar(255) NOT NULL,
ClientSecret nvarchar(255) NOT NULL,
IsActive BIT NOT NULL default 0,
CreatedDate datetime2 NOT NULL DEFAULT GETUTCDATE(),
CreatedBy int NOT NULL,
ModifiedDate datetime2 NULL,
ModifiedBy int NULL,
CONSTRAINT [PK_BIM360AccessKey] PRIMARY KEY CLUSTERED ([AccessKeyId] ASC)
)
END
ELSE
BEGIN
	Print 'BIM360AccessKey Table already exist';
END;


GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'IncomingProjectHistory'))
BEGIN
CREATE TABLE [dbo].[IncomingProjectHistory](
	[Id] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[ProjectId] [int] NULL,
	[Action] [nvarchar](50) NULL,
	[UserId] [int] NULL,
	[CustomerId] [int] NULL,
	[CreatedDate] [datetime2](7) NULL,
	[TransferredRequestId] [int] NULL
);
END
ELSE
BEGIN
	Print 'IncomingProjectHistory Table already exist';
END;

GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'ProjectTransferGlobalDataAuditLog'))
BEGIN
CREATE TABLE [dbo].[ProjectTransferGlobalDataAuditLog](
	[GlobaDataAuditLogId] [int] IDENTITY(1,1) NOT NULL,
	[SourceCustomerId] [int] NOT NULL,
	[SourceProjectId] [int] NOT NULL,
	[SourceServerId] [int] NOT NULL,
	[TargetCustomerId] [int] NOT NULL,
	[TargetProjectId] [int] NULL,
	[TargetServerId] [int] NOT NULL,
	[ItemTypeId] [int] NOT NULL,
	[SourceItemId] [int] NOT NULL,
	[SourceDescription] [nvarchar](500) NOT NULL,
	[TargetItemId] [int] NOT NULL,
	[TargetDescription] [nvarchar](500) NOT NULL,
	[CreatedDate] [datetime] NULL,
	[RequestId] [int] NOT NULL,
 CONSTRAINT [PK_ProjectTransferGlobalDataAuditLog] PRIMARY KEY CLUSTERED 
(
	[GlobaDataAuditLogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
END
ELSE
BEGIN
	Print 'ProjectTransferGlobalDataAuditLog Table already exist';
END;

GO


USE [SLCProject]
GO
ALTER TABLE [dbo].[ProjectUserTag] ADD [IsTransferred] BIT NOT NULL DEFAULT((0))
ALTER TABLE [dbo].[ReferenceStandard] ADD [IsTransferred] BIT NOT NULL DEFAULT((0))
ALTER TABLE [dbo].[Style] ADD [IsTransferred] BIT NOT NULL DEFAULT((0))
ALTER TABLE [dbo].[Template] ADD [IsTransferred] BIT NOT NULL DEFAULT((0))
ALTER TABLE [dbo].[UserGlobalTerm] ADD [IsTransferred] BIT NOT NULL DEFAULT((0))
GO
