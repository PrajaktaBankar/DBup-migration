CREATE PROCEDURE [dbo].[usp_GetSegmentsForPrint]
  (                                                                
  @ProjectId INT                                                                
 ,@CustomerId INT                                                                
 ,@SectionIdsString NVARCHAR(MAX)                                                                
 ,@UserId INT                                                                
 ,@CatalogueType NVARCHAR(MAX)                                                                
 ,@TCPrintModeId INT = 1                                                                
 ,@IsActiveOnly BIT = 1                                                              
 ,@IsPrintMasterNote BIT =0                                                       
 ,@IsPrintProjectNote BIT =0                                   
 ,@DocumentTypeId INT =1                               
 )                                                                  
AS                                                                  
BEGIN           
SET NOCOUNT ON;   

DROP TABLE IF EXISTS #tmp_ProjectSegmentStatus_Main
DROP TABLE IF EXISTS #ProjectReferenceStandard
DROP TABLE IF EXISTS #tmp_ProjectSegmentStatus_TC

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
 DECLARE @IsTrue BIT = 1;                                                                            
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
 DECLARE @SectionIdTbl TABLE (SectionId INT, mSectionId INT);                                                                            
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
 DECLARE @TRUE BIT=1, @FALSE BIT=0
 DECLARE @DefaultTemplate int = 1, @DefaultTemplateName varchar(10)='CSI Format'

 --CONVERT STRING INTO TABLE                                                                                     
 INSERT INTO @SectionIdTbl (SectionId, mSectionId)                                                                            
 SELECT *, NULL
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
 --DROP TABLE                                                             
                               
 --IF EXISTS #tmp_ProjectSegmentStatus;                           
 CREATE TABLE #tmp_ProjectSegmentStatus_Main (                        
SegmentStatusId BIGINT                                                            
,SectionId INT
,mSectionId INT
,ParentSegmentStatusId BIGINT                                                                           
,mSegmentStatusId  BIGINT                        
,mSegmentId INT                                                                 
, SegmentId BIGINT                                                                   
,SegmentSource NVARCHAR(10)                                                                       
,SegmentOrigin NVARCHAR(10)                                                               
,IndentLevel INT                                                                           
,SequenceNumber  INT                                                                          
,SegmentStatusTypeId INT                                                                          
,SegmentStatusCode BIGINT                                                                         
,IsParentSegmentStatusActive BIT                                       
,IsShowAutoNumber BIT                                                
,FormattingJson NVARCHAR(MAX)                                                                           
,TagType NVARCHAR(50)                                        
,SpecTypeTagId INT                                                                        
,IsRefStdParagraph BIT                                                                     
,IsPageBreak BIT                            
,TrackOriginOrder NVARCHAR(100)                                                                           
,MTrackDescription NVARCHAR(MAX)                                                     
,TrackChangeType NVARCHAR(50)                                
,IsStatusTrack BIT
,ProjectId INT
,CustomerId INT
)                                           

 CREATE TABLE #tmp_ProjectSegmentStatus_TC (                        
SegmentStatusId BIGINT                                                            
,SectionId INT                                                                          
,ParentSegmentStatusId BIGINT                                                                           
,mSegmentStatusId  BIGINT                        
,mSegmentId INT                                                                 
, SegmentId BIGINT                                                                   
,SegmentSource NVARCHAR(10)                                                                       
,SegmentOrigin NVARCHAR(10)                                                               
,IndentLevel INT                                                                           
,SequenceNumber  INT                                                                          
,SegmentStatusTypeId INT                                                                          
,SegmentStatusCode BIGINT                                                                         
,IsParentSegmentStatusActive BIT                                                                           
,IsShowAutoNumber BIT                                                
,FormattingJson NVARCHAR(MAX)                                                                           
,TagType NVARCHAR(50)                                        
,SpecTypeTagId INT                              
,IsRefStdParagraph BIT                                                                     
,IsPageBreak BIT                            
,TrackOriginOrder NVARCHAR(100)                     
,MTrackDescription NVARCHAR(MAX)                                                     
,TrackChangeType NVARCHAR(50)                         
,IsStatusTrack BIT
)

                                   
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
   ,PS.SortOrder
   ,ISNULL(PS.SectionSource,1) as SectionSource  
   ,CONVERT(nvarchar(250), '') as Documentpath       
  INTO #tmp_ProjectSection                                                                            
  FROM ProjectSection PS WITH (NOLOCK)                                                                            
  WHERE PS.ProjectId = @PProjectId                                                                            
   AND PS.CustomerId = @PCustomerId                                                                            
   AND ISNULL(PS.IsDeleted, 0) = 0;   
     
  Update TPS  set TPS.Documentpath=SD.DocumentPath  
  from  #tmp_ProjectSection TPS inner join  SectionDocument SD WITH (NOLOCK) ON TPS.SectionId=SD.SectionId  and  tps.ProjectId=SD.ProjectId where ISNULL(TPS.SectionSource,0)=8                                                                               
   
	UPDATE A SET A.mSectionId = B.mSectionId
	FROM @SectionIdTbl A INNER JOIN #tmp_ProjectSection B ON A.SectionId = B.SectionId
                                   
