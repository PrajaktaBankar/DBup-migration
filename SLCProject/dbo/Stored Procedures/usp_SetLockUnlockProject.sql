CREATE PROCEDURE [dbo].[usp_SetLockUnlockProject]                                         
  @ProjectId INT           
 ,@UserId INT        
 ,@IsLocked BIT = 0        
 ,@LockedBy NVARCHAR(500)      
 
                                       
AS                                        
BEGIN                                      
                                      
  DECLARE @PProjectId INT = @ProjectId;       
  DECLARE @PUserId INT = @UserId;                                      
  DECLARE @PIsLocked BIT = @IsLocked;                                      
  DECLARE @PLockedBy NVARCHAR(500) = @LockedBy;                                      
                            
     
 UPDATE P       
 SET p.IsLocked = @PIsLocked ,      
 P.ModifiedBy = @UserId,      
 p.ModifiedDate = GETUTCDATE(),      
 p.LockedBy = @PLockedBy,      
 p.LockedDate = GETUTCDATE()      
 from project P with(NOLOCK)        
 WHERE ProjectId = @PProjectId;          
END;