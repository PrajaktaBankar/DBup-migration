USE SLCProject
GO
----------Add settings for 'Active Project'--------------------------------------------------------------
DECLARE @AccessTypePublic int = 1;
DECLARE @ProjectOrigineTypeId int;
DECLARE @ProjectOwnerTypeId int;

select @ProjectOrigineTypeId = ProjectOriginTypeId  from LuProjectOriginType WITH(NOLOCK) where [Name] = 'SLC Project';
select @ProjectOwnerTypeId = ProjectOwnerTypeId from LuProjectOwnerType WITH(NOLOCK) where [Name] = 'User Who Created the Project';
DECLARE @IsOfficeMaster bit = 0;

IF NOT EXISTS (SELECT 1	FROM ProjectDefaultPrivacySetting  WITH(NOLOCK) WHERE CustomerId = 0 and ProjectOriginTypeId = @ProjectOrigineTypeId and IsOfficeMaster=@IsOfficeMaster)
BEGIN
	insert into ProjectDefaultPrivacySetting(
	CustomerId,ProjectAccessTypeId,ProjectOwnerTypeId, ProjectOriginTypeId,IsOfficeMaster,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)
	values (0, @AccessTypePublic, @ProjectOwnerTypeId, @ProjectOrigineTypeId, @IsOfficeMaster, null, null, null, null);
END
ELSE
BEGIN
	PRINT ('Active Projects default privacy settings already exists.');
END

GO
----------Add settings for 'Office Master'--------------------------------------------------------------
DECLARE @AccessTypePublic int = 1;
DECLARE @ProjectOrigineTypeId int;
DECLARE @ProjectOwnerTypeId int;

select @ProjectOrigineTypeId = ProjectOriginTypeId  from LuProjectOriginType WITH(NOLOCK) where [Name] = 'SLC Project';
select @ProjectOwnerTypeId = ProjectOwnerTypeId from LuProjectOwnerType WITH(NOLOCK) where [Name] = 'User Who Created the Project';
DECLARE @IsOfficeMaster bit = 1;

IF NOT EXISTS (SELECT 1	FROM ProjectDefaultPrivacySetting  WITH(NOLOCK) WHERE CustomerId = 0 and ProjectOriginTypeId = @ProjectOrigineTypeId and IsOfficeMaster=@IsOfficeMaster)
BEGIN
	insert into ProjectDefaultPrivacySetting(
	CustomerId,ProjectAccessTypeId,ProjectOwnerTypeId, ProjectOriginTypeId,IsOfficeMaster,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)
	values (0,	@AccessTypePublic, @ProjectOwnerTypeId, @ProjectOrigineTypeId, @IsOfficeMaster,	null, null, null, null);
END
ELSE
BEGIN
	PRINT ('Office Masters default privacy settings already exists.');
END

GO
----------Add settings for 'Migrated Projects'--------------------------------------------------------------
DECLARE @AccessTypePublic int = 1;
DECLARE @ProjectOrigineTypeId int;
DECLARE @ProjectOwnerTypeId int;

select @ProjectOrigineTypeId = ProjectOriginTypeId  from LuProjectOriginType WITH(NOLOCK) where [Name] = 'Migrated Project';
select @ProjectOwnerTypeId = ProjectOwnerTypeId from LuProjectOwnerType WITH(NOLOCK) where [Name] = 'Not Assigned';
DECLARE @IsOfficeMaster bit = 0;
IF NOT EXISTS (SELECT 1	FROM ProjectDefaultPrivacySetting  WITH(NOLOCK) WHERE CustomerId = 0 and ProjectOriginTypeId = @ProjectOrigineTypeId and IsOfficeMaster=@IsOfficeMaster)
BEGIN
	insert into ProjectDefaultPrivacySetting(
	CustomerId,ProjectAccessTypeId,ProjectOwnerTypeId, ProjectOriginTypeId,IsOfficeMaster,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)
	values (0,	@AccessTypePublic,	@ProjectOwnerTypeId,@ProjectOrigineTypeId, @IsOfficeMaster,	null, null, null, null);
END
ELSE
BEGIN
	PRINT ('Migrated Projects default privacy settings already exists.');