--FETCH SEGMENT STATUS DATA INTO TEMP TABLE WITH TRACK CHANGES                                        
IF ((@PTCPrintModeId = @Lu_AllWithMarkups OR @PTCPrintModeId = @Lu_InheritFromSection) AND @PIsActiveOnly = @IsTrue)                           
BEGIN       

	INSERT INTO #tmp_ProjectSegmentStatus_TC                      
		EXEC usp_GetSegmentStatusDataWithTCForPrint @IsActiveOnly,@TCPrintModeId,@PSectionIdsString,@PCatalogueType,@PProjectId,@PCustomerId  

	--FETCH SEGMENT STATUS DATA INTO TEMP TABLE                           
	INSERT INTO                       
		#tmp_ProjectSegmentStatus_Main (SegmentStatusId,SectionId, mSectionId ,ParentSegmentStatusId ,mSegmentStatusId  ,mSegmentId , SegmentId ,SegmentSource 
			,SegmentOrigin ,IndentLevel ,SequenceNumber  ,SegmentStatusTypeId ,SegmentStatusCode ,IsParentSegmentStatusActive ,IsShowAutoNumber 
			,FormattingJson ,TagType ,SpecTypeTagId ,IsRefStdParagraph ,IsPageBreak ,TrackOriginOrder ,MTrackDescription ,TrackChangeType ,IsStatusTrack )                 
		SELECT SegmentStatusId,A.SectionId, SIDTBL.mSectionId ,ParentSegmentStatusId ,mSegmentStatusId  ,mSegmentId , SegmentId ,SegmentSource 
			,SegmentOrigin ,IndentLevel ,SequenceNumber  ,SegmentStatusTypeId ,SegmentStatusCode ,IsParentSegmentStatusActive ,IsShowAutoNumber 
			,FormattingJson ,TagType ,SpecTypeTagId ,IsRefStdParagraph ,IsPageBreak ,TrackOriginOrder ,MTrackDescription ,TrackChangeType ,IsStatusTrack  
		FROM #tmp_ProjectSegmentStatus_TC A
		INNER JOIN @SectionIdTbl SIDTBL ON A.SectionId = SIDTBL.SectionId                    

	UPDATE #tmp_ProjectSegmentStatus_Main SET ProjectId = @PProjectId, CustomerId = @PCustomerId 

  --SELECT SEGMENT STATUS DATA                                     
 SELECT SegmentStatusId,SectionId,ParentSegmentStatusId,mSegmentStatusId,mSegmentId,SegmentId,SegmentSource,SegmentOrigin                                                        
 ,IndentLevel,SequenceNumber,SegmentStatusTypeId,isnull(SegmentStatusCode,0) as SegmentStatusCode,IsParentSegmentStatusActive                                                        
 ,IsShowAutoNumber, COALESCE(TagType,'')TagType,isnull(SpecTypeTagId,0)as SpecTypeTagId,COALESCE(FormattingJson,'') as FormattingJson                                   
 ,IsRefStdParagraph,IsPageBreak,COALESCE(TrackOriginOrder,'') AS TrackOriginOrder, @PProjectId as ProjectId                                                        
  ,@PCustomerId as CustomerId ,IsStatusTrack ,TrackChangeType, 0 AS IsGreyBackground
 FROM #tmp_ProjectSegmentStatus_Main PSST WITH (NOLOCK)                                               
 WHERE @IsActiveOnly = 0 OR TrackChangeType IN ('AddedParagraph', 'RemovedParagraph','Untouched')                                            
 ORDER BY PSST.SectionId                                                                            
  ,PSST.SequenceNumber;                         
                        
END                        
--FETCH SEGMENT STATUS DATA INTO TEMP TABLE WITHOUT TRACK CHANGES                        
ELSE                    
BEGIN                        
--FETCH SEGMENT STATUS DATA INTO TEMP TABLE                          
INSERT INTO #tmp_ProjectSegmentStatus_Main                                                                                             
 SELECT PSST.SegmentStatusId                                                                      
  ,PSST.SectionId
  ,SIDTBL.mSectionId
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
  ,'' AS TrackChangeType                                 
  ,CAST(0 AS BIT) AS IsStatusTrack
  ,@PProjectId
  ,@PCustomerId
 FROM @SectionIdTbl SIDTBL                                                                          
 INNER JOIN ProjectSegmentStatus AS PSST WITH (NOLOCK) ON PSST.ProjectId = @PProjectId AND PSST.SectionId = SIDTBL.SectionId                                                                            
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
     PSST.SegmentStatusTypeId>0 AND PSST.SegmentStatusTypeId<6 AND PSST.IsParentSegmentStatusActive=1                                  
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

DROP TABLE IF EXISTS #tmpProjectSegmentStatusView;
DROP TABLE IF EXISTS #tmpLinks;

SELECT sv.SectionId, sv.mSectionId, sv.SegmentStatusId, sv.SectionCode, sv.SegmentStatusCode, sv.SegmentCode, sv.SequenceNumber, sv.IsDeleted
INTO #tmpProjectSegmentStatusView
FROM SLCProject.dbo.ProjectSegmentStatusView sv
INNER JOIN @SectionIdTbl sc ON sc.mSectionId = sv.mSectionId
WHERE CustomerId = @PCustomerId AND ProjectId = @PProjectId AND ISNULL(sv.IsDeleted, 0) = 0

SELECT sv.mSectionId, sl.SourceSectionCode, sl.SourceSegmentStatusCode, sl.SourceSegmentCode
	,sl.TargetSectionCode, sl.TargetSegmentStatusCode, sl.TargetSegmentCode, sl.LinkStatusTypeId
	,sv.SequenceNumber as TargetSequenceNumber
