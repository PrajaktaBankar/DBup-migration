CREATE PROCEDURE [dbo].[usp_deleteProjectById]
    @ProjectId INT,   
	@CustomerId   INT,   
	@UserId INT,
	@UserName NVARCHAR(500)null=''
AS                   
BEGIN
      
    DECLARE @PProjectId INT = @ProjectId;
	DECLARE @PCustomerId   INT = @CustomerId;
	DECLARE @PUserId INT = @UserId;
	DECLARE @PUserName NVARCHAR(500) = @UserName;
	DECLARE @IsSuccess BIT = 1
            
	DECLARE @ErrorMessageÇode  INT;
	IF EXISTS (SELECT TOP 1
		1
	FROM [ProjectSection] WITH (NOLOCK)
	WHERE ProjectId = @PProjectId
	AND IsLastLevel = 1
	AND IsLocked = 1
	AND LockedBy != @UserId
	AND CustomerId = @CustomerId)
BEGIN
SET @IsSuccess = 0
SET @ErrorMessageÇode = 1
SELECT
	@IsSuccess AS IsSuccess
   ,@ErrorMessageÇode AS ErrorCode
END
ELSE
BEGIN
UPDATE p
SET p.IsDeleted = 1
   ,p.ModifiedBy = @PuserID
   ,p.ModifiedDate = GETUTCDATE()
   ,p.ModifiedByFullName = @PUserName
   from Project p WITH(NOLOCK)
WHERE p.ProjectId = @PProjectId
AND p.CustomerId = @PCustomerId

SET @IsSuccess = 1
SET @ErrorMessageÇode = 0
SELECT
	@IsSuccess AS IsSuccess
   ,@ErrorMessageÇode AS ErrorCode
END
END

GO
