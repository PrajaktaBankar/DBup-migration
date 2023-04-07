CREATE PROC usp_UnArchiveProject  
(  
 @CustomerId INT,  
 @ArchiveProjectId INT,  
 @UserId INT,  
 @ModifiedByFullName NVARCHAR(50)=''  
)  
AS  
BEGIN  
  
 UPDATE P  
 SET P.IsArchived=0
	 --P.IsShowMigrationPopup=0
 FROM Project P WITH(NOLOCK)  
 WHERE P.ProjectId=@ArchiveProjectId  AND P.CustomerId=@CustomerId
  
 UPDATE UF  
 SET UF.UserId=@UserId,  
  UF.LastAccessed=GETUTCDATE(),  
  LastAccessByFullName=@ModifiedByFullName  
 FROM UserFolder UF WITH(NOLOCK)  
 WHERE UF.ProjectId=@ArchiveProjectId  
 AND UF.CustomerId=@CustomerId
END