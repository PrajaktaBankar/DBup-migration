CREATE TABLE [dbo].[ProjectSegmentChoice] (
    [SegmentChoiceId]     BIGINT            IDENTITY (1, 1) NOT NULL,
    [SectionId]           INT            NOT NULL,
    [SegmentStatusId]     BIGINT            NULL,
    [SegmentId]           BIGINT            NULL,
    [ChoiceTypeId]        INT            NULL,
    [ProjectId]           INT            NOT NULL,
    [CustomerId]          INT            NOT NULL,
    [SegmentChoiceSource] CHAR NULL,
    [SegmentChoiceCode]   BIGINT            CONSTRAINT [Default_ProjectSegmentChoice_SegmentChoiceCode] DEFAULT (NEXT VALUE FOR [seq_ProjectSegmentChoice]) NULL,
    [CreatedBy]           INT            NOT NULL,
    [CreateDate]          DATETIME2 (7)  NOT NULL,
    [ModifiedBy]          INT            NULL,
    [ModifiedDate]        DATETIME2 (7)  NULL,
    [SLE_DocID]           INT            NULL,
    [SLE_SegmentID]       INT            NULL,
    [SLE_StatusID]        INT            NULL,
    [SLE_ChoiceNo]        INT            NULL,
    [SLE_ChoiceTypeID]    TINYINT        NULL,
    [A_SegmentChoiceId]   BIGINT            NULL,
    [IsDeleted]           BIT            DEFAULT ((0)) NULL,
    CONSTRAINT [PK_PROJECTSEGMENTCHOICE] PRIMARY KEY CLUSTERED ([SegmentChoiceId] ASC),
    CONSTRAINT [FK_ProjectSegmentChoice_LuProjectChoiceType] FOREIGN KEY ([ChoiceTypeId]) REFERENCES [dbo].[LuProjectChoiceType] ([ChoiceTypeId]),
    CONSTRAINT [FK_ProjectSegmentChoice_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectSegmentChoice_ProjectSection] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId]),
    CONSTRAINT [FK_ProjectSegmentChoice_ProjectSegment] FOREIGN KEY ([SegmentId]) REFERENCES [dbo].[ProjectSegment] ([SegmentId]),
    CONSTRAINT [FK_ProjectSegmentChoice_ProjectSegmentStatus] FOREIGN KEY ([SegmentStatusId]) REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId])
);


GO
CREATE NONCLUSTERED INDEX [CIX_ProjectSegmentChoice_SectionId_ProjectId_CustomerId]
    ON [dbo].[ProjectSegmentChoice]([SectionId] ASC, [ProjectId] ASC, [CustomerId] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [NCIX_ProjectSegmentChoice]
    ON [dbo].[ProjectSegmentChoice]([SegmentChoiceId] ASC, [SectionId] ASC)
    INCLUDE([SegmentStatusId], [SegmentId], [ProjectId], [CustomerId]) WITH (FILLFACTOR = 90);

