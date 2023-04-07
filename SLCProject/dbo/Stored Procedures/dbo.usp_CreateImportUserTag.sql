CREATE PROCEDURE  [dbo].[usp_CreateImportUserTag] 
(  
	@CustomerId INT,
	@UserId INT,
	@TagType VARCHAR(5),  
	@Description VARCHAR(MAX)
)  
AS
BEGIN
	DECLARE @SortOrder INT = 0;
	DECLARE @UserTagId INT = 0;

SET @SortOrder = (SELECT
		COUNT(1)
	FROM ProjectUserTag WITH (NOLOCK)
	WHERE CustomerId = @CustomerId)
SET @SortOrder = @SortOrder + 1
	
	IF NOT EXISTS (SELECT TOP 1
		1
	FROM ProjectUserTag WITH (NOLOCK)
	WHERE CustomerId = @CustomerId
	AND TagType = @TagType)
BEGIN
INSERT INTO ProjectUserTag (CustomerId, TagType, [Description], SortOrder, IsSystemTag, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)
	VALUES (@CustomerId, @TagType, @Description, @SortOrder, 0, GETUTCDATE(), @UserId, GETUTCDATE(), @UserId);
SET @UserTagId = SCOPE_IDENTITY();
    END
	ELSE
	BEGIN
SET @UserTagId = (SELECT DISTINCT
		UserTagId
	FROM ProjectUserTag WITH (NOLOCK)
	WHERE CustomerId = @CustomerId
	AND TagType = @TagType)
	END

SELECT
	@UserTagId AS UserTagId

END