ALTER TABLE [dbo].[CustomerGlobalSetting] ADD [IsIncludeManufacturerParagraph] BIT NULL
GO

ALTER TABLE [Footer] ADD [DocumentTypeId] INT DEFAULT ((1)) NOT NULL
GO


ALTER TABLE [dbo].[Footer] WITH NOCHECK
    ADD CONSTRAINT [FK_Footer_DocumentTypeId] FOREIGN KEY ([DocumentTypeId]) REFERENCES [dbo].[LuHeaderFooterDocumentType] ([DocumentTypeId]);
GO

ALTER TABLE [Header] ADD [DocumentTypeId] INT DEFAULT ((1)) NOT NULL
GO

ALTER TABLE [dbo].[Header] WITH NOCHECK
    ADD CONSTRAINT [FK_Header_DocumentTypeId] FOREIGN KEY ([DocumentTypeId]) REFERENCES [dbo].[LuHeaderFooterDocumentType] ([DocumentTypeId]);
GO

ALTER TABLE [LuCountry] ADD [CurrencyName] NVARCHAR (255) NULL
GO

ALTER TABLE [LuCountry] ADD [CurrencyDigitalCode]  NVARCHAR (5)   NULL
GO

ALTER TABLE [ProjectSummary] ADD [ProjectAccessTypeId] INT DEFAULT ((1)) NULL
GO

ALTER TABLE [ProjectSummary] ADD [OwnerId] INT NULL
GO

ALTER TABLE [ProjectGlobalTerm] ADD [OldValue] NVARCHAR (500) NULL
GO

ALTER TABLE [ProjectSegmentStatus] ADD [TrackOriginOrder]  NVARCHAR (2) NULL
GO

ALTER TABLE [ProjectSegmentStatus] ADD [MTrackDescription]  NVARCHAR (MAX)  NULL
GO

ALTER TABLE [dbo].[LuProjectSize] WITH NOCHECK
    ADD CONSTRAINT [fk_ProjectUoMId] FOREIGN KEY ([ProjectUoMId]) REFERENCES [dbo].[LuProjectUoM] ([ProjectUoMId]);
GO