CREATE TABLE [dbo].[LuGlobalTermFieldType] (
    [GlobalTermFieldTypeId] SMALLINT      IDENTITY (1, 1) NOT NULL,
    [Description]           NVARCHAR (50) NULL,
    [IsActive]              BIT           DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([GlobalTermFieldTypeId] ASC) WITH (FILLFACTOR = 80)
);

