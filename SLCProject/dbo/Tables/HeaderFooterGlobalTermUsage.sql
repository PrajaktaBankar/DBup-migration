CREATE TABLE [dbo].[HeaderFooterGlobalTermUsage] (
    [HeaderFooterGTId]       INT           IDENTITY (1, 1) NOT NULL,
    [HeaderId]               INT           NULL,
    [FooterId]               INT           NULL,
    [UserGlobalTermId]       INT           NOT NULL,
    [CustomerId]             INT           NULL,
    [ProjectId]              INT           NULL,
    [HeaderFooterCategoryId] INT           NULL,
    [CreatedDate]            DATETIME2 (7) NULL,
    [CreatedById]            INT           NULL,
    CONSTRAINT [PK_HEADERFOOTERGLOBALTERMUSAGE] PRIMARY KEY CLUSTERED ([HeaderFooterGTId] ASC),
    CONSTRAINT [FK_HeaderFooterGlobalTermUsage_Footer] FOREIGN KEY ([FooterId]) REFERENCES [dbo].[Footer] ([FooterId]),
    CONSTRAINT [FK_HeaderFooterGlobalTermUsage_Header] FOREIGN KEY ([HeaderId]) REFERENCES [dbo].[Header] ([HeaderId]),
    CONSTRAINT [FK_HeaderFooterGlobalTermUsage_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_HeaderFooterGlobalTermUsage_UserGlobalTerm] FOREIGN KEY ([UserGlobalTermId]) REFERENCES [dbo].[UserGlobalTerm] ([UserGlobalTermId])
);




GO
CREATE NONCLUSTERED INDEX [IX_]
    ON [dbo].[HeaderFooterGlobalTermUsage]([ProjectId] ASC, [CustomerId] ASC)
    INCLUDE([HeaderId], [FooterId]) WITH (FILLFACTOR = 90);

