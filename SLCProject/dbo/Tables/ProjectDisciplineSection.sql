CREATE TABLE [dbo].[ProjectDisciplineSection] (
    [Id]           INT IDENTITY (1, 1) NOT NULL,
    [SectionId]    INT NOT NULL,
    [Disciplineld] INT NULL,
    [ProjectId]    INT NOT NULL,
    [CustomerId]   INT NOT NULL,
    [IsActive]     BIT NOT NULL,
    CONSTRAINT [PK_PROJECTDISCIPLINESECTION] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ProjectDisciplineSection_LuProjectDiscipline] FOREIGN KEY ([Disciplineld]) REFERENCES [dbo].[LuProjectDiscipline] ([Disciplineld]),
    CONSTRAINT [FK_ProjectDisciplineSection_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectDisciplineSection_ProjectSection] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId])
);




GO
CREATE NONCLUSTERED INDEX [IX_ProjectDisciplineSection_ProjectId_SectionId]
    ON [dbo].[ProjectDisciplineSection]([ProjectId] ASC, [SectionId] ASC) WITH (FILLFACTOR = 90);

