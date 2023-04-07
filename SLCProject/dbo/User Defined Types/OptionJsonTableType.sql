CREATE TYPE [dbo].[OptionJsonTableType] AS TABLE (
    [srNo]            INT            NULL,
    [ChoiceCode]      INT            NULL,
    [optionJson]      NVARCHAR (MAX) NULL,
    [FinalChoiceText] NVARCHAR (MAX) NULL);

