Use SLCProject
GO

/* to check log file size
Use SLCProject
GO

SELECT file_id, name, type_desc, physical_name, size, max_size  
FROM sys.database_files ;  
GO
*/


ALTER DATABASE SLCProject
SET RECOVERY SIMPLE
GO

DBCC SHRINKFILE (SLCProject_log, 1)
GO