CREATE TABLE [dbo].[TemplateStylePDF] (
    [TemplateStyleId]   INT     NOT NULL,
    [TemplateId]        INT     NOT NULL,
    [StyleId]           INT     NOT NULL,
    [Level]             TINYINT NOT NULL,
    [CustomerId]        INT     NULL,
    [A_TemplateStyleId] INT     NULL,
    CONSTRAINT [PK_TEMPLATESTYLE_PDF] PRIMARY KEY CLUSTERED ([TemplateStyleId] ASC)
);

