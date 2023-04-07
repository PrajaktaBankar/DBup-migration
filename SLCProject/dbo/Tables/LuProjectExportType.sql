CREATE TABLE [dbo].[LuProjectExportType] (
    [ProjectExportTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [Name]                NVARCHAR (50)  NOT NULL,
    [Description]         NVARCHAR (150) NULL,
    [IsActive]            BIT            DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([ProjectExportTypeId] ASC) WITH (FILLFACTOR = 80)
);

