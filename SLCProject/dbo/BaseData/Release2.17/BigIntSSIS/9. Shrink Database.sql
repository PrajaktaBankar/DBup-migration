

USE SLCProject;
GO
-- Shrink the mdf file
DBCC SHRINKFILE(N'SLCProject', 0);
GO
-- Shrink the log.ldf file
DBCC SHRINKFILE(N'SLCProject_log', 0);
GO
