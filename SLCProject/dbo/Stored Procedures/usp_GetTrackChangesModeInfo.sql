CREATE PROCEDURE usp_GetTrackChangesModeInfo
(    
 @ProjectId INT,  
 @SectionId INT
)    
AS    
BEGIN

	DECLARE @TcModeBySection TINYINT = 3;
	SELECT TOP 1 @TcModeBySection = ISNULL(TrackChangesModeId, @TcModeBySection)
	FROM ProjectSummary WITH(NOLOCK) WHERE ProjectId = @ProjectId
	OPTION (FAST 1);

	SELECT 
	 @TcModeBySection AS TrackChangesModeId
	,IsTrackChanges
	,IsTrackChangeLock  
	,COALESCE(TrackChangeLockedBy, 0) AS TrackChangeLockedBy
	FROM ProjectSection WITH(NOLOCK)  
	WHERE SectionId = @SectionId;

END