INTO #tmpLinks
from [SLCMaster].dbo.SegmentLink sl WITH (NOLOCK)
INNER JOIN #tmpProjectSegmentStatusView sv WITH (NOLOCK) ON sv.SectionCode = sl.SourceSectionCode AND sv.SectionCode = sl.TargetSectionCode AND sv.SegmentStatusCode = sl.TargetSegmentStatusCode AND sv.SegmentCode = sl.TargetSegmentCode
WHERE sl.IsDeleted = 0 AND ISNULL(sl.SourceSegmentChoiceCode, 0) = 0 AND ISNULL(sl.SourceChoiceOptionCode, 0) = 0
	AND ISNULL(sl.TargetSegmentChoiceCode, 0) = 0 AND ISNULL(sl.TargetChoiceOptionCode, 0) = 0
	AND sl.LinkSource='M' --AND sl.LinkStatusTypeId <> 3
	AND sv.IsDeleted=0
ORDER BY sl.TargetSectionCode, sv.SequenceNumber

SELECT DISTINCT PSST.SegmentStatusId,PSST.SectionId,PSST.ParentSegmentStatusId,PSST.mSegmentStatusId,PSST.mSegmentId,PSST.SegmentId,PSST.SegmentSource,PSST.SegmentOrigin                                                        
	,PSST.IndentLevel,PSST.SequenceNumber,PSST.SegmentStatusTypeId,isnull(PSST.SegmentStatusCode,0) as SegmentStatusCode,PSST.IsParentSegmentStatusActive                                                        
	,IsShowAutoNumber, COALESCE(TagType,'')TagType,isnull(PSST.SpecTypeTagId,0)as SpecTypeTagId,COALESCE(FormattingJson,'') as FormattingJson                                                        
	,IsRefStdParagraph,IsPageBreak,COALESCE(TrackOriginOrder,'') AS TrackOriginOrder, @PProjectId as ProjectId                                                        
	,@PCustomerId as CustomerId ,IsStatusTrack ,TrackChangeType, lnk.LinkStatusTypeId
	--,CASE WHEN lnk.LinkStatusTypeId IS NULL THEN 0 WHEN lnk.LinkStatusTypeId <> 3 THEN 1 ELSE 0 END IsGreyBackground
	,CASE WHEN lnk.LinkStatusTypeId = 3 THEN 0 ELSE 1 END IsGreyBackground
FROM #tmp_ProjectSegmentStatus_Main PSST WITH (NOLOCK)
LEFT JOIN #tmpProjectSegmentStatusView B ON PSST.SectionId = B.SectionId AND PSST.ParentSegmentStatusId = B.SegmentStatusId
LEFT JOIN #tmpLinks lnk ON lnk.mSectionId = PSST.mSectionId AND PSST.SegmentStatusCode = lnk.TargetSegmentStatusCode AND B.SegmentStatusCode = lnk.SourceSegmentStatusCode
ORDER BY PSST.SectionId, PSST.SequenceNumber;

END                        
                        
DROP TABLE IF EXISTS #tmpProjectSegmentStatusForNote;                                                             
                                                        
 --FETCH SegmentStatusId AND MSegmentStatusId DATA INTO TEMP TABLE     
SELECT PSST.SegmentStatusId                                                                        
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId                                           
  ,PSST.SectionId                                                                           
 INTO #tmpProjectSegmentStatusForNote                                                                              
 FROM @SectionIdTbl SIDTBL                                                                            
 INNER JOIN #tmp_ProjectSegmentStatus_Main AS PSST WITH (NOLOCK)  ON PSST.SectionId = SIDTBL.SectionId                                                                             
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
  ,ISNULL(PSG.SegmentCode ,0)SegmentCode                                                        
  ,@PProjectId as ProjectId                                                        
  ,@PCustomerId as CustomerId                                                        
 FROM @SectionIdTbl STBL                                                         
 INNER JOIN #tmp_ProjectSegmentStatus_Main AS PSST WITH (NOLOCK)                                                            
 ON PSST.SectionId = STBL.SectionId                                                        
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId                                                             
 AND PS.SectionId  = STBL.SectionId                                                                    
 INNER JOIN ProjectSegment AS PSG WITH (NOLOCK) ON PSST.SegmentId = PSG.SegmentId                                                          
 AND PSG.ProjectId = @PProjectId AND PSG.SectionId= STBL.SectionId                                                    
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
  ,ISNULL(MSG.SegmentCode ,0)SegmentCode                                            
  ,@PProjectId as ProjectId                                        
  ,@PCustomerId as CustomerId                                                        
 FROM @SectionIdTbl STBL                                                         
 INNER JOIN #tmp_ProjectSegmentStatus_Main AS PSST WITH (NOLOCK)                                                                            
 ON PSST.SectionId = STBL.SectionId AND ISNULL(PSST.mSegmentId,0) > 0                                                        
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId                                                          
 AND PS.SectionId  = STBL.SectionId                                                                             
 INNER JOIN SLCMaster..Segment AS MSG WITH (NOLOCK) ON PSST.mSegmentId = MSG.SegmentId                                                     
 WHERE PS.ProjectId = @PProjectId                                                                            
  AND PS.CustomerId = @PCustomerId                                                         
   AND ISNULL(PSST.mSegmentId,0) > 0                                                              
                                                                
