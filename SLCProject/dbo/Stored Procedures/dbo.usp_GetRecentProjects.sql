CREATE PROCEDURE [dbo].[usp_GetRecentProjects]
@CustomerId INT NULL, @UserId INT NULL=NULL, @ParticipantEmailId NVARCHAR (255) NULL=NULL, @IsDesc BIT NULL=NULL, @PageNo INT NULL=1, @PageSize INT NULL=100, @ColName NVARCHAR (255) NULL=NULL
AS
BEGIN
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PUserId INT = @UserId;
DECLARE @PParticipantEmailId NVARCHAR (255) = @ParticipantEmailId;
DECLARE @PIsDesc BIT = @IsDesc;
DECLARE @PPageNo INT = @PageNo;
DECLARE @PPageSize INT =  @PageSize;
DECLARE @PColName NVARCHAR (255) = @ColName;

    DECLARE @Order AS INT = CASE @PIsDesc WHEN 1 THEN -1 ELSE 1 END;
    DECLARE @allProjectCount AS INT = COALESCE (( SELECT
		COUNT(1)
	FROM Project AS P WITH (NOLOCK)
	WHERE P.CustomerId = @PCustomerId)
, 0);
SELECT
	x.ProjectId
   ,x.Name
   ,x.IsOfficeMaster
   ,x.Description
   ,x.TemplateId
   ,x.UserId
   ,x.CustomerId
   ,x.CreateDate
   ,x.CreatedBy
   ,x.ModifiedBy
   ,x.ModifiedDate
   ,COALESCE((SELECT
			COUNT(*)
		FROM  Project AS P WITH (NOLOCK)
		INNER JOIN ProjectSection AS PS WITH (NOLOCK)
			ON x.ProjectId = PS.ProjectId
			AND x.CustomerId = PS.CustomerId
			AND x.ProjectId = P.ProjectId
			AND x.CustomerId = P.CustomerId
		INNER JOIN ProjectSegmentStatus AS PSS WITH (NOLOCK)
			ON PSS.ProjectId = x.ProjectId
			AND PSS.CustomerId = x.CustomerId
			AND PSS.SectionId = PS.SectionId
		WHERE PS.IsLastLevel = 1
		AND PSS.ParentSegmentStatusId = 0
		AND (PSS.SegmentStatusTypeId > 0
		AND PSS.SegmentStatusTypeId < 6)
		GROUP BY P.ProjectId)
	, 0) AS SectionCount
   ,x.LastAccessed
   ,@allProjectCount AS allProjectCount
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
		WHERE P.CustomerId = @PCustomerId) AS ProjectsLst
	CROSS APPLY (SELECT
			MAX(UF.LastAccessed) AS LastAccessed
		FROM UserFolder AS UF WITH (NOLOCK)
		WHERE UF.ProjectId = ProjectsLst.ProjectId
		AND UF.CustomerId = ProjectsLst.CustomerId) AS uf) AS x
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
	WHEN @PIsDesc = 0 THEN CASE
			WHEN LOWER(@PColName) = 'Id' THEN X.[ProjectId]
		END
END, CASE
	WHEN @PIsDesc = 0 THEN CASE
			WHEN LOWER(@PColName) = 'createdate' THEN X.LastAccessed
		END
END
OFFSET @PPageSize * (@PPageNo - 1) ROWS FETCH NEXT @PPageSize ROWS ONLY;
END

GO
