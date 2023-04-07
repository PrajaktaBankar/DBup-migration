CREATE PROCEDURE [dbo].[usp_GetChoicesForPrint]
( @ProjectId int
 ,@CustomerId int
 ,@SectionIds nvarchar(max)
 ,@IsActiveOnly BIT = 1 
)
as
Begin
DECLARE @SectionIdTbl TABLE (SectionId INT); 
DECLARE @PProjectId INT = @ProjectId;                    
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PIsActiveOnly BIT = @IsActiveOnly;

--CONVERT STRING INTO TABLE                                        
 INSERT INTO @SectionIdTbl (SectionId)                    
 SELECT *                    
 FROM dbo.fn_SplitString(@SectionIds, ',');                    
       
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
 
 IF( @@rowcount > 0)
 BEGIN
  -- insert missing sco entries                        
 INSERT INTO BsdLogging..DBLogging (                    
  ArtifactName                    
  ,DBServerName                    
  ,DBServerIP                    
  ,CreatedDate                    
  ,LevelType                    
  ,InputData                    
  ,ErrorProcedure                    
  ,ErrorMessage                    
  )                    
 VALUES (                    
  'usp_GetSegmentsForPrint'                    
  ,@@SERVERNAME                    
  ,convert(NVARCHAR, CONNECTIONPROPERTY('local_net_address'))                    
  ,Getdate()                    
  ,'Information'                    
  ,('ProjectId: ' + @PProjectId +  ' CustomerId: ' + @PCustomerId + ' SectionIdsString:' + @SectionIds)        
  ,'Insert'                    
  ,('Scenario 1: SelectedChoiceOption Rows Inserted - ' + convert(NVARCHAR, @@ROWCOUNT))                    
  )                    
       
 END;                 
             
 -- Mark isdeleted =0 for SelectedChoiceOption                      
 UPDATE sco                    
 SET sco.isdeleted = 0                    
 FROM ProjectSegmentChoice psc WITH (NOLOCK)                    
 INNER JOIN @SectionIdTbl stb  ON psc.SectionId = stb.SectionId                    
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
  
  IF( @@rowcount > 0)
  BEGIN
  --                      
 INSERT INTO BsdLogging..DBLogging (                    
  ArtifactName         
  ,DBServerName                    
  ,DBServerIP                    
  ,CreatedDate                    
  ,LevelType                    
  ,InputData                    
  ,ErrorProcedure                    
  ,ErrorMessage                    
  )                    
 VALUES (                    
  'usp_GetSegmentsForPrint'                    
  ,@@SERVERNAME                    
  ,convert(NVARCHAR, CONNECTIONPROPERTY('local_net_address'))                    
  ,Getdate()                    
  ,'Information'                    
  ,('ProjectId: ' + @PProjectId +  ' CustomerId: ' + @PCustomerId + ' SectionIdsString:' + @SectionIds)     
  ,'Update'      
  ,('Scenario 2: SelectedChoiceOption Rows Updated - ' + convert(NVARCHAR, @@ROWCOUNT))                    
  )                    
     
  End;                  
                
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
 
 SELECT PSST.SectionId,PSST.SegmentId, PSST.mSegmentId INTO #tempPSS FROM @SectionIdTbl STBL
 INNER JOIN  ProjectSegmentStatus PSST WITH (NOLOCK)
 ON PSST.SectionId = STBL.SectionId 
 WHERE PSST.ProjectId = @PProjectId                    
  AND PSST.CustomerId = @PCustomerId                    
  AND ISNULL(PSST.IsDeleted,0)=0
    AND (                    
   @PIsActiveOnly = 0                    
   OR (                    
    PSST.SegmentStatusTypeId > 0                    
    AND PSST.SegmentStatusTypeId < 6                    
    AND PSST.IsParentSegmentStatusActive = 1                    
    )                    
   OR (PSST.IsPageBreak = 1)                    
   )    
     
                    
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
 FROM #tempPSS PSST WITH (NOLOCK)                    
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
  ,PCHOP.SortOrder                    
  ,PCH.SegmentChoiceId       
  ,PCHOP.ChoiceOptionId                    
  ,PSCHOP.SelectedChoiceOptionId                    
  ,PSST.SectionId                    
 FROM #tempPSS PSST WITH (NOLOCK)                    
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
                    
End;

GO

Alter PROCEDURE [dbo].[usp_GetSegmentsForPrint] (                  
 @ProjectId INT                  
 ,@CustomerId INT                  
 ,@SectionIdsString NVARCHAR(MAX)                  
 ,@UserId INT                  
 ,@CatalogueType NVARCHAR(MAX)                  
 ,@TCPrintModeId INT = 1                  
 ,@IsActiveOnly BIT = 1                
 ,@IsPrintMasterNote BIT =0         
 ,@IsPrintProjectNote BIT =0             
 )                    
