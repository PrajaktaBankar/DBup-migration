CREATE TABLE [dbo].[ProjectPrintSettingPDF] (
    [ProjectPrintSettingId]     INT           NOT NULL,
    [ProjectId]                 INT           NULL,
    [CustomerId]                INT           NULL,
    [CreatedBy]                 INT           NULL,
    [CreateDate]                DATETIME2 (7) NULL,
    [ModifiedBy]                INT           NULL,
    [ModifiedDate]              DATETIME2 (7) NULL,
    [IsExportInMultipleFiles]   BIT           NOT NULL,
    [IsBeginSectionOnOddPage]   BIT           NOT NULL,
    [IsIncludeAuthorInFileName] BIT           NOT NULL,
    [TCPrintModeId]             INT           NOT NULL,
    [IsIncludePageCount]        BIT           NOT NULL,
    [IsIncludeHyperLink]        BIT           NOT NULL,
    [KeepWithNext]              BIT           NOT NULL,
    [IsPrintMasterNote]         BIT           NULL,
    [IsPrintProjectNote]        BIT           NULL,
    [IsPrintNoteImage]          BIT           NULL,
    [IsPrintIHSLogo]            BIT           NULL,
    CONSTRAINT [PK_ProjectPrintSetting_PDF] PRIMARY KEY CLUSTERED ([ProjectPrintSettingId] ASC)
);

