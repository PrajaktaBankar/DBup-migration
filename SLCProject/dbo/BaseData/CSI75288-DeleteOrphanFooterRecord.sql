/*

Customer Support 75288: Create New Project from existing project failed - 64856/2204

Orphan footer record causing copy project to fail.
Uncomment begin and commit and rollback before running
make sure only one record is affected.

--SELECT * FROM dbo.HeaderFooterGlobalTermUsage WHERE ProjectId=15828 AND HeaderFooterGTId=13672

*/

USE SLCProject
GO

--BEGIN TRAN 

DELETE dbo.HeaderFooterGlobalTermUsage WHERE ProjectId=15828 AND HeaderFooterGTId=13672
--make sure only one record is affected


--commit tran

--rollback tran