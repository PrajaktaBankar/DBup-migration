CREATE PROCEDURE [dbo].[usp_GetSegmentsForCommentsReport]                     
(                    
@ProjectId INT,                    
@CustomerId INT,                                       
@TCPrintModeId INT = 0,              
@SectionIdList NVARCHAR(MAX)              
)                        
AS                        
BEGIN  

DROP TABLE IF EXISTS #SegmentStatusIds
DROP TABLE IF EXISTS #CommentedSegment
DROP TABLE IF EXISTS #CommentReport
DROP TABLE IF EXISTS #DapperChoiceTbl
  
DECLARE @PProjectId INT = @ProjectId;  
DECLARE @PCustomerId INT = @CustomerId;   
DECLARE @PTCPrintModeId INT = 0;  
DECLARE @SegmentTypeId INT = 1;  
DECLARE @HeaderFooterTypeId INT = 3; 
DECLARE @PSectionIdList NVARCHAR(MAX) = @SectionIdList;

DROP TABLE IF EXISTS #SectionIdTbl;

-- Get section ids in table format
SELECT splitdata AS SectionId 
INTO #SectionIdTbl
FROM dbo.fn_SplitString(@PSectionIdList, ',');
            
CREATE table #SegmentStatusIds (SegmentStatusId bigint);  

-- Get SegmentsStatusIds with comments  
INSERT INTO #SegmentStatusIds (SegmentStatusId)  
 (SELECT DISTINCT SC.SegmentStatusId
	FROM SegmentComment SC WITH(NOLOCK) 
	INNER JOIN #SectionIdTbl S WITH(NOLOCK) ON S.SectionId = SC.SectionId
	WHERE SC.CustomerId = @PCustomerId AND SC.ProjectId = @PProjectId
	AND ISNULL(SC.IsDeleted, 0) = 0
  );  

 -- Get ProjectSegmentStatus data 
