CREATE PROCEDURE [dbo].[usp_DeleteHeaderFooterDetails]
@ProjectId INT,
@CustomerId INT,
@SectionId INT,
@TypeId INT
AS    
BEGIN
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PTypeId INT = @TypeId;

DELETE FROM HEADER
WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND SectionId = @PSectionId
	AND TypeId = @PTypeId

DELETE FROM Footer
WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND SectionId = @PSectionId
	AND TypeId = @PTypeId
END

GO
