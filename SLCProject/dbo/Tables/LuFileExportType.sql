CREATE TABLE [dbo].[LuFileExportType] (
    [FileExportTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [Name]             NVARCHAR (50)  NOT NULL,
    [Description]      NVARCHAR (150) NULL,
    [IsActive]         BIT            DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([FileExportTypeId] ASC) WITH (FILLFACTOR = 80)
);

