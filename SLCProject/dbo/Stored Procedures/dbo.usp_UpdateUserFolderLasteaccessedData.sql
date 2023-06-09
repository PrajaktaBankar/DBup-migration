CREATE PROCEDURE [dbo].[usp_UpdateUserFolderLasteaccessedData]    
 @ProjectId	INT ,
 @UserId INT ,
 @UserName nvarchar(500)
  AS
BEGIN
 DECLARE @PProjectId INT = @ProjectId;
 DECLARE @PUserId INT = @UserId;
 DECLARE @PUserName nvarchar(500) = @UserName;
UPDATE UF
SET UF.LastAccessed = GETUTCDATE(), UF.UserId = @UserId
   ,UF.LastAccessByFullName = @PUserName
FROM UserFolder UF WITH (NOLOCK)
WHERE UF.ProjectId = @PProjectId
END
GO