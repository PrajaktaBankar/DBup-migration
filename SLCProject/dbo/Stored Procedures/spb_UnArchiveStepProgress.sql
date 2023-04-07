CREATE PROCEDURE [dbo].[spb_UnArchiveStepProgress]
(
	@RequestId						INT
	,@StepName						NVARCHAR(100)
	,@Description					NVARCHAR(500)
	,@Step							NVARCHAR(100)
	,@ProgressInPercent				INT
	,@OldCount						INT
	,@NewCount						INT
)
AS
BEGIN
	INSERT INTO [dbo].[UnArchiveStepProgress]
	([RequestId],[StepName],[Description],[IsCompleted],[Step],[OldCount],[NewCount],[CreatedDate])
	VALUES (@RequestId, @StepName, @Description, 1, @Step, @OldCount, @NewCount, GETUTCDATE())

	IF @ProgressInPercent IS NULL
	BEGIN
		UPDATE U
			SET U.IsNotify = 0
				,U.StatusId = 4
				,U.ModifiedDate = GETUTCDATE()
		FROM [SLCProject].[dbo].[UnArchiveProjectRequest] U with(nolock)
		WHERE U.[RequestId] = @RequestId;
	END
	ELSE
	BEGIN
		UPDATE U
			SET U.[ProgressInPercentage] = @ProgressInPercent
				,U.IsNotify = 0
				,U.StatusId = IIF(@ProgressInPercent = 100, 3, 2)
				,U.ModifiedDate = GETUTCDATE()
				,U.StartTime = IIF(@ProgressInPercent = 100, GETUTCDATE(), StartTime)
				,U.EndTime = IIF(@ProgressInPercent = 100, GETUTCDATE(), EndTime)
		FROM [SLCProject].[dbo].[UnArchiveProjectRequest] U  with(nolock)
		WHERE U.[RequestId] = @RequestId;
	END

END