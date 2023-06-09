CREATE PROCEDURE [dbo].[usp_GetSectionsdemo]  
@projectId INT NULL, @customerId INT NULL, @userId INT NULL=NULL, @isActiveOnly BIT NULL=NULL, @DisciplineId NVARCHAR (MAX) NULL, @MasterDataTypeId INT NULL, @CatalogueType NVARCHAR (MAX) NULL='FS', @DivisionId NVARCHAR (50) NULL=''  
AS  
BEGIN
DECLARE @PprojectId INT = @projectId;
DECLARE @PcustomerId INT = @customerId;
DECLARE @PuserId INT = @userId;
DECLARE @PisActiveOnly BIT = @isActiveOnly;
DECLARE @PDisciplineId NVARCHAR (MAX) = @DisciplineId;
DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;
DECLARE @PCatalogueType NVARCHAR (MAX) = @CatalogueType;
DECLARE @PDivisionId NVARCHAR (50) = @DivisionId;

DECLARE @OLSFCountTbl TABLE (
SectionId INT,
OLSFCount INT,
IsDataFetched BIT
);

SET NOCOUNT ON;
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
WHERE (Discipline.DisciplineId IN (SELECT
		Id
	FROM dbo.udf_GetSplittedIds(@PDisciplineId, ','))
)
AND Discipline.MasterDataTypeId = @PMasterDataTypeId;
--SELECT
-- PS.SectionId AS SectionId
--   ,COUNT(1) AS OLSFCount INTO #tmp_OLSFCount
--FROM ProjectSection AS PS WITH (NOLOCK)
--INNER JOIN SLCMaster..SegmentStatus AS MSS WITH (NOLOCK)
-- ON PS.mSectionId = MSS.SectionId
--WHERE PS.ProjectId = @PprojectId
--AND PS.CustomerId = @PcustomerId
--AND MSS.SpecTypeTagId IN (1, 2)
--GROUP BY PS.SectionId;

INSERT INTO @OLSFCountTbl (SectionId, OLSFCount, IsDataFetched)
	SELECT
		PS.SectionId
	   ,X.StatusCount
	   ,CAST(1 AS BIT)
	FROM ProjectSection PS
	INNER JOIN (SELECT
			PSST.ProjectId
		   ,PSST.SectionId
		   ,PSST.CustomerId
		   ,COUNT(1) AS StatusCount
		FROM ProjectSegmentStatus PSST
		WHERE PSST.SpecTypeTagId IN (1, 2)
		GROUP BY PSST.ProjectId
				,PSST.SectionId
				,PSST.CustomerId) AS X
		ON PS.ProjectId = X.ProjectId
			AND PS.SectionId = X.SectionId
			AND PS.CustomerId = X.CustomerId
	WHERE PS.ProjectId = @PprojectId
	AND PS.CustomerId = @PcustomerId

INSERT INTO @OLSFCountTbl (SectionId, OLSFCount, IsDataFetched)
	SELECT
		PS.SectionId
	   ,x.StatusCount
	   ,CAST(1 AS BIT)
	FROM ProjectSection PS
	INNER JOIN (SELECT
			COUNT(1) AS StatusCount
		   ,sectionid
		FROM SLCMaster..SegmentStatus SST
		WHERE spectypetagid IN (1, 2)
		AND SST.IsDeleted = 0
		GROUP BY sectionid) AS x
		ON PS.mSectionId = x.SectionId
	LEFT JOIN @OLSFCountTbl Tbl
		ON PS.SectionId = Tbl.SectionId
	WHERE PS.ProjectId = @PprojectId
	AND PS.CustomerId = @PcustomerId
	AND Tbl.SectionId IS NULL

SELECT DISTINCT
	PS.SectionId
   ,COALESCE(PS.mSectionId, 0) AS mSectionId
   ,ISNULL(PS.ParentSectionId, 0) AS ParentSectionId
   ,PS.ProjectId
   ,PS.CustomerId
   ,PS.UserId
   ,COALESCE(PS.TemplateId, 0) AS TemplateId
   ,COALESCE(PS.DivisionId, 0) AS DivisionId
   ,COALESCE(PS.DivisionCode, '') AS DivisionCode
   ,PS.Description
   ,@PCatalogueType
   ,CASE
		WHEN ((TMPDSC.SectionId IS NOT NULL) AND
			(@PCatalogueType = 'FS' OR
			TMPDSC.SpecTypeSectionRestrictionId IS NULL)) THEN CAST(1 AS BIT)
		WHEN (PS.ISLASTLEVEL = 1 AND
			PS.DivisionId IN (SELECT
					Id
				FROM dbo.udf_GetSplittedIds(@PDivisionId, ','))
			) THEN CAST(1 AS BIT)
		WHEN (PS.ISLASTLEVEL = 1 AND
			(PS.mSectionId IS NULL OR
			PS.mSectionId = 0 OR
			PS.Author = 'USER')) THEN CAST(1 AS BIT)
		ELSE CAST(0 AS BIT)
	END AS IsDisciplineEnabled
   ,PS.LEVELID
   ,PS.ISLASTLEVEL
   ,PS.SOURCETAG
   ,COALESCE(PS.Author, '') AS Author
   ,PS.CreateDate
   ,PS.CreatedBy
   ,COALESCE(PS.ModifiedBy, 0) AS ModifiedBy
   ,COALESCE(PS.ModifiedDate, GETDATE()) AS ModifiedDate
   ,CASE
		WHEN PS.mSectionId IS NOT NULL AND
			PS.mSectionId > 0 THEN 'M'
		ELSE 'U'
	END AS SegmentOrigin
   ,COALESCE(PSS.SegmentStatusTypeId, -1) AS SegmentStatusTypeId
   ,PS.SECTIONCODE
   ,PS.IsLocked
   ,COALESCE(PS.LockedBy, 0) AS LockedBy
   ,COALESCE(PS.LockedByFullName, '') AS LockedByFullName
   ,PS.FormatTypeId
   ,PSSS.SourceTagFormat
   ,COALESCE(TMPOLSFCOUNT.OLSFCount, 0) AS OLSFCount
FROM ProjectSection AS PS WITH (NOLOCK)
LEFT OUTER JOIN ProjectSegmentStatus AS PSS WITH (NOLOCK)
	ON PS.SectionId = PSS.SectionId
		AND PS.ProjectId = PSS.ProjectId
		AND PS.CustomerId = PSS.CustomerId
		AND PSS.ParentSegmentStatusId = 0
		AND PSS.IndentLevel = 0
LEFT OUTER JOIN #tmp_DesciplineSection AS TMPDSC
	ON PS.mSectionId = TMPDSC.SectionId
LEFT OUTER JOIN @OLSFCountTbl AS TMPOLSFCOUNT
	ON PS.SectionId = TMPOLSFCOUNT.SectionId
INNER JOIN ProjectSummary AS PSSS
	ON PS.ProjectId = PSSS.ProjectId
WHERE PS.ProjectId = @PprojectId
AND PS.CustomerId = @PcustomerId
AND PS.ISDELETED = 0
ORDER BY PS.IsLastLevel ASC, PS.SourceTag ASC;
END

GO
