CREATE PROCEDURE [dbo].[usp_GetOfficeMaster]    
@CustomerId INT NULL, @UserId INT NULL=NULL, @ParticipantEmailId NVARCHAR (255) NULL=NULL, @IsDesc BIT NULL=NULL, @PageNo INT NULL=1, @PageSize INT NULL=100, @ColName NVARCHAR (255) NULL=NULL, @SearchField NVARCHAR (255) NULL=NULL, @DisciplineId NVARCHAR 
  
(MAX) NULL='', @CatalogueType NVARCHAR (MAX) NULL='FS'    
AS    
BEGIN
  
    DECLARE @PCustomerId INT = @CustomerId;
	DECLARE @PUserId INT = @UserId;
	DECLARE @PParticipantEmailId NVARCHAR (255) = @ParticipantEmailId;
	DECLARE @PIsDesc BIT = @IsDesc;
	DECLARE @PPageNo INT = @PageNo;
	DECLARE @PPageSize INT = @PageSize;
	DECLARE @PColName NVARCHAR (255) = @ColName;
	DECLARE @PSearchField NVARCHAR (255) = @SearchField;
	DECLARE @PDisciplineId NVARCHAR = @DisciplineId;

    DECLARE @Order AS INT = CASE @PIsDesc WHEN 1 THEN -1 ELSE 1 END;
  
    
    DECLARE @isnumeric AS INT = ISNUMERIC(@PSearchField);
  
    
    IF @PSearchField = 'All'
SET @PSearchField = NULL;

DECLARE @allProjectCount AS INT = COALESCE((SELECT
		COUNT(*)
	FROM Project AS P WITH (NOLOCK)
	WHERE P.CustomerId = @PCustomerId
	AND P.IsOfficeMaster = 1)
, 0);

DECLARE @officeMasterCount AS INT = COALESCE((SELECT
		COUNT(*)
	FROM Project AS P WITH (NOLOCK)
	WHERE P.CustomerId = @PCustomerId
	AND P.IsOfficeMaster = 1)
, 0);

SELECT
	Discipline.Name AS DisciplineName
   ,DisciplineSection.DisciplineId
   ,DisciplineSection.SectionId
   ,LuMasterDataType.MasterDataTypeId
   ,LuMasterDataType.Name AS MasterDataTypeName
   ,sts.SpecTypeSectionRestrictionID AS SpecTypeSectionRestrictionID INTO #tmp_DesciplineSection
FROM SLCMaster..Discipline WITH (NOLOCK)
INNER JOIN SLCMaster..DisciplineSection WITH (NOLOCK)
	ON Discipline.DisciplineId = DisciplineSection.DisciplineId
INNER JOIN SLCMaster..LuMasterDataType WITH (NOLOCK)
	ON Discipline.MasterDataTypeId = LuMasterDataType.MasterDataTypeId
LEFT OUTER JOIN SLCMaster..SpecTypeSectionRestriction AS sts WITH (NOLOCK)
	ON DisciplineSection.SectionId = sts.SectionId
WHERE (@PDisciplineId = ''
OR Discipline.DisciplineId IN (SELECT
		*
	FROM dbo.fn_SplitString(@PDisciplineId, ','))
OR @PDisciplineId IS NULL);
SELECT
	P.ProjectId
   ,COUNT(*) AS SectionCount INTO #ProjectCount
FROM Project AS P WITH (NOLOCK)
INNER JOIN ProjectSection AS PS WITH (NOLOCK)
	ON P.ProjectId = PS.ProjectId
		AND P.CustomerId = PS.CustomerId
		AND P.ProjectId = P.ProjectId
		AND P.CustomerId = P.CustomerId
INNER JOIN ProjectSegmentStatus AS PSS WITH (NOLOCK)
	ON PSS.ProjectId = P.ProjectId
		AND PSS.CustomerId = P.CustomerId
		AND PSS.SectionId = PS.SectionId
