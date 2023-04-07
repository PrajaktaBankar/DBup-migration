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

