
CREATE PROCEDURE [dbo].[usp_GetProjectForImportSection](      
@PageSize INT = 25,        
 @PageNumber INT = 1,        
 @IsOfficeMaster BIT,        
 @TargetProjectId INT =0,        
 @CustomerId INT ,        
 @SearchName NVARCHAR(MAX) = NULL,        
 @UserId INT,        
 @IsSystemManager BIT = 0        
)        
AS        
BEGIN          
          
 DECLARE @PPageSize INT = @PageSize;          
 DECLARE @PPageNumber INT = @PageNumber;          
 DECLARE @PIsOfficeMaster BIT = @IsOfficeMaster;          
 DECLARE @PTargetProjectId INT = @TargetProjectId;          
 DECLARE @PCustomerId INT = @CustomerId;          
 DECLARE @PUserId INT = @UserId;          
 DECLARE @PSearchName NVARCHAR(MAX) = @SearchName;          
 DECLARE @PIsSystemManager BIT = @IsSystemManager;          
          
 -- Project Access Type constants          
 DECLARE @PublicProjectAccess TINYINT = 1, @PrivateProjectAccess TINYINT = 2, @HiddenProjectAccess TINYINT = 3;          
          
 DROP TABLE IF EXISTS #ProjectForImportSection;    
 DROP TABLE IF EXISTS #AccessibleProjectIds;
           
 DECLARE @MasterDataTypeId INT = 0;          
 SET @MasterDataTypeId = (SELECT TOP 1 P.MasterDataTypeId FROM Project P WITH (NOLOCK) WHERE P.ProjectId = @PTargetProjectId)          
                                        
 IF @PSearchName = ''          
 BEGIN          
  SET @PSearchName = NULL;          
 END          
          
 CREATE TABLE #ProjectForImportSection (          
  ProjectId INT 
    ,[Name] NVARCHAR(500)          
    ,IsOfficeMaster BIT          
    ,CustomerId INT          
    ,ModifiedDate DATETIME2          
    ,OpenSectionCount INT          
    ,IsMigrated BIT          
    ,HasMigrationError BIT          
 );          
          
 IF (@PIsSystemManager = 0)          
 BEGIN          
          
  CREATE TABLE #AccessibleProjectIds (          
   ProjectId INT   PRIMARY KEY
     ,ProjectAccessTypeId INT          
     ,IsProjectAccessible BIT          
     ,ProjectAccessTypeName NVARCHAR(100)          
     ,IsProjectOwner BIT          
  );          
                 
  -- Get all public,private and owned projects                                            
  INSERT INTO #AccessibleProjectIds (ProjectId, ProjectAccessTypeId, IsProjectAccessible, ProjectAccessTypeName, IsProjectOwner)                            
   SELECT                            
    PS.ProjectId            
   ,PS.ProjectAccessTypeId            
   ,IIF(PS.ProjectAccessTypeId = @PublicProjectAccess, 1, 0) AS IsProjectAccessible          
   ,'' AS ProjectAccessTypeName            
   ,IIF(ps.OwnerId = @PUserId, 1, 0)            
   FROM ProjectSummary PS WITH (NOLOCK)            
   WHERE PS.CustomerId = @PCustomerId            
   AND (PS.ProjectAccessTypeId IN (@PublicProjectAccess, @PrivateProjectAccess) OR PS.OwnerId = @PUserId);          
          
  -- Update all private Projects if they are accessible                                            
  UPDATE AP          
  SET AP.IsProjectAccessible = 1            
  FROM UserProjectAccessMapping UPAM WITH (NOLOCK)            
  INNER JOIN #AccessibleProjectIds AP                           
   /* BHAVINI-replace AP.ProjectId = AP.ProjectId with AP.ProjectId = UPAM.ProjectId */          
  ON AP.ProjectId = UPAM.ProjectId           
      AND AP.ProjectAccessTypeId = @PrivateProjectAccess          
      AND UPAM.CustomerId = @PCustomerId            
      AND UPAM.UserId = @PUserId          
      AND UPAM.IsActive = 1          
      AND AP.ProjectAccessTypeId = @PrivateProjectAccess;            
                            
  -- Get all accessible projects                                            
