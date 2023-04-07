USE SLCProject
GO

IF NOT EXISTS (SELECT 1	FROM LuImportedDocType WHERE DocType = 'PDF')
BEGIN
  INSERT INTO LuImportedDocType VALUES('PDF','PDF')
END
ELSE 
Print 'Alread exists "PDF" in LuImportedDocType'
GO

IF NOT EXISTS (SELECT 1	FROM LuImportedDocType WHERE DocType = 'Image')
BEGIN
  INSERT INTO LuImportedDocType VALUES('Image','Image')
END
ELSE 
Print 'Alread exists "Image" in LuImportedDocType'
GO

