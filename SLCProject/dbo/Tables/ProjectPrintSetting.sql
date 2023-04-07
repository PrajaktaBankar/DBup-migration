CREATE TABLE [dbo].[ProjectPrintSetting] (
    [ProjectPrintSettingId]     INT           IDENTITY (1, 1) NOT NULL,
    [ProjectId]                 INT           NULL,
    [CustomerId]                INT           NULL,
    [CreatedBy]                 INT           NULL,
    [CreateDate]                DATETIME2 (7) NULL,
    [ModifiedBy]                INT           NULL,
    [ModifiedDate]              DATETIME2 (7) NULL,
    [IsExportInMultipleFiles]   BIT           DEFAULT ((1)) NOT NULL,
    [IsBeginSectionOnOddPage]   BIT           DEFAULT ((1)) NOT NULL,
    [IsIncludeAuthorInFileName] BIT           DEFAULT ((1)) NOT NULL,
    [TCPrintModeId]             INT           DEFAULT ((1)) NOT NULL,
    [IsIncludePageCount]        BIT           DEFAULT ((0)) NOT NULL,
    [IsIncludeHyperLink]        BIT           CONSTRAINT [DF__ProjectPrintSetting__IsArchived] DEFAULT ((0)) NOT NULL,
    [KeepWithNext]              BIT           DEFAULT ((1)) NOT NULL,
    [IsPrintMasterNote]         BIT           DEFAULT ((0)) NOT NULL,
    [IsPrintProjectNote]        BIT           DEFAULT ((0)) NOT NULL,
    [IsPrintNoteImage]          BIT           DEFAULT ((0)) NOT NULL,
    [IsPrintIHSLogo]            BIT           DEFAULT ((0)) NOT NULL,
    [IsIncludePdfBookmark]		BIT           DEFAULT ((0)) NOT NULL,
    [BookmarkLevel]             INT           DEFAULT ((0)) NOT NULL,
    [IsIncludeOrphanParagraph]  BIT           DEFAULT ((0)) NOT NULL,
    [IsMarkPagesAsBlank]        BIT  DEFAULT ((0)) NOT NULL, 
    [IsIncludeHeaderFooterOnBlackPages] BIT DEFAULT ((0))  NOT NULL, 
    [BlankPagesText] NVARCHAR(250)  NULL, 
    [IncludeSectionIdAfterEod] BIT NULL, 
    [IncludeEndOfSection] BIT NOT NULL DEFAULT (1),
    [IncludeDivisionNameandNumber] BIT NOT NULL DEFAULT (1),
    [IsIncludeAuthorForBookMark] BIT NOT NULL DEFAULT 0, 
    [IsContinuousPageNumber] BIT NOT NULL DEFAULT 0, 
    CONSTRAINT [PK_ProjectPrintSetting] PRIMARY KEY CLUSTERED ([ProjectPrintSettingId] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [FK_ProjectPrintSetting_LuTCPrintMode] FOREIGN KEY ([TCPrintModeId]) REFERENCES [dbo].[LuTCPrintMode] ([TCPrintModeId])
);


GO


GO


GO


GO


GO


GO


GO
CREATE NONCLUSTERED INDEX [IX_ProjectPrintSetting_ProjectId]
    ON [dbo].[ProjectPrintSetting]([ProjectId] ASC, [CustomerId] ASC) WITH (FILLFACTOR = 90);

