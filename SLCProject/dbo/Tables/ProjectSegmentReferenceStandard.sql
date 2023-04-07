CREATE TABLE [dbo].[ProjectSegmentReferenceStandard] (
    [SegmentRefStandardId] INT           IDENTITY (1, 1) NOT NULL,
    [SectionId]            INT           NOT NULL,
    [SegmentId]            BIGINT           NULL,
    [RefStandardId]        INT           NULL,
    [RefStandardSource]    CHAR (1)      NULL,
    [mRefStandardId]       INT           NULL,
    [CreateDate]           DATETIME2 (7) NOT NULL,
    [CreatedBy]            INT           NOT NULL,
    [ModifiedDate]         DATETIME2 (7) NULL,
    [ModifiedBy]           INT           NULL,
    [mSegmentId]           INT           NULL,
    [ProjectId]            INT           NOT NULL,
    [CustomerId]           INT           NOT NULL,
    [RefStdCode]           INT           NULL,
    [IsDeleted]            BIT           DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PROJECTSEGMENTREFERENCESTANDARD] PRIMARY KEY CLUSTERED ([SegmentRefStandardId] ASC),
    CONSTRAINT [FK_ProjectSegmentReferenceStandard_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectSegmentReferenceStandard_ProjectSection] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId])
);



GO

CREATE NONCLUSTERED INDEX [NCI_ProjectId_SegmentId_RefStdCode]
    ON [dbo].[ProjectSegmentReferenceStandard]([SegmentId] DESC, [ProjectId] DESC, [RefStdCode] DESC, [SectionId] DESC) WITH (FILLFACTOR = 90);


GO
