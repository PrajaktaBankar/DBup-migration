CREATE PROC [dbo].[usp_GetImportRequest]        
(            
 @CustomerId INT,            
 @UserId INT             
)            
AS            
BEGIN            
 DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())          
         
 SELECT           
 CPR.RequestId          
,CPR.TargetProjectId  AS ProjectId       
,CPR.TargetSectionId  AS SectionId      
,PS.[Description] AS [TaskName]      
,CPR.CreatedById  As UserId        
,CPR.CustomerId          
,CPR.CreatedDate AS RequestDateTime         
,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr
,DATEADD(DAY,30,CPR.CreatedDate) AS RequestExpiryDateTime          
,ISNULL(CPR.ModifiedDate,'') as ModifiedDate          
,CPR.StatusId          
,CPR.IsNotify          
,CPR.CompletedPercentage       
,LCS.Name as StatusDescription
,CPR.Source
 FROM ImportProjectRequest CPR WITH(NOLOCK)         
   INNER JOIN LuCopyStatus LCS  WITH(NOLOCK)        
   ON LCS.CopyStatusId=CPR.StatusId           
   INNER JOIN ProjectSection PS WITH(NOLOCK)      
   ON PS.SectionId=CPR.TargetSectionId      
 WHERE CPR.CreatedById=@UserId AND Source IN('SpecAPI','Import from Template')     
  AND isnull(CPR.IsDeleted,0)=0       
 AND CPR.CreatedDate> @DateBefore30Days           
 ORDER by CPR.CreatedDate DESC            
END