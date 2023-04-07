
--Database:Authentication
--Production Support 60319: SLC- Duplicate links are not allowed error
--76241-User cannot be removed from SLC
--Records affected: 1

--Query
	
	UPDATE UserRole SET IsDeleted=1 WHERE UserRoleId=37649