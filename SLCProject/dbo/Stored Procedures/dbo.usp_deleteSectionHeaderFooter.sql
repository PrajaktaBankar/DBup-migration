CREATE PROCEDURE [dbo].[usp_deleteSectionHeaderFooter]
	@ProjectId INT,  
	@CustomerId INT,
	@SectionId INT,
	@TypeId INT = 2,
	@DocumentTypeId Int
AS      
BEGIN
	DECLARE @PProjectId INT = @ProjectId;
	DECLARE @PCustomerId INT = @CustomerId;
	DECLARE @PSectionId INT = @SectionId;
	DECLARE @PTypeId INT = @TypeId;
	
--DELETE USED GLOBAL TERM INSTANCES	
DELETE HFGT
	FROM Header H  with(NOLOCK)
	INNER JOIN HeaderFooterGlobalTermUsage HFGT with(NOLOCK)
		ON H.HeaderId = ISNULL(HFGT.HeaderId, 0)
WHERE H.ProjectId = @PProjectId
	AND H.CustomerId = @PCustomerId
	AND H.SectionId = @PSectionId
	AND @PProjectId > 0
	AND @PSectionId > 0
	AND @PCustomerId > 0
	AND H.DocumentTypeId=@DocumentTypeId

DELETE HFGT
	FROM Footer F  with(NOLOCK)
	INNER JOIN HeaderFooterGlobalTermUsage HFGT  with(NOLOCK)
		ON F.FooterId = ISNULL(HFGT.FooterId, 0)
WHERE F.ProjectId = @PProjectId
	AND F.CustomerId = @PCustomerId
	AND F.SectionId = @PSectionId
	AND @PProjectId > 0
	AND @PSectionId > 0
	AND @PCustomerId > 0
	AND F.DocumentTypeId=@DocumentTypeId
--DELETE HEADER/FOOTER
DELETE h
FROM HEADER h  with(NOLOCK)
WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND SectionId = @PSectionId
	AND TypeId = @PTypeId
	AND  DocumentTypeId=@DocumentTypeId

DELETE f
FROM Footer f  with(NOLOCK)
WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND SectionId = @PSectionId
	AND TypeId = @PTypeId
	AND  DocumentTypeId=@DocumentTypeId
END


GO
