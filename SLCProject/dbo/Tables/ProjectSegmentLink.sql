CREATE TABLE [dbo].[ProjectSegmentLink] (
    [SegmentLinkId]           BIGINT           IDENTITY (1, 1) NOT NULL,
    [SourceSectionCode]       INT           NOT NULL,
    [SourceSegmentStatusCode] BIGINT           NOT NULL,
    [SourceSegmentCode]       BIGINT           NOT NULL,
    [SourceSegmentChoiceCode] BIGINT           NULL,
    [SourceChoiceOptionCode]  BIGINT           NULL,
    [LinkSource]              VARCHAR (1)   NULL,
    [TargetSectionCode]       INT           NOT NULL,
    [TargetSegmentStatusCode] BIGINT           NOT NULL,
    [TargetSegmentCode]       BIGINT           NOT NULL,
    [TargetSegmentChoiceCode] BIGINT           NULL,
    [TargetChoiceOptionCode]  BIGINT           NULL,
    [LinkTarget]              VARCHAR (1)   NULL,
    [LinkStatusTypeId]        INT           NULL,
    [IsDeleted]               BIT           DEFAULT ((0)) NOT NULL,
    [CreateDate]              DATETIME2 (7) NOT NULL,
    [CreatedBy]               INT           NOT NULL,
    [ModifiedBy]              INT           NULL,
    [ModifiedDate]            DATETIME2 (7) NULL,
    [ProjectId]               INT           NOT NULL,
    [CustomerId]              INT           NOT NULL,
    [SegmentLinkCode]         BIGINT           CONSTRAINT [Default_ProjectSegmentLink_SegmentLinkCode] DEFAULT (NEXT VALUE FOR [seq_ProjectSegmentLink]) NULL,
    [SegmentLinkSourceTypeId] INT           DEFAULT ((5)) NULL,
    CONSTRAINT [PK_PROJECTSEGMENTLINK] PRIMARY KEY CLUSTERED ([SegmentLinkId] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_ProjectSegmentLink_LuSegmentLinkSourceType] FOREIGN KEY ([SegmentLinkSourceTypeId]) REFERENCES [dbo].[LuSegmentLinkSourceType] ([SegmentLinkSourceTypeId]),
    CONSTRAINT [FK_ProjectSegmentLink_ProjectSegmentLink] FOREIGN KEY ([LinkStatusTypeId]) REFERENCES [dbo].[LuProjectLinkStatusType] ([LinkStatusTypeId])
);


GO
CREATE NONCLUSTERED INDEX [NCIX_ProjectSegmentLink_CustomerId]
    ON [dbo].[ProjectSegmentLink]([CustomerId] ASC);


GO
CREATE NONCLUSTERED INDEX [NCIX_ProjectSegmentLink_ProjectId]
    ON [dbo].[ProjectSegmentLink]([ProjectId] ASC)
    INCLUDE([CustomerId]);


GO
CREATE NONCLUSTERED INDEX [NCIX_ProjectSegmentLink_SourceSectionCode_SourceSegmentStatusCode_LinkSource]
    ON [dbo].[ProjectSegmentLink]([SourceSectionCode] ASC, [SourceSegmentStatusCode] ASC, [LinkSource] ASC);


GO
CREATE NONCLUSTERED INDEX [NCIX_ProjectSegmentLink_TargetSectionCode_TargetSegmentStatusCode_LinkTarget]
    ON [dbo].[ProjectSegmentLink]([TargetSectionCode] ASC, [TargetSegmentStatusCode] ASC, [LinkTarget] ASC);


GO
CREATE NONCLUSTERED INDEX [NCIX_ProjectSegmentLink_SegmentLinkCode]
    ON [dbo].[ProjectSegmentLink]([SegmentLinkCode] ASC);

