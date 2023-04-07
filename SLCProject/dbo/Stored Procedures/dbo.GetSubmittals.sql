CREATE PROCEDURE [dbo].[GetSubmittals]  
 @ProjectId INT ,      
 @CustomerID INT,      
 @IsIncludeUntagged BIT      
AS      
BEGIN      
 DECLARE @PProjectId INT = @ProjectId;  
 DECLARE @PCustomerID INT = @CustomerID;  
 DECLARE @PIsIncludeUntagged BIT = @IsIncludeUntagged;  
-- SET NOCOUNT ON added to prevent extra result sets from      
-- interfering with SELECT statements.      
SET NOCOUNT ON;      
      
-- Insert statements for procedure here      
DECLARE @SubmittalsWord NVARCHAR(MAX) = 'submittals';      
DECLARE @ProjectName NVARCHAR(500)='';      
DECLARE @ProjectSourceTagFormate NVARCHAR(MAX)='';      
DECLARE @RequirementsTagTbl TABLE (      
TagType NVARCHAR(MAX),      
RequirementTagId INT      
);      
DROP TABLE IF EXISTS #SegmentsTable;      
CREATE TABLE #SegmentsTable (      
 SourceTag NVARCHAR(10)      
   ,SectionId INT      
   ,Author NVARCHAR(500)      
   ,Description NVARCHAR(MAX)      
   ,SegmentStatusId BIGINT      
   ,mSegmentStatusId INT      
   ,SegmentId BIGINT      
   ,mSegmentId INT      
   ,SegmentSource CHAR(1)      
   ,SegmentOrigin CHAR(1)      
   ,SegmentDescription NVARCHAR(MAX)      
   ,RequirementTagId INT      
   ,TagType NVARCHAR(5)      
   ,SortOrder INT      
   ,SequenceNumber DECIMAL(18, 4)      
   ,IsSegmentStatusActive INT      
   ,ProjectName NVARCHAR(500)      
   ,ParentSegmentStatusId BIGINT      
   ,IndentLevel INT      
   ,IsDeleted BIT NULL      
   ,SourceTagFormat NVARCHAR(MAX)      
   ,UnitOfMeasureValueTypeId INT     
);      
CREATE TABLE #SectionListTable (      
 SourceTag NVARCHAR(MAX)      
   ,Description NVARCHAR(MAX)      
   ,SectionId INT      
);      
CREATE TABLE #ProjectInfo    
(    
ProjectId INT ,    
SourceTagFormat NVARCHAR(MAX),    
UnitOfMeasureValueTypeId INT    
)    
--SET VARIABLES TO DEFAULT VALUE      
INSERT INTO @RequirementsTagTbl (RequirementTagId, TagType)      
 SELECT      
  RequirementTagId      
    ,TagType      
 FROM LuProjectRequirementTag WITH (NOLOCK)   
 WHERE TagType IN ('CT', 'DC', 'FR', 'II', 'IQ', 'LR', 'XM', 'MQ', 'MO', 'OM', 'PD', 'PE', 'PR', 'QS',      
 'SA', 'SD', 'TR', 'WE', 'WT', 'WS', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'NS', 'NP');      
SET @ProjectName = (SELECT      
  [Name]      
 FROM Project      
 WHERE ProjectId = @PProjectId);      
INSERT INTO #ProjectInfo     
SELECT      
ProjectId,    
  SourceTagFormat  ,    
  UnitOfMeasureValueTypeId    
      
 FROM ProjectSummary  WITH (NOLOCK)
 WHERE ProjectId = @PProjectId;      
 --SELECT * FROM #ProjectInfo;    
--1. FIND PARAGRAPHS WHICH ARE TAGGED BY GIVEN REQUIREMENTS TAGS      
WITH TaggedSegmentsCte      
AS      
(SELECT      
  PSSTV.SegmentStatusId      
    ,PSSTV.ParentSegmentStatusId      
 FROM ProjectSegmentStatusView PSSTV    with (nolock)  
 INNER JOIN ProjectSegmentRequirementTag PSRT    with (nolock)   
  ON PSSTV.SegmentStatusId = PSRT.SegmentStatusId      
 INNER JOIN @RequirementsTagTbl TagTbl      
  ON PSRT.RequirementTagId = TagTbl.RequirementTagId      
 WHERE PSSTV.ProjectId = @PProjectId      
 AND PSSTV.IsSegmentStatusActive = 1      
 UNION ALL      
 SELECT      
  CPSSTV.SegmentStatusId      
    ,CPSSTV.ParentSegmentStatusId      
 FROM ProjectSegmentStatusView CPSSTV   with (nolock)    
 INNER JOIN TaggedSegmentsCte TSC     
  ON CPSSTV.ParentSegmentStatusId = TSC.SegmentStatusId      
 WHERE CPSSTV.IsSegmentStatusActive = 1)      
      
      
      
