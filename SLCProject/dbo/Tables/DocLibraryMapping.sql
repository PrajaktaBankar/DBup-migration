CREATE TABLE [dbo].[DocLibraryMapping](
	[DocMappingId] [bigint] IDENTITY(1,1) NOT NULL,
	[CustomerId] [int] NOT NULL,
	[ProjectId] [int] NULL,
	[SectionId] [int] NULL,
	[SegmentId] [int] NULL,
	[DocLibraryId] [bigint] NULL,
	[SortOrder] [int] NULL,
	[IsActive] [bit] NULL,
	[IsAttachedToFolder] [bit] NULL,
	[IsDeleted] [bit] NULL CONSTRAINT [DF_DocLibraryMapping_IsDeleted]  DEFAULT ((0)),
	[CreatedDate] [datetime2](7) NULL,
	[CreatedBy] [int] NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[ModifiedBy] [int] NULL,
 CONSTRAINT [PK_DocLibraryMapping] PRIMARY KEY CLUSTERED ([DocMappingId] ASC) WITH (FILLFACTOR = 80)
)
GO

CREATE NONCLUSTERED INDEX [IX_ImportDocLibrary_CustomerId] ON [dbo].[DocLibraryMapping] ([CustomerId] ASC, [ProjectId] ASC, [SectionId] ASC, [IsDeleted] ASC)
INCLUDE([DocLibraryId]);
GO

CREATE NONCLUSTERED INDEX [IX_ImportDocLibrary_DocLibraryId] ON [dbo].[DocLibraryMapping] ([CustomerId] ASC, [DocLibraryId] ASC);
GO