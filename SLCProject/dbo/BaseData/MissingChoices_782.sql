--Execute It on server 3

--Assign CustomerID below so that it will update IsDeleted flag back to 0 for the deleted SelectedChoiceOption
--This will be updated for all the projects under the given customer
--Change the script if you want to update records only for single project

DECLARE @CustomerID AS INT = 782

IF OBJECT_ID('tempdb..#tmpProjects') IS NOT NULL DROP TABLE #tmpProjects

CREATE TABLE #tmpProjects
(
	RowID						INT IDENTITY(1, 1), 
    CustomerID					INT NOT NULL,
	ProjectID					INT NULL
)

INSERT INTO #tmpProjects
SELECT CustomerId, ProjectId FROM SLCProject..Project WHERE CustomerId = @CustomerID ORDER BY ProjectId DESC

DECLARE @NumberOfProjects int, @ProjectRowNumber int

-- Get the number of records in the temporary table
	SET @NumberOfProjects = @@ROWCOUNT
	SET @ProjectRowNumber = 1

	-- loop through all records in the temporary table using the WHILE loop construct
	WHILE @ProjectRowNumber <= @NumberOfProjects
	BEGIN
		DECLARE @ProjectId INT
		
		SELECT @ProjectId = ProjectId
		FROM #tmpProjects WHERE RowID = @ProjectRowNumber

		IF OBJECT_ID('tempdb..#tmpSelectedChoices') IS NOT NULL DROP TABLE #tmpSelectedChoices

		CREATE TABLE #tmpSelectedChoices
		(
			RowID						INT IDENTITY(1, 1), 
			SelectedChoiceOptionId		INT NOT NULL,
			SegmentChoiceCode			INT NULL,
			ChoiceOptionCode			INT NULL,
			ChoiceOptionSource			NVARCHAR(255) NULL,
			IsSelected					BIT NULL,
			SectionId					INT NULL,
			ProjectId					INT NULL,
			CustomerId					INT NULL,
			OptionJson					NVARCHAR(MAX) NULL,
			IsDeleted					BIT
		)

		IF OBJECT_ID('tempdb..#tmpSChoices') IS NOT NULL DROP TABLE #tmpSChoices

		CREATE TABLE #tmpSChoices
		(
			RowID						INT IDENTITY(1, 1), 
			SelectedChoiceOptionId		INT NOT NULL,
			SegmentChoiceCode			INT NULL,
			ChoiceOptionCode			INT NULL,
			ChoiceOptionSource			NVARCHAR(255) NULL,
			IsSelected					BIT NULL,
			SectionId					INT NULL,
			ProjectId					INT NULL,
			CustomerId					INT NULL,
			OptionJson					NVARCHAR(MAX) NULL,
			IsDeleted					BIT
		)
		DECLARE @NumberRecords int, @RowCount int


		INSERT INTO #tmpSelectedChoices
		SELECT * FROM SLCProject..SelectedChoiceOption WHERE CustomerId = @CustomerID AND ProjectId = @ProjectId AND IsDeleted = 1

		-- Get the number of records in the temporary table
			SET @NumberRecords = @@ROWCOUNT
			SET @RowCount = 1

			-- loop through all records in the temporary table using the WHILE loop construct
			WHILE @RowCount <= @NumberRecords
			BEGIN
				DECLARE @SegmentChoiceCode INT, @ChoiceOptionCode INT, @ChoiceOptionSource NVARCHAR(255), @IsSelected BIT, @SectionId INT
		
				SELECT @SegmentChoiceCode = SegmentChoiceCode, @ChoiceOptionCode = ChoiceOptionCode, @ChoiceOptionSource = ChoiceOptionSource, @IsSelected = IsSelected
						,@SectionId = SectionId
				FROM #tmpSelectedChoices WHERE RowID = @RowCount

				
					IF EXISTS (SELECT * FROM SLCProject..SelectedChoiceOption WHERE SegmentChoiceCode = @SegmentChoiceCode AND ChoiceOptionCode = @ChoiceOptionCode 
								AND ChoiceOptionSource = 'U' AND SectionId = @SectionId AND ProjectId = @ProjectId AND CustomerId = @CustomerID AND IsDeleted = 1)
					BEGIN
						IF NOT EXISTS (SELECT * FROM SLCProject..SelectedChoiceOption WHERE SegmentChoiceCode = @SegmentChoiceCode 
							AND ChoiceOptionCode = @ChoiceOptionCode AND ChoiceOptionSource = 'U' AND SectionId = @SectionId AND ProjectId = @ProjectId
							AND CustomerId = @CustomerID AND IsDeleted = 0)
						BEGIN
							INSERT INTO #tmpSChoices
							SELECT * FROM SLCProject..SelectedChoiceOption WHERE SegmentChoiceCode = @SegmentChoiceCode AND ChoiceOptionCode = @ChoiceOptionCode AND ChoiceOptionSource = 'U'
								AND SectionId = @SectionId AND ProjectId = @ProjectId AND CustomerId = @CustomerID

							UPDATE SLCProject..SelectedChoiceOption SET IsDeleted = 0 WHERE SegmentChoiceCode = @SegmentChoiceCode AND ChoiceOptionCode = @ChoiceOptionCode 
								AND ChoiceOptionSource = 'U' AND SectionId = @SectionId AND ProjectId = @ProjectId AND CustomerId = @CustomerID
						END
					END

				SET @RowCount = @RowCount + 1
			END
		
		SET @ProjectRowNumber = @ProjectRowNumber + 1
	END



	DROP TABLE #tmpSChoices
	DROP TABLE #tmpSelectedChoices
	DROP TABLE #tmpProjects