AS                    
BEGIN            
SET NOCOUNT ON;        
 DECLARE @PProjectId INT = @ProjectId;                    
 DECLARE @PCustomerId INT = @CustomerId;                    
 DECLARE @PSectionIdsString NVARCHAR(MAX) = @SectionIdsString;                    
 DECLARE @PUserId INT = @UserId;                    
 DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;                    
 DECLARE @PTCPrintModeId INT = @TCPrintModeId;                    
 DECLARE @PIsActiveOnly BIT = @IsActiveOnly;  
 DECLARE @PIsPrintMasterNote BIT =@IsPrintMasterNote;
 DECLARE @PIsPrintProjectNote BIT =@IsPrintProjectNote;                  
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
 DECLARE @State VARCHAR(50)=''    
 DECLARE @City VARCHAR(50)=''    
                    
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
    
 IF EXISTS (SELECT COUNT(1) FROM ProjectAddress PA  WITH (NOLOCK) WHERE Projectid=@PProjectId AND PA.StateProvinceId=99999999 AND PA.StateProvinceName IS NULL)    
 BEGIN    
  SELECT TOP 1 @State = ISNULL(concat(rtrim(VALUE),','),'') FROM ProjectGlobalTerm  WITH (NOLOCK)    
  WHERE Projectid = @PProjectId AND (NAME = 'Project Location State' OR Name ='Project Location Province') 
  OPTION (FAST 1)   
 END    
 ELSE    
 BEGIN    
  SELECT TOP 1 @State = CONCAT(RTRIM(SP.StateProvinceAbbreviation),', ') FROM LuStateProvince SP WITH (NOLOCK)    
  INNER JOIN ProjectAddress PA WITH (NOLOCK) ON PA.StateProvinceId = SP.StateProvinceID     
  WHERE ProjectId = @PProjectId 
  OPTION (FAST 1)   
 END    
     
 IF EXISTS(SELECT COUNT(1) FROM ProjectAddress PA  WITH (NOLOCK) WHERE ProjectId = @PProjectId AND PA.CityId=99999999 AND PA.CityName IS NULL)    
 BEGIN    
  SELECT TOP 1 @City =ISNULL(VALUE,'') FROM ProjectGlobalTerm  WITH (NOLOCK) WHERE ProjectId = @PProjectId AND NAME = 'Project Location City'  
  OPTION (FAST 1)  
 END    
 ELSE    
 BEGIN    
  SELECT TOP 1 @City = CITY FROM LuCity C WITH (NOLOCK) INNER JOIN ProjectAddress PA ON PA.CityId = C.CityId WHERE Projectid=@PProjectId  
  OPTION (FAST 1)
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
 FROM @SectionIdTbl SIDTBL                    
 INNER JOIN ProjectSegmentStatus AS PSST WITH (NOLOCK) ON PSST.SectionId = SIDTBL.SectionId                    
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
 FROM #tmp_ProjectSegmentStatus PSST   WITH (NOLOCK)              
 ORDER BY PSST.SectionId                    
  ,PSST.SequenceNumber;                    
     
DROP TABLE IF EXISTS #tmpProjectSegmentStatusForNote;     

 --FETCH SegmentStatusId AND MSegmentStatusId DATA INTO TEMP TABLE         
SELECT PSST.SegmentStatusId                
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId   
  ,PSST.SectionId                   
 INTO #tmpProjectSegmentStatusForNote                      
 FROM @SectionIdTbl SIDTBL                    
 INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)  ON PSST.SectionId = SIDTBL.SectionId                     
 --WHERE PSST.ProjectId = @PProjectId     
 --AND PSST.CustomerId = @PCustomerId     
    
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
 FROM @SectionIdTbl STBL 
 INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                    
 ON PSST.SectionId = STBL.SectionId
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId       
 AND PS.SectionId  = STBL.SectionId            
 INNER JOIN ProjectSegment AS PSG WITH (NOLOCK) ON PSST.SegmentId = PSG.SegmentId  
 AND PSG.SectionId= STBL.SectionId                  
 WHERE PSG.ProjectId = @PProjectId                    
  AND PSG.CustomerId = @PCustomerId                    
 UNION  ALL                  
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
 FROM @SectionIdTbl STBL 
 INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                    
 ON PSST.SectionId = STBL.SectionId AND ISNULL(PSST.mSegmentId,0) > 0
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId  
 AND PS.SectionId  = STBL.SectionId                     
 INNER JOIN SLCMaster..Segment AS MSG WITH (NOLOCK) ON PSST.mSegmentId = MSG.SegmentId                    
 WHERE PS.ProjectId = @PProjectId                    
  AND PS.CustomerId = @PCustomerId 
   AND ISNULL(PSST.mSegmentId,0) > 0                   
        
 
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
  FROM Template T WITH (NOLOCK)                    
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
  FROM Template T WITH (NOLOCK)                    
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
 FROM TemplateStyle TS WITH (NOLOCK)                    
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
 FROM Style AS ST WITH (NOLOCK)                    
 INNER JOIN TemplateStyle AS TS WITH (NOLOCK) ON ST.StyleId = TS.StyleId                    
 INNER JOIN #tmp_Template T WITH (NOLOCK) ON TS.TemplateId = T.TemplateId        
  LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK) ON SPS.StyleId=ST.StyleId                
                    
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

  DECLARE @PSourceTagFormat NVARCHAR(10)='', @IsPrintReferenceEditionDate BIT, @UnitOfMeasureValueTypeId INT;
