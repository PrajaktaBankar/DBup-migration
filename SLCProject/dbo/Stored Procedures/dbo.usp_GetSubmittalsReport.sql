CREATE PROCEDURE [dbo].[usp_GetSubmittalsReport]               
 @ProjectId INT,                      
 @CustomerID INT                    
AS                      
BEGIN     
SET	NOCOUNT ON;            
 DECLARE @PProjectId INT = @ProjectId;          
 DECLARE @PCustomerID INT = @CustomerID;          
          
--Select Active Sections into #SegmentWithTags                      
SELECT          
 PSRT.SectionId          
   ,LPRT.TagType          
   ,PS.SourceTagFormat     
   INTO #SegmentWithTags          
FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)          
INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)          
 ON LPRT.RequirementTagId = PSRT.RequirementTagId          
INNER JOIN ProjectSegmentStatus PSS WITH (NOLOCK)          
 ON PSS.SegmentStatusId = PSRT.SegmentStatusId          
INNER JOIN [ProjectSummary] PS WITH (NOLOCK)          
 ON PS.ProjectId = PSRT.ProjectId          
  AND PSS.SegmentStatusTypeId < 6          
  AND PSS.IsParentSegmentStatusActive = 1          
WHERE PSRT.ProjectId = @PProjectId          
AND PSRT.CustomerId = @PCustomerId          
AND PSRT.RequirementTagId IN (17, 26, 27)          
          
--Sections with filtered tags                      
SELECT          
 SectionId          
   ,          
 --Row Values into Column                          
 CASE          
  WHEN [PD] = 0 THEN 'N'          
  ELSE 'Y'          
 END AS IsProductData          
   ,CASE          
  WHEN [SD] = 0 THEN 'N'          
  ELSE 'Y'          
 END AS IsShopDrawings          
   ,CASE          
  WHEN [SA] = 0 THEN 'N'          
  ELSE 'Y'          
 END AS IsSamples          
   ,SourceTagFormat INTO #SectionWithTags          
FROM #SegmentWithTags          
PIVOT          
(          
COUNT(TagType)          
FOR TagType IN ([PD], [SD], [SA])          
) AS SWT          
      
--Get Master and customer divisions      
SELECT DISTINCT D.DivisionId,D.DivisionCode,D.DivisionTitle       
INTO #DivisionList      
FROM SLCMaster..Division D WITH (NOLOCK)      
INNER JOIN Project P WITH (NOLOCK)      
ON P.ProjectId= @PProjectId AND P.CustomerId = @PCustomerID      
AND D.MasterDataTypeId = P.MasterDataTypeId      
UNION       
SELECT DISTINCT      
CD.DivisionId, CD.DivisionCode, CD.DivisionTitle      
FROM CustomerDivision CD WITH (NOLOCK)      
WHERE CD.CustomerId = @PCustomerID AND ISNULL(CD.IsDeleted,0) = 0      
      
--Selects final Result with section and tags info                      
SELECT          
 PS.SectionId          
   ,PS.[Description]          
   ,PS.[Description] as SectionName        
   ,PS.DivisionId          
   ,PS.ParentSectionId          
   ,PS.DivisionCode          
   ,'DIVISION ' + UPPER(D.DivisionCode) + ' - ' + UPPER(D.DivisionTitle) AS DivisionTitle          
   ,PS.SourceTag          
   ,SWT.IsProductData          
   ,SWT.IsShopDrawings          
   ,SWT.IsSamples          
   ,SWT.SourceTagFormat  
   ,PS.SortOrder  
   ,0 AS SubFolderSortOrder  
   ,0 AS FolderSortOrder  
   ,0 AS FolderSectionId  
   INTO #ResultSet        
FROM #SectionWithTags SWT WITH (NOLOCK)          
INNER JOIN ProjectSection PS WITH (NOLOCK)          
 ON PS.SectionId = SWT.SectionId          
INNER JOIN #DivisionList D WITH (NOLOCK)          
 ON D.DivisionId = PS.DivisionId          
WHERE PS.ProjectId = @PProjectId          
AND PS.CustomerId = @PCustomerId          
and isnull(PS.IsDeleted,0)=0        
AND ISNULL(PS.IsHidden,0) = 0    
ORDER BY PS.DivisionCode ASC, PS.SourceTag ASC          
     
 -- get folders    
 SELECT SectionId,ParentSectionId,IsHidden     
 INTO #ProjectSectionTemp    
 FROM ProjectSection PS WITH (NOLOCK)    
 WHERE PS.ProjectId = @PProjectId AND PS.CustomerId = @PCustomerID    
 AND ISNULL(PS.IsDeleted,0) =0 AND ISNULL(PS.IsLastLevel,0) = 0    
    
--delete sections which parent folders are hidden    
DELETE FROM #ResultSet WHERE  SectionId IN(       
 SELECT PS1.SectionId     
 FROM #ResultSet PS1 WITH (NOLOCK)    
 INNER JOIN #ProjectSectionTemp PS2 WITH (NOLOCK)    
  ON PS2.SectionId = PS1.ParentSectionId    
  INNER JOIN #ProjectSectionTemp PS3 WITH (NOLOCK)    
  ON PS3.SectionId = PS2.ParentSectionId    
  WHERE PS2.IsHidden = 1 OR PS3.IsHidden = 1    
)    
   
  --Update Subfolder SortOrder        
 UPDATE section SET section.FolderSectionId = subF.ParentSectionId , section.SubFolderSortOrder = ISNULL(subF.SortOrder,0) FROM #ResultSet section INNER JOIN ProjectSection subF WITH(NOLOCK)      
 ON section.ParentSectionId = subF.SectionId WHERE subF.ProjectId = @PProjectId AND subF.CustomerId = @PCustomerId;       
      
 --Update Folder SortOrder        
 UPDATE section SET section.FolderSortOrder = ISNULL(folder.SortOrder,0) FROM #ResultSet section INNER JOIN ProjectSection folder WITH(NOLOCK)      
 ON section.FolderSectionId = folder.SectionId WHERE folder.ProjectId = @PProjectId AND folder.CustomerId = @PCustomerId;       
  
SELECT * FROM #ResultSet ORDER BY FolderSortOrder, SubFolderSortOrder, SortOrder;    
    
END