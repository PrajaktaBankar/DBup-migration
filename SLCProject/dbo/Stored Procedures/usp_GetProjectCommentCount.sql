
CREATE PROCEDURE [dbo].[usp_GetProjectCommentCount]  
(  
 @TenantProjectList NVARCHAR(MAX) NULL = NULL  
)  
AS  
BEGIN  
 DROP TABLE IF EXISTS #ProjectCommentCount;  
 DROP TABLE IF EXISTS #TenantProjectTable;  
  
  SELECT *   
  INTO #TenantProjectTable  
  FROM    
  OPENJSON ( @TenantProjectList )    
  WITH (     
  TenantName VARCHAR(200) '$.TenantName' ,    
  SharedProjectId INT '$.SharedProjectId',    
  SharedToUserId INT '$.SharedToUserId',    
  SharedToCustomerId INT '$.SharedToCustomerId',  
  SharedByCustomerId INT '$.SharedByCustomerId',  
  CommentCount INT '$.CommentCount'    
  )  
  
  DECLARE @OpenCommentStatusId INT = 1;  

  SELECT SC.ProjectId, COUNT(SC.SectionId) AS ProjectCommentCount  
  INTO #ProjectCommentCount 
  FROM #TenantProjectTable TPT  
  LEFT JOIN SegmentComment SC WITH (NOLOCK) ON SC.ProjectId = TPT.SharedProjectId  
  WHERE SC.CommentStatusId=@OpenCommentStatusId AND SC.ParentCommentId= 0 AND ISNULL(SC.IsDeleted, 0) = 0     
  GROUP BY SC.ProjectId
  
  UPDATE TPT
  SET TPT.CommentCount = PCC.ProjectCommentCount
  FROM #TenantProjectTable TPT
  INNER JOIN #ProjectCommentCount PCC ON TPT.SharedProjectId = PCC.ProjectId
  
  SELECT * FROM #TenantProjectTable TPT  

 END     

  
 