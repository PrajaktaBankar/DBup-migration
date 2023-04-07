CREATE TABLE [dbo].[LuSpecificationViewMode] (
    [SpecViewModeId] INT           IDENTITY (1, 1) NOT NULL,
    [Name]           NVARCHAR (50) NOT NULL,
    [SpecViewCode]   NVARCHAR (50) NOT NULL,
    [Description]    NVARCHAR (50) NULL,
    [SortOrder]      INT           NOT NULL,
    [IsActive]       BIT           CONSTRAINT [DF_LuSpecificationViewMode_IsActive_1] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_LUSPECIFICATIONVIEWMODE] PRIMARY KEY CLUSTERED ([SpecViewModeId] ASC)
);

