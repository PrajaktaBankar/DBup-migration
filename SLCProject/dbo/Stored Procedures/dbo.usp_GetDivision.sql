CREATE PROCEDURE [dbo].[usp_GetDivision]  
AS  
BEGIN  
  
SELECT DivisionId,DivisionCode,DivisionTitle,SortOrder,IsActive,MasterDataTypeId,FormatTypeId from SLCMaster..Division with (nolock) WHERE IsActive=1  
  
End


GO
