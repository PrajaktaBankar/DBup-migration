CREATE PROCEDURE [dbo].[usp_DeleteProjectID]  -- exec [dbo].[usp_DeleteProjectID]   12824,2514          
    @projectId INT,          
	--@customerID INT,    
	@userID INT,   
    @ModifiedDate DATETIME       
 AS        
                 
BEGIN
               
    DECLARE @PprojectId INT = @projectId;
	DECLARE @PuserID INT = @userID;
    DECLARE @PModifiedDate DATETIME= @ModifiedDate;
 DECLARE @IsSuccess BIT = 1
          
 DECLARE @ErrorMessageÇode  INT
          
            
  IF EXISTS (SELECT TOP 1
		1
	FROM [ProjectSection] WITH (NOLOCK)
	WHERE ProjectId = @PprojectId
	AND IsLastLevel = 1
	AND IsLocked = 1
	AND LockedBy != @UserId)
BEGIN
SET @IsSuccess = 0
SET @ErrorMessageÇode = 1
SELECT
	@IsSuccess AS IsSuccess
   ,@ErrorMessageÇode AS ErrorCode
END
ELSE
BEGIN
IF EXISTS (SELECT TOP 1
			1
		FROM Project WITH (NOLOCK)
		WHERE ProjectId = @PprojectId)
BEGIN
UPDATE p
SET p.IsDeleted = 1
   ,p.ModifiedBy = @PuserID
   ,p.ModifiedDate = @PModifiedDate
   from  Project p WITH(NOLOCK)
WHERE p.ProjectId = @PprojectId
--AND (UserId = @PuserID OR ModifiedBy = @PUserID)       

SET @IsSuccess = 1
SET @ErrorMessageÇode = 0
SELECT
	@IsSuccess AS IsSuccess
   ,@ErrorMessageÇode AS ErrorCode
END
END
END

GO
