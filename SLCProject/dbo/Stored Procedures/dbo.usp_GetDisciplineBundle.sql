CREATE PROCEDURE [dbo].[usp_GetDisciplineBundle]  
AS  
BEGIN

SELECT
	Id,DisciplineBundleId,DisciplineId,IsActive
FROM SLCMaster.dbo.DisciplineBundle WITH (NOLOCK)
WHERE IsActive = 1

END

GO
