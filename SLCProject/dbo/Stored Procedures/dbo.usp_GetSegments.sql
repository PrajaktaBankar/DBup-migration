CREATE PROCEDURE [dbo].[usp_GetSegments]                  
@ProjectId INT NULL, @SectionId INT NULL, @CustomerId INT NULL, @UserId INT NULL, @CatalogueType NVARCHAR (50) NULL='FS'                            
AS                            
BEGIN                  
DECLARE @PProjectId INT = @ProjectId;                  
DECLARE @PSectionId INT = @SectionId;                  
DECLARE @PCustomerId INT = @CustomerId;                  
DECLARE @PUserId INT = @UserId;                  
DECLARE @PCatalogueType NVARCHAR (50) = @CatalogueType;                  
                  
SET NOCOUNT ON;                  
                   
--CatalogueTypeTbl table                  
DECLARE @CatalogueTypeTbl TABLE (                  
 TagType NVARCHAR(MAX)                  
);                  
                  
IF @PCatalogueType IS NOT NULL AND @PCatalogueType != 'FS'                  
BEGIN                  
INSERT INTO @CatalogueTypeTbl (TagType)                  
 SELECT                  
  *                  
 FROM dbo.fn_SplitString(@PCatalogueType, ',');                  
                  
IF EXISTS (SELECT                  
   *                  
  FROM @CatalogueTypeTbl                  
  WHERE TagType = 'OL')                  
BEGIN                  
INSERT INTO @CatalogueTypeTbl                  
 VALUES ('UO')                  
END                  
IF EXISTS (SELECT                  
   *                  
  FROM @CatalogueTypeTbl                  
  WHERE TagType = 'SF')                  
BEGIN                  
INSERT INTO @CatalogueTypeTbl                  
 VALUES ('US')                  
END                  
END                  
                  
--Set mSectionId                    
DECLARE @MasterSectionId AS INT;                  
SET @MasterSectionId = (SELECT TOP 1                  
  mSectionId                  
 FROM ProjectSection WITH (NOLOCK)                  
 WHERE SectionId = @PSectionId                  
 AND ProjectId = @PProjectId                  
 AND CustomerId = @PCustomerId);                  
                           
--FIND TEMPLATE ID FROM                     
DECLARE @ProjectTemplateId AS INT = ( SELECT TOP 1                  
  ISNULL(TemplateId, 1)                  
 FROM Project WITH (NOLOCK)                  
 WHERE ProjectId = @PProjectId                  
 AND CustomerId = @PCustomerId);                  
                  
DECLARE @SectionTemplateId AS INT = ( SELECT TOP 1                  
  TemplateId                  
 FROM ProjectSection WITH (NOLOCK)                  
 WHERE SectionId = @PSectionId);                  
                  
DECLARE @DocumentTemplateId INT = 0;                  
                  
IF (@SectionTemplateId IS NOT NULL                  
 AND @SectionTemplateId > 0)                  
BEGIN                  
SET @DocumentTemplateId = @SectionTemplateId;                  
END                    
ELSE                    
BEGIN                  
SET @DocumentTemplateId = @ProjectTemplateId;                  
END                  
                    
DECLARE @MasterDataTypeId INT;                  
SET @MasterDataTypeId = (SELECT TOP 1                  
  MasterDataTypeId                  
 FROM Project WITH (NOLOCK)                  
 WHERE ProjectId = @PProjectId                  
 AND CustomerId = @PCustomerId);                  
                  
EXECUTE usp_MapSegmentStatusFromMasterToProject @ProjectId = @PProjectId                  
              ,@SectionId = @PSectionId                  
              ,@CustomerId = @PCustomerId                  
              ,@UserId = @PUserId;                  
EXECUTE usp_MapSegmentChoiceFromMasterToProject @ProjectId = @PProjectId                  
              ,@SectionId = @PSectionId                  
              ,@CustomerId = @PCustomerId                  
              ,@UserId = @PUserId;                  
EXECUTE usp_MapProjectRefStands @ProjectId = @PProjectId                  
          ,@SectionId = @PSectionId                  
          ,@CustomerId = @PCustomerId                  
          ,@UserId = @PUserId;                  
EXECUTE usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @PProjectId                  
                ,@SectionId = @PSectionId                  
                ,@CustomerId = @PCustomerId                  
                ,@UserId = @PUserId;                  
