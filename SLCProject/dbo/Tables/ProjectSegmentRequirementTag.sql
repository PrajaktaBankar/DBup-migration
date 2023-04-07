CREATE TABLE [dbo].[ProjectSegmentRequirementTag] (
    [SegmentRequirementTagId]  BIGINT           IDENTITY (1, 1) NOT NULL,
    [SectionId]                INT           NOT NULL,
    [SegmentStatusId]          BIGINT           NULL,
    [RequirementTagId]         INT           NOT NULL,
    [CreateDate]               DATETIME2 (7) NOT NULL,
    [ModifiedDate]             DATETIME2 (7) NULL,
    [ProjectId]                INT           NOT NULL,
    [CustomerId]               INT           NOT NULL,
    [CreatedBy]                INT           NOT NULL,
    [ModifiedBy]               INT           NULL,
    [mSegmentRequirementTagId] INT           NULL,
    [IsDeleted]                BIT           DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PROJECTSEGMENTREQUIREMENTTAG] PRIMARY KEY CLUSTERED ([SegmentRequirementTagId] ASC),
    CONSTRAINT [FK_ProjectSegmentRequirementTag_LuProjectRequirementTag] FOREIGN KEY ([RequirementTagId]) REFERENCES [dbo].[LuProjectRequirementTag] ([RequirementTagId]),
    CONSTRAINT [FK_ProjectSegmentRequirementTag_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectSegmentRequirementTag_ProjectSegmentStatus] FOREIGN KEY ([SegmentStatusId]) REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId])
);




GO



GO
CREATE NONCLUSTERED INDEX [IX_PSRT_SegmentStatusId_RequirementTagId]
    ON [dbo].[ProjectSegmentRequirementTag]([SegmentStatusId] ASC, [RequirementTagId] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_ProjectSegmentRequirementTag_SectionId_SegmentStatusId_ProjectId]
    ON [dbo].[ProjectSegmentRequirementTag]([SectionId] ASC, [SegmentStatusId] ASC, [ProjectId] ASC) WITH (FILLFACTOR = 90);

