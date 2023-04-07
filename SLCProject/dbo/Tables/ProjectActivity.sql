CREATE TABLE ProjectActivity(
ActivityId Int IDENTITY NOT NULL PRIMARY KEY,
ProjectId Int,
UserId Int,
CustomerId Int,
ProjectName NVARCHAR(100),
UserEmail NVARCHAR(100),
ProjectActivityTypeId TINYINT FOREIGN KEY  REFERENCES LuProjectActivityType(ProjectActivityTypeId),
CreatedDate DATETIME2(7)
);