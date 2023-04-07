USE SLCProject
GO

ALTER TABLE ProjectMigrationException ADD ModifiedBy int DEFAULT NULL;
GO
ALTER TABLE ProjectMigrationException ADD ModifiedDate DATETIME2(7) DEFAULT NULL;
GO