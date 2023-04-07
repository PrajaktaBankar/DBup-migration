CREATE TABLE [dbo].[TrackAcceptRejectProjectSegmentHistory] (
    [TrackHistoryId] INT            IDENTITY (1, 1) NOT NULL,
    [SectionId]      INT            NOT NULL,
    [SegmentId]      BIGINT            NULL,
    [ProjectId]      INT            NOT NULL,
    [CustomerId]     INT            NOT NULL,
    [BeforEdit]      NVARCHAR (MAX) NULL,
    [AfterEdit]      NVARCHAR (MAX) NULL,
    [TrackActionId]  INT            NULL,
    [Note]           NVARCHAR (MAX) NULL,
    FOREIGN KEY ([TrackActionId]) REFERENCES [dbo].[LuTrackingActions] ([TrackActionId])
);

