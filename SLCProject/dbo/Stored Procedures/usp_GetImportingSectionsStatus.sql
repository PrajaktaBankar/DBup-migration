CREATE PROCEDURE usp_GetImportingSectionsStatus          
(        
  @CustomerId INT         
 ,@SourceProjectId INT        
 ,@TargetProjectId INT        
 ,@SectionIdString  NVARCHAR(MAX)        
)        
AS          
BEGIN                      
DECLARE @PCustomerId INT = @CustomerId;                                 
DECLARE @PSourceProjectId INT = @SourceProjectId ;                              
DECLARE @PTargetProjectId INT = @TargetProjectId;                                  
DECLARE @PSectionIdString  NVARCHAR(MAX) = @SectionIdString ;            
                     
DECLARE @SectionIdTbl TABLE(SectionId INT);                       
DROP TABLE IF EXISTS #ImportingSectionStatus                       
CREATE TABLE #ImportingSectionStatus                      
(                      
   SourceProjectId int                      
  ,CustomerId int                      
  ,SourceSectionId int                    
  ,mSectionId INT                    
  ,SourceParentSectionId int                      
  ,IsSectionInUserFolder bit                      
  ,IsSectionInUserDivision bit    
  ,SourceTag varchar(18)                 
  ,SubFolderSourceTag varchar(18)                      
  ,SubFolderDescription nvarchar(500)                      
  ,DivisionSourceTag varchar(18)                      
  ,DivisionDescription nvarchar(500)                      
  ,IsIdenticalFolderExistInTargetProject bit default 0                      
  ,TargetParentSectionId int default 0                      
  ,IsTargetSectionIsHidden BIT DEFAULT 0                  
  ,IsTargetSectionFolderIsHidden BIT DEFAULT 0                  
)                      
                      
INSERT INTO @SectionIdTbl                            
 SELECT                            
  id                            
 FROM dbo.udf_GetSplittedIds(@PSectionIdString, ',')                        
                      
--select source PS list                    
DROP TABLE IF EXISTS #SourcePS_List;                    
SELECT PS.ProjectId,PS.CustomerId,ISNULL(PS.mSectionId, 0) AS mSectionId ,                     
PS.SectionId,PS.ParentSectionId,PS.SourceTag,PS.Description                    
INTO #SourcePS_List                    
FROM ProjectSection PS WITH (NOLOCK)                    
WHERE PS.CustomerId = @PCustomerId                    
AND PS.ProjectId = @PSourceProjectId  
AND ISNULL(PS.IsDeleted,0) =0                  
                      
 --Select sections which are under user folder                      
 INSERT INTO #ImportingSectionStatus ( SourceProjectId , CustomerId, SourceSectionId,mSectionId,SourceParentSectionId,                      
 IsSectionInUserFolder,IsSectionInUserDivision,SourceTag,SubFolderSourceTag,SubFolderDescription,DivisionSourceTag,DivisionDescription                      
 )                      
 SELECT                       
  PS.ProjectId                      
  ,PS.CustomerId                      
  ,PS.SectionId                      
  ,PS.mSectionId                    
 ,PS.ParentSectionId                      
 ,CASE WHEN ISNULL(PS1.mSectionId,0) = 0 THEN 1 ELSE 0 END AS IsSectionInUserFolder                      
 ,CASE WHEN ISNULL(PS2.mSectionId,0) = 0 THEN 1 ELSE 0 END AS IsSectionInUserDivision   
 ,PS.SourceTag                     
 ,PS1.SourceTag AS SubSourceTag                      
 ,PS1.Description AS SubFolderName                      
 ,PS2.SourceTag AS DiviSourceTag                      
 ,PS2.Description AS DivisionName                      
 FROM #SourcePS_List PS WITH (NOLOCK)                      
 INNER JOIN @SectionIdTbl ST                      
 ON PS.SectionId = ST.SectionId                      
 AND PS.ProjectId = @PSourceProjectId                      
 AND PS.CustomerId = @PCustomerId                      
 INNER JOIN #SourcePS_List PS1 WITH (NOLOCK)                      
 ON PS1.SectionId = PS.ParentSectionId                      
 AND PS1.ProjectId = PS.ProjectId     
 AND PS1.CustomerId = PS.CustomerId                      
 INNER JOIN #SourcePS_List PS2 WITH (NOLOCK)                      
 ON PS2.SectionId = PS1.ParentSectionId                      
 AND PS2.CustomerId = ps1.CustomerId                      
 AND PS2.ProjectId =ps1.ProjectId                      
                      
                      
 --SELECT * FROM #ImportingSectionStatus;                      
                  
 --get target section list   
 DROP TABLE IF EXISTS #TargetSectionsList            
 SELECT PS.ProjectId,PS.CustomerId,PS.SectionId,PS.ParentSectionId,PS.SourceTag,ISNULL(PS.IsHidden,0) AS IsHidden ,PS.IsLastLevel                  
 INTO #TargetSectionsList                  
 FROM ProjectSection PS WITH (NOLOCK)                  
 WHERE PS.CustomerId = @PCustomerId AND PS.ProjectId = @PTargetProjectId                  
 AND ISNULL(PS.IsDeleted,0) = 0                  
          
 -- Check same folder is exist in target project                      
 UPDATE SPS                      
 SET IsIdenticalFolderExistInTargetProject = 1                      
 , TargetParentSectionId = PS.SectionId                      
 , IsTargetSectionIsHidden = ISNULL(PS.IsHidden,0)                  
 , IsTargetSectionFolderIsHidden = ( CASE WHEN PS.IsHidden = 1 OR PS1.IsHidden = 1 OR PS2.IsHidden = 1 THEN 1 ELSE 0 END)                  
 FROM #ImportingSectionStatus SPS WITH (NOLOCK)                      
 LEFT OUTER JOIN #TargetSectionsList PS WITH (NOLOCK)                      
 ON PS.ProjectId = @PTargetProjectId                      
 AND PS.CustomerId = @PCustomerId                      
 AND PS.SourceTag = SPS.SubFolderSourceTag                  
 AND PS.IsLastLevel <> 1           
 INNER JOIN #TargetSectionsList PS1 WITH (NOLOCK)                  
 ON PS1.SectionId = PS.ParentSectionId                  
 AND PS1.ProjectId = PS.ProjectId                  
 INNER JOIN #TargetSectionsList PS2 WITH (NOLOCK)                  
 ON PS2.SectionId = PS1.ParentSectionId                  
 AND PS2.ProjectId = PS1.ProjectId                  
WHERE PS.SourceTag IS NOT NULL                      
   
       
   UPDATE SPS                      
 SET                      
  IsTargetSectionIsHidden = ISNULL(PS.IsHidden,0)                  
 FROM #ImportingSectionStatus SPS WITH (NOLOCK)                      
 LEFT OUTER JOIN #TargetSectionsList PS WITH (NOLOCK)                      
 ON PS.ProjectId = @PTargetProjectId                      
 AND PS.CustomerId = @PCustomerId                      
 AND PS.SourceTag = SPS.SourceTag                  
 AND PS.IsLastLevel = 1         
      
                      
SELECT                     
*                     
FROM #ImportingSectionStatus ISS WITH (NOLOCK)                    
--WHERE ISS.IsIdenticalFolderExistInTargetProject = 0                    
                    
                      
END;   