CREATE TABLE [dbo].[LuMasterDataType] (
    [MasterDataTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [Name]             NVARCHAR (255) NULL,
    [Description]      NVARCHAR (255) NULL,
    [LanguageCode]     NVARCHAR (10)  NULL,
    [LanguageName]     NVARCHAR (100) NULL,
    CONSTRAINT [PK_LUMASTERDATATYPE] PRIMARY KEY CLUSTERED ([MasterDataTypeId] ASC)
);

