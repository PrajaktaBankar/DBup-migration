CREATE TABLE [dbo].[ProjectSegmentTab] (
    [SegmentTabId]    INT           IDENTITY (1, 1) NOT NULL,
    [CustomerId]      INT           NOT NULL,
    [ProjectId]       INT           NOT NULL,
    [SectionId]       INT           NULL,
    [SegmentStatusId] BIGINT           NULL,
    [TabTypeId]       INT           NULL,
    [TabPosition]     INT           NULL,
    [CreateDate]      DATETIME2 (7) NOT NULL,
    [CreatedBy]       INT           NOT NULL,
    [ModifiedDate]    DATETIME2 (7) NULL,
    [ModifiedBy]      INT           NULL,
    CONSTRAINT [PK_PROJECTSEGMENTTAB] PRIMARY KEY CLUSTERED ([SegmentTabId] ASC),
    CONSTRAINT [FK_ProjectTab_LuProjectTabType] FOREIGN KEY ([TabTypeId]) REFERENCES [dbo].[LuProjectTabType] ([TabTypeId]),
    CONSTRAINT [FK_ProjectTab_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectTab_ProjectSection] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId]),
    CONSTRAINT [FK_ProjectTab_ProjectSegmentStatus] FOREIGN KEY ([SegmentStatusId]) REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId])
);

