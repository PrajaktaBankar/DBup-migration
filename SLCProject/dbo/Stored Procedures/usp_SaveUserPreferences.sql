CREATE PROC usp_SaveUserPreferences
(
	@CustomerId INT,
	@UserId INT=0,
	@PreferenceName NVARCHAR(100),
	@PreferenceValue NVARCHAR(500)
)
AS
BEGIN
	Declare @UserPreferenceId INT=(SELECT TOP 1 UserPreferenceId FROM UserPreference WITH(NOLOCK) WHERE CustomerId=@CustomerId and [Name]=@PreferenceName and (UserId=@UserId or @UserId=0))
	IF(ISNULL(@UserPreferenceId,0)=0)
	BEGIN
		INSERT INTO UserPreference(UserId,CustomerId,Name,Value,CreatedDate)
		VALUES(@UserId,@CustomerId,@PreferenceName,@PreferenceValue,GETUTCDATE())		
	END
	ELSE
	BEGIN
		UPDATE pref
		SET pref.Value=@PreferenceValue,
			pref.ModifiedDate=GETUTCDATE()
		FROM UserPreference pref WITH(NOLOCK)
		WHERE pref.UserPreferenceId=@UserPreferenceId
	END
END
GO
