USE SLCProject
GO
----------Add 'Not Assigned'--------------------------------------------------------------

IF NOT EXISTS (SELECT 1	FROM LuProjectOwnerType WHERE [Name] = 'Not Assigned')
BEGIN
	insert into LuProjectOwnerType([Name],[Description],IsActive, SortOrder) 
	values ('Not Assigned','Not Assigned',1, 1);
END
ELSE
BEGIN
	PRINT ('"Not Assigned" type already exists in table LuProjectOwnerType.');
END

----------Add 'User Who Received the Project'----------------------------------------------------------
GO
IF NOT EXISTS (SELECT 1	FROM LuProjectOwnerType WHERE [Name] = 'User Who Received the Project')
BEGIN
	insert into LuProjectOwnerType([Name],[Description],IsActive, SortOrder) 
	values ('User Who Received the Project','User Who Received the Project',1, 2)
END
ELSE
BEGIN
	PRINT ('"User Who Received the Project" type already exists in table LuProjectOwnerType.');
END

----------Add 'User Who Created the Project'-------------------------------------------------------
GO
IF NOT EXISTS (SELECT 1	FROM LuProjectOwnerType WHERE [Name] = 'User Who Created the Project')
BEGIN
	insert into LuProjectOwnerType([Name],[Description],IsActive, SortOrder) 
	values ('User Who Created the Project','User Who Created the Project',1,3);
END
ELSE
BEGIN
	PRINT ('"User Who Created the Project" type already exists in table LuProjectOwnerType.');
END