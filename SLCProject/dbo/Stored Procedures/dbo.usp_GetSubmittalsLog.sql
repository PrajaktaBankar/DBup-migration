    
CREATE PROCEDURE [dbo].[usp_GetSubmittalsLog]                
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
DECLARE @SubmittalsWord NVARCHAR(1024) = 'submittals';              
DECLARE @ProjectName NVARCHAR(500)='';              
--DECLARE @ProjectSourceTagFormate NVARCHAR(MAX)='';              
Declare @SourceTagFormat  VARCHAR(10);              
Declare @UnitOfMeasureValueTypeId int;              
DECLARE @RequirementsTagTbl TABLE (               
TagType NVARCHAR(5),               
RequirementTagId INT               
);              
              
DROP TABLE IF EXISTS #SegmentsTable;              
CREATE TABLE #SegmentsTable (              
 SourceTag VARCHAR(20)              
   ,SectionId INT              
   ,Author NVARCHAR(500)              
   ,Description NVARCHAR(MAX)           
   ,DivisionCode varchar(10)          
   ,ParentSectionId  INT             
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
   ,SourceTagFormat VARCHAR(10)              
   ,UnitOfMeasureValueTypeId INT              
   ,mSegmentRequirementTagId INT           
   ,isHidden BIT NULL      
   ,SectionSortOrder INT      
);              
              
--CREATE TABLE #ProjectInfo (              
-- ProjectId INT              
--   ,SourceTagFormat NVARCHAR(MAX)              
--   ,UnitOfMeasureValueTypeId INT              
--)              
              
--SET VARIABLES TO DEFAULT VALUE               
              
DROP TABLE IF EXISTS #Tags;              
CREATE TABLE #Tags (              
 TagType NVARCHAR(2)              
)              
              
INSERT INTO #Tags              
 SELECT              
  *              
 FROM STRING_SPLIT('CT,DC,FR,II,IQ,LR,XM,MQ,MO,OM,PD,PE,PR,QS,SA,SD,TR,WE,WT,WS,S1,S2,S3,S4,S5,S6,S7,NS,NP', ',')              
              
INSERT INTO @RequirementsTagTbl (RequirementTagId, TagType)              
 SELECT              
  RequirementTagId              
    ,rt.TagType              
 FROM [dbo].[LuProjectRequirementTag] AS rt WITH (NOLOCK)              
 INNER JOIN #Tags AS t              
  ON t.TagType = rt.TagType              
              
--WHERE TagType IN ('CT', 'DC', 'FR', 'II', 'IQ', 'LR', 'XM', 'MQ', 'MO', 'OM', 'PD', 'PE', 'PR', 'QS',              
--'SA', 'SD', 'TR', 'WE', 'WT', 'WS', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'NS', 'NP');              
--SET @ProjectName = (SELECT              
--  [Name]              
-- FROM Project WITH (NOLOCK)              
-- WHERE ProjectId = @PProjectId);              
              
--INSERT INTO #ProjectInfo              
SELECT              
 @ProjectName = pt.Name              
   ,@SourceTagFormat = SourceTagFormat              
   ,@UnitOfMeasureValueTypeId = UnitOfMeasureValueTypeId              
FROM ProjectSummary ps WITH (NOLOCK)              
INNER JOIN Project pt WITH (NOLOCK)              
 ON ps.ProjectId = pt.ProjectId              
WHERE ps.ProjectId = @PProjectId;              
              
DROP TABLE IF EXISTS #tmp_ProjectSegmentStatusView;              
SELECT              
 * INTO #tmp_ProjectSegmentStatusView              
FROM ProjectSegmentStatusView PSSTV  WITH (NOLOCK)              
WHERE PSSTV.ProjectId = @PProjectId             
AND PSSTV.CustomerId = @PCustomerID              
AND PSSTV.IsSegmentStatusActive = 1          
AND ISNULL(PSSTV.IsDeleted,0) = 0;               
              
DROP TABLE IF EXISTS #tmp_ProjectSegmentRequirementTag;         
SELECT              
 PSRT.* INTO #tmp_ProjectSegmentRequirementTag              
