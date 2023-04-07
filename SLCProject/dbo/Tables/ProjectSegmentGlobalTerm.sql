CREATE TABLE [dbo].[ProjectSegmentGlobalTerm] (
    [SegmentGlobalTermId] INT           IDENTITY (1, 1) NOT NULL,
    [CustomerId]          INT           NOT NULL,
    [ProjectId]           INT           NOT NULL,
    [SectionId]           INT           NOT NULL,
    [SegmentId]           BIGINT           NULL,
    [mSegmentId]          INT           NULL,
    [UserGlobalTermId]    INT           NULL,
    [GlobalTermCode]      INT           NULL,
    [IsLocked]            BIT           NULL,
    [LockedByFullName]    NVARCHAR (1)  NULL,
    [UserLockedId]        INT           NULL,
    [CreatedDate]         DATETIME2 (7) NOT NULL,
    [CreatedBy]           INT           NOT NULL,
    [ModifiedDate]        DATETIME2 (7) NULL,
    [ModifiedBy]          INT           NULL,
    [IsDeleted]           BIT           DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PROJECTSEGMENTGLOBALTERM] PRIMARY KEY CLUSTERED ([SegmentGlobalTermId] ASC),
    CONSTRAINT [FK_ProjectSegmentGlobalTerm_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectSegmentGlobalTerm_ProjectSection] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId])
);




GO
CREATE NONCLUSTERED INDEX [IX_ProjectSegmentGlobalTerm_SegmentId_GlobalTermCode]
    ON [dbo].[ProjectSegmentGlobalTerm]([SectionId] ASC, [ProjectId] ASC, [SegmentId] ASC, [GlobalTermCode] ASC) WITH (FILLFACTOR = 90);