INSERT INTO #SegmentsTable (SourceTag, SectionId, Author, [Description], SegmentStatusId, mSegmentStatusId, SegmentId, mSegmentId      
, SegmentSource, SegmentOrigin, SegmentDescription, RequirementTagId, TagType, SortOrder, SequenceNumber, IsSegmentStatusActive, ProjectName      
, ParentSegmentStatusId, IndentLevel, IsDeleted, SourceTagFormat,UnitOfMeasureValueTypeId)      
 SELECT DISTINCT      
  PS.SourceTag      
    ,PS.SectionId      
    ,PS.Author      
    ,PS.[Description]      
    ,PSSTV.SegmentStatusId      
    ,PSSTV.mSegmentStatusId      
    ,PSSTV.SegmentId      
    ,PSSTV.mSegmentId      
    ,PSSTV.SegmentSource      
    ,PSSTV.SegmentOrigin      
    ,PSSTV.SegmentDescription      
    ,ISNULL(PSRT.RequirementTagId, 0) AS RequirementTagId      
    ,ISNULL(LPRT.TagType, '') AS TagType      
    ,ISNULL(LPRT.SortOrder, 0) AS SortOrder      
    ,PSSTV.SequenceNumber      
    ,PSSTV.IsSegmentStatusActive      
    ,@ProjectName      
    ,PSSTV.ParentSegmentStatusId      
    ,PSSTV.IndentLevel      
    ,CASE      
   WHEN ISNULL(LPRT.TagType, '') = 'NS' OR      
    ISNULL(LPRT.TagType, '') = 'NP' THEN 1      
   ELSE 0      
  END AS IsDeleted      
    ,(Select SourceTagFormat from #ProjectInfo) AS SourceTagFormat    
 ,(Select UnitOfMeasureValueTypeId from #ProjectInfo)  AS UnitOfMeasureValueTypeId    
      
 FROM ProjectSegmentStatusView PSSTV     with (nolock)  
 INNER JOIN TaggedSegmentsCte TSC     with (nolock)  
  ON PSSTV.SegmentStatusId = TSC.SegmentStatusId      
 INNER JOIN ProjectSection PS    with (nolock)   
  ON PSSTV.SectionId = PS.SectionId      
 LEFT JOIN ProjectSegmentRequirementTag PSRT       WITH (NOLOCK)
  ON PSSTV.SegmentStatusId = PSRT.SegmentStatusId      
 LEFT JOIN LuProjectRequirementTag LPRT    with (nolock)   
  ON PSRT.RequirementTagId = LPRT.RequirementTagId;    
--2. FIND SUBMITTALS ARTICLE PARAGRAPHS      
WITH SubmittlesChildCte      
AS      
(SELECT      
  CPSSTV.SegmentStatusId      
    ,CPSSTV.ParentSegmentStatusId      
 FROM ProjectSegmentStatusView PSSTV     with (nolock)  
 INNER JOIN ProjectSegmentStatusView CPSSTV     with (nolock)  
  ON PSSTV.SegmentStatusId = CPSSTV.ParentSegmentStatusId      
 WHERE PSSTV.ProjectId = @PProjectId      
 AND PSSTV.CustomerId = @PCustomerID      
 AND PSSTV.SegmentDescription LIKE '%' + @SubmittalsWord      
 AND PSSTV.IndentLevel = 2      
 AND CPSSTV.IsSegmentStatusActive = 1      
 UNION ALL      
 SELECT      
  CPSSTV.SegmentStatusId      
    ,CPSSTV.ParentSegmentStatusId      
 FROM ProjectSegmentStatusView CPSSTV   with (nolock)  
 INNER JOIN SubmittlesChildCte SCC 
  ON CPSSTV.ParentSegmentStatusId = SCC.SegmentStatusId      
 WHERE CPSSTV.IsSegmentStatusActive = 1)      
      
INSERT INTO #SegmentsTable (SourceTag, Author, [Description], SegmentStatusId, mSegmentStatusId, SegmentId, mSegmentId      
, SegmentSource, SegmentOrigin, SegmentDescription, RequirementTagId, TagType, SortOrder, SequenceNumber, IsSegmentStatusActive, ParentSegmentStatusId, IndentLevel, IsDeleted, SourceTagFormat,UnitOfMeasureValueTypeId)      
 SELECT DISTINCT      
  PS.SourceTag      
    ,PS.Author      
    ,PS.[Description]      
    ,PSSTV.SegmentStatusId      
    ,PSSTV.mSegmentStatusId      
    ,PSSTV.SegmentId      
    ,PSSTV.mSegmentId      
    ,PSSTV.SegmentSource      
    ,PSSTV.SegmentOrigin      
    ,PSSTV.SegmentDescription      
    ,ISNULL(PSRT.RequirementTagId, 0) AS RequirementTagId      
    ,ISNULL(LPRT.TagType, '') AS TagType      
    ,ISNULL(LPRT.SortOrder, 0) AS SortOrder      
    ,PSSTV.SequenceNumber      
    ,PSSTV.IsSegmentStatusActive      
    ,PSSTV.ParentSegmentStatusId      
    ,PSSTV.IndentLevel      
    ,CASE      
   WHEN ISNULL(LPRT.TagType, '') = 'NS' OR      
    ISNULL(LPRT.TagType, '') = 'NP' THEN 1      
   ELSE 0      
  END AS IsDeleted      
    ,(Select SourceTagFormat from #ProjectInfo) AS SourceTagFormat    
 ,(Select UnitOfMeasureValueTypeId from #ProjectInfo)  AS UnitOfMeasureValueTypeId    
 FROM ProjectSegmentStatusView PSSTV  WITH (NOLOCK)    
 INNER JOIN SubmittlesChildCte SCC WITH (NOLOCK)     
  ON PSSTV.SegmentStatusId = SCC.SegmentStatusId      
 INNER JOIN ProjectSection PS     with (nolock)  
  ON PSSTV.SectionId = PS.SectionId      
 LEFT JOIN ProjectSegmentRequirementTag PSRT     with (nolock)  
  ON PSSTV.SegmentStatusId = PSRT.SegmentStatusId      
 LEFT JOIN LuProjectRequirementTag LPRT     with (nolock)  
  ON PSRT.RequirementTagId = LPRT.RequirementTagId      
      
      
;      
WITH cte      
AS      
(SELECT      
  s.SegmentStatusId      
    ,s.ParentSegmentStatusId      
    ,s.isDeleted      
 FROM #SegmentsTable AS s      
 WHERE s.isDeleted = 1      
 UNION ALL      
 SELECT      
  s.SegmentStatusId      
    ,s.ParentSegmentStatusId      
    ,CONVERT(BIT, 1) AS isDeleted      
 FROM #SegmentsTable AS s      
 INNER JOIN cte AS c      
  ON s.ParentSegmentStatusId = c.SegmentStatusId)      
DELETE s      
 FROM cte      
 INNER JOIN #SegmentsTable AS s      
  ON cte.SegmentStatusId = s.SegmentStatusId;      
      
      
      
DELETE FROM #SegmentsTable      
WHERE TagType IN('RS','RT','RE','ST','PI','ML','MT','PL')    
      
DELETE FROM #SegmentsTable      
WHERE @PIsIncludeUntagged = 0      
 AND TagType = '';      
      
--SELECT FINAL DATA      
if (not exists (select 1 from #SegmentsTable))      
BEGIN      
INSERT INTO #SegmentsTable(ProjectName)      
VALUES(@ProjectName)      
END      
--ELSE      
--BEGIN      
SELECT      
  dbo.[fnGetSegmentDescriptionTextForRSAndGT](@PProjectId,@PCustomerID, STbl.SegmentDescription) AS SegmentDescriptionNew      
   ,*      
FROM #SegmentsTable STbl      
WHERE STbl.ProjectName IS NOT NULL      
ORDER BY STbl.SourceTag ASC, STbl.SequenceNumber ASC, STbl.SortOrder ASC;      
--END      
      
SELECT      
 SCView.*      
FROM (SELECT DISTINCT      
  SegmentStatusId      
 FROM #SegmentsTable) AS PSST      
INNER JOIN SegmentChoiceView SCView WITH (NOLOCK)     
 ON PSST.SegmentStatusId = SCView.SegmentStatusId      
WHERE SCView.IsSelected = 1      
      
      
      
SELECT DISTINCT      
 (PS.SectionId)      
   ,PS.SourceTag      
   ,PS.Description      
   ,PS.SectionCode      
FROM ProjectSection PS   with (nolock)    
 WHERE PS.ProjectId=@PProjectId AND PS.CustomerId=@PCustomerID      
END
GO


