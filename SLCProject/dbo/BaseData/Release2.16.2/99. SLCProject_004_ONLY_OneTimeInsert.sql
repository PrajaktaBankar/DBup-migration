USE SLCProject
GO
IF(NOT EXISTS(SELECT TOP 1 1 FROM UserPreference WITH(NOLOCK) WHERE CustomerId=2626 AND [Name]='Summary Info Setting'))
BEGIN
	INSERT INTO UserPreference(UserId,CustomerId,Name,Value,CreatedDate)
	VALUES(0,2626,'Summary Info Setting','[{"EnableLinkEngineSettingVisible":true}]',GETUTCDATE())
END
ELSE
BEGIN
	PRINT 'SUMMARY INFO SETTING IS ALREADY INSERTED'
END
GO