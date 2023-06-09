CREATE Procedure usp_getTOCReport  
(                      
@ProjectId INT,                                                            
@CustomerId INT,                                                
@CatalogueType NVARCHAR(MAX),                                  
@IsTOCForAllSections BIT                                  
)                                 
AS                                    
BEGIN                     
DECLARE @PProjectId INT = @ProjectId;                                                                
DECLARE @PCustomerId INT =@CustomerId;                                                                
DECLARE @OldKeywordFormat NVARCHAR(MAX) = '{\kw\';                                                                  
DECLARE @NewKeywordFormat NVARCHAR(MAX) = '{KW#';                                                                  
DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;                                                              
DECLARE @PCatalogueTypelIST NVARCHAR(MAX) ;                                                       
 DECLARE @ImagSegment int =1                                                      
 DECLARE @ImageHeaderFooter int =3                                                    
                                                      
DECLARE @CatalogueTypeTbl TABLE (                                                                    
 TagType NVARCHAR(MAX)                                                                    
);                                                                
                                                                
  SELECT @PCatalogueTypelIST=                                                              
(CASE                                                              
    WHEN @PCatalogueType ='OL' THEN '2'                                                              
 WHEN @PCatalogueType ='SF' THEN '1,2'                                                              
    ELSE '1,2,3'                                                               
END);                                                              
                                                              
--CONVERT CATALOGUE TYPE INTO TABLE                                                                    
IF @PCatalogueType IS NOT NULL                                                                    
 AND @PCatalogueType != 'FS'                                                                    
BEGIN                                                                      
INSERT INTO @CatalogueTypeTbl (TagType)                                                                    
 SELECT                                                                    
  *                                                                    
 FROM dbo.fn_SplitString(@PCatalogueTypelIST, ',');                                                                 
 END                                                              
                                                      
--SELECT SEGMENT MASTER TAGS DATA                                                                         
SELECT                                                                
 PSRT.SegmentStatusId                                                                
   ,PSRT.SegmentRequirementTagId                                                                
   ,PSST.mSegmentStatusId                                                                
   ,LPRT.RequirementTagId                                                                
   ,LPRT.TagType                                                                
   ,LPRT.Description AS TagName                                                                
   ,CASE                                                                
  WHEN PSRT.mSegmentRequirementTagId IS NULL THEN CAST(0 AS BIT)                                                                
  ELSE CAST(1 AS BIT)                                                
 END AS IsMasterRequirementTag                                          
   ,PSST.SectionId INTO #MasterTagList                                                        
FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)                                                                
INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)                                                                
 ON PSRT.RequirementTagId = LPRT.RequirementTagId                                                                
INNER JOIN ProjectSegmentStatus AS PSST WITH (NOLOCK)                                                                
 ON  PSRT.ProjectId = PSST.ProjectId                         
 AND PSRT.CustomerId = PSST.CustomerId                                                
 AND PSRT.SectionId = PSST.SectionId                                                  
 AND PSRT.SegmentStatusId = PSST.SegmentStatusId                           
WHERE PSRT.ProjectId = @PProjectId                                        
AND PSRT.CustomerId = @PCustomerId                                                                
AND PSST.ParentSegmentStatusId=0                                           
AND LPRT.RequirementTagId IN (2,3)--NS,NP                                                                
AND ISNULL(PSST.IsDeleted, 0) = 0 --CSI 59720 
                                                  
----get the active and inactive sections list for toc                                                  
                                
SELECT                                                                
 0 As SegmentStatusId,                                                                
 ISNULL(PS.SourceTag,'')  AS SourceTag                                                              
,PS.Author                                                                
,PS.SectionId                                                                
,PS.mSectionId                                                              
,CASE WHEN PS.LevelId = 2 AND ISNULL(PS.mSectionId,0) =0 THEN 0 ELSE PS.DivisionId END  AS DivisionId                                                         
,TRIM(PS.Description) AS Description                                                                
 ,0 as SpecTypeTagId                                                    