(SELECT  
 PSS.SegmentStatusId  
   ,PSS.SectionId  
   ,PSS.ParentSegmentStatusId  
   ,PSS.mSegmentStatusId  
   ,PSS.mSegmentId  
   ,PSS.SegmentId  
   ,PSS.SegmentSource  
   ,PSS.SegmentOrigin  
   ,PSS.IndentLevel  
   ,PSS.SequenceNumber  
   ,PSS.SpecTypeTagId  
   ,PSS.SegmentStatusTypeId  
   ,PSS.IsParentSegmentStatusActive  
   ,PSS.ProjectId  
   ,PSS.CustomerId  
   ,PSS.SegmentStatusCode  
   ,PSS.IsShowAutoNumber  
   ,PSS.IsRefStdParagraph  
   ,PSS.FormattingJson  
   ,PSS.CreateDate  
   ,PSS.CreatedBy  
   ,PSS.ModifiedDate  
   ,PSS.ModifiedBy  
   ,PSS.IsPageBreak  
   ,PSS.IsDeleted  
   ,PSS.TrackOriginOrder  
   ,PSS.mTrackDescription INTO #CommentedSegment  
FROM ProjectSegmentStatus PSS WITH (NOLOCK)  
WHERE PSS.CustomerId = @PCustomerId
AND   PSS.ProjectId = @PProjectId
AND ISNULL(PSS.IsDeleted, 0) = 0
AND PSS.SegmentStatusId IN (SELECT  
  SegmentStatusId  
 FROM #SegmentStatusIds)  
);  

-- Get SegmentStatus data
WITH SegmentStatus (SegmentStatusId, SectionId, ParentSegmentStatusId, SegmentOrigin, IndentLevel, SequenceNumber, SegmentDescription)  
AS  
(SELECT  
  SegmentStatusId  
    ,SectionId  
    ,ParentSegmentStatusId  
    ,SegmentOrigin  
    ,IndentLevel  
    ,SequenceNumber  
    ,CAST(NULL AS NVARCHAR(MAX)) AS SegmentDescription  
 FROM ProjectSegmentStatus WITH (NOLOCK)  
 WHERE SegmentStatusId IN (SELECT  
   SegmentStatusId  
  FROM #CommentedSegment)  
 UNION ALL  
 SELECT  
  PSS.SegmentStatusId  
    ,PSS.SectionId  
    ,PSS.ParentSegmentStatusId  
    ,PSS.SegmentOrigin  
    ,PSS.IndentLevel  
    ,PSS.SequenceNumber  
    ,NULL AS SegmentDescription  
 FROM ProjectSegmentStatus PSS WITH (NOLOCK)  
 JOIN SegmentStatus SG  
  ON PSS.SegmentStatusId = SG.ParentSegmentStatusId )  
  
SELECT 
 * INTO #CommentReport  
FROM SegmentStatus;  

-- Update SegmentDescription
UPDATE SS  
SET SS.SegmentDescription = pssv.SegmentDescription  
FROM #CommentReport SS  
INNER JOIN ProjectSegmentStatusView pssv WITH (NOLOCK)  
 ON pssv.SegmentStatusId = SS.SegmentStatusId;  
   
DECLARE @MasterDataTypeId INT = (SELECT  
  P.MasterDataTypeId  
 FROM Project P WITH (NOLOCK)  
 WHERE P.ProjectId = @PProjectId  
 AND P.CustomerId = @PCustomerId);  
  
DECLARE @SectionIdTbl TABLE (  
 SectionId INT  
);  
DECLARE @CatalogueTypeTbl TABLE (  
 TagType NVARCHAR(MAX)  
);  
DECLARE @OldKeywordFormat NVARCHAR(MAX) = '{\kw\';  
DECLARE @NewKeywordFormat NVARCHAR(MAX) = '{KW#';  
  
DECLARE @Lu_InheritFromSection INT = 1;  
DECLARE @Lu_AllWithMarkups INT = 2;  
DECLARE @Lu_AllWithoutMarkups INT = 3;  
  
--CONVERT STRING INTO TABLE                        
INSERT INTO @SectionIdTbl (SectionId)  
 SELECT DISTINCT  
  SectionId  
 FROM #CommentReport;  
  
--DROP TEMP TABLES IF PRESENT                        
DROP TABLE IF EXISTS #tmp_ProjectSegmentStatus;  
DROP TABLE IF EXISTS #tmp_Template;  
DROP TABLE IF EXISTS #tmp_SelectedChoiceOption;  
DROP TABLE IF EXISTS #tmp_SortedProjectSection;  
DROP TABLE IF EXISTS #tmp_ProjectSection;  
  
--FETCH SECTIONS DATA IN TEMP TABLE              
SELECT  
 PS.SectionId  
   ,PS.ParentSectionId  
   ,PS.mSectionId  
   ,PS.ProjectId  
   ,PS.CustomerId  
   ,PS.UserId  
   ,PS.DivisionId  
   ,PS.DivisionCode  
   ,PS.Description  
   ,PS.LevelId  
   ,PS.IsLastLevel  
   ,PS.SourceTag  
   ,PS.Author  
   ,PS.TemplateId  
   ,PS.SectionCode  
   ,PS.IsDeleted  
   ,PS.SpecViewModeId  
   ,PS.IsTrackChanges
   ,ISNULL(PS.IsHidden,0) AS IsHidden
   ,PS.SortOrder  
   ,0 AS SubFolderSortOrder  
   ,0 AS FolderSortOrder  
   ,0 AS FolderSectionId INTO #tmp_SortedProjectSection  
FROM ProjectSection PS WITH (NOLOCK)  
WHERE PS.CustomerId = @PCustomerId
AND PS.ProjectId = @PProjectId  
AND ISNULL(PS.IsDeleted,0) =0;  
  
  --Update SubfolderSortOrder        
 UPDATE section SET section.FolderSectionId = subF.ParentSectionId , section.SubFolderSortOrder = ISNULL(subF.SortOrder,0) FROM #tmp_SortedProjectSection section  
 INNER JOIN #tmp_SortedProjectSection subF WITH(NOLOCK)      
 ON section.ParentSectionId = subF.SectionId WHERE subF.CustomerId = @PCustomerId AND subF.ProjectId = @PProjectId;       
      
 --Update Folder Sort Order        
 UPDATE section SET section.FolderSortOrder = ISNULL(folder.SortOrder,0) FROM #tmp_SortedProjectSection section INNER JOIN #tmp_SortedProjectSection folder WITH(NOLOCK)      
 ON section.FolderSectionId = folder.SectionId WHERE folder.CustomerId = @PCustomerId AND folder.ProjectId = @PProjectId;       
      
 SELECT sPS.* INTO #tmp_ProjectSection from #tmp_SortedProjectSection  sPS order BY FolderSortOrder, SubFolderSortOrder, SortOrder;  
  
--FETCH SEGMENT STATUS DATA INTO TEMP TABLE                 
SELECT  
 PSST.SegmentStatusId  
   ,PSST.SectionId  
   ,PSST.ParentSegmentStatusId  
   ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId  
   ,ISNULL(PSST.mSegmentId, 0) AS mSegmentId  
   ,ISNULL(PSST.SegmentId, 0) AS SegmentId  
   ,PSST.SegmentSource  
   ,TRIM(CONVERT(NCHAR(2), PSST.SegmentOrigin)) AS SegmentOrigin  
   ,CASE  
  WHEN PSST.IndentLevel > 8 THEN CAST(8 AS TINYINT)  
  ELSE PSST.IndentLevel  
 END AS IndentLevel  
   ,PSST.SequenceNumber  
   ,PSST.SegmentStatusTypeId  
   ,ISNULL(PSST.SegmentStatusCode,0) as SegmentStatusCode  
   ,PSST.IsParentSegmentStatusActive  
   ,PSST.IsShowAutoNumber  
   ,COALESCE(PSST.FormattingJson,'') as FormattingJson                    
   ,ISNULL(PSST.SpecTypeTagId, 0) AS SpecTypeTagId  
   ,PSST.IsRefStdParagraph  
   ,PSST.IsPageBreak  
   ,ISNULL(PSST.TrackOriginOrder, '') AS TrackOriginOrder INTO #tmp_ProjectSegmentStatus  
FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)  
  WHERE PSST.CustomerId = @PCustomerId
AND PSST.ProjectId = @PProjectId     
AND (PSST.IsDeleted IS NULL  
OR PSST.IsDeleted = 0)  
AND PSST.SegmentStatusId IN (SELECT  
  SegmentStatusId  
 FROM #CommentReport)  
 
  --delete sections which parent folders are hidden    
 DELETE PSS 
 FROM #tmp_ProjectSegmentStatus PSS WITH (NOLOCK)    
 INNER JOIN #tmp_ProjectSection PS1 WITH (NOLOCK)
 ON PSS.SectionId = PS1.SectionId
 --AND PS1.IsLastLevel = 1 
 INNER JOIN #tmp_ProjectSection PS2 WITH (NOLOCK)    
  ON PS2.SectionId = PS1.ParentSectionId    
  INNER JOIN #tmp_ProjectSection PS3 WITH (NOLOCK)    
  ON PS3.SectionId = PS2.ParentSectionId    
  WHERE PS1.IsHidden = 1 OR PS2.IsHidden = 1 OR PS3.IsHidden = 1    
  
--SELECT SEGMENT STATUS DATA              
SELECT  
 *,@PProjectId as ProjectId,@PCustomerId as CustomerId  
FROM #tmp_ProjectSegmentStatus PSST  
ORDER BY PSST.SectionId, PSST.SequenceNumber  
--SELECT SEGMENT DATA               
SELECT  
 PSST.SegmentId  
   ,PSST.SegmentStatusId  
   ,PSST.SectionId  
   ,(CASE  
  WHEN @PTCPrintModeId = @Lu_AllWithoutMarkups THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')  
  WHEN @PTCPrintModeId = @Lu_AllWithMarkups THEN COALESCE(PSG.SegmentDescription, '')  
  WHEN @PTCPrintModeId = @Lu_InheritFromSection AND  
   PS.IsTrackChanges = 1 THEN COALESCE(PSG.SegmentDescription, '')  
  WHEN @PTCPrintModeId = @Lu_InheritFromSection AND  
   PS.IsTrackChanges = 0 THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')  
  ELSE COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')  
 END) AS SegmentDescription  
   ,PSG.SegmentSource  
   ,ISNULL(PSG.SegmentCode,0) as SegmentCode  
   ,@PProjectId as ProjectId  
   ,@PCustomerId as CustomerId  
FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)  
INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK)  
 ON PSST.SectionId = PS.SectionId  
