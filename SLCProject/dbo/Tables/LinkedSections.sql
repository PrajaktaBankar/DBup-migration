CREATE TABLE [dbo].[LinkedSections] (
    [ProjectId]  INT           NOT NULL,
    [SectionId]  INT           NOT NULL,
    [VimId]      INT           NOT NULL,
    [MaterialId] INT           NOT NULL,
    [Linkedby]   INT           NULL,
    [LinkedDate] DATETIME2 (7) NULL,
    [customerId] INT           NULL,
    CONSTRAINT [PK_LINKEDSECTIONS] PRIMARY KEY CLUSTERED ([ProjectId] ASC, [SectionId] ASC, [VimId] ASC, [MaterialId] ASC)
);

