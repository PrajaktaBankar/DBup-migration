CREATE PROCEDURE [dbo].[usp_MapSegmentLinkFromMasterToProject] 
(
	@ProjectId INT NULL, 
	@SectionId INT NULL, 
	@CustomerId INT NULL, 
	@UserId INT NULL
)
AS
BEGIN
SET NOCOUNT ON;
  
DECLARE @pProjectId INT = @ProjectId
DECLARE @pSectionId INT = @SectionId
DECLARE @pCustomerId INT = @CustomerId
DECLARE @pUserId INT = @UserId
DECLARE @PSectionModifiedDate datetime2=null
DECLARE @IsMasterSection BIT=0
DECLARE @SectionCode INT;
--SET @SectionCode = (SELECT TOP 1 SectionCode FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @pSectionId AND mSectionId IS NOT NULL);

SELECT TOP 1
	@SectionCode = SectionCode
	,@PSectionModifiedDate=DataMapDateTimeStamp
	,@IsMasterSection=iif(mSectionId IS NOT NULL,1,0)
	FROM dbo.ProjectSection WITH (NOLOCK)
	WHERE SectionId = @PSectionId
	OPTION (FAST 1);

	IF(@IsMasterSection=1 AND (dateadd(HOUR,-6,GETUTCDATE())>=@PSectionModifiedDate OR @PSectionModifiedDate IS NULL))
	BEGIN
		DROP TABLE IF EXISTS #ProjectSegmentLinkTemp;
		SELECT
			 PSLNK.SourceSectionCode
			,PSLNK.SourceSegmentStatusCode
			,PSLNK.SourceSegmentCode
			,PSLNK.SourceSegmentChoiceCode
			,PSLNK.SourceChoiceOptionCode
			,PSLNK.LinkSource
			,PSLNK.TargetSectionCode
			,PSLNK.TargetSegmentStatusCode
			,PSLNK.TargetSegmentCode
			,PSLNK.TargetSegmentChoiceCode
			,PSLNK.TargetChoiceOptionCode
			,PSLNK.LinkTarget
			,PSLNK.LinkStatusTypeId
			,PSLNK.SegmentLinkId
		   INTO #ProjectSegmentLinkTemp
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
		WHERE PSLNK.ProjectId = @PProjectId
		AND PSLNK.CustomerId = @PCustomerId
		AND (PSLNK.SourceSectionCode = @SectionCode
		OR PSLNK.TargetSectionCode = @SectionCode)
		
		INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,
	TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget,
	LinkStatusTypeId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, ProjectId, CustomerId, SegmentLinkCode, SegmentLinkSourceTypeId)
		SELECT
			MSLNK.SourceSectionCode AS SourceSectionCode
		   ,MSLNK.SourceSegmentStatusCode AS SourceSegmentStatusCode
		   ,MSLNK.SourceSegmentCode AS SourceSegmentCode
		   ,MSLNK.SourceSegmentChoiceCode AS SourceSegmentChoiceCode
		   ,MSLNK.SourceChoiceOptionCode AS SourceChoiceOptionCode
		   ,MSLNK.LinkSource AS LinkSource
		   ,MSLNK.TargetSectionCode AS TargetSectionCode
		   ,MSLNK.TargetSegmentStatusCode AS TargetSegmentStatusCode
		   ,MSLNK.TargetSegmentCode AS TargetSegmentCode
		   ,MSLNK.TargetSegmentChoiceCode AS TargetSegmentChoiceCode
		   ,MSLNK.TargetChoiceOptionCode AS TargetChoiceOptionCode
		   ,MSLNK.LinkTarget AS LinkTarget
		   ,MSLNK.LinkStatusTypeId AS LinkStatusTypeId
		   ,GETUTCDATE() AS CreateDate
		   ,@pUserId AS CreatedBy
		   ,GETUTCDATE() AS ModifiedDate
		   ,@pUserId AS ModifiedBy
		   ,@pProjectId AS ProjectId
		   ,@pCustomerId AS CustomerId
		   ,MSLNK.SegmentLinkCode AS SegmentLinkCode
		   ,MSLNK.SegmentLinkSourceTypeId AS SegmentLinkSourceTypeId
		FROM SLCMaster..SegmentLink MSLNK WITH (NOLOCK)
		LEFT JOIN #ProjectSegmentLinkTemp PSLNK WITH (NOLOCK)
			ON  MSLNK.SourceSectionCode = PSLNK.SourceSectionCode
				AND MSLNK.SourceSegmentStatusCode = PSLNK.SourceSegmentStatusCode
				AND MSLNK.SourceSegmentCode = PSLNK.SourceSegmentCode
				AND ISNULL(MSLNK.SourceSegmentChoiceCode, 0) = ISNULL(PSLNK.SourceSegmentChoiceCode, 0)
				AND ISNULL(MSLNK.SourceChoiceOptionCode, 0) = ISNULL(PSLNK.SourceChoiceOptionCode, 0)
				AND MSLNK.LinkSource = PSLNK.LinkSource
				AND MSLNK.TargetSectionCode = PSLNK.TargetSectionCode
				AND MSLNK.TargetSegmentStatusCode = PSLNK.TargetSegmentStatusCode
				AND MSLNK.TargetSegmentCode = PSLNK.TargetSegmentCode
				AND ISNULL(MSLNK.TargetSegmentChoiceCode, 0) = ISNULL(PSLNK.TargetSegmentChoiceCode, 0)
				AND ISNULL(MSLNK.TargetChoiceOptionCode, 0) = ISNULL(PSLNK.TargetChoiceOptionCode, 0)
				AND MSLNK.LinkTarget = PSLNK.LinkTarget
				AND MSLNK.LinkStatusTypeId = PSLNK.LinkStatusTypeId
  WHERE 
  MSLNK.IsDeleted = 0  
  AND (MSLNK.SourceSectionCode = @SectionCode  
  OR MSLNK.TargetSectionCode = @SectionCode) 
  AND PSLNK.SegmentLinkId IS NULL  
END
END

GO