-- Get Default Template ID (CSI Template of Customer)
SELECT @DefaultTemplate=TemplateID FROM Template WHERE CustomerId=@CustomerId and isnull(IsSystem,0)=1 and [Name]=@DefaultTemplateName
IF @@ROWCOUNT = 0 SET @DefaultTemplate=1 --just in case default to original CSI template 

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
  INNER JOIN Project P WITH (NOLOCK) ON T.TemplateId = COALESCE(P.TemplateId, @DefaultTemplate)                                                                            
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
  ,@PCustomerId as CustomerId                                                                            
 FROM #tmp_Template T                                                                            
                                                                            
 --SELECT TEMPLATE STYLE DATA                                 
 SELECT TS.TemplateStyleId                                                              
  ,TS.TemplateId                                                                            
  ,TS.StyleId                                                                            
  ,TS.LEVEL                                                         
  ,@PCustomerId as CustomerId                                                        
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
  ,@PCustomerId as CustomerId                                                        
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
  ,ISNULL(PGT.GlobalTermCode,0) AS GlobalTermCode             
  ,COALESCE(PGT.UserGlobalTermId, 0) AS UserGlobalTermId                                                                            
  ,GlobalTermFieldTypeId AS GTFieldType                                                            
  ,@PProjectId as ProjectId                                            
  ,@PCustomerId as CustomerId                                                       
 FROM ProjectGlobalTerm PGT WITH (NOLOCK)                                                                            
 WHERE PGT.ProjectId = @PProjectId                                                                            
  AND PGT.CustomerId = @PCustomerId;                                                                            
                                                        
  DECLARE @PSourceTagFormat NVARCHAR(10)='', @IsPrintReferenceEditionDate BIT, @UnitOfMeasureValueTypeId INT;                                                        
SELECT TOP 1 @PSourceTagFormat= SourceTagFormat                                                        
,@IsPrintReferenceEditionDate = PS.IsPrintReferenceEditionDate                                                         
,@UnitOfMeasureValueTypeId = ISNULL(PS.UnitOfMeasureValueTypeId,0)                                                        
FROM ProjectSummary PS WITH (NOLOCK) WHERE PS.ProjectId = @PProjectId                                                        
                                                                            
 --SELECT SECTIONS DATA                                                                                                
 SELECT S.SectionId AS SectionId      
 ,S.ParentSectionId
  ,ISNULL(S.mSectionId, 0) AS mSectionId                                                                            
  ,S.Description                                                                            
  ,COALESCE(S.Author,'') as Author                                                                           
  ,ISNULL(S.SectionCode ,0)   AS SectionCode                                                                        
  ,COALESCE(S.SourceTag,'') as SourceTag                                                                           
  ,@PSourceTagFormat SourceTagFormat    --PS.SourceTagFormat                                               
  ,ISNULL(D.DivisionCode, '') AS DivisionCode                                                                            
  ,ISNULL(D.DivisionTitle, '') AS DivisionTitle                                                                            
,ISNULL(D.DivisionId, 0) AS DivisionId                                                                            
  ,ISNULL(S.IsTrackChanges, CONVERT(BIT,0)) AS IsTrackChanges    
  ,IIF(S.SectionSource=8,@TRUE,@FALSE) as IsAlternateDocument  
   ,S.Documentpath    
   ,S.SortOrder
 FROM #tmp_ProjectSection AS S WITH (NOLOCK)                               
 LEFT JOIN SLCMaster..Division D WITH (NOLOCK) ON S.DivisionId = D.DivisionId           
 --INNER JOIN ProjectSummary PS WITH (NOLOCK) ON S.ProjectId = PS.ProjectId                                                                  
 -- AND S.CustomerId = PS.CustomerId                                                                            
 WHERE S.ProjectId = @PProjectId                                                                   
  AND S.CustomerId = @PCustomerId                                                                            
  AND S.IsLastLevel = 1                                                                            
AND ISNULL(S.IsDeleted, 0) = 0                
UNION          
 SELECT S.SectionId AS SectionId      
 ,S.ParentSectionId
  ,ISNULL(S.mSectionId, 0) AS mSectionId                                                                            
  ,S.Description                                                                            
  ,COALESCE(S.Author,'') as Author                                                                           
  ,ISNULL(S.SectionCode ,0)   AS SectionCode                                                                        
  ,COALESCE(S.SourceTag,'') as SourceTag                                                                           
  ,@PSourceTagFormat SourceTagFormat    --PS.SourceTagFormat                                               
  ,ISNULL(CD.DivisionCode, '') AS DivisionCode                                                                            
  ,ISNULL(CD.DivisionTitle, '') AS DivisionTitle                                                                            
,ISNULL(S.DivisionId, 0) AS DivisionId                                                                            
  ,ISNULL(S.IsTrackChanges, CONVERT(BIT,0)) AS IsTrackChanges     
  ,IIF(S.SectionSource=8,@TRUE,@FALSE) as IsAlternateDocument  
  ,S.Documentpath    
  ,S.SortOrder
 FROM #tmp_ProjectSection AS S WITH (NOLOCK)             
 LEFT JOIN CustomerDivision CD WITH (NOLOCK)          
 ON S.DivisionId = CD.DivisionId          
 AND S.CustomerId = CD.CustomerId          
 WHERE S.ProjectId = @PProjectId          
  AND S.CustomerId = @PCustomerId                                                                            
  AND S.IsLastLevel = 1                                                                            
