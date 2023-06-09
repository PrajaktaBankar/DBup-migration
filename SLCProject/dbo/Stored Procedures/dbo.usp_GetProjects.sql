
CREATE PROCEDURE [dbo].[usp_GetProjects]                
  @CustomerId INT NULL                         
 ,@UserId INT NULL = NULL                         
 ,@ParticipantEmailId NVARCHAR(255) NULL = NULL                         
 ,@IsDesc BIT NULL = NULL                         
 ,@PageNo INT NULL = 1                         
 ,@PageSize INT NULL = 100                         
 ,@ColName NVARCHAR(255) NULL = NULL                         
 ,@SearchField NVARCHAR(255) NULL = NULL                         
 ,@DisciplineId NVARCHAR(MAX) NULL = ''                         
 ,@CatalogueType NVARCHAR(MAX) NULL = 'FS'                         
 ,@IsOfficeMasterTab BIT NULL = NULL                         
 ,@IsSystemManager BIT NULL = 0                           
AS                
BEGIN                
              
 DECLARE @allProjectCount AS INT = 0;                     
 DECLARE @deletedProjectCount AS INT = 0;                     
 DECLARE @archivedProjectCount AS INT=0;                    
 DECLARE @officeMasterCount AS INT = 0;                     
 DECLARE @deletedOfficeMasterCount AS INT = 0;                                       
 Declare @incomingProjectCount  AS INT=0;                   
 DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())                 
 DECLARE @OpenCommentStatusId INT = 1                 
              
 IF(@ColName='projectAccessTypeName')                    
  SET @IsDesc=iif(@IsDesc=0,1,0)                 
         
 --Create table for Column visibility Settings  
 CREATE TABLE #ProjectListColumnVisibilitySetting([name] nvarchar(100),[index] int,isShow bit)  
 
 INSERT INTO #ProjectListColumnVisibilitySetting  
 EXEC usp_GetColumnVisibilityPreferences @CustomerId,@UserId             
               
 --create table #accessibleProjectIds(RowId,projectId)                
  CREATE TABLE #accessibleProjectIds  (RowId INT,ProjectId INT,ProjectAccessTypeId INT,IsProjectAccessible bit,ProjectAccessTypeName NVARCHAR(100), IsProjectOwner BIT  )                
                
 --create table #filteredProjectIdList(RowId,projectId)                
 CREATE TABLE #filteredProjectIdList  (RowId INT, ProjectId INT ,CustomProjectId NVARCHAR(500),CustomProjectIdRaw Nvarchar(1000),ProjectNameRaw NVARCHAR(1000))                
                
 --exec getAccisibleProjects {customerId,UserId,SystemManager,OfficeMaster} --new Proc                
  EXEC usp_GetAccessibleProjects @CustomerId,@UserId,@IsOfficeMasterTab,@IsSystemManager              
              
 --exec GetfileterProjectIds {searchText} --new Proc customProjectId and name                
  EXEC usp_GetfilterProjects @SearchField,@ColName                
                
  CREATE TABLE #customProj(SortOrder INT,ProjectId INT,CustomProjectId NVARCHAR(500))              
                      
 
 --create table #projectList(sortOrder,.....)                
  CREATE TABLE #projectList  (               
      ProjectId INT                       
    ,[Name] NVARCHAR(255)                       
    ,[Description] NVARCHAR(255)                                                                
    ,IsOfficeMaster BIT                       
    ,TemplateId INT                       
    ,CustomerId INT                                             
    ,LastAccessed DATETIME2                       
    ,UserId INT                                                             
    ,CreateDate DATETIME2                       
    ,CreatedBy INT                       
    ,ModifiedBy INT                       
    ,ModifiedDate DATETIME2                       
    ,allProjectCount INT                                                        
    ,officeMasterCount INT                       
    ,deletedOfficeMasterCount INT                                       
    ,deletedProjectCount INT                       
    ,archivedProjectCount INT                                                          
    ,MasterDataTypeId INT                       
    ,SpecViewModeId INT                       
    ,LastAccessUserId INT                                                    
    ,IsDeleted BIT                       
    ,IsArchived BIT                                                          
    ,IsPermanentDeleted BIT                       
    ,UnitOfMeasureValueTypeId INT                       
    ,ModifiedByFullName NVARCHAR(100)                                                  
    ,ProjectAccessTypeId INT               
    ,IsProjectAccessible bit                      
    ,ProjectAccessTypeName NVARCHAR(100)                     
    ,IsProjectOwner BIT                  
    ,ProjectOwnerId INT                               
    ,CountryName NVARCHAR(255)                                                   
 ,IsMigrated BIT                                               
 ,HasMigrationError BIT DEFAULT 0                                            
 ,IsLocked BIT DEFAULT 0                             
 ,LockedBy NVARCHAR(500)                    
 ,LockedDate DateTIme2(7)                  
  ,CustomProjectId NVARCHAR(500)       
  ,IsLinkEngineEnabled BIT DEFAULT 0     
    )                      
        --exec getSortedProjectList{ sortBy,isAsc} --insert into #result table with sort order and page size --new Proc                
   EXEC usp_GetSortedProjectList @IsDesc,@ColName                          
              
  CREATE TABLE #tempTableForCount              
  (ProjectId INT ,IsDeleted BIT, IsArchived BIT,IsOfficeMaster BIT,CustomerId INT,IsIncomingProject BIT,              
  IsPermanentDeleted BIT,TransferredDate DATETIME ,UserId INT)              
              
  INSERT INTO #tempTableForCount              
  SELECT P.ProjectId ,              
         P.IsDeleted,               
      P.IsArchived,              
      P.IsOfficeMaster,              
      P.CustomerId,              
      P.IsIncomingProject,              
      P.IsPermanentDeleted,              
      P.TransferredDate,              
      P.UserId              
  FROM Project P WITH (NOLOCK) WHERE P.CustomerId = @CustomerId and ISNULL(P.IsOfficeMaster,0)=@IsOfficeMasterTab              
              
    SET @allProjectCount = COALESCE((SELECT                     
   COUNT(P.ProjectId)                     
    FROM #tempTableForCount AS P WITH (NOLOCK)                     
    inner JOIN #filteredProjectIdList t                     
    ON t.Projectid=p.ProjectId                   
    WHERE ISNULL(P.IsDeleted,0) = 0                                                             
    AND ISNULL(p.IsArchived,0)= 0                                    
    AND P.IsOfficeMaster = @IsOfficeMasterTab                                         
    AND P.customerId = @CustomerId                                           
    AND ISNULL( P.IsIncomingProject , 0)=0               
       And p.CustomerId = @CustomerId AND P.IsOfficeMaster = @IsOfficeMasterTab               
    AND IsNull(P.IsDeleted,0) = 0),0)              
                      
   SET @deletedProjectCount = COALESCE((SELECT                     
  COUNT(P.ProjectId)                     
    FROM #tempTableForCount AS P WITH (NOLOCK)                     
    --inner JOIN #accessibleProjectIds t                     
    --ON t.Projectid=p.ProjectId                     
    WHERE ISNULL(P.IsOfficeMaster, 0) = @IsOfficeMasterTab                     
    AND ISNULL(P.IsDeleted, 0) = 1                     
    AND P.customerId = @CustomerId                     
    AND ISNULL(P.IsPermanentDeleted, 0) = 0)                     
   , 0);                     
                     
   SET @archivedProjectCount = COALESCE((SELECT                     
  COUNT(P.ProjectId)                     
    FROM #tempTableForCount AS P WITH (NOLOCK)                     
    inner JOIN #accessibleProjectIds t                     
    ON t.Projectid=p.ProjectId                     
    WHERE ISNULL(P.IsOfficeMaster, 0) = @IsOfficeMasterTab                     
    AND ISNULL(P.IsArchived, 0) = 1                                                              
    and ISNULL(p.IsDeleted,0)=0                                                                    
    AND P.customerId = @CustomerId )                                                   
   , 0);                     
                                       
  SET @incomingProjectCount=COALESCE((SELECT COUNT(P.ProjectId)                                
  from #tempTableForCount p WITH (NOLOCK)                                         
  inner JOIN #accessibleProjectIds t                     
  ON t.Projectid=p.ProjectId                                        
  WHERE p.IsIncomingProject=1               
  AND  p.customerId = @CustomerId                                       
  AND ISNULL(p.IsOfficeMaster, 0) = @IsOfficeMasterTab                
  AND ISNULL(p.IsDeleted,0)=0                
  AND ISNULL(p.IsPermanentDeleted,0)=0                  
  AND P.TransferredDate > @DateBefore30Days                                    
  ),0);                                
                                                          
   SET @officeMasterCount = @allProjectCount;                     
   SET @deletedOfficeMasterCount = @deletedProjectCount;                
              
