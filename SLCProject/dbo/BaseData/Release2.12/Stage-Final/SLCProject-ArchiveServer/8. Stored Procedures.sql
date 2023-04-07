USE SLCProject
GO

DROP PROC IF EXISTS usp_getGTDateFormat
GO

CREATE PROCEDURE [dbo].[usp_getGTDateFormat]
(  
@ProjectID INT  
  
)  
AS  
BEGIN
DECLARE @PProjectID INT = @ProjectID;

DECLARE @DateFormat NVARCHAR(50) = NULL,@TimeFormat NVARCHAR(50) = NULL;
DECLARE @MasterDataTypeId int =( SELECT TOP 1
		MasterDataTypeId
	FROM Project WITH(NOLOCK)
	WHERE ProjectId = @PProjectID)
SELECT
	@DateFormat = [DateFormat]
FROM ProjectDateFormat WITH(NOLOCK)
WHERE ProjectId = @PProjectID
SELECT
	@TimeFormat = [ClockFormat]
FROM ProjectDateFormat  WITH(NOLOCK)
WHERE ProjectId = @PProjectID
IF (@DateFormat IS NULL)
BEGIN
SELECT TOP 1
	@DateFormat = [DateFormat]
FROM ProjectDateFormat WITH(NOLOCK)
WHERE MasterDataTypeId = @MasterDataTypeId
AND ProjectId IS NULL
AND CustomerId IS NULL
AND UserId IS NULL
SELECT TOP 1
	@TimeFormat = [ClockFormat]
FROM ProjectDateFormat WITH(NOLOCK)
WHERE MasterDataTypeId = @MasterDataTypeId
AND ProjectId IS NULL
AND CustomerId IS NULL
AND UserId IS NULL
END
SELECT
	@DateFormat = DateFormat
FROM LuDateFormat WITH(NOLOCK)
WHERE [DateFormat] = @DateFormat

DECLARE @True BIT = 1;
DECLARE @False BIT = 0;

SELECT
	ISNULL(P.IsMigrated, 0) AS IsMigrated
   ,IIF(CAST(P.CreateDate AS DATE) < '2019-04-04', @True, @False) AS IsOldProject
   ,@DateFormat AS DateFormat
   ,@TimeFormat AS TimeFormat
FROM Project P WITH(NOLOCK)
WHERE P.ProjectId = @PProjectID
END

GO

GO
DROP PROC IF EXISTS usp_GetSegmentsForPrintPDF
GO

CREATE PROCEDURE [dbo].[usp_GetSegmentsForPrintPDF] (                  
 @ProjectId INT                  
 ,@CustomerId INT                  
 ,@SectionIdsString NVARCHAR(MAX)                  
 ,@UserId INT                  
 ,@CatalogueType NVARCHAR(MAX)                  
 ,@TCPrintModeId INT = 1                  
 ,@IsActiveOnly BIT = 1                
              
 )                  
AS                  
BEGIN                  
 DECLARE @PProjectId INT = @ProjectId;                  
 DECLARE @PCustomerId INT = @CustomerId;                  
 DECLARE @PSectionIdsString NVARCHAR(MAX) = @SectionIdsString;                  
 DECLARE @PUserId INT = @UserId;                  
 DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;                  
 DECLARE @PTCPrintModeId INT = @TCPrintModeId;                  
 DECLARE @PIsActiveOnly BIT = @IsActiveOnly;                  
 DECLARE @IsFalse BIT = 0;                  
 DECLARE @SProjectId NVARCHAR(20) = convert(NVARCHAR, @ProjectId);                  
 DECLARE @STCPrintModeId NVARCHAR(2) = convert(NVARCHAR, @TCPrintModeId);                  
 DECLARE @SIsActiveOnly NVARCHAR(2) = convert(NVARCHAR, @IsActiveOnly);                  
 DECLARE @SCustomerId NVARCHAR(20) = convert(NVARCHAR, @CustomerId);                  
 DECLARE @SUserId NVARCHAR(20) = convert(NVARCHAR, @UserId);                  
 DECLARE @MasterDataTypeId INT = (                  
   SELECT P.MasterDataTypeId                  
   FROM Project P WITH (NOLOCK)                  
   WHERE P.ProjectId = @PProjectId                  
    AND P.CustomerId = @PCustomerId                  
   );                  
 DECLARE @SectionIdTbl TABLE (SectionId INT);                  
 DECLARE @CatalogueTypeTbl TABLE (TagType NVARCHAR(MAX));                  
 DECLARE @OldKeywordFormat NVARCHAR(MAX) = '{\kw\';                  
 DECLARE @NewKeywordFormat NVARCHAR(MAX) = '{KW#';                  
 DECLARE @Lu_InheritFromSection INT = 1;                  
 DECLARE @Lu_AllWithMarkups INT = 2;                  
 DECLARE @Lu_AllWithoutMarkups INT = 3;                 
 DECLARE @ImagSegment int =1      
 DECLARE @ImageHeaderFooter int =3      
                  
 --CONVERT STRING INTO TABLE                                      
 INSERT INTO @SectionIdTbl (SectionId)                  
 SELECT *                  
 FROM dbo.fn_SplitString(@PSectionIdsString, ',');                  
                  
 --CONVERT CATALOGUE TYPE INTO TABLE                                  
 IF @PCatalogueType IS NOT NULL                  
  AND @PCatalogueType != 'FS'                  
 BEGIN                  
  INSERT INTO @CatalogueTypeTbl (TagType)                  
  SELECT *                  
  FROM dbo.fn_SplitString(@PCatalogueType, ',');                  
                  
  IF EXISTS (                  
    SELECT *                  
    FROM @CatalogueTypeTbl                  
    WHERE TagType = 'OL'                  
    )                  
  BEGIN                  
   INSERT INTO @CatalogueTypeTbl                  
   VALUES ('UO')                  
  END                  
                  
  IF EXISTS (                  
    SELECT TOP 1 1                  
    FROM @CatalogueTypeTbl                  
    WHERE TagType = 'SF'                  
    )                  
  BEGIN                  
   INSERT INTO @CatalogueTypeTbl                  
   VALUES ('US')                  
  END                  
 END                  
                  
 --DROP TEMP TABLES IF PRESENT                                      
 DROP TABLE                  
                  
 IF EXISTS #tmp_ProjectSegmentStatus;                  
  DROP TABLE                  
                  
 IF EXISTS #tmp_Template;                  
  DROP TABLE                  
                  
 IF EXISTS #tmp_SelectedChoiceOption;                  
  DROP TABLE                  
                  
 IF EXISTS #tmp_ProjectSection;                  
  --FETCH SECTIONS DATA IN TEMP TABLE                                  
  SELECT PS.SectionId                  
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
  INTO #tmp_ProjectSection                  
  FROM ProjectSection PS WITH (NOLOCK)                  
  WHERE PS.ProjectId = @PProjectId                  
   AND PS.CustomerId = @PCustomerId                  
   AND ISNULL(PS.IsDeleted, 0) = 0;                  
                  
 --FETCH SEGMENT STATUS DATA INTO TEMP TABLE                              
 SELECT PSST.SegmentStatusId            
  ,PSST.SectionId                  
  ,PSST.ParentSegmentStatusId                  
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId                  
  ,ISNULL(PSST.mSegmentId, 0) AS mSegmentId                  
  ,ISNULL(PSST.SegmentId, 0) AS SegmentId             
  ,PSST.SegmentSource                  
  ,trim(convert(NCHAR(2), PSST.SegmentOrigin)) AS SegmentOrigin                  
  ,CASE                   
   WHEN PSST.IndentLevel > 8                  
    THEN CAST(8 AS TINYINT)                  
   ELSE PSST.IndentLevel                  
   END AS IndentLevel                  
  ,PSST.SequenceNumber                  
  ,PSST.SegmentStatusTypeId                  
  ,PSST.SegmentStatusCode                  
  ,PSST.IsParentSegmentStatusActive                  
  ,PSST.IsShowAutoNumber                  
  ,PSST.FormattingJson                  
  ,STT.TagType                  
  ,ISNULL(PSST.SpecTypeTagId, 0) AS SpecTypeTagId                  
  ,PSST.IsRefStdParagraph                  
  ,PSST.IsPageBreak                  
  ,ISNULL(PSST.TrackOriginOrder, '') AS TrackOriginOrder                  
  ,PSST.MTrackDescription                  
 INTO #tmp_ProjectSegmentStatus                  
 FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl SIDTBL ON PSST.SectionId = SIDTBL.SectionId                  
 LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK) ON PSST.SpecTypeTagId = STT.SpecTypeTagId                  
 WHERE PSST.ProjectId = @PProjectId                  
  AND PSST.CustomerId = @PCustomerId                  
  AND (                  
   PSST.IsDeleted IS NULL                  
   OR PSST.IsDeleted = 0                  
   )                  
  AND (                  
   @PIsActiveOnly = @IsFalse                  
   OR (                  
    PSST.SegmentStatusTypeId > 0                  
    AND PSST.SegmentStatusTypeId < 6                  
    AND PSST.IsParentSegmentStatusActive = 1                  
    )                  
   OR (PSST.IsPageBreak = 1)                  
   )                  
  AND (                  
   @PCatalogueType = 'FS'                  
   OR STT.TagType IN (                  
    SELECT TagType                  
    FROM @CatalogueTypeTbl                  
    )                  
   )                  
                  
 --SELECT SEGMENT STATUS DATA                                      
 SELECT *                  
 FROM #tmp_ProjectSegmentStatus PSST                  
 ORDER BY PSST.SectionId                  
  ,PSST.SequenceNumber;                  
   
