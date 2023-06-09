CREATE PROCEDURE [dbo].[usp_CreateNewProject] (    
@Name NVARCHAR(500),      
@IsOfficeMaster BIT,      
@Description NVARCHAR(100),      
@MasterDataTypeId INT,      
@UserId INT,      
@CustomerId INT,      
@ModifiedByFullName NVARCHAR(500),      
@GlobalProjectID NVARCHAR(36),      
@CreatedBy    INT     
)    
AS      
BEGIN    
DECLARE @PName NVARCHAR(500) = @Name;    
DECLARE @PIsOfficeMaster BIT = @IsOfficeMaster;    
DECLARE @PDescription NVARCHAR(100) = @Description;    
DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;    
DECLARE @PUserId INT = @UserId;    
DECLARE @PCustomerId INT = @CustomerId;    
DECLARE @PModifiedByFullName NVARCHAR(500) = @ModifiedByFullName;    
DECLARE @PGlobalProjectID NVARCHAR(36) = @GlobalProjectID;    
DECLARE @PCreatedBy INT = @CreatedBy;    
    
    DECLARE @TemplateCount AS INT = 0
	SELECT @TemplateCount = COUNT(TemplateId) FROM Template WITH (NOLOCK) WHERE CustomerId = @CustomerId AND ISNULL(IsSystem, 0) = 1

	IF @TemplateCount <= 0
	BEGIN
		--Add System Templates for Customer
		INSERT INTO Template
		([Name],[TitleFormatId],[SequenceNumbering],[CustomerId],[IsSystem],[IsDeleted],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[MasterDataTypeId],[A_TemplateId]
			,[ApplyTitleStyleToEOS],[IsTransferred])
		SELECT [Name],[TitleFormatId],[SequenceNumbering],@CustomerId,[IsSystem],[IsDeleted],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[MasterDataTypeId],[A_TemplateId]
			,[ApplyTitleStyleToEOS],[IsTransferred]
		FROM Template WITH (NOLOCK) WHERE CustomerId IS NULL AND ISNULL(IsSystem, 0) = 1

		--Add TemplateStyle for System Templates
		INSERT INTO TemplateStyle
		([TemplateId],[StyleId],[Level],[CustomerId],[A_TemplateStyleId])
		SELECT C.TemplateId, B.StyleId, B.[Level], @CustomerId, [A_TemplateStyleId]
		FROM Template A WITH (NOLOCK)
		INNER JOIN TemplateStyle B WITH (NOLOCK) ON A.TemplateId = B.TemplateId
		INNER JOIN Template C WITH (NOLOCK) ON C.CustomerId = @CustomerId AND ISNULL(C.IsSystem, 0) = 1 AND C.[Name] = A.[Name]
		WHERE A.CustomerId IS NULL AND ISNULL(A.IsSystem, 0) = 1
	
	END

    DECLARE @TemplateId INT=0;    
  -- Get Template ID as per master datatype    
 IF @PMasterDataTypeId=1    
 BEGIN    
SET @TemplateId = (SELECT TOP 1    
  TemplateId    
 FROM Template WITH (NOLOCK)    
 WHERE IsSystem = 1    
 AND MasterDataTypeId = @PMasterDataTypeId    
 AND IsDeleted = 0);    
      
  END    
  ELSE    
  BEGIN    
SET @TemplateId = (SELECT TOP 1    
  TemplateId    
 FROM Template WITH (NOLOCK)    
 WHERE IsSystem = 1    
 AND MasterDataTypeId != 1    
 AND IsDeleted = 0);    
 END    
-- make entry to project table    
INSERT INTO Project ([Name]    
, IsOfficeMaster    
, [Description]    
, TemplateId    
, MasterDataTypeId    
, UserId    
, CustomerId    
, CreateDate    
, CreatedBy    
, ModifiedBy    
, ModifiedDate    
, IsDeleted    
, IsMigrated    
, IsNamewithHeld    
, IsLocked    
, GlobalProjectID    
, IsPermanentDeleted    
, A_ProjectId    
, IsProjectMoved    
, ModifiedByFullName)    
 VALUES (@PName, @PIsOfficeMaster, @PDescription, @TemplateId, @PMasterDataTypeId, @PUserId, @PCustomerId, GETUTCDATE(), @PCreatedBy, @PCreatedBy, GETUTCDATE(), 0, NULL, 0, 0,@PGlobalProjectID, NULL, NULL, NULL, @PModifiedByFullName)    
    
DECLARE @NewProjectId INT = SCOPE_IDENTITY();    
    
-- make entry to UserFolder table    
INSERT INTO UserFolder (FolderTypeId    
, ProjectId    
, UserId    
, LastAccessed    
, CustomerId    
, LastAccessByFullName)    
 VALUES (1, @NewProjectId, @PUserId, GETUTCDATE(), @PCustomerId, @PModifiedByFullName)    
    
-- Select newly created project.    
SELECT    
 @NewProjectId AS ProjectId    
   ,@PName AS [Name]    
   ,@PIsOfficeMaster AS IsOfficeMaster    
   ,@PDescription AS [Description]    
   ,@TemplateId AS TemplateId    
   ,@PMasterDataTypeId AS MasterDataTypeId    
   ,@PUserId AS UserId    
   ,@PCustomerId AS CustomerId    
   ,GETUTCDATE() AS CreateDate    
   ,@PCreatedBy AS CreatedBy    
   ,@PCreatedBy AS ModifiedBy    
   ,GETUTCDATE() AS ModifiedDate    
   ,0 AS IsDeleted    
   ,NULL AS IsMigrated    
   ,0 AS IsNamewithHeld    
   ,0 AS IsLocked    
   ,@PGlobalProjectID AS GlobalProjectID    
   ,NULL AS IsPermanentDeleted    
   ,NULL AS A_ProjectId    
   ,NULL AS IsProjectMoved    
   ,@PModifiedByFullName AS ModifiedByFullName    
   ,@NewProjectId AS Id    
--FROM Project WITH (NOLOCK)    
--WHERE ProjectId = @NewProjectId    
      
--Insert add user into the Project Team Member list     
EXEC usp_ApplyProjectDefaultSetting @IsOfficeMaster,@NewProjectId,@PUserId,@CustomerId  
   
END