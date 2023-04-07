CREATE TABLE [LuSpecSheetPaperSize] (
[SpecSheetPaperId]  INT             IDENTITY (1, 1) NOT NULL,
[Description]       NVARCHAR(200)   NOT NULL,
[Name]              NVARCHAR(200)   NOT NULL,
[Width]             NVARCHAR(200)   NOT NULL,
[Height]             NVARCHAR(200)   NOT NULL,
[IsActive]          BIT             NOT NULL DEFAULT(1), 
[SortOrder]         INT             NOT NULL,
    CONSTRAINT [PK_LuSpecSheetPaperSize] PRIMARY KEY ([SpecSheetPaperId])
)