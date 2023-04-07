  
CREATE PROCEDURE [dbo].[usp_GetSpecSheetPaperSize]                  
AS          
BEGIN          
          
 SELECT          
  LSPS.SpecSheetPaperId,  
  LSPS.Description,  
  LSPS.Name,  
  LSPS.Width,  
  LSPS.Height,  
  LSPS.IsActive,  
  LSPS.SortOrder     
 FROM LuSpecSheetPaperSize  LSPS with (nolock)  
 WHERE LSPS.IsActive = 1   
          
END 