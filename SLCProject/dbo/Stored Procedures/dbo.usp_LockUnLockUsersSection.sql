CREATE PROCEDURE [dbo].[usp_LockUnLockUsersSection]                 
@ProjectId INT NULL,                   
@CustomerId INT NULL,                  
@UserId INT NULL=NULL,                   
@SectionId INT NULL=NULL,                  
@UserName VARCHAR (50) NULL=NULL,          
@IsSystemManager BIT=0 ,        
@IsLockedSectionOpen BIT=0,        
@IsSharedProject BIT=0,    
@LastSectionId INT=0  ,    
@IsSectionAccessible BIT=0,    
@OpenInNewTab BIT=0    
AS                  
BEGIN              
                 
DECLARE @PProjectId INT = @ProjectId;                
DECLARE @PCustomerId INT = @CustomerId;                
DECLARE @PUserId INT = @UserId;                
DECLARE @PSectionId INT = @SectionId;                
DECLARE @PUserName VARCHAR (50) = @UserName;              
DECLARE @IsUnlockSectionBySM BIT =0;          
DECLARE @LockedByFullName VARCHAR (50) = NULL;                  
DECLARE @IsLocked BIT = 0;    
DECLARE @IsLockedImportSection BIT = 0;         
DECLARE @PLastSectionId INT = @LastSectionId;    
DECLARE @PIsSectionAccessible BIT=@IsSectionAccessible;    
DECLARE @LockedBy INT=0;    
DECLARE @POpenInNewTab BIT=@OpenInNewTab;   
DECLARE @IsDeleted BIT= 0
DECLARE @MSectionId INT=0
DECLARE @CurrentSectionId INT=0
-- check if target section is already locked                  
SELECT Top 1 @LockedByFullName=LockedByFullName,@IsDeleted=IsDeleted,@MSectionId=mSectionId, @IsLocked= IIF(LockedBy <> @PUserId AND IsLocked = 1, 1, 0), @IsLockedImportSection=IsLockedImportSection,@LockedBy=LockedBy             
FROM [projectSection] WITH (NOLOCK) WHERE SectionId = @PSectionId OPTION (FAST 1)              
          
if(@IsLocked = 1 and @IsSystemManager = 1)                    
begin          
SET @IsUnlockSectionBySM = 1          
end           
         
IF(@PLastSectionId!=0 and @PLastSectionId!=@PSectionId and @POpenInNewTab=0)       
BEGIN    
 ---- Release lock if last section is locked earlier                  
  UPDATE PS                
  SET IsLocked = 0                
     ,LockedBy = 0                
     ,LockedByFullName = ''                
  FROM ProjectSection PS WITH (NOLOCK)                
  WHERE  SectionId=@PLastSectionId    
  AND ProjectId = @PProjectId                
  AND CustomerId = @PCustomerId                
  AND LockedBy = @PUserId              
  AND IsLastLevel = 1      
  AND IsLocked = 1;     
END    
    
IF(@PSectionId!=0 and @PIsSectionAccessible=1)    
BEGIN    
IF(@IsLocked=0 or (@IsLocked = 1 and @IsSystemManager = 1 and @IsLockedSectionOpen=1 and @IsSharedProject=0))                    
 BEGIN                
 ---- Release lock if any section is locked earlier                  
 -- UPDATE PS                
 -- SET IsLocked = 0                
 --    ,LockedBy = 0                
 --    ,LockedByFullName = ''                
 -- FROM ProjectSection PS WITH (NOLOCK)                
 -- WHERE ProjectId = @PProjectId                
 -- AND CustomerId = @PCustomerId                
 -- AND LockedBy = @PUserId              
 -- AND IsLastLevel = 1              
 -- AND IsLocked = 1;              
                
  UPDATE PS                
  SET IsLocked = 1                
     ,LockedBy = @PUserId                
     ,LockedByFullName = @PUserName                
     ,ModifiedBy = @PUserId                
     ,ModifiedDate = GETUTCDATE()                
  FROM ProjectSection PS WITH (NOLOCK)                
  WHERE SectionId = @PSectionId;         
               
            
 END                
ELSE              
 BEGIN                
  SET @IsLocked = 1;              
 END        
END          
    
IF(@IsDeleted=1)
BEGIN
Select @CurrentSectionId=SectionId from ProjectSection where ProjectId=@ProjectId and CustomerId=@CustomerId and mSectionId=@MSectionId
END	      
-- Select section lock info              
SELECT @IsLocked AS IsLocked,@IsLockedImportSection AS IsLockedImportSection, @IsUnlockSectionBySM AS IsUnlockSectionBySM , @LockedByFullName AS LockedByFullName ,@LockedBy  AS LockedBy ,@IsDeleted AS IsDeleted, @CurrentSectionId AS CurrentSectionId
              
END 