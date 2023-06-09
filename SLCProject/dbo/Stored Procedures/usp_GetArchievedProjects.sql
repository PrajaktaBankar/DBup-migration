CREATE PROCEDURE [dbo].[usp_GetArchievedProjects]                  
 @CustomerId INT NULL              
 ,@UserId INT = NULL              
 ,@IsOfficeMaster BIT  = NULL              
 ,@IsSystemManager BIT NULL = 0      
 ,@SearchField NVARCHAR(255)  = NULL                 
AS              
BEGIN      
            
 DECLARE @PCustomerId INT = @CustomerId;      
 DECLARE @PUserId INT = @UserId;      
 DECLARE @PIsOfficeMaster BIT = @IsOfficeMaster;      
 DECLARE @PIsSystemManager BIT = @IsSystemManager;      
 DECLARE @PSearchField NVARCHAR(255) = @SearchField;    
          
 SET @PsearchField = REPLACE(@PSearchField, '_', '[_]')                  
 DECLARE @isnumeric AS INT = ISNUMERIC(@PSearchField);                  
 IF @PSearchField = ''                  
 SET @PSearchField = NULL;        
    
    
 CREATE TABLE #projectList  (              
   ProjectId INT              
    ,[Name] NVARCHAR(255)              
    ,ModifiedBy INT              
    ,ModifiedDate DATETIME2              
    ,ModifiedByFullName NVARCHAR(200)              
    ,ProjectAccessTypeId INT            
    ,IsProjectAccessible bit             
    ,ProjectAccessTypeName NVARCHAR(100)            
    )      
              
            
 IF(@PIsSystemManager=1)            
 BEGIN      
INSERT INTO #projectList      
 SELECT      
  p.ProjectId      
    ,LTRIM(RTRIM(p.[Name])) AS [Name]      
    ,p.ModifiedBy      
    ,p.ModifiedDate      
    ,UF.LastAccessByFullName    as ModifiedByFullName  
    ,psm.projectAccessTypeId      
    ,1 AS isProjectAccessible      
    ,'' AS projectAccessTypeName      
 FROM Project AS p WITH (NOLOCK)      
 INNER JOIN [ProjectSummary] psm WITH (NOLOCK)      
  ON psm.ProjectId = p.ProjectId      
 LEFT JOIN UserFolder UF WITH (NOLOCK)                  
  ON UF.ProjectId = P.ProjectId        
 WHERE p.IsArchived = 1      
 AND ISNULL(P.IsDeleted, 0) = 0      
 AND p.IsOfficeMaster = @PIsOfficeMaster      
 AND p.customerId = @PCustomerId      
 AND   (@PSearchField IS NULL OR p.[Name] LIKE '%' + COALESCE(@PSearchField, p.[Name]) + '%') 
  order by ModifiedDate desc  

END      
ELSE      
BEGIN      
CREATE TABLE #AccessibleProjectIds (      
 Projectid INT      
   ,ProjectAccessTypeId INT      
   ,IsProjectAccessible BIT      
   ,ProjectAccessTypeName NVARCHAR(100)      
   ,IsProjectOwner BIT      
);      
      
---Get all public,private and owned projects            
INSERT INTO #AccessibleProjectIds      
 SELECT      
  ps.Projectid      
    ,ps.ProjectAccessTypeId      
    ,0      
    ,''      
    ,IIF(ps.OwnerId = @PUserId, 1, 0)      
 FROM ProjectSummary ps WITH (NOLOCK)      
 WHERE (ps.ProjectAccessTypeId IN (1, 2)      
 OR ps.OwnerId = @PUserId)      
 AND ps.CustomerId = @PCustomerId      
      
--Update all public Projects as accessible            
UPDATE t      
SET t.IsProjectAccessible = 1      
FROM #AccessibleProjectIds t   
WHERE t.ProjectAccessTypeId = 1      
      
--Update all private Projects if they are accessible            
UPDATE t      
SET t.IsProjectAccessible = 1      
FROM #AccessibleProjectIds t       
INNER JOIN UserProjectAccessMapping u WITH (NOLOCK)      
 ON t.Projectid = u.ProjectId      
WHERE u.UserId = @PUserId      
AND u.IsActive = 1      
AND t.ProjectAccessTypeId = 2      
AND u.CustomerId = @PCustomerId      
      
--Get all accessible projects            
INSERT INTO #AccessibleProjectIds      
 SELECT      
  ps.Projectid      
    ,ps.ProjectAccessTypeId      
    ,1      
    ,''      
    ,IIF(ps.OwnerId = @PUserId, 1, 0)      
 FROM ProjectSummary ps WITH (NOLOCK)      
 INNER JOIN UserProjectAccessMapping upam WITH (NOLOCK)      
  ON upam.ProjectId = ps.ProjectId      
   AND upam.CustomerId = ps.CustomerId      
 LEFT OUTER JOIN #AccessibleProjectIds t      
  ON t.Projectid = ps.ProjectId      
 WHERE ps.ProjectAccessTypeId = 3      
 AND upam.UserId = @PUserId      
 AND t.Projectid IS NULL      
 AND ps.CustomerId = @PCustomerId      
 AND (upam.IsActive = 1      
 OR ps.OwnerId = @PUserId)      
      
      
UPDATE t      
SET t.IsProjectAccessible = t.IsProjectOwner      
FROM #AccessibleProjectIds t      
WHERE t.IsProjectOwner = 1      
      
INSERT INTO #projectList      
 SELECT      
  p.ProjectId      
    ,LTRIM(RTRIM(p.[Name])) AS [Name]      
    ,p.ModifiedBy      
    ,p.ModifiedDate      
    ,p.ModifiedByFullName as ModifiedByFullName   
    ,psm.projectAccessTypeId      
    ,t.isProjectAccessible      
    ,t.projectAccessTypeName      
 FROM Project AS p WITH (NOLOCK)      
 INNER JOIN [ProjectSummary] psm WITH (NOLOCK)      
  ON psm.ProjectId = p.ProjectId      
 INNER JOIN #AccessibleProjectIds t      
  ON t.Projectid = p.ProjectId      
   LEFT JOIN UserFolder UF WITH (NOLOCK)                  
  ON UF.ProjectId = P.ProjectId   
 WHERE p.IsArchived = 1      
 AND ISNULL(P.IsDeleted, 0) = 0      
 AND p.IsOfficeMaster = @PIsOfficeMaster      
 AND p.customerId = @PCustomerId      
 AND (@PSearchField IS NULL OR p.[Name] LIKE '%' + COALESCE(@PSearchField, p.[Name]) + '%')     
END      
      

UPDATE t      
SET t.ProjectAccessTypeName = pt.Name      
FROM #projectList t      
INNER JOIN LuProjectAccessType pt WITH (NOLOCK)          
 ON t.ProjectAccessTypeId = pt.ProjectAccessTypeId;      
      
SELECT      
 ProjectId AS ProjectID      
   ,[Name] AS ProjectName      
   ,ModifiedBy       
   ,ModifiedDate      
   ,ModifiedByFullName     
   ,ProjectAccessTypeId      
   ,IsProjectAccessible      
   ,ProjectAccessTypeName      
FROM #projectList pl      
order by ModifiedDate desc  
END      
GO