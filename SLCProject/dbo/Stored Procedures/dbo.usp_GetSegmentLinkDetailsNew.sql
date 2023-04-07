
CREATE PROCEDURE [dbo].[usp_GetSegmentLinkDetailsNew] (    
 @InpSegmentLinkJson NVARCHAR(MAX)  
)   
AS            
BEGIN                
--PARAMETER SNIFFING CARE                
DECLARE @PInpSegmentLinkJson NVARCHAR(MAX) = @InpSegmentLinkJson;               
                
/** [BLOCK] LOCAL VARIABLES **/                
BEGIN                
--SET NO COUNT ON                    
SET NOCOUNT ON;                
                  
--DECLARE TYPES OF LINKS                    
DECLARE @P2P INT = 1;                
DECLARE @P2C INT = 2;                
              
DECLARE @C2P INT = 3;                
DECLARE @C2C INT = 4;                
                 
--DECLARE TAGS VARIABLES                  
DECLARE @RS_TAG INT = 22;                
DECLARE @RT_TAG INT = 23;                
DECLARE @RE_TAG INT = 24;                
DECLARE @ST_TAG INT = 25;                
                
--DECLARE LOOPED VARIABLES                    
DECLARE @LoopedSectionId INT = 0;                
DECLARE @LoopedSegmentStatusCode BIGINT = 0;                
DECLARE @LoopedSegmentSource CHAR(1) = '';                
                 
--DECALRE COMMON VARIABLES FROM INP JSON                  
DECLARE @ProjectId INT = 0;                
DECLARE @CustomerId INT = 0;                
DECLARE @UserId INT = 0;                
          
--DECLARE FIELD WHICH SHOWS RECORD TYPE                  
DECLARE @SourceOfRecord_Master VARCHAR(1) = 'M';                
DECLARE @SourceOfRecord_Project VARCHAR(1) = 'U';                
                
DECLARE @Master_LinkTypeId INT = 1;                
DECLARE @RS_LinkTypeId INT = 2;                
DECLARE @RE_LinkTypeId INT = 3;                
DECLARE @LinkManE_LinkTypeId INT = 4;           
DECLARE @USER_LinkTypeId INT = 5;                
                
--DECLARE VARIABLES USED IN UNIQUE SECTION CODES COUNT                    
DECLARE @UniqueSectionCodesLoopCnt INT = 1;                
DECLARE @InpSegmentLinkLoopCnt INT = 1;                
                
--DECLARE VARIABLES FOR ITERATIONS                
DECLARE @MaxIteration INT = 2;          
          
--DECLARE INP SEGMENT LINK VAR                
DROP TABLE IF EXISTS #InputDataTable                
CREATE TABLE #InputDataTable (                
   RowId INT NOT NULL PRIMARY KEY                
   ,ProjectId INT NOT NULL                
   ,CustomerId INT NOT NULL                
   ,SectionId INT NOT NULL                
   ,SectionCode INT NOT NULL                
   ,SegmentStatusCode BIGINT NULL                
   ,SegmentSource CHAR(1) NULL                
   ,UserId INT NOT NULL                
);    
                
--CREATE TEMP TABLE TO STORE SEGMENT LINK IN DATA                
DROP TABLE IF EXISTS #SegmentLinkTable                
CREATE TABLE #SegmentLinkTable (                
 SegmentLinkId BIGINT                
   ,SourceSectionCode INT                
   ,SourceSegmentStatusCode BIGINT                
   ,SourceSegmentCode BIGINT                
   ,SourceSegmentChoiceCode BIGINT                
   ,SourceChoiceOptionCode BIGINT                
   ,LinkSource CHAR(1)                
   ,TargetSectionCode INT                
   ,TargetSegmentStatusCode BIGINT                
   ,TargetSegmentCode BIGINT                
   ,TargetSegmentChoiceCode BIGINT                
   ,TargetChoiceOptionCode BIGINT                
   ,LinkTarget CHAR(1)                
   ,LinkStatusTypeId INT                
   ,IsDeleted BIT                
   ,SegmentLinkCode BIGINT                
   ,SegmentLinkSourceTypeId INT                
   ,IsTgtLink BIT            
   ,IsSrcLink BIT                
   ,SourceOfRecord CHAR(1)                
   ,Iteration INT              
   ,ProjectId INT  -- Added By Bhushan    
);    
                
--CREATE TEMP TABLE TO STORE SEGMENT STATUS DATA                
DROP TABLE IF EXISTS #SegmentStatusTable                
CREATE TABLE #SegmentStatusTable (                
 ProjectId INT                
   ,SectionId INT                
   ,CustomerId INT                
   ,SegmentStatusId BIGINT      
   ,SegmentStatusCode BIGINT                
   ,SegmentStatusTypeId INT                
   ,IsParentSegmentStatusActive BIT                
   ,ParentSegmentStatusId BIGINT                
   ,SectionCode INT                
   ,SegmentSource CHAR(1)             
   ,SegmentOrigin CHAR(1)                
   ,ChildCount INT                
   ,SrcLinksCnt INT                
   ,TgtLinksCnt INT                
   ,SequenceNumber DECIMAL(18, 4)                
   ,mSegmentStatusId INT                
   ,SegmentCode BIGINT                
   ,mSegmentId INT                
   ,SegmentId BIGINT                
   ,IsFetchedDbLinkResult BIT
   ,mSectionId INT
);                
                
--CREATE TEMP TABLE TO STORE UNIQUE TARGET SECTION CODE DATA                
DROP TABLE IF EXISTS #TargetSectionCodeTable                
CREATE TABLE #TargetSectionCodeTable (                
 Id INT                
   ,SectionCode INT                
   ,SectionId INT                
);                
                
--CREATE TEMP TABLE TO STORE CHOICES DATA                
DROP TABLE IF EXISTS #SegmentChoiceTable                
CREATE TABLE #SegmentChoiceTable (                
 ProjectId INT                
   ,SectionId INT                
   ,CustomerId INT                
   ,SegmentChoiceCode BIGINT                
  ,SegmentChoiceSource CHAR(1)                
   ,ChoiceTypeId INT                
   ,ChoiceOptionCode BIGINT                
   ,ChoiceOptionSource CHAR(1)                
   ,IsSelected BIT                
   ,SectionCode INT                
   ,SegmentStatusId BIGINT                
   ,mSegmentId INT                
   ,SegmentId BIGINT                
   ,SelectedChoiceOptionId BIGINT                
);                
END                    
/** [BLOCK] FETCH INPUT DATA INTO TEMP TABLE **/                
BEGIN                
--PUT FETCHED INP RESULT IN LOCAL TABLE VARIABLE                   
IF @PInpSegmentLinkJson != ''                
BEGIN                
INSERT INTO #InputDataTable                
 SELECT                
  ROW_NUMBER() OVER (ORDER BY ProjectId ASC) AS RowId                
    ,ProjectId                
    ,CustomerId                
    ,SectionId                
    ,SectionCode                
    ,SegmentStatusCode                
    ,SegmentSource                
    ,UserId                
 FROM OPENJSON(@PInpSegmentLinkJson)                
 WITH (                
 ProjectId INT '$.ProjectId',                
 CustomerId INT '$.CustomerId',                
 SectionId INT '$.SectionId',                
 SectionCode INT '$.SectionCode',                
 SegmentStatusCode BIGINT '$.SegmentStatusCode',                
 SegmentSource CHAR(1) '$.SegmentSource',                
 UserId INT '$.UserId'                
 );                
END                
END                
                
/** [BLOCK] FETCH COMMON INPUT DATA INTO VARIABLES **/                
BEGIN                
--SET COMMON VARIABLES FROM INP JSON                  
SELECT TOP 1     
    @ProjectId = ProjectId                
   ,@CustomerId = CustomerId                
   ,@UserId = UserId                
FROM #InputDataTable  
OPTION (FAST 1);               
END    
      
-- Create #ProjectSection table and store ProjectSection data    
-- Note : This is then used to identify that target sections are opned and if not then insert data    
BEGIN    
 DROP TABLE IF EXISTS #ProjectSection;    
 CREATE TABLE #ProjectSection (                
  SectionId INT NOT NULL PRIMARY KEY                
    ,SectionCode INT NOT NULL    
    ,IsLastLevel BIT NULL    
    ,mSectionId INT NULL    
 );    
 INSERT INTO #ProjectSection    
 SELECT PS.SectionId, PS.SectionCode, PS.IsLastLevel, PS.mSectionId      
 FROM ProjectSection PS with (nolock)  
 WHERE PS.ProjectId = @ProjectId AND IsNULL(PS.IsDeleted,0) = 0;   
END               
                