FROM ProjectSegmentRequirementTag PSRT  WITH (NOLOCK)              
WHERE PSRT.ProjectId = @PProjectId              
AND PSRT.CustomerId = @PCustomerID;              
              
--1. FIND PARAGRAPHS WHICH ARE TAGGED BY GIVEN REQUIREMENTS TAGS              
WITH TaggedSegmentsCte              
AS              
(SELECT              
  PSSTV.SegmentStatusId              
    ,PSSTV.ParentSegmentStatusId              
 FROM #tmp_ProjectSegmentStatusView PSSTV WITH (NOLOCK)             
 INNER JOIN #tmp_ProjectSegmentRequirementTag PSRT WITH (NOLOCK)              
  ON PSSTV.SegmentStatusId = PSRT.SegmentStatusId              
 INNER JOIN @RequirementsTagTbl TagTbl              
  ON PSRT.RequirementTagId = TagTbl.RequirementTagId              
 WHERE PSSTV.ProjectId = @PProjectId              
 AND PSSTV.IsParentSegmentStatusActive = 1              
 AND PSSTV.SegmentStatusTypeId < 6              
 UNION ALL              
 SELECT              
  CPSSTV.SegmentStatusId              
    ,CPSSTV.ParentSegmentStatusId              
 FROM #tmp_ProjectSegmentStatusView CPSSTV WITH (NOLOCK)              
 INNER JOIN TaggedSegmentsCte TSC              
  ON CPSSTV.ParentSegmentStatusId = TSC.SegmentStatusId              
 WHERE CPSSTV.IsParentSegmentStatusActive = 1              
 AND CPSSTV.SegmentStatusTypeId < 6)              
              
INSERT INTO #SegmentsTable (SourceTag, SectionId, Author, [Description],DivisionCode,ParentSectionId, SegmentStatusId, mSegmentStatusId, SegmentId, mSegmentId              
, SegmentSource, SegmentOrigin, SegmentDescription, RequirementTagId, TagType, SortOrder, SequenceNumber, IsSegmentStatusActive, ProjectName              
, ParentSegmentStatusId, IndentLevel, IsDeleted, SourceTagFormat, UnitOfMeasureValueTypeId, mSegmentRequirementTagId,isHidden,SectionSortOrder)              
 SELECT DISTINCT              
  PS.SourceTag              
    ,PS.SectionId              
    ,PS.Author              
    ,PS.[Description]           
    ,PS.DivisionCode          
    ,PS.ParentSectionId          
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
    ,@SourceTagFormat              
  AS SourceTagFormat              
    ,@UnitOfMeasureValueTypeId              
  AS UnitOfMeasureValueTypeId              
    ,PSRT.mSegmentRequirementTagId             
    ,PS.isHidden      
    ,PS.SortOrder AS SectionSortOrder               
 FROM #tmp_ProjectSegmentStatusView PSSTV WITH (NOLOCK)              
 INNER JOIN TaggedSegmentsCte TSC              
  ON PSSTV.SegmentStatusId = TSC.SegmentStatusId              
 INNER JOIN ProjectSection PS WITH (NOLOCK)              
  ON PSSTV.SectionId = PS.SectionId              
  AND ISNULL(Ps.IsDeleted,0)=0            
 LEFT JOIN #tmp_ProjectSegmentRequirementTag PSRT WITH (NOLOCK)              
  ON PSSTV.SegmentStatusId = PSRT.SegmentStatusId              
 LEFT JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)              
  ON PSRT.RequirementTagId = LPRT.RequirementTagId;              
              
--2. FIND SUBMITTALS ARTICLE PARAGRAPHS               
WITH SubmittlesChildCte              
AS            (SELECT              
  CPSSTV.SegmentStatusId              
    ,CPSSTV.ParentSegmentStatusId              
 FROM #tmp_ProjectSegmentStatusView PSSTV              
 INNER JOIN #tmp_ProjectSegmentStatusView CPSSTV WITH (NOLOCK)              
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
 FROM #tmp_ProjectSegmentStatusView CPSSTV WITH (NOLOCK)              
 INNER JOIN SubmittlesChildCte SCC              
  ON CPSSTV.ParentSegmentStatusId = SCC.SegmentStatusId              
 WHERE CPSSTV.IsParentSegmentStatusActive = 1              
 AND CPSSTV.SegmentStatusTypeId < 6)              
              
