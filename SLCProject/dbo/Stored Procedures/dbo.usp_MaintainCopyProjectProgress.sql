CREATE PROCEDURE [dbo].[usp_MaintainCopyProjectProgress]    
@SourceProjectId INT,    
@TargetProjectId INT,    
@CreatedById INT,    
@CustomerId INT,    
@Status INT,    
@CompletedPercentage FLOAT,    
@IsInsertRecord BIT  ,  
@CustomerName NVARCHAR(200),  
@UserName NVARCHAR(200)  
AS    
BEGIN    
IF @IsInsertRecord = 1    
BEGIN    
INSERT INTO CopyProjectRequest (SourceProjectId,    
TargetProjectId,    
CreatedById,    
CustomerId,    
CreatedDate,    
ModifiedDate,    
[StatusId],    
CompletedPercentage,    
IsNotify,    
IsDeleted,  
IsEmailSent,  
CustomerName,  
UserName,CopyProjectTypeId)    
 VALUES (@SourceProjectId,   
 @TargetProjectId,   
 @CreatedById,   
 @CustomerId,   
 GETUTCDATE(),   
 NULL,   
 @Status,   
 @CompletedPercentage,  
 0,  
 0,  
 0,  
 @CustomerName,  
 @UserName,
 1);    
END    
ELSE    
BEGIN    
UPDATE CPR    
SET CPR.[StatusId] = @Status    
   ,CompletedPercentage = @CompletedPercentage    
   ,IsNotify=0    
FROM CopyProjectRequest CPR WITH (NOLOCK)    
WHERE CPR.TargetProjectId = @TargetProjectId    
AND CPR.CustomerId = @CustomerId    
END    
END