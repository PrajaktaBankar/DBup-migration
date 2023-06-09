CREATE PROCEDURE [dbo].[usp_DataLoadMaterialSectionMapping] @ProjectId INT,@RevitFileId INT -- As VimId
AS
BEGIN
 DECLARE @PProjectId INT = @ProjectId;
 DECLARE @PRevitFileId INT = @RevitFileId;
--Set Nocount On
SET NOCOUNT ON;
	
	-- STEP 1 - SECTION MAPPING FOR KEYNOTES
	DECLARE @BIMFILEID  INT = @PRevitFileId
	DECLARE @customerID INT = ( SELECT
		p.CustomerId
	FROM Project p WITH (NOLOCK)
	WHERE p.ProjectId = @PProjectId)
DECLARE @count INT = 1
	   ,@max INT = 1;
DECLARE @key NVARCHAR(2000) = ''
DECLARE @MaterialID INT = NULL;
--DECLARE @RevitId INT= (SELECT a.RevitFileId FROM [SLCProject].[dbo].[ProjectRevitFile] as a 
--			inner join [SLCProject].[dbo].[ProjectRevitFileMapping] as b on 
--			a.revitFileId=b.revitFileId 
--			WHERE b.projectid=@ProjectId and a.ExtVimId= @PRevitFileId)
SELECT DISTINCT
	IIF(ISNUMERIC(DivisionCode) = 1, CONVERT(NVARCHAR, CONVERT(INT, DivisionCode)), DivisionCode) AS DivisionCode
   ,SectionId
   ,sourceTag INTO #Section
FROM [ProjectSection] WITH (NOLOCK)
WHERE projectId = @PProjectId
AND IsLastLevel = 1
AND IsDeleted = 0;
IF (@PRevitFileId IS NOT NULL
	OR @PRevitFileId = '')
BEGIN
--CASE 1 :Section Mapping on Source Tag
INSERT INTO MaterialSectionMapping (ProjectId, SectionId, MaterialId, RevitFileId, CustomerId, IsActive, IsLinked)
	SELECT DISTINCT
		@PProjectId
	   ,s.sectionId
	   ,m.MaterialId
	   ,@PRevitFileId AS RevitId
	   ,@customerID
	   ,1 AS IsActive
	   ,0 AS IsLinked
	FROM buildingMaterial m WITH (NOLOCK)
	INNER JOIN #Section AS s
		ON m.materialKeyNote = s.sourceTag
	WHERE m.bimId = @PRevitFileId;


--Get invalid and no keynote materials
SELECT DISTINCT
	m.* INTO #invalidKeynoteMaterial
FROM vimdb.dbo.buildingMaterial m WITH (NOLOCK)
LEFT OUTER JOIN #Section ps
	ON ps.sourceTag = m.materialKeyNote
WHERE bimId = @PRevitFileId
AND ps.DivisionCode IS NULL


--CASE 3 : Divisions [All Division]
INSERT INTO MaterialSectionMapping (ProjectId, SectionId, MaterialId, RevitFileId, CustomerId, IsActive, IsLinked)
	SELECT DISTINCT
		@PProjectId
	   ,ps.sectionId
	   ,m.MaterialId
	   ,@PRevitFileId
	   ,@customerID
	   ,1 AS IsActive
	   ,0 AS IsLinked
	FROM #invalidKeynoteMaterial m
	INNER JOIN revitcategories AS r WITH (NOLOCK)
		ON Name = m.categoryName
	CROSS JOIN #Section ps
	LEFT OUTER JOIN MaterialSectionMapping AS sm WITH (NOLOCK)
		ON sm.ProjectId = @PProjectId
			AND sm.SectionId = ps.SectionId
			AND sm.RevitFileId = @PRevitFileId
			AND sm.MaterialId = m.MaterialId
	WHERE m.bimId = @PRevitFileId
	AND r.IsActive = 1
	AND r.HasAllDivisions = 1
	AND sm.MaterialSectionMappingId IS NULL