,PS.ParentSectionId                                  
,PS.SortOrder                                                  
INTO #ActiveInactiveSectionList                                                           
FROM ProjectSection PS WITH(NOLOCK)                                             
WHERE PS.ProjectId = @PProjectId                                                                
AND PS.CustomerId = @PCustomerId                                                                
AND PS.IsDeleted = 0                                                  
AND ISNULL(PS.IsHidden,0) = 0                                              
                                                               
                                                  
                                                       
--SELECT Active Section DATA                                                                         
SELECT                                                  
PSST.SegmentStatusId                                                                
,ISNULL(PS.SourceTag ,'')AS SourceTag                                     
,PS.Author                                                                
,PS.SectionId                                                                
,PS.mSectionId                                                                
,PS.DivisionId                                                                
,TRIM(PS.Description) AS Description                                                                 
,PSST.SpecTypeTagId                                                       
,PS.ParentSectionId          
,PS.SortOrder                                                     
INTO #ActiveSectionList                                                        
FROM ProjectSection PS WITH(NOLOCK)                                                                
INNER JOIN ProjectSegmentStatus PSST WITH(NOLOCK)                                                                
ON PS.SectionId = PSST.SectionId                                                 
AND PS.ProjectId = PSST.ProjectId                                                
AND PS.CustomerId = PSST.CustomerId                                           
WHERE PS.ProjectId = @PProjectId                                                                
AND PS.CustomerId = @PCustomerId                                                                
AND PS.IsDeleted = 0                                                 
AND ISNULL(PS.IsHidden,0) = 0                                                               
AND PSST.SequenceNumber = 0                                         
AND PSST.IndentLevel = 0                                                                
AND PSST.ParentSegmentStatusId = 0    
AND ISNULL(PSST.IsDeleted, 0) = 0 --CSI 59720
AND (PSST.IsParentSegmentStatusActive = 1 AND PSST.SegmentStatusTypeId<6)                                                                
AND (@PCatalogueType = 'FS'                                                                    
OR PSST.SpecTypeTagId IN (SELECT * FROM @CatalogueTypeTbl))                                                              

	DROP TABLE IF EXISTS #ProjectSectionList;

	SELECT ProjectId,mSectionId, SectionId,ParentSectionId,IsHidden, IsDeleted,CustomerId,UserId,SourceTag,[Description],DivisionId,Author,SortOrder,0 AS SubFolderSortOrder, 0 AS FolderId, 0 AS FolderSortOrder, IsLastLevel,LevelId            
  INTO #ProjectSectionList FROM ProjectSection WITH (NOLOCK) WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId AND ISNULL(IsDeleted,0) = 0;  
                                                          