/** [BLOCK] MAP CLICKED SECTION DATA IF NOT OPENED **/                
BEGIN                
--LOOP INP SEGMENT LINK TABLE TO MAP SEGMENT STATUS AND CHOICES IF SECTION STATUS IS CLICKED                
declare @InputDataTableRowCount INT=(SELECT                
  COUNT(1)                
 FROM #InputDataTable)                
WHILE @InpSegmentLinkLoopCnt <= @InputDataTableRowCount                
BEGIN                
IF EXISTS (SELECT TOP 1                
   1               
  FROM #InputDataTable                
  WHERE RowId = @InpSegmentLinkLoopCnt                
  AND SegmentStatusCode <= 0)                
BEGIN                
SET @LoopedSectionId = 0;                
SET @LoopedSegmentStatusCode = 0;                
SET @LoopedSegmentSource = '';                
                
SELECT                
 @LoopedSectionId = SectionId                
FROM #InputDataTable                
WHERE RowId = @InpSegmentLinkLoopCnt     
OPTION (FAST 1);             
   
 DECLARE @HasProjectSegmentStatus INT =0;  
          
SELECT TOP 1                
   @HasProjectSegmentStatus = COUNT(1)               
  FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)                
  WHERE PSST.ProjectId = @ProjectId                
  AND PSST.CustomerId = @CustomerId                
  AND PSST.SectionId = @LoopedSectionId   
  OPTION (FAST 1);     
IF (@HasProjectSegmentStatus = 0)               
BEGIN                
EXEC usp_MapSegmentStatusFromMasterToProject @ProjectId = @ProjectId                
           ,@SectionId = @LoopedSectionId                
            ,@CustomerId = @CustomerId                
            ,@UserId = @UserId;                
END                
   
 DECLARE @HasSelectedChoiceOption INT = 0;  
  
SELECT TOP 1 @HasSelectedChoiceOption = COUNT(1)                
  FROM SelectedChoiceOption AS PSCHOP WITH (NOLOCK)                
  WHERE PSCHOP.SectionId = @LoopedSectionId                
  AND PSCHOP.ProjectId = @ProjectId                 
  AND PSCHOP.ChoiceOptionSource = 'M'                 
  AND PSCHOP.CustomerId = @CustomerId  
   OPTION (FAST 1);   
IF (@HasSelectedChoiceOption = 0)                
BEGIN                
EXEC usp_MapSegmentChoiceFromMasterToProject @ProjectId = @ProjectId                
            ,@SectionId = @LoopedSectionId                
            ,@CustomerId = @CustomerId                
            ,@UserId = @UserId;                
END                
   
 DECLARE @HasProjectSegmentRequirementTag INT = 0;  
 SELECT TOP 1 @HasProjectSegmentRequirementTag = COUNT(1)               
  FROM ProjectSegmentRequirementTag AS PSRT WITH (NOLOCK)                
  WHERE PSRT.ProjectId = @ProjectId                
  AND PSRT.CustomerId = @CustomerId                
  AND PSRT.SectionId = @LoopedSectionId  
  OPTION (FAST 1);                
IF (@HasProjectSegmentRequirementTag = 0)               
BEGIN                
EXEC usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @ProjectId                
              ,@SectionId = @LoopedSectionId                
              ,@CustomerId = @CustomerId                
              ,@UserId = @UserId;                
END                
                
--EXEC dbo.usp_MapSegmentLinkFromMasterToProject @ProjectId = @ProjectId                
--             ,@SectionId = @LoopedSectionId                
--             ,@CustomerId = @CustomerId                
--        ,@UserId = @UserId;                
                
--FETCH TOP MOST SEGMENT STATUS CODE FROM SEGMENT STATUS ITS SOURCE                    
SELECT TOP 1                
 @LoopedSegmentStatusCode = SegmentStatusCode                
   ,@LoopedSegmentSource = SegmentOrigin                
FROM ProjectSegmentStatus WITH (NOLOCK)                
WHERE SectionId = @LoopedSectionId                
AND ProjectId = @ProjectId                
AND CustomerId = @CustomerId                
AND ParentSegmentStatusId = 0
AND SequenceNumber ='0'
OPTION (FAST 1);               
                
UPDATE TMPTBL                
SET TMPTBL.SegmentStatusCode = @LoopedSegmentStatusCode                
   ,TMPTBL.SegmentSource = @LoopedSegmentSource                
FROM #InputDataTable TMPTBL WITH (NOLOCK)                
WHERE TMPTBL.RowId = @InpSegmentLinkLoopCnt                END                
                
SET @InpSegmentLinkLoopCnt = @InpSegmentLinkLoopCnt + 1;                
                 
END;                
END                
                
/** [BLOCK] GET RQEUIRED LINKS **/                
BEGIN                
    
-- Start : Create #ProjectSegmentLink table for quering links for project/section    
DROP TABLE IF EXISTS #ProjectSegmentLink;    
--CREATE TABLE #ProjectSegmentLink (    
-- SegmentLinkId BIGINT NOT NULL PRIMARY KEY,    
-- SourceSectionCode INT,    
-- SourceSegmentStatusCode BIGINT,    
-- SourceSegmentCode BIGINT,    
-- SourceSegmentChoiceCode BIGINT,    
-- SourceChoiceOptionCode BIGINT,    
-- LinkSource CHAR(1),    
-- TargetSectionCode INT,    
-- TargetSegmentStatusCode BIGINT,    
-- TargetSegmentCode BIGINT,    
-- TargetSegmentChoiceCode BIGINT,    
-- TargetChoiceOptionCode BIGINT,    
-- LinkTarget CHAR(1),    
-- LinkStatusTypeId INT,    
-- IsDeleted INT,    
-- SegmentLinkCode BIGINT,    
-- SegmentLinkSourceTypeId INT,    
-- ProjectId INT,    
-- CustomerId INT,    
--);    
--INSERT INTO #ProjectSegmentLink    
SELECT    
  PSL.SegmentLinkId                
    ,PSL.SourceSectionCode                
    ,PSL.SourceSegmentStatusCode                
    ,PSL.SourceSegmentCode                
    ,PSL.SourceSegmentChoiceCode                
    ,PSL.SourceChoiceOptionCode                
    ,PSL.LinkSource                
    ,PSL.TargetSectionCode                
    ,PSL.TargetSegmentStatusCode                
    ,PSL.TargetSegmentCode                
    ,PSL.TargetSegmentChoiceCode                
    ,PSL.TargetChoiceOptionCode                
    ,PSL.LinkTarget                
    ,PSL.LinkStatusTypeId                
    ,PSL.IsDeleted                
    ,PSL.SegmentLinkCode                
    ,PSL.SegmentLinkSourceTypeId    
 ,PSL.ProjectId    
 ,PSL.CustomerId
 INTO #ProjectSegmentLink
FROM ProjectSegmentLink PSL with (nolock)   
WHERE PSL.ProjectId = @ProjectId and PSL.CustomerId = @CustomerId  
-- End : Create #ProjectSegmentLink table for quering links for project/section    
     
--Print '--1. FETCH SRC LINKS FROM SLCProject..ProjectSegmentLink '             
--1. FETCH SRC LINKS FROM SLCProject..ProjectSegmentLink                
INSERT INTO #SegmentLinkTable                
 SELECT DISTINCT                
     PSLNK.SegmentLinkId                
    ,PSLNK.SourceSectionCode                
    ,PSLNK.SourceSegmentStatusCode                
    ,PSLNK.SourceSegmentCode                
    ,PSLNK.SourceSegmentChoiceCode                
    ,PSLNK.SourceChoiceOptionCode                
    ,PSLNK.LinkSource                
    ,PSLNK.TargetSectionCode                
    ,PSLNK.TargetSegmentStatusCode                
    ,PSLNK.TargetSegmentCode                
    ,PSLNK.TargetSegmentChoiceCode                
    ,PSLNK.TargetChoiceOptionCode                
    ,PSLNK.LinkTarget                
    ,PSLNK.LinkStatusTypeId                
    ,PSLNK.IsDeleted                
    ,PSLNK.SegmentLinkCode                
    ,PSLNK.SegmentLinkSourceTypeId                
    ,0 AS IsTgtLink                
    ,1 AS IsSrcLink                
    ,@SourceOfRecord_Project AS SourceOfRecord                
    ,NULL AS Iteration            
 ,TMP.ProjectId -- Added by Bhushan                
 FROM #InputDataTable TMP WITH (NOLOCK)                
 INNER JOIN #ProjectSegmentLink PSLNK WITH (NOLOCK)                
 ON TMP.ProjectId = PSLNK.ProjectId AND               
  TMP.SectionCode = PSLNK.TargetSectionCode                
   AND TMP.SegmentStatusCode = PSLNK.TargetSegmentStatusCode                
   AND TMP.SegmentSource = PSLNK.LinkTarget                
 WHERE PSLNK.ProjectId = @ProjectId                
 AND PSLNK.CustomerId = @CustomerId                
 --AND PSLNK.IsDeleted = 0                
            
