CREATE PROCEDURE [dbo].[usp_GetChoiceType]  
AS  
BEGIN  
  
SELECT  ChoiceTypeId,ChoiceType FROM LuProjectChoiceType  with (nolock)
  
End


GO
