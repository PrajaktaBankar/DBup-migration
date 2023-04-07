CREATE TABLE [dbo].[TemplateStyle] (
    [TemplateStyleId]   INT     IDENTITY (1, 1) NOT NULL,
    [TemplateId]        INT     NOT NULL,
    [StyleId]           INT     NOT NULL,
    [Level]             TINYINT NOT NULL,
    [CustomerId]        INT     NULL,
    [A_TemplateStyleId] INT     NULL,
    CONSTRAINT [PK_TEMPLATESTYLE] PRIMARY KEY CLUSTERED ([TemplateStyleId] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_TemplatesStyles_Templates] FOREIGN KEY ([TemplateId]) REFERENCES [dbo].[Template] ([TemplateId]),
    CONSTRAINT [FK_TemplateStyle_Style] FOREIGN KEY ([StyleId]) REFERENCES [dbo].[Style] ([StyleId])
);




GO
CREATE NONCLUSTERED INDEX [IX_TemplateStyle_LevelId]
    ON [dbo].[TemplateStyle]([Level] ASC) WITH (FILLFACTOR = 90);