AND ISNULL(S.IsDeleted, 0) = 0   
AND ISNULL(CD.DivisionTitle, '') != ''    
 UNION                                                                            
 SELECT 0 AS SectionId  
 ,0 AS ParentSectionId
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
  ,IIF(PS.SectionSource=8,@TRUE,@FALSE) as IsAlternateDocument  
  ,PS.Documentpath    
  ,PS.SortOrder
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
   END AS IsMasterAppliedTag                                                                            
  ,PSST.SectionId                                       
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)                                                      
 INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK) ON PSRT.RequirementTagId = LPRT.RequirementTagId                                                                            
INNER JOIN #tmp_ProjectSegmentStatus_Main AS PSST WITH (NOLOCK) ON PSRT.SegmentStatusId = PSST.SegmentStatusId                                                                            
 WHERE PSRT.ProjectId = @PProjectId                                                                            
 AND PSRT.CustomerId = @PCustomerId                                                                            
                                                                                 
 --SELECT REQUIRED IMAGES DATA                                                                                                
 SELECT                                                        
  PIMG.SegmentImageId                                                                      
 ,IMG.ImageId                                                                      
 ,IMG.ImagePath                                                                      
 ,COALESCE(PIMG.ImageStyle,'')  as ImageStyle                                                                    
 ,PIMG.SectionId                                                                       
 ,ISNULL(IMG.LuImageSourceTypeId,0) as LuImageSourceTypeId                                                        
                                                                    
 FROM ProjectSegmentImage PIMG WITH (NOLOCK)                                                                            
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PIMG.ImageId = IMG.ImageId                                                                            
 --INNER JOIN @SectionIdTbl SIDTBL ON PIMG.SectionId = SIDTBL.SectionId  //To resolved cross section images in headerFooter                                                      
 WHERE PIMG.ProjectId = @PProjectId                                                                            
  AND PIMG.CustomerId = @PCustomerId                                                                            
  AND IMG.LuImageSourceTypeId IN(@ImagSegment,@ImageHeaderFooter)                                                              
UNION ALL -- This union to ge Note images                                                              
 SELECT                                                                       
  0 SegmentImageId                                                                      
 ,PN.ImageId          
 ,IMG.ImagePath                                                       
 ,'' ImageStyle                                                                      
 ,PN.SectionId                                                                       
 ,ISNULL(IMG.LuImageSourceTypeId,0) as   LuImageSourceTypeId                                                             
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
 ,'' ImageStyle                                                                        
 ,NI.SectionId                                                                         
 ,ISNULL(MIMG.LuImageSourceTypeId,0) as    LuImageSourceTypeId                                                             
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
 INNER JOIN #tmp_ProjectSegmentStatus_Main PSST WITH (NOLOCK) ON PSUT.SegmentStatusId = PSST.SegmentStatusId                                                                            
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
 SELECT MREFSTD.RefStdId as Id                                          
  ,COALESCE(MREFSTD.RefStdName, '') AS RefStdName                                                                            
  ,'M' AS RefStdSource                                                                            
  ,COALESCE(MREFSTD.ReplaceRefStdId, 0) AS ReplaceRefStdId                                                                            
  ,'M' AS ReplaceRefStdSource                                                   
  ,MREFSTD.IsObsolete AS IsObsolute       
  ,COALESCE(MREFSTD.RefStdCode, 0) AS RefStdCode                                                                            
 FROM SLCMaster..ReferenceStandard MREFSTD WITH (NOLOCK)                                            
 WHERE MREFSTD.MasterDataTypeId = CASE                                                                             
WHEN @MasterDataTypeId = 2                                                                            
    OR @MasterDataTypeId = 3                                                                            
THEN 1                                                                            
   ELSE @MasterDataTypeId                                                                            
   END                                                                            
                                                                             
 UNION                                                                            
                                                        
 SELECT PREFSTD.RefStdId  as Id                                                                          
  ,PREFSTD.RefStdName                                                                            
  ,'U' AS RefStdSource       
  ,COALESCE(PREFSTD.ReplaceRefStdId, 0) AS ReplaceRefStdId                                                  
  ,COALESCE(PREFSTD.ReplaceRefStdSource, '') AS ReplaceRefStdSource                                                                            
  ,PREFSTD.IsObsolete as IsObsolute                                                                           
  ,COALESCE(PREFSTD.RefStdCode, 0) AS RefStdCode                                                                            
 FROM ReferenceStandard PREFSTD WITH (NOLOCK)                                                                            
 WHERE PREFSTD.CustomerId = @PCustomerId                                                                 
                    
 --SELECT REFERENCE EDITION DATA                           
                   
                   
 DECLARE @table_RefStandardWithEditionId TABLE (                                  
    RefStdId int,                                  
 RefStdEditionId int                                  
);                                  
SELECT RefStandardId,RefStdEditionId,CustomerId,RefStdSource INTO #ProjectReferenceStandard                                 
FROM ProjectReferenceStandard  PRT  WITH(NOLOCK) where PRT.ProjectId=@PProjectId    and PRT.CustomerId=@PCustomerId and PRT.RefStdSource='U' AND ISNULL(PRT.IsDeleted,0) = 0                               
                                  
INSERT INTO  @table_RefStandardWithEditionId                                   
--RS list with edition which is not yet used                                  
SELECT RT.RefStdId AS RefStdId                                  
   ,MAX(RSE.RefStdEditionId) AS RefStdEditionId                                  
  FROM ReferenceStandard RT  WITH(NOLOCK) left outer join #ProjectReferenceStandard  PRT                                   
