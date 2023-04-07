CREATE TABLE [dbo].[HeaderFooterReferenceStandardUsage] (
    [HeaderFooterRSId]       INT           IDENTITY (1, 1) NOT NULL,
    [HeaderId]               INT           NOT NULL,
    [FooterId]               INT           NOT NULL,
    [ReferenceStandardId]    INT           NOT NULL,
    [CustomerId]             INT           NULL,
    [ProjectId]              INT           NULL,
    [HeaderFooterCategoryId] INT           NULL,
    [CreatedDate]            DATETIME2 (7) NULL,
    [CreatedById]            INT           NULL,
    CONSTRAINT [PK_HEADERFOOTERREFERENCESTANDARDUSAGE] PRIMARY KEY CLUSTERED ([HeaderFooterRSId] ASC),
    CONSTRAINT [FK_HeaderFooterReferenceStandardUsage_Footer] FOREIGN KEY ([FooterId]) REFERENCES [dbo].[Footer] ([FooterId]),
    CONSTRAINT [FK_HeaderFooterReferenceStandardUsage_Header] FOREIGN KEY ([HeaderId]) REFERENCES [dbo].[Header] ([HeaderId]),
    CONSTRAINT [FK_HeaderFooterReferenceStandardUsage_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_HeaderFooterReferenceStandardUsage_ReferenceStandard] FOREIGN KEY ([ReferenceStandardId]) REFERENCES [dbo].[ReferenceStandard] ([RefStdId])
);




GO
CREATE NONCLUSTERED INDEX [IX_HeaderFooterReferenceStandardUsage_ProjectId_ProjRefStdId]
    ON [dbo].[HeaderFooterReferenceStandardUsage]([ProjectId] ASC, [ReferenceStandardId] ASC) WITH (FILLFACTOR = 90);

