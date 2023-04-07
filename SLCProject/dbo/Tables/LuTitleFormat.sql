CREATE TABLE [dbo].[LuTitleFormat] (
    [TitleFormatId] INT            IDENTITY (1, 1) NOT NULL,
    [Name]          NVARCHAR (255) NULL,
    [IsActive]      BIT            NOT NULL,
    CONSTRAINT [PK_LUTITLEFORMAT] PRIMARY KEY CLUSTERED ([TitleFormatId] ASC)
);

