Create Procedure [dbo].[usp_SpecDataCreateSegments]   
(      
@ProjectId int,      
@CustomerId int,      
@UserId Int,      
@MasterSectionIdJson NVARCHAR(max)      
)      
as      
begin
      
      
DECLARE  @InputDataTable TABLE(      
RowId int,      
    mSectionId INT,
	SectionId   int      
);
      
      
IF @MasterSectionIdJson != ''      
BEGIN
INSERT INTO @InputDataTable
	SELECT
		ROW_NUMBER() OVER (ORDER BY mSectionId ASC) AS RowId
	   ,mSectionId
	   ,0
	FROM OPENJSON(@MasterSectionIdJson)
	WITH (
	mSectionId INT '$.SectionId'
	);
END

UPDATE IDTBL
SET IDTBL.SectionId = ps.SectionId
FROM ProjectSection PS WITH (NOLOCK)
INNER JOIN @InputDataTable IDTBL
	ON IDTBL.mSectionId = PS.mSectionId
	AND PS.ProjectId = @ProjectId
	AND PS.CustomerId = @CustomerId
	AND ISNULL(PS.IsDeleted, 0) = 0

DECLARE @InputDataTablerowCount INT = (SELECT
				COUNT(SectionId)
			FROM @InputDataTable)
	   ,@n INT = 1;

WHILE (@InputDataTablerowCount >= @n)
BEGIN

DECLARE @SectionId INT = 0;
SELECT
	@SectionId = SectionId
FROM @InputDataTable IDTBL
WHERE RowId = @n

EXECUTE usp_MapSegmentStatusFromMasterToProject @ProjectId
											   ,@SectionId
											   ,@CustomerId
											   ,@UserId

EXECUTE usp_MapSegmentChoiceFromMasterToProject @ProjectId
											   ,@SectionId
											   ,@CustomerId
											   ,@UserId
EXECUTE usp_MapProjectRefStands @ProjectId
							   ,@SectionId
							   ,@CustomerId
							   ,@UserId

EXECUTE usp_MapSegmentRequirementTagFromMasterToProject @ProjectId
													   ,@SectionId
													   ,@CustomerId
													   ,@UserId

EXECUTE usp_MapSegmentLinkFromMasterToProject @ProjectId
											 ,@SectionId
											 ,@CustomerId
											 ,@UserId

EXECUTE usp_UpdateSegmentStatus_ApplyMasterUpdate @ProjectId
												 ,@CustomerId
												 ,@SectionId

EXECUTE usp_DeleteSegmentRequirementTag_ApplyMasterUpdate @ProjectId
														 ,@CustomerId
														 ,@SectionId

SET @n = @n + 1;
      
END
      
END
 