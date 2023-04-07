CREATE PROCEDURE [dbo].[usp_CreateCopiedLinks]  
(    
     
 @UserId int ,    
 @CustomerId int    ,
 @IsCopyLinkUndoRedo BIT,
 @IsCopyCrossLinks BIT,
 @CopyLinkRequestJson NVARCHAR(MAX)

)    
AS    
BEGIN
    
    
 DECLARE @SegmentLinkSourceTypeId INT = 5;
 -- User created link  

	SELECT
		SrcChoiceOptionCode
	   ,SrcProjectId
	   ,SrcSectionCode
	   ,SrcSectionId
	   ,SrcSegmentChoiceCode
	   ,SrcSegmentCode
	   ,SrcSegmentId
	   ,SrcSegmentStatusCode
	   ,SrcSegmentStatusId
	   ,TrgChoiceOptionCode
	   ,TrgProjectId
	   ,TrgSectionCode
	   ,TrgSectionId
	   ,TrgSegmentChoiceCode
	   ,TrgSegmentCode
	   ,TrgSegmentId
	   ,TrgSegmentStatusCode
	   ,TrgSegmentStatusId  INTO #CopyLinkRequestTable
	FROM OPENJSON(@CopyLinkRequestJson) WITH (
	--LinkType INT '$.LinkType',  
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

DROP TABLE IF EXISTS #TempProjectSegmentLink, #ProjectSegmentLinkTBL

DECLARE @ProjectId INT = 0
	   ,@SectionCode INT = 0
	   ,@SectionId INT = 0
	   ,@SourceSegmentCode BIGINT = 0;

SELECT TOP 1
	@ProjectId = SrcProjectId
   ,@SectionCode = SrcSectionCode
   ,@SectionId = TrgSectionId
   ,@SourceSegmentCode = TrgSegmentCode
FROM #CopyLinkRequestTable

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
AND CustomerId = @CustomerId
AND SourceSectionCode = @SectionCode

IF (@IsCopyCrossLinks = 0)
BEGIN

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
FROM #CopyLinkRequestTable CLRT  
INNER JOIN #ProjectSegmentLinkTBL PSL 
	ON CLRT.SrcProjectId = PSL.ProjectId
		AND CLRT.SrcSectionCode = PSL.SourceSectionCode
		AND ISNULL(PSL.IsDeleted, 0) =0
		--CASE
		--	WHEN @IsCopyLinkUndoRedo = 0 THEN 0
		--	WHEN @IsCopyLinkUndoRedo = 1 THEN 1
		--	ELSE 0
		--END
		AND CLRT.SrcSegmentStatusCode = PSL.SourceSegmentStatusCode
		AND CLRT.SrcSegmentCode = PSL.SourceSegmentCode
		AND ISNULL(CLRT.SrcChoiceOptionCode, 0) = ISNULL(PSL.SourceChoiceOptionCode, 0)
		AND ISNULL(CLRT.SrcSegmentChoiceCode, 0) = ISNULL(PSL.SourceSegmentChoiceCode, 0)
WHERE PSL.CustomerId = @CustomerId


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
	   ,CLRT.SourceSegmentChoiceCode
	   ,CLRT.SourceChoiceOptionCode
	   ,CLRT.LinkSource
	   ,CLRT.TargetSectionCode
	   ,CLRT.TargetSegmentStatusCode
	   ,CLRT.TargetSegmentCode
	   ,CLRT.TargetSegmentChoiceCode
	   ,CLRT.TargetChoiceOptionCode
	   ,CLRT.LinkTarget
	   ,CLRT.LinkStatusTypeId
	   ,CLRT.IsDeleted
	   ,CLRT.CreateDate
	   ,CLRT.CreatedBy
	   ,CLRT.ProjectId
	   ,CLRT.CustomerId
	   ,CLRT.SegmentLinkSourceTypeId
	FROM #TempProjectSegmentLink CLRT
	LEFT OUTER JOIN #ProjectSegmentLinkTBL psl
		ON CLRT.ProjectId = PSL.ProjectId
			AND CLRT.SourceSectionCode = PSL.SourceSectionCode
			AND CLRT.SourceSegmentStatusCode = PSL.SourceSegmentStatusCode
			AND CLRT.SourceSegmentCode = PSL.SourceSegmentCode
			AND ISNULL(CLRT.SourceChoiceOptionCode, 0) = ISNULL(PSL.SourceChoiceOptionCode, 0)
			AND ISNULL(CLRT.SourceSegmentChoiceCode, 0) = ISNULL(PSL.SourceSegmentChoiceCode, 0)
			AND psl.CustomerId = @CustomerId
			AND psl.IsDeleted = 0
	WHERE psl.SegmentLinkId IS NULL



END
ELSE
BEGIN

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
   ,@SegmentLinkSourceTypeId AS SegmentLinkSourceTypeId INTO #TempProjectSegmentLinkCrossSection
FROM #CopyLinkRequestTable CLRT 
INNER JOIN #ProjectSegmentLinkTBL PSL
	ON CLRT.SrcProjectId = PSL.ProjectId
		AND CLRT.SrcSectionCode = PSL.SourceSectionCode
		AND PSL.SourceSectionCode <> PSL.TargetSectionCode
		AND CLRT.SrcSegmentStatusCode = PSL.SourceSegmentStatusCode
		AND CLRT.SrcSegmentCode = PSL.SourceSegmentCode
		AND ISNULL(CLRT.SrcChoiceOptionCode, 0) = ISNULL(PSL.SourceChoiceOptionCode, 0)
		AND ISNULL(CLRT.SrcSegmentChoiceCode, 0) = ISNULL(PSL.SourceSegmentChoiceCode, 0)
		AND ISNULL(PSL.IsDeleted, 0) =0
		--CASE
		--	WHEN @IsCopyLinkUndoRedo  = 0 THEN 0
		--	WHEN @IsCopyLinkUndoRedo = 1 THEN 1
		--	ELSE 0
		--END
WHERE PSL.CustomerId = @CustomerId

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
	   ,CLRT.SourceSegmentChoiceCode
	   ,CLRT.SourceChoiceOptionCode
	   ,CLRT.LinkSource
	   ,CLRT.TargetSectionCode
	   ,CLRT.TargetSegmentStatusCode
	   ,CLRT.TargetSegmentCode
	   ,CLRT.TargetSegmentChoiceCode
	   ,CLRT.TargetChoiceOptionCode
	   ,CLRT.LinkTarget
	   ,CLRT.LinkStatusTypeId
	   ,CLRT.IsDeleted
	   ,CLRT.CreateDate
	   ,CLRT.CreatedBy
	   ,CLRT.ProjectId
	   ,CLRT.CustomerId
	   ,CLRT.SegmentLinkSourceTypeId
	FROM #TempProjectSegmentLinkCrossSection CLRT
	LEFT OUTER JOIN #ProjectSegmentLinkTBL psl
		ON CLRT.ProjectId = PSL.ProjectId
			AND CLRT.SourceSectionCode = PSL.SourceSectionCode
			AND CLRT.SourceSegmentStatusCode = PSL.SourceSegmentStatusCode
			AND CLRT.SourceSegmentCode = PSL.SourceSegmentCode
			AND ISNULL(CLRT.SourceChoiceOptionCode, 0) = ISNULL(PSL.SourceChoiceOptionCode, 0)
			AND ISNULL(CLRT.SourceSegmentChoiceCode, 0) = ISNULL(PSL.SourceSegmentChoiceCode, 0)
			AND psl.CustomerId = @CustomerId
			AND psl.IsDeleted = 0
	WHERE psl.SegmentLinkId IS NULL


END

END
GO


