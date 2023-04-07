CREATE PROC [dbo].[usp_InsertGTForImportFromWord]
(
	@Id INT
)
AS
BEGIN
	DECLARE @customerId INT,    
	 @projectId INT,    
	 @sectionId INT,    
	 @segmentId BIGINT,    
	 @segmentStatusId BIGINT,    
	 @GTJson NVARCHAR(MAX)    
    
	SELECT 
	@customerId = customerId,
	@projectId = projectId,
	@sectionId = sectionId,    
	@segmentId = segmentId,
	@segmentStatusId = segmentStatusId,
	@GTJson = GTList   
	FROM #InpSegmentStatusidTableVar    
	WHERE RowId = @Id

	SELECT ROW_NUMBER() OVER(ORDER BY PlaceHolder) AS RowId,*,PlaceHolder AS oldPlaceHolder INTO #GTTemp   
	FROM openjson(@GTJson)    
	WITH(    
		Placeholder NVARCHAR(10),    
		[Value] NVARCHAR(10)
	) 

	UPDATE gtt
	SET gtt.PlaceHolder = CONCAT('{GT#', e.OptionValue,'}')
	FROM #GTTemp gtt
	INNER JOIN #enhanceTextMapping e
	ON gtt.[Value] = e.OptionVar

	DECLARE @SegmentDesc NVARCHAR(MAX) = (SELECT SegmentDescription FROM #InpSegmentStatusidTableVar WHERE RowId = @Id)
	DECLARE @GTCount INT = (SELECT LEN(@SegmentDesc) - LEN(REPLACE(@SegmentDesc, '{GT', '')))

	IF @GTCount > 0
	BEGIN
		SET @SegmentDesc = REPLACE(@SegmentDesc,'{GT','~{GT')
		DROP TABLE IF EXISTS #tempSegDescTable
		CREATE TABLE #tempSegDescTable
		(
			RowId INT IDENTITY(1,1),
			SplitDesc NVARCHAR(max)
		)
		INSERT INTO #tempSegDescTable SELECT [value] FROM STRING_SPLIT(@SegmentDesc,'~')

		UPDATE tsdt
		SET tsdt.SplitDesc = REPLACE(tsdt.SplitDesc, gtt.oldPlaceHolder, gtt.PlaceHolder)
		FROM #GTTemp gtt, 
		#tempSegDescTable tsdt
		WHERE (SELECT LEN(tsdt.SplitDesc) - LEN(REPLACE(tsdt.SplitDesc, gtt.oldPlaceHolder, ''))) > 0

		DECLARE @ConcatDesc VARCHAR(MAX) = ''
		SELECT @ConcatDesc = COALESCE(@ConcatDesc + '', '') + SplitDesc FROM #tempSegDescTable
		SET @SegmentDesc = @ConcatDesc

		UPDATE #InpSegmentStatusidTableVar SET
		SegmentDescription = @SegmentDesc
		WHERE RowId = @Id
	END
END
