CREATE PROCEDURE usp_ArchiveMigratedProject  
(  
 @CustomerId INT,  
 @IsOfficeMaster BIT=0,  
 @ArchiveProjectId INT,  
 @UserId INT,  
 @ModifiedByFullName NVARCHAR(50)=''  
)  
AS  
BEGIN  
  
 UPDATE P  
 SET P.IsArchived=1  
 FROM Project P WITH(NOLOCK)  
 WHERE P.ProjectId=@ArchiveProjectId  
  
 UPDATE UF  
 SET UF.UserId=@UserId,  
  UF.LastAccessed=GETUTCDATE(),  
  LastAccessByFullName=@ModifiedByFullName  
 FROM UserFolder UF WITH(NOLOCK)  
 WHERE UF.ProjectId=@ArchiveProjectId  
END