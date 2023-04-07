USE SLCProject
GO

IF NOT EXISTS (SELECT 1	FROM LuSectionSource WHERE [Name] = 'Master')
BEGIN
  INSERT INTO LuSectionSource VALUES('Master','Master')
END
ELSE 
Print 'Alread exists "Master" in LuSectionSource'
GO

IF NOT EXISTS (SELECT 1	FROM LuSectionSource WHERE [Name] = 'MasterWithProjectImport')
BEGIN
  INSERT INTO LuSectionSource VALUES('MasterWithProjectImport','Master section imported from other projects')
END
ELSE 
Print 'Alread exists "MasterWithProjectImport" in LuSectionSource'
GO

IF NOT EXISTS (SELECT 1	FROM LuSectionSource WHERE [Name] = 'UserWithProjectImport')
BEGIN
  INSERT INTO LuSectionSource VALUES('UserWithProjectImport','User section imported from other projects')
END
ELSE 
Print 'Alread exists "UserWithProjectImport" in LuSectionSource'
GO

IF NOT EXISTS (SELECT 1	FROM LuSectionSource WHERE [Name] = 'CopyMasterSection')
BEGIN
  INSERT INTO LuSectionSource VALUES('CopyMasterSection','Copy from master section')
END
ELSE 
Print 'Alread exists "CopyMasterSection" in LuSectionSource'
GO

IF NOT EXISTS (SELECT 1	FROM LuSectionSource WHERE [Name] = 'CopyUserSection')
BEGIN
  INSERT INTO LuSectionSource VALUES('CopyUserSection','Copy from user section')
END
ELSE 
Print 'Alread exists "CopyUserSection" in LuSectionSource'
GO

IF NOT EXISTS (SELECT 1	FROM LuSectionSource WHERE [Name] = 'FromTemplate')
BEGIN
 INSERT INTO LuSectionSource VALUES('FromTemplate','From template')
END
ELSE 
Print 'Alread exists "FromTemplate" in LuSectionSource'
GO

IF NOT EXISTS (SELECT 1	FROM LuSectionSource WHERE [Name] = 'FromWord')
BEGIN
 INSERT INTO LuSectionSource VALUES('FromWord','From word')
END
ELSE 
Print 'Alread exists "FromWord" in LuSectionSource'
GO

IF NOT EXISTS (SELECT 1	FROM LuSectionSource WHERE [Name] = 'AlternateDoc')
BEGIN
 INSERT INTO LuSectionSource VALUES('AlternateDoc','Alternate document section')
END
ELSE 
Print 'Alread exists "AlternateDoc" in LuSectionSource'
GO

IF NOT EXISTS (SELECT 1	FROM LuSectionDocumentType WHERE [Type] = 'AlternateDocument')
BEGIN
 INSERT INTO LuSectionDocumentType VALUES('AlternateDocument','Alternate document section')
END
ELSE 
Print 'Alread exists "AlternateDoc" in LuSectionDocumentType'
GO