IF @IsTOCForAllSections = 1                                                  
  BEGIN                                             
  create table #Temp(RowId INT,SectionId INT,ParentSectionId INT,DivisionId INT,DivisionCode nvarchar(10),SourceTag nvarchar(20),Author nvarchar(100),mSectionId INT,[Description] nvarchar(500),IsHidden bit,IsLastLevel bit,SortOrder int,xSourceTag nvarchar(50),xAuthor nvarchar(50),[Type] NVARCHAR(10),DSortOrder INT,SdSortOrder INT,ActualSortOrder INT)                               
   --TOC List for active and inactive sections and divisions           
   insert into #Temp          
   exec usp_CorrectProjectSectionSortO1rder_df @ProjectId,@CustomerId,0              
                                                        
  SELECT 0 as SegmentStatusId,SourceTag,Author,SectionId,ISNULL(mSectionId,0) as mSectionId ,ISNULL(DivisionId,0) AS DivisionId,TRIM(Description) AS [Description],0 as SpecTypeTagId,                          
  ParentSectionId, SortOrder, SdSortOrder AS SubFolderSortOrder, DSortOrder AS FolderSortOrder, 0 AS FolderSectionId,DSortOrder,SdSortOrder,DivisionCode          
     into #TOCAllSectionsList FROM #Temp           
  where [Type] in('3Leaf') and DivisionId>0          
  order by DSortOrder,SdSortOrder,SortOrder          
    

  
    ------ Delete sections which parent folders are hidden                        
 DELETE FROM #TOCAllSectionsList WHERE SectionId IN (                        
 SELECT PS1.SectionId                        
 FROM #TOCAllSectionsList PS1 WITH (NOLOCK)                        
 INNER JOIN #ProjectSectionList PS2 WITH (NOLOCK)                        
 ON PS2.SectionId = PS1.ParentSectionId                        
 --AND PS2.ProjectId = PS1.ProjectId                        
 INNER JOIN #ProjectSectionList PS3 WITH (NOLOCK)                        
 ON PS3.SectionId = PS2.ParentSectionId                        
 AND PS3.ProjectId = PS2.ProjectId                        
 WHERE PS2.IsHidden = 1 OR PS3.IsHidden = 1                        
 )                        
 ------ 
         
  select * from #TOCAllSectionsList order by DSortOrder,SdSortOrder,SortOrder          
             
  CREATE TABLE #DivisionList(RowId INT,DivisionId INT,DivisionCode NVARCHAR(10),DivisionTitle NVARCHAR(500),SortOrder INT,IsActive INT)          
            
  insert into #DivisionList(DivisionId,DivisionCode,SortOrder,IsActive,DivisionTitle)          
  select DISTINCT DivisionId,DivisionCode,DSortOrder,1,Description from #Temp           
  WHERE Type='1Div' and DivisionId is not null order by  DSortOrder             
               
  update dl          
  set dl.DivisionCode=d.DivisionCode,          
   dl.DivisionTitle=d.DivisionTitle,          
   dl.IsActive=D.IsActive                  
  FROM #DivisionList dl INNER JOIN CustomerDivision D WITH(NOLOCK)          
  ON dl.DivisionId=D.DivisionId AND D.CustomerId = @PCustomerId               
  WHERE ISNULL(D.IsDeleted,0) =0;          
                            
                                
   SELECT distinct DivisionId as ID, DivisionCode, DivisionTitle, IsActive , SortOrder AS SO1          
   from   #DivisionList where isActive=1 order by  SortOrder             
                                     
                                                  
  END                                                  
                                                  
ELSE                                               
 BEGIN                                                   
 --TOC List                                                                
 SELECT T.SegmentStatusId,T.SourceTag,T.Author,T.SectionId,ISNULL(T.mSectionId,0) as mSectionId ,ISNULL(DivisionId,0) AS DivisionId,Description,SpecTypeTagId,                             
  T.ParentSectionId, T.SortOrder, 0 AS SubFolderSortOrder, 0 AS FolderSortOrder, 0 AS FolderSectionId                               
  INTO #TOCSectionList FROM #MasterTagList M  WITH(NOLOCK)                                                               
 FULL OUTER JOIN  #ActiveSectionList T   WITH(NOLOCK)                      
 ON T.SegmentStatusId=M.SegmentStatusId                                                                
 WHERE M.SegmentStatusId IS NULL                                                    
                                                    
 ----Added for to delete parent delete section CSI ticket 35671                                                    
 DELETE P FROM #TOCSectionList P WITH (NOLOCK)                                                    
 INNER JOIN #ProjectSectionList PS WITH (NOLOCK)                                                    
 ON PS.SectionId = P.ParentSectionId                                                    
 where ISNULL(PS.IsDeleted,0)=1;                                                    
 
  ------ Delete sections which parent folders are hidden                        
 DELETE FROM #TOCSectionList WHERE SectionId IN (                        
 SELECT PS1.SectionId                        
 FROM #TOCSectionList PS1 WITH (NOLOCK)                        
 INNER JOIN #ProjectSectionList PS2 WITH (NOLOCK)                        
 ON PS2.SectionId = PS1.ParentSectionId                        
 --AND PS2.ProjectId = PS1.ProjectId                        
 INNER JOIN #ProjectSectionList PS3 WITH (NOLOCK)                        
 ON PS3.SectionId = PS2.ParentSectionId                        
 AND PS3.ProjectId = PS2.ProjectId                        
 WHERE PS2.IsHidden = 1 OR PS3.IsHidden = 1                        
 )                        
 ------  
                                                    
  --Update Subfolder SortOrder                                  
 UPDATE section SET section.FolderSectionId = subF.ParentSectionId , section.SubFolderSortOrder = ISNULL(subF.SortOrder,0) FROM #TOCSectionList section INNER JOIN #ProjectSectionList subF WITH(NOLOCK)                                
 ON section.ParentSectionId = subF.SectionId WHERE subF.ProjectId = @PProjectId AND subF.CustomerId = @PCustomerId;                                 
                                
 --Update Folder SortOrder                                  
 UPDATE section SET section.FolderSortOrder = ISNULL(folder.SortOrder,0) FROM #TOCSectionList section INNER JOIN #ProjectSectionList folder WITH(NOLOCK)                                
 ON section.FolderSectionId = folder.SectionId WHERE folder.ProjectId = @PProjectId AND folder.CustomerId = @PCustomerId;                              
                                                     
  SELECT * FROM #TOCSectionList WITH(NOLOCK) ORDER BY FolderSortOrder, SubFolderSortOrder, SortOrder;                                                       
                                            
  DROP TABLE IF EXISTS #NewDivisionList;                                          
                                                   
