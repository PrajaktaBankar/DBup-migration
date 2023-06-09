CREATE PROCEDURE usp_SaveProjectDefaultPrivacySetting    
(    
@CustomerId int,    
@UserId int,    
@ProjectAccessTypeId int,    
@ProjectOwnerTypeId int,    
@ProjectOriginTypeId int,    
@IsOfficeMaster bit    
)    
AS    
BEGIN    
DECLARE @PCustomerId int = @CustomerId;    
DECLARE @PUserId int = @UserId;    
DECLARE @PProjectAccessTypeId int = @ProjectAccessTypeId;    
DECLARE @PProjectOwnerTypeId int = @ProjectOwnerTypeId;    
DECLARE @PProjectOriginTypeId int = @ProjectOriginTypeId;    
DECLARE @PIsOfficeMaster bit = @IsOfficeMaster;    
  
IF(@PProjectOriginTypeId = 2)  
BEGIN  
 update PS set PS.ProjectAccessTypeId = @PProjectAccessTypeId  
  from Project P WITH(NOLOCK)          
  join ProjectSummary PS WITH(NOLOCK)
  ON P.ProjectId = PS.ProjectId      
  where P.CustomerId=@CustomerId AND Isnull(p.isDeleted,0)=0 and P.IsShowMigrationPopup=1          
  and ISNULL(p.IsArchived,0)=0  AND ISNULL(p.IsOfficeMaster,0)=@IsOfficeMaster;   
END  
  
DECLARE @ID INT = ( SELECT TOP 1    
  Id    
 FROM ProjectDefaultPrivacySetting WITH (NOLOCK)    
 WHERE CustomerId = @PCustomerId    
 AND ProjectOriginTypeId = @PProjectOriginTypeId    
 AND IsOfficeMaster = @PIsOfficeMaster);    
    
IF (@ID IS NULL)    
BEGIN    
 INSERT INTO ProjectDefaultPrivacySetting (CustomerId, ProjectAccessTypeId, ProjectOwnerTypeId, ProjectOriginTypeId, IsOfficeMaster, CreatedBy, CreatedDate)    
 VALUES (@PCustomerId, @PProjectAccessTypeId, @PProjectOwnerTypeId, @PProjectOriginTypeId, @PIsOfficeMaster, @PUserId, GETUTCDATE());    
END    
ELSE    
BEGIN -- add new    
 UPDATE p    
 SET p.ProjectAccessTypeId = @PProjectAccessTypeId    
    ,p.ProjectOwnerTypeId = @PProjectOwnerTypeId    
    ,p.ModifiedBy = @PUserId    
    ,p.ModifiedDate = GETUTCDATE()    
 FROM ProjectDefaultPrivacySetting p WITH (NOLOCK)    
 WHERE p.CustomerId = @PCustomerId    
 AND p.ProjectOriginTypeId = @PProjectOriginTypeId    
 AND p.IsOfficeMaster = @PIsOfficeMaster;    
END    
END;