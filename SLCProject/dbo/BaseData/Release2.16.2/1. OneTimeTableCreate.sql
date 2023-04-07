USE SLCProject
GO
IF EXISTS(SELECT 1 FROM SYS.TABLES WHERE [NAME] = 'UserPreference')
BEGIN
	PRINT 'UserPreference table already exists.';
END
ELSE
BEGIN
CREATE TABLE UserPreference
(
	UserPreferenceId INT IDENTITY(1,1),
	UserId INT NULL,
	CustomerId INT NOT NULL,
	Name NVARCHAR(100) NOT NULL,
	Value NVARCHAR(500),
	CreatedDate DATETIME2 NOT NULL,
	ModifiedDate DATETIME2 NULL
	CONSTRAINT [PK_UserPreference] PRIMARY KEY CLUSTERED (UserPreferenceId ASC)
)
END
GO