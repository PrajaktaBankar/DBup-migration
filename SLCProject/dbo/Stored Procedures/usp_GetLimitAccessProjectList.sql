CREATE PROCEDURE [dbo].[usp_GetLimitAccessProjectList]          
(          
 @UserId INT,          
 @LoggedUserId INT,          
 @CustomerId INT,          
 @IsSystemManager BIT,          
 @SearchText NVARCHAR(100)          
)          
AS          
BEGIN          
 DECLARE @PsearchField NVARCHAR(100) = REPLACE(@SearchText, '_', '[_]')         
 SET @PsearchField = REPLACE(@PSearchField, '%', '[%]')            
        
 IF(@IsSystemManager=1)          
 BEGIN          
  SELECT distinct P.Name,          
  PS.ProjectAccessTypeId,          
  P.ProjectId,          
  CAST(IIF(UPAM.ProjectId IS NOT NULL AND UPAM.IsActive=1 ,1,0) as BIT) AS IsSelected,          
  CAST(IIF(PS.OwnerId=@UserId,1,0) AS BIT) as IsProjectOwner          
  ,P.IsMigrated         
  ,CONVERT( bit,0) AS HasMigrationError       
  INTO #LimitAccessProjectListSM      
  FROM Project P WITH(NOLOCK)           
  INNER JOIN ProjectSummary PS WITH(NOLOCK)          
  ON P.ProjectId=PS.ProjectId           
  LEFT OUTER JOIN UserProjectAccessMapping UPAM WITH(NOLOCK)          
  ON UPAM.ProjectId=P.ProjectId          
  AND UPAM.UserId=@UserId AND P.CustomerId=UPAM.CustomerId          
  WHERE ISNULL(P.IsDeleted,0)=0 AND ISNULL(P.IsArchived,0)=0 
  AND P.CustomerId=@CustomerId           
  AND (ISNULL(PS.ProjectAccessTypeId,1)!=1)          
  AND (@PSearchField IS NULL OR P.[Name] LIKE '%' + COALESCE(@PSearchField, P.[Name]) + '%')          
      
 UPDATE P          
 SET P.HasMigrationError = 1          
 FROM #LimitAccessProjectListSM P          
 INNER JOIN ProjectMigrationException PME WITH (NOLOCK)          
 ON PME.ProjectId = P.ProjectId          
 WHERE ISNULL(P.IsMigrated, 0) = 1 AND ISNULL(IsResolved,0)=0    
 SELECT * FROM #LimitAccessProjectListSM     
 END          
 ELSE          
 BEGIN          
  SELECT distinct P.Name,PS.ProjectAccessTypeId,P.ProjectId,          
  CAST(IIF(UPAM.ProjectId IS NOT NULL and UPAM.IsActive=1 ,1,0) AS BIT) AS IsSelected,          
  CAST(IIF(PS.OwnerId=@UserId,1,0) AS BIT) as IsProjectOwner          
  ,P.IsMigrated         
  ,CONVERT( bit,0) AS HasMigrationError       
  INTO #LimitAccessProjectList      
  FROM Project P WITH(NOLOCK)           
  INNER JOIN ProjectSummary PS WITH(NOLOCK)          
  ON P.ProjectId=PS.ProjectId          
  LEFT OUTER JOIN UserProjectAccessMapping UPAM WITH(NOLOCK)          
  ON UPAM.ProjectId=P.ProjectId           
  AND UPAM.UserId=@UserId AND P.CustomerId=UPAM.CustomerId          
  WHERE ISNULL(P.IsDeleted,0)=0 AND ISNULL(P.IsArchived,0)=0 AND PS.OwnerId=@LoggedUserId    
  AND P.CustomerId=@CustomerId           
  AND (ISNULL(PS.ProjectAccessTypeId,1)!=1)          
  AND (@PSearchField IS NULL OR P.[Name] LIKE '%' + COALESCE(@PSearchField, P.[Name]) + '%')          
      
  UPDATE P          
 SET P.HasMigrationError = 1          
 FROM #LimitAccessProjectList P          
 INNER JOIN ProjectMigrationException PME WITH (NOLOCK)          
 ON PME.ProjectId = P.ProjectId          
 WHERE ISNULL(P.IsMigrated, 0) = 1   AND ISNULL(IsResolved,0)=0    
 SELECT * FROM #LimitAccessProjectList      
 END          
END 