INNER JOIN ProjectSegment AS PSG WITH (NOLOCK)  
 ON PSST.SegmentId = PSG.SegmentId  
INNER JOIN #CommentReport TR  
 ON TR.SectionId = PS.SectionId  
WHERE PSG.CustomerId = @PCustomerId
AND PSG.ProjectId = @PProjectId    
  
UNION  

SELECT  
 MSG.SegmentId  
   ,PSST.SegmentStatusId  
   ,PSST.SectionId  
   ,CASE  
  WHEN PSST.ParentSegmentStatusId = 0 AND  
   PSST.SequenceNumber = 0 THEN PS.Description  
  ELSE ISNULL(MSG.SegmentDescription, '')  
 END AS SegmentDescription  
   ,MSG.SegmentSource  
   ,ISNULL(MSG.SegmentCode,0) as SegmentCode  
   ,@PProjectId as ProjectId  
   ,@PCustomerId as CustomerId  
FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)  
INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK)  
 ON PSST.SectionId = PS.SectionId  
INNER JOIN SLCMaster..Segment AS MSG WITH (NOLOCK)  
 ON PSST.mSegmentId = MSG.SegmentId  
INNER JOIN #CommentReport TR  
 ON TR.SectionId = PS.SectionId  
WHERE PS.CustomerId = @PCustomerId    
AND PS.ProjectId = @PProjectId
  