--Select Division For Sections who has tagged segments                                                                            
 SELECT DISTINCT                                                                  
  ISNULL(D.DivisionId,0)  as Id                                                    
  ,D.DivisionCode                                                                  
    ,D.DivisionTitle                                            
    ,CAST(D.SortOrder AS INT) AS SortOrder                                                               
    ,D.IsActive                                                     
    , ISNULL(D.MasterDataTypeId,0) MasterDataTypeId                                                                  
    ,ISNULL(D.FormatTypeId,0) FormatTypeId                                             
   INTO #NewDivisionList                                          
 FROM SLCMaster..Division D WITH (NOLOCK)                                                                  
 INNER JOIN #ProjectSectionList PS WITH (NOLOCK)                                                
  ON PS.DivisionId = D.DivisionId                                                  
  AND PS.ProjectId = @PProjectId                                              
  AND PS.CustomerId = @PCustomerId                                                              
 JOIN #TOCSectionList SCTS WITH (NOLOCK)                                            
   ON PS.SectionId = SCTS.SectionId                                                                  
 WHERE PS.ProjectId = @PProjectId                                                                  
 AND PS.CustomerId = @PCustomerId;                                             
                        
 UPDATE dl SET dl.SortOrder = PS.SortOrder FROM #NewDivisionList dl INNER JOIN #ProjectSectionList PS WITH(NOLOCK) ON                             
 dl.DivisionCode = PS.SourceTag WHERE PS.ProjectId = @ProjectId AND PS.CustomerId = @PCustomerId AND PS.LevelId = 2                        
 AND PS.mSectionId IS NOT NULL;                
                 
 -- Set Sort order of Adminstration Division to Template                
 DECLARE @AdminDivSO INT = (SELECT TOP 1 SortOrder FROM #ProjectSectionList WITH(NOLOCK) WHERE ProjectId = @PProjectId                                                                  
 AND CustomerId = @PCustomerId AND mSectionId IN (1120,3001316));                
         
 UPDATE DL SET SortOrder = @AdminDivSO , DivisionTitle = 'Administration'  FROM #NewDivisionList DL WHERE Id In (38, 3000037);                
 UPDATE DL SET SortOrder = @AdminDivSO+1 FROM #NewDivisionList DL WHERE Id In (37, 3000036);              
                
                                           
  INSERT INTO #NewDivisionList                                          
 SELECT  DISTINCT                                         
  ISNULL(CD.DivisionId,0)  as Id                                                    
  ,CD.DivisionCode                                                                  
    ,CD.DivisionTitle                                                                  
    ,0 AS SortOrder                                                                  
    ,CD.IsActive                                                                  
    , ISNULL(CD.MasterDataTypeId,0) MasterDataTypeId                                                                  
    ,ISNULL(CD.FormatTypeId,0) FormatTypeId                                           
 FROM #TOCSectionList SCTS WITH (NOLOCK)                                           
 INNER JOIN CustomerDivision CD WITH (NOLOCK)                                          
 ON CD.DivisionId = SCTS.DivisionId AND CD.CustomerId = @PCustomerId;                            
                             
