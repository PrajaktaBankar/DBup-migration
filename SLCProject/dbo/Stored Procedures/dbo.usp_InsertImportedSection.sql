CREATE PROCEDURE [dbo].[usp_InsertImportedSection]           
@ProjectId int,          
@UserId int ,          
@UserName NVARCHAR(500) null=null,          
@ParentSectionId int,          
@CustomerId int,          
@Description nvarchar(500)null=null,          
@SourceTag varchar(18)null=null,          
@Author nvarchar(100)null=null,          
@CreatedBy int,          
@SpecViewModeId int          
          
AS          
BEGIN          
DECLARE @PProjectId int = @ProjectId;          
DECLARE @PUserId int = @UserId;          
DECLARE @PUserName NVARCHAR(500) = @UserName;          
DECLARE @PParentSectionId int = @ParentSectionId;          
DECLARE @PCustomerId int = @CustomerId;          
DECLARE @PDescription nvarchar(500) = @Description;          
DECLARE @PSourceTag varchar(18) = @SourceTag;          
DECLARE @PAuthor nvarchar(100) = @Author;          
DECLARE @PCreatedBy int = @CreatedBy;          
DECLARE @PSpecViewModeId int = @SpecViewModeId;          
DECLARE @SortOrder INT = dbo.udf_getSectionSortOrder(@PProjectId, @PCustomerId, @PParentSectionId, @PSourceTag, @PAuthor);      
      
UPDATE PS SET SortOrder = SortOrder + 1 FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId  AND ParentSectionId = @ParentSectionId AND SortOrder >= @SortOrder;      
      
INSERT INTO ProjectSection (ParentSectionId          
, mSectionId          
, ProjectId          
, CustomerId          
, UserId          
, DivisionId          
, DivisionCode          
, Description          
, LevelId          
, IsLastLevel          
, SourceTag          
, Author          
, TemplateId          
, IsDeleted          
, IsLocked          
, LockedBy          
, LockedByFullName          
, CreateDate          
, CreatedBy          
, ModifiedBy          
, ModifiedDate          
, FormatTypeId          
, SLE_FolderID          
, SLE_ParentID          
, SLE_DocID          
, SpecViewModeId          
, IsLockedImportSection          
, A_SectionId      
, SortOrder)          
 VALUES (@PParentSectionId, NULL, @PProjectId, @PCustomerId, @PUserId, null, null, @PDescription, 3, 1, @PSourceTag, @PAuthor, NULL, 0, 0, NULL, NULL, GETUTCDATE(), @PUserId, NULL, GETUTCDATE(), 1, NULL, NULL, NULL, @PSpecViewModeId, 0, NULL, @SortOrder);
  
    
       
      
DECLARE @NewSectionId INT = SCOPE_IDENTITY();       
         
          
SELECT          
 SectionCode          
   ,SectionId          
FROM ProjectSection WITH (NOLOCK)          
WHERE SectionId = @NewSectionId          
END 