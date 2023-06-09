CREATE PROCEDURE [dbo].[usp_deleteUserSegments]  
(          
 @SegmentStatusIds NVARCHAR(MAX)          
)          
AS          
BEGIN
BEGIN TRY  
  DECLARE @PSegmentStatusIds NVARCHAR(MAX) =  @SegmentStatusIds;
  
--  DECLARE @ChoiceCount INT = 1;
  
    
--  DECLARE @SegmentStatusIdTbl TABLE(    
--   SegmentStatusId INT,    
--   SegmentId INT,    
--   ProjectId INT,    
--   CustomerId INT,    
--   RowId INT    
--  )

--INSERT INTO @SegmentStatusIdTbl (SegmentStatusId, RowId)
--	SELECT
--		Id
--	   ,ROW_NUMBER() OVER (ORDER BY Id) AS RowId
--	FROM dbo.udf_GetSplittedIds(@PSegmentStatusIds, ',');


----UPDATE TBL  
----SET TBL.SegmentId = PSST.SegmentId  
----   ,TBL.ProjectId = PSST.ProjectId  
----   ,TBL.CustomerId = PSST.CustomerId  
----FROM ProjectSegmentStatus PSST WITH (NOLOCK)  
----INNER JOIN @SegmentStatusIdTbl TBL  
---- ON PSST.SegmentStatusId = TBL.SegmentStatusId  


--SET NOCOUNT ON;
  
     
--  --Default variables          
--  DECLARE @Source VARCHAR(1) = 'U';
  
    
--  DECLARE @CurSegmentStatusId INT;
  
    
  --DECLARE @Counter int=1, @TotalSegment int=0;
	EXEC usp_deleteUserSegment @SegmentStatusIds
--SELECT
--	@TotalSegment = COUNT(1)
--FROM @SegmentStatusIdTbl

----loop delete all segments and choices  
--WHILE @Counter <= @TotalSegment
--BEGIN
--SELECT
--	@CurSegmentStatusId = SegmentStatusId
--FROM @SegmentStatusIdTbl
--WHERE RowId = @Counter
--SELECT
--	@Counter = @Counter + 1
--END
END TRY
BEGIN CATCH
	insert into BsdLogging..AutoSaveLogging
	values('usp_deleteUserSegments',
	getdate(),
	ERROR_MESSAGE(),
	ERROR_NUMBER(),
	ERROR_Severity(),
	ERROR_LINE(),
	ERROR_STATE(),
	ERROR_PROCEDURE(),
	concat('exec usp_deleteUserSegments ''',@SegmentStatusIds,''''),
	@SegmentStatusIds
	)

	DECLARE @AutoSaveLoggingId INT =  (SELECT @@IDENTITY AS [@@IDENTITY]);
    THROW 50010, @AutoSaveLoggingId, 1;
END CATCH
END
GO
