CREATE TABLE [dbo].[TrackProjectSegment] (
    [TrackSegmentId] INT            IDENTITY (1, 1) NOT NULL,
    [SectionId]      INT            NOT NULL,
    [SegmentId]      BIGINT            NULL,
    [ProjectId]      INT            NOT NULL,
    [CustomerId]     INT            NOT NULL,
    [BeforEdit]      NVARCHAR (MAX) NULL,
    [AfterEdit]      NVARCHAR (MAX) NULL,
    [CreateDate]     DATETIME       NULL,
    [ChangedDate]    DATETIME       NULL,
    [ChangedById]    INT            NULL,
    [IsDeleted]      BIT            NULL,
    CONSTRAINT [PK_TrackProjectSegment] PRIMARY KEY CLUSTERED ([TrackSegmentId] ASC),
    CONSTRAINT [FK_TrackProjectSegment_ProjectSegments] FOREIGN KEY ([SegmentId]) REFERENCES [dbo].[ProjectSegment] ([SegmentId])
);