INSERT INTO #SegmentsTable (SourceTag, Author, [Description],DivisionCode,ParentSectionId, SegmentStatusId, mSegmentStatusId, SegmentId, mSegmentId              
, SegmentSource, SegmentOrigin, SegmentDescription, RequirementTagId, TagType, SortOrder, SequenceNumber, IsSegmentStatusActive,             
ParentSegmentStatusId, IndentLevel, IsDeleted, SourceTagFormat, UnitOfMeasureValueTypeId, mSegmentRequirementTagId,isHidden,SectionSortOrder)              
 SELECT DISTINCT              
  PS.SourceTag              
    ,PS.Author              
    ,PS.[Description]            
    ,PS.DivisionCode          
 ,PS.ParentSectionId            
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
    ,@SourceTagFormat              
  AS SourceTagFormat              
    ,@UnitOfMeasureValueTypeId              
  AS UnitOfMeasureValueTypeId              
    ,PSRT.mSegmentRequirementTagId            
    ,PS.isHidden             
    ,PS.SortOrder AS SectionSortOrder      
 FROM #tmp_ProjectSegmentStatusView PSSTV WITH (NOLOCK)              
 INNER JOIN SubmittlesChildCte SCC WITH (NOLOCK)              
  ON PSSTV.SegmentStatusId = SCC.SegmentStatusId              
 INNER JOIN ProjectSection PS WITH (NOLOCK)              
  ON PSSTV.SectionId = PS.SectionId              
 LEFT JOIN #tmp_ProjectSegmentRequirementTag PSRT WITH (NOLOCK)              
  ON PSSTV.SegmentStatusId = PSRT.SegmentStatusId              
 LEFT JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)              
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
              
--DELETE FROM #SegmentsTable              
--WHERE TagType IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP')         
              
