CREATE PROC usp_CorrectHierarchyBasedOnIndentLevel_DF
(
	@projectId INT,
	@SectionId INT,
	@viewOnly BIT=1
)
AS
BEGIN
	DROP TABLE IF EXISTS #t

	SELECT ROW_NUMBER() OVER(ORDER BY SequenceNumber) as RowNo,SequenceNumber,IndentLevel,SegmentDescription,SegmentStatusId,ParentSegmentStatusId AS CurrentParentSegmentStatusId, CONVERT(BIGINT,0) AS ActualParentSegmentStatusId INTO #t 
	FROM ProjectSegmentStatusView WITH(NOLOCK) 
	WHERE ProjectId=@projectId and sectionId=@SectionId and IsDeleted=0
	ORDER BY SequenceNumber

	DECLARE @i INT=2,@cnt INT=(SELECT count(1) FROM #t)
	DECLARE @currentIdentLevel INT,@PrevIndentLevel INT,@CurrSegmentStatusId BIGINT,@PrevSegmentStatusId BIGINT
	DECLARE @parentSegmentStatusId BIGINT=0

	DECLARE @indentSequenceMapping AS TABLE(IndentLevel INT,SegmentStatusId BIGINT,ParentSegmentStatusId BIGINT)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(0)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(1)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(2)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(3)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(4)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(5)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(6)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(7)
	INSERT INTO @indentSequenceMapping(IndentLevel) VALUES(8)

	SELECT @CurrSegmentStatusId=SegmentStatusId FROM #t WHERE RowNo=1

	UPDATE @indentSequenceMapping
	SET SegmentStatusId=@CurrSegmentStatusId,
		ParentSegmentStatusId=0
	WHERE IndentLevel=0

	WHILE(@i<=@cnt)
	BEGIN
		SELECT @currentIdentLevel=IndentLevel,@CurrSegmentStatusId=SegmentStatusId FROM #t WHERE RowNo=@i

		SELECT @PrevIndentLevel=IndentLevel,@PrevSegmentStatusId=SegmentStatusId,@parentSegmentStatusId=ParentSegmentStatusId 
		FROM @indentSequenceMapping WHERE IndentLevel=@currentIdentLevel-1

		UPDATE @indentSequenceMapping
		SET SegmentStatusId=@CurrSegmentStatusId,
			ParentSegmentStatusId=@PrevSegmentStatusId
		WHERE IndentLevel=@currentIdentLevel


		IF(@currentIdentLevel>@PrevIndentLevel)
		BEGIN
			UPDATE #t
			SET ActualParentSegmentStatusId=@PrevSegmentStatusId
			WHERE RowNo=@i
		END
		ELSE IF(@currentIdentLevel=@PrevIndentLevel)
		BEGIN
			UPDATE #t
			SET ActualParentSegmentStatusId=@parentSegmentStatusId
			WHERE RowNo=@i
		END
		ELSE IF(@currentIdentLevel<@PrevIndentLevel)
		BEGIN
			SELECT @PrevIndentLevel=IndentLevel,@PrevSegmentStatusId=SegmentStatusId,@parentSegmentStatusId=ParentSegmentStatusId 
			FROM @indentSequenceMapping WHERE IndentLevel=@currentIdentLevel
		
			UPDATE #t
			SET ActualParentSegmentStatusId=@parentSegmentStatusId
			WHERE RowNo=@i
		END

		SET @i=@i+1
END

	IF(@viewOnly=0)
	BEGIN
		UPDATE ps
		SET ps.ParentSegmentStatusId=t.ActualParentSegmentStatusId
		FROM ProjectSegmentStatus ps WITH(NOLOCK) INNER JOIN #t t
		ON ps.SegmentStatusId=t.SegmentStatusId
		WHERE t.ActualParentSegmentStatusId<>t.CurrentParentSegmentStatusId

		SELECT CONCAT(@@ROWCOUNT,' Records affected') as MSG
	END
	IF(@viewOnly=1)
	BEGIN
		SELECT *,IIF(CurrentParentSegmentStatusId<>ActualParentSegmentStatusId,'Y','') AS MisMatch FROM #t ORDER BY RowNo
	END
END