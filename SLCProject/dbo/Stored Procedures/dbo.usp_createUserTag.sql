CREATE PROCEDURE  [dbo].[usp_createUserTag]  
(  
	@CustomerId INT,
	@TagType VARCHAR(MAX),  
	@Description VARCHAR(MAX), 
	@SortOrder INT,  
	@IsSystemTag BIT, 
	@CreatedBy INT, 
	@ModifiedBy INT
)  
AS
BEGIN
	DECLARE @PCustomerId INT = @CustomerId;
	DECLARE @PTagType VARCHAR(MAX) = @TagType;
	DECLARE @PDescription VARCHAR(MAX) = @Description;
	DECLARE @PSortOrder INT = @SortOrder;
	DECLARE @PIsSystemTag BIT = @IsSystemTag;
	DECLARE @PCreatedBy INT = @CreatedBy;
	DECLARE @PModifiedBy INT = @ModifiedBy;
    DECLARE @UserTagId INT;
INSERT INTO ProjectUserTag (CustomerId, TagType, [Description], SortOrder, IsSystemTag, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)
	VALUES (@PCustomerId, @PTagType, @PDescription, @PSortOrder, @PIsSystemTag, GETUTCDATE(), @PCreatedBy, GETUTCDATE(), @PModifiedBy);

SET @UserTagId = SCOPE_IDENTITY();

SELECT
	@UserTagId AS UserTagId

END

GO
