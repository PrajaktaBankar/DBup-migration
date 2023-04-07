CREATE TABLE [dbo].[Header] (
    [HeaderId]                  INT            IDENTITY (1, 1) NOT NULL,
    [ProjectId]                 INT            NULL,
    [SectionId]                 INT            NULL,
    [CustomerId]                INT            NULL,
    [Description]               NVARCHAR (MAX) NULL,
    [IsLocked]                  BIT            DEFAULT ((0)) NULL,
    [LockedByFullName]          NVARCHAR (500) NULL,
    [LockedBy]                  INT            NULL,
    [ShowFirstPage]             BIT            DEFAULT ((1)) NULL,
    [CreatedBy]                 INT            NULL,
    [CreatedDate]               DATETIME2 (7)  NOT NULL,
    [ModifiedBy]                INT            NULL,
    [ModifiedDate]              DATETIME2 (7)  NULL,
    [TypeId]                    INT            NULL,
    [AltHeader]                 NVARCHAR (MAX) NULL,
    [FPHeader]                  NVARCHAR (MAX) NULL,
    [UseSeparateFPHeader]       BIT            NULL,
    [HeaderFooterCategoryId]    INT            NULL,
    [DateFormat]                NVARCHAR (500) DEFAULT ('Short') NULL,
    [TimeFormat]                NVARCHAR (500) DEFAULT ('Short') NULL,
    [A_HeaderId]                INT            NULL,
    [HeaderFooterDisplayTypeId] INT            DEFAULT ((1)) NOT NULL,
    [DefaultHeader]             NVARCHAR (MAX) NULL,
    [FirstPageHeader]           NVARCHAR (MAX) NULL,
    [OddPageHeader]             NVARCHAR (MAX) NULL,
    [EvenPageHeader]            NVARCHAR (MAX) NULL,
    [DocumentTypeId]            INT            DEFAULT ((1)) NOT NULL,
    [IsShowLineAboveHeader]     BIT            DEFAULT ((0)) NOT NULL,
    [IsShowLineBelowHeader]     BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_HEADER] PRIMARY KEY CLUSTERED ([HeaderId] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Header_DocumentTypeId] FOREIGN KEY ([DocumentTypeId]) REFERENCES [dbo].[LuHeaderFooterDocumentType] ([DocumentTypeId]),
    CONSTRAINT [FK_Header_LuHeaderFooterCategory] FOREIGN KEY ([HeaderFooterCategoryId]) REFERENCES [dbo].[LuHeaderFooterCategory] ([CategoryId]),
    CONSTRAINT [FK_Header_LuHeaderFooterDisplayType] FOREIGN KEY ([HeaderFooterDisplayTypeId]) REFERENCES [dbo].[LuHeaderFooterDisplayType] ([HeaderFooterDisplayTypeId]),
    CONSTRAINT [FK_Header_LuHeaderFooterType] FOREIGN KEY ([TypeId]) REFERENCES [dbo].[LuHeaderFooterType] ([TypeId]),
    CONSTRAINT [FK_Header_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_Header_ProjectSection] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId])
);




GO
CREATE NONCLUSTERED INDEX [IX_Header_ProjectId_SectionId]
    ON [dbo].[Header]([ProjectId] ASC, [SectionId] ASC) WITH (FILLFACTOR = 90);

