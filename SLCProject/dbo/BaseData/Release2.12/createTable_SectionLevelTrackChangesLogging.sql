USE SLCProject
GO
IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'SectionLevelTrackChangesLogging'))
BEGIN
CREATE TABLE SectionLevelTrackChangesLogging (
SectionChangeId Int IDENTITY NOT NULL PRIMARY KEY,
UserId Int,
ProjectId Int,
SectionId Int,
CustomerId Int,
UserEmail NVARCHAR(100),
IsTrackChanges BIT,
IsTrackChangeLock BIT,
CreatedDate DATETIME2(7)
);
END
ELSE
Print 'SectionLevelTrackChangesLogging name already exist' 
GO