DROP TABLE IF EXISTS #tmpProjectSegmentStatusForNote;     
 --FETCH SegmentStatusId AND MSegmentStatusId DATA INTO TEMP TABLE       
SELECT PSST.SegmentStatusId              
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId                    
 INTO #tmpProjectSegmentStatusForNote                    
 FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)                    
 INNER JOIN @SectionIdTbl SIDTBL ON PSST.SectionId = SIDTBL.SectionId                   
 WHERE PSST.ProjectId = @PProjectId   
 AND PSST.CustomerId = @PCustomerId    
  
 --SELECT SEGMENT DATA                                      
 SELECT PSST.SegmentId                  
  ,PSST.SegmentStatusId                  
  ,PSST.SectionId                  
  ,(                  
   CASE                   
    WHEN @PTCPrintModeId = @Lu_AllWithoutMarkups                  
     THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                  
    WHEN @PTCPrintModeId = @Lu_AllWithMarkups                  
     THEN COALESCE(PSG.SegmentDescription, '')                  
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                  
     AND PS.IsTrackChanges = 1                  
     THEN COALESCE(PSG.SegmentDescription, '')                  
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                  
     AND PS.IsTrackChanges = 0                  
     THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                  
    ELSE COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                  
    END                  
   ) AS SegmentDescription                  
  ,PSG.SegmentSource                  
  ,PSG.SegmentCode                  
 FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                  
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId                  
 INNER JOIN ProjectSegment AS PSG WITH (NOLOCK) ON PSST.SegmentId = PSG.SegmentId                  
 WHERE PSG.ProjectId = @PProjectId                  
  AND PSG.CustomerId = @PCustomerId                  
                   
 UNION                  
                   
 SELECT MSG.SegmentId                  
  ,PSST.SegmentStatusId                  
  ,PSST.SectionId                  
  ,CASE                   
   WHEN PSST.ParentSegmentStatusId = 0                AND PSST.SequenceNumber = 0                  
    THEN PS.Description                  
   ELSE ISNULL(MSG.SegmentDescription, '')                  
   END AS SegmentDescription                  
  ,MSG.SegmentSource                  
  ,MSG.SegmentCode                  
 FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                  
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId                  
 INNER JOIN SLCMaster..Segment AS MSG WITH (NOLOCK) ON PSST.mSegmentId = MSG.SegmentId                  
 WHERE PS.ProjectId = @PProjectId                  
  AND PS.CustomerId = @PCustomerId                  
                  
 --FETCH TEMPLATE DATA INTO TEMP TABLE                                      
 SELECT *                  
 INTO #tmp_Template                  
 FROM (                  
  SELECT T.TemplateId                  
   ,T.Name                  
   ,T.TitleFormatId                  
   ,T.SequenceNumbering                  
   ,T.IsSystem                  
   ,T.IsDeleted                  
   ,0 AS SectionId                 
   ,T.ApplyTitleStyleToEOS              
   ,CAST(1 AS BIT) AS IsDefault                  
  --FROM Template T WITH (NOLOCK)                  
  FROM TemplatePDF T WITH (NOLOCK) 
  INNER JOIN Project P WITH (NOLOCK) ON T.TemplateId = COALESCE(P.TemplateId, 1)                  
  WHERE P.ProjectId = @PProjectId                  
   AND P.CustomerId = @PCustomerId                  
                    
  UNION                  
                    
  SELECT T.TemplateId                  
   ,T.Name                  
   ,T.TitleFormatId                  
   ,T.SequenceNumbering                  
   ,T.IsSystem                
   ,T.IsDeleted                  
   ,PS.SectionId                  
   ,T.ApplyTitleStyleToEOS              
   ,CAST(0 AS BIT) AS IsDefault                  
  --FROM Template T WITH (NOLOCK)       
  FROM TemplatePDF T WITH (NOLOCK) 
  INNER JOIN #tmp_ProjectSection PS WITH (NOLOCK) ON T.TemplateId = PS.TemplateId                  
  INNER JOIN @SectionIdTbl SIDTBL ON PS.SectionId = SIDTBL.SectionId                  
  WHERE PS.ProjectId = @PProjectId                  
   AND PS.CustomerId = @PCustomerId                  
   AND PS.TemplateId IS NOT NULL       
  ) AS X                  
                  
 --SELECT TEMPLATE DATA                                      
 SELECT *                  
 FROM #tmp_Template T                  
                  
 --SELECT TEMPLATE STYLE DATA                                      
 SELECT TS.TemplateStyleId                  
  ,TS.TemplateId                  
  ,TS.StyleId                  
  ,TS.LEVEL                  
 --FROM TemplateStyle TS WITH (NOLOCK)        
 FROM TemplateStylePDF TS WITH (NOLOCK)        
 INNER JOIN #tmp_Template T WITH (NOLOCK) ON TS.TemplateId = T.TemplateId                  
                  
 --SELECT STYLE DATA                                      
 SELECT ST.StyleId                  
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
  ,CAST(TS.LEVEL AS INT) AS LEVEL         
  ,ISNULL(SPS.CustomLineSpacing,0) as CustomLineSpacing    
  ,ISNULL(SPS.DefaultSpacesId,0) as  DefaultSpacesId    
  ,ISNULL(SPS.BeforeSpacesId,0) as   BeforeSpacesId    
  ,ISNULL(SPS.AfterSpacesId,0) as AfterSpacesId           
 --FROM Style AS ST WITH (NOLOCK)                  
 --INNER JOIN TemplateStyle AS TS WITH (NOLOCK) ON ST.StyleId = TS.StyleId   
 FROM StylePDF AS ST WITH (NOLOCK)                  
 INNER JOIN TemplateStylePDF AS TS WITH (NOLOCK) ON ST.StyleId = TS.StyleId   
 INNER JOIN #tmp_Template T WITH (NOLOCK) ON TS.TemplateId = T.TemplateId      
  LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK) ON SPS.StyleId=ST.StyleId              
                  
 -- insert missing sco entries                      
 INSERT INTO SelectedChoiceOption                  
 SELECT psc.SegmentChoiceCode                  
  ,pco.ChoiceOptionCode                  
  ,pco.ChoiceOptionSource                  
  ,slcmsco.IsSelected                  
  ,psc.SectionId                  
  ,psc.ProjectId                  
  ,pco.CustomerId                  
  ,NULL AS OptionJson                  
  ,0 AS IsDeleted                  
 FROM ProjectSegmentChoice psc WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl stb ON psc.SectionId = stb.SectionId                  
 INNER JOIN ProjectChoiceOption pco WITH (NOLOCK) ON pco.SegmentChoiceId = psc.SegmentChoiceId                  
  AND pco.SectionId = psc.SectionId                  
  AND pco.ProjectId = psc.ProjectId                  
  AND pco.CustomerId = psc.CustomerId                  
 LEFT OUTER JOIN SelectedChoiceOption sco WITH (NOLOCK) ON pco.ChoiceOptionCode = sco.ChoiceOptionCode                  
  AND pco.SectionId = sco.SectionId                  
  AND pco.ProjectId = sco.ProjectId                  
  AND pco.CustomerId = sco.CustomerId                  
  AND sco.ChoiceOptionSource = pco.ChoiceOptionSource                  
 INNER JOIN SLCMaster.dbo.SelectedChoiceOption slcmsco WITH (NOLOCK) ON slcmsco.ChoiceOptionCode = pco.ChoiceOptionCode                  
 WHERE sco.SelectedChoiceOptionId IS NULL                  
  AND pco.CustomerId = @PCustomerId                  
  AND pco.ProjectId = @PProjectId                  
  AND ISNULL(pco.IsDeleted, 0) = 0                  
  AND ISNULL(psc.IsDeleted, 0) = 0                  
 
              
 -- Mark isdeleted =0 for SelectedChoiceOption                    
 UPDATE sco                  
 SET sco.isdeleted = 0                  
 FROM ProjectSegmentChoice psc WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl stb ON psc.SectionId = stb.SectionId                  
 INNER JOIN ProjectChoiceOption pco WITH (NOLOCK) ON pco.SegmentChoiceId = psc.SegmentChoiceId                  
  AND pco.SectionId = psc.SectionId                  
  AND pco.ProjectId = psc.ProjectId     
  AND pco.CustomerId = psc.CustomerId                  
 LEFT OUTER JOIN SelectedChoiceOption sco WITH (NOLOCK) ON pco.ChoiceOptionCode = sco.ChoiceOptionCode                  
  AND pco.SectionId = sco.SectionId                  
  AND pco.ProjectId = sco.ProjectId                  
  AND pco.CustomerId = sco.CustomerId                  
  AND sco.ChoiceOptionSource = pco.ChoiceOptionSource                  
 WHERE ISNULL(sco.IsDeleted, 0) = 1                  
  AND pco.CustomerId = @PCustomerId                  
  AND pco.ProjectId = @PProjectId                  
  AND ISNULL(pco.IsDeleted, 0) = 0                  
  AND ISNULL(psc.IsDeleted, 0) = 0                  
  AND psc.SegmentChoiceSource = 'U'                  
                  
  
 --FETCH SelectedChoiceOption INTO TEMP TABLE                                      
 SELECT DISTINCT SCHOP.SegmentChoiceCode                  
  ,SCHOP.ChoiceOptionCode                  
  ,SCHOP.ChoiceOptionSource              ,SCHOP.IsSelected                  
  ,SCHOP.ProjectId                  
  ,SCHOP.SectionId                  
  ,SCHOP.CustomerId                  
  ,0 AS SelectedChoiceOptionId                  
  ,SCHOP.OptionJson                  
 INTO #tmp_SelectedChoiceOption                  
 FROM SelectedChoiceOption SCHOP WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl SIDTBL ON SCHOP.SectionId = SIDTBL.SectionId                  
 WHERE SCHOP.ProjectId = @PProjectId                  
  AND SCHOP.CustomerId = @PCustomerId                  
  AND IsNULL(SCHOP.IsDeleted, 0) = 0                  
                  
 --FETCH MASTER + USER CHOICES AND THEIR OPTIONS                                        
 SELECT 0 AS SegmentId                  
  ,MCH.SegmentId AS mSegmentId                  
  ,MCH.ChoiceTypeId                  
  ,'M' AS ChoiceSource                  
  ,ISNULL(MCH.SegmentChoiceCode, 0) AS SegmentChoiceCode                
  ,ISNULL(MCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode                  
  ,PSCHOP.IsSelected                  
  ,PSCHOP.ChoiceOptionSource                  
  ,CASE                   
   WHEN PSCHOP.IsSelected = 1                  
    AND PSCHOP.OptionJson IS NOT NULL                  
    THEN PSCHOP.OptionJson                  
   ELSE MCHOP.OptionJson                  
   END AS OptionJson                  
  ,MCHOP.SortOrder                  
  ,MCH.SegmentChoiceId                  
  ,MCHOP.ChoiceOptionId            
  ,PSCHOP.SelectedChoiceOptionId                  
  ,PSST.SectionId                  
 FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)                  
 INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK) ON PSST.mSegmentId = MCH.SegmentId                  
 INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK) ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId                  
 INNER JOIN #tmp_SelectedChoiceOption PSCHOP WITH (NOLOCK) ON MCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode                  
  AND MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode                  
  AND PSCHOP.ChoiceOptionSource = 'M'                  
                   
 UNION                  
                   
 SELECT PCH.SegmentId                  
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
 INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK) ON PSST.SegmentId = PCH.SegmentId                  
  AND ISNULL(PCH.IsDeleted, 0) = 0                  
 INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK) ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId                  
  AND ISNULL(PCHOP.IsDeleted, 0) = 0                  
 INNER JOIN #tmp_SelectedChoiceOption PSCHOP WITH (NOLOCK) ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode                  
  AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode                  
AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource                  
  AND PSCHOP.ChoiceOptionSource = 'U'                  
 WHERE PCH.ProjectId = @PProjectId                  
  AND PCH.CustomerId = @PCustomerId                  
  AND PCHOP.ProjectId = @PProjectId                  
  AND PCHOP.CustomerId = @PCustomerId                  
  AND ISNULL(PCH.IsDeleted, 0) = 0                  
  AND ISNULL(PCHOP.IsDeleted, 0) = 0                  
                  
 --SELECT GLOBAL TERM DATA                                      
 SELECT PGT.GlobalTermId                  
  ,COALESCE(PGT.mGlobalTermId, 0) AS mGlobalTermId                  
  ,PGT.Name                  
  ,ISNULL(PGT.value, '') AS value                  
  ,PGT.CreatedDate                  
  ,PGT.CreatedBy                  
  ,PGT.ModifiedDate                  
  ,PGT.ModifiedBy                  
  ,PGT.GlobalTermSource                  
  ,PGT.GlobalTermCode                  
  ,COALESCE(PGT.UserGlobalTermId, 0) AS UserGlobalTermId                  
  ,GlobalTermFieldTypeId                  
 FROM ProjectGlobalTerm PGT WITH (NOLOCK)                  
 WHERE PGT.ProjectId = @PProjectId                  
  AND PGT.CustomerId = @PCustomerId;                  
                  
 --SELECT SECTIONS DATA                                      
 SELECT S.SectionId AS SectionId                  
  ,ISNULL(S.mSectionId, 0) AS mSectionId                  
  ,S.Description                  
  ,S.Author                  
  ,S.SectionCode                  
  ,S.SourceTag                  
  ,PS.SourceTagFormat                  
  ,ISNULL(D.DivisionCode, '') AS DivisionCode                  
  ,ISNULL(D.DivisionTitle, '') AS DivisionTitle                  
  ,ISNULL(D.DivisionId, 0) AS DivisionId                  
  ,S.IsTrackChanges                  
 FROM #tmp_ProjectSection AS S WITH (NOLOCK)                  
 LEFT JOIN SLCMaster..Division D WITH (NOLOCK) ON S.DivisionId = D.DivisionId                  
 INNER JOIN ProjectSummary PS WITH (NOLOCK) ON S.ProjectId = PS.ProjectId                  
  AND S.CustomerId = PS.CustomerId                  
 WHERE S.ProjectId = @PProjectId                  
  AND S.CustomerId = @PCustomerId                  
  AND S.IsLastLevel = 1                  
AND ISNULL(S.IsDeleted, 0) = 0                  
                   
 UNION                  
                   
 SELECT 0 AS SectionId                  
  ,MS.SectionId AS mSectionId                  
  ,MS.Description                  
  ,MS.Author                  
  ,MS.SectionCode                  
  ,MS.SourceTag                  
  ,P.SourceTagFormat                  
  ,ISNULL(D.DivisionCode, '') AS DivisionCode                  
  ,ISNULL(D.DivisionTitle, '') AS DivisionTitle                  
  ,ISNULL(D.DivisionId, 0) AS DivisionId                  
  ,CONVERT(BIT, 0) AS IsTrackChanges                  
 FROM SLCMaster..Section MS WITH (NOLOCK)                  
 LEFT JOIN SLCMaster..Division D WITH (NOLOCK) ON MS.DivisionId = D.DivisionId                  
 INNER JOIN ProjectSummary P WITH (NOLOCK) ON P.ProjectId = @PProjectId                  
  AND P.CustomerId = @PCustomerId                  
 LEFT JOIN #tmp_ProjectSection PS WITH (NOLOCK) ON MS.SectionId = PS.mSectionId                  
  AND PS.ProjectId = @PProjectId                  
  AND PS.CustomerId = @PCustomerId                  
 WHERE MS.MasterDataTypeId = @MasterDataTypeId                  
  AND MS.IsLastLevel = 1                  
  AND PS.SectionId IS NULL                  
  AND ISNULL(PS.IsDeleted, 0) = 0                  
                  
 --SELECT SEGMENT REQUIREMENT TAGS DATA                                      
 SELECT PSRT.SegmentStatusId                  
  ,PSRT.SegmentRequirementTagId                  
  ,PSST.mSegmentStatusId                  
  ,LPRT.RequirementTagId                  
  ,LPRT.TagType                  
  ,LPRT.Description AS TagName                  
  ,CASE                   
   WHEN PSRT.mSegmentRequirementTagId IS NULL                  
    THEN CAST(0 AS BIT)                  
   ELSE CAST(1 AS BIT)                  
   END AS IsMasterRequirementTag                  
  ,PSST.SectionId                  
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)                  
 INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK) ON PSRT.RequirementTagId = LPRT.RequirementTagId                  
INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK) ON PSRT.SegmentStatusId = PSST.SegmentStatusId                  
 WHERE PSRT.ProjectId = @PProjectId                  
  AND PSRT.CustomerId = @PCustomerId                  
                       
 --SELECT REQUIRED IMAGES DATA                                      
 SELECT             
  PIMG.SegmentImageId            
 ,IMG.ImageId            
 ,IMG.ImagePath            
 ,PIMG.ImageStyle            
 ,PIMG.SectionId             
 ,IMG.LuImageSourceTypeId     
          
 FROM ProjectSegmentImage PIMG WITH (NOLOCK)                  
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PIMG.ImageId = IMG.ImageId                  
 --INNER JOIN @SectionIdTbl SIDTBL ON PIMG.SectionId = SIDTBL.SectionId    //To resolved cross section images in headerFooter               
 WHERE PIMG.ProjectId = @PProjectId                  
  AND PIMG.CustomerId = @PCustomerId                  
  AND IMG.LuImageSourceTypeId IN(@ImagSegment,@ImageHeaderFooter)    
UNION ALL -- This union to ge Note images    
 SELECT             
  0 SegmentImageId            
 ,PN.ImageId            
 ,IMG.ImagePath            
 ,NULL ImageStyle            
 ,PN.SectionId             
 ,IMG.LuImageSourceTypeId     
 FROM ProjectNoteImage PN  WITH (NOLOCK)         
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PN.ImageId = IMG.ImageId    
 INNER JOIN @SectionIdTbl SIDTBL ON PN.SectionId = SIDTBL.SectionId    
 WHERE PN.ProjectId = @PProjectId                  
  AND PN.CustomerId = @PCustomerId   
 UNION ALL -- This union to ge Master Note images   
 select   
  0 SegmentImageId            
 ,NI.ImageId            
 ,MIMG.ImagePath            
 ,NULL ImageStyle            
 ,NI.SectionId             
 ,MIMG.LuImageSourceTypeId    
