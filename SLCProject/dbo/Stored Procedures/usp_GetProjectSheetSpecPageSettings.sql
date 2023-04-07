    
CREATE PROCEDURE [dbo].[usp_GetProjectSheetSpecPageSettings]          
(    
@ProjectId INT ,    
@CustomerId INT     
)              
AS            
BEGIN        
    
DECLARE  @PProjectId INT =@ProjectId;    
DECLARE  @CCustomerId INT =@CustomerId;    
        
        
   SELECT PaperSettingKey,ProjectId,CustomerId,Name,Value,CreatedDate,CreatedBy,ModifiedDate,ModifiedBy,IsActive,IsDeleted FROM SheetSpecsPageSettings WITH(NOLOCK)    
        WHERE ProjectId = @PProjectId and CustomerId = @CCustomerId     
END      
    
    