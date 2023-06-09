CREATE PROCEDURE [dbo].[usp_getDeletedMasterSections] --  
 @projectId INT NULL,  @customerId INT NULL=NULL, @userId INT NULL=0,@CatalogueType NVARCHAR (50) NULL='FS'                      
AS  
BEGIN
  
 DECLARE @PprojectId INT = @projectId;
 DECLARE @PcustomerId INT = @customerId;
 DECLARE @PuserId INT = @userId;
 DECLARE @PCatalogueType NVARCHAR (50) = @CatalogueType;
  DECLARE @DeletedProjectSections TABLE   
   (  
   [ProjectID] [int] NULL,  
   [SectionId] [int] NULL,  
   [IsDeleted] bit NULL  
   )

--- TODO : STEP 1 : loop through all deleted master sections.  
SELECT
	ROW_NUMBER() OVER (ORDER BY ms.SectionId) AS id
   ,ms.SectionId
   ,ms.MasterDataTypeId
   ,ms.Description
   ,ms.SourceTag
   ,ms.Author
   ,ms.ParentSectionId
   ,ms.IsLastLevel
   ,ms.SectionCode
   ,CONVERT(INT, 0) AS isDeleteFromProject INTO #DeletedMasterSections
FROM [SLCMaster].dbo.Section AS ms WITH (NOLOCK)
--SLCProject.dbo.ProjectSection AS ps INNER JOIN [SLCMaster].dbo.Section AS ms ON ms.SectionId = ps.mSectionId  
WHERE ms.IsDeleted = 1
--AND ps.IsDeleted = 0  
--AND ps.ProjectId = @PprojectId  
AND ms.IsLastLevel = 1;

SELECT TOP 1
	ROW_NUMBER() OVER (ORDER BY p.ProjectId) AS Id
   ,p.ProjectId INTO #allProjects
FROM Project AS p WITH (NOLOCK)
WHERE p.MasterDataTypeId = 1
AND p.IsDeleted = 0
AND COALESCE(p.IsPermanentDeleted, 0) = 0
AND p.ProjectId = 1
ORDER BY p.ProjectId;

DECLARE @cnt INT = 1
	   ,@deletedcnt INT = 0
	   ,@mSectionId INT = 0
	   ,@SectionCode INT = 0
	   ,@flag BIT = 0
	   ,@allProjectcnt INT = 0
	   ,@Projectcnt INT = 1;