EXECUTE usp_MapSegmentLinkFromMasterToProject @ProjectId = @PProjectId                
            ,@SectionId = @PSectionId                  
            ,@CustomerId = @PCustomerId                  
            ,@UserId = @PUserId;                  
EXECUTE usp_UpdateSegmentStatus_ApplyMasterUpdate @ProjectId = @PProjectId                  
             ,@CustomerId = @PCustomerId                  
             ,@SectionId = @PSectionId                  
EXECUTE usp_DeleteSegmentRequirementTag_ApplyMasterUpdate @ProjectId = @PProjectId                  
               ,@CustomerId = @PCustomerId                  
               ,@SectionId = @PSectionId                  
                  
DROP TABLE IF EXISTS #tmp_ProjectSegmentStatus;                  
SELECT                  
 PSS.ProjectId                  
   ,PSS.CustomerId                  
   ,PSS.SegmentStatusId                  
   ,PSS.SectionId                  
   ,CONVERT(BIGINT,PSS.ParentSegmentStatusId) as ParentSegmentStatusId              
   ,ISNULL(PSS.mSegmentStatusId, 0) AS mSegmentStatusId                  
   ,ISNULL(PSS.mSegmentId, 0) AS mSegmentId                  
   ,ISNULL(PSS.SegmentId, 0) AS SegmentId                  
   ,PSS.SegmentSource                  
   ,CONVERT(nvarchar(2),trim(PSS.SegmentOrigin)) as SegmentOrigin          
   ,PSS.IndentLevel                  
   ,ISNULL(MSST.IndentLevel, 0) AS MasterIndentLevel                  
   ,PSS.SequenceNumber                  
   ,PSS.SegmentStatusTypeId                  
   ,PSS.SegmentStatusCode                  
   ,PSS.IsParentSegmentStatusActive                  
   ,PSS.IsShowAutoNumber                  
   ,PSS.FormattingJson                  
   ,STT.TagType                  
   ,CASE                  
  WHEN PSS.SpecTypeTagId IS NULL THEN 0                  
  ELSE PSS.SpecTypeTagId                  
 END AS SpecTypeTagId                  
   ,PSS.IsRefStdParagraph                  
   ,PSS.IsPageBreak                  
   ,PSS.IsDeleted                  
   ,MSST.SpecTypeTagId AS MasterSpecTypeTagId                  
   ,ISNULL(MSST.ParentSegmentStatusId, 0) AS MasterParentSegmentStatusId                  
   ,CASE                  
  WHEN MSST.SegmentStatusId IS NOT NULL AND                  
   MSST.SpecTypeTagId = PSS.SpecTypeTagId THEN CAST(1 AS BIT)                  
  ELSE CAST(0 AS BIT)                  
 END AS IsMasterSpecTypeTag                  
   ,PSS.TrackOriginOrder AS TrackOriginOrder            
   ,PSS.MTrackDescription            
   INTO #tmp_ProjectSegmentStatus                  
FROM ProjectSegmentStatus AS PSS WITH (NOLOCK)                  
LEFT JOIN SLCMaster..SegmentStatus MSST WITH (NOLOCK)                  
 ON PSS.mSegmentStatusId = MSST.SegmentStatusId                  
LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK)                  
 ON PSS.SpecTypeTagId = STT.SpecTypeTagId                  
WHERE PSS.SectionId = @PSectionId                  
AND PSS.ProjectId = @PProjectId                  
AND PSS.CustomerId = @PCustomerId                  
AND ISNULL(PSS.IsDeleted, 0) = 0                  
AND (@PCatalogueType = 'FS'                  
OR STT.TagType IN (SELECT                  
  *                  
 FROM @CatalogueTypeTbl)                  
)                  
                  
SELECT                  
 *                  
FROM #tmp_ProjectSegmentStatus                  
ORDER BY SequenceNumber;                  
                  
SELECT                  
 *                  
