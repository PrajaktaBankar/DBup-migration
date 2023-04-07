CREATE PROCEDURE [dbo].[usp_UpdateStatusExportedFile]                
(         
@ProjectExportId INT = 0,                      
@ProjectId INT,                  
@CustomerId INT            
)          
AS                  
BEGIN          
If EXISTS(select TOP 1 1 FROM PrintRequestDetails WITH (NOLOCK) WHERE PrintRequestId = @ProjectExportId)        
BEGIN         
 UPDATE PRD          
 SET PRD.PrintStatus = 'Canceled',          
 ModifiedDate = GETUTCDATE()          
 FROM PrintRequestDetails PRD WITH (NOLOCK)          
 WHERE PRD.PrintRequestId =@ProjectExportId and PRD.ProjectId= @ProjectId and PRD.CustomerId= @CustomerId  and PRD.PrintStatus!='Success'       
        
 END        
 ELSE        
 BEGIN        
        
  UPDATE PE          
 SET PE.FileStatus = 'Canceled',          
 ModifiedDate = GETUTCDATE()          
 FROM ProjectExport PE WITH (NOLOCK)          
 WHERE PE.ProjectExportId =@ProjectExportId  and PE.ProjectId= @ProjectId and PE.CustomerId= @CustomerId and PE.FileStatus!='Completed'          
        
 END        
END