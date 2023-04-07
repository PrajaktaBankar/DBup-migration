CREATE TABLE [dbo].[StyleParagraphLineSpace] (
    [StyleId]           INT             NOT NULL,
    [DefaultSpacesId]   INT             NULL,
    [BeforeSpacesId]    INT             NULL,
    [AfterSpacesId]     INT             NULL,
    [CustomLineSpacing] DECIMAL (10, 2) NULL,
    FOREIGN KEY ([AfterSpacesId]) REFERENCES [dbo].[LuParagraphLineSpaceOption] ([ParagraphLineSpaceOptionId]),
    FOREIGN KEY ([BeforeSpacesId]) REFERENCES [dbo].[LuParagraphLineSpaceOption] ([ParagraphLineSpaceOptionId]),
    FOREIGN KEY ([DefaultSpacesId]) REFERENCES [dbo].[LuParagraphLineSpaceOption] ([ParagraphLineSpaceOptionId])
);

