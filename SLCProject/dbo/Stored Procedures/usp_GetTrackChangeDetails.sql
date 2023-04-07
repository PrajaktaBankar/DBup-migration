CREATE PROCEDURE [dbo].[usp_GetTrackChangeDetails] -- [Obsolete]
(    
 @ProjectId  int,  
 @SectionId int,  
 @CustomerId int,  
 @UserId int = null
)    
AS    
BEGIN

	DECLARE @TcModeBySection TINYINT = 3;
	SELECT ISNULL(TrackChangesModeId, @TcModeBySection) AS TrackChangesModeId 
	FROM ProjectSummary WITH(NOLOCK) WHERE ProjectId = @ProjectId;

	SELECT  
	 IsTrackChanges  
	,IsTrackChangeLock  
	,COALESCE(TrackChangeLockedBy, 0) AS TrackChangeLockedBy
	FROM ProjectSection WITH(NOLOCK)  
	WHERE ProjectId = @ProjectId  
	AND SectionId = @SectionId  
	AND CustomerId = @CustomerId

END