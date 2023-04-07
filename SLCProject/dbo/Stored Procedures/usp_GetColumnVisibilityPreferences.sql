CREATE PROC usp_GetColumnVisibilityPreferences 
-- usp_GetColumnVisibilityPreferences 645,1563
(
	@CustomerId INT,
	@UserId INT=0
)
AS
BEGIN
	DECLARE @json nvarchar(500),@PreferenceName NVARCHAR(100)='projectListColumnDetails'

	SELECT @json=[Value] from UserPreference WITH(NOLOCK) 
	WHERE [Name]=@PreferenceName AND CustomerId=@CustomerId 
	AND (UserId=@UserId or @UserId=0)

	select * from openjson(@json)
	WITH(
		[name] nvarchar(100),
		[index] int,
		[isShow] bit
	)
END
GO