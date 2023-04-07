CREATE TABLE [dbo].[MaterialSectionMapping] (
    [MaterialSectionMappingId] INT IDENTITY (1, 1) NOT NULL,
    [ProjectId]                INT NOT NULL,
    [SectionId]                INT NOT NULL,
    [MaterialId]               INT NULL,
    [RevitFileId]              INT NOT NULL,
    [CustomerId]               INT NOT NULL,
    [IsActive]                 BIT DEFAULT ((1)) NOT NULL,
    [IsLinked]                 BIT NULL,
    CONSTRAINT [PK_MATERIALSECTIONMAPPING] PRIMARY KEY CLUSTERED ([MaterialSectionMappingId] ASC),
    CONSTRAINT [FK_MaterialSectionMapping_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_MaterialSectionMapping_ProjectSection] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId])
);

