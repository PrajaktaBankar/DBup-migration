CREATE PROCEDURE [dbo].[usp_GetDivisionsAndSectionsForPrint]                 
(                          
 @ProjectId INT,                          
 @CustomerId INT,                          
 @CatalogueType NVARCHAR(100)                          
)                  
  AS                            
BEGIN                                                

 DECLARE @PProjectId INT = @ProjectId;                                                
 DECLARE @PCustomerId INT = @CustomerId;                                                
 DECLARE @PCatalogueType NVARCHAR(100) = @CatalogueType;                                                
  DECLARE @TRUE BIT=1, @FALSE BIT=0                                              
 DROP TABLE IF EXISTS #ProjectInfoTbl;                                          
 DROP TABLE IF EXISTS #ActiveSectionsTbl;                                          
 DROP TABLE IF EXISTS #DistinctDivisionTbl;                                          
 DROP TABLE IF EXISTS #ActiveSectionsIdsTbl;              
 DROP TABLE IF EXISTS #DivisionResultTbl;      
 DROP TABLE IF EXISTS #SupDocSubFolderIdsTbl;
                                                
 SELECT                                                
  P.ProjectId                                                
    ,P.[Name] AS ProjectName                                                
    ,P.MasterDataTypeId                                                
    ,PS.SourceTagFormat                                                
    ,PS.SpecViewModeId                                                
    ,PS.UnitOfMeasureValueTypeId                                             
 INTO #ProjectInfoTbl                                                
 FROM Project P WITH (NOLOCK)                                                
 INNER JOIN ProjectSummary PS WITH (NOLOCK)                                                
  ON PS.ProjectId = P.ProjectId                                                
 WHERE P.ProjectId = @PProjectId                                                
 
DECLARE @MasterDataTypeId INT;
SELECT @MasterDataTypeId = MasterDataTypeId FROM #ProjectInfoTbl;

 SELECT SectionId                                          
 INTO #ActiveSectionsIdsTbl                                          
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)                                          
 WHERE PSST.ProjectId = @PProjectId                                          
 AND PSST.CustomerId = @PCustomerId                                             
 AND PSST.SequenceNumber = 0                                                
 AND PSST.IndentLevel = 0                                             
 AND PSST.IsParentSegmentStatusActive = 1                                                
 AND PSST.SegmentStatusTypeId < 6                                                
 AND ISNULL(PSST.IsDeleted,0) = 0;                                          
 
 -- Get subfolder's SectionIds which have active supplemental docs attached.
DROP TABLE IF EXISTS #SupDocSubFolderIdsTbl;
 SELECT DISTINCT SectionId 
INTO #SupDocSubFolderIdsTbl
FROM DocLibraryMapping WITH(NOLOCK) WHERE CustomerId = @PCustomerId AND ProjectId = @PProjectId 
AND ISNULL(IsActive, 0) = 1 AND ISNULL(IsAttachedToFolder, 0) = 1 AND ISNULL(IsDeleted, 0) = 0;

 DROP TABLE IF EXISTS #ProjectSectionList;              
  SELECT ProjectId,SectionId,ParentSectionId,IsHidden, IsDeleted,CustomerId,UserId,SourceTag,[Description],DivisionId,Author,SortOrder, CONVERT(INT, 0) AS SubFolderId, CONVERT(INT, 0) AS SubFolderSortOrder, CONVERT(INT, 0) AS FolderId, CONVERT(INT, 0) AS FolderSortOrder, IsLastLevel,LevelId,SectionSource, FormatTypeId              
  INTO #ProjectSectionList FROM ProjectSection WITH (NOLOCK) WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId AND ISNULL(IsDeleted,0) = 0;                 

