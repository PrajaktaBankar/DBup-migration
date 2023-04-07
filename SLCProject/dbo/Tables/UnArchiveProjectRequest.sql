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
    [IsBlobCopied] BIT NOT NULL DEFAULT ((0)), 
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
