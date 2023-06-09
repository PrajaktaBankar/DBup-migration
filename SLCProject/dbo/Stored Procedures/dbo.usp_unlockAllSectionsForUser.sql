
CREATE PROCEDURE [dbo].[usp_UnlockAllSectionsForUser]    
(  
 @ProjectId int,
 @UserId int
)    
AS        
BEGIN  
DECLARE @PProjectId int = @ProjectId;  
DECLARE @PUserId int = @UserId;  
UPDATE PS  
SET PS.IsLocked = 0  
   ,PS.LockedBy = 0  
   ,PS.LockedByFullName = ''  
FROM ProjectSection PS WITH (NOLOCK)  
WHERE PS.ProjectId = @PProjectId and PS.ModifiedBy=@PUserId and PS.IsLocked=1
END  
GO