CREATE  PROCEDURE [dbo].[usp_ValidateSection]               
(                
@CustomerId INT,                
@SourceProjectId INT,                
@SourceTagString NVARCHAR(MAX)=NULL,                
@TargetProjectId INT,                
@mSectionIdString  NVARCHAR(MAX)=NULL,                
@SectionIdString  NVARCHAR(MAX)=NULL,                
@IncludeReferencedSections BIT = 1                
)                
AS                
BEGIN             
DECLARE @PCustomerId INT = @CustomerId;              
DECLARE @PSourceProjectId INT = @SourceProjectId;            
DECLARE @PSourceTagString NVARCHAR(MAX) = @SourceTagString;               
DECLARE @PTargetProjectId INT = @TargetProjectId;               
DECLARE @PmSectionIdString  NVARCHAR(MAX) = @mSectionIdString;              
DECLARE @PSectionIdString  NVARCHAR(MAX) = @SectionIdString;             
DECLARE @PIncludeReferencedSections BIT = @IncludeReferencedSections;         
                
DECLARE @SectionIdTbl TABLE(Id INT);        
DECLARE @mSectionIdTbl TABLE(Id INT);        
DECLARE @SourceTagTbl TABLE(Id nvarchar(MAX));        
DECLARE @InpSectionId INT = NULL;        
        
DROP TABLE IF EXISTS #tmp_SrcProjectSegmentStatus;        
DROP TABLE IF EXISTS #tmp_SrcProjectChoiceOption;        
DROP TABLE IF EXISTS #tmp_SrcProjectSection;        
        
INSERT INTO @SectionIdTbl        
 SELECT        
  id        
 FROM dbo.udf_GetSplittedIds(@PSectionIdString, ',')        
        
INSERT INTO @mSectionIdTbl        
 SELECT        
  id        
 FROM dbo.udf_GetSplittedIds(@PmSectionIdString, ',')        
        
INSERT INTO @SourceTagTbl (id)        
 SELECT        
  *        
 FROM dbo.fn_SplitString(@PSourceTagString, ',')        
 
 DROP TABLE IF EXISTS #userSection_Source;
        
SELECT  PS.SourceTag        
   ,PS.Author        
   ,PS.SectionCode        
into #userSection_Source FROM ProjectSection PS WITH (NOLOCK)        
INNER JOIN @SectionIdTbl SI        
 ON PS.SectionId = SI.id        
WHERE PS.ProjectId = @PSourceProjectId        
AND PS.CustomerId = @PCustomerId        
AND ISNULL(PS.IsDeleted,0)= 0        
AND PS.IsLastLevel = 1     
AND ISNULL(PS.mSectionId,0)=0    
    
SELECT        
 PS.SectionId        
   ,PS.ParentSectionId        
   ,PS.mSectionId        
   ,PS.ProjectId        
   ,PS.DivisionId        
   ,PS.DivisionCode        
   ,PS.[Description]    
   ,PS.LevelId        
   ,PS.IsLastLevel        
   ,PS.SourceTag        
   ,PS.Author        
   ,PS.SectionCode        
   ,PS.IsDeleted        
FROM ProjectSection PS WITH (NOLOCK)        
INNER JOIN @mSectionIdTbl SI        
 ON PS.mSectionId = SI.id        
WHERE PS.ProjectId = @PTargetProjectId        
AND PS.CustomerId = @PCustomerId        
AND ISNULL(PS.IsDeleted,0)= 0        
AND PS.IsLastLevel = 1        
  UNION      
 SELECT        
 PS.SectionId        
   ,PS.ParentSectionId        
   ,PS.mSectionId        
   ,PS.ProjectId        
   ,PS.DivisionId        
   ,PS.DivisionCode        
   ,PS.[Description]    
   ,PS.LevelId        
   ,PS.IsLastLevel        
   ,PS.SourceTag        
   ,PS.Author        
   ,PS.SectionCode        
   ,PS.IsDeleted        
FROM ProjectSection PS WITH (NOLOCK)        
INNER JOIN #userSection_Source SI        
 ON PS.SourceTag = SI.SourceTag    
 AND PS.Author = SI.Author    
WHERE PS.ProjectId = @PTargetProjectId        
AND PS.CustomerId = @PCustomerId        
AND ISNULL(PS.IsDeleted,0)= 0        
AND PS.IsLastLevel = 1        
    