SELECT TOP 1 @PSourceTagFormat= SourceTagFormat
,@IsPrintReferenceEditionDate = PS.IsPrintReferenceEditionDate 
,@UnitOfMeasureValueTypeId = PS.UnitOfMeasureValueTypeId
FROM ProjectSummary PS WITH (NOLOCK) WHERE PS.ProjectId = @PProjectId
                    
 --SELECT SECTIONS DATA                                        
 SELECT S.SectionId AS SectionId                    
  ,ISNULL(S.mSectionId, 0) AS mSectionId                    
  ,S.Description                    
  ,S.Author                    
  ,S.SectionCode                    
  ,S.SourceTag                    
  ,@PSourceTagFormat SourceTagFormat    --PS.SourceTagFormat                 
  ,ISNULL(D.DivisionCode, '') AS DivisionCode                    
  ,ISNULL(D.DivisionTitle, '') AS DivisionTitle                    
  ,ISNULL(D.DivisionId, 0) AS DivisionId                    
  ,S.IsTrackChanges                    
 FROM #tmp_ProjectSection AS S WITH (NOLOCK)                    
 LEFT JOIN SLCMaster..Division D WITH (NOLOCK) ON S.DivisionId = D.DivisionId                    
 --INNER JOIN ProjectSummary PS WITH (NOLOCK) ON S.ProjectId = PS.ProjectId                    
 -- AND S.CustomerId = PS.CustomerId                    
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
  ,@PSourceTagFormat SourceTagFormat --P.SourceTagFormat                    
  ,ISNULL(D.DivisionCode, '') AS DivisionCode                    
  ,ISNULL(D.DivisionTitle, '') AS DivisionTitle                    
  ,ISNULL(D.DivisionId, 0) AS DivisionId                    
  ,CONVERT(BIT, 0) AS IsTrackChanges                    
 FROM SLCMaster..Section MS WITH (NOLOCK)                    
 LEFT JOIN SLCMaster..Division D WITH (NOLOCK) ON MS.DivisionId = D.DivisionId                    
 --INNER JOIN ProjectSummary P WITH (NOLOCK) ON P.ProjectId = @PProjectId                    
 -- AND P.CustomerId = @PCustomerId                  
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
 INNER JOIN ProjectUserTag PUT WITH (NOLOCK) ON PSUT.UserTagId = PUT.UserTagId                    
 INNER JOIN #tmp_ProjectSegmentStatus PSST WITH (NOLOCK) ON PSUT.SegmentStatusId = PSST.SegmentStatusId                    
 WHERE PSUT.ProjectId = @PProjectId                    
  AND PSUT.CustomerId = @PCustomerId             
      
 --SELECT Project Summary information                                        
 SELECT P.ProjectId AS ProjectId                    
  ,P.Name AS ProjectName                    
  ,'' AS ProjectLocation                    
  ,@IsPrintReferenceEditionDate AS IsPrintReferenceEditionDate                    
  ,@PSourceTagFormat AS SourceTagFormat                    
  ,CONCAT(@State,@City) AS DbInfoProjectLocationKeyword                    
  ,ISNULL(PGT.value, '') AS ProjectLocationKeyword                    
  ,@UnitOfMeasureValueTypeId AS UnitOfMeasureValueTypeId                    
 FROM Project P WITH (NOLOCK)                    
 --INNER JOIN ProjectSummary PS WITH (NOLOCK) ON P.ProjectId = PS.ProjectId                    
 INNER JOIN ProjectAddress PA WITH (NOLOCK) ON P.ProjectId = PA.ProjectId                    
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
 FROM ReferenceStandard PREFSTD WITH (NOLOCK)                    
 WHERE PREFSTD.CustomerId = @PCustomerId                    
                    
 --SELECT REFERENCE EDITION DATA                                        
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
                     
 UNION                    
                     
 SELECT PREFEDN.RefStdId                    
  ,PREFEDN.RefStdEditionId                    
  ,PREFEDN.RefEdition                    
  ,PREFEDN.RefStdTitle                    
  ,PREFEDN.LinkTarget                    
  ,'U' AS RefEdnSource                    
 FROM ReferenceStandardEdition PREFEDN WITH (NOLOCK)                    
 WHERE PREFEDN.CustomerId = @PCustomerId                    
                    
 --SELECT ProjectReferenceStandard MAPPING DATA                                        
 SELECT PREFSTD.RefStandardId                    
  ,PREFSTD.RefStdSource                    
  ,COALESCE(PREFSTD.mReplaceRefStdId, 0) AS mReplaceRefStdId                    
  ,PREFSTD.RefStdEditionId                    
  ,SIDTBL.SectionId                    
 FROM @SectionIdTbl SIDTBL                    
 INNER JOIN ProjectReferenceStandard PREFSTD WITH (NOLOCK) ON PREFSTD.SectionId = SIDTBL.SectionId                    
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
      
