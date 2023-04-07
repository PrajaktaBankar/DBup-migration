CREATE PROCEDURE [dbo].[usp_CheckLockedSection]
@UserId INT NULL=NULL,             
@SectionId INT NULL=NULL,
@ProjectId INT Null=Null,
@CustomerId INT Null=NULL
AS            
BEGIN 
DECLARE @PProjectId INT = @ProjectId;          
DECLARE @PCustomerId INT = @CustomerId;              
DECLARE @PUserId INT = @UserId;          
DECLARE @PSectionId INT = @SectionId; 
DECLARE @IsLocked BIT = 0;
  
-- check if target section is already locked            
SELECT Top 1 @IsLocked= IIF(LockedBy <> @PUserId AND IsLocked = 1, 1, 0)    
FROM [projectSection] WITH (NOLOCK) WHERE SectionId = @PSectionId OPTION (FAST 1)  

 ---- Release lock if any section is locked earlier            
  UPDATE PS          
  SET IsLocked = 0          
     ,LockedBy = 0          
     ,LockedByFullName = ''          
  FROM ProjectSection PS WITH (NOLOCK)          
  WHERE SectionId=@PSectionId         
  AND CustomerId = @PCustomerId          
  AND LockedBy = @PUserId 
  --AND ProjectId = @PProjectId   
  AND IsLastLevel = 1        
  AND IsLocked = 1;        
     
    
-- Select section lock info        
SELECT @IsLocked AS IsLocked 
        
END 