UPDATE dl SET dl.SortOrder = PS.SortOrder FROM #NewDivisionList dl INNER JOIN ProjectSection PS WITH(NOLOCK) ON                             
 dl.Id = PS.DivisionId  WHERE PS.ProjectId = @ProjectId AND PS.CustomerId = @PCustomerId AND                        
 PS.LevelId = 2 AND DL.SortOrder =0  AND PS.mSectionID IS NULL;                            
                                                              
 select ROW_NUMBER() OVER(ORDER BY SortOrder) AS SortOrder, ID, DivisionCode, DivisionTitle, IsActive,  SortOrder AS SO                           
 FROM #NewDivisionList                                          
 ORDER BY SortOrder;                                                  
                                                                    
   END                                                    
                                                                  
                                                  
SELECT DISTINCT                                                                  
 TemplateId INTO #TEMPLATE                                                                  
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
   ,@PCustomerId as CustomerId                      
   ,ST.IsSystem                                                               
   ,ST.IsDeleted                                                                  
   --,TSY.Level                                                                
   ,CAST(TSY.Level as INT) as Level                                                           
   ,ISNULL(SPS.CustomLineSpacing,0) as CustomLineSpacing                                                      
   ,ISNULL(SPS.DefaultSpacesId,0) as  DefaultSpacesId                                                    
   ,ISNULL(SPS.BeforeSpacesId,0) as   BeforeSpacesId                                                    
   ,ISNULL(SPS.AfterSpacesId,0) as AfterSpacesId                                                    
FROM Style ST WITH (NOLOCK)                                         
INNER JOIN TemplateStyle TSY WITH (NOLOCK)                                                                  
 ON ST.StyleId = TSY.StyleId                                                       
INNER JOIN #TEMPLATE T                                                                  
 ON TSY.TemplateId = COALESCE(T.TemplateId, 1)                                                            
LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK) ON SPS.StyleId=ST.StyleId                                                           
                                                      
-- GET SourceTagFormat                                                                             
SELECT                                                                  
 SourceTagFormat                                                                  
FROM ProjectSummary WITH (NOLOCK)                                                 
WHERE ProjectId = @PProjectId;                                                                  
                                                                  
--SELECT Header/Footer information                                                                                  
IF EXISTS (SELECT                                                           
   TOP 1 1                                                                
  FROM Header WITH (NOLOCK)                                                                
  WHERE ProjectId = @PProjectId                                                                  
  AND CustomerId = @PCustomerId                                                                  
  AND DocumentTypeId = 3)                                                                  
