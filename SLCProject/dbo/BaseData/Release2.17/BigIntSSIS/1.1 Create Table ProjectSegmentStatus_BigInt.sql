USE [SLCProject]
GO

/****** Object:  Table [dbo].[ProjectSegmentStatus_BigInt]    Script Date: 4/27/2021 6:06:36 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ProjectSegmentStatus_BigInt](
	[SegmentStatusId] [bigint] IDENTITY(1,1) NOT NULL,
	[SectionId] [int] NOT NULL,
	[ParentSegmentStatusId] [bigint] NULL,
	[mSegmentStatusId] [int] NULL,
	[mSegmentId] [int] NULL,
	[SegmentId] [bigint] NULL,
	[SegmentSource] [char](1) NULL,
	[SegmentOrigin] [char](1) NULL,
	[IndentLevel] [tinyint] NOT NULL,
	[SequenceNumber] [decimal](18, 4) NOT NULL,
	[SpecTypeTagId] [int] NULL,
	[SegmentStatusTypeId] [int] NULL,
	[IsParentSegmentStatusActive] [bit] NULL,
	[ProjectId] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,
	[SegmentStatusCode] [bigint] NULL,
	[IsShowAutoNumber] [bit] NULL,
	[IsRefStdParagraph] [bit] NOT NULL,
	[FormattingJson] [nvarchar](255) NULL,
	[CreateDate] [datetime2](7) NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[ModifiedBy] [int] NULL,
	[IsPageBreak] [bit] NOT NULL,
	[SLE_DocID] [int] NULL,
	[SLE_ParentID] [int] NULL,
	[SLE_SegmentID] [int] NULL,
	[SLE_ProjectSegID] [int] NULL,
	[SLE_StatusID] [int] NULL,
	[A_SegmentStatusId] [bigint] NULL,
	[IsDeleted] [bit] NULL,
	[TrackOriginOrder] [nvarchar](2) NULL,
	[MTrackDescription] [nvarchar](max) NULL,
 CONSTRAINT [PK_PROJECTSEGMENTSTATUS_BigInt] PRIMARY KEY CLUSTERED 
(
	[SegmentStatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[ProjectSegmentStatus_BigInt] ADD  CONSTRAINT [Default_ProjectSegmentStatus_BigInt_SegmentStatusCode]  DEFAULT (NEXT VALUE FOR [seq_ProjectSegmentStatus]) FOR [SegmentStatusCode]
GO

ALTER TABLE [dbo].[ProjectSegmentStatus_BigInt] ADD  DEFAULT ((0)) FOR [IsRefStdParagraph]
GO

ALTER TABLE [dbo].[ProjectSegmentStatus_BigInt] ADD  DEFAULT ((0)) FOR [IsPageBreak]
GO

ALTER TABLE [dbo].[ProjectSegmentStatus_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegmentStatus_BigInt_LuProjectSegmentStatusType] FOREIGN KEY([SegmentStatusTypeId])
REFERENCES [dbo].[LuProjectSegmentStatusType] ([SegmentStatusTypeId])
GO

ALTER TABLE [dbo].[ProjectSegmentStatus_BigInt] CHECK CONSTRAINT [FK_ProjectSegmentStatus_BigInt_LuProjectSegmentStatusType]
GO

ALTER TABLE [dbo].[ProjectSegmentStatus_BigInt]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegmentStatus_BigInt_LuProjectSpecTypeTag] FOREIGN KEY([SpecTypeTagId])
REFERENCES [dbo].[LuProjectSpecTypeTag] ([SpecTypeTagId])
GO

ALTER TABLE [dbo].[ProjectSegmentStatus_BigInt] CHECK CONSTRAINT [FK_ProjectSegmentStatus_BigInt_LuProjectSpecTypeTag]
GO


