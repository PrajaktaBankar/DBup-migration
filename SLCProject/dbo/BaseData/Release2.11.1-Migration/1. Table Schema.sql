Use SLCProject 
GO
DROP TABLE IF EXISTS LuUnArchiveRequestType
GO

CREATE TABLE LuUnArchiveRequestType(
	[RequestTypeId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[TypeDescription] [nvarchar](50) NULL,
 CONSTRAINT [PK_UnArchiveRequestType] PRIMARY KEY CLUSTERED 
(
	[RequestTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO

DROP TABLE IF EXISTS LuUnArchiveRequestStatus
GO
CREATE TABLE [dbo].[LuUnArchiveRequestStatus](
	[StatusId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[StatusDescription] [nvarchar](50) NULL,
 CONSTRAINT [PK_UnArchiveStatus] PRIMARY KEY CLUSTERED 
(
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO

DROP TABLE IF EXISTS Logging
GO
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
GO

DROP TABLE IF EXISTS UnArchiveStepProgress
GO
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
GO

ALTER TABLE UnArchiveStepProgress  WITH NOCHECK ADD  CONSTRAINT [FK_UnArchiveStepProgress_RequestId] FOREIGN KEY(RequestId)
REFERENCES UnArchiveProjectRequest (RequestId)
GO

DROP TABLE IF EXISTS UnArchiveProjectRequest
GO
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
GO

ALTER TABLE [dbo].[UnArchiveProjectRequest] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO

ALTER TABLE [dbo].[UnArchiveProjectRequest]  WITH NOCHECK ADD  CONSTRAINT [FK_UnArchiveProjectRequest_UnArchiveRequestType] FOREIGN KEY([RequestType])
REFERENCES [dbo].[LuUnArchiveRequestType] ([RequestTypeId])
GO

ALTER TABLE [dbo].[UnArchiveProjectRequest] CHECK CONSTRAINT [FK_UnArchiveProjectRequest_UnArchiveRequestType]
GO

ALTER TABLE [dbo].[UnArchiveProjectRequest]  WITH NOCHECK ADD  CONSTRAINT [FK_UnArchiveProjectRequest_UnArchiveStatus] FOREIGN KEY([StatusId])
REFERENCES [dbo].[LuUnArchiveRequestStatus] ([StatusId])
GO

ALTER TABLE [dbo].[UnArchiveProjectRequest] CHECK CONSTRAINT [FK_UnArchiveProjectRequest_UnArchiveStatus]
GO
