CREATE TABLE [dbo].[ProjectExport] (
    [ProjectExportId]     INT            IDENTITY (1, 1) NOT NULL,
    [FileName]            NVARCHAR (500) NOT NULL,
    [ProjectId]           INT            NOT NULL,
    [FilePath]            NVARCHAR (256) NOT NULL,
    [FileFormatType]      NVARCHAR (10)  NOT NULL,
    [ProjectExportTypeId] INT            NOT NULL,
    [ExprityDate]         DATETIME       NOT NULL,
    [IsDeleted]           BIT            DEFAULT ((0)) NOT NULL,
    [CreatedDate]         DATETIME       DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]           INT            NOT NULL,
    [CreatedByFullName]   NVARCHAR (50)  NOT NULL,
    [ModifiedDate]        DATETIME       NULL,
    [ModifiedBy]          INT            NULL,
    [ModifiedByFullName]  NVARCHAR (50)  NULL,
    [FileExportTypeId]    INT            NOT NULL,
    [CustomerId]          INT            NOT NULL,
    [ProjectName]         NVARCHAR (150) NOT NULL,
    [FileStatus]          NVARCHAR (150) NOT NULL,
    [PrintFailureReason]  NVARCHAR (150)  NULL,
    PRIMARY KEY CLUSTERED ([ProjectExportId] ASC) WITH (FILLFACTOR = 80),
    FOREIGN KEY ([FileExportTypeId]) REFERENCES [dbo].[LuFileExportType] ([FileExportTypeId]),
    FOREIGN KEY ([ProjectExportTypeId]) REFERENCES [dbo].[LuProjectExportType] ([ProjectExportTypeId]),
    FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId])
);




GO
CREATE NONCLUSTERED INDEX [IX_ProjectExport_ProjectId_CustomerId]
    ON [dbo].[ProjectExport]([ProjectId] ASC, [CustomerId] ASC) WITH (FILLFACTOR = 90);

