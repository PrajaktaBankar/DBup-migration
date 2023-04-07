CREATE TABLE [dbo].[ProjectPageSetting] (
    [ProjectPageSettingId] INT             IDENTITY (1, 1) NOT NULL,
    [MarginTop]            DECIMAL (10, 4) NULL,
    [MarginBottom]         DECIMAL (10, 4) NULL,
    [MarginLeft]           DECIMAL (10, 4) NULL,
    [MarginRight]          DECIMAL (10, 4) NULL,
    [EdgeHeader]           DECIMAL (10, 4) NULL,
    [EdgeFooter]           DECIMAL (10, 4) NULL,
    [IsMirrorMargin]       BIT             NOT NULL,
    [ProjectId]            INT             NULL,
    [CustomerId]           INT             NULL,
    [SectionId] INT NULL, 
    [TypeId] INT NOT NULL DEFAULT 1, 
    CONSTRAINT [PK_PROJECTPAGESETTING] PRIMARY KEY CLUSTERED ([ProjectPageSettingId] ASC),
    CONSTRAINT [FK_ProjectPageSetting_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectPageSetting_ProjectSection] FOREIGN KEY([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId]),
    CONSTRAINT [FK_ProjectPageSetting_LuHeaderFooterType] FOREIGN KEY([TypeId]) REFERENCES [dbo].[LuHeaderFooterType] ([TypeId])
);




GO
CREATE NONCLUSTERED INDEX [IX_ProjectPageSetting_ProjectId]
    ON [dbo].[ProjectPageSetting]([ProjectId] ASC, [CustomerId] ASC) WITH (FILLFACTOR = 90);

