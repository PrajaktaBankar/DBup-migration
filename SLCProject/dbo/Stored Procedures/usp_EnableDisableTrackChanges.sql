CREATE PROCEDURE  [dbo].[usp_EnableDisableTrackChanges]
(  
 @ProjectId  int,
 @SectionId int,
 @CustomerId int,
 @UserId int,
 @IsTrackChanges bit
)
AS  
BEGIN  
	DECLARE @IsLocked BIT;
	SET @IsLocked = (SELECT
		COUNT(1) AS TrackChangeLockedBy
	FROM [ProjectSection] PS WITH (NOLOCK)
	WHERE PS.SectionId = @SectionId
	AND PS.IsTrackChangeLock = 1)

	IF(@IsLocked=1 and @IsTrackChanges=1)
	BEGIN
		UPDATE PS SET PS.IsTrackChanges = @IsTrackChanges
		FROM ProjectSection PS WITH(NOLOCK) WHERE PS.SectionId = @SectionId
	END

	IF(@IsLocked=0)
	BEGIN
		UPDATE PS  SET PS.IsTrackChanges =@IsTrackChanges
		FROM ProjectSection PS WITH(NOLOCK) WHERE PS.SectionId=@SectionId
	END

	SELECT IsTrackChanges,PS.IsTrackChangeLock ,COALESCE(PS.TrackChangeLockedBy,0)AS TrackChangeLockedBy
	FROM ProjectSection PS WITH(NOLOCK) WHERE PS.SectionId=@SectionId

END