/*
 Server name : Authentication
 Customer Support 67931: SpecLive Licenses
*/

USE Authentication
GO

--SELECT * FROM [User] WHERE Email = 'bob@avecs.build'
--SELECT * FROM UserRole WHERE UserId = 23404

UPDATE UserRole SET IsActive = 0, IsDeleted = 1 WHERE UserId = 23404 AND UserRoleId = 26231;