INSERT INTO #projectList              
    SELECT  DISTINCT                 
      p.ProjectId                                                         
      ,LTRIM(RTRIM(p.[Name])) AS [Name]                     
      ,p.[Description]                     
      ,p.IsOfficeMaster                     
      ,COALESCE(p.TemplateId, 1) TemplateId                     
      ,p.customerId                     
      ,UF.LastAccessed                     
      ,p.UserId                     
      ,p.CreateDate                     
      ,p.CreatedBy                     
      ,p.ModifiedBy                     
      ,p.ModifiedDate                     
      ,@allProjectCount AS allprojectcount                                                                   
      ,@officeMasterCount AS officemastercount                     
      ,@deletedOfficeMasterCount AS deletedOfficeMasterCount                     
      ,@deletedProjectCount AS deletedProjectCount                                                            
      ,@archivedProjectCount AS archiveProjectcount                                         
      ,p.MasterDataTypeId                     
      ,COALESCE(psm.SpecViewModeId, 0) AS SpecViewModeId                     
      ,COALESCE(UF.UserId, 0) AS lastaccessuserid                     
      ,p.IsDeleted                                                              
      ,p.IsArchived                                                                    
      ,COALESCE(p.IsPermanentDeleted, 0) AS IsPermanentDeleted                     
      ,psm.UnitOfMeasureValueTypeId                     
      ,COALESCE(UF.LastAccessByFullName, 'NA') AS ModifiedByFullName                                                          
      ,psm.projectAccessTypeId                     
      ,t.isProjectAccessible                     
      ,t.projectAccessTypeName                     
      ,iif(psm.OwnerId=@UserId,1,0) as IsProjectOwner                     
      ,COALESCE(psm.OwnerId,0) AS ProjectOwnerId                         
    ,'' AS CountryName                                                    
    ,P.IsMigrated                                              
    ,0 AS HasMigrationError                                                
    ,ISNULL(P.IsLocked,0) as IsLocked                                          
    ,P.LockedBy as LockedBy                                          
    ,P.LockedDate as LockedDate                       
    ,c.CustomProjectId            
 ,psm.IsLinkEngineEnabled    
    FROM dbo.Project AS p WITH (NOLOCK)               
    INNER JOIN [dbo].[ProjectSummary] psm WITH (NOLOCK)                                                                  
  ON psm.ProjectId = p.ProjectId                
  inner JOIN #accessibleProjectIds t                     
       ON t.Projectid=p.ProjectId                       
    inner join #customProj c                    
    on c.ProjectId=p.ProjectId                    
    LEFT JOIN UserFolder UF WITH (NOLOCK)                     
  ON UF.ProjectId = P.ProjectId                     
   AND UF.customerId = p.customerId                    
    WHERE ISNULL(P.IsDeleted,0) = 0                                                 
    AND ISNULL(p.IsArchived,0)= 0                                                               
    AND p.IsOfficeMaster = @IsOfficeMasterTab                     
    AND p.customerId = @CustomerId                    
    AND ISNULL( P.IsIncomingProject , 0)=0                 
              
 -- Update Project Access Type                                                                
   UPDATE t                     
   set t.ProjectAccessTypeName=pt.Name                     
   from #projectList t inner join LuProjectAccessType pt  WITH (NOLOCK)                                                    
   on t.ProjectAccessTypeId=pt.ProjectAccessTypeId                     
                        
  -- Update Country Name                      
   UPDATE t                                         
   set t.CountryName = lc.CountryName                      
   from #projectList t inner join ProjectAddress pa WITH(NOLOCK)                      
   on t.ProjectId = pa.ProjectId inner join LuCountry lc WITH(NOLOCK)                      
   on pa.CountryId = lc.CountryId;                                               
                                             
 UPDATE P                                              
 SET P.HasMigrationError = 1                                              
 FROM #projectList P                                              
 INNER JOIN ProjectMigrationException PME WITH (NOLOCK)                                              
  ON PME.ProjectId = P.ProjectId                                              
 WHERE ISNULL(P.IsMigrated, 0) = 1 AND ISNULL(IsResolved,0)=0                                                          
 DROP TABLE IF EXISTS #ProjectCommentCount                                        
                                   
  ;WITH CTE_SectionCommentCount(ProjectId, ProjectCommentCount)                                                
  AS                 
  (Select SC.ProjectId,Count(SC.SectionId) as ProjectCommentCount                                                 
 from #projectList pl with (nolock)                                                
 INNER JOIN ProjectSection PS with (nolock) ON pl.ProjectId = PS.ProjectId                                                
 INNER JOIN SegmentComment SC  with (nolock)                                                
 ON SC.SectionId = PS.SectionId AND SC.ProjectId = pl.ProjectId                                                
 where SC.CustomerId = @CustomerId                                                 
 AND ISNULL(SC.IsDeleted, 0) = 0                                           
 AND ISNULL(PS.IsDeleted, 0) = 0                              
 AND ps.IsLastLevel = 1                                                
 AND SC.CommentStatusId=@OpenCommentStatusId                                      
 AND SC.ParentCommentId=0                                       
 GROUP by SC.ProjectId,SC.CustomerId)                                       
                                      
 SELECT ProjectId, ProjectCommentCount INTO #ProjectCommentCount FROM CTE_SectionCommentCount                         

