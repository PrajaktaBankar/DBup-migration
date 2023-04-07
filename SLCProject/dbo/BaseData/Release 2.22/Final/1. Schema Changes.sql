USE [SLCProject]
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'LuImportedDocType'))
BEGIN

CREATE TABLE [dbo].[LuImportedDocType](
	[ImportedDocTypeId] [int] IDENTITY(1,1) NOT NULL,
	[DocType] [nvarchar](100) NULL,
	[Description] [nvarchar](150) NULL,
 CONSTRAINT [PK_LuImportedDocType] PRIMARY KEY CLUSTERED ([ImportedDocTypeId] ASC) WITH (FILLFACTOR = 80)
);

PRINT 'LuImportedDocType table created successfully.';
END
ELSE
PRINT 'LuImportedDocType table already exists.';
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'ImportDocLibrary'))
BEGIN

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
 CONSTRAINT [PK_ImportDocLibrary] PRIMARY KEY CLUSTERED ([DocLibraryId] ASC) WITH (FILLFACTOR = 80),
 CONSTRAINT [FK_ImportDocLibrary_LuImportedDocType] FOREIGN KEY ([DocumentTypeId]) REFERENCES [dbo].[LuImportedDocType] ([ImportedDocTypeId])
)
PRINT 'ImportDocLibrary table created successfully.';
END
ELSE
PRINT 'ImportDocLibrary table already exists.';
GO



IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'DocLibraryMapping'))
BEGIN

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
	[AttachedByFullName] [nvarchar](500) NULL,
 CONSTRAINT [PK_DocLibraryMapping] PRIMARY KEY CLUSTERED ([DocMappingId] ASC) WITH (FILLFACTOR = 80)
)
PRINT 'DocLibraryMapping table created successfully.';
END
ELSE
PRINT 'DocLibraryMapping table already exists.';
GO


IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsIncludeAttachedDocuments' AND Object_ID = Object_ID(N'[dbo].[ProjectPrintSetting]'))
BEGIN
	ALTER TABLE ProjectPrintSetting ADD IsIncludeAttachedDocuments [bit] NOT NULL DEFAULT ((0))
    PRINT 'IsIncludeAttachedDocuments Column Added.';
END
Else 
PRINT 'IsIncludeAttachedDocuments Column already exists.';
GO


IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'UpdateStatisticsLog'))
BEGIN

CREATE TABLE [dbo].[UpdateStatisticsLog](
	[StatLogId] [int] IDENTITY(1,1) NOT NULL,
	[TableName] [nvarchar](250) NOT NULL,
	[StartTime] [datetime] NOT NULL,
	[EndTime] [datetime] NULL	
) ON [PRIMARY]
PRINT 'UpdateStatisticsLog table created successfully.';
END
ELSE
PRINT 'UpdateStatisticsLog table already exists.';
GO
