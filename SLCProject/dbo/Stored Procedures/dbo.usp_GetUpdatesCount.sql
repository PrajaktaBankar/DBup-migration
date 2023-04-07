CREATE  PROCEDURE [dbo].[usp_GetUpdatesCount]  
@ProjectId INT, @SectionId INT, @CustomerId INT, @CatalogueType NVARCHAR(50) = 'FS'        
AS        
BEGIN    
DECLARE @PProjectId INT = @ProjectId;    
DECLARE @PSectionId INT = @SectionId;    
DECLARE @PCustomerId INT = @CustomerId;    
DECLARE @PCatalogueType NVARCHAR(50) = @CatalogueType;    
--DECLARE @ProjectId INT = 0;    
--DECLARE @SectionId INT = 0;    
--DECLARE @CustomerId INT = 0;    
--DECLARE @CatalogueType NVARCHAR(50) = '';    
    
--VARIABLES          
    
--FINAL TABLE CONTAINS [SEGMENTS UPDATES] OF VARIOUS TYPES          
DROP TABLE IF EXISTS #SegmentUpdatesTable;    
CREATE TABLE #SegmentUpdatesTable (    
 SegmentStatusId BIGINT NULL    
   , --Project SegmentStatusId          
 ParentSegmentStatusId BIGINT NULL    
   , --Project ParentSegmentStatusId          
 mSegmentStatusId INT NULL    
   , --Master SegmentStatusId          
 mSegmentId INT NULL    
   , --Master SegmentId          
 SegmentSource CHAR(1) NULL    
   , --SegmentSource          
 SegmentOrigin CHAR(2) NULL    
   , --SegmentOrigin          
 IndentLevel TINYINT NULL    
   , --IndentLevel          
 MasterIndentLevel TINYINT NULL    
   , --Master IndentLevel          
 UpdateType NVARCHAR(MAX) NULL    
   , --Update Type          
 ScenarioA BIT NULL    
   , --Is Delete ScenarioA          
 ScenarioB BIT NULL    
   , --Is Delete ScenarioB          
 ScenarioC BIT NULL    
   , --Is Delete ScenarioC          
);    
    
--TEMP TABLE USED TO STORE DELETED SEGMENTS COUNT          
DROP TABLE IF EXISTS #DeletedSegmentsTable;    
CREATE TABLE #DeletedSegmentsTable (    
 Id INT NULL    
   , -- Row Id          
 SegmentStatusId BIGINT NULL    
   , --Project SegmentStatusId          
);    
    
--TABLE TO STORE DELETED SEGMENTS HIERARCHY          
DROP TABLE IF EXISTS #DeletedSegmentsHierarchy;    
CREATE TABLE #DeletedSegmentsHierarchy (    
 SegmentStatusId BIGINT NULL    
   , --Project SegmentStatusId          
 ParentSegmentStatusId BIGINT NULL    
   , --Project ParentSegmentStatusId          
 mSegmentStatusId INT NULL    
   , --Master SegmentStatusId          
 mSegmentId INT NULL    
   , --Master SegmentId          
 SegmentSource CHAR(1) NULL    
   , --SegmentSource          
 SegmentOrigin CHAR(2) NULL    
   , --SegmentOrigin          
 IndentLevel TINYINT NULL    
   , --IndentLevel          
 MasterIndentLevel TINYINT NULL    
   , --Master IndentLevel          
 ReferencedSegmentStatusId BIGINT NULL --Original SegmentStatusId whose sub hierarchy is          
);    
    
--TABLE TO STORE RS UPDATES          
DROP TABLE IF EXISTS #RSUpdatesTable;    
CREATE TABLE #RSUpdatesTable (    
 RefStandardId INT NULL    
   ,RefStdName NVARCHAR(100) NULL    
);    
    
--TABLE TO STORE User RS UPDATES          
DROP TABLE IF EXISTS #URSUpdatesTable;    
CREATE TABLE #URSUpdatesTable (    
 RefStandardId INT NULL    
   ,RefStdName NVARCHAR(100) NULL    
);    
    