--Print '--2. FETCH TGT LINKS FROM SLCProject..ProjectSegmentLink'      --2. FETCH TGT LINKS FROM SLCProject..ProjectSegmentLink                
;WITH ProjectLinksCTE                
AS                
(SELECT                
  PSLNK.*                
    ,1 AS Iteration           
 FROM #InputDataTable TMP WITH (NOLOCK)                
 INNER JOIN #ProjectSegmentLink PSLNK WITH (NOLOCK)                
 ON TMP.ProjectId = PSLNK.ProjectId AND               
  TMP.SectionCode = PSLNK.SourceSectionCode                
  AND TMP.SegmentStatusCode = PSLNK.SourceSegmentStatusCode                
  AND TMP.SegmentSource = PSLNK.LinkSource                
 WHERE PSLNK.ProjectId = @ProjectId                
 AND PSLNK.CustomerId = @CustomerId                
 --AND PSLNK.IsDeleted = 0                
 UNION ALL                
 SELECT                
  PSLNK.*                
    ,CTE.Iteration + 1 AS Iteration                
 FROM ProjectLinksCTE CTE                
 INNER JOIN #ProjectSegmentLink PSLNK WITH (NOLOCK)                
 ON CTE.ProjectId = PSLNK.ProjectId AND               
   CTE.TargetSectionCode = PSLNK.SourceSectionCode                
  AND CTE.TargetSegmentStatusCode = PSLNK.SourceSegmentStatusCode                
  AND CTE.LinkTarget = PSLNK.LinkSource                
 WHERE PSLNK.ProjectId = @ProjectId                
 AND PSLNK.CustomerId = @CustomerId                
 --AND PSLNK.IsDeleted = 0                
 AND CTE.Iteration < @MaxIteration)          
                
INSERT INTO #SegmentLinkTable                
 SELECT DISTINCT                
  CTE.SegmentLinkId                
    ,CTE.SourceSectionCode                
    ,CTE.SourceSegmentStatusCode                
    ,CTE.SourceSegmentCode                
    ,CTE.SourceSegmentChoiceCode                
    ,CTE.SourceChoiceOptionCode                
    ,CTE.LinkSource                
    ,CTE.TargetSectionCode                
    ,CTE.TargetSegmentStatusCode                
    ,CTE.TargetSegmentCode                
    ,CTE.TargetSegmentChoiceCode                
    ,CTE.TargetChoiceOptionCode                
    ,CTE.LinkTarget                
    ,CTE.LinkStatusTypeId                
    ,CTE.IsDeleted                
    ,CTE.SegmentLinkCode                
    ,CTE.SegmentLinkSourceTypeId                
    ,1 AS IsTgtLink                
    ,0 AS IsSrcLink                
    ,@SourceOfRecord_Project AS SourceOfRecord                
    ,CTE.Iteration              
 ,@ProjectId -- Added by Bhushan              
 FROM ProjectLinksCTE CTE                
                
--3. FETCH TGT LINKS FROM SLCMaster..SegmentLink                
;                
WITH MasterLinksCTE                
AS                
(SELECT                
  MSLNK.*                
    ,1 AS Iteration                
 FROM #InputDataTable TMP WITH (NOLOCK)                
 INNER JOIN SLCMaster..SegmentLink MSLNK WITH (NOLOCK)                
  ON TMP.SectionCode = MSLNK.SourceSectionCode                
  AND TMP.SegmentStatusCode = MSLNK.SourceSegmentStatusCode                
  AND TMP.SegmentSource = MSLNK.LinkSource            
 WHERE MSLNK.IsDeleted = 0                
 UNION ALL                
 SELECT                
  MSLNK.*                
    ,CTE.Iteration + 1 AS Iteration                
 FROM MasterLinksCTE CTE                
 INNER JOIN SLCMaster..SegmentLink MSLNK WITH (NOLOCK)                
  ON CTE.TargetSectionCode = MSLNK.SourceSectionCode                
  AND CTE.TargetSegmentStatusCode = MSLNK.SourceSegmentStatusCode                
  AND CTE.LinkTarget = MSLNK.LinkSource                
 WHERE MSLNK.IsDeleted = 0                
 AND CTE.Iteration < @MaxIteration)                
                
INSERT INTO #SegmentLinkTable                
 SELECT DISTINCT                
  CTE.SegmentLinkId                
    ,CTE.SourceSectionCode                
    ,CTE.SourceSegmentStatusCode                    
 ,CTE.SourceSegmentCode                
    ,CTE.SourceSegmentChoiceCode                
    ,CTE.SourceChoiceOptionCode                
    ,CTE.LinkSource                
    ,CTE.TargetSectionCode                
    ,CTE.TargetSegmentStatusCode                
    ,CTE.TargetSegmentCode                
    ,CTE.TargetSegmentChoiceCode                
    ,CTE.TargetChoiceOptionCode                
    ,CTE.LinkTarget                
    ,CTE.LinkStatusTypeId                
    ,CTE.IsDeleted                
    ,CTE.SegmentLinkCode                
    ,CTE.SegmentLinkSourceTypeId                
    ,1 AS IsTgtLink                
    ,0 AS IsSrcLink                
    ,@SourceOfRecord_Master AS SourceOfRecord                
    ,CTE.Iteration            
  ,@ProjectId -- Added by Bhushan                 
 FROM MasterLinksCTE CTE                
            
--Print '--4. FETCH SRC LINKS FROM SLCProject..ProjectSegmentLink FOR SETTING HIGHEST PRIORITY'            
--4. FETCH SRC LINKS FROM SLCProject..ProjectSegmentLink FOR SETTING HIGHEST PRIORITY                
INSERT INTO #SegmentLinkTable                
 SELECT DISTINCT                
  SLNK.SegmentLinkId                
    ,SLNK.SourceSectionCode                
    ,SLNK.SourceSegmentStatusCode                
    ,SLNK.SourceSegmentCode                
    ,SLNK.SourceSegmentChoiceCode                
    ,SLNK.SourceChoiceOptionCode                
    ,SLNK.LinkSource                
    ,SLNK.TargetSectionCode                
    ,SLNK.TargetSegmentStatusCode                
    ,SLNK.TargetSegmentCode                
    ,SLNK.TargetSegmentChoiceCode                
    ,SLNK.TargetChoiceOptionCode                
    ,SLNK.LinkTarget                
    ,SLNK.LinkStatusTypeId                
    ,SLNK.IsDeleted                
    ,SLNK.SegmentLinkCode         
    ,SLNK.SegmentLinkSourceTypeId                
    ,0 AS IsTgtLink                
    ,1 AS IsSrcLink                
    ,@SourceOfRecord_Project AS SourceOfRecord                
    ,NULL AS Iteration            
 ,@ProjectId AS ProjectId -- Added by Bhushan    
 FROM #SegmentLinkTable SLT WITH (NOLOCK)                
 INNER JOIN #ProjectSegmentLink SLNK WITH (NOLOCK)          
 ON SLT.ProjectId = SLNK.ProjectId -- Added by Bhushan              
   AND SLT.TargetSectionCode = SLNK.TargetSectionCode                
   AND SLT.TargetSegmentStatusCode = SLNK.TargetSegmentStatusCode                
   AND SLT.TargetSegmentCode = SLNK.TargetSegmentCode                
   AND SLT.LinkTarget = SLNK.LinkTarget                
 LEFT JOIN #SegmentLinkTable TMP WITH (NOLOCK)                
  ON SLNK.SegmentLinkCode = TMP.SegmentLinkCode                
 WHERE SLNK.ProjectId = @ProjectId                
 AND SLNK.CustomerId = @CustomerId                
 --AND SLNK.IsDeleted = 0    
 AND SLT.IsTgtLink = 1                
 AND TMP.SegmentLinkCode IS NULL                
                
--5. FETCH SRC LINKS FROM SLCMaster..SegmentLink FOR SETTING HIGHEST PRIORITY                
INSERT INTO #SegmentLinkTable                
 SELECT DISTINCT                
  SLNK.SegmentLinkId                
    ,SLNK.SourceSectionCode                
    ,SLNK.SourceSegmentStatusCode                
    ,SLNK.SourceSegmentCode                
    ,SLNK.SourceSegmentChoiceCode                
    ,SLNK.SourceChoiceOptionCode                
    ,SLNK.LinkSource                
    ,SLNK.TargetSectionCode                
    ,SLNK.TargetSegmentStatusCode                
    ,SLNK.TargetSegmentCode                
    ,SLNK.TargetSegmentChoiceCode                
    ,SLNK.TargetChoiceOptionCode                
    ,SLNK.LinkTarget                
    ,SLNK.LinkStatusTypeId          
    ,SLNK.IsDeleted                
    ,SLNK.SegmentLinkCode                
    ,SLNK.SegmentLinkSourceTypeId                
    ,0 AS IsTgtLink                
    ,1 AS IsSrcLink                
    ,@SourceOfRecord_Master AS SourceOfRecord                
    ,NULL AS Iteration            
 ,@ProjectId -- Added by Bhushan                  
 FROM #SegmentLinkTable SLT WITH (NOLOCK)                
 INNER JOIN SLCMaster..SegmentLink SLNK WITH (NOLOCK)                
  ON SLT.TargetSectionCode = SLNK.TargetSectionCode                
   AND SLT.TargetSegmentStatusCode = SLNK.TargetSegmentStatusCode                
   AND SLT.TargetSegmentCode = SLNK.TargetSegmentCode                
   AND SLT.LinkTarget = SLNK.LinkTarget                
 LEFT JOIN #SegmentLinkTable TMP WITH (NOLOCK)                
  ON SLNK.SegmentLinkCode = TMP.SegmentLinkCode                
 WHERE SLNK.IsDeleted = 0                
 AND SLT.IsTgtLink = 1                
 AND TMP.SegmentLinkCode IS NULL                
                
