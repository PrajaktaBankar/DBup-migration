CREATE procedure usp_updatePrintRequestDetails    
(  
@PrintRequestId int,  
@PrintStatus NVARCHAR(20),  
@ModifiedBy int  
)    
AS    
BEGIN    
   
 UPDATE PRD   
 SET PRD.PrintStatus = @PrintStatus,  
 PRD.ModifiedDate = GETUTCDATE(),  
 PRD.ModifiedBy = @ModifiedBy  
 from PrintRequestDetails PRD WITH(NOLOCK)  
 WHERE PRD.PrintRequestId = @PrintRequestId;  
  
END