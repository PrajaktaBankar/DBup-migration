CREATE PROCEDURE [dbo].[usp_UpdateLastAccessedOfProject] 
(
	@ProjectId int,
	@UserId int,
	@UserName NVARCHAR(500) = 'NA'
)
AS  
BEGIN
  
	DECLARE @PProjectId int = @ProjectId;
	DECLARE @PUserId int = @UserId;
	DECLARE @PUserName NVARCHAR(500) = @UserName;
	DECLARE @userFolderId INT = 0
  
  -- Commented merge statements as it locks the pages before update
      --MERGE UserFolder AS TARGET  
      --USING UserFolder  AS SOURCE   
      --ON (TARGET.ProjectId = SOURCE.ProjectId and TARGET.ProjectId=@PProjectId)
      --WHEN MATCHED  
      --THEN   
      --UPDATE SET TARGET.LastAccessed=GETUTCDATE(),TARGET.UserId=@PUserId,TARGET.LastAccessByFullName=@PUserName;
    

	SET @userFolderId = (SELECT userfolderId FROM UserFolder with (nolock) WHERE ProjectId=@ProjectId);
  
	 IF (@userFolderId > 0)  
	 BEGIN  
	 if(@UserName=null)  
	 set @UserName='NA'  
  
	 UPDATE UF 
	 set LastAccessed=GETUTCDATE(), UserId=@UserId ,LastAccessByFullName=@UserName  
	 from UserFolder UF WITH (NOLOCK)
	 WHERE UF.UserFolderId = @userFolderId
	 END  
	 

  
END
  
  


GO
