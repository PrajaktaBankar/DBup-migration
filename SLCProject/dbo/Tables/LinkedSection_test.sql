CREATE TABLE [dbo].[LinkedSection_test] (
    [ProjectId]  INT      NOT NULL,
    [SectionId]  INT      NOT NULL,
    [VimId]      INT      NOT NULL,
    [MaterialId] INT      NOT NULL,
    [Linkedby]   INT      NULL,
    [LinkedDate] DATETIME NULL
);

