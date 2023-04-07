CREATE PROCEDURE [dbo].[usp_SectionLevelTrackChangesLogging](
@UserId INT NULL,  
@ProjectId INT NULL,  
@CustomerId INT NULL,  
@UserEmail  NVARCHAR(100) NULL,   
@SectionId Int=NULL,
@IsTrackChanges BIT=1,
@IsTrackChangeLock BIT=0
)
AS 
BEGIN
INSERT INTO SectionLevelTrackChangesLogging ( UserId
, ProjectId
, SectionId
, CustomerId
, UserEmail
, IsTrackChanges
, IsTrackChangeLock
, CreatedDate
)
	VALUES ( @UserId,@ProjectId, @SectionId,@CustomerId,@UserEmail, @IsTrackChanges,@IsTrackChangeLock, GETUTCDATE() )
END
