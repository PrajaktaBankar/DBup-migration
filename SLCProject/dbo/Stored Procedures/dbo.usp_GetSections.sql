CREATE PROCEDURE [dbo].[usp_GetSections]    
	@projectId INT NULL, @customerId INT NULL, @userId INT NULL=NULL, 
	@isActiveOnly BIT NULL=NULL, @DisciplineId NVARCHAR (MAX) NULL, 
	@MasterDataTypeId INT NULL, @CatalogueType NVARCHAR (MAX) NULL='FS', 
	@DivisionId NVARCHAR (MAX) NULL='',@UserAccessDivisionId NVARCHAR (MAX) = ''    
AS    
BEGIN
	DECLARE @PprojectId INT = @projectId;
	DECLARE @PcustomerId INT = @customerId;
	DECLARE @PuserId INT = @userId;
	DECLARE @PisActiveOnly BIT = @isActiveOnly;
	DECLARE @PDisciplineId NVARCHAR = @DisciplineId;
	DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;
	DECLARE @PCatalogueType NVARCHAR = @CatalogueType;
	DECLARE @PDivisionId NVARCHAR = @DivisionId;
	DECLARE @PUserAccessDivisionId NVARCHAR = @UserAccessDivisionId;
--Set NoCount ON
SET NOCOUNT ON;
--TODO : CREATE COMMON SP TO CALL ALL UPDATES SPs : START

--CALL SP FOR EXISTING PROJECT TO SECTION NEWLLY ADDED SECTION  
EXECUTE [sp_LoadUnMappedMasterSectionsToExistingProjectUpdates] @projectId = @PprojectId

--UPDATE SLCPROJECT FOR SPECTYPE TAG
UPDATE PSS
SET PSS.SpecTypeTagId = SS.SpecTypeTagId
FROM ProjectSegmentStatus PSS  WITH(NOLOCK)
INNER JOIN SLCMaster..SegmentStatus SS  WITH(NOLOCK)
	ON PSS.mSegmentStatusId = SS.SegmentStatusId
WHERE PSS.SegmentSource = 'M'
AND PSS.SegmentOrigin = 'M'
AND PSS.SpecTypeTagId IS NULL
AND SS.SpecTypeTagId IS NOT NULL
AND PSS.ProjectId = @PprojectId
AND PSS.CustomerId = @PcustomerId;


-- DELETE RECORDS FROM SLCProject
DELETE FROM PSRT
	FROM ProjectSegmentRequirementTag PSRT  WITH(NOLOCK)
	LEFT JOIN SLCMaster..SegmentRequirementTag SRT  WITH(NOLOCK)
		ON SRT.SegmentRequirementTagId = PSRT.mSegmentRequirementTagId
WHERE SRT.SegmentRequirementTagId IS NULL
	AND PSRT.mSegmentRequirementTagId IS NOT NULL
	AND PSRT.ProjectId = @PprojectId
	AND PSRT.CustomerId = @PcustomerId;


/* SP CALL TO MODIFIY SECTION NAME AND ID */
EXEC usp_updateSectionNameAndID @projectId = @PprojectId

/* CHECK DELETED MASTER SECTION IN A PROJECT */
/* NOTE: Commented below due to performance [Delete Section Scenario - 1] */
EXEC usp_deletedMasterSectionsFromProject @ProjectId = @PprojectId
											 ,@customerId = @PcustomerId

-- : END


--Declare table variables
DECLARE @AdminDivisionIdTbl TABLE (
	DivisionId INT
);
DECLARE @AdminDisciplineIdTbl TABLE (
	DisciplineId INT
);
DECLARE @UserAccessDivisionIdTbl TABLE (
	DivisionId INT
);

--OL/SF count table
DECLARE @OLSFCountTbl TABLE (
	SectionId INT
   ,OLSFCount INT
   ,IsDataFetched BIT
);

--Set data into variables
SET @PMasterDataTypeId = (SELECT TOP 1
		MasterDataTypeId
	FROM Project
	WHERE ProjectId = @PprojectId);

INSERT INTO @AdminDisciplineIdTbl (DisciplineId)
	SELECT
		*
	FROM dbo.fn_SplitString(@PDisciplineId, ',');

INSERT INTO @AdminDivisionIdTbl (DivisionId)
	SELECT
		*
	FROM dbo.fn_SplitString(@PDivisionId, ',');

INSERT INTO @UserAccessDivisionIdTbl (DivisionId)
	SELECT
		*
	FROM dbo.fn_SplitString(@PUserAccessDivisionId, ',');

