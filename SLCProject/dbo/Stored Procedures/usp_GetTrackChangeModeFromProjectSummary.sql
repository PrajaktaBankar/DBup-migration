CREATE PROCEDURE usp_GetTrackChangeModeFromProjectSummary
(      
 @ProjectId  int,    
 @CustomerId int   
)      
AS      
BEGIN  
  
 DECLARE @TcModeBySection TINYINT = 3;  
 SELECT ISNULL(TrackChangesModeId, @TcModeBySection) AS TrackChangesModeId   
 FROM ProjectSummary WITH(NOLOCK) WHERE ProjectId = @ProjectId and CustomerId = @CustomerId;  
  
END