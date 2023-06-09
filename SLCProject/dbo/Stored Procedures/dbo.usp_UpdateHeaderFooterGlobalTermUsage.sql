CREATE PROCEDURE [dbo].[usp_UpdateHeaderFooterGlobalTermUsage]
(
	@HeaderFooterId INT = null,
	@CreatedById INT = null,
	@ProjectId INT = null,
	@CustomerId INT = null,
	@SectionId INT = null,
	@HtmlDescription NVARCHAR(MAX),
	@Type NVARCHAR(10) = 'HEADER',
	@Pattern NVARCHAR(10) = '{GT#'
)
AS
BEGIN
	DECLARE @PHeaderFooterId INT = @HeaderFooterId;
	DECLARE @PCreatedById INT = @CreatedById;
	DECLARE @PProjectId INT = @ProjectId;
	DECLARE @PCustomerId INT = @CustomerId;
	DECLARE @PSectionId INT = @SectionId;
	DECLARE @PHtmlDescription NVARCHAR(MAX) = @HtmlDescription;
	DECLARE @PType NVARCHAR(10) = @Type;
	DECLARE @PPattern NVARCHAR(10) = @Pattern;

	DECLARE @UsedGTS TABLE(GlobalTermCode INT NULL);
	DECLARE @HeaderFooterGT TABLE(
		HeaderId INT NULL,
		FooterId INT NULL,
		UserGlobalTermId INT NULL,
		CustomerId INT NULL,
		ProjectId INT NULL,
		HeaderFooterCategoryId INT NULL,
		CreatedDate DATETIME2 NULL,
		CreatedById INT NULL
	);

INSERT INTO @UsedGTS
	SELECT
		[value] AS GlobalTermCode
	FROM STRING_SPLIT(dbo.[udf_GetCodeFromFormat](@PHtmlDescription, @PPattern), ',')

DECLARE @HeaderId INT = 0;
DECLARE @FooterId INT = 0;
DECLARE @HeaderFooterCategoryId INT = 1;

SELECT
	@HeaderId = IIF(@PType = 'HEADER', @PHeaderFooterId, NULL)
   ,@FooterId = IIF(@PType = 'FOOTER', @PHeaderFooterId, NULL)

IF (@PType = 'HEADER')
BEGIN
UPDATE H
SET H.Description = @PHtmlDescription
   ,H.ModifiedDate = GETUTCDATE()
   ,H.ModifiedBy = @PCreatedById
   FROM Header H WITH (NOLOCK)
WHERE H.HeaderId = @HeaderId
AND H.ProjectId = @PProjectId
AND H.CustomerId = @PCustomerId
  
END
ELSE
BEGIN
UPDATE F
SET F.Description = @PHtmlDescription
   ,F.ModifiedDate = GETUTCDATE()
   ,F.ModifiedBy = @PCreatedById
    FROM Footer F WITH (NOLOCK)
WHERE F.ProjectId = @PProjectId
AND F.CustomerId = @PCustomerId
AND F.FooterId = @FooterId
END

INSERT INTO @HeaderFooterGT
	SELECT
		@HeaderId AS HeaderId
	   ,@FooterId AS FooterId
	   ,PGT.UserGlobalTermId
	   ,PGT.CustomerId
	   ,PGT.ProjectId
	   ,@HeaderFooterCategoryId AS HeaderFooterCategoryId
	   ,GETUTCDATE() AS CreatedDate
	   ,@PCreatedById AS CreatedById
	FROM @UsedGTS GT
	LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK)
		ON PGT.GlobalTermCode = GT.GlobalTermCode
	WHERE PGT.ProjectId = @PProjectId
	AND PGT.GlobalTermSource = 'U'
	AND PGT.CustomerId = @PCustomerId

DELETE PSGT
	FROM HeaderFooterGlobalTermUsage PSGT  WITH (NOLOCK)
	LEFT JOIN @HeaderFooterGT UGT
		ON PSGT.UserGlobalTermId = UGT.UserGlobalTermId
WHERE PSGT.ProjectId = @PProjectId
	AND (PSGT.HeaderId =
	CASE @PType
		WHEN 'HEADER' THEN @HeaderId
	END
	OR PSGT.FooterId =
	CASE @PType
		WHEN 'FOOTER' THEN @FooterId
	END)
--AND UGT.UserGlobalTermId IS NULL

INSERT INTO HeaderFooterGlobalTermUsage
	SELECT
		UGT.*
	FROM @HeaderFooterGT UGT
	LEFT JOIN HeaderFooterGlobalTermUsage PSGT  WITH (NOLOCK)
		ON PSGT.UserGlobalTermId = UGT.UserGlobalTermId
			AND UGT.ProjectId = PSGT.ProjectId
			AND (PSGT.HeaderId =
				CASE @PType
					WHEN 'HEADER' THEN @HeaderId
				END
				OR PSGT.FooterId =
				CASE @PType
					WHEN 'FOOTER' THEN @FooterId
				END)
			AND PSGT.CustomerId = UGT.CustomerId
	WHERE UGT.ProjectId = @PProjectId
	AND (UGT.HeaderId =
	CASE @PType
		WHEN 'HEADER' THEN @HeaderId
	END
	OR UGT.FooterId =
	CASE @PType
		WHEN 'FOOTER' THEN @FooterId
	END)
-- AND PSGT.UserGlobalTermId IS NULL

SELECT
	GETUTCDATE() AS ModifiedDate;
END

GO
