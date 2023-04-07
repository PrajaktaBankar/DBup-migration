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
	CONSTRAINT [PK_SectionDocument] PRIMARY KEY CLUSTERED (SectionFormId ASC),
	CONSTRAINT [FK_SectionDocument_ProjectSection] FOREIGN KEY (SectionId) REFERENCES [dbo].ProjectSection (SectionId),
	CONSTRAINT [FK_SectionDocument_LuSectionDocumentType] FOREIGN KEY (SectionDocumentTypeId) REFERENCES [dbo].LuSectionDocumentType (SectionDocumentId)
)