IF(@IsPrintMasterNote = 1  OR @IsPrintProjectNote =1)
BEGIN
/*Start - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/      
SELECT     
NoteId    
,PN.SectionId      
,PSS.SegmentStatusId       
,PSS.mSegmentStatusId       
,CASE WHEN Title != '' THEN CONCAT(Title,'<br/>', NoteText)     
 ELSE NoteText END NoteText      
,PN.ProjectId    
,PN.CustomerId    
,PN.IsDeleted    
,NoteCode ,    
PN.Title    
FROM @SectionIdTbl SIDTBL     
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK) ON PSS.SectionId  = SIDTBL.SectionId  
INNER JOIN  ProjectNote PN WITH (NOLOCK)  ON PN.SegmentStatusId = PSS.SegmentStatusId
AND PN.ProjectId= @PProjectId AND PN.SectionId = PSS.SectionId 
WHERE PN.ProjectId=@PProjectId and PN.CustomerId=@PCustomerId AND ISNULL(PN.IsDeleted, 0) = 0      
UNION ALL      
SELECT NoteId      
,0 SectionId      
,PSS.SegmentStatusId       
,PSS.mSegmentStatusId       
,NoteText      
,@PProjectId As ProjectId       
,@PCustomerId As CustomerId       
,0 IsDeleted      
,0 NoteCode ,    
'' As Title    
 FROM @SectionIdTbl SIDTBL  
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK)    
ON PSS.SectionId = SIDTBL.SectionId  
INNER JOIN SLCMaster..Note MN  WITH (NOLOCK)   ON
 ISNULL(PSS.mSegmentStatusId, 0) > 0 and  MN.SegmentStatusId = PSS.mSegmentStatusId 
 AND PSS.SectionId = SIDTBL.SectionId 
 WHERE ISNULL(PSS.mSegmentStatusId, 0) > 0   
    
/*End - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/      
End;

END 

Go

Alter PROCEDURE [dbo].[usp_GetTagReports]                    
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
 SegmentStatusId INT          
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
 WHERE PSUT.ProjectId = @PProjectId          
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
 PS.SectionId          
   ,PS.DivisionId          
   ,PS.DivisionCode          
   ,PS.[Description]          
   ,PS.SourceTag          
   ,PS.Author          
   ,PS.SectionCode          
   ,SCTS.Tagid          
   ,SCTS.TagName          
FROM ProjectSection PS WITH (NOLOCK)          
JOIN #SectionsContainingTaggedSegments SCTS          
 ON PS.ProjectId = SCTS.ProjectId          
  AND PS.SectionId = SCTS.SectionId          
  AND PS.CustomerId = SCTS.CustomerId          
WHERE PS.ProjectId = @PProjectId          
AND PS.CustomerId = @PCustomerId          
ORDER BY SCTS.Tagname, PS.SourceTag;          
          
--Select Division For Sections who has tagged segments                    
SELECT DISTINCT          
 D.DivisionId          
   ,D.DivisionCode          
   ,D.DivisionTitle          
   ,D.SortOrder          
   ,D.IsActive          
   ,D.MasterDataTypeId          
   ,D.FormatTypeId          
FROM SLCMaster..Division D WITH (NOLOCK)          
INNER JOIN ProjectSection PS WITH (NOLOCK)          
 ON PS.DivisionId = D.DivisionId          
JOIN #SectionsContainingTaggedSegments SCTS WITH (NOLOCK)          
 ON PS.ProjectId = SCTS.ProjectId          
  AND PS.SectionId = SCTS.SectionId          
  AND PS.CustomerId = SCTS.CustomerId          
WHERE PS.ProjectId = @PProjectId          
AND PS.CustomerId = @PCustomerId          
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
