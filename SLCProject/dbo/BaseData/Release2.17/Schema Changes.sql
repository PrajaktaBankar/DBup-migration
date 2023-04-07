USE SLCProject
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsHiddenAllBsdSections' AND Object_ID = Object_ID(N'[dbo].[ProjectSummary]'))
BEGIN
   ALTER TABLE ProjectSummary ADD IsHiddenAllBsdSections BIT DEFAULT 0 ;
END
ELSE 
Print 'Alread exists IsHiddenAllBsdSections'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsHidden' AND Object_ID = Object_ID(N'[dbo].[ProjectSection]'))
BEGIN
   ALTER TABLE ProjectSection ADD IsHidden BIT DEFAULT 0 ;
END
ELSE 
Print 'Alread exists IsHidden'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'SortOrder' AND Object_ID = Object_ID(N'[dbo].[ProjectSection]'))
BEGIN
   ALTER TABLE ProjectSection ADD SortOrder INT ;
END
ELSE 
Print 'Alread exists SortOrder'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsLinkEngineEnabled' AND Object_ID = Object_ID(N'[dbo].[ProjectSummary]'))
BEGIN
    ALTER TABLE ProjectSummary ADD IsLinkEngineEnabled BIT DEFAULT 1

   	UPDATE ps SET ps.IsLinkEngineEnabled = 1
	FROM ProjectSummary ps WITH(NOLOCK)
	WHERE ps.IsLinkEngineEnabled IS NULL

	ALTER TABLE ProjectSummary
	ALTER COLUMN IsLinkEngineEnabled BIT NOT NULL

END
ELSE 
Print 'Alread exists IsLinkEngineEnabled'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'TargetParentSectionId' AND Object_ID = Object_ID(N'[dbo].[ImportProjectRequest]'))
BEGIN
   ALTER TABLE ImportProjectRequest  ADD TargetParentSectionId INT DEFAULT 0;
END
ELSE 
Print 'Alread exists TargetParentSectionId'
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsCreateFolderStructure' AND Object_ID = Object_ID(N'[dbo].[ImportProjectRequest]'))
BEGIN
  ALTER table ImportProjectRequest ADD IsCreateFolderStructure bit default 0
END
ELSE 
Print 'Alread exists IsCreateFolderStructure'
GO
