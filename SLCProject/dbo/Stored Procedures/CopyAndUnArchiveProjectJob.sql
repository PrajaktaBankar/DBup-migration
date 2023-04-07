CREATE PROCEDURE [dbo].[CopyAndUnArchiveProjectJob]  
AS  
BEGIN  
   
    --find and mark as failed copy project requests which running loner(more than 30 mins)  
    EXEC [dbo].[usp_UpdateCopyProjectStepProgress]  
  
 EXEC [dbo].[usp_SendEmailCopyProjectFailedJob]  
  
 IF(NOT EXISTS(SELECT TOP 1 1 FROM [dbo].CopyProjectRequest WITH(nolock) WHERE StatusId=2 AND CopyProjectTypeId=1))  
 BEGIN  
  DECLARE @SourceProjectId INT;  
  DECLARE @TargetProjectId INT;  
  DECLARE @CustomerId INT;  
  DECLARE @UserId INT;  
  DECLARe @RequestId INt;  
   
  SELECT TOP 1  
   @SourceProjectId = SourceProjectId  
     ,@TargetProjectId = TargetProjectId  
     ,@CustomerId = CustomerId  
     ,@UserId = CreatedById  
     ,@RequestId = RequestId  
  FROM [dbo].[CopyProjectRequest] WITH(nolock)   
  WHERE StatusId=1 AND ISNULL(IsDeleted,0)=0  
   AND CopyProjectTypeId=1
  ORDER BY CreatedDate ASC  
  
  IF(@TargetProjectId>0)  
  BEGIN  
   EXEC [dbo].[usp_CopyProject] @SourceProjectId  
       ,@TargetProjectId  
       ,@CustomerId  
       ,@UserId  
       ,@RequestId  
  END  
 END  
  
 IF(NOT EXISTS(SELECT TOP 1 1 FROM [dbo].CopyProjectRequest WITH(nolock) WHERE StatusId=2  AND CopyProjectTypeId=1))  
 BEGIN  
  EXECUTE [dbo].[sp_UnArchiveProject]  
 END  
  
END  