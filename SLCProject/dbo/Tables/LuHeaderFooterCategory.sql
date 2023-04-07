CREATE TABLE [dbo].[LuHeaderFooterCategory] (
    [CategoryId]   INT            IDENTITY (1, 1) NOT NULL,
    [CategoryName] NVARCHAR (255) NULL,
    [Description]  NVARCHAR (255) NULL,
    [IsActive]     BIT            NULL,
    CONSTRAINT [PK_LUHEADERFOOTERCATEGORY] PRIMARY KEY CLUSTERED ([CategoryId] ASC)
);

