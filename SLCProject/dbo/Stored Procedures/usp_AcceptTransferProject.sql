CREATE PROCEDURE usp_AcceptTransferProject        
(        
 @ProjectId INT,    
 @UserId INT=0,    
 @CustomerId INT,  
 @ModifiedByFullName NVARCHAR(500)    
)        
AS        
BEGIN        
         
DECLARE @PProjectId INT=@ProjectId;    
DECLARE @PUserId INT=@UserId;    
DECLARE @PModifiedByFullName NVARCHAR(500)=@ModifiedByFullName;    
    
 UPDATE P        
 SET P.IsIncomingProject = 0,    
 P.ModifiedBy=@PUserId,    
 P.ModifiedByFullName=@PModifiedByFullName,    
 P.CreateDate=GETUTCDATE()    
 FROM Project P WITH(NOLOCK)        
 WHERE P.ProjectId =  @PProjectId;        
        
 UPDATE UF       
 SET UF.LastAccessed=GETUTCDATE()  ,    
 UF.UserId=@PUserId,    
 UF.LastAccessByFullName=@PModifiedByFullName    
 FROM UserFolder UF WITH(NOLOCK)       
 where UF.ProjectId=@PProjectId      
  
 DECLARE @TransferredRequestId INT =0  
 SELECT  @TransferredRequestId=TransferRequestId  FROM CopyProjectRequest  WITH(NOLOCK) WHERE  TargetProjectId=@PProjectId  
 INSERT INTO IncomingProjectHistory VALUES (@ProjectId,'ACCEPTED',@UserId,@CustomerId,GETUTCDATE(),@TransferredRequestId)  
END        