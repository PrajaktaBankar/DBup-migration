CREATE TABLE [dbo].[TrackSegmentStatusType](
	[SegmentStatusTrackId] [int] IDENTITY(1,1) NOT NULL,
	[ProjectId] [int] NOT NULL,
	[SectionId] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,
	[SegmentStatusId] BIGINT NOT NULL,
	[SegmentStatusTypeId] [int] NOT NULL,
	[PrevStatusSegmentStatusTypeId] [int] NULL,
	[InitialStatusSegmentStatusTypeId] [int] NULL,
	[InitialStatus] [bit] NULL,
	[CurrentStatus] [bit] NULL,
	[IsAccepted] [bit] NULL,
	[UserId] [int] NOT NULL,
	[UserFullName] [nvarchar](500) NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[ModifiedById] [int] NULL,
	[ModifiedByUserFullName] [nvarchar](500) NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[TenantId] [nvarchar](100) NULL,
	[IsSegmentStatusChangeBySelection] BIT,
	[SegmentStatusTypeIdBeforeSelection] INT NULL
PRIMARY KEY CLUSTERED 
(
	[SegmentStatusTrackId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TrackSegmentStatusType]  WITH CHECK ADD  CONSTRAINT [FK_ProjectId] FOREIGN KEY([ProjectId])
REFERENCES [dbo].[Project] ([ProjectId])
GO
ALTER TABLE [dbo].[TrackSegmentStatusType] CHECK CONSTRAINT [FK_ProjectId]
GO
ALTER TABLE [dbo].[TrackSegmentStatusType]  WITH CHECK ADD  CONSTRAINT [FK_SectionId] FOREIGN KEY([SectionId])
REFERENCES [dbo].[ProjectSection] ([SectionId])
GO
ALTER TABLE [dbo].[TrackSegmentStatusType] CHECK CONSTRAINT [FK_SectionId]
GO
ALTER TABLE [dbo].[TrackSegmentStatusType]  WITH CHECK ADD  CONSTRAINT [FK_SegmentStatusId] FOREIGN KEY([SegmentStatusId])
REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId])
GO
ALTER TABLE [dbo].[TrackSegmentStatusType]  WITH CHECK ADD  CONSTRAINT [FK_SegmentStatusTypeId] FOREIGN KEY([SegmentStatusTypeId])
REFERENCES [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId])
GO
ALTER TABLE [dbo].[TrackSegmentStatusType] CHECK CONSTRAINT [FK_SegmentStatusId]
GO
CREATE NONCLUSTERED INDEX [CIX_TrackSegmentStatusType_SegmentStatusId] ON [dbo].[TrackSegmentStatusType]
(
	[SegmentStatusId] DESC,
	[SectionId] DESC,
	[ProjectId] DESC
)
INCLUDE ( 
	IsAccepted
	)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO