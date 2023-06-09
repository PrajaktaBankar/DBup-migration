CREATE PROCEDURE [dbo].[usp_getRecommandedSections]    
 @ProjectId int ,    
 @vimId int ,    
 @parentVimId int,  
 @MaterialId1 NVARCHAR(MAX)='',  
 @MaterialId2 NVARCHAR(MAX)=''  
  
AS    
BEGIN
  
 DECLARE @PProjectId int = @ProjectId;
 DECLARE @PvimId int = @vimId;
 DECLARE @PparentVimId int = @parentVimId;
 DECLARE @PMaterialId1 NVARCHAR(MAX) = @MaterialId1;
 DECLARE @PMaterialId2 NVARCHAR(MAX) = @MaterialId2;
  
    DECLARE @true bit=1
  
    DECLARE @false bit=0
  
 declare @MaterialIdTbl table(splitdata nvarchar(10))
INSERT INTO @MaterialIdTbl
	SELECT DISTINCT
		*
	FROM dbo.fn_SplitString(@PMaterialId1, ',')
	UNION
	SELECT DISTINCT
		*
	FROM dbo.fn_SplitString(@PMaterialId2, ',')

SET NOCOUNT ON
SELECT DISTINCT
	ls.ProjectId
   ,ls.SectionId
   ,ls.VimId
   ,@true AS IsLinked
   ,@false AS IsSuggested
   ,@false AS IsRemoved
   ,@false AS IsModified INTO #t
FROM LinkedSections ls WITH (NOLOCK)
INNER JOIN @MaterialIdTbl AS M_Ids
	ON ls.MaterialId = M_Ids.splitdata
WHERE ls.ProjectId = @PProjectId
AND ls.VimID = @PvimId

IF (@PparentVimId <> @PvimId
	AND @PparentVimId > 0)
BEGIN
--selected materials   
SELECT
	v.materialId
   ,v.materialCode INTO #selectedMaterials
FROM vimDb.dbo.buildingMaterial v WITH (NOLOCK)
INNER JOIN @MaterialIdTbl AS M_Ids
	ON v.MaterialId = M_Ids.splitdata
WHERE v.BimId = @PvimId

--Find any element is removed  
DECLARE @c INT
	   ,@presentCount INT = 0
SELECT
	@c = COUNT(1)
FROM #selectedMaterials sm
LEFT OUTER JOIN vimDb.dbo.buildingMaterial v WITH (NOLOCK)
	ON sm.materialCode = v.materialCode
		AND v.BimId = @PparentVimId
WHERE v.MaterialId IS NULL;

IF (@c > 0)
BEGIN
--some elements are removed  
--check for others  
--get group of removed elements  
DECLARE @groupByKey NVARCHAR(MAX);
SELECT
	@groupByKey = CONCAT(MaterialName, MaterialType, CategoryName, MaterialFamilyName)
