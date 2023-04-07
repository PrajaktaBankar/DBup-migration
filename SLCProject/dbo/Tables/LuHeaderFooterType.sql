CREATE TABLE [dbo].[LuHeaderFooterType] (
    [TypeId]      INT            IDENTITY (1, 1) NOT NULL,
    [Name]        NVARCHAR (255) NULL,
    [Description] NVARCHAR (255) NULL,
    CONSTRAINT [PK_LUHEADERFOOTERTYPE] PRIMARY KEY CLUSTERED ([TypeId] ASC)
);