--DELETE ALREADY MAPPED MASTER RECORDS INTO PROJECT WHICH ARE ALSO FETCHED FROM MASTER DB                  
DELETE MSLNK                
 FROM #SegmentLinkTable MSLNK WITH (NOLOCK)                
 INNER JOIN #SegmentLinkTable USLNK WITH (NOLOCK)                
  ON MSLNK.SegmentLinkCode = USLNK.SegmentLinkCode                
WHERE MSLNK.SourceOfRecord = @SourceOfRecord_Master                
 AND USLNK.SourceOfRecord = @SourceOfRecord_Project                
END                
                
/** [BLOCK] FIND UNIQUE TARGET SECTIONS WHOSE DATA TO BE MAPPED **/                
BEGIN               
    
SELECT DISTINCT TargetSectionCode AS SectionCode     
INTO #DistinctTargetSectionCode    
FROM #SegmentLinkTable    
    
INSERT INTO #TargetSectionCodeTable                
 SELECT     
     ROW_NUMBER() OVER (ORDER BY X.SectionCode) AS Id                
    ,X.SectionCode                
    ,PS.SectionId                
 FROM #DistinctTargetSectionCode X    
 INNER JOIN #ProjectSection PS WITH (NOLOCK)                
  ON PS.SectionCode = X.SectionCode                
 LEFT JOIN ProjectSegmentStatus PSST WITH (NOLOCK)                
  ON  
   PS.SectionId = PSST.SectionId                
   AND PSST.ParentSegmentStatusId = 0                
   AND PSST.IndentLevel = 0  
   AND PSST.ProjectId = @ProjectId  
 WHERE       
  PS.IsLastLevel = 1                
 AND PS.mSectionId IS NOT NULL    
 AND ISNULL(PSST.IsDeleted, 0) = 0    
 AND PSST.SegmentStatusId IS NULL    
END           
        
-- Note this can be done in background and need to resume the task from here onwards         
                
/** [BLOCK] LOOP TO MAP TARGET SECTIONS DATA **/                
BEGIN                
 declare @TargetSectionCodeTableRowCount INT=(SELECT                
  COUNT(1)                
 FROM #TargetSectionCodeTable WITH (NOLOCK))                
WHILE @UniqueSectionCodesLoopCnt <= @TargetSectionCodeTableRowCount                
BEGIN                
SET @LoopedSectionId = 0;                
SELECT TOP 1    
  @LoopedSectionId =SectionId                
 FROM #TargetSectionCodeTable WITH (NOLOCK)                
 WHERE Id = @UniqueSectionCodesLoopCnt  
 OPTION (FAST 1);              
    
  
DECLARE @LoopedHasProjectSegmentStatus INT;  
SELECT TOP 1 @LoopedHasProjectSegmentStatus = COUNT(1)  
 FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)                
 WHERE PSST.SectionId = @LoopedSectionId  
 AND PSST.ProjectId = @ProjectId                
 AND PSST.CustomerId = @CustomerId  
  OPTION (FAST 1);  
             
IF (@LoopedHasProjectSegmentStatus = 0)  
BEGIN                
EXEC dbo.usp_MapSegmentStatusFromMasterToProject @ProjectId = @ProjectId                
            ,@SectionId = @LoopedSectionId                
            ,@CustomerId = @CustomerId                
            ,@UserId = @UserId;                
END                
  
DECLARE @LoopedHasSelectedChoiceOption INT;  
SELECT TOP 1 @LoopedHasSelectedChoiceOption = COUNT(1)  
  FROM SelectedChoiceOption AS PSCHOP WITH (NOLOCK)  
  WHERE PSCHOP.SectionId = @LoopedSectionId  
  AND PSCHOP.ProjectId = @ProjectId                
  AND PSCHOP.CustomerId = @CustomerId  
  AND PSCHOP.ChoiceOptionSource = 'M'  
  OPTION (FAST 1);  
             
IF (@LoopedHasSelectedChoiceOption = 0)  
BEGIN                
EXEC dbo.usp_MapSegmentChoiceFromMasterToProject @ProjectId = @ProjectId                
            ,@SectionId = @LoopedSectionId                
            ,@CustomerId = @CustomerId                
            ,@UserId = @UserId;             
END                
   
 DECLARE @LoopedHasProjectSegmentRequirementTag INT = 0;  
  SELECT @LoopedHasProjectSegmentRequirementTag = COUNT(1)               
  FROM ProjectSegmentRequirementTag AS PSRT WITH (NOLOCK)          
  WHERE PSRT.ProjectId = @ProjectId                
  AND PSRT.CustomerId = @CustomerId                
  AND PSRT.SectionId = @LoopedSectionId    
    OPTION (FAST 1);            
IF ( @LoopedHasProjectSegmentRequirementTag = 0)            
BEGIN                
EXEC dbo.usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @ProjectId                
              ,@SectionId = @LoopedSectionId                
              ,@CustomerId = @CustomerId                
              ,@UserId = @UserId;                
END                
                
--EXEC dbo.usp_MapSegmentLinkFromMasterToProject @ProjectId = @ProjectId                
--             ,@SectionId = @LoopedSectionId                
--             ,@CustomerId = @CustomerId                
--  ,@UserId = @UserId;                
                
