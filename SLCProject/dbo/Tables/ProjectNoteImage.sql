CREATE TABLE [dbo].[ProjectNoteImage] (
    [NoteImageId] INT IDENTITY (1, 1) NOT NULL,
    [NoteId]      INT NOT NULL,
    [SectionId]   INT NOT NULL,
    [ImageId]     INT NOT NULL,
    [ProjectId]   INT NOT NULL,
    [CustomerId]  INT NOT NULL,
    CONSTRAINT [PK_PROJECTNOTEIMAGE] PRIMARY KEY CLUSTERED ([NoteImageId] ASC),
    CONSTRAINT [FK_ProjectNoteImage_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectNoteImage_ProjectImage] FOREIGN KEY ([ImageId]) REFERENCES [dbo].[ProjectImage] ([ImageId]),
    CONSTRAINT [FK_ProjectNoteImage_ProjectNote] FOREIGN KEY ([NoteId]) REFERENCES [dbo].[ProjectNote] ([NoteId]),
    CONSTRAINT [FK_ProjectNoteImage_ProjectSection] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId])
);


GO
CREATE NONCLUSTERED INDEX [NCIx_ProjectNoteImage]
    ON [dbo].[ProjectNoteImage]([NoteImageId] ASC)
    INCLUDE([NoteId], [SectionId], [ImageId], [ProjectId], [CustomerId]);