--TABLE TO STORE NEW PARAGRAPH UPDATES      
DROP TABLE IF EXISTS #MutedParagraphUpdatesTable;    
CREATE TABLE #MutedParagraphUpdatesTable (    
 mSegmentStatusId INT NULL    
   ,mSegmentId INT NULL    
);    
    
--TABLE TO STORE SPECTYPETAGID'S      
DROP TABLE IF EXISTS #LuSpecTypeTagTable;    
CREATE TABLE #LuSpecTypeTagTable (    
 SpecTypeTagId INT NULL    
);    
    
DECLARE @UpdateType_TEXT NVARCHAR(MAX) = 'TEXT';    
DECLARE @UpdateType_DELETE NVARCHAR(MAX) = 'DELETE';    
DECLARE @UpdateType_MANUFACTURER NVARCHAR(MAX) = 'MANUFACTURER';    
DECLARE @RequirementTagId_ML INT = 11;    
DECLARE @UpdatesCount INT = 0;    
    
DECLARE @DeletedSegmentsCount INT = NULL;    
DECLARE @DeletedSegmentsLoopCount INT = NULL;    
DECLARE @LoopedSegmentStatusId BIGINT = NULL;    
    
DECLARE @mSectionId INT = NULL;    
    
--GET mSectionId      
SELECT    
 @mSectionId = PS.mSectionId    
FROM ProjectSection PS WITH (NOLOCK)    
INNER JOIN SLCMaster..Section MS WITH (NOLOCK)    
 ON PS.mSectionId = MS.SectionId    
WHERE PS.SectionId = @PSectionId    
AND PS.ProjectId = @PProjectId    
AND PS.CustomerId = @PCustomerId    
AND ISNULL( MS.IsDeleted,0) = 0  
AND ISNULL( PS.IsDeleted,0) = 0  
AND PS.Author != 'USER'    
    
IF @mSectionId IS NOT NULL    
 AND @mSectionId > 0    
BEGIN    
    
--IF undefined CAME FROM UI THEN SET TO FS    
IF @CatalogueType = 'undefined'    
BEGIN    
SET @CatalogueType = 'FS';    
END    
    
--CALCULATE SPECTYPETAG ID'S    
IF @CatalogueType != 'FS'      
BEGIN    
INSERT INTO #LuSpecTypeTagTable (SpecTypeTagId)    
 SELECT    
  SpecTypeTagId    
 FROM LuProjectSpecTypeTag WITH (NOLOCK)    
 WHERE TagType IN (SELECT    
   *    
  FROM dbo.fn_SplitString(@CatalogueType, ','))    
END    
    
