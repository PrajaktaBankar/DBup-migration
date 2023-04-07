USE SLCProject
GO
IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'ProjectLevelTrackChangesLogging'))
BEGIN
CREATE TABLE ProjectLevelTrackChangesLogging (
ProjectChangeId Int IDENTITY NOT NULL PRIMARY KEY,
UserId Int,
ProjectId Int,
CustomerId Int,
UserEmail NVARCHAR(100),
PriviousTrackChangeModeId TINYINT FOREIGN KEY  REFERENCES LuTrackChangesMode(TcModeId),
CurrentTrackChangeModeId TINYINT FOREIGN KEY  REFERENCES LuTrackChangesMode(TcModeId),
CreatedDate DATETIME2(7)  
);
END
ELSE
Print 'ProjectLevelTrackChangesLogging name already exist' 
GO