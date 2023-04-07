USE SLCProject
GO
IF NOT EXISTS (SELECT 1	FROM LuProjectActivityType WHERE [Name] = 'Locked')
BEGIN
INSERT INTO LuProjectActivityType ( [Name], [Description])
VALUES ( 'Locked','Locked' )
END 

IF NOT EXISTS (SELECT 1	FROM LuProjectActivityType WHERE [Name] = 'Unlocked')
BEGIN
INSERT INTO LuProjectActivityType ( [Name], [Description])
VALUES ( 'Unlocked','Unlocked' )
END 

IF NOT EXISTS (SELECT 1	FROM LuProjectActivityType WHERE [Name] = 'Restored')
BEGIN
INSERT INTO LuProjectActivityType ( [Name], [Description])
VALUES ( 'Restored','Restored' )
END

IF NOT EXISTS (SELECT 1	FROM LuProjectActivityType WHERE [Name] = 'Archived')
BEGIN
INSERT INTO LuProjectActivityType ( [Name], [Description])
VALUES ( 'Archived','Archived' )
END
ELSE
BEGIN
	PRINT ('Data already exists in table LuProjectActivityType.');
END
GO