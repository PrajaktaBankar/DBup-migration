CREATE PROCEDURE [dbo].[usp_GetDiscipline]    
AS    
BEGIN

SELECT
	DisciplineId AS DisciplineId
   ,MasterDataTypeId
   ,Name
   ,IsActive
   ,IsBundle
   ,DisplayName
   ,Initial
FROM SLCMaster..Discipline WITH (NOLOCK)


END

GO
