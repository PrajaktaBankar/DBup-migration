
CREATE Proc [dbo].[usp_rebuildSequenceNumber](
@SectionId INT
)
AS
BEGIN
 
DECLARE @PSectionId INT = @SectionId;
DECLARE @PProjectId AS INT;

SELECT @PProjectId = ProjectId FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSectionId;


-- Generate  SequenceNumber as per row id/number
SELECT
	PSST.SegmentStatusId
   ,PSST.SequenceNumber
   ,CAST(ROW_NUMBER() OVER (ORDER BY PSST.SequenceNumber) - 1 AS DECIMAL(18, 4)) AS NewSequenceNumber INTO #SectionOrderedBySequence
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
WHERE PSST.ProjectId = @PProjectId AND PSST.SectionId = @PSectionId

--Update SequenceNumber as per row id/number
UPDATE PSST
SET PSST.SequenceNumber = X.NewSequenceNumber
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN #SectionOrderedBySequence AS X
	ON PSST.SegmentStatusId = X.SegmentStatusId

END
GO