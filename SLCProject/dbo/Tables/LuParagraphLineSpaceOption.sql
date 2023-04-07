CREATE TABLE [dbo].[LuParagraphLineSpaceOption] (
    [ParagraphLineSpaceOptionId] INT           IDENTITY (1, 1) NOT NULL,
    [Name]                       NVARCHAR (50) NOT NULL,
    [Description]                NVARCHAR (50) NOT NULL,
    [IsActive]                   BIT           DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_LUPARAGRAPHLINESPACEOPTION] PRIMARY KEY CLUSTERED ([ParagraphLineSpaceOptionId] ASC)
);

