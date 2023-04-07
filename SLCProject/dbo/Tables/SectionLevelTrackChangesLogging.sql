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