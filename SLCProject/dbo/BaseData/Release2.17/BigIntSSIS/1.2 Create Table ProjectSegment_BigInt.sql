USE [SLCProject]
GO

/****** Object:  Table [dbo].[ProjectSegment_BigInt]    Script Date: 4/27/2021 6:16:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ProjectSegment_BigInt](
	[SegmentId] [bigint] IDENTITY(1,1) NOT NULL,
	[SegmentStatusId] [bigint] NULL,
	[SectionId] [int] NOT NULL,
	[ProjectId] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,
	[SegmentDescription] [nvarchar](max) NULL,
	[SegmentSource] [char](1) NULL,
	[SegmentCode] [bigint] NULL,
	[CreatedBy] [int] NOT NULL,
	[CreateDate] [datetime2](7) NOT NULL,
	[ModifiedBy] [int] NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[SLE_DocID] [int] NULL,
	[SLE_SegmentID] [int] NULL,
	[SLE_StatusID] [int] NULL,
	[A_SegmentId] [bigint] NULL,
	[IsDeleted] [bit] NOT NULL,
	[BaseSegmentDescription] [nvarchar](max) NULL,
 CONSTRAINT [PK_PROJECTSEGMENT_BigInt] PRIMARY KEY CLUSTERED 
(
	[SegmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[ProjectSegment_BigInt] ADD  CONSTRAINT [Default_ProjectSegment_BigInt_SegmentCode]  DEFAULT (NEXT VALUE FOR [seq_ProjectSegment]) FOR [SegmentCode]
GO

ALTER TABLE [dbo].[ProjectSegment_BigInt] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO

ALTER TABLE [dbo].[ProjectSegment_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegments_BigInt_Projects] FOREIGN KEY([ProjectId])
REFERENCES [dbo].[Project] ([ProjectId])
GO

ALTER TABLE [dbo].[ProjectSegment_BigInt] CHECK CONSTRAINT [FK_ProjectSegments_BigInt_Projects]
GO

ALTER TABLE [dbo].[ProjectSegment_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegments_BigInt_ProjectSections] FOREIGN KEY([SectionId])
REFERENCES [dbo].[ProjectSection] ([SectionId])
GO

ALTER TABLE [dbo].[ProjectSegment_BigInt] CHECK CONSTRAINT [FK_ProjectSegments_BigInt_ProjectSections]
GO

ALTER TABLE [dbo].[ProjectSegment_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegments_BigInt_ProjectSegmentStatus] FOREIGN KEY([SegmentStatusId])
REFERENCES [dbo].[ProjectSegmentStatus_BigInt] ([SegmentStatusId])
GO

ALTER TABLE [dbo].[ProjectSegment_BigInt] CHECK CONSTRAINT [FK_ProjectSegments_BigInt_ProjectSegmentStatus]
GO


