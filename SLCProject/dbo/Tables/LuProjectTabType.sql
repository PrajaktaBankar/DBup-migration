CREATE TABLE [dbo].[LuProjectTabType] (
    [TabTypeId]   INT           IDENTITY (1, 1) NOT NULL,
    [TabType]     INT           NOT NULL,
    [Description] VARCHAR(100) NOT NULL,
    CONSTRAINT [PK_LUPROJECTTABTYPE] PRIMARY KEY CLUSTERED ([TabTypeId] ASC)
);