--FETCH [MASTER TEXT UPDATES], [MANUFACTURER UPDATES] AND [MASTER SEGMENT DELETE UPDATES] OF NORMAL SCENARIOS          
INSERT INTO #SegmentUpdatesTable (SegmentStatusId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId,    
SegmentSource, SegmentOrigin, IndentLevel, MasterIndentLevel, UpdateType)    
 SELECT DISTINCT    
  PSST.SegmentStatusId AS SegmentStatusId    
    ,CONVERT(BIGINT,PSST.ParentSegmentStatusId)   AS ParentSegmentStatusId    
    ,PSST.mSegmentStatusId AS mSegmentStatusId    
    ,PSST.mSegmentId AS mSegmentId    
    ,PSST.SegmentSource AS SegmentSource    
    ,PSST.SegmentOrigin AS SegmentOrigin    
    ,PSST.IndentLevel AS IndentLevel    
    ,MST.IndentLevel AS MasterIndentLevel    
    ,(CASE    
   WHEN ISNULL(PSST.IsDeleted, 0) = 0 AND    
    ISNULL(MST.IsDeleted, 0) = 0 AND    
    ISNULL(MSG.UpdatedId, 0) > 0 AND    
    MSRT.SegmentRequirementTagId IS NOT NULL THEN @UpdateType_MANUFACTURER    
   WHEN ISNULL(PSST.IsDeleted, 0) = 0 AND    
    ISNULL(MST.IsDeleted, 0) = 0 AND    
    ISNULL(MSG.UpdatedId, 0) > 0 AND    
    MSRT.SegmentRequirementTagId IS NULL THEN @UpdateType_TEXT    
   WHEN ISNULL(PSST.IsDeleted, 0) = 0 AND    
    ISNULL(MST.IsDeleted, 0) > 0 THEN @UpdateType_DELETE    
  END) AS UpdateType    
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)    
 INNER JOIN SLCMaster..SegmentStatus MST WITH (NOLOCK)    
  ON PSST.mSegmentStatusId = MST.SegmentStatusId    
 INNER JOIN SLCMaster..Segment MSG WITH (NOLOCK)    
  ON PSST.mSegmentId = MSG.SegmentId    
 LEFT JOIN #LuSpecTypeTagTable TMPLST    
  ON PSST.SpecTypeTagId = TMPLST.SpecTypeTagId    
 LEFT JOIN SLCMaster..SegmentRequirementTag MSRT WITH (NOLOCK)    
  ON MST.SegmentStatusId = MSRT.SegmentStatusId    
   AND MSRT.RequirementTagId = @RequirementTagId_ML    
 WHERE PSST.SectionId = @PSectionId    
 AND PSST.ProjectId = @PProjectId    
 AND PSST.CustomerId = @PCustomerId    
 AND PSST.SegmentSource = 'M'    
 --Reference Standard Paragraph : Customer Support 48227: SLC Ref Standard Update Issue  
 --AND PSST.IsRefStdParagraph = 0    
 AND PSST.mSegmentId IS NOT NULL    
 AND ((    
 ISNULL(PSST.IsDeleted, 0) = 0    
 AND ISNULL(MST.IsDeleted, 0) = 0    
 AND ISNULL(MSG.UpdatedId, 0) > 0    
 )    
 OR (    
 ISNULL(PSST.IsDeleted, 0) = 0    
 AND ISNULL(MST.IsDeleted, 0) > 0    
 ))    
 AND ((@CatalogueType = 'FS')    
 OR (TMPLST.SpecTypeTagId IS NOT NULL))    
    
--PUSH DELETED SEGMENTS INTO ONE TABLE          
INSERT INTO #DeletedSegmentsTable (Id, SegmentStatusId)    
 SELECT    
  ROW_NUMBER() OVER (ORDER BY SegmentStatusId ASC)    
    ,SegmentStatusId    
 FROM #SegmentUpdatesTable    
 WHERE UpdateType = @UpdateType_DELETE    
    
SET @DeletedSegmentsCount = (SELECT    
  COUNT(*)    
 FROM #DeletedSegmentsTable);    
    
--FETCH DELETED SEGMENTS AND THEIR SUB HIERARCHY INTO TEMP TABLE          
;    
WITH CTE_SubHierarchy    
AS    
(    
 --GET DELETED SEGMENTS          
 SELECT    
  UT.SegmentStatusId AS SegmentStatusId    
    ,CONVERT(BIGINT,UT.ParentSegmentStatusId)  AS ParentSegmentStatusId    
    ,UT.mSegmentStatusId AS mSegmentStatusId    
    ,UT.mSegmentId AS mSegmentId    
    ,CAST(UT.SegmentSource AS CHAR(1)) AS SegmentSource    
    ,CAST(UT.SegmentOrigin AS CHAR(2)) SegmentOrigin    
    ,UT.IndentLevel AS IndentLevel    
    ,UT.SegmentStatusId AS ReferencedSegmentStatusId    
 FROM #SegmentUpdatesTable UT    
 WHERE UT.UpdateType = @UpdateType_DELETE    
 UNION ALL    
 --GET SUB HIERARCHY OF DELETED SEGMENTS          
 SELECT    
  CPSST.SegmentStatusId AS SegmentStatusId    
    ,CONVERT(BIGINT,CPSST.ParentSegmentStatusId) AS ParentSegmentStatusId    
    ,CPSST.mSegmentStatusId AS mSegmentStatusId    
    ,CPSST.mSegmentId AS mSegmentId    
    ,CAST(CPSST.SegmentSource AS CHAR(1)) AS SegmentSource    
    ,CAST(CPSST.SegmentOrigin AS CHAR(2)) AS SegmentOrigin    
    ,CPSST.IndentLevel AS IndentLevel    
    ,CTE.ReferencedSegmentStatusId AS ReferencedSegmentStatusId    
 FROM CTE_SubHierarchy CTE    
 INNER JOIN ProjectSegmentStatus CPSST WITH (NOLOCK)    
  ON CTE.SegmentStatusId = CONVERT(INT,CPSST.ParentSegmentStatusId)    
 WHERE CPSST.SectionId = @PSectionId  
 AND CPSST.ProjectId = @PProjectId    
 AND CPSST.CustomerId = @PCustomerId )    
    
INSERT INTO #DeletedSegmentsHierarchy (SegmentStatusId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId,    
SegmentSource, SegmentOrigin, IndentLevel, ReferencedSegmentStatusId)    
 SELECT    
  SegmentStatusId    
    ,ParentSegmentStatusId    
    ,mSegmentStatusId    
    ,mSegmentId    
    ,SegmentSource    
    ,SegmentOrigin    
    ,IndentLevel    
    ,ReferencedSegmentStatusId    
 FROM CTE_SubHierarchy    
    