UPDATE section SET section.FolderId = subF.ParentSectionId , section.SubFolderId = subF.SectionId
 FROM #ProjectSectionList section INNER JOIN #ProjectSectionList subF          
 ON section.ParentSectionId = subF.SectionId WHERE section.IsLastLevel = 1;  
 
  UPDATE section SET section.FolderId = subF.SectionId , section.SubFolderId = section.SectionId
 FROM #ProjectSectionList section INNER JOIN #ProjectSectionList subF          
 ON section.ParentSectionId = subF.SectionId WHERE section.LevelId != 2 AND section.IsLastLevel = 0
 
   UPDATE section SET section.FolderId = section.SectionId , section.SubFolderId = section.SectionId
 FROM #ProjectSectionList section INNER JOIN #ProjectSectionList subF          
 ON section.ParentSectionId = subF.SectionId WHERE section.LevelId = 2 AND section.IsLastLevel = 0

   UPDATE section SET section.FolderSortOrder = ISNULL(subF.SortOrder, 0)
 FROM #ProjectSectionList section INNER JOIN #ProjectSectionList subF          
 ON section.FolderId = subF.SectionId 

    UPDATE section SET section.SubFolderSortOrder = CASE WHEn section.SubFolderId = section.SectionId THEN ISNULL(section.SortOrder, 0) ELSE ISNULL(subF.SortOrder, 0) END
 FROM #ProjectSectionList section INNER JOIN #ProjectSectionList subF          
 ON section.SubFolderId = subF.SectionId
 
 UPDATE section SET section.FolderSortOrder = CASE WHEN section.FolderSortOrder < 0 THEN 0 ELSE ISNULL(section.FolderSortOrder, 0) END,
 section.SubFolderSortOrder = CASE WHEN section.SubFolderSortOrder < 0 THEN 0 ELSE ISNULL(section.SubFolderSortOrder, 0) END
  FROM #ProjectSectionList section
          
DROp TABLE IF EXISTS #ActiveSectionsTbl;              
 SELECT                                
  PS.ProjectId                                                
    ,PS.CustomerId                                            
    ,PS.SectionId                                                
    ,PS.UserId                                               
    ,PS.SourceTag                                                
    ,PS.[Description] AS SectionName                                                
    ,PS.DivisionId                                                
    ,PS.Author                                      
    ,PS.ParentSectionId          
    ,PS.SortOrder                 
    ,PS.SubFolderSortOrder          
    ,PS.FolderSortOrder  
	,PS.SectionSource    
	,@FALSE AS IsSuppDocsAttached
	,@FALSE AS IsSubFolder
 INTO #ActiveSectionsTbl                                                
 FROM #ActiveSectionsIdsTbl AST WITH (NOLOCK)                                          
 INNER JOIN #ProjectSectionList PS WITH (NOLOCK) ON PS.SectionId = AST.SectionId                                       
 WHERE ISNULL(PS.IsDeleted,0) = 0 AND ISNULL(PS.IsHidden,0) = 0;                     
                           
  ------ Delete sections which parent folders are hidden                          
 DELETE FROM #ActiveSectionsTbl WHERE SectionId IN (                          
 SELECT PS1.SectionId                          
 FROM #ActiveSectionsTbl PS1 WITH (NOLOCK)                          
 INNER JOIN #ProjectSectionList PS2 WITH (NOLOCK)                          
 ON PS2.SectionId = PS1.ParentSectionId                          
 AND PS2.ProjectId = PS1.ProjectId                          
 INNER JOIN #ProjectSectionList PS3 WITH (NOLOCK)                          
 ON PS3.SectionId = PS2.ParentSectionId                          
 AND PS3.ProjectId = PS2.ProjectId                          
 WHERE PS2.IsHidden = 1 OR PS3.IsHidden = 1                          
 )                          
 ------                          

