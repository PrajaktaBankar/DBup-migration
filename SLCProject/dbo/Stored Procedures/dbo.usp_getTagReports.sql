
CREATE PROCEDURE [dbo].[usp_getTagReports]                        
(                      
@ProjectId INT,                        
@CustomerId INT,                       
@TagType INT,                       
@TagIdList NVARCHAR(MAX) NULL                      
)                        
AS                        
BEGIN                
DROP TABLE IF EXISTS #SegmentStatusIds                
DROP TABLE IF EXISTS #SectionsContainingTaggedSegments                
                
DECLARE @PProjectId INT = @ProjectId;                
DECLARE @PCustomerId INT = @CustomerId;                
DECLARE @PTagType INT = @TagType;                
DECLARE @PTagIdList NVARCHAR(MAX) = @TagIdList;                
                
--CONVERT STRING INTO TABLE                                  
CREATE TABLE #TagIdTbl (                
 TagId INT                
);                
INSERT INTO #TagIdTbl (TagId)                
 SELECT                
  *                
 FROM dbo.fn_SplitString(@PTagIdList, ',');                
                
CREATE TABLE #SegmentStatusIds (                
 SegmentStatusId BIGINT                
   ,TagId INT                
   ,TagName NVARCHAR(MAX)                
);                
                
INSERT INTO #SegmentStatusIds (SegmentStatusId, TagId, TagName)                
 (SELECT                
  PSRT.SegmentStatusId                
    ,TIT.TagId                
    ,LPRTI.Description AS TagName                
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)                
 INNER JOIN LuProjectRequirementTag LPRTI WITH (NOLOCK)                
  ON PSRT.RequirementTagId = LPRTI.RequirementTagId                
 INNER JOIN #TagIdTbl TIT                
  ON PSRT.RequirementTagId = TIT.TagId                
 WHERE PSRT.ProjectId = @PProjectId                
 --AND PSRT.RequirementTagId = @PTagId                        
 UNION ALL                
 SELECT                
  PSUT.SegmentStatusId                
    ,TIT.TagId                
    ,PUT.Description AS TagName                
 FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)                
 INNER JOIN #TagIdTbl TIT                
  ON PSUT.UserTagId = TIT.TagId                
 INNER JOIN ProjectUserTag PUT  WITH (NOLOCK)              
  ON PUT.UserTagId = TIT.TagId                
 WHERE PSUT.CustomerId = @PCustomerId AND PSUT.ProjectId = @PProjectId                
 --AND PSUT.UserTagId = @PTagId                        
 )                
--END                        
                
--Inserts Sections Containing Tagged Segments                          
SELECT                
 PSS.SectionId                
   ,SI.TagId                
   ,SI.TagName                
   ,PSS.ProjectId                
   ,PSS.CustomerId INTO #SectionsContainingTaggedSegments                
FROM ProjectSegmentStatusView PSS WITH (NOLOCK)                
INNER JOIN #SegmentStatusIds SI                
 ON PSS.SegmentStatusId = SI.SegmentStatusId                
WHERE PSS.ProjectId = @PProjectId                
AND PSS.CustomerId = @PCustomerId                
AND PSS.IsDeleted = 0                
AND PSS.IsSegmentStatusActive <> 0

               
--Select Sections with Tags                          
SELECT DISTINCT                
    ISNULL(PS.SectionId,0)as SectionId      
   ,ISNULL(PS.DivisionId,0)  as DivisionId             
   ,PS.DivisionCode     
   ,PS.ParentSectionId     
   ,PS.[Description]                
   ,PS.SourceTag                
   ,PS.Author                
   ,ISNULL(PS.SectionCode,0) as SectionCode               
   ,ISNULL(SCTS.Tagid,0) as Tagid            
   ,SCTS.TagName  
   ,PS.SortOrder  
   ,0 AS SubFolderSortOrder  
   ,0 AS FolderSortOrder  
   ,0 AS FolderSectionId          
   INTO #ResultSet      
FROM ProjectSection PS WITH (NOLOCK)                
JOIN #SectionsContainingTaggedSegments SCTS                
 ON PS.ProjectId = SCTS.ProjectId                
  AND PS.SectionId = SCTS.SectionId                
  AND PS.CustomerId = SCTS.CustomerId                
