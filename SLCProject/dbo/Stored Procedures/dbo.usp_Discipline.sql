CREATE PROCEDURE [dbo].[usp_Discipline]  
AS  
BEGIN  
  
SELECT * FROM LuProjectDiscipline with (nolock) WHERE IsActive=1  

End


GO
