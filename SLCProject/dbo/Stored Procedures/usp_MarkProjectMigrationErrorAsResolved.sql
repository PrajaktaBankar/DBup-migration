       
CREATE PROCEDURE usp_MarkProjectMigrationErrorAsResolved            
(            
 @MigrationExceptionId INT,           
 @UserId INT            
)            
AS            
BEGIN 

DECLARE @PMigrationExceptionId INT = @MigrationExceptionId;      
DECLARE @PUserId INT =@UserId;

 UPDATE p            
 set p.IsResolved=1,          
     p.ModifiedBy = @PUserId,        
 p.ModifiedDate = GETUTCDATE()          
 from ProjectMigrationException p WITH(NOLOCK)            
 where p.MigrationExceptionId=@PMigrationExceptionId;           
END