SET @UniqueSectionCodesLoopCnt = @UniqueSectionCodesLoopCnt + 1;                
END;              
END                
    
        
/** [BLOCK] GET SEGMENT STATUS DATA **/                
BEGIN                
INSERT INTO #SegmentStatusTable                
 --GET SEGMENT STATUS FOR PASSED INPUT DATA                
 SELECT DISTINCT                
     PSST.ProjectId                
    ,PSST.SectionId                
    ,PSST.CustomerId                
    ,PSST.SegmentStatusId                
    ,PSST.SegmentStatusCode                
    ,PSST.SegmentStatusTypeId                
    ,PSST.IsParentSegmentStatusActive                
    ,PSST.ParentSegmentStatusId                
    ,PS.SectionCode                
    ,PSST.SegmentOrigin AS SegmentSource                
    ,PSST.SegmentSource AS SegmentOrigin                
    ,0 AS ChildCount                
    ,0 AS SrcLinksCnt                
    ,0 AS TgtLinksCnt                
    ,PSST.SequenceNumber                
    ,PSST.mSegmentStatusId                
    ,(CASE              
   WHEN PSST.SegmentSource = 'M' THEN PSST.mSegmentId  
   ELSE 0  
  END) AS SegmentCode  
    ,PSST.mSegmentId                
    ,PSST.SegmentId                
  ,0 AS IsFetchedDbLinkResult
  ,(CASE WHEN PS.mSectionId IS NOT NULL THEN PS.mSectionId ELSE 0 END) AS mSectionId
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN #ProjectSection PS WITH (NOLOCK)                
  ON PSST.SectionId = PS.SectionId                
 INNER JOIN #InputDataTable IDT WITH (NOLOCK)                
  ON PS.SectionCode = IDT.SectionCode                
   AND PSST.SegmentStatusCode = IDT.SegmentStatusCode                
 WHERE PSST.ProjectId = @ProjectId                
 AND PSST.CustomerId = @CustomerId                
 --AND PS.IsDeleted = 0                
 UNION                
 --GET SEGMENT STATUS OF SOURCE RECORDS FROM FETCHED TGT LINKS                
 SELECT DISTINCT                
  PSST.ProjectId                
    ,PSST.SectionId                
    ,PSST.CustomerId                
    ,PSST.SegmentStatusId                
    ,PSST.SegmentStatusCode                
    ,PSST.SegmentStatusTypeId                
    ,PSST.IsParentSegmentStatusActive                
    ,PSST.ParentSegmentStatusId                
    ,PS.SectionCode                
    ,PSST.SegmentOrigin AS SegmentSource                
    ,PSST.SegmentSource AS SegmentOrigin                
    ,0 AS ChildCount                
    ,0 AS SrcLinksCnt                
    ,0 AS TgtLinksCnt                
    ,PSST.SequenceNumber                
    ,PSST.mSegmentStatusId                
    ,0 AS SegmentCode                
    ,PSST.mSegmentId                
    ,PSST.SegmentId                
    ,0 AS IsFetchedDbLinkResult
	,(CASE WHEN PS.mSectionId IS NOT NULL THEN PS.mSectionId ELSE 0 END) AS mSectionId
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN #ProjectSection PS WITH (NOLOCK)                
  ON PSST.SectionId = PS.SectionId                
 INNER JOIN #SegmentLinkTable SRC_SLT WITH (NOLOCK)                
  ON PS.SectionCode = SRC_SLT.SourceSectionCode                
   AND PSST.SegmentStatusCode = SRC_SLT.SourceSegmentStatusCode                
 WHERE PSST.ProjectId = @ProjectId                
 AND PSST.CustomerId = @CustomerId                 --AND PS.IsDeleted = 0                
 AND SRC_SLT.IsTgtLink = 1                
 UNION                
 --GET SEGMENT STATUS OF TARGET RECORDS FROM FETCHED TGT LINKS                
 SELECT DISTINCT                
  PSST.ProjectId                
    ,PSST.SectionId                
    ,PSST.CustomerId                
    ,PSST.SegmentStatusId                
    ,PSST.SegmentStatusCode                
    ,PSST.SegmentStatusTypeId                
    ,PSST.IsParentSegmentStatusActive                
    ,PSST.ParentSegmentStatusId                
    ,PS.SectionCode                
    ,PSST.SegmentOrigin AS SegmentSource                
    ,PSST.SegmentSource AS SegmentOrigin                
    ,0 AS ChildCount                
    ,0 AS SrcLinksCnt                
    ,0 AS TgtLinksCnt                
    ,PSST.SequenceNumber                
    ,PSST.mSegmentStatusId                
   ,0 AS SegmentCode                
    ,PSST.mSegmentId                
    ,PSST.SegmentId                
    ,0 AS IsFetchedDbLinkResult
	,(CASE WHEN PS.mSectionId IS NOT NULL THEN PS.mSectionId ELSE 0 END) AS mSectionId
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN #ProjectSection PS WITH (NOLOCK)                
  ON PSST.SectionId = PS.SectionId                
 INNER JOIN #SegmentLinkTable TGT_SLT WITH (NOLOCK)                
  ON PS.SectionCode = TGT_SLT.TargetSectionCode                
   AND PSST.SegmentStatusCode = TGT_SLT.TargetSegmentStatusCode                
 WHERE PSST.ProjectId = @ProjectId                
 AND PSST.CustomerId = @CustomerId                
 --AND PS.IsDeleted = 0                
 AND TGT_SLT.IsTgtLink = 1                
 UNION                
 --GET SEGMENT STATUS OF CHILD RECORDS FROM PASSED INPUT DATA                
 SELECT DISTINCT                
  CPSST.ProjectId                
    ,CPSST.SectionId                
    ,CPSST.CustomerId                
    ,CPSST.SegmentStatusId                
    ,CPSST.SegmentStatusCode                
    ,CPSST.SegmentStatusTypeId                
    ,CPSST.IsParentSegmentStatusActive                
    ,CPSST.ParentSegmentStatusId                
    ,PS.SectionCode                
    ,CPSST.SegmentOrigin AS SegmentSource                
    ,CPSST.SegmentSource AS SegmentOrigin                
    ,0 AS ChildCount                
    ,0 AS SrcLinksCnt                
    ,0 AS TgtLinksCnt                
    ,CPSST.SequenceNumber                
    ,CPSST.mSegmentStatusId                
    ,0 AS SegmentCode                
    ,CPSST.mSegmentId                
    ,CPSST.SegmentId                
    ,0 AS IsFetchedDbLinkResult
	,(CASE WHEN PS.mSectionId IS NOT NULL THEN PS.mSectionId ELSE 0 END) AS mSectionId
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN #ProjectSection PS WITH (NOLOCK)                
  ON PSST.SectionId = PS.SectionId                
 INNER JOIN ProjectSegmentStatus CPSST WITH (NOLOCK)                
  ON PSST.SegmentStatusId = CPSST.ParentSegmentStatusId                
 INNER JOIN #InputDataTable IDT WITH (NOLOCK)                
  ON PS.SectionCode = IDT.SectionCode                
   AND PSST.SegmentStatusCode = IDT.SegmentStatusCode                
 WHERE PSST.ProjectId = @ProjectId                
 AND PSST.CustomerId = @CustomerId                
 --AND PS.IsDeleted = 0                
 UNION                
 --GET SEGMENT STATUS OF CHILD RECORDS FOR TGT RECORDS FROM TGT LINKS                
 SELECT DISTINCT                
  CPSST.ProjectId                
    ,CPSST.SectionId                
    ,CPSST.CustomerId                
    ,CPSST.SegmentStatusId                
    ,CPSST.SegmentStatusCode                
    ,CPSST.SegmentStatusTypeId                
    ,CPSST.IsParentSegmentStatusActive                
    ,CPSST.ParentSegmentStatusId                
    ,PS.SectionCode                
    ,CPSST.SegmentOrigin AS SegmentSource                
    ,CPSST.SegmentSource AS SegmentOrigin                
    ,0 AS ChildCount                
    ,0 AS SrcLinksCnt                
    ,0 AS TgtLinksCnt                
    ,CPSST.SequenceNumber                
    ,CPSST.mSegmentStatusId                
    ,0 AS SegmentCode                
    ,CPSST.mSegmentId                
    ,CPSST.SegmentId                
    ,0 AS IsFetchedDbLinkResult
	,(CASE WHEN PS.mSectionId IS NOT NULL THEN PS.mSectionId ELSE 0 END) AS mSectionId
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN #ProjectSection PS WITH (NOLOCK)                
  ON PSST.SectionId = PS.SectionId                
 INNER JOIN ProjectSegmentStatus CPSST WITH (NOLOCK)                
  ON PSST.SegmentStatusId = CPSST.ParentSegmentStatusId                
 INNER JOIN #SegmentLinkTable TGT_SLT WITH (NOLOCK)                
  ON PS.SectionCode = TGT_SLT.TargetSectionCode                
   AND PSST.SegmentStatusCode = TGT_SLT.TargetSegmentStatusCode                
   AND TGT_SLT.Iteration <= @MaxIteration                
 WHERE PSST.ProjectId = @ProjectId                
 AND PSST.CustomerId = @CustomerId                
 --AND PS.IsDeleted = 0                
 AND TGT_SLT.IsTgtLink = 1                
 UNION                
 --GET SEGMENT STATUS OF PARENT RECORDS FROM PASSED INPUT DATA                
 SELECT                
  PPSST.ProjectId                
    ,PPSST.SectionId                
    ,PPSST.CustomerId                
    ,PPSST.SegmentStatusId                
    ,PPSST.SegmentStatusCode                
    ,PPSST.SegmentStatusTypeId                
    ,PPSST.IsParentSegmentStatusActive                
    ,PPSST.ParentSegmentStatusId                
    ,PS.SectionCode                
    ,PPSST.SegmentOrigin AS SegmentSource                
    ,PPSST.SegmentSource AS SegmentOrigin                
    ,0 AS ChildCount                
    ,0 AS SrcLinksCnt                
    ,0 AS TgtLinksCnt                
    ,PPSST.SequenceNumber                
    ,PPSST.mSegmentStatusId                
    ,0 AS SegmentCode                
    ,PPSST.mSegmentId                
    ,PPSST.SegmentId                
    ,0 AS IsFetchedDbLinkResult
	,(CASE WHEN PS.mSectionId IS NOT NULL THEN PS.mSectionId ELSE 0 END) AS mSectionId
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN #ProjectSection PS WITH (NOLOCK)                
  ON PSST.SectionId = PS.SectionId                
 INNER JOIN ProjectSegmentStatus PPSST WITH (NOLOCK)                
  ON PSST.ParentSegmentStatusId = PPSST.SegmentStatusId                
 INNER JOIN #InputDataTable IDT WITH (NOLOCK)                
  ON PS.SectionCode = IDT.SectionCode                
   AND PSST.SegmentStatusCode = IDT.SegmentStatusCode                
 WHERE PSST.ProjectId = @ProjectId                
 AND PSST.CustomerId = @CustomerId                
 --AND PS.IsDeleted = 0                
 UNION                
 --GET SEGMENT STATUS OF PARENT RECORDS FOR TGT RECORDS FROM TGT LINKS                
 SELECT                
  PPSST.ProjectId                
    ,PPSST.SectionId                
    ,PPSST.CustomerId                
    ,PPSST.SegmentStatusId                
    ,PPSST.SegmentStatusCode                
    ,PPSST.SegmentStatusTypeId                
    ,PPSST.IsParentSegmentStatusActive                
    ,PPSST.ParentSegmentStatusId                
    ,PS.SectionCode                
    ,PPSST.SegmentOrigin AS SegmentSource                
    ,PPSST.SegmentSource AS SegmentOrigin                
    ,0 AS ChildCount                
    ,0 AS SrcLinksCnt                
    ,0 AS TgtLinksCnt                
    ,PPSST.SequenceNumber                
    ,PPSST.mSegmentStatusId                
    ,0 AS SegmentCode                
    ,PPSST.mSegmentId                
    ,PPSST.SegmentId                
    ,0 AS IsFetchedDbLinkResult
	,(CASE WHEN PS.mSectionId IS NOT NULL THEN PS.mSectionId ELSE 0 END) AS mSectionId
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN #ProjectSection PS WITH (NOLOCK)                
  ON PSST.SectionId = PS.SectionId                
 INNER JOIN ProjectSegmentStatus PPSST WITH (NOLOCK)                
  ON PSST.ParentSegmentStatusId = PPSST.SegmentStatusId                
 INNER JOIN #SegmentLinkTable TGT_SLT WITH (NOLOCK)                
  ON PS.SectionCode = TGT_SLT.TargetSectionCode                
   AND PSST.SegmentStatusCode = TGT_SLT.TargetSegmentStatusCode                
   AND TGT_SLT.Iteration <= @MaxIteration                
 WHERE PSST.ProjectId = @ProjectId                
 AND PSST.CustomerId = @CustomerId                
 --AND PS.IsDeleted = 0                
 AND TGT_SLT.IsTgtLink = 1                
 UNION                
 --GET SEGMENT STATUS OF SOURCE RECORDS FROM SRC LINKS                
 SELECT DISTINCT                
  PSST.ProjectId                
    ,PSST.SectionId                
    ,PSST.CustomerId                
    ,PSST.SegmentStatusId                
    ,PSST.SegmentStatusCode                
    ,PSST.SegmentStatusTypeId                
    ,PSST.IsParentSegmentStatusActive                
    ,PSST.ParentSegmentStatusId                
    ,PS.SectionCode                
    ,PSST.SegmentOrigin AS SegmentSource                
    ,PSST.SegmentSource AS SegmentOrigin                
    ,0 AS ChildCount                
    ,0 AS SrcLinksCnt                
    ,0 AS TgtLinksCnt                
    ,PSST.SequenceNumber                
    ,PSST.mSegmentStatusId                
    ,0 AS SegmentCode                
    ,PSST.mSegmentId                
    ,PSST.SegmentId                
    ,0 AS IsFetchedDbLinkResult
	,(CASE WHEN PS.mSectionId IS NOT NULL THEN PS.mSectionId ELSE 0 END) AS mSectionId
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
 INNER JOIN ProjectSection PS WITH (NOLOCK)                
  ON PSST.SectionId = PS.SectionId
  AND IsNULL(PS.IsDeleted,0) = 0
 INNER JOIN #SegmentLinkTable SRC_SLT WITH (NOLOCK)                
  ON PS.SectionCode = SRC_SLT.SourceSectionCode                
   AND PSST.SegmentStatusCode = SRC_SLT.SourceSegmentStatusCode                
 WHERE PSST.ProjectId = @ProjectId                
 AND PSST.CustomerId = @CustomerId                
 --AND PS.IsDeleted = 0                
 AND ((PSST.IsParentSegmentStatusActive = 1                
 AND SRC_SLT.SegmentLinkSourceTypeId IN (@Master_LinkTypeId, @USER_LinkTypeId))                
 OR (                
 SRC_SLT.SegmentLinkSourceTypeId IN (@RS_LinkTypeId, @RE_LinkTypeId, @LinkManE_LinkTypeId)))                
 AND PSST.SegmentStatusTypeId < 6                
 AND SRC_SLT.IsSrcLink = 1                
                