DROP TABLE IF EXISTS #SupDocSubFoldersTbl;
 SELECT                                
  PS.ProjectId                                                
    ,PS.CustomerId                                            
    ,PS.SectionId                                                
    ,PS.UserId                                               
    ,PS.SourceTag                                                
    ,PS.[Description] AS SectionName  
	,ISNULL(MD.DivisionId, PS1.DivisionId) AS DivisionId
    ,ISNULL(PS.Author, '') AS Author                                       
    ,PS.ParentSectionId          
    ,PS.SortOrder                 
    ,PS.SubFolderSortOrder          
    ,PS.FolderSortOrder  
	,PS.SectionSource   
	,@TRUE AS IsSuppDocsAttached
	,@TRUE AS IsSubFolder
 INTO #SupDocSubFoldersTbl                                                
 FROM #SupDocSubFolderIdsTbl AST WITH (NOLOCK)                                          
 INNER JOIN #ProjectSectionList PS WITH (NOLOCK) ON PS.SectionId = AST.SectionId  
 INNER JOIN #ProjectSectionList PS1 WITH (NOLOCK) ON PS1.SectionId = PS.ParentSectionId  
 LEFT JOIN SLCMaster..Division MD WITH(NOLOCK) ON MD.DivisionCode = CASE PS1.SourceTag WHEN '9' THEN '99' ELSE PS1.SourceTag END AND MD.MasterDataTypeId = @MasterDataTypeId AND MD.FormatTypeId = PS.FormatTypeId
 WHERE ISNULL(PS.IsDeleted,0) = 0 AND ISNULL(PS.IsHidden,0) = 0;

  ------ Delete sections which parent folders are hidden                          
 DELETE FROM #SupDocSubFoldersTbl WHERE SectionId IN (                          
 SELECT PS1.SectionId                          
 FROM #ActiveSectionsTbl PS1 WITH (NOLOCK)                          
 INNER JOIN #ProjectSectionList PS2 WITH (NOLOCK)                          
 ON PS2.SectionId = PS1.ParentSectionId                          
 AND PS2.ProjectId = PS1.ProjectId                          
 INNER JOIN #ProjectSectionList PS3 WITH (NOLOCK)                          
 ON PS3.SectionId = PS2.ParentSectionId                          
 AND PS3.ProjectId = PS2.ProjectId                          
 WHERE PS2.IsHidden = 1 OR PS3.IsHidden = 1                          
 )
                   
 SELECT DISTINCT                                                
  D.DivisionId                                                
    ,D.DivisionCode                                                
    ,D.DivisionTitle AS DivisionName INTO #DistinctDivisionTbl                                                
 FROM #ActiveSectionsTbl AST                                              
 INNER JOIN SLCMaster..Division D WITH (NOLOCK)                                                
  ON D.DivisionId = AST.DivisionId                         
  UNION                         
SELECT    DISTINCT                      
  CD.DivisionId                                                
    ,CD.DivisionCode                                                
    ,CD.DivisionTitle AS DivisionName                         
  FROM #ActiveSectionsTbl AST                        
  INNER JOIN CustomerDivision CD WITH (NOLOCK)                        
  ON AST.DivisionId = CD.DivisionId                        
  AND AST.CustomerId = CD.CustomerId                       
  WHERE ISNULL(CD.IsDeleted,0) = 0                       
  UNION
SELECT DISTINCT                                                
  D.DivisionId                                                
    ,D.DivisionCode                                                
    ,D.DivisionTitle AS DivisionName                                               
 FROM #SupDocSubFoldersTbl AST                                              
 INNER JOIN SLCMaster..Division D WITH (NOLOCK)                                                
  ON D.DivisionId = AST.DivisionId
  UNION                         
SELECT    DISTINCT                      
  CD.DivisionId                                                
    ,CD.DivisionCode                                                
    ,CD.DivisionTitle AS DivisionName                         
  FROM #SupDocSubFoldersTbl AST                        
  INNER JOIN CustomerDivision CD WITH (NOLOCK)                        
  ON AST.DivisionId = CD.DivisionId                        
  AND AST.CustomerId = CD.CustomerId                       
  WHERE ISNULL(CD.IsDeleted,0) = 0


 SELECT                                                
  DivisionId                                                
    ,ISNULL(DivisionCode,'') AS DivisionCode                  
    ,DivisionName             
    ,CAST(dbo.udf_ExpandDigits(ISNULL(DivisionCode,''), 18, '0') AS NVARCHAR(400)) AS T_DivisionCode            
    ,CAST(dbo.udf_ExpandDigits(ISNULL(DivisionName,''), 20, '0') AS NVARCHAR(MAX)) AS T_DivisionName            
     INTO #DivisionResultTbl                                 
 FROM #DistinctDivisionTbl;            
    
 UPDATE #DivisionResultTbl SET DivisionName = 'Administration' WHERE DivisionCode = '99';    
                                                    
                                            
 ----START Added for to delete parent deleted section CSI ticket 35671                                      
DELETE P FROM #ActiveSectionsTbl P WITH (NOLOCK)                                      
INNER JOIN ProjectSection PS WITH (NOLOCK)                                      
ON PS.SectionId = P.ParentSectionId                                      
where ISNULL(PS.IsDeleted,0)=1    
                                    
DELETE P FROM #SupDocSubFoldersTbl P WITH (NOLOCK)                                      
INNER JOIN ProjectSection PS WITH (NOLOCK)                                      
ON PS.SectionId = P.ParentSectionId                                      
where ISNULL(PS.IsDeleted,0)=1 
                                  