--CASE 3 : Divisions[Specific division]
INSERT INTO MaterialSectionMapping (ProjectId, SectionId, MaterialId, RevitFileId, CustomerId, IsActive, IsLinked)
	SELECT DISTINCT
		@PProjectId
	   ,ps.sectionId
	   ,m.MaterialId
	   ,@PRevitFileId
	   ,@customerID
	   ,1 AS IsActive
	   ,0 AS IsLinked
	FROM #invalidKeynoteMaterial m
	INNER JOIN revitcategories AS r WITH (NOLOCK)
		ON Name = m.categoryName
	INNER JOIN RevitCategoriesDivisions rd WITH (NOLOCK)
		ON rd.categoryId = r.id
	INNER JOIN #Section ps
		ON ps.divisionCode = IIF(ISNUMERIC(rd.division) = 1, CONVERT(NVARCHAR, CONVERT(INT, rd.division)), rd.division)
	LEFT OUTER JOIN MaterialSectionMapping AS sm WITH (NOLOCK)
		ON sm.ProjectId = @PProjectId
			AND sm.SectionId = ps.SectionId
			AND sm.RevitFileId = @PRevitFileId
			AND sm.MaterialId = m.MaterialId
	WHERE m.bimId = @PRevitFileId
	AND r.IsActive = 1
	AND r.HasAllDivisions = 0
	AND sm.MaterialSectionMappingId IS NULL

END

/* KeyNote Mapping with fulltext*/
-- Step 1 - Extract Keywords
SELECT DISTINCT
	ROW_NUMBER() OVER (ORDER BY (SELECT
			NULL)
	) AS id
   ,bm.MaterialID
   ,CONCAT('"', REPLACE(bm.MaterialFamilyName, '"', ''), '" OR "', REPLACE(bm.MaterialType, '"', ''), '" OR "', REPLACE(bm.MaterialName, '"', ''), '"') AS keyWord INTO #tbl_KeyWords
FROM #invalidKeynoteMaterial AS bm
LEFT OUTER JOIN vimdb.[dbo].revitcategories rc WITH (NOLOCK)
	ON bm.categoryName = rc.Name
WHERE Bimid = @PRevitFileId
AND (materialKeynote IS NULL
OR materialKeynote = '')
AND rc.Id IS NULL

-- Step 2- Create Temp Table for Result
SELECT TOP 1
	0 AS materialId
   ,[ID]
   ,[FolderID]
   ,[Location]
   ,[Prefix]
   ,[Position]
   ,[suffix]
   ,[Origin]
   ,[KeyNoteNumber]
   ,[KeyNoteText] INTO #t
FROM [VimDb].[dbo].[KeyNoteMapping] WITH (NOLOCK)
WHERE 1 = 2;


-- Step 3- Search KeyWord in KeyNoteMapping
DECLARE @cnt INT = 1
SET @max = (SELECT
		MAX(ID)
	FROM #tbl_KeyWords)
SET @key = ''
	WHILE(@cnt<=@max)
	BEGIN
SELECT
	@key = keyWord
   ,@MaterialID = MaterialID
FROM #tbl_KeyWords
WHERE id = @cnt
INSERT INTO #t
	SELECT DISTINCT
		@MaterialID
	   ,[ID]
	   ,[FolderID]
	   ,[Location]
	   ,[Prefix]
	   ,[Position]
	   ,[suffix]
	   ,[Origin]
	   ,[KeyNoteNumber]
	   ,[KeyNoteText]
	FROM [VimDb].[dbo].[KeyNoteMapping] AS km
	WHERE CONTAINS(km.keyNoteText, @key)
SET @cnt = @cnt + 1
		END

-- Step 3- Search KeyWord in KeyNoteMapping
INSERT INTO materialSectionMapping (ProjectId, SectionId, MaterialId, RevitFileId, CustomerId, IsActive, IsLinked)
	SELECT DISTINCT
		@PProjectId
	   ,p.SectionId
	   ,t.MaterialId
	   ,@PRevitFileId
	   ,@customerID
	   ,1 AS IsActive
	   ,0 AS IsLinked
	FROM #Section AS p
	INNER JOIN #t AS t
		ON p.sourceTag = t.Location
	LEFT OUTER JOIN MaterialSectionMapping AS sm WITH (NOLOCK)
		ON sm.ProjectId = @PProjectId
			AND sm.SectionId = p.SectionId
			AND sm.RevitFileId = @PRevitFileId
			AND sm.MaterialId = t.MaterialId
	WHERE sm.MaterialSectionMappingId IS NULL


--STEP 4- DROP TEMP TABLES
DROP TABLE #tbl_KeyWords;
DROP TABLE #t;

END

GO
