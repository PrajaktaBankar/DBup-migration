
USE SLCProject 
go

ALTER TABLE ProjectSection 
ADD [DataMapDateTimeStamp]      DATETIME2 (7)  NULL

GO

ALTER TABLE SegmentComment 
ADD A_SegmentCommentId INT NULL