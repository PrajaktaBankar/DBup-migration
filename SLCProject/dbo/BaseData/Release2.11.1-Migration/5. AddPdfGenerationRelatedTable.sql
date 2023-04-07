USE SLCProject 
GO

if not exists (select * from sysobjects where name='ProjectPrintSettingPDF' and xtype='U')
BEGIN
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
 Print 'ProjectPrintSettingPDF Table created'
END
ELSE
Print 'ProjectPrintSettingPDF Already Exists'
GO

if not exists (select * from sysobjects where name='ProjectUserTagPDF' and xtype='U')
BEGIN
CREATE TABLE [dbo].[ProjectUserTagPDF] (
    [UserTagId]    INT            NOT NULL,
    [CustomerId]   INT            NOT NULL,
    [TagType]      NVARCHAR (10)  NOT NULL,
    [Description]  NVARCHAR (255) NULL,
    [SortOrder]    INT            NULL,
    [IsSystemTag]  BIT            NULL,
    [CreateDate]   DATETIME2 (7)  NULL,
    [CreatedBy]    INT            NULL,
    [ModifiedDate] DATETIME2 (7)  NULL,
    [ModifiedBy]   INT            NULL,
    [A_UserTagId]  INT            NULL,
    CONSTRAINT [PK_PROJECTUSERTAG_PDF] PRIMARY KEY CLUSTERED ([UserTagId] ASC) WITH (FILLFACTOR = 90)
);
Print 'ProjectUserTagPDF  Table created'
END
ELSE
Print 'ProjectUserTagPDF Already Exists'
GO

if not exists (select * from sysobjects where name='ReferenceStandardEditionPDF' and xtype='U')
BEGIN
CREATE TABLE [dbo].[ReferenceStandardEditionPDF] (
    [RefStdEditionId]   INT            NOT NULL,
    [RefEdition]        NVARCHAR (MAX) NULL,
    [RefStdTitle]       NVARCHAR (MAX) NULL,
    [LinkTarget]        NVARCHAR (MAX) NULL,
    [CreateDate]        DATETIME2 (7)  NOT NULL,
    [CreatedBy]         INT            NOT NULL,
    [RefStdId]          INT            NULL,
    [CustomerId]        INT            NULL,
    [ModifiedDate]      DATETIME2 (7)  NULL,
    [ModifiedBy]        INT            NULL,
    [A_RefStdEditionId] INT            NULL,
    CONSTRAINT [PK_REFERENCESTANDARDEDITION_PDF] PRIMARY KEY CLUSTERED ([RefStdEditionId] ASC) WITH (FILLFACTOR = 90)
);
Print 'ReferenceStandardEditionPDF  Table created'
END
ELSE
Print 'ReferenceStandardEditionPDF Already Exists'
GO

if not exists (select * from sysobjects where name='ReferenceStandardPDF' and xtype='U')
BEGIN
CREATE TABLE [dbo].[ReferenceStandardPDF] (
    [RefStdId]            INT            NOT NULL,
    [RefStdName]          NVARCHAR (MAX) NULL,
    [RefStdSource]        NVARCHAR (255) NULL,
    [ReplaceRefStdId]     INT            NULL,
    [ReplaceRefStdSource] NVARCHAR (255) NULL,
    [mReplaceRefStdId]    INT            NULL,
    [IsObsolete]          BIT            NOT NULL,
    [RefStdCode]          INT            NULL,
    [CreateDate]          DATETIME2 (7)  NOT NULL,
    [CreatedBy]           INT            NOT NULL,
    [ModifiedDate]        DATETIME2 (7)  NULL,
    [ModifiedBy]          INT            NULL,
    [CustomerId]          INT            NULL,
    [IsDeleted]           BIT            NOT NULL,
    [IsLocked]            BIT            NULL,
    [IsLockedByFullName]  NVARCHAR (255) NULL,
    [IsLockedById]        INT            NULL,
    [A_RefStdId]          INT            NULL,
    CONSTRAINT [PK_REFERENCESTANDARD_PDF] PRIMARY KEY CLUSTERED ([RefStdId] ASC) WITH (FILLFACTOR = 90)
);
  Print  'ReferenceStandardPDF  Table created'
END
ELSE
Print 'ReferenceStandardPDF Already Exists'
GO

