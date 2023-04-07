CREATE PROCEDURE [dbo].[usp_CopyBranchLinks]   
(  
 @UserId INT,  
 @CustomerId int,
 @NewSegmentsJson NVARCHAR(MAX)  
)  
AS  
BEGIN
  
   
 DECLARE @CreatedBy INT = @UserId,@SegmentLinkSourceTypeId int=5;

SELECT
	* INTO #NewSegmentTable
FROM OPENJSON(@NewSegmentsJson) WITH (
RowId INT '$.RowId',
SrcChoiceOptionCode BIGINT '$.SrcChoiceOptionCode',
SrcProjectId INT '$.SrcProjectId',
SrcSectionCode INT '$.SrcSectionCode',
SrcSectionId INT '$.SrcSectionId',
SrcSegmentChoiceCode BIGINT '$.SrcSegmentChoiceCode',
SrcSegmentCode BIGINT '$.SrcSegmentCode',
SrcSegmentId BIGINT '$.SrcSegmentId',
SrcSegmentStatusCode BIGINT '$.SrcSegmentStatusCode',
SrcSegmentStatusId BIGINT '$.SrcSegmentStatusId',
TrgChoiceOptionCode BIGINT '$.TrgChoiceOptionCode',
TrgProjectId INT '$.TrgProjectId',
TrgSectionCode INT '$.TrgSectionCode',
TrgSectionId INT '$.TrgSectionId',
TrgSegmentChoiceCode BIGINT '$.TrgSegmentChoiceCode',
TrgSegmentCode BIGINT '$.TrgSegmentCode',
TrgSegmentId BIGINT '$.TrgSegmentId',
TrgSegmentStatusCode BIGINT '$.TrgSegmentStatusCode',
TrgSegmentStatusId BIGINT '$.TrgSegmentStatusId'
);


DECLARE @ProjectId INT = 0
	   ,@SectionCode INT = 0
	   ,@SectionId INT = 0
	   ,@SourceSegmentCode BIGINT = 0;

SELECT TOP 1
	@ProjectId = SrcProjectId
   ,@SectionCode = SrcSectionCode
   ,@SectionId = TrgSectionId
   ,@SourceSegmentCode = TrgSegmentCode
FROM #NewSegmentTable

SELECT
	SourceSectionCode
   ,SourceSegmentStatusCode
   ,SourceSegmentCode
   ,SourceSegmentChoiceCode
   ,SourceChoiceOptionCode
   ,TargetSectionCode
   ,TargetSegmentStatusCode
   ,TargetSegmentCode
   ,TargetSegmentChoiceCode
   ,TargetChoiceOptionCode
   ,LinkTarget
   ,LinkStatusTypeId
   ,CustomerId
   ,IsDeleted
   ,ProjectId
   ,SegmentLinkId INTO #ProjectSegmentLinkTBL
FROM ProjectSegmentLink WITH (NOLOCK)
WHERE ProjectId = @ProjectId
AND  CustomerId = @CustomerId
AND SourceSectionCode = @SectionCode

---Get all Links
SELECT DISTINCT
	CLRT.TrgSectionCode AS SourceSectionCode
   ,CLRT.TrgSegmentStatusCode AS SourceSegmentStatusCode
   ,CLRT.TrgSegmentCode AS SourceSegmentCode
   ,IIF(CLRT.TrgSegmentChoiceCode = 0, NULL, CLRT.TrgSegmentChoiceCode) AS SourceSegmentChoiceCode
   ,IIF(CLRT.TrgChoiceOptionCode = 0, NULL, CLRT.TrgChoiceOptionCode) AS SourceChoiceOptionCode
   ,'U' AS LinkSource
   ,PSL.TargetSectionCode
   ,PSL.TargetSegmentStatusCode
   ,PSL.TargetSegmentCode
   ,PSL.TargetSegmentChoiceCode
   ,PSL.TargetChoiceOptionCode
   ,PSL.LinkTarget
   ,PSL.LinkStatusTypeId
   ,0 AS IsDeleted
   ,GETUTCDATE() AS CreateDate
   ,@UserId AS CreatedBy
   ,CLRT.SrcProjectId AS ProjectId
   ,@CustomerId AS CustomerId
   ,@SegmentLinkSourceTypeId AS SegmentLinkSourceTypeId INTO #TempProjectSegmentLink
FROM #ProjectSegmentLinkTBL PSL 
INNER JOIN #NewSegmentTable CLRT
	ON CLRT.SrcProjectId = PSL.ProjectId
		AND CLRT.SrcSectionCode = PSL.SourceSectionCode
		AND CLRT.SrcSegmentStatusCode = PSL.SourceSegmentStatusCode
		AND CLRT.SrcSegmentCode = PSL.SourceSegmentCode
		AND ISNULL(CLRT.SrcChoiceOptionCode, 0) = ISNULL(PSL.SourceChoiceOptionCode, 0)
		AND ISNULL(CLRT.SrcSegmentChoiceCode, 0) = ISNULL(PSL.SourceSegmentChoiceCode, 0)