BEGIN                                                                  
SELECT                                                                  
 H.HeaderId                                          
   ,ISNULL(H.ProjectId, @PProjectId) AS ProjectId                                                                  
   ,ISNULL(H.SectionId, 0) AS SectionId                                                                  
   ,ISNULL(H.CustomerId, @PCustomerId) AS CustomerId                                                                  
 ,ISNULL(H.TypeId, 1) AS TypeId                                                                  
   ,H.DateFormat                                         
   ,H.TimeFormat                                                                  
   ,ISNULL(H.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                                                                  
   ,REPLACE(ISNULL(H.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader                                                                  
   ,REPLACE(ISNULL(H.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader                                                                  
   ,REPLACE(ISNULL(H.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader                                                                  
   ,REPLACE(ISNULL(H.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader                                                                  
   ,H.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId                                                                  
   ,H.IsShowLineAboveHeader AS IsShowLineAboveHeader                        
   ,H.IsShowLineBelowHeader AS   IsShowLineBelowHeader                                                             
FROM Header H  WITH (NOLOCK)                                                                
WHERE H.ProjectId = @PProjectId                                                       
AND H.CustomerId = @PCustomerId                                                                  
AND H.DocumentTypeId = 3                                                                 
END                                                        
ELSE                                                                  
BEGIN                                                                  
SELECT                                               
 H.HeaderId                                                                  
   ,ISNULL(H.ProjectId, @PProjectId) AS ProjectId                                                                  
   ,ISNULL(H.SectionId, 0) AS SectionId                                                                  
   ,ISNULL(H.CustomerId, @PCustomerId) AS CustomerId                                                                  
   ,ISNULL(H.TypeId, 1) AS TypeId                   
   ,H.DateFormat                                                                  
   ,H.TimeFormat                                                                  
   ,ISNULL(H.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                                                                  
   ,REPLACE(ISNULL(H.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader                                                                  
   ,REPLACE(ISNULL(H.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader                                                                  
   ,REPLACE(ISNULL(H.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader                                                                  
   ,REPLACE(ISNULL(H.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader                                                                  
   ,H.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId              
    ,H.IsShowLineAboveHeader AS IsShowLineAboveHeader                                                      
   ,H.IsShowLineBelowHeader AS   IsShowLineBelowHeader                                                       
FROM Header H  WITH (NOLOCK)                                                                
WHERE H.ProjectId IS NULL                                                                  
AND H.CustomerId IS NULL                                                                  
AND H.SectionId IS NULL                                                                  
AND H.DocumentTypeId = 3                                                                  
END                                
IF EXISTS (SELECT                                                                  
   TOP 1 1                                                                  
  FROM Footer WITH (NOLOCK)                                                                 
  WHERE ProjectId = @PProjectId                                                                  
  AND CustomerId = @PCustomerId                                                                  
  AND DocumentTypeId = 3)                                                                  
BEGIN                                                                  
SELECT                                                      
 F.FooterId                                                                  
   ,ISNULL(F.ProjectId, @PProjectId) AS ProjectId                                                                  
   ,ISNULL(F.SectionId, 0) AS SectionId                                                                  
   ,ISNULL(F.CustomerId, @PCustomerId) AS CustomerId                                                  
   ,ISNULL(F.TypeId, 1) AS TypeId                                                                  
   ,F.DateFormat                                                                  
   ,F.TimeFormat                                                                  
   ,ISNULL(F.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                                                 
   ,REPLACE(ISNULL(F.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter                                                                  
   ,REPLACE(ISNULL(F.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter                                                                  
   ,REPLACE(ISNULL(F.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter                                                                  
   ,REPLACE(ISNULL(F.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter                                                                  
   ,F.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId                                                                  
   ,F.IsShowLineAboveFooter AS IsShowLineAboveFooter                                                      
   ,F.IsShowLineBelowFooter AS   IsShowLineBelowFooter                                                             
                                                                  
FROM Footer F WITH (NOLOCK)                                    
WHERE F.ProjectId = @PProjectId                                                                  
AND F.CustomerId = @PCustomerId                                                                  
AND F.DocumentTypeId = 3                                    
END                                                                  
ELSE                                                                  
BEGIN                                                                  
SELECT                                                                  
 F.FooterId                                                                  
   ,ISNULL(F.ProjectId, @PProjectId) AS ProjectId                                         
   ,ISNULL(F.SectionId, 0) AS SectionId                                      
   ,ISNULL(F.CustomerId, @PCustomerId) AS CustomerId                                                                  
   ,ISNULL(F.TypeId, 1) AS TypeId                                                   
   ,F.DateFormat                                                            
   ,F.TimeFormat                                                                  
   ,ISNULL(F.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                                                                  
   ,REPLACE(ISNULL(F.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter                                                                  
   ,REPLACE(ISNULL(F.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter                                                                  
   ,REPLACE(ISNULL(F.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter                                                                  
   ,REPLACE(ISNULL(F.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter                                       
   ,F.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId                                                                  
   ,F.IsShowLineAboveFooter AS IsShowLineAboveFooter                                                      
   ,F.IsShowLineBelowFooter AS   IsShowLineBelowFooter                     
                                                                          
FROM Footer F  WITH (NOLOCK)                                                                
WHERE F.ProjectId IS NULL                              
AND F.CustomerId IS NULL                                                                  
AND F.SectionId IS NULL                                                                  
AND F.DocumentTypeId = 3                                                        
END   

 --SELECT PageSetup INFORMATION                                                                                                
 SELECT PageSetting.ProjectPageSettingId AS ProjectPageSettingId                                                            
  ,PaperSetting.ProjectPaperSettingId AS ProjectPaperSettingId                                                                            
  ,ISNULL(PageSetting.MarginTop, 1.00) AS MarginTop                                                                            
  ,ISNULL(PageSetting.MarginBottom, 1.00) AS MarginBottom                                                     
  ,ISNULL(PageSetting.MarginLeft, 1.00) AS MarginLeft                                                                            
  ,ISNULL(PageSetting.MarginRight, 1.00) AS MarginRight                                                                           
  ,ISNULL(PageSetting.EdgeHeader, 0.05) AS EdgeHeader                                    
  ,ISNULL(PageSetting.EdgeFooter, 0.05) AS EdgeFooter                                                                            
  ,PageSetting.IsMirrorMargin AS IsMirrorMargin                                                            
  ,PageSetting.ProjectId AS ProjectId                                                                            
  ,PageSetting.CustomerId AS CustomerId                                                                            
  ,ISNULL(PaperSetting.PaperName,'A4') AS PaperName                                                                            
  ,ISNULL(PaperSetting.PaperWidth, 0.00) AS PaperWidth                                                                            
  ,ISNULL(PaperSetting.PaperHeight, 0.00) AS PaperHeight                                                                            
  ,COALESCE(PaperSetting.PaperOrientation,'') AS PaperOrientation                 
  ,COALESCE(PaperSetting.PaperSource,'') AS PaperSource     
  ,ISNULL(PageSetting.SectionId,0) As SectionId
  ,ISNULL(PageSetting.TypeId,1) As  TypeId                                                                     
 FROM ProjectPageSetting PageSetting WITH (NOLOCK)                                                               
 INNER JOIN ProjectPaperSetting PaperSetting WITH (NOLOCK) 
 ON PageSetting.ProjectId = PaperSetting.ProjectId    
 AND ISNULL(PageSetting.SectionId,0) =  ISNULL(PaperSetting.SectionId,0)                                                                        
 WHERE PageSetting.ProjectId = @PProjectId                               
                                                                
--SELECT GLOBAL TERM DATA                                                                          
SELECT                                                      
@PProjectId  as  ProjectId                                                    
,@PCustomerId   as  CustomerId                                                              
, PGT.GlobalTermId                                                                      
   ,COALESCE(PGT.mGlobalTermId, 0) AS mGlobalTermId                                                                      
   ,PGT.Name                                                                      
   ,ISNULL(PGT.value, '') AS value                                                                      
   ,PGT.CreatedDate                                                                      
   ,PGT.CreatedBy                                                                      
   ,PGT.ModifiedDate                                                                      
   ,PGT.ModifiedBy                                                                      
   ,PGT.GlobalTermSource                                                                      
   ,isnull(PGT.GlobalTermCode ,0) as  GlobalTermCode                                                                  
   ,COALESCE(PGT.UserGlobalTermId, 0) AS UserGlobalTermId                                                                      
   ,GlobalTermFieldTypeId  as GTFieldType                                                                     
FROM ProjectGlobalTerm PGT WITH (NOLOCK)                                                                      
WHERE PGT.ProjectId = @PProjectId                                                                      
AND PGT.CustomerId = @PCustomerId;                                                             
                                                      
--SELECT IMAGES DATA                                                      
 SELECT                                                             
  PIMG.SegmentImageId                                                            
 ,IMG.ImageId                    
 ,IMG.ImagePath                                                            
 ,COALESCE(PIMG.ImageStyle,'')  as ImageStyle                                                          
 ,PIMG.SectionId                                       
 ,isnull(IMG.LuImageSourceTypeId ,0) as LuImageSourceTypeId                                                           
 FROM ProjectSegmentImage PIMG WITH (NOLOCK)                                                          
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PIMG.ImageId = IMG.ImageId                                                                            
 WHERE PIMG.ProjectId = @PProjectId                                                                  
  AND PIMG.CustomerId = @PCustomerId                                                                  
  AND IMG.LuImageSourceTypeId IN(@ImagSegment,@ImageHeaderFooter)                                                         
END 