DECLARE @ReferencedSection TABLE (        
 mSectionId INT        
   ,SectionId INT        
   ,ParentSectionId INT        
   ,ProjectId INT        
   ,DivisionId INT        
   ,DivisionCode NVARCHAR(MAX)        
   ,[Description] NVARCHAR(MAX)        
   ,LevelId INT        
   ,IsLastLevel BIT        
   ,SourceTag NVARCHAR(MAX)        
   ,Author NVARCHAR(MAX)        
   ,SectionCode INT        
   ,IsDeleted BIT        
   ,MainSectionId INT        
   ,IsProcessed BIT        
)        
    
--Fetch Source Segment Status Data of sequence 0 and user segments            
SELECT        
   PSST.SectionId        
   INTO #tmp_SrcProjectSegmentStatus        
FROM ProjectSegmentStatus PSST WITH (NOLOCK)        
WHERE PSST.ProjectId = @PSourceProjectId        
AND PSST.CustomerId = @PCustomerId        
AND PSST.ParentSegmentStatusId = 0        
AND PSST.SequenceNumber = 0        
AND PSST.IndentLevel = 0        
AND PSST.SegmentOrigin = 'U'        
AND ISNULL(PSST.IsDeleted, 0) = 0;        
        
--Fetch Source user choice options            
SELECT        
 PCHOP.ChoiceOptionId        
   ,PCHOP.SegmentChoiceId        
   ,PCHOP.SortOrder        
   ,PCHOP.ChoiceOptionSource        
   ,PCHOP.OptionJson        
   ,PCHOP.ProjectId        
   ,PCHOP.SectionId        
   ,PCHOP.CustomerId        
   ,PCHOP.ChoiceOptionCode        
   ,PCHOP.CreatedBy        
   ,PCHOP.CreateDate        
   ,PCHOP.ModifiedBy        
   ,PCHOP.ModifiedDate        
   ,PCHOP.IsDeleted INTO #tmp_SrcProjectChoiceOption        
FROM ProjectChoiceOption PCHOP WITH (NOLOCK)        
INNER JOIN ProjectSegmentChoice PSC WITH (NOLOCK)        
 ON PSC.SegmentChoiceId = PCHOP.SegmentChoiceId        
WHERE ISNULL(PSC.IsDeleted, 0) = 0        
AND PCHOP.ProjectId = @PSourceProjectId        
AND PCHOP.CustomerId = @PCustomerId        
AND ISNULL(PCHOP.IsDeleted, 0) = 0        
AND PCHOP.OptionJson != '[]';        
        
--Fetch Source user sections            
SELECT        
 PS.mSectionId        
    ,PS.SectionId        
    ,PS.ParentSectionId        
    ,PS.ProjectId        
    ,PS.DivisionId        
    ,PS.DivisionCode        
    ,PS.[Description]        
    ,PS.LevelId        
    ,PS.IsLastLevel        
    ,PS.SourceTag        
    ,PS.Author        
    ,PS.SectionCode        
    ,PS.IsDeleted        
    ,PS.CustomerId INTO #tmp_SrcProjectSection        
FROM ProjectSection PS WITH (NOLOCK)        
WHERE PS.ProjectId = @PSourceProjectId        
AND PS.CustomerId = @PCustomerId        
AND PS.IsLastLevel = 1        
AND PS.IsDeleted = 0        
AND PS.mSectionId IS NULL;        
        
