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
)