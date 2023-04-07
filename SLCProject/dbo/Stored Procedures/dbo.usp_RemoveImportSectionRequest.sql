CREATE PROC usp_RemoveImportSectionRequest --221   
(    
 @RequestId INT    
)    
AS    
BEGIN    
 UPDATE CPR    
 SET CPR.IsDeleted=1 
 ,CPR.IsNotify=1
 ,ModifiedDate=GETUTCDATE()    
 FROM ImportProjectRequest CPR WITH(NOLOCK)    
 WHERE CPR.StatusId!=2 AND CPR.RequestId=@RequestId    
END  
