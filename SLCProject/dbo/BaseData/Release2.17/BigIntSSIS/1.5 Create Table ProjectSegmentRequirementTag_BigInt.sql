USE [SLCProject]
GO

/****** Object:  Table [dbo].[ProjectSegmentRequirementTag_BigInt]    Script Date: 4/27/2021 6:29:45 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ProjectSegmentRequirementTag_BigInt](
	[SegmentRequirementTagId] [bigint] IDENTITY(1,1) NOT NULL,
	[SectionId] [int] NOT NULL,
	[SegmentStatusId] [bigint] NULL,
	[RequirementTagId] [int] NOT NULL,
	[CreateDate] [datetime2](7) NOT NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[ProjectId] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[ModifiedBy] [int] NULL,
	[mSegmentRequirementTagId] [int] NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_PROJECTSEGMENTREQUIREMENTTAG_BigInt] PRIMARY KEY CLUSTERED 
(
	[SegmentRequirementTagId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ProjectSegmentRequirementTag_BigInt] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO

ALTER TABLE [dbo].[ProjectSegmentRequirementTag_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegmentRequirementTag_BigInt_LuProjectRequirementTag] FOREIGN KEY([RequirementTagId])
REFERENCES [dbo].[LuProjectRequirementTag] ([RequirementTagId])
GO

ALTER TABLE [dbo].[ProjectSegmentRequirementTag_BigInt] CHECK CONSTRAINT [FK_ProjectSegmentRequirementTag_BigInt_LuProjectRequirementTag]
GO

ALTER TABLE [dbo].[ProjectSegmentRequirementTag_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegmentRequirementTag_BigInt_Project] FOREIGN KEY([ProjectId])
REFERENCES [dbo].[Project] ([ProjectId])
GO

ALTER TABLE [dbo].[ProjectSegmentRequirementTag_BigInt] CHECK CONSTRAINT [FK_ProjectSegmentRequirementTag_BigInt_Project]
GO

ALTER TABLE [dbo].[ProjectSegmentRequirementTag_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegmentRequirementTag_BigInt_ProjectSegmentStatus] FOREIGN KEY([SegmentStatusId])
REFERENCES [dbo].[ProjectSegmentStatus_BigInt] ([SegmentStatusId])
GO

ALTER TABLE [dbo].[ProjectSegmentRequirementTag_BigInt] CHECK CONSTRAINT [FK_ProjectSegmentRequirementTag_BigInt_ProjectSegmentStatus]
GO


