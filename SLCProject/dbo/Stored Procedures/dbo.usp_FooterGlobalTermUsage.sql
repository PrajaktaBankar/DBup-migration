CREATE PROCEDURE [dbo].[usp_FooterGlobalTermUsage]  
 @ProjectId int=0,  
 @FooterId int=0,  
 @SectionId int=0,  
 @CustomerId int=0,  
 @Description nvarchar(MAX)='',  
 @CreatedById int=0  
AS  
BEGIN
  
 DECLARE @PProjectId int = @ProjectId;
 DECLARE @PFooterId int = @FooterId;
 DECLARE @PSectionId int =  @SectionId;
 DECLARE @PCustomerId int = @CustomerId;
 DECLARE @PDescription nvarchar(MAX) = @Description;
 DECLARE @PCreatedById int = @CreatedById;

 IF(@PFooterId=0)
SET @PFooterId = (SELECT
		FooterId
	FROM Footer WITH (NOLOCK)
	WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId)
  
   
  DECLARE @GTList nvarchar(MAX)=''

SET @GTList = (SELECT
		LEFT(REPLACE(splitdata, 'GT#', ''), CHARINDEX('}', REPLACE(splitdata, 'GT#', '')) - 1) + ','
	FROM dbo.fn_SplitString(@PDescription, '{')
	WHERE splitdata LIKE 'GT#%'
	FOR XML PATH (''))

UPDATE f
SET f.Description = @PDescription
   ,f.ModifiedDate = GETUTCDATE()
   ,f.ModifiedBy = @PCreatedById
   from Footer f WITH(NOLOCK)
WHERE f.ProjectId = @PProjectId
AND f.CustomerId = @PCustomerId
AND f.FooterId = @PFooterId

SET @GTList = IIF(@GTList IS NOT NULL, @GTList, '0')
  
  
 if(@PDescription='' OR @GTList='0')  
 BEGIN
DELETE hfgt
FROM HeaderFooterGlobalTermUsage hfgt WITH(NOLOCK)
WHERE hfgt.ProjectId = @PProjectId
	AND hfgt.CustomerId = @PCustomerId
	AND hfgt.FooterId = @PFooterId
END

IF (@GTList != '0')
BEGIN

SELECT
			HFU.UserGlobalTermId
		into #gtId FROM HeaderFooterGlobalTermUsage HFU WITH (NOLOCK)
		LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK)
			ON PGT.UserGlobalTermId = HFU.UserGlobalTermId
		WHERE PGT.GlobalTermCode NOT IN (SELECT
				*
			FROM dbo.fn_SplitString(@GTList, ','))
		AND PGT.ProjectId = @PProjectId
		AND HFU.FooterId = @PFooterId
		AND PGT.CustomerId = @PCustomerId

DELETE hfgt
FROM HeaderFooterGlobalTermUsage hfgt with(nolock) inner join #gtId t
ON hfgt.UserGlobalTermId =t.UserGlobalTermId
WHERE hfgt.ProjectId = @PProjectId
	AND hfgt.CustomerId = @PCustomerId
	AND hfgt.FooterId = @PFooterId



INSERT INTO HeaderFooterGlobalTermUsage (HeaderId, FooterId, UserGlobalTermId, CustomerId, ProjectId, HeaderFooterCategoryId, CreatedDate, CreatedById)
	SELECT
		NULL
	   ,@PFooterId
	   ,UserGlobalTermId
	   ,@PCustomerId
	   ,@PProjectId
	   ,1
	   ,GETUTCDATE()
	   ,@PCreatedById
	FROM ProjectGlobalTerm WITH (NOLOCK)
	WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND GlobalTermSource = 'U'
	AND GlobalTermCode IN (SELECT
			*
		FROM dbo.fn_SplitString(@GTList, ',')
		WHERE UserGlobalTermId NOT IN (SELECT
				UserGlobalTermId
			FROM HeaderFooterGlobalTermUsage WITH (NOLOCK)
			WHERE ProjectId = @PProjectId
			AND CustomerId = @PCustomerId
			AND FooterId = @PFooterId))
END

SELECT
	GETUTCDATE() AS ModifiedDate

END

GO
