CREATE PROCEDURE [dbo].[usp_CreateOrUpdateCustomerGlobalSetting]        
 (@CustomerId INT,           
 @UserId INT ,           
 @IsAutoSelectParagraph BIT = NULL,        
 @IsAutoSelectForImport BIT = NULL,        
 @IsIncludeSubparagraph BIT = NULL,        
 @IsAlwaysAllowAddPara BIT=0,      
 @IsMultipleFilesForExport BIT=0,    
 @IsTCNotifyAccepted BIT=0,    
 @IncludeAuthorInFileNames BIT=0  ,  
 @IsIncludeManufacturerParagraph BIT=1  
)AS              
BEGIN        
          
  DECLARE @PCustomerId INT = @CustomerId           
  DECLARE @PUserId INT = @UserId           
  DECLARE @PIsAutoSelectParagraph BIT = @IsAutoSelectParagraph        
  DECLARE @PIsAutoSelectForImport BIT = @IsAutoSelectForImport        
  DECLARE @PIsIncludeSubparagraph BIT = @IsIncludeSubparagraph        
  DECLARE @PIsAlwaysAllowAddPara BIT = @IsAlwaysAllowAddPara        
  DECLARE @PIsMultipleFilesForExport BIT = @IsMultipleFilesForExport    
  DECLARE @PIsTCNotifyAccepted BIT=@IsTCNotifyAccepted    
  DECLARE @PIncludeAuthorInFileNames BIT= @IncludeAuthorInFileNames    
  DECLARE @PIsIncludeManufacturerParagraph BIT= @IsIncludeManufacturerParagraph    
    
  IF NOT EXISTS(SELECT TOP 1 1 FROM CustomerGlobalSetting WITH(NOLOCK) WHERE CustomerId = @PCustomerId AND UserId = @PUserId)        
	 BEGIN        
		  INSERT INTO CustomerGlobalSetting (
			CustomerId, 
			UserId, 
			IsAutoSelectParagraph,
			IsAutoSelectForImport,
			IsIncludeSubparagraph,
			IsAlwaysAllowAddPara,
			IsMultipleFilesForExport,
			IsTCNotifyAccepted,
			IncludeAuthorInFileNames,
			IsIncludeManufacturerParagraph
		 )VALUES (
			  @PCustomerId, 
			  @PUserId,
			  @PIsAutoSelectParagraph,
			  @PIsAutoSelectForImport,
			  @PIsIncludeSubparagraph,
			  @PIsAlwaysAllowAddPara,
			  @PIsMultipleFilesForExport,
			  @PIsTCNotifyAccepted,
			  @PIncludeAuthorInFileNames,
			  @PIsIncludeManufacturerParagraph
		  )
	 END        
	ELSE        
		 BEGIN        
			  UPDATE CGS        
			  SET CGS.IsAutoSelectParagraph = COALESCE(@PIsAutoSelectParagraph, CGS.IsAutoSelectParagraph)        
				 ,CGS.IsAutoSelectForImport = COALESCE(@PIsAutoSelectForImport, CGS.IsAutoSelectForImport)        
				 ,CGS.IsIncludeSubparagraph = COALESCE(@PIsIncludeSubparagraph, CGS.IsIncludeSubparagraph)        
				 ,CGS.IsAlwaysAllowAddPara = COALESCE(@PIsAlwaysAllowAddPara, CGS.IsAlwaysAllowAddPara)        
				 ,CGS.IsMultipleFilesForExport = COALESCE(@PIsMultipleFilesForExport, CGS.IsMultipleFilesForExport)       
				 ,CGS.IsTCNotifyAccepted = COALESCE(@PIsTCNotifyAccepted, CGS.IsTCNotifyAccepted)         
				 ,CGS.IncludeAuthorInFileNames = COALESCE(@PIncludeAuthorInFileNames, CGS.IncludeAuthorInFileNames)     
				 ,CGS.IsIncludeManufacturerParagraph = COALESCE(@PIsIncludeManufacturerParagraph, CGS.IsIncludeManufacturerParagraph)     
			  FROM CustomerGlobalSetting CGS WITH(NOLOCK)        
			  WHERE CustomerId = @PCustomerId        
			  AND UserId = @PUserId        
		 END        
END 