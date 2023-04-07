CREATE PROCEDURE [dbo].[usp_LockUnlockTrackChanges]  
( 
 @SectionId int,
 @IsTrackChanges bit,  
 @IsTrackChangeLock bit,    
 @UserId int = 0
)
AS    
BEGIN
    
	UPDATE PS  
	SET PS.IsTrackChanges = @IsTrackChanges,
		PS.IsTrackChangeLock = @IsTrackChangeLock,
	    PS.TrackChangeLockedBy = @UserId
	FROM ProjectSection PS WITH (NOLOCK)  
	WHERE PS.SectionId = @SectionId
  
	SELECT IsTrackChanges  
		   ,IsTrackChangeLock  
		   ,COALESCE(TrackChangeLockedBy, 0) AS TrackChangeLockedBy  
	FROM ProjectSection WITH (NOLOCK)  
	WHERE SectionId = @SectionId 
  
END