--VIMP: In link engine SegmentSource => SegmentOrigin && SegmentOrigin => SegmentSource                
--VIMP: UPDATE PROPER VERSION OF SEGMENT CODE IN ProjectSegmentStatus TEMP TABLE                
UPDATE TMPSST                
SET TMPSST.SegmentCode = TMPSST.mSegmentId                
FROM #SegmentStatusTable TMPSST WITH (NOLOCK)                
WHERE TMPSST.SegmentSource = 'M'                
                
UPDATE TMPSST             
SET TMPSST.SegmentCode = PSG.SegmentCode                
FROM #SegmentStatusTable TMPSST WITH (NOLOCK)                
INNER JOIN ProjectSegment PSG WITH (NOLOCK)                
 ON TMPSST.SegmentId = PSG.SegmentId                
WHERE TMPSST.SegmentSource = 'U'                
END                
                
/** [BLOCK] SET CHILD COUNT AND TGT LINKS COUNT TO SEGMENT STATUS **/                
BEGIN                
--DELETE UNWANTED LINKS WHOSE VERSION DOESN'T MATCH                
DELETE SLNK                
 FROM #SegmentLinkTable SLNK WITH (NOLOCK)                
 LEFT JOIN #SegmentStatusTable SST WITH (NOLOCK)                
  ON SLNK.SourceSegmentStatusCode = SST.SegmentStatusCode                
  AND SLNK.SourceSegmentCode = SST.SegmentCode                
  AND SLNK.SourceSectionCode = SST.SectionCode                
WHERE SST.SegmentStatusId IS NULL                
                
DELETE SLNK              
 FROM #SegmentLinkTable SLNK WITH (NOLOCK)                
 LEFT JOIN #SegmentStatusTable SST WITH (NOLOCK)                
  ON SLNK.TargetSegmentStatusCode = SST.SegmentStatusCode                
  AND SLNK.TargetSegmentCode = SST.SegmentCode                
  AND SLNK.TargetSectionCode = SST.SectionCode                
WHERE SST.SegmentStatusId IS NULL                
                
--SET CHILD COUNT                
UPDATE ORIGINAL_TMPSST                
SET ORIGINAL_TMPSST.ChildCount = DUPLICATE_TMPSST.ChildCount         
FROM #SegmentStatusTable ORIGINAL_TMPSST                
INNER JOIN (SELECT DISTINCT                
  TMPSST.SegmentStatusId                
    ,COUNT(1) AS ChildCount                
 FROM #SegmentStatusTable TMPSST WITH (NOLOCK)                
 INNER JOIN dbo.ProjectSegmentStatus PSST WITH (NOLOCK)                
  ON TMPSST.SegmentStatusId = PSST.ParentSegmentStatusId                
 WHERE PSST.ProjectId = @ProjectId                
 AND PSST.CustomerId = @CustomerId                
 GROUP BY TMPSST.SegmentStatusId) DUPLICATE_TMPSST                
 ON ORIGINAL_TMPSST.SegmentStatusId = DUPLICATE_TMPSST.SegmentStatusId;                
            
--Print '--SET TGT LINKS COUNT FROM SLCProject'                
--SET TGT LINKS COUNT FROM SLCProject                
UPDATE ORIGINAL_TMPSST                
SET ORIGINAL_TMPSST.TgtLinksCnt = DUPLICATE_TMPSST.TgtLinksCnt                
FROM #SegmentStatusTable ORIGINAL_TMPSST                
INNER JOIN (SELECT DISTINCT                
  TMPSST.SegmentStatusId                
    ,COUNT(1) TgtLinksCnt                
 FROM #SegmentStatusTable TMPSST WITH (NOLOCK)                
 INNER JOIN #ProjectSegmentLink SLNK WITH (NOLOCK)                
 ON TMPSST.ProjectId = SLNK.ProjectId AND              
  TMPSST.SectionCode = SLNK.SourceSectionCode                
  AND TMPSST.SegmentStatusCode = SLNK.SourceSegmentStatusCode                
  AND TMPSST.SegmentCode = SLNK.SourceSegmentCode                
  AND TMPSST.SegmentSource = SLNK.LinkSource                
 LEFT JOIN #SegmentLinkTable TMPSLNK WITH (NOLOCK)                
  ON SLNK.SegmentLinkId = TMPSLNK.SegmentLinkId                
  AND TMPSLNK.SourceOfRecord = @SourceOfRecord_Project                
 WHERE SLNK.ProjectId = @ProjectId                
 AND SLNK.CustomerId = @CustomerId                
 AND SLNK.IsDeleted = 0                
 AND SLNK.SegmentLinkSourceTypeId = 5                
 AND TMPSLNK.SegmentLinkId IS NULL                
 GROUP BY TMPSST.SegmentStatusId) DUPLICATE_TMPSST                
 ON ORIGINAL_TMPSST.SegmentStatusId = DUPLICATE_TMPSST.SegmentStatusId;                
                