if not exists (select * from sysobjects where name='StylePDF' and xtype='U')
BEGIN
CREATE TABLE [dbo].[StylePDF] (
    [StyleId]             INT            NOT NULL,
    [Alignment]           TINYINT        NOT NULL,
    [IsBold]              BIT            NOT NULL,
    [CharAfterNumber]     INT            NOT NULL,
    [CharBeforeNumber]    INT            NOT NULL,
    [FontName]            NVARCHAR (255) NULL,
    [FontSize]            INT            NOT NULL,
    [HangingIndent]       INT            NOT NULL,
    [IncludePrevious]     BIT            NOT NULL,
    [IsItalic]            BIT            NOT NULL,
    [LeftIndent]          INT            NOT NULL,
    [NumberFormat]        INT            NOT NULL,
    [NumberPosition]      INT            NOT NULL,
    [PrintUpperCase]      BIT            NOT NULL,
    [ShowNumber]          BIT            NOT NULL,
    [StartAt]             TINYINT        NOT NULL,
    [Strikeout]           BIT            NOT NULL,
    [Name]                NVARCHAR (255) NULL,
    [TopDistance]         INT            NOT NULL,
    [Underline]           BIT            NOT NULL,
    [SpaceBelowParagraph] INT            NOT NULL,
    [IsSystem]            BIT            NOT NULL,
    [CustomerId]          INT            NULL,
    [IsDeleted]           BIT            NOT NULL,
    [CreatedBy]           INT            NOT NULL,
    [CreateDate]          DATETIME2 (7)  NOT NULL,
    [ModifiedBy]          INT            NULL,
    [ModifiedDate]        DATETIME2 (7)  NULL,
    [Level]               INT            NULL,
    [MasterDataTypeId]    INT            NULL,
    [A_StyleId]           INT            NULL,
    CONSTRAINT [PK_STYLE_PDF] PRIMARY KEY CLUSTERED ([StyleId] ASC)
);
   Print  'StylePDF  Table created'
END
ELSE
Print 'StylePDF Already Exists'
GO


if not exists (select * from sysobjects where name='TemplatePDF' and xtype='U')
BEGIN
CREATE TABLE [dbo].[TemplatePDF] (
    [TemplateId]           INT            NOT NULL,
    [Name]                 NVARCHAR (MAX) NOT NULL,
    [TitleFormatId]        INT            NULL,
    [SequenceNumbering]    BIT            NOT NULL,
    [CustomerId]           INT            NULL,
    [IsSystem]             BIT            NOT NULL,
    [IsDeleted]            BIT            NOT NULL,
    [CreatedBy]            INT            NOT NULL,
    [CreateDate]           DATETIME2 (7)  NOT NULL,
    [ModifiedBy]           INT            NULL,
    [ModifiedDate]         DATETIME2 (7)  NULL,
    [MasterDataTypeId]     INT            NULL,
    [A_TemplateId]         INT            NULL,
    [ApplyTitleStyleToEOS] BIT            NULL,
    CONSTRAINT [PK_TEMPLATE_PDF] PRIMARY KEY CLUSTERED ([TemplateId] ASC) WITH (FILLFACTOR = 90)
);
  Print  'TemplatePDF  Table created'
END
ELSE
Print 'TemplatePDF Already Exists'
GO

if not exists (select * from sysobjects where name='TemplateStylePDF' and xtype='U')
BEGIN
CREATE TABLE [dbo].[TemplateStylePDF] (
    [TemplateStyleId]   INT     NOT NULL,
    [TemplateId]        INT     NOT NULL,
    [StyleId]           INT     NOT NULL,
    [Level]             TINYINT NOT NULL,
    [CustomerId]        INT     NULL,
    [A_TemplateStyleId] INT     NULL,
    CONSTRAINT [PK_TEMPLATESTYLE_PDF] PRIMARY KEY CLUSTERED ([TemplateStyleId] ASC)
);

  Print  'TemplateStylePDF  Table created'
END
ELSE
Print 'TemplateStylePDF Already Exists'
GO

if not exists (select * from sysobjects where name='UserGlobalTermPDF' and xtype='U')
BEGIN
CREATE TABLE [dbo].[UserGlobalTermPDF] (
    [UserGlobalTermId]   INT            IDENTITY (1, 1) NOT NULL,
    [Name]               NVARCHAR (255) NULL,
    [Value]              NVARCHAR (500) NULL,
    [CreatedDate]        DATETIME2 (7)  NOT NULL,
    [CreatedBy]          INT            NOT NULL,
    [CustomerId]         INT            NULL,
    [ProjectId]          INT            NULL,
    [IsDeleted]          BIT            NULL,
    [A_UserGlobalTermId] INT            NULL,
    CONSTRAINT [PK_USERGLOBALTERM_PDF] PRIMARY KEY CLUSTERED ([UserGlobalTermId] ASC) WITH (FILLFACTOR = 90)
);
  Print 'UserGlobalTermPDF  Table created'
END
ELSE
Print 'UserGlobalTermPDF Already Exists'
GO