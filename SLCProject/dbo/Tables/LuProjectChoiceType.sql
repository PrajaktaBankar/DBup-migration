CREATE TABLE [dbo].[LuProjectChoiceType] (
    [ChoiceTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [ChoiceType]   NVARCHAR (255) NULL,
    CONSTRAINT [PK_LUPROJECTCHOICETYPE] PRIMARY KEY CLUSTERED ([ChoiceTypeId] ASC)
);

