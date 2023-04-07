UPDATE SLCProject..ProjectExport 
SET FileStatus = 'Completed'
WHERE FileStatus = 'In Progress'