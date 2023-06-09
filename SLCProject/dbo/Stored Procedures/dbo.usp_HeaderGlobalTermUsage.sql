CREATE PROCEDURE [dbo].[usp_HeaderGlobalTermUsage]
    @ProjectId int=0,
	@HeaderId int=0,
	@SectionId int=0,
	@CustomerId int=0,
	@Description nvarchar(Max)='',
	@CreatedById int=0
AS
BEGIN
    DECLARE @PProjectId int = @ProjectId;
	DECLARE @PHeaderId int = @HeaderId;
	DECLARE @PSectionId int = @SectionId;
	DECLARE @PCustomerId int = @CustomerId;
	DECLARE @PDescription nvarchar(Max) = @Description;
	DECLARE @PCreatedById int = @CreatedById;

   IF(@PHeaderId=0)
SET @PHeaderId = (SELECT
		HeaderId
	FROM Header WITH (NOLOCK)
	WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId)

     DECLARE @GTList nvarchar(MAX)='0'
SET @GTList = (SELECT
		LEFT(REPLACE(splitdata, 'GT#', ''), CHARINDEX('}', REPLACE(splitdata, 'GT#', '')) - 1) + ','
	FROM dbo.fn_SplitString(@PDescription, '{')
	WHERE splitdata LIKE 'GT#%'
	FOR XML PATH (''))

UPDATE Header
SET Description = @PDescription
   ,ModifiedDate = GETUTCDATE()
   ,ModifiedBy = @PCreatedById
WHERE ProjectId = @PProjectId
AND CustomerId = @PCustomerId
AND HeaderId = @PHeaderId

SET @GTList = IIF(@GTList IS NOT NULL, @GTList, '0')

	if(@PDescription='' OR @GTList='0')
	BEGIN
DELETE FROM HeaderFooterGlobalTermUsage
WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND HeaderId = @PHeaderId
END

IF (@GTList != '0')
BEGIN

DELETE FROM HeaderFooterGlobalTermUsage
WHERE UserGlobalTermId IN (SELECT
			HFU.UserGlobalTermId
		FROM HeaderFooterGlobalTermUsage HFU WITH (NOLOCK)
		LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK)
			ON PGT.UserGlobalTermId = HFU.UserGlobalTermId
		WHERE PGT.GlobalTermCode NOT IN (SELECT
				*
			FROM dbo.fn_SplitString(@GTList, ','))
		AND PGT.ProjectId = @PProjectId
		AND HFU.HeaderId = @PHeaderId
		AND PGT.CustomerId = @PCustomerId)
	AND ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND HeaderId = @PHeaderId

INSERT INTO HeaderFooterGlobalTermUsage (HeaderId, FooterId, UserGlobalTermId, CustomerId, ProjectId, HeaderFooterCategoryId, CreatedDate, CreatedById)
	SELECT
		@PHeaderId
	   ,NULL
	   ,UserGlobalTermId
	   ,@PCustomerId
	   ,@PProjectId
	   ,1
	   ,GETUTCDATE()
	   ,@PCreatedById
	FROM ProjectGlobalTerm WITH (NOLOCK)
	WHERE CustomerId = @PCustomerId
	AND ProjectId = @PProjectId
	AND GlobalTermSource = 'U'
	AND GlobalTermCode IN (SELECT
			*
		FROM dbo.fn_SplitString(@GTList, ',')
		WHERE UserGlobalTermId NOT IN (SELECT
				UserGlobalTermId
			FROM HeaderFooterGlobalTermUsage WITH (NOLOCK)
			WHERE CustomerId = @PCustomerId
			AND ProjectId = @PProjectId
			AND HeaderId = @PHeaderId))
END

SELECT
	GETUTCDATE() AS ModifiedDate


END

GO
