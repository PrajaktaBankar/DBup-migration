CREATE PROCEDURE [dbo].[usp_UpdatSectionLastModifiedDate]
(
@sectionId INT, 
@ModifiedBy INT
)
AS
BEGIN
DECLARE @PsectionId INT = @sectionId;
DECLARE @PModifiedBy INT = @ModifiedBy;

UPDATE PS
SET ModifiedBy = @PModifiedBy
   ,ModifiedDate = GETUTCDATE()
   from ProjectSection PS with (nolock)
WHERE SectionId = @PsectionId
END

GO
