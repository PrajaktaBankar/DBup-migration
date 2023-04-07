CREATE TABLE [dbo].[ProjectNote] (
    [NoteId]           INT             IDENTITY (10000000, 1) NOT NULL,
    [SectionId]        INT             NOT NULL,
    [SegmentStatusId]  BIGINT             NULL,
    [NoteText]         NVARCHAR (MAX)  NULL,
    [CreateDate]       DATETIME2 (7)   NOT NULL,
    [ModifiedDate]     DATETIME2 (7)   NULL,
    [ProjectId]        INT             NOT NULL,
    [CustomerId]       INT             NOT NULL,
    [Title]            NVARCHAR (2500) NULL,
    [CreatedBy]        INT             NOT NULL,
    [ModifiedBy]       INT             NULL,
    [CreatedUserName]  NVARCHAR (500)  NULL,
    [ModifiedUserName] NVARCHAR (500)  NULL,
    [IsDeleted]        BIT             DEFAULT ((0)) NULL,
    [NoteCode]         INT             CONSTRAINT [Default_ProjectNote_NoteCode] DEFAULT (NEXT VALUE FOR [seq_ProjectNote]) NULL,
    [A_NoteId]         INT             NULL,
    CONSTRAINT [PK_PROJECTNOTE] PRIMARY KEY CLUSTERED ([NoteId] ASC),
    CONSTRAINT [FK_ProjectNote_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectNote_ProjectSection] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId]),
    CONSTRAINT [FK_ProjectNote_ProjectSegmentStatus] FOREIGN KEY ([SegmentStatusId]) REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId])
);


GO
CREATE NONCLUSTERED INDEX [NCIx_ProjectNote_ProjectId]
    ON [dbo].[ProjectNote]([SectionId] ASC, [ProjectId] ASC)
    INCLUDE([SegmentStatusId]) WITH (FILLFACTOR = 90);
GO

