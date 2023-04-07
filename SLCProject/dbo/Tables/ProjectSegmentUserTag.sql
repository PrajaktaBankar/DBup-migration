CREATE TABLE [dbo].[ProjectSegmentUserTag] (
    [SegmentUserTagId] INT           IDENTITY (1, 1) NOT NULL,
    [CustomerId]       INT           NOT NULL,
    [ProjectId]        INT           NOT NULL,
    [SectionId]        INT           NOT NULL,
    [SegmentStatusId]  BIGINT           NULL,
    [UserTagId]        INT           NOT NULL,
    [CreateDate]       DATETIME2 (7) NOT NULL,
    [CreatedBy]        INT           NOT NULL,
    [ModifiedDate]     DATETIME2 (7) NULL,
    [ModifiedBy]       INT           NULL,
    [IsDeleted]        BIT           DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PROJECTSEGMENTUSERTAG] PRIMARY KEY CLUSTERED ([SegmentUserTagId] ASC),
    CONSTRAINT [FK_ProjectSegmentUserTag_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectSegmentUserTag_ProjectSection] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId]),
    CONSTRAINT [FK_ProjectSegmentUserTag_ProjectSegmentStatus] FOREIGN KEY ([SegmentStatusId]) REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId]),
    CONSTRAINT [FK_ProjectSegmentUserTag_ProjectUserTag] FOREIGN KEY ([UserTagId]) REFERENCES [dbo].[ProjectUserTag] ([UserTagId])
);




GO
CREATE NONCLUSTERED INDEX [NCI_ProjectId_SegmentId_SectionId_SegmentStatusId]
    ON [dbo].[ProjectSegmentUserTag]([ProjectId] DESC, [SectionId] DESC, [SegmentStatusId] DESC)
    INCLUDE([UserTagId]) WITH (FILLFACTOR = 90);

