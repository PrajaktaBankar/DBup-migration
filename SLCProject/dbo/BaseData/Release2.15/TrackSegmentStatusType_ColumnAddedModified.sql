USE SLCProject
GO

ALTER TABLE TrackSegmentStatusType
ADD CurrentStatus BIT NULL;

ALTER TABLE TrackSegmentStatusType
ALTER COLUMN  InitialStatus BIT NULL;
