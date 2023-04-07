IF EXISTS(SELECT 1 FROM SYS.TABLES WHERE [NAME] = 'ProjectSetting')
BEGIN
	PRINT 'ProjectSetting table already exists.';
END
ELSE
BEGIN
	CREATE TABLE [ProjectSetting] (
	[Id]			INT IDENTITY(1,1) NOT NULL,
	[ProjectId]		INT NOT NULL,
	[CustomerId]	INT NOT NULL,
	[Name]			NVARCHAR(50) NOT NULL,
	[Value]			NVARCHAR(100) NOT NULL,
	[CreatedDate]	DATETIME2(7) NOT NULL,
	[CreatedBy]		INT NOT NULL,
	[ModifiedDate]	DATETIME2(7) NULL,
	[ModifiedBy]	INT default NULL,
	CONSTRAINT [FK_ProjectSetting_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId])
	);
	PRINT 'ProjectSetting table created successfully.';
END
GO
-------------------------------------
IF EXISTS(SELECT 1 FROM SYS.TABLES WHERE [NAME] = 'CustomerDivision')
BEGIN
	PRINT 'CustomerDivision table already exists.';
END
ELSE
BEGIN
	CREATE TABLE CustomerDivision(          
	[DivisionId]		BIGINT IDENTITY(1000000,1),        
	[DivisionCode]		NVARCHAR(100),
	[DivisionTitle]		NVARCHAR(4000),
	[IsActive]			BIT,         
	[MasterDataTypeId]	INT,
	[FormatTypeId]		INT,
	[IsDeleted]			BIT,
	[CustomerId]		INT,
	[CreatedBy]			INT NULL, 
	[CreatedDate]		DATETIME2 NULL, 
	[ModifiedBy]		INT NULL, 
	[ModifiedDate]		DATETIME2 NULL,
	CONSTRAINT [PK_CustomerDivision] PRIMARY KEY CLUSTERED ([DivisionId] ASC),
	CONSTRAINT [FK_CustomerDivision_LuMasterDataType] FOREIGN KEY (MasterDataTypeId) REFERENCES LuMasterDataType (MasterDataTypeId),
	CONSTRAINT [FK_CustomerDivision_LuFormatType] FOREIGN KEY (FormatTypeId) REFERENCES LuFormatType (FormatTypeId)
	);
	PRINT 'CustomerDivision table created successfully.';
END
--------------------------------------------------------------------------------------------------------------
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