FROM (SELECT                  
  PSG.SegmentId                  
    ,PSST.SegmentStatusId                  
    ,PSG.SectionId                  
    ,ISNULL(PSG.SegmentDescription, '') AS SegmentDescription                  
    ,PSG.SegmentSource                  
    ,PSG.SegmentCode                  
 FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                  
 INNER JOIN ProjectSegment AS PSG WITH (NOLOCK)                  
  ON PSST.SegmentId = PSG.SegmentId                  
  AND PSST.SectionId = PSG.SectionId                  
  AND PSST.ProjectId = PSG.ProjectId                  
  AND PSST.CustomerId = PSG.CustomerId                  
 WHERE PSST.ProjectId = @PProjectId                  
 AND PSST.CustomerId = @PCustomerId                  
 AND PSST.SectionId = @PSectionId                  
 AND ISNULL(PSST.IsDeleted, 0) = 0                  
 UNION ALL                  
 SELECT                  
  MSG.SegmentId                  
    ,PST.SegmentStatusId                  
    ,PST.SectionId                  
    ,CASE                  
   WHEN PST.ParentSegmentStatusId = 0 AND                  
    PST.SequenceNumber = 0 THEN PS.Description                  
   ELSE ISNULL(MSG.SegmentDescription, '')                  
  END AS SegmentDescription                  
    ,MSG.SegmentSource                  
    ,MSG.SegmentCode                  
 FROM #tmp_ProjectSegmentStatus AS PST WITH (NOLOCK)                  
 INNER JOIN ProjectSection AS PS WITH (NOLOCK)                  
  ON PST.SectionId = PS.SectionId                  
 INNER JOIN SLCMaster.dbo.Segment AS MSG WITH (NOLOCK)                  
  ON PST.mSegmentId = MSG.SegmentId                  
 WHERE PST.ProjectId = @PProjectId                  
 AND PST.CustomerId = @PCustomerId                  
 AND PST.SectionId = @PSectionId                  
 AND ISNULL(PST.IsDeleted, 0) = 0) AS X                  
                  
SELECT                 
 TemplateId                  
   ,Name                  
   ,TitleFormatId                  
   ,SequenceNumbering                  
   ,IsSystem                  
   ,IsDeleted                  
   ,ISNULL(@ProjectTemplateId, 0) AS ProjectTemplateId                  
   ,ISNULL(@SectionTemplateId, 0) AS SectionTemplateId     
   ,ApplyTitleStyleToEOS            
FROM Template WITH (NOLOCK)                  
WHERE TemplateId = @DocumentTemplateId;                  
                  
SELECT                  
 TemplateStyleId                  
   ,TemplateId                  
   ,StyleId                  
   ,Level                  
FROM TemplateStyle WITH (NOLOCK)                  
WHERE TemplateId = @DocumentTemplateId;                  
                  
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
   ,CAST(TST.Level AS INT) AS Level                  
FROM Style AS ST WITH (NOLOCK)                  
INNER JOIN TemplateStyle AS TST WITH (NOLOCK)                  
 ON ST.StyleId = TST.StyleId                  
WHERE TST.TemplateId = @DocumentTemplateId;                  
                  
--NOTE -- Need to fetch distinct SelectedChoiceOption records                    
DROP TABLE IF EXISTS #SelectedChoiceOptionTemp                  
SELECT DISTINCT                  
 SCHOP.SegmentChoiceCode                  
   ,SCHOP.ChoiceOptionCode                  
   ,SCHOP.ChoiceOptionSource                  
   ,SCHOP.IsSelected                  
   ,SCHOP.ProjectId                  
   ,SCHOP.SectionId                  
   ,SCHOP.CustomerId                  
   ,0 AS SelectedChoiceOptionId                  
   ,SCHOP.OptionJson INTO #SelectedChoiceOptionTemp                  
FROM SelectedChoiceOption SCHOP WITH (NOLOCK)                  
WHERE SCHOP.SectionId = @PSectionId           
AND SCHOP.ProjectId = @PProjectId                      
AND ISNULL(SCHOP.IsDeleted, 0) = 0            
AND SCHOP.CustomerId = @PCustomerId                  
                
-- Start - Workaround for Bug 34851: Regression: Choices: Duplicate choice options are being displayed in the choice option
	DECLARE @DUPLICATE TABLE
	(
		SegmentChoiceCode BIGINT, 
		ChoiceOptionCode BIGINT, 
		CNT INT
	)
	INSERT INTO @DUPLICATE
	Select SegmentChoiceCode,ChoiceOptionCode,COUNT(1) as CNT from #SelectedChoiceOptionTemp  
	WHERE  ChoiceOptionSource='U'
	GROUP BY SegmentChoiceCode,ChoiceOptionCode
	HAVING COUNT(1)>1

	DELETE t
	from #SelectedChoiceOptionTemp t INNER JOIN @DUPLICATE d
	ON t.SegmentChoiceCode=d.SegmentChoiceCode AND t.ChoiceOptionCode=d.ChoiceOptionCode
	WHERE t.IsSelected=0 and t.ChoiceOptionSource='U'
