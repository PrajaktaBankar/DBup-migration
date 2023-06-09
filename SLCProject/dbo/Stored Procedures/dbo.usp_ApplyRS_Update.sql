CREATE PROCEDURE [dbo].[usp_ApplyRS_Update]      
@ProjectId INT NULL, @CustomerId INT NULL, @SectionId INT NULL=0 ,@RefStandardId INT NULL=0,@NewRefStdEditionId INT NULL=0,@Source nvarchar(2)     
AS      
BEGIN
 
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PRefStandardId INT  = @RefStandardId;
DECLARE @PNewRefStdEditionId INT = @NewRefStdEditionId;
DECLARE @PSource nvarchar(2) = @Source;
--Set Nocount On
SET NOCOUNT ON;

	IF(@PSource='U')
	BEGIN
UPDATE prs
SET prs.[RefStdEditionId] = @PNewRefStdEditionId
from [ProjectReferenceStandard] prs WITH(NOLOCK)
WHERE ProjectId = @PProjectId
AND CustomerId = @PCustomerId
AND RefStandardId = @PRefStandardId
AND RefStdSource = 'U'
AND ISNULL(IsDeleted,0) = 0
END
ELSE
BEGIN
UPDATE prs
SET prs.[RefStdEditionId] = @PNewRefStdEditionId
FROM [ProjectReferenceStandard] prs WITH(NOLOCK)
WHERE ProjectId = @PProjectId
AND CustomerId = @PCustomerId
AND RefStandardId = @PRefStandardId
AND RefStdSource = 'M'
AND ISNULL(IsDeleted,0) = 0
END
SELECT SectionId FROM [ProjectReferenceStandard] WITH(NOLOCK) WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId 
	AND RefStandardId = @PRefStandardId AND ISNULL(IsDeleted,0) = 0 
END

GO