from slcmaster..NoteImage NI with (nolock)  
INNER JOIN ProjectSection PS with (nolock) on NI.SectionId = PS.mSectionId  
INNER JOIN @SectionIdTbl SIDTBL ON PS.SectionId = SIDTBL.SectionId  
INNER JOIN SLCMaster..Image MIMG WITH (NOLOCK) ON MIMG.ImageId = NI.ImageId                  
                  
 --SELECT HYPERLINKS DATA                                      
 SELECT HLNK.HyperLinkId                  
  ,HLNK.LinkTarget                  
  ,HLNK.LinkText                  
  ,'U' AS Source                  
  ,HLNK.SectionId                  
 FROM ProjectHyperLink HLNK WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl SIDTBL ON HLNK.SectionId = SIDTBL.SectionId                  
 WHERE HLNK.ProjectId = @PProjectId                  
  AND HLNK.CustomerId = @PCustomerId                  
  UNION ALL -- To get Master Hyperlinks  
  SELECT MLNK.HyperLinkId                  
  ,MLNK.LinkTarget                  
  ,MLNK.LinkText                  
  ,'M' AS Source                  
  ,MLNK.SectionId                  
 FROM slcmaster..Hyperlink MLNK WITH (NOLOCK)   
 INNER JOIN #tmpProjectSegmentStatusForNote PSS WITH (NOLOCK) ON  MLNK.SegmentStatusId = PSS.mSegmentStatusId  
                
 --SELECT SEGMENT USER TAGS DATA                                      
 SELECT PSUT.SegmentUserTagId                  
  ,PSUT.SegmentStatusId                  
  ,PSUT.UserTagId                  
  ,PUT.TagType                  
  ,PUT.Description AS TagName                  
  ,PSUT.SectionId                  
 FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)                  
 --INNER JOIN ProjectUserTag PUT WITH (NOLOCK) ON PSUT.UserTagId = PUT.UserTagId            
 INNER JOIN ProjectUserTagPDF PUT WITH (NOLOCK) ON PSUT.UserTagId = PUT.UserTagId            
 INNER JOIN #tmp_ProjectSegmentStatus PSST WITH (NOLOCK) ON PSUT.SegmentStatusId = PSST.SegmentStatusId                  
 WHERE PSUT.ProjectId = @PProjectId                  
  AND PSUT.CustomerId = @PCustomerId           
    
 --SELECT Project Summary information                                      
 SELECT P.ProjectId AS ProjectId                  
  ,P.Name AS ProjectName                  
  ,'' AS ProjectLocation                  
  ,PS.IsPrintReferenceEditionDate AS IsPrintReferenceEditionDate                  
  ,PS.SourceTagFormat AS SourceTagFormat                  
  ,COALESCE(CASE                   
    WHEN len(LState.StateProvinceAbbreviation) > 0                  
     THEN LState.StateProvinceAbbreviation              ELSE PA.StateProvinceName                  
    END + ', ' + CASE                   
    WHEN len(LCity.City) > 0                  
     THEN LCity.City                  
    ELSE PA.CityName                  
    END, '') AS DbInfoProjectLocationKeyword                  
  ,ISNULL(PGT.value, '') AS ProjectLocationKeyword                  
  ,PS.UnitOfMeasureValueTypeId                  
 FROM Project P WITH (NOLOCK)                  
 INNER JOIN ProjectSummary PS WITH (NOLOCK) ON P.ProjectId = PS.ProjectId                  
 INNER JOIN ProjectAddress PA WITH (NOLOCK) ON P.ProjectId = PA.ProjectId                  
 INNER JOIN LuCountry LCountry WITH (NOLOCK) ON PA.CountryId = LCountry.CountryId                  
 LEFT JOIN LuStateProvince LState WITH (NOLOCK) ON PA.StateProvinceId = LState.StateProvinceID                  
 LEFT JOIN LuCity LCity WITH (NOLOCK) ON (                  
PA.CityId = LCity.CityId                  
   OR PA.CityName = LCity.City                  
   )                  
  AND LCity.StateProvinceId = PA.StateProvinceId                  
 LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK) ON P.ProjectId = PGT.ProjectId                  
  AND PGT.mGlobalTermId = 11                  
 WHERE P.ProjectId = @PProjectId                  
  AND P.CustomerId = @PCustomerId                  
                  
 --SELECT REFERENCE STD DATA                                   
 SELECT MREFSTD.RefStdId              
  ,COALESCE(MREFSTD.RefStdName, '') AS RefStdName                  
  ,'M' AS RefStdSource                  
  ,COALESCE(MREFSTD.ReplaceRefStdId, 0) AS ReplaceRefStdId                  
  ,'M' AS ReplaceRefStdSource                  
  ,MREFSTD.IsObsolete                  
  ,COALESCE(MREFSTD.RefStdCode, 0) AS RefStdCode                  
 FROM SLCMaster..ReferenceStandard MREFSTD WITH (NOLOCK)                  
 WHERE MREFSTD.MasterDataTypeId = CASE                   
   WHEN @MasterDataTypeId = 2                  
    OR @MasterDataTypeId = 3                  
    THEN 1                  
   ELSE @MasterDataTypeId                  
   END                  
                   
 UNION                  
                   
 SELECT PREFSTD.RefStdId                  
  ,PREFSTD.RefStdName                  
  ,'U' AS RefStdSource                  
  ,COALESCE(PREFSTD.ReplaceRefStdId, 0) AS ReplaceRefStdId                  
  ,COALESCE(PREFSTD.ReplaceRefStdSource, '') AS ReplaceRefStdSource                  
  ,PREFSTD.IsObsolete                  
  ,COALESCE(PREFSTD.RefStdCode, 0) AS RefStdCode                  
 --FROM ReferenceStandard PREFSTD WITH (NOLOCK)    
 FROM ReferenceStandardPDF PREFSTD WITH (NOLOCK)    
 WHERE PREFSTD.CustomerId = @PCustomerId                  
 
 --SELECT REFERENCE EDITION DATA New Implementation for performance improvement.  
  
 DECLARE @MRSEdition TABLE(RefStdId INT,RefStdEditionId INT,RefEdition VARCHAR(150) , RefStdTitle VARCHAR(500), LinkTarget VARCHAR(500),RefEdnSource CHAR(1))  
 DECLARE @PRSEdition TABLE(RefStdId INT,RefStdEditionId INT,RefEdition VARCHAR(150) , RefStdTitle VARCHAR(500), LinkTarget VARCHAR(500),RefEdnSource CHAR(1))  
   
 INSERT into @MRSEdition  
 SELECT MREFEDN.RefStdId                  
  ,MREFEDN.RefStdEditionId                  
  ,MREFEDN.RefEdition                  
  ,MREFEDN.RefStdTitle                  
  ,MREFEDN.LinkTarget                  
  ,'M' AS RefEdnSource                  
 FROM SLCMaster..ReferenceStandardEdition MREFEDN WITH (NOLOCK)                  
 WHERE MREFEDN.MasterDataTypeId = CASE                   
   WHEN @MasterDataTypeId = 2                  
    OR @MasterDataTypeId = 3                  
    THEN 1                  
   ELSE @MasterDataTypeId                  
   END   
  
 INSERT into @PRSEdition    
 SELECT PREFEDN.RefStdId                  
  ,PREFEDN.RefStdEditionId                  
  ,PREFEDN.RefEdition                  
  ,PREFEDN.RefStdTitle                  
  ,PREFEDN.LinkTarget                  
  ,'U' AS RefEdnSource                  
 --FROM ReferenceStandardEdition PREFEDN WITH (NOLOCK)   
 FROM ReferenceStandardEditionPDF PREFEDN WITH (NOLOCK)   
 WHERE PREFEDN.CustomerId = @PCustomerId        
   
 select * from @MRSEdition  
 union   
 select * from @PRSEdition  

                  
 --SELECT ProjectReferenceStandard MAPPING DATA                                      
 SELECT PREFSTD.RefStandardId                  
  ,PREFSTD.RefStdSource                  
  ,COALESCE(PREFSTD.mReplaceRefStdId, 0) AS mReplaceRefStdId                  
  ,PREFSTD.RefStdEditionId                  
  ,SIDTBL.SectionId                  
 FROM ProjectReferenceStandard PREFSTD WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl SIDTBL ON PREFSTD.SectionId = SIDTBL.SectionId                  
 WHERE PREFSTD.ProjectId = @PProjectId                  
  AND PREFSTD.CustomerId = @PCustomerId                  
                  
 --SELECT Header/Footer information                                      
 SELECT X.HeaderId                  
  ,ISNULL(X.ProjectId, @PProjectId) AS ProjectId                  
  ,ISNULL(X.SectionId, 0) AS SectionId                  
  ,ISNULL(X.CustomerId, @PCustomerId) AS CustomerId                  
  ,ISNULL(X.TypeId, 1) AS TypeId                  
  ,X.DATEFORMAT                  
  ,X.TimeFormat                  
  ,ISNULL(X.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                  
  ,REPLACE(ISNULL(X.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader                  
  ,REPLACE(ISNULL(X.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader                  
  ,REPLACE(ISNULL(X.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader                  
  ,REPLACE(ISNULL(X.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader                  
  ,X.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId     
  ,X.IsShowLineAboveHeader as  IsShowLineAboveHeader    
  ,X.IsShowLineBelowHeader as  IsShowLineBelowHeader             
 FROM (                  
  SELECT H.*                  
  FROM Header H WITH (NOLOCK)                  
  INNER JOIN @SectionIdTbl S ON H.SectionId = S.SectionId                  
  WHERE H.ProjectId = @PProjectId                  
   AND H.DocumentTypeId = 1                  
   AND (                  
    ISNULL(H.HeaderFooterCategoryId, 1) = 1                  
    OR H.HeaderFooterCategoryId = 4                  
    )                  
                    
  UNION                  
                    
  SELECT H.*                  
  FROM Header H WITH (NOLOCK)                  
  WHERE H.ProjectId = @PProjectId                  
   AND H.DocumentTypeId = 1                  
   AND (ISNULL(H.HeaderFooterCategoryId, 1) = 1)                  
   AND (                  
    H.SectionId IS NULL                  
    OR H.SectionId <= 0                  
    )                  
                    
  UNION                  
                    
  SELECT H.*                  
  FROM Header H WITH (NOLOCK)                  
  LEFT JOIN Header TEMP                  
  WITH (NOLOCK) ON TEMP.ProjectId = @PProjectId                  
  WHERE H.CustomerId IS NULL                  
   AND TEMP.HeaderId IS NULL                  
   AND H.DocumentTypeId = 1                  
  ) AS X                  
                  
 SELECT X.FooterId                  
  ,ISNULL(X.ProjectId, @PProjectId) AS ProjectId                  
  ,ISNULL(X.SectionId, 0) AS SectionId                  
  ,ISNULL(X.CustomerId, @PCustomerId) AS CustomerId                  
  ,ISNULL(X.TypeId, 1) AS TypeId                  
  ,X.DATEFORMAT                  
  ,X.TimeFormat                  
  ,ISNULL(X.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                  
  ,REPLACE(ISNULL(X.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter                  
  ,REPLACE(ISNULL(X.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter                  
  ,REPLACE(ISNULL(X.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter                  
  ,REPLACE(ISNULL(X.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter                  
  ,X.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId      
  ,X.IsShowLineAboveFooter as  IsShowLineAboveFooter    
  ,X.IsShowLineBelowFooter as  IsShowLineBelowFooter                  
 FROM (            
  SELECT F.*                  
  FROM Footer F WITH (NOLOCK)                  
  INNER JOIN @SectionIdTbl S ON F.SectionId = S.SectionId                  
  WHERE F.ProjectId = @PProjectId                  
   AND F.DocumentTypeId = 1                  
   AND (                  
    ISNULL(F.HeaderFooterCategoryId, 1) = 1                  
    OR F.HeaderFooterCategoryId = 4                  
    )                  
                    
  UNION                  
                    
  SELECT F.*                  
  FROM Footer F WITH (NOLOCK)                  
  WHERE F.ProjectId = @PProjectId                  
   AND F.DocumentTypeId = 1                  
   AND (ISNULL(F.HeaderFooterCategoryId, 1) = 1)                  
   AND (                  
    F.SectionId IS NULL                  
    OR F.SectionId <= 0                  
    )                  
                    
  UNION                  
                    
  SELECT F.*                  
  FROM Footer F WITH (NOLOCK)           
  LEFT JOIN Footer TEMP                  
  WITH (NOLOCK) ON TEMP.ProjectId = @PProjectId                  
  WHERE F.CustomerId IS NULL                  
   AND F.DocumentTypeId = 1                  
   AND TEMP.FooterId IS NULL                  
  ) AS X                  
                  
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
  ,PaperSetting.PaperName AS PaperName                  
  ,ISNULL(PaperSetting.PaperWidth, 0.00) AS PaperWidth                  
  ,ISNULL(PaperSetting.PaperHeight, 0.00) AS PaperHeight                  
  ,PaperSetting.PaperOrientation AS PaperOrientation                  
  ,PaperSetting.PaperSource AS PaperSource                  
 FROM ProjectPageSetting PageSetting WITH (NOLOCK)                  
 INNER JOIN ProjectPaperSetting PaperSetting WITH (NOLOCK) ON PageSetting.ProjectId = PaperSetting.ProjectId                
 WHERE PageSetting.ProjectId = @PProjectId                  
    
/*Start - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/    
SELECT   
NoteId  
,PN.SectionId    
,PSS.SegmentStatusId SegmentStatusId    
,PSS.mSegmentStatusId mSegmentStatusId    
,CASE WHEN Title != '' THEN CONCAT(Title,'<br/>', NoteText)   
 ELSE NoteText END NoteText    
,PN.ProjectId  
,PN.CustomerId  
,PN.IsDeleted  
,NoteCode  
,PN.Title
FROM ProjectNote PN WITH (NOLOCK)   
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK) ON PN.SegmentStatusId = PSS.SegmentStatusId     
WHERE PN.ProjectId=@PProjectId and PN.CustomerId=@PCustomerId AND ISNULL(PN.IsDeleted, 0) = 0    
UNION ALL    
SELECT NoteId    
,0 SectionId    
,PSS.SegmentStatusId SegmentStatusId    
,PSS.mSegmentStatusId mSegmentStatusId    
,NoteText    
,@PProjectId ProjectId     
,@PCustomerId CustomerId     
,0 IsDeleted    
,0 NoteCode
,'' As Title
 FROM SLCMaster..Note MN  WITH (NOLOCK)  
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK)  
ON MN.SegmentStatusId = PSS.mSegmentStatusId   
/*End - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/    
END

GO
DROP PROC IF EXISTS usp_GetSpecDataSectionListPDF
GO
CREATE PROCEDURE [dbo].[usp_GetSpecDataSectionListPDF]     
(                
 @ProjectId INT        
)                
AS                
BEGIN
                
            
DECLARE @PProjectId INT = @ProjectId;

DROP TABLE IF EXISTS #ProjectInfoTbl;
DROP TABLE IF EXISTS #ActiveSectionsTbl;
DROP TABLE IF EXISTS #DistinctDivisionTbl;
DROP TABLE IF EXISTS #ActiveSectionsIdsTbl;

SELECT
	P.ProjectId
   ,p.CustomerId
   ,p.UserId
   ,P.[Name] AS ProjectName
   ,P.MasterDataTypeId
   ,PS.SourceTagFormat
   ,PS.SpecViewModeId
   ,PS.UnitOfMeasureValueTypeId
   ,P.CreatedBy
   ,P.CreateDate INTO #ProjectInfoTbl
FROM Project P WITH (NOLOCK)
INNER JOIN ProjectSummary PS WITH (NOLOCK)
	ON PS.ProjectId = P.ProjectId
WHERE P.ProjectId = @PProjectId

SELECT
	PIT.ProjectId
   ,PIT.CustomerId
   ,P.CreatedBy AS CreatedBy
   ,IsNull(P.ModifiedByFullName,'') AS CreatedByFullName
   ,P.CreateDate AS LocalDate
   ,P.[Name] AS ProjectName
   ,PIT.MasterDataTypeId
   ,P.[Description] AS FileName
   ,'' AS FilePath
   ,'In Progress' AS FileStatus
   ,'' AS LocalTime
FROM #ProjectInfoTbl PIT
INNER JOIN Project P WITH (NOLOCK)
	ON P.ProjectId = @PProjectId

SELECT
	SectionId INTO #ActiveSectionsIdsTbl
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
WHERE PSST.ProjectId = @PProjectId
AND PSST.SequenceNumber = 0
AND PSST.IndentLevel = 0
AND PSST.SegmentStatusTypeId < 6
AND ISNULL(PSST.IsDeleted, 0) = 0

SELECT
	PS.ProjectId
   ,PS.CustomerId
   ,PS.SectionId
   ,PS.UserId
   ,PS.SourceTag
   ,PS.[Description] AS SectionName
   ,PS.DivisionId
   ,PS.Author INTO #ActiveSectionsTbl
FROM #ActiveSectionsIdsTbl AST WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
	ON PS.SectionId = AST.SectionId


SELECT
	AST.ProjectId
   ,AST.CustomerId
   ,AST.SectionId
   ,AST.UserId
   ,AST.SourceTag
   ,AST.SectionName
   ,AST.DivisionId
   ,AST.Author
   ,PIT.ProjectName
   ,PIT.MasterDataTypeId
   ,PIT.SourceTagFormat
   ,PIT.SpecViewModeId
   ,PIT.UnitOfMeasureValueTypeId
FROM #ActiveSectionsTbl AST
INNER JOIN #ProjectInfoTbl PIT
	ON PIT.ProjectId = AST.ProjectId
ORDER BY AST.SourceTag

IF NOT EXISTS (SELECT TOP 1
			1
		FROM ProjectPrintSetting WITH (NOLOCK)
		WHERE ProjectId = @PProjectId)
BEGIN
SELECT
	@PProjectId AS ProjectId
   ,IsExportInMultipleFiles
   ,IsBeginSectionOnOddPage
   ,IsIncludeAuthorInFileName
   ,TCPrintModeId
   ,IsIncludePageCount
   ,IsIncludeHyperLink
   ,KeepWithNext
   ,IsPrintMasterNote  
   ,IsPrintProjectNote  
   ,IsPrintNoteImage  
   ,IsPrintIHSLogo   
FROM ProjectPrintSettingPDF WITH (NOLOCK)
WHERE CustomerId IS NULL
AND ProjectId IS NULL
AND CreatedBy IS NULL
END
ELSE
BEGIN
SELECT
	@PProjectId AS ProjectId
   ,CustomerId AS CustomerId
   ,CreatedBy AS CreatedBy
   ,IsExportInMultipleFiles
   ,IsBeginSectionOnOddPage
   ,IsIncludeAuthorInFileName
   ,TCPrintModeId
   ,IsIncludePageCount
   ,IsIncludeHyperLink
   ,KeepWithNext
   ,IsNull(IsPrintMasterNote,0) as IsPrintMasterNote  
   ,IsNull(IsPrintProjectNote,0) as IsPrintProjectNote  
   ,IsNull(IsPrintNoteImage,0) as IsPrintNoteImage  
   ,IsNull(IsPrintIHSLogo,0) as IsPrintIHSLogo   
FROM ProjectPrintSetting WITH (NOLOCK)
WHERE ProjectId = @PProjectId

END

END
GO

DROP PROC IF EXISTS usp_DeleteCustomerDataForPDFExport
GO
CREATE PROCEDURE  [dbo].[usp_DeleteCustomerDataForPDFExport]   
AS  
BEGIN 
	Truncate Table TemplatePDF
	Truncate Table TemplateStylePDF
	Truncate Table StylePDF
	Truncate Table ProjectUserTagPDF
	Truncate Table ReferenceStandardPDF
	Truncate Table ReferenceStandardEditionPDF
	Truncate Table ProjectPrintSettingPDF
END
GO

CREATE FUNCTION [dbo].[fn_SplitString]
(@string NVARCHAR (MAX) NULL, @delimiter CHAR (1) NULL)
RETURNS 
    @output TABLE (
        [splitdata] NVARCHAR (MAX) NULL)
AS
BEGIN
    DECLARE @start AS INT, @end AS INT;
    SELECT @start = 1,
           @end = CHARINDEX(@delimiter, @string);
    WHILE @start < LEN(@string) + 1
        BEGIN
            IF @end = 0
                SET @end = LEN(@string) + 1;
            INSERT  INTO @output (splitdata)
            VALUES              (SUBSTRING(@string, @start, @end - @start));
            SET @start = @end + 1;
            SET @end = CHARINDEX(@delimiter, @string, @start);
        END
    RETURN;
END
GO
DROP function if exists fnGetSegmentDescriptionTextForRSAndGT
GO
CREATE FUNCTION [dbo].[fnGetSegmentDescriptionTextForRSAndGT]    
(    
 @ProjectId int,    
 @CustomerId int,    
 @segmentDescription NVARCHAR(MAX)    
)RETURNS NVARCHAR(MAX)    
AS    
BEGIN    
	IF(@segmentDescription like '%{RS#%')
	BEGIN
		SELECT @segmentDescription = REPLACE(@segmentDescription,    
		CONCAT('{RS#', CONVERT(NVARCHAR(MAX), prs.RefStdCode), '}'), rs.RefStdName)    
		FROM [dbo].[ProjectReferenceStandard] prs WITH(NOLOCK)  Inner JOIN ReferenceStandard rs WITH(NOLOCK)  
		ON prs.RefStandardId=rs.RefStdId  
		WHERE prs.ProjectId=@ProjectId and prs.CustomerId=@CustomerId  
  
		SELECT @segmentDescription = REPLACE(@segmentDescription,    
		CONCAT('{RS#', CONVERT(NVARCHAR(MAX), RefStdCode), '}'), RefStdName)    
		FROM [SLCMaster].[dbo].[ReferenceStandard] WITH(NOLOCK)    
    END 
	IF @segmentDescription LIKE '%{RSTEMP#%'    
	BEGIN    
		  DECLARE @RSCode INT = 0;    
		  SELECT @RSCode = LEFT(Val, PATINDEX('%[^0-9]%', Val + 'a') - 1)     
		  FROM (SELECT SUBSTRING(@segmentDescription, PATINDEX('%[0-9]%', @segmentDescription), LEN(@segmentDescription)) Val) RSCode    
    
		  SELECT @segmentDescription = CONCAT(RSEdition.RefStdName, ' - ', RSEdition.RefStdTitle + '; ' + RSEdition.RefEdition + '.')    
		  FROM (SELECT TOP 1    
			   RSE.RefStdTitle    
			  ,RSE.RefEdition    
			  ,RS.RefStdName    
			  ,RS.RefStdCode    
		   FROM [SLCMaster].[dbo].[ReferenceStandard] RS WITH(NOLOCK)    
		   INNER JOIN [SLCMaster].[dbo].[ReferenceStandardEdition] RSE WITH(NOLOCK)    
		   ON RS.RefStdId = RSE.RefStdId    
		   WHERE RS.RefStdCode = @RSCode    
		   ORDER BY RSE.RefStdEditionId DESC) RSEdition    
    
		  SELECT @segmentDescription = CONCAT(RSEdition.RefStdName, ' - ', RSEdition.RefStdTitle + '; ' + RSEdition.RefEdition + '.')    
		  FROM (SELECT TOP 1    
			RSE.RefStdTitle    
			  ,RSE.RefEdition    
			  ,RS.RefStdName    
			  ,RS.RefStdCode    
		 FROM [ReferenceStandard] RS WITH(NOLOCK)    
		 INNER JOIN [ReferenceStandardEdition] RSE WITH(NOLOCK)    
		 ON RS.RefStdId = RSE.RefStdId    
		 WHERE RS.RefStdCode = @RSCode    
		 ORDER BY RSE.RefStdEditionId DESC) RSEdition    
	END    
    
	--Commented for Bug: Location related GT are not appearing with Project Value in "Submittals Log Report  
	--SELECT    
	-- @segmentDescription = REPLACE(@segmentDescription,    
	-- CONCAT('{GT#', CONVERT(NVARCHAR(MAX), GlobalTermCode), '}'), [Value])    
	--FROM [SLCMaster].[dbo].[GlobalTerm] WITH(NOLOCK)    
  
    IF(@segmentDescription like '%{GT#%')
	BEGIN
		SELECT @segmentDescription = REPLACE(@segmentDescription,    
		CONCAT('{GT#', CONVERT(NVARCHAR(MAX), GlobalTermCode), '}'), [Value])    
		FROM [dbo].[ProjectGlobalTerm] WITH(NOLOCK)    
		WHERE ProjectId = @ProjectId    
		AND CustomerId = @CustomerId    
		AND ISNULL(IsDeleted,0) = 0    
    END
	RETURN @segmentDescription;    
END
GO

DROP function if exists fnGetSegmentDescriptionTextForChoice
GO
CREATE FUNCTION [dbo].[fnGetSegmentDescriptionTextForChoice]
(  
 @segmentStatusId int
)  
RETURNS nvarchar(max)  
AS  
BEGIN
	
	-- Declare the return variable here  
	DECLARE @ChoiceCounter int=1,@ChoiceCount int=0
	DECLARE @OptionCounter int=1,@OptionCount int=0
	DECLARE @ItemCounter int=1,@ItemCount int=0
	DECLARE @OptionTypeName NVARCHAR(255),@SortOrder INT,@Value NVARCHAR(255),@Id INT
	DECLARE @ChoiceOptionText NVARCHAR(1024)
	DECLARE @ProjectId int,@origin nvarchar(2),@sectionId int,@segmentId int,@mSegmentId int,@mSegmentStatusId INT
	DECLARE @Description NVARCHAR(1024),@sourceTag VARCHAR(10)
	DECLARE @segmentDescription NVARCHAR(max)=''

	SELECT 
	@ProjectId=ProjectId,@origin=SegmentOrigin,@sectionId=SectionId,
	@segmentId=SegmentId,@mSegmentId=mSegmentId,@mSegmentStatusId=mSegmentStatusId
	FROM dbo.ProjectSegmentStatus with (nolock)
	WHERE SegmentStatusId=@segmentStatusId
	
  --All Choices
	DECLARE @AllChoices TABLE(srNo int,choiceCode int);

	--All Choices with Options
	DECLARE @ChoiceTable TABLE  
	(  
	srNo int,  
	choiceCode int,  
	optionJson nvarchar(max),  
	finalChoiceText nvarchar(max),
	sortOrder int
	);

	--Single Choice with Options
	DECLARE @ChoiceTableTemp TABLE  
	(  
	srNo int,  
	choiceCode int,  
	optionJson nvarchar(max),  
	optionText nvarchar(max),
	sortOrder int
	);

	--All Options in single choice
	DECLARE @ChoiceOptionTable TABLE  
	(  
	srNo int,  
	OptionTypeName varchar(200),  
	SortOrder int,  
	Value nvarchar(1024),  
	Id int  
	);

	-- Segment Description for given @SegmentId  
	DECLARE @ChoiceCode int=0
	DECLARE @OptionJson nvarchar(max)=''
	DECLARE @Saperator nvarchar(5)=''

  
   --Step 1 : Get Segment Description based on origin  
   IF(@origin='M')  
   BEGIN
		select TOP 1 @segmentDescription=SegmentDescription FROM [SLCMaster].[dbo].[Segment] WITH(NOLOCK) where SegmentId=@mSegmentId
		IF(@segmentDescription like '%{CH#%')
		BEGIN
		
		-- All Choice Option for given Segment     
			INSERT INTO @ChoiceTable (srNo, ChoiceCode, optionJson, finalChoiceText,SortOrder)
				SELECT
					ROW_NUMBER() OVER (ORDER BY co.ChoiceOptionId) AS Id
				   ,sc.SegmentChoiceCode
				   ,co.OptionJson
				   ,''
				   ,co.SortOrder
				FROM [SLCMaster].[dbo].[SegmentChoice] AS sc  with (nolock)
				INNER JOIN [SLCMaster].[dbo].[ChoiceOption] AS co  with (nolock)
					ON sc.SegmentChoiceId = co.SegmentChoiceId
				INNER JOIN [SelectedChoiceOption] sco  with (nolock)
					ON  sco.SectionId=@sectionId
						AND sco.ChoiceOptionCode = co.ChoiceOptionCode
						AND sco.SegmentChoiceCode = sc.SegmentChoiceCode
				WHERE sc.SegmentStatusId=@mSegmentStatusId
				AND sco.SectionId=@sectionId
				AND sco.ProjectId=@ProjectId
				AND sco.IsSelected = 1 
				AND sco.ChoiceOptionSource='M'
				ORDER BY co.SortOrder;

				INSERT INTO @AllChoices
				SELECT distinct ROW_NUMBER() OVER (ORDER BY ChoiceCode) AS Id,* from
				(
				select distinct ChoiceCode from @ChoiceTable
				) as x

				--Get count of All Choices
				SET @ChoiceCount=(SELECT COUNT(1) FROM @AllChoices)

				WHILE(@ChoiceCounter<=@ChoiceCount)
				BEGIN
					SELECT @ChoiceCode=choiceCode FROM @AllChoices WHERE srNo=@ChoiceCounter
					SELECT TOP 1 @Saperator=IIF(ChoiceTypeId=2,' and ',IIF(ChoiceTypeId=3,' or ',''))
					 from [SLCMaster].[dbo].[SegmentChoice]  with (nolock) 
					 where SegmentStatusId=@mSegmentStatusId
					 and SegmentChoiceCode=@choiceCode
					--CLEAR @ChoiceTableTemp
					DELETE FROM @ChoiceTableTemp
					--Get all options
					INSERT INTO @ChoiceTableTemp
					SELECT  ROW_NUMBER() OVER (ORDER BY sortOrder ) AS Id,*
					FROM (
					SELECT DISTINCT ChoiceCode, optionJson, finalChoiceText,sortOrder FROM @ChoiceTable 
					WHERE choiceCode=@ChoiceCode) as x

					SET @optionCount=@@rowcount
					SET @OptionCounter=1
	
					--Iterate options
					WHILE(@OptionCounter<=@optionCount)
					BEGIN
						SELECT @OptionJson=optionJson FROM @ChoiceTableTemp WHERE srNo=@OptionCounter

						--CLEAR @ChoiceOptionTable
						DELETE FROM @ChoiceOptionTable
						--Get all items in options
						INSERT INTO @ChoiceOptionTable
						SELECT ROW_NUMBER() OVER (ORDER BY [SortOrder]) AS srNo,* FROM OPENJSON(@OptionJson)
						WITH (
							OptionTypeName NVARCHAR(200) '$.OptionTypeName',
							[SortOrder] INT '$.SortOrder',
							[Value] NVARCHAR(255) '$.Value',
							[Id] INT '$.Id'
						);

						SET @ItemCount=@@rowcount
						SET @ItemCounter=1
						SET @ChoiceOptionText=''
		
						--Iterate all items
						WHILE(@ItemCounter<=@ItemCount)
						BEGIN
							SELECT
								 @OptionTypeName = OptionTypeName
								,@SortOrder = SortOrder
								,@Value = Value
								,@Id = Id
							FROM @ChoiceOptionTable
							WHERE srNo = @ItemCounter

							IF (@OptionTypeName IN('CustomText','NoneNA','GlobalTerm', 'UnitOfMeasure'))
							BEGIN
								SET @ChoiceOptionText = CONCAT(@ChoiceOptionText,' ', @Value,' ')
							END 
							ELSE IF (@OptionTypeName IN('FillInBlank'))
							BEGIN
								IF(@Value='' OR @Value is null)
									SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, ' [_______] ')
								ELSE 
									SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value,' ')
							END 
						 
							ELSE IF(@OptionTypeName='SectionID')  
							BEGIN
								SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, (SELECT
									SourceTag
								FROM SLCMaster.dbo.Section WITH (NOLOCK)
								WHERE sectionid = @Id),' ')
							END  
							ELSE IF(@OptionTypeName='ReferenceStandard')  
							BEGIN
								SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value,' ')
  
							END  
							ELSE IF(@OptionTypeName='ReferenceEditionDate')  
							BEGIN
								SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value, '')
							END  
							ELSE IF(@OptionTypeName='SectionTitle')  
							BEGIN
								SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, (SELECT
									Description FROM SLCMaster.dbo.Section WITH (NOLOCK) WHERE sectionid = @Id),' '
								)
							END
							SET @ItemCounter=@ItemCounter+1
						END
		
						UPDATE @ChoiceTableTemp
						SET optionText=@ChoiceOptionText
						WHERE srNo=@OptionCounter and ChoiceCode=@ChoiceCode
					
						SET @OptionCounter=@OptionCounter+1
					END

					--set @ChoiceOptionText=(SELECT optionText+',' FROM @ChoiceTableTemp WHERE choiceCode=@ChoiceCode FOR XML PATH(''))
					DECLARE @count int,@i int=2

					SELECT @count=count(1) FROM @ChoiceTableTemp
					SELECT TOP 1 @ChoiceOptionText=optionText FROM @ChoiceTableTemp
					WHILE (@i<@count)
					BEGIN
						SET @ChoiceOptionText=CONCAT(@ChoiceOptionText,', ',(SELECT optionText FROM @ChoiceTableTemp WHERE srNo=@i))
						SET @i=@i+1
					END

					IF(@count>1)
					SET @ChoiceOptionText=CONCAT(@ChoiceOptionText,@Saperator,(SELECT optionText FROM @ChoiceTableTemp WHERE srNo=@i))

					SET @segmentDescription = REPLACE(@segmentDescription, CONCAT('{CH#', @choiceCode, '}'), @ChoiceOptionText)

					SET	@ChoiceCounter=@ChoiceCounter+1
				END
			END
	   END  
	   ELSE IF(@origin='U')  
	   BEGIN
			select TOP 1 @segmentDescription=SegmentDescription FROM [dbo].[ProjectSegment] WITH(NOLOCK) where SegmentId=@segmentId and SectionId=@SectionId 
			
			IF(@segmentDescription like '%{CH#%')
			BEGIN

			-- store all choices WITH OPTIONS
			INSERT INTO @ChoiceTable (srNo, ChoiceCode, optionJson, finalChoiceText,sortOrder)
			SELECT  
			ROW_NUMBER() OVER (ORDER BY co.ChoiceOptionId) AS Id
			,sc.SegmentChoiceCode
			,co.OptionJson
			,''   
			,co.SortOrder
			FROM [ProjectSegmentChoice] AS sc  with (nolock)
			INNER JOIN [ProjectChoiceOption] AS co with (nolock)
			ON co.SectionId = sc.SectionId
			and sc.SegmentChoiceId = co.SegmentChoiceId
			INNER JOIN [SelectedChoiceOption] sco with (nolock)
			ON sco.SectionId = sc.SectionId
			AND sco.ProjectId = sc.ProjectId
			AND sco.SegmentChoiceCode = sc.SegmentChoiceCode
			and sco.ChoiceOptionCode=co.ChoiceOptionCode
			WHERE sc.SectionId=@sectionId and  
			sc.SegmentStatusId=@segmentStatusId
			AND sco.IsSelected = 1  and sco.ChoiceOptionSource='U'
			ORDER BY co.SortOrder,sc.SegmentChoiceCode;

			--GET ALL CHOICES WITHOUT OPTIONS
			INSERT INTO @AllChoices
			SELECT distinct ROW_NUMBER() OVER (ORDER BY ChoiceCode) AS Id,* from
			(
			select distinct ChoiceCode from @ChoiceTable
			) as x

			--Get count of All Choices
			SET @ChoiceCount=(SELECT COUNT(1) FROM @AllChoices)
			--Iterate choices
			WHILE(@ChoiceCounter<=@ChoiceCount)
			BEGIN
				SELECT @ChoiceCode=choiceCode FROM @AllChoices WHERE srNo=@ChoiceCounter
				SELECT TOP 1 @Saperator=IIF(ChoiceTypeId=2,' and ',IIF(ChoiceTypeId=3,' or ','')) 
				from [dbo].[ProjectSegmentChoice] with (nolock)
				where SectionId=@sectionId and SegmentStatusId=@segmentStatusId
				AND SegmentChoiceCode=@choiceCode

				--CLEAR @ChoiceTableTemp
				DELETE FROM @ChoiceTableTemp
				--Get all options
				--INSERT INTO @ChoiceTableTemp
				--SELECT ROW_NUMBER() OVER (ORDER BY srNo) AS Id,ChoiceCode, optionJson, finalChoiceText FROM @ChoiceTable WHERE choiceCode=@ChoiceCode
				INSERT INTO @ChoiceTableTemp
				SELECT  ROW_NUMBER() OVER (ORDER BY sortOrder ) AS Id,*
				FROM (
				SELECT DISTINCT ChoiceCode, optionJson, finalChoiceText,sortOrder FROM @ChoiceTable WHERE choiceCode=@ChoiceCode) as x

				SET @optionCount=@@rowcount
				SET @OptionCounter=1
			  
				--Iterate options
				WHILE(@OptionCounter<=@optionCount)
				BEGIN
					SELECT @OptionJson=optionJson FROM @ChoiceTableTemp WHERE srNo=@OptionCounter

					--CLEAR @ChoiceOptionTable
					DELETE FROM @ChoiceOptionTable
					--Get all items in options
					INSERT INTO @ChoiceOptionTable
					SELECT ROW_NUMBER() OVER (ORDER BY [SortOrder]) AS srNo,* FROM OPENJSON(@OptionJson)
					WITH (
						OptionTypeName NVARCHAR(200) '$.OptionTypeName',
						[SortOrder] INT '$.SortOrder',
						[Value] NVARCHAR(255) '$.Value',
						[Id] INT '$.Id'
					);

					SET @ItemCount=@@rowcount
					SET @ItemCounter=1
					SET @ChoiceOptionText=''
		
					--Iterate all items
					WHILE(@ItemCounter<=@ItemCount)
					BEGIN
						SELECT
							 @OptionTypeName = OptionTypeName
							,@SortOrder = SortOrder
							,@Value = Value
							,@Id = Id
						FROM @ChoiceOptionTable
						WHERE srNo = @ItemCounter

						IF (@OptionTypeName IN('CustomText','NoneNA','GlobalTerm', 'UnitOfMeasure'))
						BEGIN
							SET @ChoiceOptionText = CONCAT(@ChoiceOptionText,' ', @Value,' ')
						END 
						ELSE IF (@OptionTypeName IN('FillInBlank'))
						BEGIN
							IF(@Value='' OR @Value is null)
								SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, ' [_______] ')
							ELSE 
								SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value,' ')
						END 
						ELSE IF(@OptionTypeName='SectionID')  
						BEGIN
							SET @ChoiceOptionText =	CONCAT(@ChoiceOptionText,@Value,' ')
							--set @sourceTag=(SELECT
							--SourceTag
							--FROM [SLCProject].[dbo].[ProjectSection]
							--WHERE sectionid = @Id and ProjectId=@ProjectId)

							--SET @ChoiceOptionText = CONCAT(@ChoiceOptionText,iif(@sourceTag is null OR LEN(@sourceTag)<=0,(SELECT
							--	SourceTag
							--FROM SLCMaster.dbo.Section
							--WHERE sectionid = @Id),@sourceTag)
							--)
  
						END  
						ELSE IF(@OptionTypeName='ReferenceStandard')  
						BEGIN
							SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value,' ')
  
						END  
						ELSE IF(@OptionTypeName='ReferenceEditionDate')  
						BEGIN
  
							SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value,'')
  
						END  
						ELSE IF(@OptionTypeName='SectionTitle')  
						BEGIN

						SET @Description=(SELECT
							Description
							FROM [ProjectSection] with (nolock)
							WHERE sectionid = @Id and ProjectId=@ProjectId)

							SET @ChoiceOptionText = CONCAT(@ChoiceOptionText,iif(@Description is null,(SELECT
								Description
							FROM SLCMaster.dbo.Section WITH (NOLOCK)
							WHERE sectionid = @Id),@Description),' '
							)
							--SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, (SELECT
							--Description
							--FROM [SLCProject].[dbo].[ProjectSection]
							--WHERE sectionid = @Id)
							--)
  
						END
					
						SET @ItemCounter=@ItemCounter+1
					END
		
					UPDATE @ChoiceTableTemp
					SET optionText=@ChoiceOptionText
					WHERE srNo=@OptionCounter and ChoiceCode=@ChoiceCode

					SET @OptionCounter=@OptionCounter+1
				END

				
				SELECT @count=count(1) FROM @ChoiceTableTemp
				SELECT TOP 1 @ChoiceOptionText=optionText FROM @ChoiceTableTemp
				WHILE (@i<@count)
				BEGIN
					SET @ChoiceOptionText=CONCAT(@ChoiceOptionText,', ',(SELECT optionText FROM @ChoiceTableTemp WHERE srNo=@i))
					SET @i=@i+1
				END

				IF(@count>1)
				SET @ChoiceOptionText=CONCAT(@ChoiceOptionText,@Saperator,(SELECT optionText FROM @ChoiceTableTemp WHERE srNo=@i))
	           
				SET @segmentDescription = REPLACE(@segmentDescription, CONCAT('{CH#', @choiceCode, '}'), @ChoiceOptionText)

				SET	@ChoiceCounter=@ChoiceCounter+1
			END
			END
	   END
  
   return @segmentDescription;
 
END
GO