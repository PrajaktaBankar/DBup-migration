USE [SLCProject]
GO

/****** Object:  Table [dbo].[ProjectSegmentLink_BigInt]    Script Date: 4/27/2021 6:32:03 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ProjectSegmentLink_BigInt](
	[SegmentLinkId] [bigint] IDENTITY(1,1) NOT NULL,
	[SourceSectionCode] [int] NOT NULL,
	[SourceSegmentStatusCode] [bigint] NOT NULL,
	[SourceSegmentCode] [bigint] NOT NULL,
	[SourceSegmentChoiceCode] [bigint] NULL,
	[SourceChoiceOptionCode] [bigint] NULL,
	[LinkSource] [varchar](1) NULL,
	[TargetSectionCode] [int] NOT NULL,
	[TargetSegmentStatusCode] [bigint] NOT NULL,
	[TargetSegmentCode] [bigint] NOT NULL,
	[TargetSegmentChoiceCode] [bigint] NULL,
	[TargetChoiceOptionCode] [bigint] NULL,
	[LinkTarget] [varchar](1) NULL,
	[LinkStatusTypeId] [int] NULL,
	[IsDeleted] [bit] NOT NULL,
	[CreateDate] [datetime2](7) NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[ModifiedBy] [int] NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[ProjectId] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,
	[SegmentLinkCode] [bigint] NULL,
	[SegmentLinkSourceTypeId] [int] NULL,
 CONSTRAINT [PK_PROJECTSEGMENTLINK_BigInt] PRIMARY KEY CLUSTERED 
(
	[SegmentLinkId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ProjectSegmentLink_BigInt] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO

ALTER TABLE [dbo].[ProjectSegmentLink_BigInt] ADD  CONSTRAINT [Default_ProjectSegmentLink_BigInt_SegmentLinkCode]  DEFAULT (NEXT VALUE FOR [seq_ProjectSegmentLink]) FOR [SegmentLinkCode]
GO

ALTER TABLE [dbo].[ProjectSegmentLink_BigInt] ADD  DEFAULT ((5)) FOR [SegmentLinkSourceTypeId]
GO

ALTER TABLE [dbo].[ProjectSegmentLink_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegmentLink_BigInt_LuSegmentLinkSourceType] FOREIGN KEY([SegmentLinkSourceTypeId])
REFERENCES [dbo].[LuSegmentLinkSourceType] ([SegmentLinkSourceTypeId])
GO

ALTER TABLE [dbo].[ProjectSegmentLink_BigInt] CHECK CONSTRAINT [FK_ProjectSegmentLink_BigInt_LuSegmentLinkSourceType]
GO

ALTER TABLE [dbo].[ProjectSegmentLink_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegmentLink_BigInt_ProjectSegmentLink] FOREIGN KEY([LinkStatusTypeId])
REFERENCES [dbo].[LuProjectLinkStatusType] ([LinkStatusTypeId])
GO

ALTER TABLE [dbo].[ProjectSegmentLink_BigInt] CHECK CONSTRAINT [FK_ProjectSegmentLink_BigInt_ProjectSegmentLink]
GO


