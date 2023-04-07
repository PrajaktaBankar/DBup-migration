UPDATE SLCProject..ProjectExport 
SET FileStatus = 'Failed'
WHERE FileStatus = 'In Progress'