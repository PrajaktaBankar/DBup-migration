CREATE PROCEDURE [dbo].[usp_GetParentSectionIdForImportedSection] 
@ProjectId INT NULL, @CustomerId INT NULL, @CreatedBy INT NULL, @SourceTag VARCHAR (18) NULL  
AS  
BEGIN
  DECLARE @PProjectId INT = @ProjectId;
  DECLARE @PCustomerId INT = @CustomerId;
  DECLARE @PCreatedBy INT = @CreatedBy;
  DECLARE @PSourceTag VARCHAR (18) = @SourceTag;
--DECLARE @ProjectId INT = 0;
--DECLARE @CustomerId INT = 0;
--DECLARE @CreatedBy INT = 0;
--DECLARE @SourceTag NVARCHAR (MAX) = '';

DECLARE @MasterDataTypeId AS INT = 0;
DECLARE @ParentSectionId AS INT;

SET @MasterDataTypeId = (SELECT
		MasterDataTypeId
	FROM Project WITH (NOLOCK)
	WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId);

SELECT TOP 1
	@ParentSectionId = PSEC.SectionId
FROM ProjectSection PSEC  WITH(NOLOCK)
INNER JOIN SLCMaster..Section MSEC  WITH(NOLOCK)
	ON MSEC.SourceTag = PSEC.SourceTag
WHERE projectId = @PProjectId
AND CustomerId = @PCustomerId
AND PSEC.IsLastLevel = 0
AND MSEC.MasterDataTypeId = @MasterDataTypeId
AND MSEC.SourceTag <= @PSourceTag
AND PSEC.IsDeleted = 0
AND (
(
@MasterDataTypeId IN (1, 4)
AND MSEC.LevelId = 3
)
OR (
@MasterDataTypeId IN (2, 3)
AND MSEC.LevelId = 2
)
)
AND (
(CASE
	WHEN LEFT(MSEC.SourceTag, 3) = LEFT(@PSourceTag, 3) THEN 1
	WHEN LEFT(MSEC.SourceTag, 2) = LEFT(@PSourceTag, 2) THEN 1
	WHEN LEFT(MSEC.SourceTag, 1) = LEFT(@PSourceTag, 1) THEN 1
	ELSE 0
END
) = 1
)
AND ((@MasterDataTypeId IN (2, 3)
AND PSEC.DivisionId IS NOT NULL)
OR @MasterDataTypeId IN (1, 4))

ORDER BY PSEC.SourceTag DESC

SELECT
	@ParentSectionId AS SectionId;
END

GO
