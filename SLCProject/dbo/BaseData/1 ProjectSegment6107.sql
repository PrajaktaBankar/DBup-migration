USE [SLCProject]
GO

/****** Object:  Table [dbo].[ProjectSegment6107]    Script Date: 22-01-2020 02:35:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ProjectSegment6107](
	[SegmentId] [int] IDENTITY(1,1) NOT NULL,
	[SegmentStatusId] [int] NULL,
	[SectionId] [int] NOT NULL,
	[ProjectId] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,
	[SegmentDescription] [nvarchar](max) NULL,
	[SegmentSource] [char](1) NULL,
	[SegmentCode] [int] NULL,
	[CreatedBy] [int] NOT NULL,
	[CreateDate] [datetime2](7) NOT NULL,
	[ModifiedBy] [int] NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[SLE_DocID] [int] NULL,
	[SLE_SegmentID] [int] NULL,
	[SLE_StatusID] [int] NULL,
	[A_SegmentId] [int] NULL,
	[IsDeleted] [bit] NOT NULL,
	[BaseSegmentDescription] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


