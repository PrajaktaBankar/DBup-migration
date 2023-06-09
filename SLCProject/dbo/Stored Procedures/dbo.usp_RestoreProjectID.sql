CREATE PROCEDURE [dbo].[usp_RestoreProjectID]            
   @projectId INT,  
   @CustomerId INT,  
   @userID INT,  
   @UserName NVARCHAR(500)null=''        
  AS            
BEGIN
 
   DECLARE @PprojectId INT = @projectId;
   DECLARE @PCustomerId INT = @CustomerId;
   DECLARE @PuserID INT = @userID;
   DECLARE @PUserName NVARCHAR(500) = @UserName;
          
 IF EXISTS (SELECT TOP 1
		1
	FROM Project WITH (NOLOCK)
	WHERE ProjectId = @PprojectId
	AND CustomerId = @PCustomerId)
BEGIN
UPDATE P
SET P.IsDeleted = 0
   ,P.ModifiedBy = @PuserID
   ,P.ModifiedDate = GETUTCDATE()
   ,P.ModifiedByFullName = @PUserName
   FROM Project P WITH (NOLOCK)
WHERE P.ProjectId = @PprojectId
AND P.CustomerId = @PCustomerId
END
END

GO
