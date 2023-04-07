CREATE TABLE [dbo].[LuProjectChoiceOptionType] (
    [ChoiceOptionTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [ChoiceOptionType]   NVARCHAR (255) NULL,
    CONSTRAINT [PK_LUPROJECTCHOICEOPTIONTYPE] PRIMARY KEY CLUSTERED ([ChoiceOptionTypeId] ASC)
);

