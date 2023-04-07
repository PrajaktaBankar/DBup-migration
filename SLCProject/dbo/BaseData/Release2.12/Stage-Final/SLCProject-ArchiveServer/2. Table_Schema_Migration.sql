Use SLCProject 
GO
IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'LuUnArchiveRequestType'))
BEGIN
CREATE TABLE LuUnArchiveRequestType(
	[RequestTypeId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[TypeDescription] [nvarchar](50) NULL,
 CONSTRAINT [PK_UnArchiveRequestType] PRIMARY KEY CLUSTERED 
(
	[RequestTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
PRINT 'LuUnArchiveRequestType table created successfully.';
END
ELSE
PRINT 'LuUnArchiveRequestType table already exists.';
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'LuUnArchiveRequestStatus'))
BEGIN
CREATE TABLE [dbo].[LuUnArchiveRequestStatus](
	[StatusId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[StatusDescription] [nvarchar](50) NULL,
 CONSTRAINT [PK_UnArchiveStatus] PRIMARY KEY CLUSTERED 
(
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
PRINT 'LuUnArchiveRequestStatus table created successfully.';
END
ELSE
PRINT 'LuUnArchiveRequestStatus table already exists.';
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'Logging'))
BEGIN
CREATE TABLE [dbo].[Logging](
	[LogID] [bigint] IDENTITY(1,1) NOT NULL,
	[ErrorCode] [int] NULL,
	[ErrorStep] [varchar](50) NOT NULL,
	[ErrorMessage] [nvarchar](1024) NULL,
	[Created] [datetime] NOT NULL,
	[CycleID] [bigint] NULL,
 CONSTRAINT [PK_Logging] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
PRINT 'Logging table created successfully.';
END
ELSE
PRINT 'Logging table already exists.';
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'UnArchiveStepProgress'))
BEGIN
CREATE TABLE UnArchiveStepProgress(
	[UnArchiveStepProgressId] [bigint] IDENTITY(1,1) NOT NULL,
	[StepName] [nvarchar](100) NULL,
	[Description] [nvarchar](500) NULL,
	[IsCompleted] [bit] NOT NULL,
	[Step] [nvarchar](100) NULL,
	[OldCount] [int] NULL,
	[NewCount] [int] NULL,
	[CreatedDate] [datetime] NULL,
	RequestId INT NOT NULL,
 CONSTRAINT [PK_UnArchiveStepProgress] PRIMARY KEY CLUSTERED 
(
	[UnArchiveStepProgressId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
PRINT 'UnArchiveStepProgress table created successfully.';
END
ELSE
PRINT 'UnArchiveStepProgress table already exists.';
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'UnArchiveProjectRequest'))
BEGIN
CREATE TABLE [dbo].[UnArchiveProjectRequest](
	[RequestId] [int] IDENTITY(1,1) NOT NULL,
	[SLC_ArchiveProjectId] [int] NOT NULL,
	[SLCProd_ProjectId] [int] NOT NULL,
	[ProjectName] [nvarchar](500) NOT NULL,
	[SLC_CustomerId] [int] NOT NULL,
	[SLC_UserId] [int] NOT NULL,
	[RequestDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[RequestType] [int] NOT NULL,
	[StatusId] [int] NOT NULL,
	[IsNotify] [bit] NULL,
	[ProgressInPercentage] [int] NULL,
	[EmailFlag] [bit] NULL,
	[IsDeleted] [bit] NOT NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
 CONSTRAINT [PK_UnArchiveProjectRequest_RequestId] PRIMARY KEY CLUSTERED 
(
	[RequestId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
PRINT 'UnArchiveProjectRequest table created successfully.';
END
ELSE
PRINT 'UnArchiveProjectRequest table already exists.';
GO

IF (NOT EXISTS(SELECT 1 FROM sysconstraints WHERE OBJECT_NAME(constid) = 'FK_UnArchiveStepProgress_RequestId' AND OBJECT_NAME(id) = 'UnArchiveStepProgress'))
 BEGIN
ALTER TABLE UnArchiveStepProgress  WITH NOCHECK ADD  CONSTRAINT [FK_UnArchiveStepProgress_RequestId] FOREIGN KEY(RequestId)
REFERENCES UnArchiveProjectRequest (RequestId)
END
ELSE 
Print 'Already exists FK_UnArchiveStepProgress_RequestId in Table UnArchiveStepProgress'
GO

--ALTER TABLE [dbo].[UnArchiveProjectRequest] ADD  DEFAULT ((0)) FOR [IsDeleted]
--GO

IF (NOT EXISTS(SELECT 1 FROM sysconstraints WHERE OBJECT_NAME(constid) = 'FK_UnArchiveProjectRequest_UnArchiveRequestType' AND OBJECT_NAME(id) = 'UnArchiveProjectRequest'))
BEGIN
ALTER TABLE [dbo].[UnArchiveProjectRequest]  WITH NOCHECK ADD  CONSTRAINT [FK_UnArchiveProjectRequest_UnArchiveRequestType] FOREIGN KEY([RequestType])
REFERENCES [dbo].[LuUnArchiveRequestType] ([RequestTypeId])
END
ELSE 
Print 'Already exists FK_UnArchiveProjectRequest_UnArchiveRequestType in Table UnArchiveStepProgress'
GO

ALTER TABLE [dbo].[UnArchiveProjectRequest] CHECK CONSTRAINT [FK_UnArchiveProjectRequest_UnArchiveRequestType]
GO

IF (NOT EXISTS(SELECT 1 FROM sysconstraints WHERE OBJECT_NAME(constid) = 'FK_UnArchiveProjectRequest_UnArchiveStatus' AND OBJECT_NAME(id) = 'UnArchiveProjectRequest'))
BEGIN
ALTER TABLE [dbo].[UnArchiveProjectRequest]  WITH NOCHECK ADD  CONSTRAINT [FK_UnArchiveProjectRequest_UnArchiveStatus] FOREIGN KEY([StatusId])
REFERENCES [dbo].[LuUnArchiveRequestStatus] ([StatusId])
END
ELSE 
Print 'Already exists FK_UnArchiveProjectRequest_UnArchiveStatus in Table UnArchiveProjectRequest'
GO

ALTER TABLE [dbo].[UnArchiveProjectRequest] CHECK CONSTRAINT [FK_UnArchiveProjectRequest_UnArchiveStatus]
GO
