CREATE PROCEDURE [dbo].[usp_LockUnLockUsersSectionForJob]   
@ProjectId INT NULL,   
@CustomerId INT NULL,  
@UserId INT NULL=NULL,   
@SectionId nvarchar(max)=NULL,  
@UserName VARCHAR (50) NULL=NULL   
AS  
BEGIN
  
  
 DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PUserId INT = @UserId;
DECLARE @PSectionId nvarchar(max) = @SectionId;
DECLARE @PUserName VARCHAR (50) = @UserName;

 DECLARE @IsLocked bit =0

-- check if target section is already locked  
SET @IsLocked = (SELECT
		COUNT(1) AS IsLocked
	FROM [projectSection] WITH (NOLOCK)
	WHERE SectionId IN (SELECT
			CAST(value AS INT)
		FROM STRING_SPLIT(@PSectionId, ','))
	AND ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND LockedBy <> @PUserId
	AND IsLocked = 1)
  
   
   
 IF(@IsLocked = 0)  
  BEGIN
-- Release lock if any section is locked earlier  
UPDATE PS
SET IsLocked = 0
   ,LockedBy = 0
   ,LockedByFullName = ''
    FROM ProjectSection PS WITH (NOLOCK)
WHERE ProjectId = @PProjectId
AND CustomerId = @PCustomerId
AND LockedBy = @PUserId
AND IsLocked = 1;

UPDATE PS
SET IsLocked = 1
   ,LockedBy = @PUserId
   ,LockedByFullName = @PUserName
    FROM ProjectSection PS WITH (NOLOCK)
WHERE ProjectId = @PProjectId
AND CustomerId = @PCustomerId
AND SectionId IN (SELECT
		CAST(value AS INT)
	FROM STRING_SPLIT(@PSectionId, ','))

SET @IsLocked = 0
  
  END

SELECT
	@IsLocked AS IsLocked

END

GO
