CREATE TABLE [dbo].[LuHeaderFooterDisplayType] (
    [HeaderFooterDisplayTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [HeaderFooterDisplayType]   NVARCHAR (50)  NOT NULL,
    [Description]               NVARCHAR (250) NOT NULL,
    [IsActive]                  BIT            DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_LuHeaderFooterDisplayType] PRIMARY KEY CLUSTERED ([HeaderFooterDisplayTypeId] ASC)
);

