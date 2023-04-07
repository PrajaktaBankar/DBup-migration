CREATE PROCEDURE [dbo].[usp_ProjectLevelTrackChangesLogging](
@UserId INT NULL,  
@ProjectId INT NULL,  
@CustomerId INT NULL,  
@UserEmail  NVARCHAR(100) ='NA',  
@PriviousTrackChangeModeId INT NULL ,
@CurrentTrackChangeModeId INT NULL 
)
AS 
BEGIN
DECLARE @PPriviousTrackChangeModeId INT = CASE WHEN ISNULL(@PriviousTrackChangeModeId,0) = 0 OR @PriviousTrackChangeModeId = 0 THEN 3 ELSE @PriviousTrackChangeModeId END;
DECLARE @P@CurrentTrackChangeModeId INT = CASE WHEN ISNULL(@CurrentTrackChangeModeId,0) = 0 OR @CurrentTrackChangeModeId = 0 THEN 3 ELSE @CurrentTrackChangeModeId END;

INSERT INTO ProjectLevelTrackChangesLogging ( UserId  
, ProjectId  
, CustomerId  
, UserEmail  
, PriviousTrackChangeModeId  
, CurrentTrackChangeModeId  
, CreatedDate  
)  
 VALUES ( @UserId,@ProjectId, @CustomerId, @UserEmail,@PPriviousTrackChangeModeId,@P@CurrentTrackChangeModeId,GETUTCDATE() )  
END  
