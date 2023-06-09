CREATE PROCEDURE [dbo].[usp_UpdateProjectLastModifiedDate]
(
@projectId INT, 
@ModifiedBy INT
)
AS
BEGIN
DECLARE @PprojectId INT = @projectId;
DECLARE @PModifiedBy INT = @ModifiedBy;
UPDATE P 
SET ModifiedBy = @PModifiedBy
   ,ModifiedDate = GETUTCDATE()
   from Project P with (nolock)
WHERE ProjectId = @PprojectId
END

GO