--Final section table
CREATE TABLE #SectionTable(
	SectionId INT
   ,mSectionId INT
   ,ParentSectionId INT
   ,ProjectId INT
   ,CustomerId INT
   ,UserId INT
   ,TemplateId INT
   ,DivisionId INT
   ,DivisionCode NVARCHAR(MAX)
   ,Description NVARCHAR(MAX)
   ,DescriptionForPrint NVARCHAR(MAX)
   ,CatalogueType NVARCHAR(MAX)
   ,IsDisciplineEnabled BIT
   ,LevelId INT
   ,IsLastLevel BIT
   ,SourceTag VARCHAR(10)
   ,Author NVARCHAR(MAX)
   ,CreatedBy INT
   ,CreateDate DATETIME2(7)
   ,ModifiedBy INT
   ,ModifiedDate DATETIME2(7)
   ,SegmentOrigin CHAR(2)
   ,SegmentStatusTypeId INT
   ,SectionCode INT
   ,IsLocked BIT
   ,LockedBy INT
   ,LockedByFullName NVARCHAR(MAX)
   ,FormatTypeId INT
   ,SourceTagFormat VARCHAR(10)
   ,OLSFCount INT
   ,IsMasterDeleted BIT
   ,IsUserSection BIT
);

--Fetch details in section table
INSERT INTO #SectionTable
	SELECT
		PS.SectionId AS SectionId
	   ,ISNULL(PS.mSectionId, 0) AS mSectionId
	   ,ISNULL(PS.ParentSectionId, 0) AS ParentSectionId
	   ,PS.ProjectId AS ProjectId
	   ,PS.CustomerId AS CustomerId
	   ,@PuserId AS UserId
	   ,ISNULL(PS.TemplateId, 0) AS TemplateId
	   ,ISNULL(PS.DivisionId, 0) AS DivisionId
	   ,ISNULL(D.DivisionCode, '') AS DivisionCode
	   ,ISNULL(PS.Description, '') AS Description
	   ,ISNULL(PS.Description, '') AS DescriptionForPrint
	   ,@PCatalogueType AS CatalogueType
	   ,1 AS IsDisciplineEnabled
	   ,PS.LevelId AS LevelId
	   ,PS.IsLastLevel AS IsLastLevel
	   ,PS.SourceTag AS SourceTag
	   ,ISNULL(PS.Author, '') AS Author
	   ,ISNULL(PS.CreatedBy, 0) AS CreatedBy
	   ,ISNULL(PS.CreateDate, GETDATE()) AS CreateDate
	   ,ISNULL(PS.ModifiedBy, 0) AS ModifiedBy
	   ,ISNULL(PS.ModifiedDate, GETDATE()) AS ModifiedDate
	   ,(CASE
			WHEN PSS.SegmentStatusId IS NULL AND
				PS.mSectionId IS NOT NULL THEN 'M'
			WHEN PSS.SegmentStatusId IS NULL AND
				PS.mSectionId IS NULL THEN 'U'
			WHEN PSS.SegmentStatusId IS NOT NULL AND
				PSS.SegmentSource = 'M' AND
				PSS.SegmentOrigin = 'M' THEN 'M'
			WHEN PSS.SegmentStatusId IS NOT NULL AND
				PSS.SegmentSource = 'U' AND
				PSS.SegmentOrigin = 'U' THEN 'U'
			WHEN PSS.SegmentStatusId IS NOT NULL AND
				PSS.SegmentSource = 'M' AND
				PSS.SegmentOrigin = 'U' THEN 'M*'
		END) AS SegmentOrigin
	   ,COALESCE(PSS.SegmentStatusTypeId, -1) AS SegmentStatusTypeId
	   ,ISNULL(PS.SectionCode, 0) AS SectionCode
	   ,ISNULL(PS.IsLocked, 0) AS IsLocked
	   ,ISNULL(PS.LockedBy, 0) AS LockedBy
	   ,ISNULL(PS.LockedByFullName, '') AS LockedByFullName
	   ,PS.FormatTypeId AS FormatTypeId
	   ,PSMRY.SourceTagFormat AS SourceTagFormat
	   ,0 AS OLSFCount
	   ,(CASE
			WHEN MS.SectionId IS NOT NULL AND
				MS.IsDeleted = 1 THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
		END) AS IsMasterDeleted
	   ,(CASE
			WHEN PS.IsLastLevel = 1 AND
				(PS.mSectionId IS NULL OR
				PS.mSectionId <= 0 OR
				PS.Author = 'USER') THEN 1
			ELSE 0
		END) AS IsUserSection
	FROM ProjectSection PS WITH (NOLOCK)
	INNER JOIN ProjectSummary PSMRY WITH (NOLOCK)
		ON PS.ProjectId = PSMRY.ProjectId
	LEFT JOIN SLCMaster..Section MS WITH (NOLOCK)
		ON PS.mSectionId = MS.SectionId
	LEFT JOIN SLCMaster..Division D WITH (NOLOCK)
		ON PS.DivisionId = D.DivisionId
	LEFT OUTER JOIN ProjectSegmentStatus AS PSS WITH (NOLOCK)
		ON PS.SectionId = PSS.SectionId
			AND PSS.ParentSegmentStatusId = 0
			AND PSS.SequenceNumber = 0
			AND PSS.IndentLevel = 0
	WHERE PS.ProjectId = @PprojectId
	AND PS.CustomerId = @PcustomerId
	AND PS.IsDeleted = 0

