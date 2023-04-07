CREATE PROC usp_GetSummaryInfoUserPreferences
(
	@UserId INT=0,
	@CustomerId INT
)
AS
BEGIN  

	DECLARE @json nvarchar(500),@PreferenceName NVARCHAR(100)='';
	DECLARE @EnableAutoSaveIndexDbFeature BIT = 0;
	DECLARE @EnableLinkEngineSettingVisible BIT = 0;  
	DECLARE @EnableAutosaveButton BIT = 0;

	DECLARE @ErrorMessage NVARCHAR(1000);

	SET @PreferenceName = 'AutoSaveIndexDdSetting';
	SELECT top 1 @json=[value] FROM UserPreference WITH(NOLOCK)   
	WHERE CustomerId=@CustomerId AND  
	UserId=0 AND  [Name]=@PreferenceName  
 
	BEGIN TRY
		SELECT @EnableAutoSaveIndexDbFeature = EnableAutoSaveIndexDbFeature 
		FROM openjson(@json)  
		WITH(EnableAutoSaveIndexDbFeature BIT)
	END TRY
	BEGIN CATCH  
		SELECT @EnableAutoSaveIndexDbFeature = 0;
		
		SELECT @ErrorMessage = ERROR_MESSAGE();
		INSERT INTO BsdLogging..DBLogging (
		 ArtifactName,DBServerName,DBServerIP,CreatedDate
		 ,LevelType,InputData,ErrorProcedure,ErrorMessage                          
		)                          
		VALUES (                          
			'usp_GetSummaryInfoUserPreferences'                          
			,@@SERVERNAME,convert(NVARCHAR, CONNECTIONPROPERTY('local_net_address')),Getdate()                          
			,'Error'                          
			,('CustomerId: ' + convert(NVARCHAR(10), ISNULL(@CustomerId, '')))              
			,'usp_GetSummaryInfoUserPreferences'                          
			,ISNULL(@ErrorMessage, '')                          
		);
	END CATCH;

	SET @PreferenceName = 'Summary Info Setting';
	SELECT top 1 @json=[value] FROM UserPreference WITH(NOLOCK)   
	WHERE CustomerId=@CustomerId AND  
	UserId=@UserId AND  
	[Name]=@PreferenceName  
	
	BEGIN TRY
		SELECT @EnableLinkEngineSettingVisible = EnableLinkEngineSettingVisible, 
			@EnableAutosaveButton = EnableAutosaveButton 
		FROM openjson(@json)  
		WITH(
			EnableLinkEngineSettingVisible BIT,
			EnableAutosaveButton  BIT
		)
	END TRY
	BEGIN CATCH  
		SELECT @EnableLinkEngineSettingVisible = 0;
		SELECT @EnableAutosaveButton = 0;

		SELECT @ErrorMessage = ERROR_MESSAGE();
		INSERT INTO BsdLogging..DBLogging (
			ArtifactName,DBServerName,DBServerIP,CreatedDate                          
			,LevelType,InputData,ErrorProcedure,ErrorMessage                          
		)                          
		VALUES (                          
			'usp_GetSummaryInfoUserPreferences'                          
			,@@SERVERNAME,convert(NVARCHAR, CONNECTIONPROPERTY('local_net_address')),Getdate()                          
			,'Error'                          
			,('CustomerId: ' + convert(NVARCHAR(10), ISNULL(@CustomerId, '')))              
			,'usp_GetSummaryInfoUserPreferences'                          
			,ISNULL(@ErrorMessage, '')                          
		);
	END CATCH;

	SELECT ISNULL(@EnableLinkEngineSettingVisible, 0) AS EnableLinkEngineSettingVisible, 
		ISNULL(@EnableAutosaveButton, 0) AS EnableAutosaveButton, 
		ISNULL(@EnableAutoSaveIndexDbFeature, 0) AS EnableAutoSaveIndexDbFeature
	
END