CREATE TABLE [dbo].[LuProjectUoM] (
    [ProjectUoMId] INT           IDENTITY (1, 1) NOT NULL,
    [Description]  VARCHAR(50) NULL,
    CONSTRAINT [PK_LUPROJECTUOM] PRIMARY KEY CLUSTERED ([ProjectUoMId] ASC)
);