on RT.RefStdId=PRT.RefStandardId and RT.CustomerId=PRT.CustomerId and RT.RefStdSource=PRT.RefStdSource                                  
INNER JOIN ReferenceStandardEdition RSE  WITH(NOLOCK) on RT.RefStdId=RSE.RefStdId                                  
where RT.CustomerId=@PCustomerId and RT.RefStdSource='U' AND   ISNULL(RT.IsDeleted,0) = 0  AND                                
PRT.RefStandardId is null                                  
GROUP BY RT.RefStdId UNION                                 
--RS list with edition which is in used                           
SELECT RT.RefStdId AS RefStdId                                  
   ,MAX(PRT.RefStdEditionId) AS RefStdEditionId                                  
FROM ReferenceStandard RT   WITH(NOLOCK)INNER JOIN #ProjectReferenceStandard  PRT                                  
on RT.RefStdId=PRT.RefStandardId and RT.CustomerId=PRT.CustomerId and RT.RefStdSource=PRT.RefStdSource                                 
--INNER JOIN ReferenceStandardEdition RSE  WITH(NOLOCK) on PRT.RefStandardId =RSE.RefStdId                                 
where RT.CustomerId=@PCustomerId and RT.RefStdSource='U'  AND   ISNULL(RT.IsDeleted,0) = 0 GROUP BY RT.RefStdId                  
                   
                          
 SELECT MREFEDN.RefStdId                                                                            
  ,MREFEDN.RefStdEditionId as Id                                                                           
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
                                                                             
 --SELECT PREFEDN.RefStdId                                                                        
 -- ,PREFEDN.RefStdEditionId as Id                                                                       
 -- ,PREFEDN.RefEdition                                                                        
 -- ,PREFEDN.RefStdTitle                                                                        
 -- ,PREFEDN.LinkTarget                                                                        
 -- ,'U' AS RefEdnSource                                                                        
 --FROM ReferenceStandardEdition PREFEDN WITH (NOLOCK)                    
 --INNER JOIN ProjectReferenceStandard PRS   WITH (NOLOCK)                     
 --ON PRS.RefStdEditionId=PREFEDN.RefStdEditionId                                                            
 --WHERE  PRS.ProjectId=@ProjectId  and PREFEDN.CustomerId = @PCustomerId                        
                  
SELECT                                  
PRSE.RefStdId                                                                        
  ,PRSE.RefStdEditionId as Id                                                                       
  ,PRSE.RefEdition                                                                        
  ,PRSE.RefStdTitle                                                                        
  ,PRSE.LinkTarget                                                                        
  ,'U' AS RefEdnSource                                  
FROM ReferenceStandard PRS WITH(NOLOCK)                                  
inner join ReferenceStandardEdition PRSE  WITH(NOLOCK)                                  
on PRSE.RefStdId = PRS.RefStdId                                  
INNER JOIN @table_RefStandardWithEditionId tvn                                  
on tvn.RefStdId=prs.RefStdId and tvn.RefStdEditionId=prse.RefStdEditionId                                  
where PRS.CustomerId=@PCustomerId and ISNULL(PRS.IsDeleted,0) = 0                   
                  
                                      
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
 DECLARE @projectLevelValueForHeader BIT                
SET @projectLevelValueForHeader =(SELECT TOP 1                
  1                
 FROM Header H WITH (NOLOCK)                
 WHERE H.ProjectId = @PProjectId                
 AND H.DocumentTypeId = @DocumentTypeId                
 AND (ISNULL(H.HeaderFooterCategoryId, 1) = 1)                
 AND (                
 H.SectionId IS NULL                
 OR H.SectionId <= 0))                
                
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
  SELECT H.HeaderId,H.ProjectId,H.SectionId,H.CustomerId,H.TypeId,H.DATEFORMAT,H.TimeFormat,H.HeaderFooterCategoryId,H.              
DefaultHeader,H.FirstPageHeader,H.OddPageHeader,H.EvenPageHeader,H.HeaderFooterDisplayTypeId,H.              
IsShowLineAboveHeader,H.IsShowLineBelowHeader                                                                      
  FROM Header H WITH (NOLOCK)                                                                            
  INNER JOIN @SectionIdTbl S ON H.SectionId = S.SectionId                    
  WHERE H.ProjectId = @PProjectId                               
   AND H.DocumentTypeId = @DocumentTypeId                                                                            
   AND (                                                                            
    ISNULL(H.HeaderFooterCategoryId, 1) = 1                                                                            
    OR H.HeaderFooterCategoryId = 4                                                                            
    )                                                                            
                                                                              
  UNION                                             
                                                                              
  SELECT H.HeaderId,H.ProjectId,H.SectionId,H.CustomerId,H.TypeId,H.DATEFORMAT,H.TimeFormat,H.HeaderFooterCategoryId,H.              
DefaultHeader,H.FirstPageHeader,H.OddPageHeader,H.EvenPageHeader,H.HeaderFooterDisplayTypeId,H.              
IsShowLineAboveHeader,H.IsShowLineBelowHeader                                                                       
  FROM Header H WITH (NOLOCK)                                                                
  WHERE H.ProjectId = @PProjectId                                                       
   AND H.DocumentTypeId = @DocumentTypeId                                
   AND (ISNULL(H.HeaderFooterCategoryId, 1) = 1)                                     
   AND (                                                             
    H.SectionId IS NULL                                                                            
    OR H.SectionId <= 0                                                                            
    )                                                                            
                                                                              
  UNION                                                                            
                                                                              
  SELECT H.HeaderId,H.ProjectId,H.SectionId,H.CustomerId,H.TypeId,H.DATEFORMAT,H.TimeFormat,H.HeaderFooterCategoryId,H.              