--FETCH TEMPLATE DATA INTO TEMP TABLE                        
SELECT  
 * INTO #tmp_Template  
FROM (SELECT  
  T.TemplateId  
    ,T.Name  
    ,T.TitleFormatId  
    ,T.SequenceNumbering  
    ,T.IsSystem  
    ,T.IsDeleted  
    ,0 AS SectionId  
    ,CAST(1 AS BIT) AS IsDefault  
 FROM Template T WITH (NOLOCK)  
 INNER JOIN Project P WITH (NOLOCK)  
  ON T.TemplateId = COALESCE(P.TemplateId, 1)  
  
 WHERE P.CustomerId = @PCustomerId  
 AND P.ProjectId = @PProjectId) AS X  
  
--SELECT TEMPLATE DATA                       
SELECT  
 *,@PCustomerId as CustomerId  
FROM #tmp_Template T  
  
--SELECT TEMPLATE STYLE DATA                    
  
SELECT  
 TS.TemplateStyleId  
   ,TS.TemplateId  
   ,TS.StyleId  
   ,TS.Level  
   ,@PCustomerId as CustomerId  
FROM TemplateStyle TS WITH (NOLOCK)  
INNER JOIN #tmp_Template T WITH (NOLOCK)  
 ON TS.TemplateId = T.TemplateId  
  
--SELECT STYLE DATA                        
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
   ,CAST(TS.Level AS INT) AS Level  
   ,ISNULL(SPS.CustomLineSpacing,0) as CustomLineSpacing  
   ,ISNULL(SPS.DefaultSpacesId,0) as  DefaultSpacesId  
  ,ISNULL(SPS.BeforeSpacesId,0) as   BeforeSpacesId  
  ,ISNULL(SPS.AfterSpacesId,0) as AfterSpacesId  
  ,@PCustomerId as CustomerId  
FROM Style AS ST WITH (NOLOCK)  
INNER JOIN TemplateStyle AS TS WITH (NOLOCK)  
 ON ST.StyleId = TS.StyleId  
