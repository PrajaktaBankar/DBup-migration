CREATE PROCEDURE usp_GetIncomingTransferProjects (            
   @UserId INT,            
   @IsSystemManager BIT,            
   @CustomerId INT,            
   @IsOfficeMaster BIT            
)             
AS            
BEGIN             
            
 DECLARE @PCustomerId INT = @CustomerId;            
 DECLARE @PUserId INT = @UserId;            
 DECLARE @PIsOfficeMasterTab BIT = @IsOfficeMaster;            
 DECLARE @PIsSystemManager BIT = @IsSystemManager;            
 DECLARE @StatusCompleted INT =3          
 DROP TABLE IF EXISTS #IncomingProjectList;            
 DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())             
 CREATE TABLE #IncomingProjectList  (            
  ProjectId INT,            
  ProjectName NVARCHAR(255),            
  ProjectAccessTypeId INT,            
  IsProjectAccessible BIT,            
  ProjectAccessTypeName NVARCHAR(100)            
 );            
             
 IF(@PIsSystemManager = 1)             
 BEGIN            
  INSERT INTO #IncomingProjectList            
  SELECT            
     P.ProjectId,            
     P.[Name] AS ProjectName,            
     PS.ProjectAccessTypeId,            
     1 as IsProjectAccessible,            
     '' as ProjectAccessTypeName            
  FROM Project AS P WITH (NOLOCK)            
     INNER JOIN [dbo].[ProjectSummary] PS WITH (NOLOCK) ON PS.ProjectId = P.ProjectId            
     LEFT JOIN UserFolder UF WITH (NOLOCK) ON UF.ProjectId = P.ProjectId            
     AND UF.customerId = P.CustomerId            
  WHERE ISNULL(p.IsDeleted, 0) = 0      
     AND ISNULL(p.IsPermanentDeleted, 0) = 0         
     AND ISNULL(p.IsArchived, 0) = 0            
     AND P.IsOfficeMaster = @PIsOfficeMasterTab            
     AND P.CustomerId = @PCustomerId            
     AND ISNULL(P.IsIncomingProject, 0) = 1      
  AND P.TransferredDate > @DateBefore30Days;     
 END            
 ELSE             
 BEGIN             
  DROP TABLE IF EXISTS #AccessibleProjectIds;            
            
  CREATE TABLE #AccessibleProjectIds(            
   ProjectId INT,            
   ProjectAccessTypeId INT,            
   IsProjectAccessible bit,            
   ProjectAccessTypeName NVARCHAR(100),            
   IsProjectOwner BIT            
  );            
              
  ---Get all public,private and owned projects            
  INSERT INTO #AccessibleProjectIds(ProjectId,ProjectAccessTypeId,IsProjectAccessible,ProjectAccessTypeName,IsProjectOwner)            
  SELECT PS.ProjectId, PS.ProjectAccessTypeId, 0, '', IIF(PS.OwnerId = @PUserId, 1, 0)            
  FROM ProjectSummary PS WITH(NOLOCK)            
  WHERE (PS.ProjectAccessTypeId IN(1, 2) OR PS.OwnerId = @PUserId)AND ps.CustomerId = @PCustomerId;            
                 
  -- Update all public Projects as accessible            
  UPDATE AP            
  SET AP.IsProjectAccessible = 1            
  FROM #AccessibleProjectIds AP            
  WHERE AP.ProjectAccessTypeId = 1;            
              
  -- Update all private Projects if they are accessible            
  UPDATE AP            
  SET AP.IsProjectAccessible = 1            
  FROM #AccessibleProjectIds AP            
  INNER JOIN UserProjectAccessMapping UPAM  WITH(NOLOCK) ON AP.ProjectId = UPAM.ProjectId            
  WHERE UPAM.IsActive = 1            
     AND UPAM.UserId = @PUserId            
     AND AP.ProjectAccessTypeId = 2            
     AND UPAM.CustomerId = @PCustomerId;            
                 
  --Get all accessible projects            
  INSERT INTO #AccessibleProjectIds (ProjectId,ProjectAccessTypeId,IsProjectAccessible,ProjectAccessTypeName,IsProjectOwner)            
  SELECT PS.ProjectId, PS.ProjectAccessTypeId, 1, '', IIF(PS.OwnerId = @PUserId, 1, 0)            
  FROM ProjectSummary PS WITH(NOLOCK)            
     INNER JOIN UserProjectAccessMapping UPAM WITH(NOLOCK) ON UPAM.ProjectId = PS.ProjectId            
     LEFT OUTER JOIN #AccessibleProjectIds AP            
     ON AP.ProjectId = ps.ProjectId            
  WHERE PS.ProjectAccessTypeId = 3            
AND UPAM.UserId = @PUserId            
     AND AP.ProjectId IS NULL            
     AND PS.CustomerId = @PCustomerId            
     AND(UPAM.IsActive = 1 OR PS.OwnerId = @PUserId);            
            
  UPDATE AP            
  SET AP.IsProjectAccessible = AP.IsProjectOwner            
  FROM #AccessibleProjectIds AP            
  WHERE AP.IsProjectOwner = 1;            
            
  INSERT INTO #IncomingProjectList            
  SELECT            
     P.ProjectId,            
     P.[Name] AS ProjectName,            
     PS.ProjectAccessTypeId,            
     AP.IsProjectAccessible,            
     AP.ProjectAccessTypeName            
  FROM Project P WITH (NOLOCK)            
     INNER JOIN [dbo].[ProjectSummary] PS WITH (NOLOCK) ON PS.ProjectId = P.ProjectId            
     INNER JOIN #AccessibleProjectIds AP ON AP.ProjectId = P.ProjectId            
     LEFT JOIN UserFolder UF WITH (NOLOCK) ON UF.ProjectId = P.ProjectId AND UF.CustomerId = P.CustomerId            
  WHERE ISNULL(p.IsDeleted, 0) = 0      
     AND ISNULL(p.IsPermanentDeleted, 0) = 0           
     AND ISNULL(P.IsArchived, 0) = 0            
     AND P.IsOfficeMaster = @PIsOfficeMasterTab            
     AND P.CustomerId = @PCustomerId            
     AND ISNULL(P.IsIncomingProject, 0) = 1    
  AND P.TransferredDate > @DateBefore30Days;         
 END            
            
 UPDATE IPL            
 SET IPL.ProjectAccessTypeName = PT.[Name]            
 FROM #IncomingProjectList IPL WITH (NOLOCK)            
 INNER JOIN LuProjectAccessType PT WITH (NOLOCK) ON IPL.ProjectAccessTypeId = PT.ProjectAccessTypeId;            
          
 SELECT   DISTINCT          
 IPL.ProjectId,             
 IPL.ProjectName,             
 IPL.ProjectAccessTypeId,             
 IPL.IsProjectAccessible,             
 IPL.ProjectAccessTypeName AS ProjectType            
 FROM #IncomingProjectList IPL           
    
END             
            
-- EXEC sp_helptext usp_GetIncomingTransferProjects_new 82, 1, 24, 0 