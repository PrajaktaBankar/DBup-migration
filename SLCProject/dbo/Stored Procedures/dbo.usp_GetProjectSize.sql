CREATE PROCEDURE [dbo].[usp_GetProjectSize]  
AS  
BEGIN  
SELECT SizeId,SizeDescription,ProjectUoMId FROM LuProjectSize  with (nolock)
End
GO
