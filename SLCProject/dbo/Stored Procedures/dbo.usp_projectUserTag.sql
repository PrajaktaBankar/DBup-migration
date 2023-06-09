CREATE Procedure [dbo].[usp_ProjectUserTag]  
(  
@CustomerId int,@TagType varchar(max),  
@Description varchar(max), @SortOrder int,  
@IsSystemTag bit, @CreatedBy int , @ModifiedBy int  
)  
As  
Begin
  
DECLARE @PCustomerId int = @CustomerId;
DECLARE @PTagType varchar(max) = @TagType;
DECLARE @PDescription varchar(max) = @Description;
DECLARE @PSortOrder int = @SortOrder;
DECLARE @PIsSystemTag bit = @IsSystemTag;
DECLARE @PCreatedBy int = @CreatedBy;
DECLARE @PModifiedBy int = @ModifiedBy;
Declare @UserTagId int;

INSERT INTO projectUserTag (CustomerId, TagType, Description, SortOrder, IsSystemTag, CreateDate,
CreatedBy, ModifiedDate, ModifiedBy)
	VALUES (@PCustomerId, @PTagType, @PDescription, @PSortOrder, @PIsSystemTag, GETUTCDATE(), @PCreatedBy, GETUTCDATE(), @PModifiedBy);

SET @UserTagId = SCOPE_IDENTITY();

SELECT
	UserTagId
   ,CustomerId
   ,TagType
   ,Description
   ,SortOrder
   ,IsSystemTag
   ,CreateDate
   ,CreatedBy
   ,ModifiedDate
   ,ModifiedBy
   ,A_UserTagId
FROM projectUserTag WITH (NOLOCK)
WHERE UserTagId = @UserTagId

END;

GO 
