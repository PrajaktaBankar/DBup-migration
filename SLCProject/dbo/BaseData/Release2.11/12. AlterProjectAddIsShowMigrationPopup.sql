Use SLCProject
go

ALTER TABLE Project
ADD IsShowMigrationPopup bit 
DEFAULT 0 NOT NULL;
GO


--Update Project
--set IsShowMigrationPopup = 1 where projectid IN 
--(Select projectId from Project where ISNULL(IsMigrated,0) = 1)
GO
