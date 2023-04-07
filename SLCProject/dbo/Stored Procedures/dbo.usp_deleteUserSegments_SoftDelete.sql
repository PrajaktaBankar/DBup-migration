CREATE PROCEDURE [dbo].[usp_deleteUserSegments_SoftDelete]
(        
 @SegmentStatusIds NVARCHAR(MAX)        
)        
AS        
BEGIN
        
	 DECLARE @ChoiceCount INT = 1;
  
	 DECLARE @SegmentStatusIdTbl TABLE(  
		 SegmentStatusId BIGINT,  
		 SegmentId BIGINT,  
		 ProjectId INT,  
		 CustomerId INT,  
		 RowId INT  
	 )

	INSERT INTO @SegmentStatusIdTbl (SegmentStatusId, RowId)
		SELECT
			Id
		   ,ROW_NUMBER() OVER (ORDER BY Id) AS RowId
		FROM dbo.udf_GetSplittedIds(@SegmentStatusIds, ',');


	UPDATE TBL
	SET TBL.SegmentId = PSST.SegmentId
	   ,TBL.ProjectId = PSST.ProjectId
	   ,TBL.CustomerId = PSST.CustomerId
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN @SegmentStatusIdTbl TBL
		ON PSST.SegmentStatusId = TBL.SegmentStatusId


	SET NOCOUNT ON;
   
	 --Default variables        
	 DECLARE @Source VARCHAR(1) = 'U';
  
	 DECLARE @CurSegmentStatusId BIGINT;
  
	 DECLARE @Counter int=1, @TotalSegment int=0;
	SELECT
		@TotalSegment = COUNT(1)
	FROM @SegmentStatusIdTbl

	--loop delete all segments and choices
	WHILE @Counter <= @TotalSegment
	BEGIN
		SELECT @CurSegmentStatusId = SegmentStatusId
		FROM @SegmentStatusIdTbl
		WHERE RowId = @Counter
		EXEC usp_deleteUserSegment_SoftDelete @CurSegmentStatusId
		SELECT @Counter = @Counter + 1
	END
END
GO


