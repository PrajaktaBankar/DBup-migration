CREATE TABLE [dbo].[DocLibraryAttachLog](
	[DocLibraryAttachLogId] [bigint] IDENTITY(1,1) NOT NULL,
	[CustomerId] [int] NOT NULL,
	[ProjectId] [int] NULL,
	[SectionId] [int] NULL,
	[SegmentId] [int] NULL,
	[OrignalFileName] [nvarchar](500) NULL,
	[DocumentPath] [nvarchar](1000) NULL,
	[IsAttachedToFolder] [bit] NULL,
	[CreatedBy] [int] NULL,
	[IsFailed] [bit] NULL,
	[StatusMessage] [nvarchar](MAX) NULL,
	[CreatedDate] [datetime2](7) NULL,
 CONSTRAINT [PK_DocLibraryAttachLog] PRIMARY KEY CLUSTERED 
(
	[DocLibraryAttachLogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


