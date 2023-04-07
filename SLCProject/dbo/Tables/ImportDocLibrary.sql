CREATE TABLE [dbo].[ImportDocLibrary](
	[DocLibraryId] [bigint] IDENTITY(1,1) NOT NULL,
	[CustomerId] [int] NOT NULL,
	[DocumentTypeId] [int] NULL,
	[DocumentPath] [nvarchar](1000) NULL,
	[OriginalFileName] [nvarchar](500) NULL,
	[FileGUID] [uniqueidentifier] NULL DEFAULT (newsequentialid()),
	[FileSize] [nvarchar](100) NULL,
	[IsDeleted] [bit] NULL CONSTRAINT [DF_ImportDocLibrary_IsDeleted] DEFAULT ((0)),
	[CreatedDate] [datetime2](7) NULL,
	[CreatedBy] [int] NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[ModifiedBy] [int] NULL,
	[A_DocLibraryId] [int] NULL,
 CONSTRAINT [PK_ImportDocLibrary] PRIMARY KEY CLUSTERED ([DocLibraryId] ASC) WITH (FILLFACTOR = 80),
 CONSTRAINT [FK_ImportDocLibrary_LuImportedDocType] FOREIGN KEY ([DocumentTypeId]) REFERENCES [dbo].[LuImportedDocType] ([ImportedDocTypeId])
)
GO

CREATE NONCLUSTERED INDEX [IX_ImportDocLibrary_CustomerId] ON [dbo].[ImportDocLibrary]([CustomerId] ASC)
INCLUDE([DocumentPath],[OriginalFileName]);
GO