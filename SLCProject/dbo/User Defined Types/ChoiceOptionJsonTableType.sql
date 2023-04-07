CREATE TYPE [dbo].[ChoiceOptionJsonTableType] AS TABLE (
    [RowNumber]    INT            NOT NULL,
    [OptionTypeId] VARCHAR (200)  NULL,
    [SortOrder]    INT            NULL,
    [Value]        VARCHAR (1024) NULL,
    [Id]           INT            NULL);