-- End - Workaround for Bug 34851: Regression: Choices: Duplicate choice options are being displayed in the choice option
                  
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
FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)                  
INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK)                  
 ON PSST.mSegmentId = MCH.SegmentId                  
INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)                  
 ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId                  
INNER JOIN #SelectedChoiceOptionTemp PSCHOP WITH (NOLOCK)                  
 ON MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode            
 AND MCH.SegmentChoiceCode= PSCHOP.SegmentChoiceCode               
  AND PSCHOP.ChoiceOptionSource = 'M'                  
  AND PSCHOP.ProjectId = @PProjectId                  
  AND PSCHOP.SectionId = @PSectionId                  
WHERE PSST.ProjectId = @PProjectId                  
AND PSST.SectionId = @PSectionId                  
AND PSST.CustomerId = @PCustomerId                  
AND ISNULL(PSST.IsDeleted, 0) = 0                  
UNION ALL                  
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
FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)                  
INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)                  
 ON PSST.SegmentId = PCH.SegmentId                  
  AND ISNULL(PCH.IsDeleted, 0) = 0                  
INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)                  
 ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId                  
  AND ISNULL(PCHOP.IsDeleted, 0) = 0                  
INNER JOIN #SelectedChoiceOptionTemp PSCHOP WITH (NOLOCK)                  
 ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode                  
  AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode                  
  AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource                  
  AND PSCHOP.ProjectId = @PProjectId                  
  AND PSCHOP.SectionId = @PSectionId                  
  AND PSCHOP.ChoiceOptionSource = 'U'                  
WHERE PSST.ProjectId = @PProjectId                  
AND PSST.SectionId = @PSectionId                  
AND PSST.CustomerId = @PCustomerId                  
AND ISNULL(PSST.IsDeleted, 0) = 0                  
                  
SELECT                  
 GlobalTermId                     ,COALESCE(mGlobalTermId, 0) AS mGlobalTermId                  
 --  ProjectId,                            
 -- CustomerId,                           
   ,[Name]                    
   ,ISNULL([Value], '') AS [Value]                  
   ,ISNULL(OldValue, '') AS OldValue                
   ,CreatedDate                  
   ,CreatedBy                  
   ,COALESCE(ModifiedDate,NULL)AS ModifiedDate              
   ,COALESCE(ModifiedBy, 0) AS ModifiedBy                  
   ,GlobalTermSource                  
   ,GlobalTermCode                  
   ,COALESCE(UserGlobalTermId, 0) AS UserGlobalTermId                  
   ,ISNULL(GlobalTermFieldTypeId, 1) AS GlobalTermFieldTypeId                  
FROM ProjectGlobalTerm WITH (NOLOCK)                  
WHERE ProjectId = @PProjectId                  
AND CustomerId = @PCustomerId                  
AND (IsDeleted = 0                  
OR IsDeleted IS NULL)                  
ORDER BY Name                  
                  
DROP TABLE IF EXISTS #Sections;                  
                  
--ADD UnDeleted from ProjectSection                    
SELECT                  
 S.Description                  
   ,S.Author                  
   ,S.SectionCode                  
   ,S.SourceTag                  
   ,PS.SourceTagFormat                  
   ,S.mSectionId                  
   ,S.SectionId                  
   ,S.IsDeleted INTO #Sections                  
FROM ProjectSection AS S WITH (NOLOCK)                  
INNER JOIN ProjectSummary PS WITH (NOLOCK)                  
 ON S.ProjectId = PS.ProjectId                  
  AND S.CustomerId = PS.CustomerId                  
WHERE S.ProjectId = @PProjectId                  
AND S.CustomerId = @PCustomerId                  
AND S.IsDeleted = 0                  
                  
--ADD Deleted from ProjectSection WIH UnInserted                    
INSERT INTO #Sections                  
 SELECT                  
  S.Description                  
    ,S.Author                  
    ,S.SectionCode                  
    ,S.SourceTag                  
    ,PS.SourceTagFormat                  
    ,S.mSectionId                  
    ,S.SectionId                  
    ,S.IsDeleted                  
 FROM ProjectSection AS S WITH (NOLOCK)                  
 INNER JOIN ProjectSummary PS WITH (NOLOCK)                  
  ON S.ProjectId = PS.ProjectId                  
   AND S.CustomerId = PS.CustomerId              
 LEFT JOIN #Sections TMP WITH (NOLOCK)                  
  ON S.SectionCode = TMP.SectionCode                  
 WHERE S.ProjectId = @PProjectId                  
 AND S.CustomerId = @PCustomerId                  
 AND S.IsDeleted = 1                  
 AND TMP.SectionId IS NULL                  
                  
