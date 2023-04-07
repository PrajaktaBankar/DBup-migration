USE SLCProject

GO

ALTER TABLE ProjectMigrationException ADD IsResolved BIT DEFAULT 0; 
GO
--User Story 34428: Migration: Restrictions for migrated projects with errors
--Excute it on Prodoction only after  alter the ProjectMigrationException table and IsResolved column is added.
--Restrictions for migrated projects with errors is not applicable for old/legacy project 
UPDATE PME
SET PME.IsResolved=1
FROM ProjectMigrationException PME WITH (NOLOCK)