CREATE PROCEDURE [dbo].[usp_CreateSpecDataSegments] (@ProjectId INT,
@CustomerId INT,
@UserId INT,
@MasterSectionIdJson NVARCHAR(MAX))
AS
BEGIN
	DECLARE @StepInprogress INT = 2;
	DECLARE @ProgressPer10 INT = 10;
	DECLARE @ProgressPer20 INT = 20;
	DECLARE @ProgressPer30 INT = 30;
	DECLARE @ProgressPer40 INT = 40;
	DECLARE @ProgressPer50 INT = 50;
	DECLARE @ProgressPer60 INT = 60;
	DECLARE @ProgressPer65 INT = 65;
	DECLARE @InputDataTable TABLE (
		RowId INT
	   ,SectionId INT
	   ,RequestId INT
	);

	IF @MasterSectionIdJson != ''
	BEGIN
		INSERT INTO @InputDataTable
			SELECT
				ROW_NUMBER() OVER (ORDER BY SectionId ASC) AS RowId
			   ,SectionId
			   ,RequestId
			FROM OPENJSON(@MasterSectionIdJson)
			WITH (
			SectionId INT '$.SectionId',
			RequestId INT '$.RequestId'
			);

		DECLARE @n INT = 1
		WHILE ((SELECT
				COUNT(SectionId)
			FROM @InputDataTable)
		>= @n)
		BEGIN
		DECLARE @SectionId INT;
		DECLARE @RequestId INT;

		(SELECT TOP 1
			@SectionId = SectionId
		   ,@RequestId = RequestId
		FROM @InputDataTable
		WHERE RowId = @n)


		EXECUTE usp_MapSegmentStatusFromMasterToProject @ProjectId
													   ,@SectionId
													   ,@CustomerId
													   ,@UserId

		EXEC usp_MaintainImportProjectProgress NULL
											  ,@ProjectId
											  ,NULL
											  ,@SectionId
											  ,@UserId
											  ,@CustomerId
											  ,@StepInprogress
											  ,@ProgressPer10  
											  ,0
											  ,"SpecAPI"
											  ,@RequestId;



		EXECUTE usp_MapSegmentChoiceFromMasterToProject @ProjectId
													   ,@SectionId
													   ,@CustomerId
													   ,@UserId

		EXEC usp_MaintainImportProjectProgress NULL
											  ,@ProjectId
											  ,NULL
											  ,@SectionId
											  ,@UserId
											  ,@CustomerId
											  ,@StepInprogress
											  ,@ProgressPer10  
											  ,0
											  ,'SpecAPI'
											  ,@RequestId;

		EXECUTE usp_MapProjectRefStands @ProjectId
									   ,@SectionId
									   ,@CustomerId
									   ,@UserId


		EXEC usp_MaintainImportProjectProgress NULL
											  ,@ProjectId
											  ,NULL
											  ,@SectionId
											  ,@UserId
											  ,@CustomerId
											  ,@StepInprogress
											  ,@ProgressPer30 --Percent
											  ,0
											  ,'SpecAPI'
											  ,@RequestId;

		EXECUTE usp_MapSegmentRequirementTagFromMasterToProject @ProjectId
															   ,@SectionId
															   ,@CustomerId
															   ,@UserId
		EXEC usp_MaintainImportProjectProgress NULL
											  ,@ProjectId
											  ,NULL
											  ,@SectionId
											  ,@UserId
											  ,@CustomerId
											  ,2
											  ,@ProgressPer40 --Percent
											  ,0
											  ,'SpecAPI'
											  ,@RequestId;

		EXECUTE usp_MapSegmentLinkFromMasterToProject @ProjectId
													 ,@SectionId
													 ,@CustomerId
													 ,@UserId
		EXEC usp_MaintainImportProjectProgress NULL
											  ,@ProjectId
											  ,NULL
											  ,@SectionId
											  ,@UserId
											  ,@CustomerId
											  ,@StepInprogress
											  ,@ProgressPer50 --Percent
											  ,0
											  ,'SpecAPI'
											  ,@RequestId;
		EXECUTE usp_UpdateSegmentStatus_ApplyMasterUpdate @ProjectId
														 ,@CustomerId
														 ,@SectionId

		EXEC usp_MaintainImportProjectProgress NULL
											  ,@ProjectId
											  ,NULL
											  ,@SectionId
											  ,@UserId
											  ,@CustomerId
											  ,@StepInprogress
											  ,@ProgressPer60 --Percent
											  ,0
											  ,'SpecAPI'
											  ,@RequestId;
		EXECUTE usp_DeleteSegmentRequirementTag_ApplyMasterUpdate @ProjectId
																 ,@CustomerId
																 ,@SectionId

		EXEC usp_MaintainImportProjectProgress NULL
											  ,@ProjectId
											  ,NULL
											  ,@SectionId
											  ,@UserId
											  ,@CustomerId
											  ,@StepInprogress
											  ,@ProgressPer65 --Percent
											  ,0
											  ,'SpecAPI'
											  ,@RequestId;
		SET @n = @n + 1;

		END

	END
END