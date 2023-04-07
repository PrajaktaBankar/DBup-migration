CREATE PROCEDURE [dbo].[usp_ArchiveProject]             
@UserId INT,            
@ProjectId INT,            
@CustomerId INT,            
@UserName nvarchar(500),          
@IsArchived BIT          
AS            
BEGIN      
            
DECLARE @PUserId INT = @UserId      
DECLARE @PProjectId INT = @ProjectId      
DECLARE @PCustomerId INT = @CustomerId      
DECLARE @PUserName nvarchar(500) =  @UserName      
DECLARE @PIsArchived BIT = @IsArchived      
DECLARE @IsSuccess BIT = 1    
DECLARE @ErrorMessageÇode  INT;    
      
 IF EXISTS (SELECT TOP 1    
  1    
 FROM [ProjectSection] WITH (NOLOCK)    
 WHERE ProjectId = @PProjectId    
 AND IsLastLevel = 1    
 AND IsLocked = 1    
 AND isnull(isdeleted,0)=0
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
    
UPDATE P      
SET P.IsArchived = @PIsArchived      
   ,P.ModifiedBy = @PUserId      
   ,P.ModifiedByFullName = @PUserName      
   ,P.ModifiedDate = GETUTCDATE()      
FROM Project P WITH (NOLOCK)      
WHERE P.ProjectId = @PProjectId      
AND P.CustomerId = @PCustomerId      
      
UPDATE UF      
SET UF.LastAccessed = GETUTCDATE(), UF.UserId = @UserId
   ,UF.LastAccessByFullName = @PUserName      
FROM UserFolder UF WITH (NOLOCK)      
WHERE UF.ProjectId = @PProjectId      
AND UF.CustomerId = @PCustomerId      
    
SET @IsSuccess = 1    
SET @ErrorMessageÇode = 0    
SELECT    
 @IsSuccess AS IsSuccess    
   ,@ErrorMessageÇode AS ErrorCode      
END   


SELECT UserTagId INTO #UserTagList  FROM  ProjectUserTag WITH (NOLOCK) WHERE customerid=@CustomerId and IsDeleted=1  
SELECT t.UserTagId INTO #usedTags FROM #userTagList t inner join ProjectSegmentUserTag  put WITH (NOLOCK) ON   
t.UserTagId=put.UserTagId WHERE customerId=@CustomerId  
UPDATE put  
SET put.isDeleted=0  
from #usedTags t inner join ProjectUserTag put WITH(NOLOCK) ON  
t.UserTagId=put.UserTagId  
WHERE put.CustomerId=@CustomerId  
END  
