CREATE PROCEDURE [dbo].[usp_DeleteProjectPermanent]      
  	@projectId INT  
  AS      
BEGIN
     
	DECLARE @PprojectId INT = @projectId;
	IF EXISTS (SELECT TOP 1
		1
	FROM Project WITH (NOLOCK)
	WHERE ProjectId = @PprojectId)
BEGIN
UPDATE p
SET p.IsPermanentDeleted = 1
from Project p WITH (NOLOCK)
WHERE p.ProjectId = @PprojectId and p.IsDeleted=1
END
END
GO