--SET TGT LINKS COUNT FROM SLCMaster                
UPDATE ORIGINAL_TMPSST                
SET ORIGINAL_TMPSST.TgtLinksCnt = ORIGINAL_TMPSST.TgtLinksCnt + DUPLICATE_TMPSST.TgtLinksCnt                
FROM #SegmentStatusTable ORIGINAL_TMPSST                
INNER JOIN (SELECT DISTINCT                
  TMPSST.SegmentStatusId                
    ,COUNT(1) TgtLinksCnt                
 FROM #SegmentStatusTable TMPSST WITH (NOLOCK)                
 INNER JOIN SLCMaster..SegmentLink SLNK WITH (NOLOCK)                
  ON TMPSST.SectionCode = SLNK.SourceSectionCode                
  AND TMPSST.SegmentStatusCode = SLNK.SourceSegmentStatusCode                
  AND TMPSST.SegmentCode = SLNK.SourceSegmentCode                
  AND TMPSST.SegmentSource = SLNK.LinkSource                
 LEFT JOIN #SegmentLinkTable TMPSLNK WITH (NOLOCK)                
  ON SLNK.SegmentLinkId = TMPSLNK.SegmentLinkId                
  AND TMPSLNK.SourceOfRecord = @SourceOfRecord_Master                
 WHERE SLNK.IsDeleted = 0                
 AND TMPSLNK.SegmentLinkId IS NULL                
 GROUP BY TMPSST.SegmentStatusId) DUPLICATE_TMPSST                
 ON ORIGINAL_TMPSST.SegmentStatusId = DUPLICATE_TMPSST.SegmentStatusId;                
END                
                
/** [BLOCK] GET SEGMENT CHOICE DATA **/                
BEGIN                
INSERT INTO #SegmentChoiceTable                
 --GET CHOICES FOR SOURCE RECORDS FROM LINKS FROM SLCMaster                
 SELECT DISTINCT                
  PSST.ProjectId                
    ,PSST.SectionId                
    ,PSST.CustomerId                
    ,CH.SegmentChoiceCode                
    ,CH.SegmentChoiceSource                
    ,CH.ChoiceTypeId                
    ,CHOP.ChoiceOptionCode                
    ,CHOP.ChoiceOptionSource                
    ,SCHOP.IsSelected                
    ,PSST.SectionCode                
    ,PSST.SegmentStatusId                
    ,PSST.mSegmentId                
    ,PSST.SegmentId                
    ,SCHOP.SelectedChoiceOptionId                
 FROM #SegmentStatusTable PSST WITH (NOLOCK)                
 INNER JOIN SLCMaster..SegmentChoice CH WITH (NOLOCK)                
  --ON PSST.mSegmentId = CH.SegmentId                
  ON PSST.mSectionId = CH.SectionId AND PSST.mSegmentId = CH.SegmentId
 INNER JOIN SLCMaster..ChoiceOption CHOP WITH (NOLOCK)                
  ON CH.SegmentChoiceId = CHOP.SegmentChoiceId                
 INNER JOIN SelectedChoiceOption SCHOP WITH (NOLOCK)                
  ON SCHOP.CustomerId = PSST.CustomerId    
   AND SCHOP.ProjectId = PSST.ProjectId    
   AND SCHOP.SectionId = PSST.SectionId    
   AND SCHOP.SegmentChoiceCode = CH.SegmentChoiceCode    
   AND SCHOP.ChoiceOptionCode = CHOP.ChoiceOptionCode    
   AND SCHOP.ChoiceOptionSource = 'M'    
 INNER JOIN #SegmentLinkTable SRC_SLT WITH (NOLOCK)                
  ON SCHOP.SegmentChoiceCode = SRC_SLT.SourceSegmentChoiceCode                
   AND SCHOP.ChoiceOptionSource = SRC_SLT.LinkSource                
 --WHERE     
 --SCHOP.ProjectId = @ProjectId                
 --AND SCHOP.CustomerId = @CustomerId                
 --AND SCHOP.ChoiceOptionSource = 'M'    
 UNION                
 --GET CHOICES FOR TARGET RECORDS FROM LINKS FROM SLCMaster                
 SELECT DISTINCT                
  PSST.ProjectId                
    ,PSST.SectionId                
    ,PSST.CustomerId                
    ,CH.SegmentChoiceCode                
    ,CH.SegmentChoiceSource                
    ,CH.ChoiceTypeId                
    ,CHOP.ChoiceOptionCode                
    ,CHOP.ChoiceOptionSource                
    ,SCHOP.IsSelected                
    ,PSST.SectionCode                
    ,PSST.SegmentStatusId                
    ,PSST.mSegmentId                
    ,PSST.SegmentId                
    ,SCHOP.SelectedChoiceOptionId                
 FROM #SegmentStatusTable PSST WITH (NOLOCK)                
 INNER JOIN SLCMaster..SegmentChoice CH WITH (NOLOCK)                
  --ON PSST.mSegmentId = CH.SegmentId                
  ON PSST.mSectionId = CH.SectionId AND PSST.mSegmentId = CH.SegmentId
 INNER JOIN SLCMaster..ChoiceOption CHOP WITH (NOLOCK)                
  ON CH.SegmentChoiceId = CHOP.SegmentChoiceId                
 INNER JOIN SelectedChoiceOption SCHOP WITH (NOLOCK)                
  ON SCHOP.CustomerId = PSST.CustomerId    
   AND SCHOP.ProjectId = PSST.ProjectId    
   AND SCHOP.SectionId = PSST.SectionId    
   AND SCHOP.SegmentChoiceCode = CH.SegmentChoiceCode    
   AND SCHOP.ChoiceOptionCode = CHOP.ChoiceOptionCode    
   AND SCHOP.ChoiceOptionSource = 'M'         
 INNER JOIN #SegmentLinkTable TGT_SLT WITH (NOLOCK)                
  ON SCHOP.SegmentChoiceCode = TGT_SLT.TargetSegmentChoiceCode                
   AND SCHOP.ChoiceOptionSource = TGT_SLT.LinkTarget                
 --WHERE SCHOP.ProjectId = @ProjectId                
 --AND SCHOP.CustomerId = @CustomerId                
 --AND SCHOP.ChoiceOptionSource = 'M'                
 UNION                
 --GET CHOICES FOR SOURCE RECORDS FROM LINKS FROM SLCProject                
 SELECT                
  PSST.ProjectId                
    ,PSST.SectionId                
    ,PSST.CustomerId                
    ,CH.SegmentChoiceCode                
    ,CH.SegmentChoiceSource                
    ,CH.ChoiceTypeId                
    ,CHOP.ChoiceOptionCode                
    ,CHOP.ChoiceOptionSource                
    ,SCHOP.IsSelected                
    ,PSST.SectionCode                
    ,PSST.SegmentStatusId                
    ,PSST.mSegmentId                
    ,PSST.SegmentId                
    ,SCHOP.SelectedChoiceOptionId                
 FROM #SegmentStatusTable PSST WITH (NOLOCK)                
 INNER JOIN ProjectSegmentChoice CH WITH (NOLOCK)                
 ON CH.ProjectId = PSST.ProjectId AND CH.CustomerId = PSST.CustomerId AND CH.SectionId = PSST.SectionId and              
   PSST.SegmentId = CH.SegmentId                
 INNER JOIN ProjectChoiceOption CHOP WITH (NOLOCK)                
 ON CHOP.SectionId = PSST.SectionId  and              
   CH.SegmentChoiceId = CHOP.SegmentChoiceId                
 INNER JOIN SelectedChoiceOption SCHOP WITH (NOLOCK)                
 ON SCHOP.CustomerId = PSST.CustomerId    
   AND SCHOP.ProjectId = PSST.ProjectId    
   AND SCHOP.SectionId = PSST.SectionId    
   AND SCHOP.SegmentChoiceCode = CH.SegmentChoiceCode    
   AND SCHOP.ChoiceOptionCode = CHOP.ChoiceOptionCode    
   AND SCHOP.ChoiceOptionSource = 'U'         
 INNER JOIN #SegmentLinkTable SRC_SLT WITH (NOLOCK)                
  ON SCHOP.SegmentChoiceCode = SRC_SLT.SourceSegmentChoiceCode                
  AND SCHOP.ChoiceOptionSource = SRC_SLT.LinkSource                
 --WHERE SCHOP.ProjectId = @ProjectId                
 --AND SCHOP.CustomerId = @CustomerId                
 --AND SCHOP.ChoiceOptionSource = 'U'                
 UNION                
 --GET CHOICES FOR TARGET RECORDS FROM LINKS FROM SLCProject                
 SELECT                
  PSST.ProjectId                
    ,PSST.SectionId                
    ,PSST.CustomerId                
    ,CH.SegmentChoiceCode                
    ,CH.SegmentChoiceSource                
    ,CH.ChoiceTypeId                
    ,CHOP.ChoiceOptionCode                
    ,CHOP.ChoiceOptionSource                
    ,SCHOP.IsSelected                
    ,PSST.SectionCode                
    ,PSST.SegmentStatusId                
    ,PSST.mSegmentId                
    ,PSST.SegmentId                
    ,SCHOP.SelectedChoiceOptionId                
 FROM #SegmentStatusTable PSST WITH (NOLOCK)                
 INNER JOIN ProjectSegmentChoice CH WITH (NOLOCK)                
 ON CH.ProjectId = PSST.ProjectId AND CH.CustomerId = PSST.CustomerId AND CH.SectionId = PSST.SectionId and              
   PSST.SegmentId = CH.SegmentId                
 INNER JOIN ProjectChoiceOption CHOP WITH (NOLOCK)                
 ON CHOP.SectionId = PSST.SectionId  and              
  CH.SegmentChoiceId = CHOP.SegmentChoiceId                
 INNER JOIN SelectedChoiceOption SCHOP WITH (NOLOCK)                
  ON SCHOP.CustomerId = PSST.CustomerId    
   AND SCHOP.ProjectId = PSST.ProjectId    
   AND SCHOP.SectionId = PSST.SectionId    
   AND SCHOP.SegmentChoiceCode = CH.SegmentChoiceCode    
   AND SCHOP.ChoiceOptionCode = CHOP.ChoiceOptionCode    
   AND SCHOP.ChoiceOptionSource = 'U'                 
 INNER JOIN #SegmentLinkTable TGT_SLT WITH (NOLOCK)                
  ON SCHOP.SegmentChoiceCode = TGT_SLT.TargetSegmentChoiceCode                
   AND SCHOP.ChoiceOptionSource = TGT_SLT.LinkTarget                
 --WHERE     
 --SCHOP.ProjectId = @ProjectId                
 --AND SCHOP.CustomerId = @CustomerId                
 --AND SCHOP.ChoiceOptionSource = 'U'                