INNER JOIN #tmp_Template T WITH (NOLOCK)  
 ON TS.TemplateId = T.TemplateId  
LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK) ON SPS.StyleId=ST.StyleId   
  
--FETCH SelectedChoiceOption INTO TEMP TABLE               
SELECT DISTINCT  
 SCHOP.SegmentChoiceCode  
   ,SCHOP.ChoiceOptionCode  
   ,SCHOP.ChoiceOptionSource  
   ,SCHOP.IsSelected  
   ,SCHOP.ProjectId  
   ,SCHOP.SectionId  
   ,SCHOP.CustomerId  
   ,0 AS SelectedChoiceOptionId  
   ,SCHOP.OptionJson INTO #tmp_SelectedChoiceOption  
FROM SelectedChoiceOption SCHOP WITH (NOLOCK)  
INNER JOIN @SectionIdTbl SIDTBL  
 ON SCHOP.SectionId = SIDTBL.SectionId  
WHERE SCHOP.ProjectId = @PProjectId  
AND SCHOP.CustomerId = @PCustomerId  
AND ISNULL(SCHOP.IsDeleted, 0) = 0  

--FETCH MASTER + USER CHOICES AND THEIR OPTIONS               
SELECT  
 0 AS SegmentId  
   ,MCH.SegmentId AS mSegmentId  
   ,MCH.ChoiceTypeId  
   ,'M' AS ChoiceSource  
   ,ISNULL(MCH.SegmentChoiceCode, 0) AS SegmentChoiceCode  
   ,ISNULL(MCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode  
   ,PSCHOP.IsSelected  
   ,PSCHOP.ChoiceOptionSource  
   ,CASE  
  WHEN PSCHOP.IsSelected = 1 AND  
   PSCHOP.OptionJson IS NOT NULL THEN PSCHOP.OptionJson  
  ELSE MCHOP.OptionJson  
 END AS OptionJson  
   ,MCHOP.SortOrder  
   ,MCH.SegmentChoiceId  
   ,MCHOP.ChoiceOptionId  
   ,PSCHOP.SelectedChoiceOptionId  
   ,PSST.SectionId into #DapperChoiceTbl  
FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)  
INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK)  
 ON PSST.mSegmentId = MCH.SegmentId  
INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)  
 ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId  
INNER JOIN #tmp_SelectedChoiceOption PSCHOP WITH (NOLOCK)  
 ON MCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode  
  AND MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode  
  AND PSCHOP.ChoiceOptionSource = 'M'  
UNION  
SELECT  
 PCH.SegmentId  
   ,0 AS mSegmentId  
   ,PCH.ChoiceTypeId  
   ,PCH.SegmentChoiceSource AS ChoiceSource  
   ,ISNULL(PCH.SegmentChoiceCode, 0) AS SegmentChoiceCode  
   ,ISNULL(PCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode  
   ,PSCHOP.IsSelected  
   ,PSCHOP.ChoiceOptionSource  
   ,PCHOP.OptionJson  
   ,PCHOP.SortOrder  
   ,PCH.SegmentChoiceId  
   ,PCHOP.ChoiceOptionId  
   ,PSCHOP.SelectedChoiceOptionId  
   ,PSST.SectionId  
FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)  
INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)  
 ON PSST.SegmentId = PCH.SegmentId  
  AND ISNULL(PCH.IsDeleted, 0) = 0  
INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)  
 ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId  
  AND ISNULL(PCHOP.IsDeleted, 0) = 0  
INNER JOIN #tmp_SelectedChoiceOption PSCHOP WITH (NOLOCK)  
 ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode  
  AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode  
  AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource  
  AND PSCHOP.ChoiceOptionSource = 'U'  
WHERE PCH.CustomerId = @PCustomerId    
AND PCH.ProjectId = @PProjectId
AND PCHOP.CustomerId = @PCustomerId   
AND PCHOP.ProjectId = @PProjectId
  
