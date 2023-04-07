USE [SLCProject]
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'LuSectionSource'))
BEGIN

CREATE TABLE LuSectionSource
(
	Id INT IDENTITY(1,1) NOT NULL,
	[Name] NVARCHAR(100) NOT NULL,
	[Description] NVARCHAR(150) NOT NULL,
	CONSTRAINT [PK_LuSectionSource] PRIMARY KEY CLUSTERED 
	(
		Id ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]

PRINT 'LuSectionSource table created successfully.';
END
ELSE
PRINT 'LuSectionSource table already exists.';
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsBlobCopied' AND Object_ID = Object_ID(N'[dbo].[UnArchiveProjectRequest]'))
BEGIN
	ALTER TABLE UnArchiveProjectRequest ADD IsBlobCopied INT NULL DEFAULT (0);
    PRINT 'IsBlobCopied Column Added.';
END
Else 
PRINT 'IsBlobCopied Column already exists.';
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'SectionSource' AND Object_ID = Object_ID(N'[dbo].[ProjectSection]'))
BEGIN
	ALTER TABLE ProjectSection ADD SectionSource INT NULL DEFAULT (1);
    PRINT 'SectionSource Column Added.';
END
Else 
PRINT 'SectionSource Column already exists.';
GO

ALTER TABLE ProjectSection
ADD CONSTRAINT [FK_ProjectSection_LuSectionSource] FOREIGN KEY (SectionSource) REFERENCES [dbo].LuSectionSource (id)
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'SectionId' AND Object_ID = Object_ID(N'[dbo].[ProjectPageSetting]'))
BEGIN
	ALTER TABLE ProjectPageSetting ADD SectionId INT NULL;
    PRINT 'SectionId Column Added.';
END
Else 
PRINT 'SectionId Column already exists.';
GO

IF NOT EXISTS(SELECT 1 FROM SYS.OBJECTS WHERE TYPE = 'F' AND NAME = 'FK_ProjectPageSetting_ProjectSection')
BEGIN
	ALTER TABLE [dbo].[ProjectPageSetting] 
	ADD  CONSTRAINT [FK_ProjectPageSetting_ProjectSection] FOREIGN KEY([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId])
	PRINT 'FK_ProjectPageSetting_ProjectSection Constraint Added.';
END
Else 
	PRINT 'FK_ProjectPageSetting_ProjectSection Constraint already exists.';
GO


IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'TypeId' AND Object_ID = Object_ID(N'[dbo].[ProjectPageSetting]'))
BEGIN
	ALTER TABLE ProjectPageSetting ADD TypeId INT NOT NULL DEFAULT (1);
    PRINT 'TypeId Column Added.';
END
Else 
PRINT 'TypeId Column already exists.';
GO

IF NOT EXISTS(SELECT 1 FROM SYS.OBJECTS WHERE TYPE = 'F' AND NAME = 'FK_ProjectPageSetting_LuHeaderFooterType')
BEGIN
	ALTER TABLE [dbo].[ProjectPageSetting] 
	ADD  CONSTRAINT [FK_ProjectPageSetting_LuHeaderFooterType] FOREIGN KEY([TypeId]) REFERENCES [dbo].[LuHeaderFooterType] ([TypeId])
	PRINT 'FK_ProjectPageSetting_LuHeaderFooterType Constraint Added.';
END
Else 
	PRINT 'FK_ProjectPageSetting_LuHeaderFooterType Constraint already exists.';
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'SectionId' AND Object_ID = Object_ID(N'[dbo].[ProjectPaperSetting]'))
BEGIN
	ALTER TABLE ProjectPaperSetting ADD SectionId INT NULL;
    PRINT 'SectionId Column Added.';
END
Else 
PRINT 'SectionId Column already exists.';
GO

IF NOT EXISTS(SELECT 1 FROM SYS.OBJECTS WHERE TYPE = 'F' AND NAME = 'FK_ProjectPaperSetting_ProjectSection')
BEGIN
	ALTER TABLE [dbo].[ProjectPaperSetting] 
	ADD  CONSTRAINT [FK_ProjectPaperSetting_ProjectSection] FOREIGN KEY([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId])
    PRINT 'FK_ProjectPaperSetting_ProjectSection Constraint Added.';
END
Else 
PRINT 'FK_ProjectPaperSetting_ProjectSection Constraint already exists.';
GO


IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'LuSectionDocumentType'))
BEGIN

CREATE TABLE LuSectionDocumentType
(
	SectionDocumentId INT IDENTITY(1,1) NOT NULL,
	 [Type] NVARCHAR(100) NOT NULL,
	[Description] NVARCHAR(150) NOT NULL,
	CONSTRAINT [PK_LuSectionDocumentType] PRIMARY KEY CLUSTERED 
	(
		SectionDocumentId ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]

PRINT 'LuSectionDocumentType table created successfully.';
END
ELSE
PRINT 'LuSectionDocumentType table already exists.';
GO


IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'SectionDocument'))
BEGIN

CREATE TABLE SectionDocument
(
	SectionFormId INT IDENTITY(1,1) NOT NULL,
	[ProjectId] INT NOT NULL,
	SectionId INT NOT NULL,
	[SectionDocumentTypeId] INT NOT NULL,
	[DocumentPath] NVARCHAR(150) NULL,
	[OriginalFileName] NVARCHAR(500) NULL,
	[IsDeleted] BIT NULL,
	[ModifiedBy] INT NULL,
	[ModifiedDate] DATETIME2 (7) NULL,
	[CreateDate] DATETIME2 (7)  NOT NULL,
    [CreatedBy]   INT  NOT NULL,
	CONSTRAINT [PK_SectionDocument] PRIMARY KEY CLUSTERED 
	(
		SectionFormId ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]

PRINT 'SectionDocument table created successfully.';
END
ELSE
PRINT 'SectionDocument table already exists.';
GO

ALTER TABLE SectionDocument
ADD CONSTRAINT [FK_SectionDocument_ProjectSection] FOREIGN KEY (SectionId) REFERENCES [dbo].ProjectSection (SectionId)
GO

ALTER TABLE SectionDocument
ADD CONSTRAINT [FK_SectionDocument_LuSectionDocumentType] FOREIGN KEY (SectionDocumentTypeId) REFERENCES [dbo].LuSectionDocumentType (SectionDocumentId)
GO


IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'ExcludeFromAutoArchive'))
BEGIN

CREATE TABLE [dbo].[ExcludeFromAutoArchive](
	[RowId] [int] IDENTITY(1,1) NOT NULL,
	[CustomerId] [int] NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL
) ON [PRIMARY]


PRINT 'ExcludeFromAutoArchive table created successfully.';
END
ELSE
PRINT 'ExcludeFromAutoArchive table already exists.';
GO


ALTER TABLE [dbo].[ExcludeFromAutoArchive] ADD  CONSTRAINT [DF_ExcludeFromAutoArchive_CreatedDate]  DEFAULT (getutcdate()) FOR [CreatedDate]
GO
