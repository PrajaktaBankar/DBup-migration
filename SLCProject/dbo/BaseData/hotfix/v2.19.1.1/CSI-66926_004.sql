
/*
Customer Support 66926: Client wants export that is stuck canceled out - 45975/1972
Server - 004
*/
USE SLCProject

GO

UPDATE PE SET IsDeleted = 1 FROM ProjectExport PE WITH(NOLOCK) WHERE ProjectExportId = 148806;