SELECT SegmentId,MSegmentId,ChoiceTypeId,ChoiceSource,SegmentChoiceCode,SegmentChoiceId, @PProjectId as ProjectId , @PCustomerId as CustomerId  
,SectionId  
FROM #DapperChoiceTbl  
  
SELECT ChoiceOptionCode,IsSelected,SegmentChoiceCode,ChoiceOptionSource,ChoiceOptionId,SortOrder,SelectedChoiceOptionId, @PProjectId as ProjectId , @PCustomerId as CustomerId  
,SectionId,OptionJson  
FROM #DapperChoiceTbl  
  
--SELECT GLOBAL TERM DATA                   
SELECT  
 PGT.GlobalTermId  
   ,COALESCE(PGT.mGlobalTermId, 0) AS mGlobalTermId  
   ,PGT.Name  
   ,ISNULL(PGT.value, '') AS value  
   ,PGT.CreatedDate  
   ,PGT.CreatedBy  
   ,PGT.ModifiedDate  
   ,PGT.ModifiedBy  
   ,PGT.GlobalTermSource  
   ,isnull(PGT.GlobalTermCode,0) as GlobalTermCode  
   ,COALESCE(PGT.UserGlobalTermId, 0) AS UserGlobalTermId  
   ,GlobalTermFieldTypeId as GTFieldType  
   ,@PProjectId as ProjectId   
   ,@PCustomerId as CustomerId  
FROM ProjectGlobalTerm PGT WITH (NOLOCK)  
WHERE PGT.CustomerId = @PCustomerId  
AND PGT.ProjectId = @PProjectId;  
  
--SELECT SECTIONS DATA                  
  
;WITH Section_CTE AS  
(SELECT  
 S.SectionId AS SectionId  
   ,ISNULL(S.mSectionId, 0) AS mSectionId  
   ,S.Description  
   ,S.Author  
   ,ISNULL(S.SectionCode,0) AS SectionCode  
   ,ISNULL(S.SourceTag,'') as SourceTag  
   ,PS.SourceTagFormat  
   ,ISNULL(D.DivisionCode, '') AS DivisionCode  
   ,ISNULL(D.DivisionTitle, '') AS DivisionTitle  
   ,ISNULL(D.DivisionId, 0) AS DivisionId  
   ,ISNULL(S.IsTrackChanges,CONVERT(BIT, 0)) as IsTrackChanges  
   ,S.FolderSortOrder  
   ,S.SubFolderSortOrder  
   ,S.SortOrder  
FROM #tmp_ProjectSection AS S WITH (NOLOCK)  
LEFT JOIN SLCMaster..Division D WITH (NOLOCK)  
 ON S.DivisionId = D.DivisionId  
INNER JOIN ProjectSummary PS WITH (NOLOCK)  
 ON S.ProjectId = PS.ProjectId  
  AND S.CustomerId = PS.CustomerId  
WHERE S.CustomerId = @PCustomerId
AND S.ProjectId = @PProjectId    
AND S.IsLastLevel = 1  
UNION  
SELECT  
 0 AS SectionId  
   ,MS.SectionId AS mSectionId  
   ,MS.Description  
   ,MS.Author  
   ,ISNULL(MS.SectionCode,0) as SectionCode  
   ,ISNULL(MS.SourceTag,'') as SourceTag  
   ,P.SourceTagFormat  
   ,ISNULL(D.DivisionCode, '') AS DivisionCode  
   ,ISNULL(D.DivisionTitle, '') AS DivisionTitle  
   ,ISNULL(D.DivisionId, 0) AS DivisionId  
   ,CONVERT(BIT, 0) AS IsTrackChanges  
   ,ISNULL(PS.FolderSortOrder,0) AS FolderSortOrder  
   ,ISNULL(PS.SubFolderSortOrder,0) AS SubFolderSortOrder  
   ,ISNULL(PS.SortOrder,0) AS SortOrder  
FROM SLCMaster..Section MS WITH (NOLOCK)  
LEFT JOIN SLCMaster..Division D WITH (NOLOCK)  
 ON MS.DivisionId = D.DivisionId  
INNER JOIN ProjectSummary P WITH (NOLOCK)  
 ON P.ProjectId = @PProjectId  
  AND P.CustomerId = @PCustomerId  
LEFT JOIN #tmp_ProjectSection PS WITH (NOLOCK)  
 ON MS.SectionId = PS.mSectionId  
  AND PS.CustomerId = @PCustomerId    
  AND PS.ProjectId = @PProjectId
WHERE MS.MasterDataTypeId = @MasterDataTypeId  
AND MS.IsLastLevel = 1  
AND PS.SectionId IS NULL)  
SELECT * FROM Section_CTE ORDER BY FolderSortOrder, SubFolderSortOrder, SortOrder;   
  
