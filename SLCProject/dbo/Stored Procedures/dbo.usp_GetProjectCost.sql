CREATE PROCEDURE [dbo].[usp_GetProjectCost]    
AS    
BEGIN    
SELECT CostId,CostDescription,CountryCode FROM LuProjectCost  with (nolock)  
End
GO
