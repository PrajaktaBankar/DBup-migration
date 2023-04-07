USE BPMCore_Staging_SLC
GO

/****** Object:  Table [dbo].[ProjectSegment]    Script Date: 7/20/2022 4:32:09 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
drop table [ProjectSegment_3228]
go
CREATE TABLE [dbo].[ProjectSegment_3228](
	[SegmentId] [bigint] NULL,
	[SegmentStatusId] [bigint] NULL,
	[SectionId] [int] NULL,
	[ProjectId] [int] NULL,
	[CustomerId] [int] NULL,
	[SegmentDescription] [nvarchar](max) NULL,
	[SegmentSource] [char](1) NULL,
	[SegmentCode] [bigint] NULL,
	[CreatedBy] [int] NULL,
	[CreateDate] [datetime2](7) NULL,
	[ModifiedBy] [int] NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[SLE_DocID] [int] NULL,
	[SLE_SegmentID] [int] NULL,
	[SLE_StatusID] [int] NULL,
	[A_SegmentId] [bigint] NULL,
	[IsDeleted] [bit] NULL,
	[BaseSegmentDescription] [nvarchar](max) NULL,
	[BackupRunDate] datetime2
	)
GO