INSERT INTO @ReferencedSection        
 SELECT        
  PS.mSectionId        
    ,PS.SectionId        
    ,PS.ParentSectionId        
    ,PS.ProjectId        
    ,PS.DivisionId        
    ,PS.DivisionCode        
    ,PS.[Description]        
    ,PS.LevelId        
    ,PS.IsLastLevel        
    ,PS.SourceTag        
    ,PS.Author        
    ,PS.SectionCode        
    ,PS.IsDeleted        
    ,X.MainSectionId AS MainSectionId        
    ,0 AS IsProcessed        
 FROM (SELECT        
   PST.id AS MainSectionId        
     ,JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.Id') AS ReferSectionId        
     ,JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.Value') AS SectionName        
  FROM #tmp_SrcProjectChoiceOption CH WITH (NOLOCK)        
  INNER JOIN @SectionIdTbl PST        
   ON CH.SectionId = PST.id        
  WHERE CH.ProjectId = @PSourceProjectId        
  AND CH.CustomerId = @PCustomerId        
  AND JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.OptionTypeName') = 'SectionID'        
  AND JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.Id') > 0) AS X        
 INNER JOIN #tmp_SrcProjectSection PS WITH (NOLOCK)        
  ON X.ReferSectionId = PS.SectionCode        
 INNER JOIN #tmp_SrcProjectSegmentStatus PSS WITH (NOLOCK)        
  ON PS.SectionId = PSS.SectionId        
 WHERE PS.ProjectId = @PSourceProjectId        
 AND PS.CustomerId = @PCustomerId        
--OPTION (RECOMPILE)            
        
SET @InpSectionId = ISNULL((SELECT TOP 1        
  SectionId        
 FROM @ReferencedSection        
 WHERE IsProcessed IS NULL        
 OR IsProcessed = 0        
 )        
, 0);        
            
                
WHILE(@InpSectionId > 0)                
BEGIN        
UPDATE @ReferencedSection        
SET IsProcessed = 1        
WHERE SectionId = @InpSectionId;        
        
INSERT INTO @ReferencedSection        
 SELECT        
  PS.mSectionId        
    ,PS.SectionId        
    ,PS.ParentSectionId        
    ,PS.ProjectId        
    ,PS.DivisionId        
    ,PS.DivisionCode        
    ,PS.[Description]        
    ,PS.LevelId        
    ,PS.IsLastLevel        
    ,PS.SourceTag        
    ,PS.Author        
    ,PS.SectionCode        
    ,PS.IsDeleted        
    ,X.MainSectionId AS MainSectionId        
    ,0 AS IsProcessed        
 FROM (SELECT        
   @InpSectionId AS MainSectionId        
     ,JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.Id') AS ReferSectionId           ,JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.Value') AS SectionName        
  FROM #tmp_SrcProjectChoiceOption CH WITH (NOLOCK)        
  WHERE CH.ProjectId = @PSourceProjectId        
  AND CH.CustomerId = @PCustomerId        
  AND CH.SectionId = @InpSectionId        
  AND JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.OptionTypeName') = 'SectionID'        
  AND JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.Id') > 0) AS X        
 INNER JOIN #tmp_SrcProjectSection PS WITH (NOLOCK)        
  ON X.ReferSectionId = PS.SectionCode        
 INNER JOIN #tmp_SrcProjectSegmentStatus PSS WITH (NOLOCK)        
  ON PS.SectionId = PSS.SectionId        
 LEFT JOIN @ReferencedSection RSINPTBL        
  ON PS.SectionId = RSINPTBL.SectionId        
 WHERE PS.ProjectId = @PSourceProjectId        
 AND PS.CustomerId = @PCustomerId        
 AND RSINPTBL.SectionId IS NULL        
--OPTION (RECOMPILE)            
        
SET @InpSectionId = ISNULL((SELECT TOP 1        
  SectionId        
 FROM @ReferencedSection        
 WHERE IsProcessed IS NULL        
 OR IsProcessed = 0)        
, 0);        
            
END        
 
 drop table if EXISTS #ReferencedSectionList;       
SELECT        
 DISTINCT         
 RS.mSectionId         
   ,RS.SectionId        
   ,RS.ParentSectionId        
   ,RS.ProjectId        
   ,RS.DivisionId         
   ,RS.DivisionCode        
   ,RS.[Description]        
   ,RS.LevelId        
   ,RS.IsLastLevel        
   ,RS.SourceTag        
   ,RS.Author        
   ,RS.SectionCode        
   ,RS.IsDeleted        
   ,0 AS MainSectionId        
   ,RS.IsProcessed  
   INTO #ReferencedSectionList
FROM @ReferencedSection RS        
LEFT JOIN ProjectSection PS WITH (NOLOCK)        
 ON RS.SourceTag = PS.SourceTag AND RS.Author=PS.Author AND PS.IsDeleted=0 AND PS.IsLastLevel=1    
  AND  PS.ProjectId = @PTargetProjectId        
Where PS.SectionId IS NULL ;     

SELECT 
@PSectionIdString = CONCAT(@PSectionIdString,',',SectionId) 
FROM #ReferencedSectionList
 
 SELECT * FROM #ReferencedSectionList;

EXEC usp_GetImportingSectionsStatus @PCustomerId,@PSourceProjectId,@PTargetProjectId,@PSectionIdString  
END 