END                
                
/** [BLOCK] SET IsFetchedDbLinkResult **/                
BEGIN                
--UPDATE PSST                
--SET PSST.IsFetchedDbLinkResult = CAST(1 AS BIT)                
--FROM #SegmentStatusTable PSST WITH (NOLOCK)                
--INNER JOIN #InputDataTable IDT WITH (NOLOCK)                
-- ON PSST.SectionCode = IDT.SectionCode                
-- AND PSST.SegmentStatusCode = IDT.SegmentStatusCode                
-- AND PSST.SegmentSource = IDT.SegmentSource                
                
UPDATE PSST        
SET PSST.IsFetchedDbLinkResult = CAST(1 AS BIT)                
FROM #SegmentLinkTable SLT WITH (NOLOCK)                
INNER JOIN #SegmentStatusTable PSST WITH (NOLOCK)                
 ON SLT.TargetSectionCode = PSST.SectionCode                
 AND SLT.TargetSegmentStatusCode = PSST.SegmentStatusCode                
 AND SLT.TargetSegmentCode = PSST.SegmentCode                
 AND SLT.LinkTarget = PSST.SegmentSource                
WHERE SLT.Iteration < @MaxIteration                
END                
                
/** [BLOCK] FETCH FINAL DATA **/                
BEGIN                
--SELECT LINK RESULT            
                 
SELECT                
DISTINCT                
 SLNK.SegmentLinkId                
   ,SLNK.SourceSectionCode                
   ,SLNK.SourceSegmentStatusCode                
   ,SLNK.SourceSegmentCode                
   ,COALESCE(SLNK.SourceSegmentChoiceCode, 0) AS SourceSegmentChoiceCode                
,COALESCE(SLNK.SourceChoiceOptionCode, 0) AS SourceChoiceOptionCode                
   ,SLNK.LinkSource                
   ,SLNK.TargetSectionCode                
   ,SLNK.TargetSegmentStatusCode                
   ,SLNK.TargetSegmentCode                
   ,COALESCE(SLNK.TargetSegmentChoiceCode, 0) AS TargetSegmentChoiceCode                
   ,COALESCE(SLNK.TargetChoiceOptionCode, 0) AS TargetChoiceOptionCode                
   ,SLNK.LinkTarget                
   ,SLNK.LinkStatusTypeId                
   ,CASE                
  WHEN SLNK.SourceSegmentChoiceCode IS NULL AND                
   SLNK.TargetSegmentChoiceCode IS NULL THEN @P2P                
  WHEN SLNK.SourceSegmentChoiceCode IS NULL AND                
   SLNK.TargetSegmentChoiceCode IS NOT NULL THEN @P2C                
  WHEN SLNK.SourceSegmentChoiceCode IS NOT NULL AND                
   SLNK.TargetSegmentChoiceCode IS NULL THEN @C2P                
  WHEN SLNK.SourceSegmentChoiceCode IS NOT NULL AND                
   SLNK.TargetSegmentChoiceCode IS NOT NULL THEN @C2C                
 END AS SegmentLinkType                
   ,SLNK.SourceOfRecord                
   ,SLNK.SegmentLinkCode                
   ,SLNK.SegmentLinkSourceTypeId                
   ,SLNK.IsDeleted                
   ,@ProjectId AS ProjectId                
   ,@CustomerId AS CustomerId                
FROM #SegmentLinkTable SLNK WITH (NOLOCK)                
            
            
                
SELECT                
 PSST.ProjectId                
   ,PSST.SectionId                
   ,PSST.CustomerId                
   ,PSST.SegmentStatusId                
   ,COALESCE(PSST.SegmentStatusCode, 0) AS SegmentStatusCode                
   ,PSST.SegmentStatusTypeId                
   ,PSST.IsParentSegmentStatusActive                
   ,PSST.ParentSegmentStatusId                
   ,COALESCE(PSST.SectionCode, 0) AS SectionCode                
   ,PSST.SegmentSource                
   ,PSST.SegmentOrigin                
   ,PSST.ChildCount                
   ,PSST.SrcLinksCnt                
   ,PSST.TgtLinksCnt                
   ,COALESCE(PSST.SequenceNumber, 0) AS SequenceNumber                
   ,COALESCE(PSST.mSegmentStatusId, 0) AS mSegmentStatusId                
   ,COALESCE(PSST.SegmentCode, 0) AS SegmentCode                
   ,COALESCE(PSST.mSegmentId, 0) AS mSegmentId                
   ,COALESCE(PSST.SegmentId, 0) AS SegmentId                
   ,PSST.IsFetchedDbLinkResult                
FROM #SegmentStatusTable PSST WITH (NOLOCK)  
inner join #ProjectSection PS with (nolock)
on PS.SectionId =  PSST.SectionId
               
            
                 
SELECT                
 SCH.ProjectId                
   ,SCH.SectionId                
   ,SCH.CustomerId                
   ,COALESCE(SCH.SegmentChoiceCode, 0) AS SegmentChoiceCode                
   ,SCH.SegmentChoiceSource                
   ,SCH.ChoiceTypeId                
   ,COALESCE(SCH.ChoiceOptionCode, 0) AS ChoiceOptionCode                
   ,SCH.ChoiceOptionSource                
   ,SCH.IsSelected                
   ,COALESCE(SCH.SectionCode, 0) AS SectionCode                
   ,SCH.SegmentStatusId                
   ,COALESCE(SCH.mSegmentId, 0) AS mSegmentId                
   ,COALESCE(SCH.SegmentId, 0) AS SegmentId                
   ,SCH.SelectedChoiceOptionId                
FROM #SegmentChoiceTable SCH WITH (NOLOCK)                
                 
SELECT            
 PSRT.SegmentRequirementTagId AS SegmentRequirementTagId            
   ,COALESCE(PSST.mSegmentStatusId, 0) AS mSegmentStatusId            
   ,PSRT.RequirementTagId AS RequirementTagId            
   ,PSST.SegmentStatusId AS SegmentStatusId            
   ,@SourceOfRecord_Project AS SourceOfRecord            
FROM #SegmentStatusTable PSST WITH (NOLOCK)            
INNER JOIN ProjectSegmentRequirementTag PSRT WITH (NOLOCK)            
 ON PSRT.SegmentStatusId = PSST.SegmentStatusId   
 AND PSRT.RequirementTagId IN (@RS_TAG, @RT_TAG, @RE_TAG, @ST_TAG)   
WHERE PSRT.ProjectId = @ProjectId            
AND PSRT.CustomerId = @CustomerId            
AND ISNULL(PSRT.IsDeleted,0)=0          
                 
SELECT                
 PSMRY.ProjectId                
   ,PSMRY.CustomerId                
   ,PSMRY.IsIncludeRsInSection                
   ,PSMRY.IsIncludeReInSection                
   ,PSMRY.IsActivateRsCitation                
FROM ProjectSummary PSMRY WITH (NOLOCK)                
WHERE PSMRY.ProjectId = @ProjectId                
AND PSMRY.CustomerId = @CustomerId             
             
END               
        
DROP TABLE IF EXISTS #ProjectSection;    
DROP TABLE IF EXISTS #ProjectSegmentLink;    
                
END  