AND PSL.CustomerId = @CustomerId 

---Validate and insert data into ProjectSegmentLink Table

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

	SELECT DISTINCT
		CLRT.SourceSectionCode
	   ,CLRT.SourceSegmentStatusCode
	   ,CLRT.SourceSegmentCode
	   ,IIF(CLRT.SourceSegmentChoiceCode = 0, NULL, CLRT.SourceSegmentChoiceCode)
	   ,IIF(CLRT.SourceChoiceOptionCode = 0, NULL, CLRT.SourceChoiceOptionCode)
	   ,CLRT.LinkSource
	   ,CLRT.TargetSectionCode
	   ,CLRT.TargetSegmentStatusCode
	   ,CLRT.TargetSegmentCode
	   ,IIF(CLRT.TargetSegmentChoiceCode = 0, NULL, CLRT.TargetSegmentChoiceCode)
	   ,IIF(CLRT.TargetChoiceOptionCode = 0, NULL, CLRT.TargetChoiceOptionCode)
	   ,CLRT.LinkTarget
	   ,CLRT.LinkStatusTypeId
	   ,CLRT.IsDeleted
	   ,CLRT.CreateDate
	   ,CLRT.CreatedBy
	   ,CLRT.ProjectId
	   ,CLRT.CustomerId
	   ,CLRT.SegmentLinkSourceTypeId
	FROM #TempProjectSegmentLink CLRT
	LEFT OUTER JOIN #ProjectSegmentLinkTBL PSLTBL
		ON CLRT.ProjectId = PSLTBL.ProjectId
			AND CLRT.SourceSectionCode = PSLTBL.SourceSectionCode
			AND CLRT.SourceSegmentStatusCode = PSLTBL.SourceSegmentStatusCode
			AND CLRT.SourceSegmentCode = PSLTBL.SourceSegmentCode
			AND ISNULL(CLRT.SourceChoiceOptionCode, 0) = ISNULL(PSLTBL.SourceChoiceOptionCode, 0)
			AND ISNULL(CLRT.SourceSegmentChoiceCode, 0) = ISNULL(PSLTBL.SourceSegmentChoiceCode, 0)
			AND PSLTBL.CustomerId = @CustomerId
			AND PSLTBL.IsDeleted = 0
	WHERE PSLTBL.SegmentLinkId IS NULL

---Update Within branch newly created segment details.
UPDATE PSL
SET PSL.TargetSectionCode = CLRT.TrgSectionCode
   ,PSL.TargetSegmentStatusCode = CLRT.TrgSegmentStatusCode
   ,PSL.TargetSegmentCode = CLRT.TrgSegmentCode
   ,PSL.TargetSegmentChoiceCode = IIF(CLRT.TrgSegmentChoiceCode = 0, NULL, CLRT.TrgSegmentChoiceCode)
   ,PSL.TargetChoiceOptionCode = IIF(CLRT.TrgChoiceOptionCode = 0, NULL, CLRT.TrgChoiceOptionCode)
   ,PSL.LinkTarget = 'U'
FROM ProjectSegmentLink PSL WITH (NOLOCK)
INNER JOIN #NewSegmentTable CLRT
	ON CLRT.SrcProjectId = PSL.ProjectId
	AND CLRT.SrcSectionCode = PSL.TargetSectionCode
	AND ISNULL(PSL.IsDeleted, 0) = 0
	AND CLRT.SrcSegmentStatusCode = PSL.TargetSegmentStatusCode
	AND CLRT.SrcSegmentCode = PSL.TargetSegmentCode
	AND ISNULL(CLRT.SrcChoiceOptionCode, 0) = ISNULL(PSL.TargetChoiceOptionCode, 0)
	AND ISNULL(CLRT.SrcSegmentChoiceCode, 0) = ISNULL(PSL.TargetSegmentChoiceCode, 0)
INNER JOIN #TempProjectSegmentLink SRCPSL
	ON PSL.ProjectId = SRCPSL.ProjectId
	AND PSL.SourceSectionCode = SRCPSL.SourceSectionCode
	AND PSL.SourceSegmentStatusCode = SRCPSL.SourceSegmentStatusCode
	AND PSL.SourceSegmentCode = SRCPSL.SourceSegmentCode
	AND ISNULL(PSL.SourceChoiceOptionCode, 0) = ISNULL(SRCPSL.SourceChoiceOptionCode, 0)
	AND ISNULL(PSL.SourceSegmentChoiceCode, 0) = ISNULL(SRCPSL.SourceSegmentChoiceCode, 0)
WHERE PSL.LinkSource = 'U' AND PSL.CustomerId = @CustomerId

END
GO