--UPDATE MASTER INDENT LEVEL IN HIERARCHY          
UPDATE PSST    
SET PSST.MasterIndentLevel = MST.IndentLevel    
FROM #DeletedSegmentsHierarchy PSST    
INNER JOIN SLCMaster..SegmentStatus MST WITH (NOLOCK)    
 ON PSST.mSegmentStatusId = MST.SegmentStatusId    
    
--LOOP DELETED SEGMENTS TO FIND THEIR COMPLEX SCENARIOS A,B,C IF ANY          
SET @DeletedSegmentsLoopCount = 1;    
          
WHILE(@DeletedSegmentsLoopCount <= @DeletedSegmentsCount)          
BEGIN    
SET @LoopedSegmentStatusId = (SELECT    
  SegmentStatusId    
 FROM #DeletedSegmentsTable    
 WHERE Id = @DeletedSegmentsLoopCount);    
        
DECLARE @ScenarioA BIT = NULL;    
DECLARE @ScenarioB BIT = NULL;    
DECLARE @ScenarioC BIT = NULL;    
           
--SCENARIO A          
IF EXISTS (SELECT TOP 1    
  SegmentStatusId    
 FROM #DeletedSegmentsHierarchy    
 WHERE ReferencedSegmentStatusId = @LoopedSegmentStatusId    
 AND IndentLevel != MasterIndentLevel)    
BEGIN    
SET @ScenarioA = 1;    
END    
       
--SCENARIO B          
IF EXISTS (SELECT TOP 1    
  SegmentStatusId    
 FROM #DeletedSegmentsHierarchy    
 WHERE ReferencedSegmentStatusId = @LoopedSegmentStatusId    
 AND SegmentSource = 'U'    
 AND SegmentOrigin = 'U')    
BEGIN    
SET @ScenarioB = 1;    
END    
      
--SCENARIO C          
IF EXISTS (SELECT TOP 1    
  SegmentStatusId    
 FROM #DeletedSegmentsHierarchy    
 WHERE ReferencedSegmentStatusId = @LoopedSegmentStatusId    
 AND SegmentSource = 'M'    
 AND SegmentOrigin = 'U')    
BEGIN    
SET @ScenarioC = 1;    
END    
    
UPDATE #SegmentUpdatesTable    
SET @ScenarioA = @ScenarioA    
   ,@ScenarioB = @ScenarioB    
   ,@ScenarioC = @ScenarioC    
WHERE SegmentStatusId = @LoopedSegmentStatusId;    
    
SET @DeletedSegmentsLoopCount = @DeletedSegmentsLoopCount + 1;    
END    
  
--GET MUTED PARAGRAPH UPDATES COUNT      
IF EXISTS (SELECT TOP 1    
   PSST.SegmentStatusId    
  FROM ProjectSegmentStatus PSST WITH (NOLOCK)    
  WHERE PSST.SectionId = @PSectionId  
  AND PSST.ProjectId = @PProjectId    
  AND PSST.CustomerId = @PCustomerId)    
