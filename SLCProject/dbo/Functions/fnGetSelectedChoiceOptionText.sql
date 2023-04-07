
CREATE FUNCTION [dbo].[fnGetSelectedChoiceOptionText]
(
	@choiceOptionId int,
	@segmentOrigin char(2),
	@optionJsonString nvarchar(MAX)
)
RETURNS nvarchar(1024)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ChoiceOptionText nvarchar(1024)
	DECLARE @cnt int=1,@max int=0,
	@OptionTypeId int ,@Id  int,@SortOrder int,
	@Value nvarchar(1024)
	DECLARE @OptionJson ChoiceOptionJsonTableType
 ;

	IF(@segmentOrigin='M')
	BEGIN
		--SELECT @OptionJson=OptionJson FROM [SLCMaster].[dbo].[ChoiceOption] where ChoiceOptionId=@choiceOptionId;
		INSERT INTO @OptionJson
			SELECT
				ROW_NUMBER() OVER (ORDER BY SortOrder) AS row_number
			   ,*
			FROM OPENJSON(@optionJsonString)
			WITH (

			[OptionTypeId] VARCHAR(200) '$.OptionTypeId',
			[SortOrder] [int] '$.SortOrder',
			[Value] [varchar](1024) '$.Value',
			[Id] INT '$.Id'
			);

		SELECT
			@max = COUNT(1)
		FROM @OptionJson;
		SET @optionJsonString = '';
		WHILE(@cnt<=@max)
		BEGIN
			SELECT
				@OptionTypeId = OptionTypeId
			   ,@SortOrder = SortOrder
			   ,@Value = Value
			   ,@Id = Id
			FROM @OptionJson
			WHERE [RowNumber] = @cnt;
			IF (@OptionTypeId = 1
				OR @OptionTypeId = 4)
			BEGIN
				SET @optionJsonString = CONCAT(@optionJsonString, @Value)
							END
							IF(@OptionTypeId=3)
							BEGIN
				SET @optionJsonString = CONCAT(@optionJsonString, (SELECT
						SourceTag
					FROM SLCMaster.dbo.Section WITH(NOLOCK)
					WHERE sectionid = @Id)
				)
			END
			IF(@OptionTypeId=10)
			BEGIN
				SET @optionJsonString = CONCAT(@optionJsonString, (SELECT
						Description
					FROM SLCMaster.dbo.Section WITH(NOLOCK)
					WHERE sectionid = @Id)
				)
			END
			SET @cnt = @cnt + 1
		END
	END
	ELSE IF(@segmentOrigin='U')
	BEGIN
		INSERT INTO @OptionJson
			SELECT
				ROW_NUMBER() OVER (ORDER BY SortOrder) AS row_number
			   ,*
			FROM OPENJSON(@optionJsonString)
			WITH (

			[OptionTypeId] VARCHAR(200) '$.OptionTypeId',
			[SortOrder] [int] '$.SortOrder',
			[Value] [varchar](1024) '$.Value',
			[Id] INT '$.Id'
			);

		SELECT
			@max = COUNT(1)
		FROM @OptionJson;
		SET @optionJsonString = '';
		WHILE(@cnt<=@max)
		BEGIN
			SELECT
				@OptionTypeId = OptionTypeId
			   ,@SortOrder = SortOrder
			   ,@Value = Value
			   ,@Id = Id
			FROM @OptionJson
			WHERE [RowNumber] = @cnt;
			IF (@OptionTypeId = 1
				OR @OptionTypeId = 4)
			BEGIN
				SET @optionJsonString = CONCAT(@optionJsonString, @Value)
							END
							IF(@OptionTypeId=3)
							BEGIN
				SET @optionJsonString = CONCAT(@optionJsonString, (SELECT
						SourceTag
					FROM SLCMaster.dbo.Section WITH(NOLOCK)
					WHERE sectionid = @Id)
				)
			END
			IF(@OptionTypeId=10)
			BEGIN
				SET @optionJsonString = CONCAT(@optionJsonString, (SELECT
						Description
					FROM SLCMaster.dbo.Section WITH(NOLOCK)
					WHERE sectionid = @Id))
			END
			SET @cnt = @cnt + 1
		END
	END
	return @optionJsonString
END
