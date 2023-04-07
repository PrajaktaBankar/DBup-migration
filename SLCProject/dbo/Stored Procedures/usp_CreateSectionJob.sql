CREATE PROCEDURE [dbo].[usp_CreateSectionJob]   
AS  
BEGIN  
 --Check for Expiry  
 update r
 set r.StatusId=5,
	r.IsNotify=0
 FROM ImportProjectRequest r WITH(nolock) 
 WHERE r.StatusId=2 and 
 r.Source='Import from Template' 
 and isnull(r.IsDeleted,0)=0
 and DATEADD(Minute,-5,GETUTCDATE())>r.ModifiedDate

 IF(NOT EXISTS(SELECT TOP 1 1 FROM ImportProjectRequest WITH(nolock) WHERE StatusId=2 and Source='Import from Template' and isnull(IsDeleted,0)=0))  
 BEGIN  
  DECLARE @RequestId INT      
   
  SELECT TOP 1  
   @RequestId=RequestId  
  FROM ImportProjectRequest WITH(nolock)   
  WHERE StatusId=1 AND ISNULL(IsDeleted,0)=0  
  AND Source='Import from Template' 
  ORDER BY CreatedDate ASC  
  
  IF(@RequestId>0)  
  BEGIN  
   EXEC usp_CreateSectionFromMasterTemplate_Job @RequestId  
  END  
 END  
END