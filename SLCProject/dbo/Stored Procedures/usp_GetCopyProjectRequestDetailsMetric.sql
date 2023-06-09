CREATE PROC usp_GetCopyProjectRequestDetailsMetric    
AS    
BEGIN    
 SELECT   
 (SELECT COUNT(1) FROM CopyProjectRequest WITH(NOLOCK) WHERE  CopyProjectTypeId=1 AND IsDeleted=0) AS TotalRequests,  
 (SELECT COUNT(1) FROM CopyProjectRequest WITH(NOLOCK) WHERE  CopyProjectTypeId=1 AND IsDeleted=0 AND StatusId=1) AS QueuedRequests,  
 (SELECT COUNT(1) FROM CopyProjectRequest WITH(NOLOCK) WHERE  CopyProjectTypeId=1 AND IsDeleted=0 AND StatusId=2) AS RunningRequests,  
 (SELECT COUNT(1) FROM CopyProjectRequest WITH(NOLOCK) WHERE  CopyProjectTypeId=1 AND IsDeleted=0 AND StatusId=3) AS ProcessedRequests,  
 (SELECT COUNT(1) FROM CopyProjectRequest WITH(NOLOCK) WHERE  CopyProjectTypeId=1 AND IsDeleted=0 AND StatusId IN(4,5))  AS FailedRequests,  
 '' AS JsonResponse  
END