--ADD EXTRA from SLCMaster..Section WIH UnInserted                    
INSERT INTO #Sections                  
 SELECT                  
  MS.Description                  
    ,MS.Author                  
    ,MS.SectionCode                  
    ,MS.SourceTag                  
    ,P.SourceTagFormat                  
    ,MS.SectionId AS mSectionId                  
    ,0 AS SectionId                  
    ,MS.IsDeleted                  
 FROM SLCMaster..Section MS WITH (NOLOCK)                  
 INNER JOIN ProjectSummary P WITH (NOLOCK)                  
  ON P.ProjectId = @PProjectId                  
   AND P.CustomerId = @PCustomerId                  
 LEFT JOIN #Sections TMP WITH (NOLOCK)                  
  ON MS.SectionCode = TMP.SectionCode                  
 WHERE MS.MasterDataTypeId = @MasterDataTypeId                  
 AND MS.IsLastLevel = 1                  
 AND TMP.SectionId IS NULL;                  
                  
SELECT                  
 *                  
FROM #Sections;                  
                  
--FETCH SEGMENT REQUIREMENT TAGS LIST                    
SELECT                  
 PSRT.SegmentStatusId                  
   ,PSRT.SegmentRequirementTagId                  
   ,Temp.mSegmentStatusId                  
   ,LPRT.RequirementTagId                  
   ,LPRT.TagType                 
   ,LPRT.Description AS TagName                  
   ,CASE                  
  WHEN PSRT.mSegmentRequirementTagId IS NULL THEN CAST(0 AS BIT)                  
  ELSE CAST(1 AS BIT)                  
 END AS IsMasterRequirementTag                  
FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)                  
INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)                  
 ON PSRT.RequirementTagId = LPRT.RequirementTagId                  
INNER JOIN #tmp_ProjectSegmentStatus Temp WITH (NOLOCK)                  
 ON PSRT.SegmentStatusId = Temp.SegmentStatusId                  
WHERE PSRT.ProjectId = @PProjectId                  
AND PSRT.SectionId = @PSectionId                  
AND PSRT.CustomerId = @PCustomerId                
AND ISNULL(PSRT.IsDeleted,0)=0            
                  
--FETCH REQUIRED IMAGES FROM DB                      
SELECT                  
  PSI.SegmentImageId  
 ,IMG.ImageId  
 ,IMG.ImagePath  
 ,ISNULL(PSI.ImageStyle, '') AS ImageStyle
FROM ProjectSegmentImage PSI WITH (NOLOCK)  
INNER JOIN ProjectImage IMG WITH (NOLOCK)  
 ON PSI.ImageId = IMG.ImageId  
WHERE PSI.SectionId = @PSectionId  
AND IMG.LuImageSourceTypeId = 1  
                  
--FETCH HYPERLINKS FROM PROJECT DB                    
SELECT                  
 HLNK.HyperLinkId                  
   ,HLNK.LinkTarget                  
   ,HLNK.LinkText                  
   ,'U' AS [Source]                  
FROM ProjectHyperLink HLNK WITH (NOLOCK)                  
WHERE HLNK.SectionId = @PSectionId
AND HLNK.ProjectId = @PProjectId
                  
--FETCH SEGMENT USER TAGS LIST                    
SELECT                  
 PSUT.SegmentUserTagId                  
   ,PSUT.SegmentStatusId                  
   ,PSUT.UserTagId                  
   ,PUT.TagType                  
   ,PUT.Description AS TagName                  
FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)                  
INNER JOIN ProjectUserTag PUT WITH (NOLOCK)                  
 ON PSUT.UserTagId = PUT.UserTagId                  
WHERE PSUT.ProjectId = @PProjectId                  
AND PSUT.CustomerId = @PCustomerId                  
AND PSUT.SectionId = @PSectionId                  
                  
SELECT    
ProjectId                
,IsIncludeRsInSection    
,IsIncludeReInSection    
,ISNULL(IsPrintReferenceEditionDate, 0) AS IsPrintReferenceEditionDate                   
FROM ProjectSummary WITH (NOLOCK)              
WHERE ProjectId = @PProjectId                  
END 

GO


