CREATE PROCEDURE [dbo].[usp_MaintainImportProjectProgress]            
@SourceProjectId INT,                      
@TargetProjectId INT,                  
@SourceSectiontId int,            
@TargetSectionId int,                
@CreatedById INT,                      
@CustomerId INT,                      
@Status TINYINT,                      
@CompletedPercentage TINYINT,                      
@IsInsertRecord BIT,            
@Source nvarchar(200),               
@RequestId int            
AS                      
BEGIN            
IF @IsInsertRecord = 1                      
BEGIN                      
INSERT INTO ImportProjectRequest (SourceProjectId,                      
TargetProjectId,                    
SourceSectionId,                
TargetSectionId,                
CreatedById,                      
CustomerId,                      
CreatedDate,                      
ModifiedDate,                      
[StatusId],                      
CompletedPercentage,              
Source,            
IsNotify)                   
                
 VALUES (@SourceProjectId,                     
 @TargetProjectId,                  
 @SourceSectiontId, @TargetSectionId,                
 @CreatedById,                     
 @CustomerId,                
 GETUTCDATE(),                 
 NULL,                
 @Status,                     
 @CompletedPercentage,            
 @Source,                
0);                      
END                      
ELSE                      
BEGIN                      
UPDATE IPR                      
SET IPR.[StatusId] = @Status                      
   ,CompletedPercentage = @CompletedPercentage,  
   IPR.TargetSectionId= isnull(IPR.TargetSectionId, @TargetSectionId)                
 ,IsNotify=0                 
FROM ImportProjectRequest IPR WITH (NOLOCK)                      
WHERE IPR.RequestId = @RequestId;              
END                      
END       
    
  