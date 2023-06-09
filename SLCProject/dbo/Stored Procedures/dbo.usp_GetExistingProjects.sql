CREATE PROCEDURE [dbo].[usp_GetExistingProjects]          
(              
  @CustomerId INT,-- = 8,              
  @UserId INT,-- = 92,              
  @ParticipantEmailId NVARCHAR(MAX),-- = 'ALL',              
  @IsDesc BIT,-- = 1,              
  @PageNo INT,-- = 1,              
  @PageSize INT,-- = 15,              
  @ColName NVARCHAR(MAX),-- = 'CreateDate',              
  @SearchField NVARCHAR(MAX),-- = 'ALL',              
  @IsOfficeMaster BIT = 0,        
  @IsSystemManager BIT=0        
)              
AS              
BEGIN        
            
  DECLARE @PCustomerId INT = @CustomerId;        
  DECLARE @PUserId INT = @UserId;        
  DECLARE @PParticipantEmailId NVARCHAR(MAX) = @ParticipantEmailId;        
  DECLARE @PIsDesc BIT = @IsDesc;        
  DECLARE @PPageNo INT = @PageNo;        
  DECLARE @PPageSize INT = @PageSize;        
  DECLARE @PColName NVARCHAR(MAX) = @ColName;        
  DECLARE @PSearchField NVARCHAR(MAX) = @SearchField;        
  DECLARE @PIsOfficeMaster BIT = @IsOfficeMaster;        
  DECLARE @PIsSystemManager BIT = @IsSystemManager;        
        
 IF @PSearchField = 'ALL'              
 BEGIN        
SET @PSearchField = '';        
 END        
        
 CREATE TABLE #accesibleProjectIdList (        
 ProjectId INT        
   ,[Name] NVARCHAR(MAX)        
   ,IsOfficeMaster BIT        
   ,MasterDataTypeId INT        
   ,LastAccessed DATETIME2        
   ,ProjectAccessTypeId INT        
   ,IsProjectAccessible BIT        
   ,IsProjectOwner BIT        
   ,ProjectAccessTypeName NVARCHAR(100)        
   ,ProjectOwnerId INT        
   ,IsMigrated BIT         
   ,HasMigrationError BIT DEFAULT 0          
)        
        
 if(@PIsSystemManager=0)        
 BEGIN        
 INSERT INTO #accesibleProjectIdList        
 SELECT        
  P.ProjectId        
    ,P.[Name]        
    ,P.IsOfficeMaster        
    ,ISNULL(P.MasterDataTypeId, 0) AS MasterDataTypeId        
    ,UF.LastAccessed --, COALESCE(UF.UserId, 0) AS LastAccessUserId          
    ,ProjectAccessTypeId        
    ,IIF(ProjectAccessTypeId = 1, 1, 0) AS IsProjectAccessible        
    ,IIF(OwnerId = @PUserId, 1, 0) AS IsProjectOwner        
    ,''        
    ,COALESCE(PS.OwnerId,0) AS ProjectOwnerId        
 ,P.IsMigrated          
   ,0 as HasMigrationError       
 FROM Project P WITH (NOLOCK)        
 LEFT JOIN ProjectSummary PS WITH (NOLOCK)        
  ON P.ProjectId = PS.ProjectId        
 INNER JOIN UserFolder UF WITH (NOLOCK)        
  ON UF.ProjectId = P.ProjectId        
 WHERE P.CustomerID = @PCustomerId        
 and ISNULL(p.IsDeleted,0)=0 AND ISNULL(P.IsArchived,0)=0  
        
 UPDATE ap        
 SET ap.IsProjectAccessible = 1        
 FROM UserProjectAccessMapping UM WITH (NOLOCK)      
 INNER JOIN #accesibleProjectIdList ap        
  ON ap.projectId = um.projectId        
 WHERE UM.IsActive = 1        
 AND UM.customerId = @PCustomerId        
 AND UserId = @PUserId        
