CREATE PROCEDURE [dbo].[usp_ApplyProjectDefaultSetting] (      
@IsOfficeMaster BIT,        
@ProjectId INT,    
@UserId INT,        
@CustomerId INT ,   
@ProjectOriginTypeId INT=1--Projects that are created or copied in SLC    
)      
AS        
BEGIN      
DECLARE @PIsOfficeMaster BIT = @IsOfficeMaster;      
DECLARE @PUserId INT = @UserId;      
DECLARE @PCustomerId INT = @CustomerId;     
DECLARE @PProjectOriginTypeId INT = @ProjectOriginTypeId;      
   
--Insert add user into the Project Team Member list       
INSERT INTO UserProjectAccessMapping      
SELECT       
 @ProjectId AS ProjectId      
   ,@PUserId AS UserId      
   ,PDPS.CustomerId      
   ,PDPS.CreatedBy      
   ,GETUTCDATE() AS CreateDate      
   ,PDPS.ModifiedBy      
   ,GETUTCDATE() AS ModifiedDate      
   ,CAST(1 AS BIT) AS IsActive FROM ProjectDefaultPrivacySetting PDPS WITH(NOLOCK)      
WHERE PDPS.CustomerId=@CustomerId       
AND PDPS.ProjectAccessTypeId IN (2,3)  --Private,Hidden      
AND ProjectOriginTypeId=@PProjectOriginTypeId   
AND ProjectOwnerTypeId=1 --Not Assigned    
AND PDPS.IsOfficeMaster=@IsOfficeMaster      
      
END  
  
        