USE SLCProject
GO
----------Add 'SLC Project'--------------------------------------------------------------

IF NOT EXISTS (SELECT 1	FROM LuProjectOriginType WHERE [Name] = 'SLC Project')
BEGIN
	INSERT INTO LuProjectOriginType ([Name], [Description], IsActive)
	VALUES ('SLC Project', 'Projects that are created or copied in SLC', 1);
END
ELSE
BEGIN
	PRINT ('SLC Project - already exists in table LuProjectOriginType.');
END

----------Add 'Migrated Project'----------------------------------------------------------
GO
IF NOT EXISTS (SELECT 1	FROM LuProjectOriginType WHERE [Name] = 'Migrated Project')
BEGIN
	INSERT INTO LuProjectOriginType ([Name], [Description], IsActive)
	VALUES ('Migrated Project','Projects that are migrated from SLE into SLC',1);
END
ELSE
BEGIN
	PRINT ('Migrated Project - already exists in table LuProjectOriginType.');
END

----------Add 'Transferred Project'-------------------------------------------------------
GO
IF NOT EXISTS (SELECT 1	FROM LuProjectOriginType WHERE [Name] = 'Transferred Project')
BEGIN
	INSERT INTO LuProjectOriginType ([Name], [Description], IsActive)
	VALUES ('Transferred Project','Transferred Project',1);
END
ELSE
BEGIN
	PRINT ('Transferred Project - already exists in table LuProjectOriginType.');
END