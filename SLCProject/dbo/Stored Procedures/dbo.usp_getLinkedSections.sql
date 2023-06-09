CREATE PROC [dbo].[usp_getLinkedSections] 
(
	@projectId int,
	@customerId int,
	@vimId int,
	@parentVimId int
)
AS
BEGIN
	DECLARE @PprojectId int = @projectId;
	DECLARE @PcustomerId int = @customerId;
	DECLARE @PvimId int = @vimId;
	DECLARE @PparentVimId inT = @parentVimId;
--SET NOCOUNT ON
SET NOCOUNT ON;
--SET STATISTICS TIME ON;

	DECLARE @true bit=1
	DECLARE @false bit=0
SELECT
	SectionId
   ,@false AS IsSuggested
   ,@false AS IsLinked
   ,@false AS IsRemoved
   ,@false AS IsModified INTO #temp
FROM ProjectSection WITH (NOLOCK)
WHERE projectId = @PprojectId
AND IsLastLevel = 1
AND IsDeleted = 0
AND customerId = @PcustomerId

UPDATE t
SET t.IsLinked = @true
FROM #temp t
INNER JOIN [LinkedSections] ls WITH (NOLOCK)
	ON ls.sectionId = t.SectionId
WHERE ls.projectId = @PprojectId
AND ls.VimId = @PvimId

SELECT DISTINCT
	MaterialId
   ,value AS sectionId INTO #allSections
FROM (SELECT
		ms.MaterialId
	   ,ms.sectionId
	FROM materialSection ms WITH (NOLOCK)
	WHERE ms.vimId = @PvimId
	AND ms.projectId = @PprojectId) AS x
CROSS APPLY STRING_SPLIT(sectionId, ',');

UPDATE t
SET t.IsSuggested = @true
FROM #temp t
INNER JOIN #allSections ms
	ON ms.sectionId = t.SectionId;
--WHERE ms.projectId = @PprojectId;

IF (@PparentVimId <> @PvimId
	AND @PparentVimId > 0)
BEGIN
SELECT
	v.MaterialId INTO #removedMaterials
FROM VimDb.dbo.buildingMaterial v WITH (NOLOCK)
LEFT OUTER JOIN VimDb.dbo.buildingMaterial p WITH (NOLOCK)
	ON p.materialCode = v.materialCode
		AND p.BimId = @PparentVimId
WHERE v.BimId = @PvimId
AND p.materialCode IS NULL

UPDATE t
SET t.IsRemoved = @true
FROM #temp t
INNER JOIN [LinkedSections] ls WITH (NOLOCK)
	ON ls.sectionId = t.SectionId
INNER JOIN #removedMaterials rm
	ON ls.MaterialId = rm.MaterialId
WHERE ls.projectId = @PprojectId
AND ls.VimId = @PvimId

SELECT
	x.MaterialId INTO #tempMaterial
FROM VimDb.dbo.buildingMaterial x WITH (NOLOCK)
INNER JOIN VimDb.dbo.buildingMaterial item WITH (NOLOCK)
	ON item.materialCode = x.materialCode
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
FROM VimDb.dbo.buildingMaterial x WITH (NOLOCK)
LEFT OUTER JOIN #tempMaterial item
	ON item.MaterialId = x.MaterialId
WHERE x.BimId = @PvimId
AND item.MaterialId IS NULL

UPDATE t
SET t.IsModified = @true
FROM #temp t
INNER JOIN [LinkedSections] ls WITH (NOLOCK)
	ON ls.sectionId = t.SectionId
INNER JOIN #modifiedMaterial mm
	ON ls.MaterialId = mm.MaterialId
WHERE ls.projectId = @PprojectId
AND ls.VimId = @PvimId
END

SELECT
	SectionId
   ,IsSuggested
   ,IsLinked
   ,IsRemoved
   ,IsModified
FROM #temp
WHERE IsSuggested = @true
OR IsLinked = @true
OR IsModified = @true
--ORDER BY sectionId

END

GO
