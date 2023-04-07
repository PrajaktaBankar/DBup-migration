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