--Get OL/SF Count
INSERT INTO @OLSFCountTbl (SectionId, OLSFCount, IsDataFetched)
	SELECT
		PS.SectionId
	   ,X.StatusCount
	   ,CAST(1 AS BIT)
	FROM #SectionTable PS WITH(NOLOCK)
	INNER JOIN (SELECT
			PSST.SectionId
		   ,COUNT(1) AS StatusCount
		FROM ProjectSegmentStatus PSST WITH (NOLOCK)
		WHERE PSST.SpecTypeTagId IN (1, 2, 3, 4)
		AND (PSST.IsDeleted IS NULL
		OR PSST.IsDeleted = 0)
		GROUP BY PSST.SectionId) AS X
		ON PS.SectionId = X.SectionId

INSERT INTO @OLSFCountTbl (SectionId, OLSFCount, IsDataFetched)
	SELECT
		PS.SectionId
	   ,X.StatusCount
	   ,CAST(1 AS BIT)
	FROM #SectionTable PS WITH(NOLOCK)
	INNER JOIN (SELECT
			SST.SectionId
		   ,COUNT(1) AS StatusCount
		FROM SLCMaster..SegmentStatus SST WITH (NOLOCK)
		WHERE SST.SpecTypeTagId IN (1, 2)
		AND (SST.IsDeleted IS NULL
		OR SST.IsDeleted = 0)
		GROUP BY SST.SectionId) AS X
		ON PS.mSectionId = X.SectionId
	LEFT JOIN @OLSFCountTbl Tbl
		ON PS.SectionId = Tbl.SectionId
	WHERE Tbl.SectionId IS NULL

--Update OL/SF Count
UPDATE PS
SET PS.OLSFCount = CT.OLSFCount
FROM #SectionTable PS WITH(NOLOCK)
INNER JOIN @OLSFCountTbl CT
	ON PS.SectionId = CT.SectionId

--Update Correct DescriptionForPrint
UPDATE PS
SET PS.DescriptionForPrint = PS.SourceTag + ' - ' + PS.DescriptionForPrint
FROM #SectionTable PS WITH(NOLOCK)
WHERE PS.IsLastLevel = 0
AND PS.DescriptionForPrint NOT LIKE '%Division%'
AND PS.DescriptionForPrint NOT LIKE '%-%'

--Set Discipline Disabled if not accessible to disciplines came from ADMIN
UPDATE PS
SET PS.IsDisciplineEnabled = 0
FROM #SectionTable PS WITH(NOLOCK)
INNER JOIN SLCMaster..DisciplineSection DS WITH(NOLOCK)
	ON PS.mSectionId = DS.SectionId
INNER JOIN SLCMaster..Discipline D WITH(NOLOCK)
	ON DS.DisciplineId = D.DisciplineId
LEFT JOIN @AdminDisciplineIdTbl DSTbl
	ON D.DisciplineId = DSTbl.DisciplineId
WHERE PS.IsLastLevel = 1
AND PS.IsUserSection = 0
AND DSTbl.DisciplineId IS NULL

--Set discipline enabled if accessible to disciplines came from ADMIN
UPDATE PS
SET PS.IsDisciplineEnabled = 1
FROM #SectionTable PS WITH(NOLOCK)
INNER JOIN SLCMaster..DisciplineSection DS WITH(NOLOCK)
	ON PS.mSectionId = DS.SectionId 
INNER JOIN SLCMaster..Discipline D WITH(NOLOCK)
	ON DS.DisciplineId = D.DisciplineId
INNER JOIN @AdminDisciplineIdTbl DSTbl
	ON D.DisciplineId = DSTbl.DisciplineId
WHERE PS.IsLastLevel = 1
AND PS.IsUserSection = 0

--Set Discipline Disabled if not accessible to divisions came from ADMIN in case of NMS
UPDATE PS
SET PS.IsDisciplineEnabled = 1
FROM #SectionTable PS WITH(NOLOCK)
INNER JOIN @AdminDivisionIdTbl DTbl
	ON PS.DivisionId = DTbl.DivisionId
WHERE PS.IsLastLevel = 1
AND @PMasterDataTypeId != 1

--Set Discipline Disabled if not accessible to divisions 
IF EXISTS (SELECT TOP 1
			*
		FROM @UserAccessDivisionIdTbl)
BEGIN
UPDATE PS
SET PS.IsDisciplineEnabled = 0
FROM #SectionTable PS WITH(NOLOCK)
LEFT JOIN @UserAccessDivisionIdTbl DTbl
	ON PS.DivisionId = DTbl.DivisionId
WHERE PS.IsLastLevel = 1
AND @PMasterDataTypeId = 1
AND DTbl.DivisionId IS NULL
END

--Set Discipline Disabled if catalogue type is not FS and restricted by table
IF @PCatalogueType != 'FS'
BEGIN
UPDATE PS
SET PS.IsDisciplineEnabled = 0
FROM #SectionTable PS WITH(NOLOCK)
INNER JOIN SLCMaster..SpecTypeSectionRestriction SSR WITH(NOLOCK)
	ON PS.mSectionId = SSR.SectionId
WHERE PS.IsLastLevel = 1
AND PS.IsUserSection = 0
AND @PMasterDataTypeId = 1
END

--Select final result
SELECT
	*
FROM #SectionTable WITH(NOLOCK)
ORDER BY SourceTag ASC, Author ASC

END

GO