DefaultHeader,H.FirstPageHeader,H.OddPageHeader,H.EvenPageHeader,H.HeaderFooterDisplayTypeId,H.              
IsShowLineAboveHeader,H.IsShowLineBelowHeader                                                                         
  FROM Header H WITH (NOLOCK)                                                                         
  LEFT JOIN Header TEMP                                                                            
  WITH (NOLOCK) ON TEMP.ProjectId = @PProjectId                                                                            
  WHERE H.CustomerId IS NULL                         
   AND TEMP.HeaderId IS NULL                                                                  
   AND H.DocumentTypeId = @DocumentTypeId                      
                     
   UNION                  
                  
 SELECT H.HeaderId,H.ProjectId,H.SectionId,H.CustomerId,H.TypeId,H.DATEFORMAT,H.TimeFormat,H.HeaderFooterCategoryId,H.              
DefaultHeader,H.FirstPageHeader,H.OddPageHeader,H.EvenPageHeader,H.HeaderFooterDisplayTypeId,H.              
IsShowLineAboveHeader,H.IsShowLineBelowHeader                                                                        
  FROM Header H WITH (NOLOCK)                                                                            
  WHERE H.CustomerId IS NULL                                                                              
   AND H.ProjectId IS NULL                                                                    
   AND H.DocumentTypeId = @DocumentTypeId                     
   AND ISNULL (@projectLevelValueForHeader ,0)= 0                
  ) AS X                         
                  
  DECLARE @projectLevelValueForFooter BIT                
SET @projectLevelValueForFooter =(SELECT TOP 1                
  1                
 FROM Footer F WITH (NOLOCK)                
 WHERE F.ProjectId = @PProjectId                
 AND F.DocumentTypeId = @DocumentTypeId                
 AND (ISNULL(F.HeaderFooterCategoryId, 1) = 1)                
 AND (                
 F.SectionId IS NULL                
 OR F.SectionId <= 0))                
                
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
  SELECT F.FooterId,F.ProjectId,F.SectionId,F.CustomerId,F.TypeId,F.DATEFORMAT,F.TimeFormat,F.HeaderFooterCategoryId,F.              
  DefaultFooter,F.FirstPageFooter,F.OddPageFooter,F.EvenPageFooter,F.HeaderFooterDisplayTypeId,F.              
  IsShowLineAboveFooter,F.IsShowLineBelowFooter                                                                        
  FROM Footer F WITH (NOLOCK)                                                                            
  INNER JOIN @SectionIdTbl S ON F.SectionId = S.SectionId                                                                            
  WHERE F.ProjectId = @PProjectId                                                                            
   AND F.DocumentTypeId = @DocumentTypeId                                            
   AND (                                                                            
    ISNULL(F.HeaderFooterCategoryId, 1) = 1                                                                            
    OR F.HeaderFooterCategoryId = 4                                                                            
    )                                                                            
                                                                              
  UNION                                                                            
                                                                              
  SELECT F.FooterId,F.ProjectId,F.SectionId,F.CustomerId,F.TypeId,F.DATEFORMAT,F.TimeFormat,F.HeaderFooterCategoryId,F.              
  DefaultFooter,F.FirstPageFooter,F.OddPageFooter,F.EvenPageFooter,F.HeaderFooterDisplayTypeId,F.              
  IsShowLineAboveFooter,F.IsShowLineBelowFooter              
  FROM Footer F WITH (NOLOCK)                                                                            
  WHERE F.ProjectId = @PProjectId                                                                       
   AND F.DocumentTypeId = @DocumentTypeId                                          
   AND (ISNULL(F.HeaderFooterCategoryId, 1) = 1)                                       
   AND (                                                                            
    F.SectionId IS NULL                                      
    OR F.SectionId <= 0                                                                            
    )                                                                            
                                                                              
  UNION                                                                            
                 
  SELECT F.FooterId,F.ProjectId,F.SectionId,F.CustomerId,F.TypeId,F.DATEFORMAT,F.TimeFormat,F.HeaderFooterCategoryId,F.              
  DefaultFooter,F.FirstPageFooter,F.OddPageFooter,F.EvenPageFooter,F.HeaderFooterDisplayTypeId,F.              
  IsShowLineAboveFooter,F.IsShowLineBelowFooter                                                                      
  FROM Footer F WITH (NOLOCK)                                                                            
  LEFT JOIN Footer TEMP                                                                            
  WITH (NOLOCK) ON TEMP.ProjectId = @PProjectId                                                                            
 WHERE F.CustomerId IS NULL                                                                            
   AND F.DocumentTypeId = @DocumentTypeId                                                                            
   AND TEMP.FooterId IS NULL                       
                     
   UNION                  
   SELECT F.FooterId,F.ProjectId,F.SectionId,F.CustomerId,F.TypeId,F.DATEFORMAT,F.TimeFormat,F.HeaderFooterCategoryId,F.              
  DefaultFooter,F.FirstPageFooter,F.OddPageFooter,F.EvenPageFooter,F.HeaderFooterDisplayTypeId,F.              
  IsShowLineAboveFooter,F.IsShowLineBelowFooter                                                                      
  FROM Footer F WITH (NOLOCK)                  
  WHERE F.CustomerId IS NULL                                                                              
   AND F.ProjectId IS NULL                                                                    
   AND F.DocumentTypeId = @DocumentTypeId                        
   AND ISNULL(@projectLevelValueForFooter ,0)= 0                
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
                                                              
