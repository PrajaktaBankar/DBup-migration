﻿CREATE TABLE [dbo].[StylePDF] (
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

