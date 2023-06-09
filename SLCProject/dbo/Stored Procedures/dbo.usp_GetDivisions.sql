CREATE PROCEDURE [dbo].[usp_GetDivisions]  
AS      
BEGIN

SELECT
	D.DivisionId
   ,D.DivisionCode
   ,D.DivisionTitle
   ,D.SortOrder
   ,D.IsActive
   ,D.MasterDataTypeId
   ,D.FormatTypeId
FROM [SLCMaster].[dbo].[Division] D WITH (NOLOCK)
WHERE IsActive = 1 
ORDER BY D.MasterDataTypeId, D.DivisionCode   
END

GO