WHERE PS.IsLastLevel = 1
AND PSS.ParentSegmentStatusId = 0
AND PS.mSectionId IN (SELECT DISTINCT
		SectionId
	FROM #tmp_DesciplineSection AS t
	WHERE (@CatalogueType = 'FS'
	OR t.SpecTypeSectionRestrictionId IS NULL))
AND (PSS.SegmentStatusTypeId > 0
AND PSS.SegmentStatusTypeId < 6)
GROUP BY P.ProjectId;
SELECT
	x.ProjectId
   ,x.Name
   ,x.Description
   ,x.IsOfficeMaster
   ,COALESCE(x.TemplateId, 0) AS TemplateId
   ,x.CustomerId
   ,x.LastAccessed
   ,x.UserId
   ,x.CreateDate
   ,x.CreatedBy
   ,x.ModifiedBy
   ,x.ModifiedDate
   ,@allProjectCount AS allProjectCount
   ,@officeMasterCount AS officeMasterCount
   ,COALESCE(pc.SectionCount, 0) AS SectionCount
   ,x.LastAccessed
   ,x.MasterDataTypeId
FROM (SELECT
		*
	FROM (SELECT
			P.ProjectId
		   ,LTRIM(RTRIM(P.Name)) AS Name
		   ,P.IsOfficeMaster
		   ,P.Description
		   ,P.TemplateId
		   ,P.UserId
		   ,P.CustomerId
		   ,P.CreateDate
		   ,P.CreatedBy
		   ,P.ModifiedBy
		   ,P.ModifiedDate
		   ,0 AS SectionCount
		   ,P.MasterDataTypeId
		FROM Project AS P WITH (NOLOCK)
		WHERE P.IsDeleted = 0
		AND P.IsOfficeMaster = 1
		AND P.CustomerId = @PCustomerId
		AND (P.[Name] LIKE '%' + COALESCE(@PSearchField, P.[Name]) + '%')
		AND ((P.[Description] LIKE '%' + COALESCE(@PSearchField, P.[Description]) + '%')
		OR (P.[ProjectId] =
		CASE
			WHEN @isnumeric = 1 THEN CONVERT(INT, COALESCE(@PSearchField, P.[ProjectId]))
		END
		OR P.[ProjectId] LIKE CASE
			WHEN @isnumeric = 0 THEN '%' + @PSearchField + '%'
		END))) AS ProjectsLst
	OUTER APPLY (SELECT
			MAX(UF.LastAccessed) AS LastAccessed
		FROM UserFolder AS UF WITH (NOLOCK)
		WHERE UF.ProjectId = ProjectsLst.ProjectId
		AND UF.CustomerId = ProjectsLst.CustomerId) AS uf) AS x
LEFT OUTER JOIN #ProjectCount AS pc
	ON x.ProjectId = pc.ProjectId
ORDER BY CASE
	WHEN @PIsDesc = 1 THEN CASE
			WHEN LOWER(@PColName) = 'name' THEN X.Name
		END
END DESC, CASE
	WHEN @PIsDesc = 1 THEN CASE
			WHEN LOWER(@PColName) = 'Id' THEN X.[ProjectId]
		END
END DESC, CASE
	WHEN @PIsDesc = 1 THEN CASE
			WHEN LOWER(@PColName) = 'createdate' THEN X.LastAccessed
		END
END DESC, CASE
	WHEN @PIsDesc = 0 THEN CASE
			WHEN LOWER(@PColName) = 'name' THEN X.Name
		END
END, CASE
	WHEN @IsDesc = 0 THEN CASE
			WHEN LOWER(@PColName) = 'Id' THEN X.[ProjectId]
		END
END, CASE
	WHEN @IsDesc = 0 THEN CASE
			WHEN LOWER(@PColName) = 'createdate' THEN X.LastAccessed
		END
END OFFSET @PPageSize * (@PPageNo - 1) ROWS
FETCH NEXT @PPageSize ROWS ONLY;
END
---------------------------------------------------------  

GO