BEGIN    
INSERT INTO #MutedParagraphUpdatesTable (mSegmentStatusId, mSegmentId)    
 SELECT    
  MST.SegmentStatusId AS mSegmentStatusId    
    ,MSG.SegmentId AS mSegmentId    
 FROM SLCMaster..SegmentStatus MST WITH (NOLOCK)    
 INNER JOIN SLCMaster..Segment MSG WITH (NOLOCK)    
  ON MST.SegmentId = MSG.SegmentId    
 LEFT JOIN ProjectSegmentStatus PSST WITH (NOLOCK)    
  ON PSST.ProjectId = @PProjectId    
   AND PSST.CustomerId = @PCustomerId    
   AND PSST.SectionId = @PSectionId    
   AND PSST.mSegmentStatusId IS NOT NULL    
   AND PSST.mSegmentStatusId > 0    
   AND PSST.mSegmentStatusId = MST.SegmentStatusId    
   AND ISNULL(PSST.IsDeleted,0) = 0  
 WHERE MST.SectionId = @mSectionId    
 AND ISNULL(MST.IsDeleted, 0) = 0    
 AND PSST.SegmentStatusId IS NULL    
END    
    
END  
  
--FETCH RS UPDATES          
INSERT INTO #RSUpdatesTable (RefStandardId, RefStdName)    
 SELECT    
  RS.RefStdId AS RefStandardId    
    ,RS.RefStdName AS RefStdName    
 FROM ProjectReferenceStandard ProjRefStd WITH (NOLOCK)    
 INNER JOIN SLCMaster..ReferenceStandardEdition Edn WITH (NOLOCK)    
  ON ProjRefStd.RefStandardId = Edn.RefStdId    
 INNER JOIN SLCMaster..ReferenceStandard RS WITH (NOLOCK)    
  ON RS.RefStdId = Edn.RefStdId    
 WHERE ProjRefStd.SectionId = @PSectionId    
 AND ProjRefStd.ProjectId = @PProjectId    
 AND ProjRefStd.CustomerId = @PCustomerId    
 AND ISNULL( ProjRefStd.IsDeleted,0) = 0    
 AND ProjRefStd.RefStdSource = 'M'    
 AND Edn.RefStdEditionId > ProjRefStd.RefStdEditionId    
 GROUP BY RS.RefStdId,RS.RefStdName;  
  
--FETCH User RS UPDATES      
INSERT INTO #URSUpdatesTable (RefStandardId, RefStdName)    
 SELECT    
  RS.RefStdId AS RefStandardId    
    ,RS.RefStdName AS RefStdName    
 FROM ProjectReferenceStandard ProjRefStd WITH (NOLOCK)    
 INNER JOIN ReferenceStandardEdition Edn WITH (NOLOCK)    
  ON ProjRefStd.RefStandardId = Edn.RefStdId    
 INNER JOIN ReferenceStandard RS WITH (NOLOCK)    
  ON RS.RefStdId = Edn.RefStdId
  AND     ProjRefStd.CustomerId = RS.CustomerId
 WHERE ProjRefStd.SectionId = @PSectionId    
 AND ProjRefStd.ProjectId = @PProjectId    
 AND ProjRefStd.CustomerId = @PCustomerId    
 AND ISNULL( ProjRefStd.IsDeleted,0) = 0    
 AND ProjRefStd.RefStdSource = 'U'    
 AND ISNULL( RS.IsDeleted,0) = 0    
 AND Edn.RefStdEditionId > ProjRefStd.RefStdEditionId    
 GROUP BY RS.RefStdId, RS.RefStdName;    
  
    
 -- CALCULATE FINAL COUNT          
 SET @UpdatesCount = (SELECT COUNT(1) FROM #SegmentUpdatesTable);  
 SET @UpdatesCount = @UpdatesCount + (SELECT COUNT(1) FROM #RSUpdatesTable);  
 SET @UpdatesCount = @UpdatesCount + (SELECT COUNT(1) FROM #URSUpdatesTable);  
 SET @UpdatesCount = @UpdatesCount + (SELECT COUNT(1) FROM #MutedParagraphUpdatesTable);  
  
 --SELECT FINAL RESULT          
 SELECT @PProjectId AS ProjectId, @PSectionId AS SectionId, @PCustomerId AS CustomerId, @UpdatesCount AS UpdatesCount;  
  
END    
  
-- EXEC [usp_GetUpdatesCount] 7715, 9173922, 105, 'FS'  