INSERT INTO #AccessibleProjectIds (ProjectId, ProjectAccessTypeId, IsProjectAccessible, ProjectAccessTypeName, IsProjectOwner)                            
   SELECT          
    PS.ProjectId            
   ,PS.ProjectAccessTypeId            
   ,1 AS IsProjectAccessible            
   ,'' AS ProjectAccessTypeName            
   ,IIF(ps.OwnerId = @PUserId, 1, 0) AS IsProjectOwner          
   FROM ProjectSummary PS WITH (NOLOCK)                          
   INNER JOIN UserProjectAccessMapping UPAM WITH (NOLOCK) ON UPAM.ProjectId = PS.ProjectId                            
   LEFT OUTER JOIN #AccessibleProjectIds AP ON AP.ProjectId = PS.ProjectId          
   WHERE PS.CustomerId = @PCustomerId AND UPAM.UserId = @PUserId AND PS.ProjectAccessTypeId = @HiddenProjectAccess          
   AND AP.Projectid IS NULL  AND (UPAM.IsActive = 1 OR PS.OwnerId = @PUserId)            
          
  -- Insert Projects into temp table          
  INSERT INTO #ProjectForImportSection          
  SELECT          
    P.ProjectId          
   ,LTRIM(RTRIM(P.[Name])) AS [Name]          
   ,P.IsOfficeMaster          
   ,P.CustomerId AS CustomerId          
   ,UF.LastAccessed AS ModifiedDate          
   ,0 AS OpenSectionCount          
   ,ISNULL(P.IsMigrated, 0) AS IsMigrated          
   ,CONVERT(BIT,0) AS HasMigrationError          
  FROM Project AS P WITH (NOLOCK)          
  INNER JOIN UserFolder UF WITH (NOLOCK)          
   ON UF.CustomerId = P.CustomerId AND UF.ProjectId = P.ProjectId  AND ISNULL(P.IsDeleted,0)=0          
  AND ISNULL(P.IsArchived,0)=0          
  AND ISNULL(P.IsPermanentDeleted, 0) = 0            
  INNER JOIN #AccessibleProjectIds AP ON AP.Projectid = P.ProjectId          
  WHERE P.CustomerId = @PCustomerId          
  AND P.IsOfficeMaster = @PIsOfficeMaster          
  AND P.MasterDataTypeId = @MasterDataTypeId          
  AND P.ProjectId != @PTargetProjectId          
  AND (@PSearchName IS NULL OR P.[Name] LIKE '%' + COALESCE(@PSearchName, P.[Name]) + '%');          
          
 END          
           
 IF (@PIsSystemManager = 1)          
 BEGIN          
          
  -- Insert Projects into temp table          
  INSERT INTO #ProjectForImportSection          
  SELECT          
    P.ProjectId          
   ,LTRIM(RTRIM(P.[Name])) AS [Name]          
   ,P.IsOfficeMaster          
   ,P.CustomerId AS CustomerId          
   ,UF.LastAccessed AS ModifiedDate          
   ,0 AS OpenSectionCount          
   ,ISNULL(P.IsMigrated, 0) AS IsMigrated          
   ,CONVERT(BIT,0) AS HasMigrationError          
  FROM Project AS P WITH (NOLOCK)          
  INNER JOIN UserFolder UF WITH (NOLOCK)          
   ON-- UF.CustomerId = P.CustomerId AND           
   UF.ProjectId = P.ProjectId          
  WHERE P.CustomerId = @PCustomerId          
  AND P.IsOfficeMaster = @PIsOfficeMaster          
  AND P.MasterDataTypeId = @MasterDataTypeId          
  AND ISNULL(P.IsDeleted,0)=0          
  AND ISNULL(P.IsArchived,0)=0          
  AND ISNULL(P.IsPermanentDeleted, 0) = 0           
  AND P.ProjectId != @PTargetProjectId          
  AND (@PSearchName IS NULL OR P.[Name] LIKE '%' + COALESCE(@PSearchName, P.[Name]) + '%');          
 
 END          
          
 UPDATE P          
 SET P.HasMigrationError = 1          
 FROM #ProjectForImportSection P          
 INNER JOIN ProjectMigrationException PME WITH (NOLOCK)          
 ON PME.ProjectId = P.ProjectId          
 WHERE ISNULL(P.IsMigrated, 0) = 1 AND ISNULL(IsResolved,0) = 0;          
SELECT P.ProjectId                          
    ,P.CustomerId                          
    ,P.[Name]                          
    ,P.IsOfficeMaster                          
    ,P.ModifiedDate          
    ,COUNT(PS.SectionId) AS OpenSectionCount                          
    ,P.IsMigrated          
    ,P.HasMigrationError 
	FROM ProjectSegmentStatus PSS 
	INNER JOIN ProjectSection PS ON PS.ProjectId = PSS.ProjectId AND PSS.SectionId = PS.SectionId          
              AND PSS.ProjectId = PS.ProjectId 
			  AND PSS.CustomerId = @CustomerId 
			  AND PSS.IndentLevel = 0 AND PSS.ParentSegmentStatusId = 0          
              AND PSS.SequenceNumber = 0 AND ISNULL(PSS.IsDeleted, 0) = 0 AND ISNULL(PS.IsDeleted, 0) = 0  AND ISNULL(PS.IsHidden,0) = 0        
			  AND PS.IsLastLevel = 1  AND ISNULL(PS.IsDeleted,0) = 0  
	INNER JOIN #ProjectForImportSection P ON PS.ProjectId = P.ProjectId  AND PS.CustomerId = P.CustomerId           
      
 GROUP BY P.ProjectId          
   ,P.CustomerId          
   ,P.[Name]           ,P.IsOfficeMaster          
   ,P.ModifiedDate          
   ,P.IsMigrated          
   ,P.HasMigrationError          
  HAVING COUNT(PS.SectionId) > 0          
  ORDER BY P.ModifiedDate DESC          
  OFFSET @PPageSize * (@PPageNumber - 1) ROWS                          
  FETCH NEXT @PPageSize ROWS ONLY;          
          
 DROP TABLE IF EXISTS #ProjectForImportSection;          
          
END  