CREATE PROCEDURE [dbo].[usp_InsertNewProjectSummary]    
@ProjectId INT,          
@CustomerId  INT,          
@UserId   INT,          
@ProjectTypeId  INT,          
@FacilityTypeId  INT,          
@SizeUoM  INT,          
@IsIncludeRsInSection  BIT,          
@IsIncludeReInSection  BIT,          
@SpecViewModeId  INT,          
@UnitOfMeasureValueTypeId  INT,          
@SourceTagFormat  VARCHAR(10),          
@IsActivateRsCitation  BIT,          
@ActualCostId  INT,          
@ActualSizeId  INT      
      
AS          
BEGIN      
          
DECLARE @PProjectId INT = @ProjectId;      
DECLARE @PCustomerId INT = @CustomerId;      
DECLARE @PUserId INT = @UserId;      
DECLARE @PProjectTypeId INT = @ProjectTypeId;      
DECLARE @PFacilityTypeId INT = @FacilityTypeId;      
DECLARE @PSizeUoM INT = @SizeUoM;      
DECLARE @PIsIncludeRsInSection BIT = @IsIncludeRsInSection;      
DECLARE @PIsIncludeReInSection BIT = @IsIncludeReInSection;      
DECLARE @PSpecViewModeId  INT = @SpecViewModeId;      
DECLARE @PUnitOfMeasureValueTypeId INT = @UnitOfMeasureValueTypeId;      
DECLARE @PSourceTagFormat  VARCHAR(10) = @SourceTagFormat;      
DECLARE @PIsActivateRsCitation BIT = @IsActivateRsCitation;      
DECLARE @PActualCostId INT = @ActualCostId;      
DECLARE @PActualSizeId INT =@ActualSizeId;      
    
-- Get Project Default Privacy Settings    
DECLARE @PProjectOriginType int = 1; -- NON Migrated SLC Project    
DECLARE @ProjectAccessTypeId int = 0;    
DECLARE @ProjectOwnerTypeId int = 0;    
DECLARE @OwnerId int =null;    
DECLARE @IsOfficeMaster bit = (select IsOfficeMaster from Project WITH(NOLOCK) where ProjectId = @ProjectId and CustomerId = @CustomerId);    
    
IF NOT EXISTS(select 1 from ProjectDefaultPrivacySetting pdps WITH(NOLOCK)    
    where CustomerId = @PCustomerId and ProjectOriginTypeId = @PProjectOriginType and IsOfficeMaster = @IsOfficeMaster)  
BEGIN  
select @ProjectAccessTypeId = ProjectAccessTypeId,     
    @ProjectOwnerTypeId = ProjectOwnerTypeId from ProjectDefaultPrivacySetting pdps WITH(NOLOCK)    
    where CustomerId = 0 and ProjectOriginTypeId = @PProjectOriginType and IsOfficeMaster = @IsOfficeMaster;
	--Used CustomerId = 0 to fetch default setting;
END  
ELSE   
BEGIN  
select @ProjectAccessTypeId = ProjectAccessTypeId,     
    @ProjectOwnerTypeId = ProjectOwnerTypeId from ProjectDefaultPrivacySetting pdps WITH(NOLOCK)    
    where CustomerId = @PCustomerId and ProjectOriginTypeId = @PProjectOriginType and IsOfficeMaster = @IsOfficeMaster;    
END  
    
IF(@ProjectOwnerTypeId > 1) -- If Default owner type 'user who has created the project'    
BEGIN    
 SET @OwnerId = @PUserId;    
END    
-- Else Set the Project Owner to the 'Not Assigned' - ie. @null    
      
INSERT INTO ProjectSummary (ProjectId      
, CustomerId      
, UserId      
, ProjectTypeId      
, FacilityTypeId      
, SizeUoM      
, IsIncludeRsInSection      
, IsIncludeReInSection      
, SpecViewModeId      
, UnitOfMeasureValueTypeId      
, LastMasterUpdate      
, BudgetedCostId      
, BudgetedCost      
, ActualCost      
, EstimatedArea      
, SourceTagFormat      
, IsActivateRsCitation      
, SpecificationIssueDate      
, SpecificationModifiedDate      
, ActualCostId      
, ActualSizeId      
, EstimatedSizeId      
, EstimatedSizeUoM      
, ProjectAccessTypeId    
, OwnerId)      
 VALUES (@PProjectId, @PCustomerId, @PUserId, @PProjectTypeId, @PFacilityTypeId, @PSizeUoM, @PIsIncludeRsInSection, @PIsIncludeReInSection, @PSpecViewModeId, @PUnitOfMeasureValueTypeId, NULL, NULL, NULL, NULL, NULL, @PSourceTagFormat, @PIsActivateRsCitation, NULL, NULL, @PActualCostId, @PActualSizeId, NULL, NULL,@ProjectAccessTypeId,@OwnerId)      
      
END 