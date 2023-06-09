CREATE PROCEDURE [dbo].[usp_IsExistSectionForImport]   
 @ProjectId	INT ,
 @CustomerId	INT ,
 @Author	nvarchar(20) ,
 @SourceTag	varchar(10)

  AS
BEGIN
 DECLARE @PProjectId	INT = @ProjectId;
 DECLARE @PCustomerId INT = @CustomerId;
 DECLARE @PAuthor nvarchar(20) = @Author;
 DECLARE @PSourceTag	varchar(10) = @SourceTag;

SELECT
	SectionId
   ,ParentSectionId
   ,mSectionId
   ,ProjectId
   ,CustomerId
   ,UserId
   ,DivisionId
   ,DivisionCode
   ,Description
   ,LevelId
   ,IsLastLevel
   ,SourceTag
   ,Author
   ,TemplateId
   ,SectionCode
   ,IsDeleted
   ,IsLocked
   ,LockedBy
   ,LockedByFullName
   ,CreateDate
   ,CreatedBy
   ,ModifiedBy
   ,ModifiedDate
   ,FormatTypeId 
   ,SpecViewModeId 
   ,IsLockedImportSection
   ,IsTrackChanges
   ,IsTrackChangeLock
   ,TrackChangeLockedBy
FROM ProjectSection WITH (NOLOCK)
WHERE ProjectId = @PProjectId
AND CustomerId = @PCustomerId
AND Author = @PAuthor
AND SourceTag = @PSourceTag
AND IsLastLevel = 1
AND IsDeleted = 0
END

GO
