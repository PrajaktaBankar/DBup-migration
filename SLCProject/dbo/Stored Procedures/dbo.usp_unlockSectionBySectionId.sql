CREATE PROCEDURE [dbo].[usp_unlockSectionBySectionId] 
(  
 @SectionId INT  
)    
AS
BEGIN
DECLARE @PSectionId INT = @SectionId;

UPDATE PS
SET PS.IsLocked = 0
   ,PS.LockedBy = 0
   ,PS.LockedByFullName = ''
FROM ProjectSection PS WITH (NOLOCK)
WHERE PS.SectionId = @PSectionId
END

GO