SET @deletedcnt = (SELECT
		COUNT(*)
	FROM #DeletedMasterSections);
SET @allProjectcnt = (SELECT
		COUNT(*)
	FROM #allProjects);
   
  WHILE (@cnt<=@deletedcnt )  
  BEGIN
-- TODO : Loop through all projects   
--- TODO : STEP 2.1 : check 1st conditions - The section has never been opened in this particular project (or the project it was copied from).  

SET @mSectionId = (SELECT
		sectionId
	FROM #DeletedMasterSections
	WHERE id = @cnt);
SET @SectionCode = (SELECT
		SectionCode
	FROM #DeletedMasterSections
	WHERE id = @cnt);
SET @Projectcnt = 1;
  
   WHILE(@Projectcnt<=@allProjectcnt)  
   BEGIN
SET @flag = 0;
SET @PprojectId = (SELECT
		ProjectId
	FROM #allProjects
	WHERE Id = @Projectcnt);
  
  
   -- TODO -- CHECK ALREADY DELETED OR NOT   
   IF(( SELECT
		COUNT(1)
	FROM ProjectSection AS ps WITH (NOLOCK)
	WHERE ps.ProjectID = @PprojectId
	AND ps.mSectionId = @mSectionId
	AND ps.IsDeleted = 1)
>= 1)
SET @flag = 1;

IF (@flag = 0)
BEGIN
IF ((SELECT
			COUNT(1)
		FROM ProjectSegmentStatus AS pss WITH (NOLOCK)
		INNER JOIN ProjectSection AS ps WITH (NOLOCK)
			ON pss.SectionId = ps.SectionId
		WHERE ps.ProjectId = @PprojectId
		AND ps.mSectionId = @mSectionId)
	= 0)
BEGIN

--UPDATE a   
--SET a.isDeleteFromProject = 1  
--from #DeletedMasterSections as a  
--WHERE a.id = @cnt;  

INSERT INTO @DeletedProjectSections ([ProjectID], [SectionId], [IsDeleted])
	VALUES (@PprojectId, @mSectionId, 1)

SET @flag = 1;
  
   END
  
  
    IF(@flag=0)  
    BEGIN
  
   --- TODO : STEP 2.2 : check 2nd conditions - No paragraph w/in the section is presently targeted by an active green or yellow (Spec)link  
     IF( ( SELECT
		COUNT(1)
	FROM ProjectSegmentLink AS psl WITH (NOLOCK)
	WHERE psl.ProjectId = @PprojectId
	AND psl.TargetSectionCode = @SectionCode
	AND IsDeleted = 0
	AND (psl.LinkStatusTypeId = 2
	OR psl.LinkStatusTypeId = 3))
= 0)
BEGIN
UPDATE a
SET a.isDeleteFromProject = 1
FROM #DeletedMasterSections AS a
WHERE a.id = @cnt;

INSERT INTO @DeletedProjectSections ([ProjectID], [SectionId], [IsDeleted])
	VALUES (@PprojectId, @mSectionId, 1)

SET @flag = 1;
  
     END
  
   END
  
     
    IF(@flag=0)  
    BEGIN
  
    --- TODO : STEP 2.3 : check 3nd conditions - The section is not presently referenced by Section ID enhanced text in any section in the project.  
    -- CHECK OPTION JSON  FOR MASTER AND PROJECT  
    -- MASTER CHOICE  
  
     DECLARE @ccnt int =1,@cmax int=0
/* WE CAN SELECT MASTER CHOICE ONLY ONCE AT THE BIGINNING*/
SELECT
	ROW_NUMBER() OVER (ORDER BY ch.ChoiceOptionId) AS ID
   ,ch.OptionJson
   ,ch.ChoiceOptionSource INTO #masterChoiceoptions
FROM SLCMaster.dbo.ChoiceOption AS ch WITH (NOLOCK)
WHERE CH.OptionJson IS NOT NULL
AND CH.OptionJson != '[]'
AND LEN(CH.OptionJson) > 2
AND OptionJson LIKE '%sectionid%'
--- UNION : PROJECT CHOICE   
SET @cmax = (SELECT
		COALESCE(COUNT(*), 0)
	FROM #masterChoiceoptions)
INSERT INTO #masterChoiceoptions
	SELECT
		ROW_NUMBER() OVER (ORDER BY ch.ChoiceOptionId) + @cmax AS ID
	   ,ch.OptionJson
	   ,ch.ChoiceOptionSource
	FROM ProjectChoiceOption AS ch WITH (NOLOCK)
	WHERE ch.OptionJson IS NOT NULL
	AND ch.OptionJson != '[]'
	AND LEN(ch.OptionJson) > 2
	AND OptionJson LIKE '%sectionid%'
	AND ch.ProjectId = @PprojectId;

SET @ccnt = 1
  DECLARE @masterChoiceoptionsRowCount INT=(SELECT COUNT(1) FROM #masterChoiceoptions)

    WHILE (@ccnt<=@masterChoiceoptionsRowCount)
BEGIN
IF ((SELECT
			COUNT(*)
		FROM OPENJSON((SELECT
				OptionJson
			FROM #masterChoiceoptions
			WHERE Id = @ccnt)
		)
		WITH (
		number VARCHAR(200) '$.OptionTypeId',
		type VARCHAR(200) '$.OptionTypeName',
		SectionId INT '$.Id'
		)
		WHERE type = 'SectionID'
		AND SectionId = @SectionCode)
	>= 1)
BEGIN
PRINT 'FOUND ID'
UPDATE a
SET a.isDeleteFromProject = 0
FROM #DeletedMasterSections AS a
WHERE a.id = @cnt;
SET @flag = 1;

DELETE FROM @DeletedProjectSections
WHERE [ProjectID] = @PprojectId
	AND [SectionId] = @mSectionId
--SELECT 'FOUND',@mSectionId,@PprojectId  
BREAK;
END
SET @ccnt = @ccnt + 1;
   
    END

--IF(@flag=0) -- IF SECTION ID NOT FOUND IN CHOICES  
--BEGIN  
-- INSERT INTO @DeletedProjectSections([ProjectID],[SectionId],[IsDeleted])  
-- VALUES(@PprojectId,@mSectionId,1)  
--END  
DROP TABLE #masterChoiceoptions;
END

END

SET @Projectcnt = @Projectcnt + 1;
 --TODO : Fetch next project  
     
   END-- Project Loop ends  
SET @cnt = @cnt + 1;
 --- TODO : STEP 5 : Fetch next section  
  END -- Section Loop ends  
--SELECT * FROM #DeletedMasterSections as a where a.isDeleteFromProject=1;  
SELECT
	*
FROM @DeletedProjectSections
ORDER BY ProjectID
END

GO
