CREATE TABLE [dbo].[ProjectSegment] (
    [SegmentId]              BIGINT            IDENTITY (1, 1) NOT NULL,
    [SegmentStatusId]        BIGINT            NULL,
    [SectionId]              INT            NOT NULL,
    [ProjectId]              INT            NOT NULL,
    [CustomerId]             INT            NOT NULL,
    [SegmentDescription]     NVARCHAR (MAX) NULL,
    [SegmentSource]          CHAR (1)       NULL,
    [SegmentCode]            BIGINT            CONSTRAINT [Default_ProjectSegment_SegmentCode] DEFAULT (NEXT VALUE FOR [seq_ProjectSegment]) NULL,
    [CreatedBy]              INT            NOT NULL,
    [CreateDate]             DATETIME2 (7)  NOT NULL,
    [ModifiedBy]             INT            NULL,
    [ModifiedDate]           DATETIME2 (7)  NULL,
    [SLE_DocID]              INT            NULL,
    [SLE_SegmentID]          INT            NULL,
    [SLE_StatusID]           INT            NULL,
    [A_SegmentId]            BIGINT            NULL,
    [IsDeleted]              BIT            DEFAULT ((0)) NOT NULL,
    [BaseSegmentDescription] NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_PROJECTSEGMENT] PRIMARY KEY CLUSTERED ([SegmentId] ASC),
    CONSTRAINT [FK_ProjectSegments_Projects] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectSegments_ProjectSections] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId]),
    CONSTRAINT [FK_ProjectSegments_ProjectSegmentStatus] FOREIGN KEY ([SegmentStatusId]) REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId])
);


GO

CREATE NONCLUSTERED INDEX [CIX_ProjectSegment_SegmentStatusId]
    ON [dbo].[ProjectSegment]([SegmentStatusId] DESC, [SectionId] DESC, [ProjectId] DESC)
    INCLUDE([SegmentCode], [IsDeleted]) WITH (FILLFACTOR = 90);


GO

CREATE FULLTEXT INDEX ON [dbo].[ProjectSegment]
    ([SegmentDescription] LANGUAGE 1033)
    KEY INDEX [PK_PROJECTSEGMENT]
    ON [FTProjectSegment];
GO

