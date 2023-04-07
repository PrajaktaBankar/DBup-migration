CREATE PROC [dbo].[usp_GetCopyProjectRequest]    
(    
 @CustomerId INT,    
 @UserId INT,    
 @IsSystemManager BIT=0    
)    
AS    
BEGIN    
 DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())    
 SELECT   
 CPR.RequestId  
,CPR.SourceProjectId  
,CPR.TargetProjectId  
,CPR.CreatedById  
,CPR.CustomerId  
,CPR.CreatedDate  
,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr
,DATEADD(DAY,30,CPR.CreatedDate) AS RequestExpiryDateTime  
,ISNULL(CPR.ModifiedDate,'') as ModifiedDate  
,CPR.StatusId  
,CPR.IsNotify  
,CPR.CompletedPercentage  
,CPR.IsDeleted  
,P.[Name]  
,LCS.Name as StatusDescription  
 FROM CopyProjectRequest CPR WITH(NOLOCK)    
  INNER JOIN Project P WITH(NOLOCK)    
   ON P.ProjectId = CPR.TargetProjectId   
   INNER JOIN LuCopyStatus LCS  WITH(NOLOCK)
   ON LCS.CopyStatusId=CPR.StatusId   
 WHERE CPR.CreatedById=@UserId  
 AND isnull(CPR.IsDeleted,0)=0    
 AND CPR.CreatedDate> @DateBefore30Days   
  AND CPR.CopyProjectTypeId=1
 ORDER by CPR.CreatedDate DESC    
END    


  