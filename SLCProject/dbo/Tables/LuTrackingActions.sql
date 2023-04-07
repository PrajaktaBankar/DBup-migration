CREATE TABLE [dbo].[LuTrackingActions] (
    [TrackActionId] INT           IDENTITY (1, 1) NOT NULL,
    [TrackActions]  NVARCHAR (50) NULL,
    PRIMARY KEY CLUSTERED ([TrackActionId] ASC)
);

