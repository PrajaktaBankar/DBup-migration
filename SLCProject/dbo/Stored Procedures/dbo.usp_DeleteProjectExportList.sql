CREATE PROCEDURE usp_DeleteProjectExportList               
(                
@ProjectExportId INT,                
@ModifiedBy INT,            
@ModifiedByFullName NVARCHAR(100),          
@CustomerId INT,
@ProjectExportFlag BIT          
)                
AS                
BEGIN   
         
    IF(@ProjectExportFlag=0)
	BEGIN        
        UPDATE PE            
        SET PE.IsDeleted = 1            
           ,PE.ModifiedDate = GETUTCDATE()            
           ,PE.ModifiedBy = @ModifiedBy            
           ,ModifiedByFullName = @ModifiedByFullName            
        FROM ProjectExport PE WITH (NOLOCK)            
        WHERE PE.ProjectExportId = @ProjectExportId            
        AND PE.CustomerId=@CustomerId  
    END
    ELSE IF(@ProjectExportFlag=1)
	 BEGIN
        UPDATE PD
        SET   PD.IsDeleted=1
             ,PD.ModifiedDate=GETUTCDATE()
        	   ,PD.ModifiedBy = @ModifiedBy
        FROM PrintRequestDetails PD WITH(NOLOCK)
        WHERE PD.PrintRequestId=@ProjectExportId AND PD.CustomerId=@CustomerId
     END
            
END  

