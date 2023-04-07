USE SLCProject
GO
IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'TrackSegmentStatusType'))
BEGIN
CREATE TABLE [dbo].[TrackSegmentStatusType](
	[SegmentStatusTrackId] [int] IDENTITY(1,1) NOT NULL,
	[ProjectId] [int] NOT NULL,
	[SectionId] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,
	[SegmentStatusId] [int] NOT NULL,
	[SegmentStatusTypeId] [int] NOT NULL,
	[PrevStatusSegmentStatusTypeId] [int] NULL,
	[InitialStatusSegmentStatusTypeId] [int] NULL,
	[IsAccepted] [bit] NULL,
	[UserId] [int] NOT NULL,
	[UserFullName] [nvarchar](500) NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[ModifiedById] [int] NULL,
	[ModifiedByUserFullName] [nvarchar](500) NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[TenantId] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[SegmentStatusTrackId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

ALTER TABLE [dbo].[TrackSegmentStatusType]  WITH CHECK ADD  CONSTRAINT [FK_ProjectId] FOREIGN KEY([ProjectId])
REFERENCES [dbo].[Project] ([ProjectId])

ALTER TABLE [dbo].[TrackSegmentStatusType] CHECK CONSTRAINT [FK_ProjectId]

ALTER TABLE [dbo].[TrackSegmentStatusType]  WITH CHECK ADD  CONSTRAINT [FK_SectionId] FOREIGN KEY([SectionId])
REFERENCES [dbo].[ProjectSection] ([SectionId])

ALTER TABLE [dbo].[TrackSegmentStatusType] CHECK CONSTRAINT [FK_SectionId]

ALTER TABLE [dbo].[TrackSegmentStatusType]  WITH CHECK ADD  CONSTRAINT [FK_SegmentStatusId] FOREIGN KEY([SegmentStatusId])
REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId])

ALTER TABLE [dbo].[TrackSegmentStatusType]  WITH CHECK ADD  CONSTRAINT [FK_SegmentStatusTypeId] FOREIGN KEY([SegmentStatusTypeId])
REFERENCES [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId])

ALTER TABLE [dbo].[TrackSegmentStatusType] CHECK CONSTRAINT [FK_SegmentStatusId]

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


END
ELSE
Print 'TrackSegmentStatusType name already exist'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsIncludePdfBookmark' AND Object_ID = Object_ID(N'[dbo].[ProjectPrintSetting]'))
BEGIN
   ALTER TABLE ProjectPrintSetting ADD IsIncludePdfBookmark BIT NOT NULL DEFAULT(0)
END
ELSE 
Print 'Alread exists IsIncludePdfBookmark'
GO


IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'BookmarkLevel' AND Object_ID = Object_ID(N'[dbo].[ProjectPrintSetting]'))
BEGIN
   ALTER TABLE ProjectPrintSetting ADD BookmarkLevel INT NOT NULL DEFAULT(0)
END
ELSE 
Print 'Alread exists BookmarkLevel'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'InitialStatus' AND Object_ID = Object_ID(N'[dbo].[TrackSegmentStatusType]'))
BEGIN
   ALTER TABLE TrackSegmentStatusType ADD InitialStatus BIT NOT NULL DEFAULT 0
END
ELSE 
Print 'Alread exists InitialStatus'
GO
