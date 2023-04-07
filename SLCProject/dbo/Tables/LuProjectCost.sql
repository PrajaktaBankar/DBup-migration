CREATE TABLE [dbo].[LuProjectCost] (
    [CostId]          INT           IDENTITY (1, 1) NOT NULL,
    [CostDescription] NVARCHAR (50) NULL,
    [CountryCode]     NVARCHAR (5)  DEFAULT (NULL) NULL,
    CONSTRAINT [PK_LUPROJECTCOST] PRIMARY KEY CLUSTERED ([CostId] ASC)
);