--SELECT SEGMENT REQUIREMENT TAGS DATA               
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
 END AS IsMasterAppliedTag  
   ,PSST.SectionId  
FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)  
 ON PSRT.RequirementTagId = LPRT.RequirementTagId  
INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)  
 ON PSRT.SegmentStatusId = PSST.SegmentStatusId  
WHERE PSRT.CustomerId = @PCustomerId
AND PSRT.ProjectId = @PProjectId    
  
--SELECT REQUIRED IMAGES DATA               
SELECT  
 IMG.ImageId  
   ,IMG.ImagePath  
   ,PIMG.SectionId  
   ,ISNULL(PIMG.ImageStyle,'') as ImageStyle  
   ,IMG.LuImageSourceTypeId  
FROM ProjectSegmentImage PIMG WITH (NOLOCK)  
INNER JOIN ProjectImage IMG WITH (NOLOCK)  
 ON PIMG.ImageId = IMG.ImageId  
--INNER JOIN @SectionIdTbl SIDTBL ON PIMG.SectionId = SIDTBL.SectionId //To resolved cross section images in headerFooter  
WHERE PIMG.CustomerId = @PCustomerId    
AND PIMG.ProjectId = @PProjectId
AND IMG.LuImageSourceTypeId in (@SegmentTypeId,@HeaderFooterTypeId)  
UNION ALL -- This union to ge Note images    
 SELECT             
 PN.ImageId            
 ,IMG.ImagePath            
 ,PN.SectionId             
 ,'' ImageStyle            
 ,IMG.LuImageSourceTypeId     
 FROM ProjectNoteImage PN  WITH (NOLOCK)         
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PN.ImageId = IMG.ImageId    
 INNER JOIN @SectionIdTbl SIDTBL ON PN.SectionId = SIDTBL.SectionId    
 WHERE PN.CustomerId = @PCustomerId                      
  AND PN.ProjectId = @PProjectId
  
--SELECT HYPERLINKS DATA                        
SELECT  
 HLNK.HyperLinkId  
   ,HLNK.LinkTarget  
   ,HLNK.LinkText  
   ,'U' AS Source  
   ,HLNK.SectionId  
FROM ProjectHyperLink HLNK WITH (NOLOCK)  
INNER JOIN @SectionIdTbl SIDTBL  
 ON HLNK.SectionId = SIDTBL.SectionId  
WHERE HLNK.CustomerId = @PCustomerId    
AND HLNK.ProjectId = @PProjectId
  
--SELECT SEGMENT USER TAGS DATA               
SELECT  
 PSUT.SegmentUserTagId  
   ,PSUT.SegmentStatusId  
   ,PSUT.UserTagId  
   ,PUT.TagType  
   ,PUT.Description AS TagName  
   ,PSUT.SectionId  
FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)  
INNER JOIN ProjectUserTag PUT WITH (NOLOCK)  
 ON PSUT.UserTagId = PUT.UserTagId  
INNER JOIN #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)  
 ON PSUT.SegmentStatusId = PSST.SegmentStatusId  
WHERE PSUT.CustomerId = @PCustomerId AND PSUT.ProjectId = @PProjectId
  
