CREATE PROCEDURE [dbo].[usp_GetProjectDivisionAndSections]            
(                      
 @ProjectId INT NULL,                       
 @CustomerId INT NULL,                       
 @UserId INT NULL=NULL,                       
 @DisciplineId NVARCHAR (1024) NULL='',                       
 @CatalogueType NVARCHAR (1024) NULL='FS',                       
 @DivisionId NVARCHAR (1024) NULL='',                      
 @UserAccessDivisionId NVARCHAR (1024) = ''                          
)                      
AS                          
BEGIN                                    
  DECLARE @PprojectId INT = @ProjectId;                                    
  DECLARE @PcustomerId INT = @CustomerId;                                    
  DECLARE @PuserId INT = @UserId;                                    
  DECLARE @PDisciplineId NVARCHAR (1024) = @DisciplineId;                                    
  DECLARE @PCatalogueType NVARCHAR (1024) = @CatalogueType;                                   
  DECLARE @PDivisionId NVARCHAR (1024) = @DivisionId;                                    
  DECLARE @PUserAccessDivisionId NVARCHAR (1024) = @UserAccessDivisionId;     
  
  DECLARE @AlternateDocument INT = 8 ;              
  DECLARE @DocumentPath NVARCHAR(200) ='' ;                            
                                    
 --IMP: Apply master updates to project for some types of actions                                    
 EXEC usp_ApplyMasterUpdatesToProject @PprojectId, @PcustomerId;                                
                                
 --DECLARE Variables                                    
 DECLARE @MasterDataTypeId INT = 0;                                
 DECLARE @SourceTagFormat VARCHAR(18);                                
                                
 --Set data into variables                                        
 SELECT top 1 @MasterDataTypeId=MasterDataTypeId FROM Project WITH(NOLOCK) WHERE ProjectId = @PprojectId option(fast 1) --fast N                              
                              
