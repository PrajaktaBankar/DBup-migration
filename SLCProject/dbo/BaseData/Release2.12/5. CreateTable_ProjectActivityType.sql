USE SLCProject
GO
IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'LuProjectActivityType'))
BEGIN
CREATE Table LuProjectActivityType(
ProjectActivityTypeId TINYINT IDENTITY NOT NULL PRIMARY KEY,
[Name] NVARCHAR(100),
[Description] NVARCHAR(100),
);
END
ELSE
Print 'LuProjectActivityType name already exist' 
GO
--------------------------------------------------------------------------------------------------------------------------
USE SLCProject
GO
IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'ProjectActivity'))
BEGIN
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
END
ELSE
Print 'ProjectActivity Table already exist' 
GO