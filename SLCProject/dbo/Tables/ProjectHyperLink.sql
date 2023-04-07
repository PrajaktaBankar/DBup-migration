CREATE TABLE [dbo].[ProjectHyperLink] (
    [HyperLinkId]             INT            IDENTITY (1, 1) NOT NULL,
    [SectionId]               INT            NOT NULL,
    [SegmentId]               BIGINT            NULL,
    [SegmentStatusId]         BIGINT            NULL,
    [ProjectId]               INT            NOT NULL,
    [CustomerId]              INT            NOT NULL,
    [LinkTarget]              NVARCHAR (500) NULL,
    [LinkText]                NVARCHAR (500) NULL,
    [LuHyperLinkSourceTypeId] INT            NOT NULL,
    [CreateDate]              DATETIME2 (7)  NOT NULL,
    [CreatedBy]               INT            NOT NULL,
    [ModifiedDate]            DATETIME2 (7)  NULL,
    [SLE_DocID]               INT            NULL,
    [SLE_SegmentID]           INT            NULL,
    [SLE_StatusID]            INT            NULL,
    [SLE_LinkNo]              SMALLINT       NULL,
    [A_HyperLinkId]           INT            NULL,
    [ModifiedBy]              INT            NULL,
    CONSTRAINT [PK_PROJECTHYPERLINK] PRIMARY KEY CLUSTERED ([HyperLinkId] ASC),
    CONSTRAINT [FK_ProjectHyperLink_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId]),
    CONSTRAINT [FK_ProjectHyperLink_ProjectSection] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[ProjectSection] ([SectionId]),
    CONSTRAINT [FK_ProjectHyperLink_ProjectSegmentStatus] FOREIGN KEY ([SegmentStatusId]) REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId])
);




GO
CREATE NONCLUSTERED INDEX [IX__ProjectHyperLink_ProjectId_SectionId_SegmentStatusId]
    ON [dbo].[ProjectHyperLink]([SectionId] ASC, [ProjectId] ASC)
    INCLUDE([SegmentStatusId]) WITH (FILLFACTOR = 90);

