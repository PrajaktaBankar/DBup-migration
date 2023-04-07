IF NOT EXISTS (SELECT TOP 1
		*
	FROM LuTCPrintMode)
BEGIN
INSERT INTO [dbo].[LuTCPrintMode] (Name, Description, CreatedBy, CreateDate)
	VALUES ('InheritFromSection', 'Inherit from section', 1, GETUTCDATE()),
	('AllWithTrackChanges', 'All sections with markup', 1, GETUTCDATE()),
	('AllWithoutTrackChanges', 'All sections without markup', 1, GETUTCDATE())
END