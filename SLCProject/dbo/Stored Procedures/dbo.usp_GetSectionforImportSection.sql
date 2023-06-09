CREATE PROCEDURE usp_GetSectionforImportSection              
(                
 @ProjectId INT,                      
 @CustomerId INT                       
)                      
 AS                      
 BEGIN                    
                     
 DECLARE @PProjectId INT = @ProjectId;                
 DECLARE @PCustomerId INT = @CustomerId;                
                
 DROP TABLE IF EXISTS #SubDivision;                
 DROP TABLE IF EXISTS #TempOpenSection;                
                
 -- Select Project for import from project list                
 SELECT  DISTINCT                  
     PS.SectionId                  
    ,PS.ParentSectionId                  
    ,PS.mSectionId                  
    ,PS.ProjectId                  
    ,PS.CustomerId                  
    ,PS.UserId                  
    ,PS.DivisionId                  
    ,PS.DivisionCode                  
    ,PS.[Description]                  
    ,PS.LevelId                  
    ,PS.IsLastLevel                  
    ,PS.SourceTag                  
    ,PS.Author                  
    ,PS.TemplateId                  
    ,PS.SectionCode                  
    ,PS.IsDeleted                  
    ,PS.IsLocked                  
    ,PS.LockedBy                  
    ,PS.FormatTypeId                  
    ,PS.SpecViewModeId                
    ,(CASE WHEN PSS.SegmentStatusTypeId < 6 AND PSS.IsParentSegmentStatusActive = 1 THEN 1 ELSE 0 END) AS IsActive          
    ,PS.SortOrder      
    ,PS.SectionSource             
    ,0 AS SubFolderSortOrder            
    ,0 AS FolderSortOrder            
    ,0 AS FolderSectionId  
    ,sd.OriginalFileName ,  
     sd.DocumentPath          
 INTO #TempOpenSection                
 FROM ProjectSection PS WITH (NOLOCK)                
 INNER JOIN ProjectSegmentStatus PSS WITH (NOLOCK) ON PSS.SectionId = PS.SectionId                
              AND PSS.ProjectId = PS.ProjectId                
              AND PSS.CustomerId = @CustomerId                
              AND PSS.IndentLevel = 0                
              AND PSS.ParentSegmentStatusId = 0                
              AND PSS.SequenceNumber = 0                
              AND ISNULL(PSS.IsDeleted, 0) = 0                
              AND ISNULL(PS.IsDeleted, 0) = 0                
     AND ISNULL(PS.IsHidden,0) = 0      
  LEFT OUTER JOIN SectionDocument sd WITH(NOLOCK)  on sd.sectionId = PS.SectionId             
  WHERE PS.ProjectId = @PProjectId AND PS.CustomerId = @PCustomerId                
  ORDER BY PS.SourceTag;                
          
  --Update SubfolderSortOrder                  
 UPDATE section     
 SET section.FolderSectionId = subF.ParentSectionId ,     
     section.SubFolderSortOrder = ISNULL(subF.SortOrder,0)     
 FROM #TempOpenSection section            
  INNER JOIN ProjectSection subF WITH(NOLOCK)                
 ON section.ParentSectionId = subF.SectionId WHERE subF.ProjectId = @PProjectId AND subF.CustomerId = @PCustomerId;                 
                
 --Update Folder Sort Order                  
 UPDATE section     
 SET section.FolderSortOrder = ISNULL(folder.SortOrder,0)     
 FROM #TempOpenSection section     
  INNER JOIN ProjectSection folder WITH(NOLOCK)                
 ON section.FolderSectionId = folder.SectionId WHERE folder.ProjectId = @PProjectId AND folder.CustomerId = @PCustomerId;                
  
    -- Update master deleted sections as deleted        
 --UPDATE TOS        
 --SET TOS.IsDeleted = 1          
 --FROM #TempOpenSection TOS        
 --INNER JOIN SLCMaster..Section MS WITH (NOLOCK)        
 --ON MS.SectionId = TOS.mSectionId AND MS.IsDeleted = 1;        
       
 -- Select SubDivisions into #SubDivision                
 SELECT DISTINCT                  
     PS.SectionId                  
    ,PS.ParentSectionId                  
    ,PS.mSectionId                  
    ,PS.ProjectId                  
    ,PS.CustomerId                  
    ,PS.UserId                  
    ,PS.DivisionId                  
    ,PS.DivisionCode                  
    ,PS.[Description]                  
    ,PS.LevelId                  
    ,PS.IsLastLevel                  
    ,PS.SourceTag                  
    ,PS.Author                  
    ,PS.TemplateId                  
    ,PS.SectionCode                  
    ,PS.IsDeleted   
    ,PS.IsLocked                  
    ,PS.LockedBy                  
    ,PS.FormatTypeId                  
    ,PS.SpecViewModeId          
    ,PS.SortOrder AS SubFolderSortOrder        
    ,PS.SectionSource          
    ,0 AS FolderSortOrder                 
 INTO #SubDivision                  
 FROM ProjectSection PS WITH (NOLOCK)                  
 INNER JOIN #TempOpenSection PS3 ON PS.SectionId = PS3.ParentSectionId                  
 WHERE PS.ProjectId = @PProjectId           
 AND PS.IsLastLevel = 0                  
 AND PS.CustomerId = @PCustomerId                  
 AND ISNULL(PS.IsDeleted, 0) = 0                
 AND ISNULL(PS.IsHidden,0) = 0              
 ORDER BY PS.SourceTag;                
          
 UPDATE section SET section.FolderSortOrder = ISNULL(folder.SortOrder,0) FROM #SubDivision section INNER JOIN ProjectSection folder WITH(NOLOCK)                
 ON section.ParentSectionId = folder.SectionId WHERE folder.ProjectId = @PProjectId AND folder.CustomerId = @PCustomerId;         
            
 -- Select Divisions                
 SELECT DISTINCT                  
  PS.SectionId                  
    ,PS.ParentSectionId                  
    ,PS.mSectionId                  
    ,PS.ProjectId                  
    ,PS.CustomerId                  
    ,PS.UserId                  
    ,PS.DivisionId                  
    ,PS.DivisionCode                  
    ,PS.[Description]                  
    ,PS.LevelId                
    ,PS.IsLastLevel                
    ,PS.SourceTag                
    ,PS.Author                
    ,PS.TemplateId                  
    ,PS.SectionCode                  
    ,PS.IsDeleted                  
    ,PS.IsLocked                  
    ,PS.LockedBy                  
    ,PS.FormatTypeId                  
    ,PS.SpecViewModeId          
    ,PS.SortOrder     
    ,PS.SectionSource                 
 FROM ProjectSection PS WITH (NOLOCK)                  
 INNER JOIN #SubDivision PS2                  
  ON PS.SectionId = PS2.ParentSectionId                  
 WHERE PS.ProjectId = @PProjectId                  
 AND PS.IsLastLevel = 0                  
 AND PS.CustomerId = @PCustomerId                  
 AND ISNULL(PS.IsDeleted, 0) = 0                
 AND ISNULL(PS.IsHidden,0) = 0              
 ORDER BY PS.SortOrder;                
 -- Select Sub Division                
 SELECT * FROM #SubDivision ORDER BY SubFolderSortOrder, FolderSortOrder;                
                
 -- Select Open Leaf Sections                
 SELECT * FROM #TempOpenSection ORDER BY SortOrder, SubFolderSortOrder, FolderSortOrder;                
                
                
 DROP TABLE IF EXISTS #SubDivision;                
 DROP TABLE IF EXISTS #TempOpenSection;                
                
END 