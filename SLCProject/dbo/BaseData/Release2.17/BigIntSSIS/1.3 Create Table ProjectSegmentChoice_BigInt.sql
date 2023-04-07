USE [SLCProject]
GO

/****** Object:  Table [dbo].[ProjectSegmentChoice_BigInt]    Script Date: 4/27/2021 6:20:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ProjectSegmentChoice_BigInt](
	[SegmentChoiceId] [bigint] IDENTITY(1,1) NOT NULL,
	[SectionId] [int] NOT NULL,
	[SegmentStatusId] [bigint] NULL,
	[SegmentId] [bigint] NULL,
	[ChoiceTypeId] [int] NULL,
	[ProjectId] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,
	[SegmentChoiceSource] [char](1) NULL,
	[SegmentChoiceCode] [bigint] NULL,
	[CreatedBy] [int] NOT NULL,
	[CreateDate] [datetime2](7) NOT NULL,
	[ModifiedBy] [int] NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[SLE_DocID] [int] NULL,
	[SLE_SegmentID] [int] NULL,
	[SLE_StatusID] [int] NULL,
	[SLE_ChoiceNo] [int] NULL,
	[SLE_ChoiceTypeID] [tinyint] NULL,
	[A_SegmentChoiceId] [bigint] NULL,
	[IsDeleted] [bit] NULL,
 CONSTRAINT [PK_PROJECTSEGMENTCHOICE_BigInt] PRIMARY KEY CLUSTERED 
(
	[SegmentChoiceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ProjectSegmentChoice_BigInt] ADD  CONSTRAINT [Default_ProjectSegmentChoice_BigInt_SegmentChoiceCode]  DEFAULT (NEXT VALUE FOR [seq_ProjectSegmentChoice]) FOR [SegmentChoiceCode]
GO

ALTER TABLE [dbo].[ProjectSegmentChoice_BigInt] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO

ALTER TABLE [dbo].[ProjectSegmentChoice_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegmentChoice_BigInt_LuProjectChoiceType] FOREIGN KEY([ChoiceTypeId])
REFERENCES [dbo].[LuProjectChoiceType] ([ChoiceTypeId])
GO

ALTER TABLE [dbo].[ProjectSegmentChoice_BigInt] CHECK CONSTRAINT [FK_ProjectSegmentChoice_BigInt_LuProjectChoiceType]
GO

ALTER TABLE [dbo].[ProjectSegmentChoice_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegmentChoice_BigInt_Project] FOREIGN KEY([ProjectId])
REFERENCES [dbo].[Project] ([ProjectId])
GO

ALTER TABLE [dbo].[ProjectSegmentChoice_BigInt] CHECK CONSTRAINT [FK_ProjectSegmentChoice_BigInt_Project]
GO

ALTER TABLE [dbo].[ProjectSegmentChoice_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegmentChoice_BigInt_ProjectSection] FOREIGN KEY([SectionId])
REFERENCES [dbo].[ProjectSection] ([SectionId])
GO

ALTER TABLE [dbo].[ProjectSegmentChoice_BigInt] CHECK CONSTRAINT [FK_ProjectSegmentChoice_BigInt_ProjectSection]
GO

ALTER TABLE [dbo].[ProjectSegmentChoice_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegmentChoice_BigInt_ProjectSegment] FOREIGN KEY([SegmentId])
REFERENCES [dbo].[ProjectSegment_BigInt] ([SegmentId])
GO

ALTER TABLE [dbo].[ProjectSegmentChoice_BigInt] CHECK CONSTRAINT [FK_ProjectSegmentChoice_BigInt_ProjectSegment]
GO

ALTER TABLE [dbo].[ProjectSegmentChoice_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegmentChoice_BigInt_ProjectSegmentStatus] FOREIGN KEY([SegmentStatusId])
REFERENCES [dbo].[ProjectSegmentStatus_BigInt] ([SegmentStatusId])
GO

ALTER TABLE [dbo].[ProjectSegmentChoice_BigInt] CHECK CONSTRAINT [FK_ProjectSegmentChoice_BigInt_ProjectSegmentStatus]
GO


