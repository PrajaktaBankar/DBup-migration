CREATE PROCEDURE usp_RejectTransferProject  
(  
 @ProjectId INT,  
 @UserId INT,  
 @CustomerId INT  
)  
AS  
BEGIN  
   
 UPDATE P  
 SET P.IsDeleted = 1, P.IsPermanentDeleted = 1,  
 P.ModifiedBy=@UserId,  
 P.ModifiedDate=GETUTCDATE()  
 FROM Project P WITH(NOLOCK)  
 WHERE P.ProjectId =  @ProjectId;  
  
 DECLARE @TransferredRequestId INT =0  
    SELECT  @TransferredRequestId=TransferRequestId  FROM CopyProjectRequest WITH(NOLOCK) WHERE  TargetProjectId=@ProjectId  
 INSERT INTO IncomingProjectHistory VALUES (@ProjectId,'REJECTES',@UserId,@CustomerId,GETUTCDATE(),@TransferredRequestId)  
END  
  