END

GO
----------Add settings for 'Migrated Office Master'--------------------------------------------------------------
DECLARE @AccessTypePublic int = 1;
DECLARE @ProjectOrigineTypeId int;
DECLARE @ProjectOwnerTypeId int;

select @ProjectOrigineTypeId = ProjectOriginTypeId  from LuProjectOriginType WITH(NOLOCK) where [Name] = 'Migrated Project';
select @ProjectOwnerTypeId = ProjectOwnerTypeId from LuProjectOwnerType WITH(NOLOCK) where [Name] = 'Not Assigned';
DECLARE @IsOfficeMaster bit = 1;

IF NOT EXISTS (SELECT 1	FROM ProjectDefaultPrivacySetting  WITH(NOLOCK) WHERE CustomerId = 0 and ProjectOriginTypeId = @ProjectOrigineTypeId and IsOfficeMaster=@IsOfficeMaster)
BEGIN
	insert into ProjectDefaultPrivacySetting(
	CustomerId,ProjectAccessTypeId,ProjectOwnerTypeId,ProjectOriginTypeId,IsOfficeMaster,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)
	values (0, @AccessTypePublic, @ProjectOwnerTypeId,	@ProjectOrigineTypeId, @IsOfficeMaster,	null, null, null, null);
END
ELSE
BEGIN
	PRINT ('Migrated Office Masters default privacy settings already exists.');
END

GO
----------Add settings for 'Transferred Projects'--------------------------------------------------------------
DECLARE @AccessTypePublic int = 1;
DECLARE @ProjectOrigineTypeId int;
DECLARE @ProjectOwnerTypeId int;

select @ProjectOrigineTypeId = ProjectOriginTypeId  from LuProjectOriginType WITH(NOLOCK) where [Name] = 'Transferred Project';
select @ProjectOwnerTypeId = ProjectOwnerTypeId from LuProjectOwnerType WITH(NOLOCK) where [Name] = 'User Who Received the Project';
DECLARE @IsOfficeMaster bit = 0;

IF NOT EXISTS (SELECT 1	FROM ProjectDefaultPrivacySetting  WITH(NOLOCK) WHERE CustomerId = 0 and ProjectOriginTypeId = @ProjectOrigineTypeId and IsOfficeMaster=@IsOfficeMaster)
BEGIN
	insert into ProjectDefaultPrivacySetting(
	CustomerId,ProjectAccessTypeId,ProjectOwnerTypeId, ProjectOriginTypeId,IsOfficeMaster,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)
	values (0,	@AccessTypePublic,	@ProjectOwnerTypeId,	@ProjectOrigineTypeId, @IsOfficeMaster,	null, null, null, null);
END
ELSE
BEGIN
	PRINT ('Transferred Projects default privacy settings already exists.');
END

GO
----------Add settings for 'Transferred Office Masters'--------------------------------------------------------------
DECLARE @AccessTypePublic int = 1;
DECLARE @ProjectOrigineTypeId int;
DECLARE @ProjectOwnerTypeId int;

select @ProjectOrigineTypeId = ProjectOriginTypeId  from LuProjectOriginType WITH(NOLOCK) where [Name] = 'Transferred Project';
select @ProjectOwnerTypeId = ProjectOwnerTypeId from LuProjectOwnerType WITH(NOLOCK) where [Name] = 'User Who Received the Project';
DECLARE @IsOfficeMaster bit = 1;

IF NOT EXISTS (SELECT 1	FROM ProjectDefaultPrivacySetting  WITH(NOLOCK) WHERE CustomerId = 0 and ProjectOriginTypeId = @ProjectOrigineTypeId and IsOfficeMaster=@IsOfficeMaster)
BEGIN
	insert into ProjectDefaultPrivacySetting(
	CustomerId,ProjectAccessTypeId,ProjectOwnerTypeId, ProjectOriginTypeId,IsOfficeMaster,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)
	values (0,@AccessTypePublic,@ProjectOwnerTypeId,@ProjectOrigineTypeId, @IsOfficeMaster,	null, null, null, null);
END
ELSE
BEGIN
	PRINT ('Transferred Office Masters default privacy settings already exists.');
END