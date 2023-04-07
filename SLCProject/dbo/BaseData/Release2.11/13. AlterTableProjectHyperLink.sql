Use SLCProject
go

ALTER TABLE ProjectHyperLink
DROP COLUMN ModifiedBy
GO

ALTER TABLE ProjectHyperLink
Add  ModifiedBy int NULL
GO
