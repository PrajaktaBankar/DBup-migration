CREATE TABLE [dbo].[CustomerGlobalSetting] (
    [CustomerGlobalSettingId]        INT IDENTITY (1, 1) NOT NULL,
    [CustomerId]                     INT NULL,
    [UserId]                         INT NULL,
    [IsAutoSelectParagraph]          BIT DEFAULT ((0)) NOT NULL,
    [IsAutoSelectForImport]          BIT NULL,
    [IsIncludeSubparagraph]          BIT NULL,
    [IsMultipleFilesForExport]       BIT DEFAULT ((0)) NOT NULL,
    [IsAlwaysAllowAddPara]           BIT DEFAULT ((0)) NOT NULL,
    [IsTCNotifyAccepted]             BIT DEFAULT ((0)) NOT NULL,
    [IncludeAuthorInFileNames]       BIT DEFAULT ((0)) NOT NULL,
    [IsIncludeManufacturerParagraph] BIT NULL,
    CONSTRAINT [PK_CustomerGlobalSetting] PRIMARY KEY CLUSTERED ([CustomerGlobalSettingId] ASC)
);






GO
CREATE NONCLUSTERED INDEX [IX_CustomerGlobalSetting_CustomerId_UserId]
    ON [dbo].[CustomerGlobalSetting]([CustomerId] ASC, [UserId] ASC) WITH (FILLFACTOR = 90);