IF(@IsPrintMasterNote = 1  OR @IsPrintProjectNote =1)                                                        
BEGIN                                                        
/*Start - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/                                                              
SELECT                                                             
NoteId                                                          
,PN.SectionId                                                              
,isnull(PSS.SegmentStatusId,0)SegmentStatusId                                                              
,PSS.mSegmentStatusId                                                               
,CASE WHEN Title != '' THEN CONCAT(Title,'<br/>', NoteText)                                      
 ELSE NoteText END NoteText                                                              
,PN.ProjectId                                  
,PN.CustomerId                                                            
,PN.IsDeleted                                                            
,NoteCode ,                                                            
COALESCE(PN.Title,'') as NoteType                                                           
FROM @SectionIdTbl SIDTBL                                         
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK) ON PSS.SectionId  = SIDTBL.SectionId                                                  
INNER JOIN  ProjectNote PN WITH (NOLOCK)  ON PN.SegmentStatusId = PSS.SegmentStatusId                                                        
AND PN.ProjectId= @PProjectId AND PN.SectionId = PSS.SectionId                                                         
WHERE PN.ProjectId=@PProjectId and PN.CustomerId=@PCustomerId AND ISNULL(PN.IsDeleted, 0) = 0                                                              
UNION ALL                                                              
SELECT NoteId                                                              
,0 SectionId        
,PSS.SegmentStatusId                                                               
,isnull(PSS.mSegmentStatusId,0) as mSegmentStatusId                                                               
,NoteText                                                              
,@PProjectId As ProjectId                                                               
,@PCustomerId As CustomerId                                                               
,0 IsDeleted                                                              
,0 NoteCode ,                                                            
'' As NoteType                                                            
 FROM @SectionIdTbl SIDTBL                                        
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK)                                       
ON PSS.SectionId = SIDTBL.SectionId                                                          
INNER JOIN SLCMaster..Note MN  WITH (NOLOCK)   ON                                                        
 ISNULL(PSS.mSegmentStatusId, 0) > 0 and  MN.SegmentStatusId = PSS.mSegmentStatusId                                                         
 AND PSS.SectionId = SIDTBL.SectionId                                                         
 WHERE ISNULL(PSS.mSegmentStatusId, 0) > 0                                                           
                                                            
/*End - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/                                                              
End;                                                   
          
--SELECT Sheet Specs Setting                   
if Exists (select top 1 1 from SheetSpecsPageSettings SSPS with (nolock)            
where ProjectId = @PProjectId and CustomerId = @PCustomerId )                       
begin                                                                           
select          
max(case when SSPS.[Name] = 'NumberOfColumns' then value end) NumOfSpecSheetsColumnsSelected,          
max(case when SSPS.[Name] = 'Height' then value end) PaperHeight,          
max(case when SSPS.[Name] = 'Width' then value end) PaperWidth,          
max(PaperSettingKey) as PaperSettingKey,          
max(LSSPS.Name) as PaperName,          
cast(0 as bit) as PaperOrientation,      
max(case when SSPS.[Name] = 'MarginTop' then value end) MarginTop,          
max(case when SSPS.[Name] = 'MarginBottom' then value end) MarginBottom,          
max(case when SSPS.[Name] = 'MarginLeft' then value end) MarginLeft,          
max(case when SSPS.[Name] = 'MarginRight' then value end) MarginRight,      
max(case when SSPS.[Name] = 'IsEqualColumnWidthEnabled' then value end) IsEqualColumnWidthEnabled,      
max(case when SSPS.[Name] = 'IsLineBetweenEnabled' then value end) IsLineBetweenEnabled,      
max(case when SSPS.[Name] = 'ColumnFormatDetails' then value end) ColumnFormatDetails      
from SheetSpecsPageSettings SSPS with (nolock) INNER JOIN LuSpecSheetPaperSize LSSPS          
on SSPS.PaperSettingKey = LSSPS.SpecSheetPaperId           
where ProjectId = @PProjectId and CustomerId = @PCustomerId           
end          
else           
begin          
 select           
 cast('3' as int) AS  NumOfSpecSheetsColumnsSelected,          
 Height AS PaperHeight,          
 Width AS PaperWidth,          
 SpecSheetPaperId as PaperSettingKey,          
 Name as PaperName,          
 cast(0 as bit) PaperOrientation,      
 cast('1' as int) AS MarginTop,          
 cast('1' as int) AS MarginBottom,          
 cast('1' as int) AS MarginLeft,          
 cast('1' as int) AS MarginRight,      
1 as IsEqualColumnWidthEnabled,      
0 as  IsLineBetweenEnabled,      
'[{"id":1,"width":13,"spacing":0.5,"isSpacingDisable":false,"isWidthDisable":false},{"id":2,"width":13,"spacing":0.5,"isSpacingDisable":true,"isWidthDisable":true},{"id":3,"width":13,"spacing":0,"isSpacingDisable":true,"isWidthDisable":true}]'     
AS ColumnFormatDetails           
 from LuSpecSheetPaperSize where SpecSheetPaperId = 13           
end          
END
