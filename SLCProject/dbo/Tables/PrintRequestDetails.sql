CREATE TABLE [dbo].[PrintRequestDetails] (
    [PrintRequestId]       INT            IDENTITY (1, 1) NOT NULL,
    [FileName]             NVARCHAR (500) NULL,
    [CustomerId]           INT            NULL,
    [ProjectId]            INT            NULL,
    [ProjectName]          NVARCHAR (100) NULL,
    [SectionName]          NVARCHAR (100) NULL,
    [PrintTypeId]          INT            NULL,
    [IsExportAsSingleFile] BIT            NULL,
    [IsBeginFromOddPage]   BIT            NULL,
    [IsIncludeAuthorName]  BIT            NULL,
    [TrackChangesOption]   INT            NULL,
    [PrintStatus]          NVARCHAR (20)  NULL,
    [CreatedDate]          DATETIME       NULL,
    [CreatedBy]            INT            NULL,
    [ModifiedDate]         DATETIME       NULL,
    [ModifiedBy]           INT            NULL,
    [IsExternalExport]     BIT            DEFAULT ((0)) NOT NULL,
    [IsDeleted]            BIT            DEFAULT ((0)) NOT NULL,
    [PrintFailureReason]   NVARCHAR (150)  NULL,
    CONSTRAINT [PK_PrintRequestDetails] PRIMARY KEY CLUSTERED ([PrintRequestId] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [FK_PrintRequestDetails_LuProjectExportType] FOREIGN KEY ([PrintTypeId]) REFERENCES [dbo].[LuProjectExportType] ([ProjectExportTypeId]),
    CONSTRAINT [FK_PrintRequestDetails_LuTCPrintMode] FOREIGN KEY ([TrackChangesOption]) REFERENCES [dbo].[LuTCPrintMode] ([TCPrintModeId])
);


GO


GO


GO


GO
