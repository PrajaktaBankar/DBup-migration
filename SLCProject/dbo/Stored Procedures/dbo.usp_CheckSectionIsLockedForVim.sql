CREATE PROCEDURE [dbo].[usp_CheckSectionIsLockedForVim]      
 @SectionId INT,  
 @ProjectId INT,    
 @CustomerId INT  
  AS  
BEGIN
  
  DECLARE @PProjectId int = @ProjectId;
  DECLARE @PCustomerId int = @CustomerId;
  DECLARE @PSectionId int  = @SectionId;
SELECT
	SectionId
   ,ParentSectionId
   ,mSectionId
   ,ProjectId
   ,CustomerId
   ,UserId
   ,DivisionId
   ,ISNULL(DivisionCode, 0) AS DivisionCode
   ,ISNULL([Description], '') AS [Description]
   ,LevelId
   ,IsLastLevel
   ,ISNULL(SourceTag, '') AS SourceTag
   ,Author
   ,TemplateId
   ,SectionCode
   ,ISNULL(IsDeleted, 0) AS IsDeleted
   ,ISNULL(IsLocked, 0) AS IsLocked
   ,LockedBy
   ,ISNULL(LockedByFullName, '') AS LockedByFullName
   ,CreateDate
   ,CreatedBy
   ,ModifiedBy
   ,ModifiedDate
   ,FormatTypeId
   ,SpecViewModeId
   ,IsLockedImportSection
FROM ProjectSection WITH (NOLOCK)
WHERE  SectionId = @PSectionId

END

GO
