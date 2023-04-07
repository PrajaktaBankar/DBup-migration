CREATE TABLE [dbo].[ProjectSegmentTracking] (
    [TrackId]            INT             IDENTITY (1, 1) NOT NULL,
    [SegmentId]          BIGINT             NULL,
    [ProjectId]          INT             NOT NULL,
    [CustomerId]         INT             NOT NULL,
    [UserId]             INT             NOT NULL,
    [SegmentDescription] NVARCHAR (255)  NULL,
    [CreatedBy]          INT             NOT NULL,
    [CreateDate]         DATETIME2 (7)   NOT NULL,
    [VersionNumber]      DECIMAL (18, 4) NULL,
    CONSTRAINT [PK_PROJECTSEGMENTTRACKING] PRIMARY KEY CLUSTERED ([TrackId] ASC),
    CONSTRAINT [FK_ProjectSegmentTrackChanges_ProjectSegments] FOREIGN KEY ([SegmentId]) REFERENCES [dbo].[ProjectSegment] ([SegmentId])
);