SELECT TOP 1 @SourceTagFormat=PS.SourceTagFormat FROM ProjectSummary PS WITH(NOLOCK) WHERE PS.ProjectId = @PprojectId option(fast 1) --fast N                              
                               
 -- Fetch level 0 segments for status                                  
 DROP TABLE IF EXISTS #LevelZeroSegments                                  
 SELECT DISTINCT PSS.SectionId, PSS.SegmentStatusId, PSS.SegmentSource, PSS.SegmentOrigin, PSS.SegmentStatusTypeId                                
  INTO #LevelZeroSegments                                      
  FROM ProjectSegmentStatus PSS WITH (NOLOCK)                                      
  WHERE PSS.CustomerId = @PCustomerId                                
  AND PSS.ProjectId = @PProjectId                                 
  AND PSS.SequenceNumber = 0                                
  AND PSS.IndentLevel = 0                                
  AND PSS.ParentSegmentStatusId = 0                                
  AND ISNULL(PSS.IsDeleted,0) = 0;                              
                              
  -- Insert Project Sections into Temp table            
  DROP TABLE IF EXISTS #ProjectSectionTemp;                          
  SELECT                                
   PS.SectionId                              
  ,PS.mSectionId                              
  ,PS.ParentSectionId                             
  ,0 AS ParentDivisionId                             
  ,PS.ProjectId                              
  ,PS.CustomerId                              
  ,PS.TemplateId                              
  ,PS.DivisionId                              
  ,PS.DivisionCode                              
  ,PS.[Description]                              
  ,PS.LevelId                              
  ,PS.IsLastLevel                              
  ,PS.SourceTag                              
  ,PS.Author                              
  ,PS.CreatedBy                              
  ,PS.CreateDate                              
  ,PS.ModifiedBy                              
  ,PS.ModifiedDate                              
  ,PS.SectionCode                      
  ,PS.IsLocked                              
  ,PS.LockedBy                              
  ,PS.LockedByFullName                          
  ,PS.FormatTypeId                    
  ,ISNULL(PS.IsHidden,0) IsHidden         
  ,PS.SortOrder        
  ,0 AS SubFolderSortOrder       
  ,IsTrackChanges    
   ,PS.SectionSource    
   ,@DocumentPath As DocumentPath  
  INTO #ProjectSectionTemp                              
  FROM ProjectSection PS WITH(NOLOCK)                              
  WHERE PS.ProjectId = @PprojectId AND PS.CustomerId = @PcustomerId AND ISNULL(PS.IsDeleted,0) = 0                            
                      
  DELETE FROM #ProjectSectionTemp                      
  WHERE LevelId > 2 AND IsHidden = 1                   
                  
  DELETE FROM  #ProjectSectionTemp                 
  WHERE  IsHidden = 1  AND IsLastLevel= 1                
                
  --delete sections which parent folders are hidden              
  DELETE FROM #ProjectSectionTemp WHERE SectionId IN               
  (SELECT PS1.SectionId               
  FROM               
  #ProjectSectionTemp PS1 WITH (NOLOCK)              
  INNER JOIN #ProjectSectionTemp PS2 WITH (NOLOCK)              
  ON PS2.SectionId = PS1.ParentSectionId              
  AND PS2.ProjectId = PS1.ProjectId              
  INNER JOIN #ProjectSectionTemp PS3 WITH (NOLOCK)              
  ON PS3.SectionId = PS2.ParentSectionId              
  AND PS3.ProjectId = PS2.ProjectId              
  WHERE PS2.IsHidden = 1 OR PS3.IsHidden = 1              
  )              
            
 -- get sub folder sort order        
 UPDATE L3         
 SET SubFolderSortOrder = ISNULL(L2.SortOrder,0)    
 FROM #ProjectSectionTemp L3 WITH (NOLOCK)        
 INNER JOIN #ProjectSectionTemp L2  WITH (NOLOCK)        
 ON L2.SectionId = L3.ParentSectionId        
 AND L3.IsLastLevel = 1        
 AND L2.LevelId= 3        
                                
   update t               
   set ParentDivisionId = PS.ParentSectionId               
   from #ProjectSectionTemp t               
   JOIN ProjectSection PS WITH(NOLOCK) ON                             
   t.ParentSectionId = PS.SectionId                            
   where t.IsLastLevel = 1;  
   
   --Update Document Path which is AlterNate Document  
  UPDATE t SET t.DocumentPath = SD.DocumentPath  
   FROM #ProjectSectionTemp t  
   INNER JOIN SectionDocument SD WITH(NOLOCK)  
   ON SD.SectionId = t.SectionId  
   Where t.SectionSource = @AlternateDocument                           
                            
  -- Insert Deleted Master Sections into Temp table         
  DROP TABLE IF EXISTS #DeletedMasterSectionTemp;                          
                               
  SELECT MS.SectionId, MS.IsDeleted                              
  INTO #DeletedMasterSectionTemp                          
  FROM SLCMaster..Section MS WITH(NOLOCK) WHERE ISNULL(MS.IsDeleted, 0) = 1                              
                                   
 ;WITH SectionTableCTE as (SELECT DISTINCT                                    
   PS.SectionId AS SectionId                                    
  ,ISNULL(PS.mSectionId, 0) AS mSectionId                                    
  ,ISNULL(PS.ParentSectionId, 0) AS ParentSectionId                                    
  ,PS.ProjectId AS ProjectId                                    
  ,PS.CustomerId AS CustomerId                                    
  ,@PuserId AS UserId                                    
  ,ISNULL(PS.TemplateId, 0) AS TemplateId                                    
  ,ISNULL(PS.DivisionId, 0) AS DivisionId                               
  ,ISNULL(PS.ParentDivisionId, 0) AS ParentDivisionId                            
  ,ISNULL(PS.DivisionCode, '') AS DivisionCode                                    
  ,ISNULL(PS.Description, '') AS [Description]                              
  ,CAST(1 as bit) AS IsDisciplineEnabled                                    
  ,PS.LevelId AS LevelId                                    
  ,PS.IsLastLevel AS IsLastLevel                                    
  ,PS.SourceTag AS SourceTag                                    
  ,ISNULL(PS.Author, '') AS Author                                    
  ,ISNULL(PS.CreatedBy, 0) AS CreatedBy                                    
  ,ISNULL(PS.CreateDate, GETDATE()) AS CreateDate                             
  ,ISNULL(PS.ModifiedBy, 0) AS ModifiedBy                                    
  ,ISNULL(PS.ModifiedDate, GETDATE()) AS ModifiedDate                                    
  ,(CASE                                    
    WHEN PSS.SegmentStatusId IS NULL AND         
  PS.mSectionId IS NOT NULL THEN 'M'                                    
    WHEN PSS.SegmentStatusId IS NULL AND                                    
  PS.mSectionId IS NULL THEN 'U'                                    
    WHEN PSS.SegmentStatusId IS NOT NULL AND                                    
  PSS.SegmentSource = 'M' AND                                    
  PSS.SegmentOrigin = 'M' THEN 'M'                                    
    WHEN PSS.SegmentStatusId IS NOT NULL AND                                    
  PSS.SegmentSource = 'U' AND                                    
  PSS.SegmentOrigin = 'U' THEN 'U'           
    WHEN PSS.SegmentStatusId IS NOT NULL AND                                    
  PSS.SegmentSource = 'M' AND                                    
  PSS.SegmentOrigin = 'U' THEN 'M*'                                    
   END) AS SegmentOrigin                                    
  ,COALESCE(PSS.SegmentStatusTypeId, -1) AS SegmentStatusTypeId                                    
  ,ISNULL(PS.SectionCode, 0) AS SectionCode                                    
  ,ISNULL(PS.IsLocked, 0) AS IsLocked                                    
  ,ISNULL(PS.LockedBy, 0) AS LockedBy                                    
  ,ISNULL(PS.LockedByFullName, '') AS LockedByFullName                                    
  ,PS.FormatTypeId AS FormatTypeId                                    
  ,@SourceTagFormat AS SourceTagFormat                                        
  ,(CASE WHEN (MS.SectionId IS NOT NULL AND MS.IsDeleted = 1) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END) AS IsMasterDeleted                                
  ,(CASE                                    
    WHEN PS.IsLastLevel = 1 AND                          
  (PS.mSectionId IS NULL OR                                    
  PS.mSectionId = 0) THEN 1                                    
    ELSE 0                                    
   END) AS IsUserSection         
   ,SubFolderSortOrder      
   ,PS.SortOrder       
   ,IsTrackChanges  
   ,PS.SectionSource 
   ,PS.DocumentPath     
  FROM #ProjectSectionTemp PS WITH (NOLOCK)                                    
  LEFT JOIN #DeletedMasterSectionTemp MS WITH (NOLOCK)                                    
   ON PS.mSectionId = MS.SectionId                                    
  LEFT OUTER JOIN #LevelZeroSegments AS PSS WITH (NOLOCK) ON PS.SectionId = PSS.SectionId                              
 )                                
                                   
 SELECT * FROM SectionTableCTE ORDER BY Sortorder ASC, Author ASC                                
                                
END 