--Delete sections whose parent id is not refering in anywhere (Bcz those parents alos printing uncessary CSI 35671)                                  
DELETE PS                                   
FROM #ActiveSectionsTbl PS WITH (NOLOCK)                                    
LEFT OUTER JOIN ProjectSection PS2  WITH (NOLOCK)                                    
ON PS2.ParentSectionId = Ps.SectionId                                  
WHERE PS.ProjectId=@PProjectId AND PS.ParentSectionId=0                                  
AND PS2.SectionId IS NULL        

DELETE PS                                   
FROM #SupDocSubFoldersTbl PS WITH (NOLOCK)                                    
LEFT OUTER JOIN ProjectSection PS2  WITH (NOLOCK)                                    
ON PS2.ParentSectionId = Ps.SectionId                                  
WHERE PS.ProjectId=@PProjectId AND PS.ParentSectionId=0                                  
AND PS2.SectionId IS NULL
---END----------------------

DROP TABLE IF EXISTS #DocLibrarySuppDocs
SELECT  SectionId , count(SectionId) as SectionIdCount
INTO #DocLibrarySuppDocs
FROM DocLibraryMapping WITH(NOLOCK) WHERE CustomerId = @PCustomerId AND ProjectId = @PProjectId 
AND ISNULL(IsActive, 0) = 1 AND ISNULL(IsDeleted, 0) = 0
GROUP BY SectionId

 DROP TABLE IF EXISTS #FinalSectionsResult

 SELECT * INTO #FinalSectionsResult
 FROM #ActiveSectionsTbl
 UNION
 SELECT * FROM #SupDocSubFoldersTbl

  SELECT                                                
 D.DivisionId                                                
    ,ISNULL(DivisionCode,'') AS DivisionCode                  
    ,DivisionName      
    ,T_DivisionCode            
    ,T_DivisionName
	,ISNULL(A.AllSectionCount, 0) AS AllSectionCount
	,ISNULL(B.SubFolderCount, 0) AS SubFolderCount
 FROM #DivisionResultTbl D
LEFT JOIN ( SELECT DivisionId, COUNT(SectionId) AS AllSectionCount FROM #FinalSectionsResult GROUP BY DivisionId) AS A ON A.DivisionId = D.DivisionId
 LEFT JOIN ( SELECT DivisionId, COUNT(SectionId) AS SubFolderCount FROM #FinalSectionsResult WHERE IsSubFolder = 1 GROUP BY DivisionId) AS B ON B.DivisionId = D.DivisionId
 ORDER BY T_DivisionCode ,T_DivisionName; 


 SELECT 
  AST.ProjectId                                                
    ,AST.CustomerId                                                
    ,AST.SectionId                                                
    ,AST.UserId                                                
    ,ISNULL(AST.SourceTag, '') AS SourceTag                                           
    ,AST.SectionName                                                
    ,AST.DivisionId                                                
    ,AST.Author                                                
    ,PIT.ProjectName                                                
    ,PIT.MasterDataTypeId                                                
    ,PIT.SourceTagFormat               
    ,PIT.SpecViewModeId                                                
    ,PIT.UnitOfMeasureValueTypeId                                                
    ,@PCatalogueType AS CatalogueType                                                
    ,ISNULL(DDT.DivisionCode ,'') AS DivisionCode                  
    ,DDT.DivisionName
	,IIF(ISNULL(AST.SectionSource,0)=8,@TRUE,@FALSE) as IsAlternateDocument      
	,IIF(AST.SectionId = DLS. SectionId, @TRUE,@FALSE) AS IsSuppDocsAttached
	,AST.IsSubFolder
 FROM  #FinalSectionsResult AST
INNER JOIN #ProjectInfoTbl PIT                                                
  ON PIT.ProjectId = AST.ProjectId                                                
 INNER JOIN #DistinctDivisionTbl DDT                                                
  ON DDT.DivisionId = AST.DivisionId                                                
LEFT JOIN #DocLibrarySuppDocs DLS on DLS.SectionId = AST.SectionId
 ORDER BY AST.FolderSortOrder ASC, AST.SubFolderSortOrder ASC, AST.IsSubFolder DESC, AST.SortOrder ASC

END