FROM vimDb.dbo.buildingMaterial v WITH (NOLOCK)
WHERE v.MaterialId = (SELECT TOP 1
		materialId
	FROM #selectedMaterials)
PRINT @groupByKey
--get all elements by @groupByKey  
SELECT
	materialCode INTO #groupElements
FROM vimDb.dbo.buildingMaterial v WITH (NOLOCK)
WHERE v.BimId = @PvimId
AND CONCAT(MaterialName, MaterialType, CategoryName, MaterialFamilyName) = @groupByKey
--check if any element is present in latest file version  
SELECT
	@presentCount = COUNT(1)
FROM vimDb.dbo.buildingMaterial p WITH (NOLOCK)
INNER JOIN #groupElements ge
	ON p.materialCode = ge.materialCode
WHERE p.BimId = @PparentVimId
PRINT @presentCount
IF (@presentCount = 0)
UPDATE t
SET IsRemoved = @true
FROM #t t

END
SELECT
	x.MaterialId INTO #tempMaterial
FROM VimDb.dbo.buildingMaterial x WITH (NOLOCK)
INNER JOIN VimDb.dbo.buildingMaterial item WITH (NOLOCK)
	ON item.materialCode = x.materialCode
INNER JOIN @MaterialIdTbl AS M_Ids  
	ON x.MaterialId = M_Ids.splitdata
WHERE x.BimId = @PvimId
AND item.BimId = @PparentVimId
AND x.AssemblyDescription + x.AssemblyNumber = item.AssemblyDescription + item.AssemblyNumber
AND x.MaterialArea = item.MaterialArea
AND x.MaterialDescription + x.MaterialFamilyName = item.MaterialDescription + item.MaterialFamilyName
AND x.MaterialKeynote + x.MaterialManufacturer = item.MaterialKeynote + item.MaterialManufacturer
AND x.MaterialName + x.MaterialType + x.MaterialVolume = item.MaterialName + item.MaterialType + item.MaterialVolume
AND x.OmniClassNumber + x.OmniClassTitle = item.OmniClassNumber + item.OmniClassTitle
AND x.LevelName + x.CategoryName = item.LevelName + item.CategoryName

SELECT
	x.MaterialId INTO #modifiedMaterial
FROM VimDb.dbo.buildingMaterial x  WITH(NOLOCK)
INNER JOIN @MaterialIdTbl AS M_Ids
	ON x.MaterialId = M_Ids.splitdata
LEFT OUTER JOIN #tempMaterial item
	ON item.MaterialId = x.MaterialId
WHERE x.BimId = @PvimId
AND item.MaterialId IS NULL

UPDATE t
SET t.IsModified = @true
FROM #t t
INNER JOIN [LinkedSections] ls  WITH(NOLOCK)
	ON ls.sectionId = t.SectionId
INNER JOIN #modifiedMaterial mm
	ON ls.MaterialId = mm.MaterialId
WHERE ls.projectId = @PprojectId
AND ls.VimId = @PvimId
AND t.IsRemoved = @false
--drop table #groupElements  
--drop table #selectedMaterials  

END


UPDATE t
SET t.IsSuggested = @true
FROM #t t
INNER JOIN MaterialSection ms  WITH(NOLOCK)
	ON ms.sectionId LIKE '%' + CONVERT(NVARCHAR(500), t.SectionId) + '%'
	AND t.VimId = ms.VimId
	AND t.ProjectId = ms.ProjectId
INNER JOIN @MaterialIdTbl AS M_Ids
	ON ms.MaterialId = M_Ids.splitdata
WHERE ms.ProjectId = @PProjectId
AND ms.VimId = @PvimId;

SELECT DISTINCT
	MaterialId
   ,value AS sectionId INTO #allSections
FROM (SELECT
		ms.MaterialId
	   ,ms.sectionId
	FROM materialSection ms
	INNER JOIN @MaterialIdTbl t
		ON ms.materialId = t.splitdata
	WHERE ms.vimId = @PvimId
	AND ms.projectId = @PprojectId) AS x
CROSS APPLY STRING_SPLIT(sectionId, ',');

--SELECT DISTINCT splitData into #allSections FROM dbo.fn_SplitString(@allsections,',')   
--where splitData<>''  

--SELECT DISTINCT sectionID FROM #allSections   
--SELECT DISTINCT MaterialId FROM #allSections   

INSERT INTO #t
	SELECT DISTINCT
		@PProjectId
	   ,ms.SectionId
	   ,@PVimId
	   ,@false AS IsLinked
	   ,@true AS IsSuggested
	   ,@false AS IsRemoved
	   ,@false AS IsModified
	FROM #allSections ms
	INNER JOIN @MaterialIdTbl AS M_Ids
		ON ms.MaterialId = M_Ids.splitdata
	LEFT OUTER JOIN #t t
		ON t.ProjectId = @PprojectId
			AND ms.SectionId = t.SectionId
			AND t.VimId = @PVimId
	WHERE --ms.ProjectId = @ProjectId AND   
	--AND ms.VimId = @PvimId  
	t.projectId IS NULL;



--INSERT INTO #t  
--SELECT ProjectId,value as SectionId,VimId,IsLinked,IsSuggested,IsRemoved,IsModified  
--FROM #MaterialSection   
--CROSS APPLY STRING_SPLIT(SectionId, ',');  
--DROP TABLE #MaterialSection;  

SELECT DISTINCT
	t.SectionId
   ,t.IsLinked
   ,t.IsSuggested
   ,t.IsRemoved
   ,t.IsModified
   ,p.SourceTag
FROM #t t
INNER JOIN ProjectSection p  WITH(NOLOCK)
	ON p.SectionId = t.SectionId
ORDER BY p.SourceTag, t.SectionId
SET NOCOUNT OFF
  
END

GO
