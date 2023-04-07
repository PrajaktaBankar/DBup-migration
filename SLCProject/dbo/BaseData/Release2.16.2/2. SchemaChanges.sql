USE SLCProject
GO
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsLinkEngineEnabled' AND Object_ID = Object_ID(N'[dbo].[ProjectSummary]'))
BEGIN
    ALTER TABLE ProjectSummary ADD IsLinkEngineEnabled BIT DEFAULT 1
END
ELSE 
Print 'Alread exists IsLinkEngineEnabled'
GO

	UPDATE ps SET ps.IsLinkEngineEnabled = 1
	FROM ProjectSummary ps WITH(NOLOCK)
	WHERE ps.IsLinkEngineEnabled IS NULL
GO
	ALTER TABLE ProjectSummary
	ALTER COLUMN IsLinkEngineEnabled BIT NOT NULL
GO