END        
        
IF (@PIsSystemManager = 1)        
BEGIN        
        
 INSERT INTO #accesibleProjectIdList        
 SELECT        
  P.ProjectId        
    ,P.[Name]        
    ,P.IsOfficeMaster        
    ,ISNULL(P.MasterDataTypeId, 0) AS MasterDataTypeId        
    ,UF.LastAccessed        
    ,ProjectAccessTypeId        
    ,1 AS IsProjectAccessible        
    ,IIF(OwnerId = @PUserId, 1, 0) AS IsProjectOwner        
    ,''        
    ,COALESCE(PS.OwnerId,0) AS ProjectOwnerId           
 ,P.IsMigrated          
   ,0 as HasMigrationError       
 FROM Project P WITH (NOLOCK)        
 LEFT JOIN ProjectSummary PS WITH (NOLOCK)        
  ON P.ProjectId = PS.ProjectId        
 INNER JOIN UserFolder UF WITH (NOLOCK)        
  ON UF.ProjectId = P.ProjectId        
 WHERE P.CustomerID = @PCustomerId        
 and ISNULL(p.IsDeleted,0)=0 and ISNULL(P.IsArchived,0)=0  
        
END        
        
update t        
set t.ProjectAccessTypeName=l.Name        
from #accesibleProjectIdList t inner join LuProjectAccessType l WITH(NOLOCK)        
on l.ProjectAccessTypeId=t.ProjectAccessTypeId        
        
update #accesibleProjectIdList        
set IsProjectAccessible=IsProjectOwner        
where IsProjectOwner=1        
        
DECLARE  @allProjectCount INT = COALESCE((SELECT                
    COUNT(P.ProjectId)                
   FROM Project AS P WITH (NOLOCK)             
   inner JOIN #accesibleProjectIdList t                
   ON t.Projectid=p.ProjectId                
   WHERE P.IsDeleted = 0                
   AND P.IsOfficeMaster = @PIsOfficeMaster                
   AND P.customerId = @PCustomerId  
   AND (IsProjectAccessible=1 or ProjectAccessTypeId=2 or IsProjectOwner=1)              
   AND (@PSearchField IS NULL OR P.[Name] LIKE '%' + COALESCE(@PSearchField, P.[Name]) + '%')            
   )                
  , 0);          
        
  UPDATE P        
SET P.HasMigrationError = 1        
FROM #accesibleProjectIdList P        
INNER JOIN ProjectMigrationException PME WITH (NOLOCK)        
 ON PME.ProjectId = P.ProjectId        
WHERE ISNULL(P.IsMigrated, 0) = 1 AND ISNULL(IsResolved,0)=0    
      
SELECT *,@allProjectCount AS allProjectCount        
 FROM #accesibleProjectIdList         
WHERE IsOfficeMaster = @IsOfficeMaster         
and (IsProjectAccessible=1 or ProjectAccessTypeId=2 or IsProjectOwner=1)   
AND [Name] LIKE '%' + REPLACE(@PSearchField, '_', '[_]') + '%'        
ORDER BY CASE        
 WHEN @PIsDesc = 1 THEN CASE        
   WHEN LOWER(@PColName) = 'name' THEN [Name]        
  END        
END DESC,        
CASE        
 WHEN @PIsDesc = 1 THEN CASE        
   WHEN LOWER(@PColName) = 'createdate' THEN LastAccessed        
  END        
END DESC,        
CASE        
 WHEN @PIsDesc = 0 THEN CASE        
   WHEN LOWER(@PColName) = 'name' THEN [Name]        
  END        
END,        
CASE        
 WHEN @PIsDesc = 0 THEN CASE        
   WHEN LOWER(@PColName) = 'createdate' THEN LastAccessed        
  END        
END        
OFFSET @PPageSize * (@PPageNo - 1) ROWS        
FETCH NEXT @PPageSize ROWS ONLY;        
END 