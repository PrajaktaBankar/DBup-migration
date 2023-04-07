CREATE TABLE [dbo].[Footer] (
    [FooterId]                  INT            IDENTITY (1, 1) NOT NULL,
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
    [AltFooter]                 NVARCHAR (MAX) NULL,
    [FPFooter]                  NVARCHAR (MAX) NULL,
    [UseSeparateFPFooter]       BIT            NULL,
    [HeaderFooterCategoryId]    INT            NULL,
    [DateFormat]                NVARCHAR (500) DEFAULT ('Short') NULL,
    [TimeFormat]                NVARCHAR (500) DEFAULT ('Short') NULL,
    [A_FooterId]                INT            NULL,
    [HeaderFooterDisplayTypeId] INT            DEFAULT ((1)) NOT NULL,
    [DefaultFooter]             NVARCHAR (MAX) NULL,
    [FirstPageFooter]           NVARCHAR (MAX) NULL,
    [OddPageFooter]             NVARCHAR (MAX) NULL,
    [EvenPageFooter]            NVARCHAR (MAX) NULL,
    [DocumentTypeId]            INT            DEFAULT ((1)) NOT NULL,
    [IsShowLineAboveFooter]     BIT            DEFAULT ((0)) NOT NULL,
    [IsShowLineBelowFooter]     BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_FOOTER] PRIMARY KEY CLUSTERED ([FooterId] ASC),
    CONSTRAINT [FK_Footer_DocumentTypeId] FOREIGN KEY ([DocumentTypeId]) REFERENCES [dbo].[LuHeaderFooterDocumentType] ([DocumentTypeId]),
    CONSTRAINT [FK_Footer_LuHeaderFooterCategory] FOREIGN KEY ([HeaderFooterCategoryId]) REFERENCES [dbo].[LuHeaderFooterCategory] ([CategoryId]),
    CONSTRAINT [FK_Footer_LuHeaderFooterDisplayType] FOREIGN KEY ([HeaderFooterDisplayTypeId]) REFERENCES [dbo].[LuHeaderFooterDisplayType] ([HeaderFooterDisplayTypeId]),
    CONSTRAINT [FK_Footer_LuHeaderFooterType] FOREIGN KEY ([TypeId]) REFERENCES [dbo].[LuHeaderFooterType] ([TypeId]),
    CONSTRAINT [FK_Footer_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_Footer_ProjectSection] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId])
);




GO
CREATE NONCLUSTERED INDEX [IX_Footer_ProjectId_SectionId]
    ON [dbo].[Footer]([ProjectId] ASC, [SectionId] ASC) WITH (FILLFACTOR = 90);