--SELECT Project Summary information              
SELECT  
 P.ProjectId AS ProjectId  
   ,P.Name AS ProjectName  
   ,'' AS ProjectLocation  
   ,PS.IsPrintReferenceEditionDate AS IsPrintReferenceEditionDate  
   ,PS.SourceTagFormat AS SourceTagFormat  
   ,COALESCE(LState.StateProvinceAbbreviation, PA.StateProvinceName) + ', ' + COALESCE(LCity.City, PA.CityName) AS DbInfoProjectLocationKeyword  
   ,ISNULL(PGT.value, '') AS ProjectLocationKeyword  
   ,PS.UnitOfMeasureValueTypeId  
FROM Project P WITH (NOLOCK)  
INNER JOIN ProjectSummary PS WITH (NOLOCK)  
 ON P.ProjectId = PS.ProjectId  
INNER JOIN ProjectAddress PA WITH (NOLOCK)  
 ON P.ProjectId = PA.ProjectId  
INNER JOIN LuCountry LCountry WITH (NOLOCK)  
 ON PA.CountryId = LCountry.CountryId  
LEFT JOIN LuStateProvince LState WITH (NOLOCK)  
 ON PA.StateProvinceId = LState.StateProvinceID  
LEFT JOIN LuCity LCity WITH (NOLOCK)  
 ON PA.CityId = LCity.CityId  
LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK)  
 ON P.ProjectId = PGT.ProjectId  
  AND PGT.mGlobalTermId = 11  
WHERE P.CustomerId = @PCustomerId    
AND P.ProjectId = @PProjectId
  
--SELECT Header/Footer information                        
IF EXISTS (SELECT  
  TOP 1  
   1  
  FROM Header WITH (NOLOCK)  
  WHERE CustomerId = @PCustomerId    
  AND ProjectId = @PProjectId
  AND DocumentTypeId = 2)  
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
   ,H.IsShowLineBelowHeader AS IsShowLineBelowHeader  
FROM Header H WITH (NOLOCK)  
WHERE H.CustomerId = @PCustomerId    
AND H.ProjectId = @PProjectId
AND H.DocumentTypeId = 2  
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
   ,H.IsShowLineBelowHeader AS IsShowLineBelowHeader  
FROM Header H WITH (NOLOCK)  
WHERE H.ProjectId IS NULL  
AND H.CustomerId IS NULL  
AND H.SectionId IS NULL  
AND H.DocumentTypeId = 2  
END  
IF EXISTS (SELECT  
  TOP 1  
   1  
  FROM Footer WITH (NOLOCK)  
  WHERE CustomerId = @PCustomerId  
  AND ProjectId = @PProjectId 
  AND DocumentTypeId = 2)  
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
   ,F.IsShowLineBelowFooter AS IsShowLineBelowFooter  
  
FROM Footer F WITH (NOLOCK)  
WHERE F.CustomerId = @PCustomerId    
AND F.ProjectId = @PProjectId
AND F.DocumentTypeId = 2  
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
   ,F.IsShowLineBelowFooter AS IsShowLineBelowFooter  
FROM Footer F WITH (NOLOCK)  
WHERE F.ProjectId IS NULL  
AND F.CustomerId IS NULL  
AND F.SectionId IS NULL  
AND F.DocumentTypeId = 2  
END  
--SELECT PageSetup INFORMATION                    
SELECT  
 PageSetting.ProjectPageSettingId AS ProjectPageSettingId  
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
   ,ISNULL(PaperSetting.PaperOrientation,'') AS PaperOrientation  
   ,ISNULL(PaperSetting.PaperSource,'') AS PaperSource  
   ,ISNULL(PageSetting.SectionId,0) As SectionId
  ,ISNULL(PageSetting.TypeId,1) As  TypeId 
FROM ProjectPageSetting PageSetting WITH (NOLOCK)  
INNER JOIN ProjectPaperSetting PaperSetting WITH (NOLOCK)  
 ON PageSetting.ProjectId = PaperSetting.ProjectId  
 AND ISNULL(PageSetting.SectionId,0) =  ISNULL(PaperSetting.SectionId,0) 
WHERE PageSetting.ProjectId = @PProjectId  
END
