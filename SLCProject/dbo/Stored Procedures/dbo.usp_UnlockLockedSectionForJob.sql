CREATE PROCEDURE [dbo].[usp_UnlockLockedSectionForJob]
(@ProjectId INT, @SectionId nvarchar(max), @CustomerId INT, @UserId INT) AS  
BEGIN
  
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId nvarchar(max) = @SectionId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PUserId INT = @UserId;

UPDATE PS
SET PS.IsLocked = 0
   ,PS.LockedBy = 0
   ,PS.LockedByFullName = ''
   ,PS.ModifiedBy = @PUserId
   ,PS.ModifiedDate = GETUTCDATE()
FROM ProjectSection PS WITH (NOLOCK)
WHERE PS.ProjectId = @PProjectId
AND PS.SectionId IN (SELECT
		CAST(value AS INT)
	FROM STRING_SPLIT(@PSectionId, ','))
AND PS.CustomerId = @PCustomerId

END

GO