WHERE PS.ProjectId = @PProjectId                
AND PS.CustomerId = @PCustomerId      
AND ISNULL(PS.IsHidden,0) = 0     
ORDER BY SCTS.Tagname, PS.SourceTag;     
    
 ---- get folders      
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
     
 -- get master and customer divisions    
 SELECT DISTINCT ISNULL(D.DivisionId,0) AS DivisionId           
   ,D.DivisionCode                
   ,D.DivisionTitle                
   ,D.SortOrder                
   ,D.IsActive                
   ,ISNULL(D.MasterDataTypeId,0) as MasterDataTypeId              
   ,ISNULL(D.FormatTypeId ,0) as  FormatTypeId     
   INTO #DivisionList    
   FROM SLCMaster..Division D WITH (NOLOCK)    
 INNER JOIN Project P WITH (NOLOCK)    
 ON P.MasterDataTypeId = D.MasterDataTypeId    
 AND P.ProjectId = @PProjectId AND P.CustomerId = @PCustomerId    
 UNION    
 SELECT DISTINCT ISNULL(CD.DivisionId,0) AS DivisionId             
   ,CD.DivisionCode                
   ,CD.DivisionTitle                
   ,0 AS SortOrder                
   ,CD.IsActive                
   ,ISNULL(CD.MasterDataTypeId,0) as MasterDataTypeId              
   ,ISNULL(CD.FormatTypeId ,0) as  FormatTypeId     
 FROM CustomerDivision CD WITH (NOLOCK)    
 WHERE CD.CustomerId = @PCustomerId AND ISNULL(CD.IsDeleted,0) = 0    
                
--Select Division For Sections who has tagged segments                          
SELECT DISTINCT                
 ISNULL(D.DivisionId,0) as Id               
   ,D.DivisionCode                
   ,D.DivisionTitle                
   ,D.SortOrder                
   ,D.IsActive                
   ,ISNULL(D.MasterDataTypeId,0) as MasterDataTypeId              
   ,ISNULL(D.FormatTypeId ,0) as  FormatTypeId       
   ,@PCustomerId as CustomerId      
FROM #DivisionList D WITH (NOLOCK)                
INNER JOIN ProjectSection PS WITH (NOLOCK)                
 ON PS.DivisionId = D.DivisionId                
JOIN #SectionsContainingTaggedSegments SCTS WITH (NOLOCK)                
 ON PS.ProjectId = SCTS.ProjectId                
  AND PS.SectionId = SCTS.SectionId                
  AND PS.CustomerId = SCTS.CustomerId                
WHERE PS.ProjectId = @PProjectId                
AND PS.CustomerId = @PCustomerId       
AND ISNULL(PS.IsHidden,0) = 0      
order by D.DivisionCode          
                
SELECT DISTINCT                
 COALESCE(TemplateId, 1) TemplateId INTO #TEMPLATE                
FROM Project WITH (NOLOCK)                
WHERE ProjectId = @PProjectID                
                
-- SELECT TEMPLATE STYLE DATA                          
SELECT                
 ST.StyleId                
   ,ST.Alignment                
   ,ST.IsBold                
   ,ST.CharAfterNumber            
   ,ST.CharBeforeNumber                
   ,ST.FontName                
   ,ST.FontSize                
   ,ST.HangingIndent                
   ,ST.IncludePrevious                
   ,ST.IsItalic                
   ,ST.LeftIndent                
   ,ST.NumberFormat                
   ,ST.NumberPosition                
   ,ST.PrintUpperCase                
   ,ST.ShowNumber                
   ,ST.StartAt                
   ,ST.Strikeout                
   ,ST.Name                
   ,ST.TopDistance                
   ,ST.Underline                
   ,ST.SpaceBelowParagraph                
   ,ST.IsSystem                
   ,ST.IsDeleted                
   ,TSY.Level           
   ,ISNULL(SPS.CustomLineSpacing,0) as CustomLineSpacing        
   ,ISNULL(SPS.DefaultSpacesId,0) as  DefaultSpacesId        
   ,ISNULL(SPS.BeforeSpacesId,0) as   BeforeSpacesId        
   ,ISNULL(SPS.AfterSpacesId,0) as AfterSpacesId           
   ,@PCustomerId as CustomerId      
FROM Style ST WITH (NOLOCK)                
INNER JOIN TemplateStyle TSY WITH (NOLOCK)                
 ON ST.StyleId = TSY.StyleId                
INNER JOIN #TEMPLATE T                
 ON TSY.TemplateId = T.TemplateId        
LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK)      
 ON SPS.StyleId=ST.StyleId;      
                
-- GET SourceTagFormat                           
SELECT                
 SourceTagFormat                
FROM ProjectSummary WITH (NOLOCK)                
WHERE ProjectId = @PProjectId;                
                
END 
GO


