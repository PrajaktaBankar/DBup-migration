CREATE TABLE [dbo].[ProjectPaperSetting] (
    [ProjectPaperSettingId] INT             IDENTITY (1, 1) NOT NULL,
    [PaperName]             NVARCHAR (500)  NULL,
    [PaperWidth]            DECIMAL (10, 4) NULL,
    [PaperHeight]           DECIMAL (10, 4) NULL,
    [PaperOrientation]      CHAR (1)        NULL,
    [PaperSource]           CHAR (1)        NULL,
    [ProjectId]             INT             NULL,
    [CustomerId]            INT             NULL,
    [SectionId] INT NULL, 
    CONSTRAINT [PK_PROJECTPAPERSETTING] PRIMARY KEY CLUSTERED ([ProjectPaperSettingId] ASC),
    CONSTRAINT [FK_ProjectPaperSetting_ProjectSection] FOREIGN KEY([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId])
);




GO
CREATE NONCLUSTERED INDEX [IX_ProjectPageSetting_ProjectId]
    ON [dbo].[ProjectPaperSetting]([ProjectId] ASC, [CustomerId] ASC) WITH (FILLFACTOR = 90);