--Get Supplemental Documents count
DROP TABLE IF EXISTS #ProjectSuppDocumentCount
;WITH CTE_ProjectSuppDocumentCount(ProjectId, ProjectDocumentCount)
AS
(
	SELECT PS.ProjectId, COUNT(PS.SectionId) AS ProjectDocumentCount
	FROM #projectList pl WITH (NOLOCK)
	INNER JOIN DocLibraryMapping PS WITH (NOLOCK) ON pl.ProjectId = PS.ProjectId AND ISNULL(PS.IsDeleted, 0) = 0
	WHERE PS.CustomerId = @CustomerId AND ISNULL(PS.IsDeleted, 0) = 0
	GROUP by PS.ProjectId
)
SELECT ProjectId, ProjectDocumentCount INTO #ProjectSuppDocumentCount FROM CTE_ProjectSuppDocumentCount
 

 --Custom Project Id                     
                    
 IF(@ColName<>'customProjectId' AND exists(select Top 1 1 FROM #ProjectListColumnVisibilitySetting where [name]='customProjectId'))                  
 BEGIN                  
  ;WITH CTE_CustomProjectTable(CustomProjectId,ProjectId)                    
  AS                    
  (SELECT pgt.[value] AS CustomProjectId,pgt.ProjectId FROM #projectList pl                     
  INNER JOIN ProjectGlobalTerm pgt WITH(NOLOCK)                     
  ON pl.ProjectId=pgt.ProjectId and pl.CustomerId=pgt.CustomerId                    
  WHERE pgt.[Name]='Project Id' and isnull(pgt.IsDeleted,0)=0                 
  )                    
 -- Update CustomProjectId                    
 UPDATE t                    
 SET t.CustomProjectId=c.CustomProjectId                    
 FROM #projectList t INNER JOIN CTE_CustomProjectTable c WITH (NOLOCK)                    
 ON t.ProjectId=c.ProjectId                    
  END                  
            
Select                 
 pl.ProjectId                             
    ,pl.[Name]                                                                      
    ,pl.[Description]                                                                      
    ,IsOfficeMaster                                                                      
    ,pl.TemplateId                                                                      
    ,pl.customerId                                                                      
    ,LastAccessed                                                                      
    ,pl.UserId                             
    ,pl.CreateDate                                                                      
    ,pl.CreatedBy                                                                      
    ,pl.ModifiedBy                                                                      
    ,pl.ModifiedDate                                                                      
    ,allProjectCount                                                                      
    ,officemastercount                                           
    ,MasterDataTypeId                                         
    ,pl.SpecViewModeId                                                                      
    ,LastAccessUserId                                                                      
    ,pl.IsDeleted                                                        
    ,pl.IsArchived                                                                      
    ,pl.IsPermanentDeleted                                                                      
    ,ISNULL(pl.UnitOfMeasureValueTypeId, 0) AS UnitOfMeasureValueTypeId                   
    ,deletedOfficeMasterCount                                                                      
    ,deletedProjectCount                                                                      
    ,archivedProjectCount                                       
    ,0 SectionCount                              
    ,ModifiedByFullName                                                                      
    ,ProjectAccessTypeId                                                                      
    ,IsProjectAccessible                                                                      
    ,ProjectAccessTypeName                                                                     
    ,pl.IsProjectOwner                                                                      
    ,pl.ProjectOwnerId                       
 ,pl.CountryName                                                
 ,pl.IsMigrated                                              
 ,pl.HasMigrationError                                              
 ,pl.IsLocked                                          
 ,pl.LockedBy                                        
 ,pl.LockedDate                     
 ,pl.CustomProjectId                       
 ,FORMAT(pl.LockedDate,'yyyy-MM-ddTHH:mm:ss') as LockedDateStr                    
 ,0 ProjectCommentCount          
 ,CAST(NULL AS NVARCHAR(100)) AS AddDivision         
 ,CAST(NULL AS NVARCHAR(100)) AS AddSubDivision         
 ,pl.IsLinkEngineEnabled
 ,0 AS IsDocumentAttached
 into #x from #projectList pl                                                
 --LEFT JOIN #ProjectCommentCount PSC ON PSC.ProjectId = pl.ProjectId                                        
 --LEFT JOIN CTE_ActiveSection X ON pl.ProjectId = X.ProjectId                   
 inner join #customProj c                    
      on c.ProjectId=pl.ProjectId                 
   ORDER BY               
      CASE  WHEN @IsDesc = 1 THEN c.SortOrder END DESC                     
, CASE WHEN @IsDesc = 0 THEN c.SortOrder                    
     END OFFSET @PageSize * (@PageNo - 1) ROWS                                                    
     FETCH NEXT @PageSize ROWS ONLY;                   
          
-- Update Project Settings          
UPDATE tx SET AddDivision = PS.[Value] FROM #x tx INNER JOIN ProjectSetting PS WITH(NOLOCK)           
ON tx.ProjectId = PS.ProjectId AND PS.CustomerId = @CustomerId AND PS.[Name] = 'AddDivision';        
        
UPDATE tx SET AddSubDivision = PS.[Value] FROM #x tx INNER JOIN ProjectSetting PS WITH(NOLOCK)           
ON tx.ProjectId = PS.ProjectId AND PS.CustomerId = @CustomerId AND PS.[Name] = 'AddSubDivision';          
                                                           
--;WITH CTE_ActiveSection (ProjectId, TotalActiveSection)                                           
--  AS                                                
--  (Select PSS.ProjectId,Count(PSS.SectionId) as TotalActiveSections                                                 
--  from #x pl with (nolock)                                                
--  INNER JOIN ProjectSection PS with (nolock) ON pl.ProjectId = PS.ProjectId                          
--  INNER JOIN Projectsegmentstatus PSS with (nolock)                                                
--  ON PSS.SectionId = PS.SectionId AND PSS.ProjectId = pl.ProjectId                                                
--  where PSS.CustomerId = @CustomerId                                                 
--  AND ISNULL(PSS.ParentSegmentStatusId,0)=0                                                
--  AND PS.IsDeleted = 0                                                
--  AND ps.IsLastLevel = 1                                                
--  and PSS.SequenceNumber = 0 and (                                                 
--  PSS.SegmentStatusTypeId > 0                                        
--  AND PSS.SegmentStatusTypeId < 6                                                 
--  )                                                
--  GROUP by PSS.ProjectId,PSS.CustomerId)               
              
  Select                                                
     pl.ProjectId                                                                      
    ,pl.[Name]                                                                      
    ,pl.[Description]                                                                      
    ,IsOfficeMaster                                                                      
    ,pl.TemplateId                                                                      
    ,pl.customerId                                                                      
    ,LastAccessed                                                                      
    ,pl.UserId                               
    ,pl.CreateDate                                                                      
    ,pl.CreatedBy                                                                      
    ,pl.ModifiedBy                                                                      
    ,pl.ModifiedDate                                                                      
    ,allProjectCount                                                                      
    ,officemastercount                                           
    ,MasterDataTypeId                                                                  
    ,pl.SpecViewModeId                                                                      
    ,LastAccessUserId                                                                      
    ,pl.IsDeleted                                                        
    ,pl.IsArchived                                                                      
    ,pl.IsPermanentDeleted                    
    ,ISNULL(pl.UnitOfMeasureValueTypeId, 0) AS UnitOfMeasureValueTypeId                                                                      
    ,deletedOfficeMasterCount                                       
    ,deletedProjectCount                                                                      
    ,archivedProjectCount                                       
    ,0 AS SectionCount                              
    ,ModifiedByFullName                                                                      
    ,ProjectAccessTypeId                                                                      
    ,IsProjectAccessible                                                                      
    ,ProjectAccessTypeName                               
    ,pl.IsProjectOwner                                                                      
    ,pl.ProjectOwnerId                       
 ,pl.CountryName                                                
 ,pl.IsMigrated                                              
 ,pl.HasMigrationError                                              
 ,pl.IsLocked                                          
 ,pl.LockedBy                                        
 ,pl.LockedDate                     
 ,pl.CustomProjectId                       
 ,FORMAT(pl.LockedDate,'yyyy-MM-ddTHH:mm:ss') as LockedDateStr                    
 ,ISNULL(PSC.ProjectCommentCount,0) ProjectCommentCount          
 ,pl.AddDivision       
 ,pl.AddSubDivision          
 ,pl.IsLinkEngineEnabled
 ,CASE WHEN ISNULL(PDC.ProjectDocumentCount,0) > 0 THEN 'TRUE' ELSE 'FALSE' END AS IsDocumentAttached
 from #x pl                                               
 LEFT JOIN #ProjectCommentCount PSC ON PSC.ProjectId = pl.ProjectId                                        
 LEFT JOIN #ProjectSuppDocumentCount PDC ON PDC.ProjectId = pl.ProjectId                                        
 --LEFT JOIN CTE_ActiveSection X ON pl.ProjectId = X.ProjectId                   
 inner join #customProj c                    
      on c.ProjectId=pl.ProjectId                 
   ORDER BY               
      CASE  WHEN @IsDesc = 1 THEN c.SortOrder END DESC                     
     , CASE WHEN @IsDesc = 0 THEN c.SortOrder                    
     END             
  --OFFSET @PageSize * (@PageNo - 1) ROWS                                                    
     --FETCH NEXT @PageSize ROWS ONLY;                   
             
 /**New logic end*********/                                                
                                                           
 SELECT                     
  @archivedProjectCount AS ArchiveProjectCount                                                          
 ,@deletedProjectCount AS DeletedProjectCount                              
    ,@deletedOfficeMasterCount AS DeletedOfficeMasterCount                                                            
    ,@officeMasterCount AS OfficeMasterCount                     
    ,@allProjectCount AS TotalProjectCount                                      
    ,@incomingProjectCount AS IncomingProjectCount;           
          
   
        select * from #ProjectListColumnVisibilitySetting            
                 
END 
GO


