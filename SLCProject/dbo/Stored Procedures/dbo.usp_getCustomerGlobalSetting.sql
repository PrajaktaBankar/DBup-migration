--usp_getCustomerGlobalSetting 8,92        
CREATE PROCEDURE [dbo].[usp_getCustomerGlobalSetting]            
 @CustomerId INT,        
 @UserId INT        
AS            
BEGIN    
           
        
DECLARE @PCustomerId INT = @CustomerId        
DECLARE @PUserId INT = @UserId    
SET NOCOUNT ON;    
    
SELECT    
 CustomerGlobalSettingId    
   ,CustomerId    
   ,UserId    
   ,IsAutoSelectParagraph    
   ,IsAutoSelectForImport    
   ,ISIncludeSubparagraph    
   ,IsAlwaysAllowAddPara    
   ,IsMultipleFilesForExport    
   ,IsTCNotifyAccepted    
   ,IncludeAuthorInFileNames,  
   IsIncludeManufacturerParagraph  
FROM [CustomerGlobalSetting] WITH(NOLOCK)    
WHERE CustomerId = @PCustomerId    
AND UserId = @PUserId    
END 