--new changes--              
--Start change--              
DELETE FROM #SegmentsTable              
WHERE ParentSegmentStatusId NOT IN (SELECT              
   SegmentStatusId              
  FROM #SegmentsTable)              
 AND TagType IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP')              
              
DELETE FROM #SegmentsTable              
WHERE SequenceNumber IN (SELECT              
   SequenceNumber              
  FROM #SegmentsTable              
  GROUP BY SequenceNumber              
  HAVING COUNT(1) > 1)              
 AND TagType IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP')              
 AND mSegmentRequirementTagId IS NOT NULL              
              
DELETE FROM #SegmentsTable              
WHERE SegmentStatusId IN (SELECT              
   SegmentStatusId              
  FROM #SegmentsTable              
  WHERE TagType NOT IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP'))              
 AND TagType IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP');              
              
UPDATE #SegmentsTable              
SET TagType = ''              
WHERE TagType IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP')              
--End Change--              
              
DELETE FROM #SegmentsTable              
WHERE @PIsIncludeUntagged = 0              
 AND TagType = '';              
              
--SELECT FINAL DATA              
IF (NOT EXISTS (SELECT              
  1              
 FROM #SegmentsTable)              
)              
BEGIN              
INSERT INTO #SegmentsTable (ProjectName)              
 VALUES (@ProjectName)              
END              
              
--ELSE               
              
--BEGIN               
DROP TABLE IF EXISTS #ResultSet;          
SELECT              
ISNULL(dbo.[fnGetSegmentDescriptionTextForRSAndGT](@PProjectId, @PCustomerID, STbl.SegmentDescription) ,'') AS SegmentText          
    ,STbl.SectionId               
    ,STbl.DivisionCode          
 ,STbl.ParentSectionId          
   ,STbl.Description as SectionName, ISNULL(STbl.SegmentStatusId,0) as SegmentStatusId,STbl.SequenceNumber, STbl.SourceTag            
   ,STbl.TagType as RequirementTag,STbl.ProjectName,STbl.Author,STbl.SourceTagFormat as SourceTagFormate,isnull(STbl.UnitOfMeasureValueTypeId,0) as UnitOfMeasureValueTypeId      
   ,Stbl.SortOrder, Stbl.SectionSortOrder ,0 AS SubFolderSortOrder, 0 AS FolderSortOrder, 0 AS FolderSectionId            
 INTO #ResultSet            
FROM #SegmentsTable STbl              
WHERE STbl.ProjectName IS NOT NULL AND ISNULL(STbl.IsHidden,0) = 0           
ORDER BY STbl.SourceTag ASC, STbl.SequenceNumber ASC, STbl.SortOrder ASC;              
          
 ---- get folders            
 SELECT SectionId,ParentSectionId,IsHidden             
 INTO #ProjectSectionTemp            
 FROM ProjectSection PS WITH (NOLOCK)            
 WHERE PS.ProjectId = @PProjectId AND PS.CustomerId = @PCustomerID            
 AND ISNULL(PS.IsDeleted,0) =0 AND ISNULL(PS.IsLastLevel,0) = 0           
          
          
          
  --delete sections which parent folders are hidden            
DELETE FROM #ResultSet WHERE  SectionId IN(               
 SELECT PS1.SectionId             
 FROM #ResultSet PS1 WITH (NOLOCK)            
 INNER JOIN #ProjectSectionTemp PS2 WITH (NOLOCK)            
  ON PS2.SectionId = PS1.ParentSectionId            
  INNER JOIN #ProjectSectionTemp PS3 WITH (NOLOCK)            
  ON PS3.SectionId = PS2.ParentSectionId            
  WHERE PS2.IsHidden = 1 OR PS3.IsHidden = 1            
)          
          
  --Update Subfolder SortOrder            
 UPDATE section SET section.FolderSectionId = subF.ParentSectionId , section.SubFolderSortOrder = ISNULL(subF.SortOrder,0) FROM #ResultSet section INNER JOIN ProjectSection subF WITH(NOLOCK)          
 ON section.ParentSectionId = subF.SectionId WHERE subF.ProjectId = @PProjectId AND subF.CustomerId = @PCustomerId;           
          
 --Update Folder SortOrder            
 UPDATE section SET section.FolderSortOrder = ISNULL(folder.SortOrder,0) FROM #ResultSet section INNER JOIN ProjectSection folder WITH(NOLOCK)          
 ON section.FolderSectionId = folder.SectionId WHERE folder.ProjectId = @PProjectId AND folder.CustomerId = @PCustomerId;           
          
SELECT * FROM #ResultSet ORDER BY FolderSortOrder, SubFolderSortOrder, SectionSortOrder;      
          
          
--END               
              
SELECT              
 SCView.SegmentStatusId, SCView.SegmentChoiceCode, SCView.SectionId,SCView.ChoiceTypeId            
 ,SCView.ChoiceOptionCode, SCView.SortOrder, SCView.ChoiceOptionSource            
 ,SCView.OptionJson INTO #DapperChoiceTbl            
FROM  SegmentChoiceView SCView WITH (NOLOCK)              
WHERE SCView.IsSelected = 1              
AND SCView.SegmentStatusId  IN (SELECT DISTINCT              
  SegmentStatusId              
 FROM #SegmentsTable)              
            
 SELECT             
 ISNULL(SegmentStatusId,0) as SegmentStatusId            
 ,ISNULL(SegmentChoiceCode,0)as SegmentChoiceCode            
 ,ISNULL(SectionId,0)as SectionId            
 ,ISNULL(ChoiceTypeId,0) as ChoiceTypeId            
 FROM #DapperChoiceTbl            
              
 SELECT             
 ISNULL(SegmentChoiceCode,0) as SegmentChoiceCode            
 ,ISNULL(ChoiceOptionCode,0) as ChoiceOptionCode            
 ,SortOrder            
 ,COALESCE(ChoiceOptionSource,'') as ChoiceOptionSource            
 ,ISNULL(SectionId,0) as SectionId            
 ,OptionJson            
 FROM #DapperChoiceTbl            
            
SELECT DISTINCT              
 (PS.SectionId)              
   ,COALESCE(PS.SourceTag,'')  as SourceTag             
   ,COALESCE(PS.Description ,'')as Description            
   ,ISNULL(PS.SectionCode,0)  as SectionCode            
FROM ProjectSection PS WITH (NOLOCK)              
WHERE PS.ProjectId = @PProjectId              
AND PS.CustomerId = @PCustomerID              
              
END 