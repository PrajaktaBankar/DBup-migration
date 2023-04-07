CREATE TABLE [dbo].[ProjectRevitFileMapping] (
    [ProjectRevitFileMappingId] INT           IDENTITY (1, 1) NOT NULL,
    [RevitFileId]               INT           NOT NULL,
    [ProjectId]                 INT           NOT NULL,
    [IsActive]                  BIT           NOT NULL,
    [CreateDate]                DATETIME2 (7) NULL,
    [ModifiedDate]              DATETIME2 (7) NULL,
    [CustomerId]                INT           NOT NULL,
    [CreatedBy]                 INT           NULL,
    CONSTRAINT [PK_PROJECTREVITFILEMAPPING] PRIMARY KEY CLUSTERED ([ProjectRevitFileMappingId] ASC),
    CONSTRAINT [FK_ProjectRevitFileMapping_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectRevitFileMapping_ProjectRevitFile] FOREIGN KEY ([RevitFileId]) REFERENCES [dbo].[ProjectRevitFile] ([RevitFileId])
);

