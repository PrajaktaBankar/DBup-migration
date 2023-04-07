CREATE TABLE [dbo].[LuProjectSize] (
    [SizeId]          INT           IDENTITY (1, 1) NOT NULL,
    [SizeDescription] VARCHAR(100) NULL,
    [ProjectUoMId]    INT           DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_LUPROJECTSIZE] PRIMARY KEY CLUSTERED ([SizeId] ASC),
    CONSTRAINT [fk_ProjectUoMId] FOREIGN KEY ([ProjectUoMId]) REFERENCES [dbo].[LuProjectUoM] ([ProjectUoMId])
);



