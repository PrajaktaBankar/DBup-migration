Create PROC usp_CopyTargetLinks     (
@ProjectId INT, @SectionID INT, @CustomerId INT, @UserId INT,     
@SourceSegmentStatusId INT , @NewSourceSegmentStatusCode INT,    
@NewSourceSegmentCode INT , @SourceSegmentOrigin nvarchar(1) 
)AS      
BEGIN
--NOTE--SET SegmentSource AND ChoiceOptionSource SHOULD BE SAME IN BELOW INP TABLE OF JSON      
DROP TABLE IF EXISTS #TempInpSegmentLinkTable
CREATE TABLE #TempInpSegmentLinkTable (
	SectionCode INT NULL
   ,SegmentStatusCode INT NULL
   ,SegmentCode INT NULL

);

DECLARE @SegmentLinkSourceTypeId INT = 5;
--INSERT JSON DATA INTO TABLE      
IF (@SourceSegmentOrigin = 'M')
BEGIN
INSERT INTO #TempInpSegmentLinkTable
	SELECT
		pss.SectionCode
	   ,pss.SegmentStatusCode
	   ,pss.SegmentCode
	FROM ProjectSegmentStatusView pss WITH (NOLOCK)
	INNER JOIN SLCMaster..SegmentStatus PS WITH (NOLOCK)
		ON pss.SectionCode = PS.SectionId
			AND pss.mSegmentId = ps.SegmentId
			AND pss.mSegmentStatusId = PS.SegmentStatusId
	WHERE pss.SectionId = @SectionId
	AND pss.SegmentStatusId = @SourceSegmentStatusId
	AND pss.ProjectId = @ProjectId
	AND pss.CustomerId = @CustomerId
	AND ISNULL(pss.IsDeleted, 0) = 0

END
ELSE
BEGIN
INSERT INTO #TempInpSegmentLinkTable
	SELECT
		pss.SectionCode
	   ,pss.SegmentStatusCode
	   ,ps.SegmentCode
	FROM ProjectSegmentStatusView pss WITH (NOLOCK)
	INNER JOIN ProjectSegment PS WITH (NOLOCK)
		ON PS.SectionId = pss.SectionId
			AND pss.SegmentId = PS.SegmentId
			AND PS.SegmentStatusId = pss.SegmentStatusId
	WHERE pss.SectionId = @SectionId
	AND pss.SegmentStatusId = @SourceSegmentStatusId
	AND pss.ProjectId = @ProjectId
	AND pss.CustomerId = @CustomerId
	AND ISNULL(pss.IsDeleted, 0) = 0
END;

--INSERT TARGET LINKS FROM PROJECT DB      

INSERT INTO ProjectSegmentLink (SourceSectionCode
, SourceSegmentStatusCode
, SourceSegmentCode
, SourceSegmentChoiceCode
, SourceChoiceOptionCode
, LinkSource
, TargetSectionCode
, TargetSegmentStatusCode
, TargetSegmentCode
, TargetSegmentChoiceCode
, TargetChoiceOptionCode
, LinkTarget
, LinkStatusTypeId
, IsDeleted
, CreateDate
, CreatedBy
, ProjectId
, CustomerId
, SegmentLinkSourceTypeId)
	SELECT
		SourceSectionCode
	   ,@NewSourceSegmentStatusCode AS SourceSegmentStatusCode
	   ,@NewSourceSegmentCode AS SourceSegmentCode
	   ,SourceSegmentChoiceCode
	   ,SourceChoiceOptionCode
	   ,'U' AS LinkSource
	   ,TargetSectionCode
	   ,TargetSegmentStatusCode
	   ,TargetSegmentCode
	   ,TargetSegmentChoiceCode
	   ,TargetChoiceOptionCode
	   ,LinkTarget
	   ,LinkStatusTypeId
	   ,0 AS IsDeleted
	   ,GETUTCDATE() AS CreateDate
	   ,@UserId AS CreatedBy
	   ,@ProjectId AS ProjectId
	   ,@CustomerId AS CustomerId
	   ,@SegmentLinkSourceTypeId AS SegmentLinkSourceTypeId
	FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
	INNER JOIN #TempInpSegmentLinkTable INPJSON WITH (NOLOCK)
		ON PSLNK.SourceSectionCode = INPJSON.SectionCode
			AND PSLNK.SourceSegmentStatusCode = INPJSON.SegmentStatusCode
			AND PSLNK.SourceSegmentCode = INPJSON.SegmentCode
	WHERE PSLNK.ProjectId = @ProjectId
	AND PSLNK.CustomerId = @CustomerId
	AND ISNULL(PSLNK.IsDeleted, 0) = 0

END