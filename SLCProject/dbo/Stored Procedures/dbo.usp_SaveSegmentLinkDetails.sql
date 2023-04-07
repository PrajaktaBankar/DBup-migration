CREATE PROCEDURE [dbo].[usp_SaveSegmentLinkDetails]    
	-- Add the parameters for the stored procedure here
	@ProjectId INT,
	@CustomerId INT,
	@UserId INT,
	@SegmentLinkId BIGINT,
	@SourceSectionCode INT,
	@SourceSegmentStatusCode BIGINT,
	@SourceSegmentCode BIGINT,
	@SourceSegmentChoiceCode BIGINT,
	@SourceChoiceOptionCode BIGINT,
	@LinkSource NVARCHAR(MAX),
	@TargetSectionCode INT,
	@TargetSegmentStatusCode BIGINT,
	@TargetSegmentCode BIGINT,
	@TargetSegmentChoiceCode BIGINT,
	@TargetChoiceOptionCode BIGINT,
	@LinkTarget NVARCHAR(MAX),
	@LinkStatusTypeId INT,
	@SegmentLinkCode BIGINT,
	@SegmentLinkSourceTypeId INT,
	@LinkActionType INT
AS
BEGIN
	DECLARE @PProjectId INT = @ProjectId;
	DECLARE @PCustomerId INT = @CustomerId;
	DECLARE @PUserId INT = @UserId;
	DECLARE @PSegmentLinkId BIGINT = @SegmentLinkId;
	DECLARE @PSourceSectionCode INT = @SourceSectionCode;
	DECLARE @PSourceSegmentStatusCode BIGINT = @SourceSegmentStatusCode;
	DECLARE @PSourceSegmentCode BIGINT = @SourceSegmentCode;
	DECLARE @PSourceSegmentChoiceCode BIGINT = @SourceSegmentChoiceCode;
	DECLARE @PSourceChoiceOptionCode BIGINT = @SourceChoiceOptionCode;
	DECLARE @PLinkSource NVARCHAR(MAX) = @LinkSource;
	DECLARE @PTargetSectionCode INT = @TargetSectionCode
	DECLARE @PTargetSegmentStatusCode BIGINT = @TargetSegmentStatusCode;
	DECLARE @PTargetSegmentCode BIGINT = @TargetSegmentCode;
	DECLARE @PTargetSegmentChoiceCode BIGINT = @TargetSegmentChoiceCode;
	DECLARE @PTargetChoiceOptionCode BIGINT = @TargetChoiceOptionCode
	DECLARE @PLinkTarget NVARCHAR(MAX) = @LinkTarget;
	DECLARE @PLinkStatusTypeId INT = @LinkStatusTypeId;
	DECLARE @PSegmentLinkCode BIGINT = @SegmentLinkCode;
	DECLARE @PSegmentLinkSourceTypeId INT = @SegmentLinkSourceTypeId;
	DECLARE @PLinkActionType INT = @LinkActionType;
DECLARE @IsSuccess BIT = 1;
DECLARE @ErrorMsg NVARCHAR(MAX) = '';

DECLARE @CreateLinkActionType_CNST INT = 1;
DECLARE @UpdateLinkActionType_CNST INT = 2;
DECLARE @DeleteLinkActionType_CNST INT = 3;
DECLARE @UserSegmentLinkSourceTypeId_CNST INT = 5;
DECLARE @MasterSegmentLinkSourceTypeId_CNST INT = 1;
DECLARE @DefaultLinkStatusTypeId_CNST INT = 3;

DECLARE @SavedSegmentLinkId BIGINT = 0;

--SET DEFAULT LINK STATUS TYPE ID IF NOT PASSED IN ANY CONDITION
IF @PLinkStatusTypeId NOT IN (SELECT
		LinkStatusTypeId
	FROM LuProjectLinkStatusType WITH (NOLOCK))
BEGIN
SET @PLinkStatusTypeId = @DefaultLinkStatusTypeId_CNST;
END

--TRY TO UPDATE SourceSegmentCode and TargetSegmentCode
SELECT TOP 1
	@PSourceSegmentCode = PSSTV.SegmentCode
FROM ProjectSegmentStatusView PSSTV WITH (NOLOCK)
WHERE PSSTV.ProjectId = @PProjectId
AND PSSTV.CustomerId = @PCustomerId
AND PSSTV.SectionCode = @PSourceSectionCode
AND PSSTV.SegmentStatusCode = @PSourceSegmentStatusCode
AND ISNULL(IsDeleted,0) = 0;

SELECT TOP 1
	@PTargetSegmentCode = PSSTV.SegmentCode
FROM ProjectSegmentStatusView PSSTV WITH (NOLOCK)
WHERE PSSTV.ProjectId = @PProjectId
AND PSSTV.CustomerId = @PCustomerId
AND PSSTV.SectionCode = @PTargetSectionCode
AND PSSTV.SegmentStatusCode = @PTargetSegmentStatusCode
AND ISNULL(IsDeleted,0) = 0;

--CHECK FOR VALIDATIONS
--CHECK SAME ENTRY ALREADY EXISTS IN CASE OF CREATE IN PROJECT DB
IF @PLinkActionType = @CreateLinkActionType_CNST
BEGIN
IF EXISTS (SELECT TOP 1
			SegmentLinkId
		FROM ProjectSegmentLink WITH (NOLOCK)
		WHERE SourceSectionCode = @PSourceSectionCode
		AND SourceSegmentStatusCode = @PSourceSegmentStatusCode
		AND COALESCE(SourceSegmentChoiceCode, 0) = @PSourceSegmentChoiceCode
		AND COALESCE(SourceChoiceOptionCode, 0) = @PSourceChoiceOptionCode
		AND LinkSource = @PLinkSource
		AND TargetSectionCode = @PTargetSectionCode
		AND TargetSegmentStatusCode = @PTargetSegmentStatusCode
		AND COALESCE(TargetSegmentChoiceCode, 0) = @PTargetSegmentChoiceCode
		AND COALESCE(TargetChoiceOptionCode, 0) = @PTargetChoiceOptionCode
		AND LinkTarget = @PLinkTarget
		AND ProjectId = @PProjectId
		AND CustomerId = @PCustomerId
		AND IsDeleted = 0)
BEGIN
SET @IsSuccess = 0;
SET @ErrorMsg = 'Duplicate links are not allowed'
END
END

--CHECK SAME ENTRY ALREADY EXISTS IN CASE OF CREATE IN MASTER DB
--TODO--Need to check below condition really needed
IF @PLinkActionType = @CreateLinkActionType_CNST
BEGIN
IF EXISTS (SELECT TOP 1
		SegmentLinkId
	FROM SLCMaster..SegmentLink WITH (NOLOCK)
	WHERE SourceSectionCode = @PSourceSectionCode
	AND SourceSegmentStatusCode = @PSourceSegmentStatusCode
	AND COALESCE(SourceSegmentChoiceCode, 0) = @PSourceSegmentChoiceCode
	AND COALESCE(SourceChoiceOptionCode, 0) = @PSourceChoiceOptionCode
	AND LinkSource = @PLinkSource
	AND TargetSectionCode = @PTargetSectionCode
	AND TargetSegmentStatusCode = @PTargetSegmentStatusCode
	AND COALESCE(TargetSegmentChoiceCode, 0) = @PTargetSegmentChoiceCode
	AND COALESCE(TargetChoiceOptionCode, 0) = @PTargetChoiceOptionCode
	AND LinkTarget = @PLinkTarget
	AND IsDeleted = 0)
BEGIN
SET @IsSuccess = 0;
SET @ErrorMsg = 'Duplicate links are not allowed'
END
END


--CHECK SAME ENTRY ALREADY EXISTS IN CASE OF UPDATE
IF @PLinkActionType = @UpdateLinkActionType_CNST
BEGIN
IF EXISTS (SELECT TOP 1
		SegmentLinkId
	FROM ProjectSegmentLink WITH (NOLOCK)
	WHERE  ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND SourceSectionCode = @PSourceSectionCode
	AND SourceSegmentStatusCode = @PSourceSegmentStatusCode
	AND COALESCE(SourceSegmentChoiceCode, 0) = @PSourceSegmentChoiceCode
	AND COALESCE(SourceChoiceOptionCode, 0) = @PSourceChoiceOptionCode
	AND LinkSource = @PLinkSource
	AND TargetSectionCode = @PTargetSectionCode
	AND TargetSegmentStatusCode = @PTargetSegmentStatusCode
	AND COALESCE(TargetSegmentChoiceCode, 0) = @PTargetSegmentChoiceCode
	AND COALESCE(TargetChoiceOptionCode, 0) = @PTargetChoiceOptionCode
	AND LinkTarget = @PLinkTarget
	AND LinkStatusTypeId = @PLinkStatusTypeId	
	AND IsDeleted = 0)
BEGIN
SET @IsSuccess = 0;
SET @ErrorMsg = 'Duplicate links are not allowed'
END
END

--MASTER LINK IS GOING TO BE MODIFY
IF @PLinkActionType = @UpdateLinkActionType_CNST AND @PSegmentLinkSourceTypeId = @MasterSegmentLinkSourceTypeId_CNST
BEGIN
SET @IsSuccess = 0;
SET @ErrorMsg = 'Master links cannot be modified'
END

--CHECK WHETHER SOURCE AND TARGET IS SAME
IF @PLinkActionType = @CreateLinkActionType_CNST OR @PLinkActionType = @UpdateLinkActionType_CNST
BEGIN
IF @PSourceSectionCode = @PTargetSectionCode AND 
@PSourceSegmentStatusCode = @PTargetSegmentStatusCode AND 
@PSourceSegmentChoiceCode = @PTargetSegmentChoiceCode AND 
@PSourceChoiceOptionCode = @PTargetChoiceOptionCode
BEGIN
SET @IsSuccess = 0;
SET @ErrorMsg = 'The paragraph cannot be both Source and Target of same link'
END
END

--CHECK FOR CIRCULAR LINKS
IF @PLinkActionType = @CreateLinkActionType_CNST OR @PLinkActionType = @UpdateLinkActionType_CNST
BEGIN
DECLARE @CircularLinkStatusTypeId INT;
SET @CircularLinkStatusTypeId = (SELECT
	TOP 1
		LinkStatusTypeId
	FROM ProjectSegmentLink WITH (NOLOCK)
	WHERE  ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND SourceSectionCode = @PTargetSectionCode
	AND SourceSegmentStatusCode = @PTargetSegmentStatusCode
	AND COALESCE(SourceSegmentChoiceCode, 0) = @PTargetSegmentChoiceCode
	AND COALESCE(SourceChoiceOptionCode, 0) = @PTargetChoiceOptionCode
	AND TargetSectionCode = @PSourceSectionCode
	AND TargetSegmentStatusCode = @PSourceSegmentStatusCode
	AND COALESCE(TargetSegmentChoiceCode, 0) = @PSourceSegmentChoiceCode
	AND COALESCE(TargetChoiceOptionCode, 0) = @PSourceChoiceOptionCode
	AND IsDeleted = 0)
IF @CircularLinkStatusTypeId IS NOT NULL AND 
	(
		(@PLinkStatusTypeId = 3 AND @CircularLinkStatusTypeId = 4) OR 
		(@PLinkStatusTypeId = 4 AND @CircularLinkStatusTypeId = 3)
	)
BEGIN
SET @IsSuccess = 0;
SET @ErrorMsg = 'Circular links cannot be created'
END
END

--If choice link exists between a paragraph and the corresponding RS paragraph, do not add a new paragraph link
IF EXISTS (SELECT TOP 1
			SegmentLinkId
		FROM ProjectSegmentLink WITH (NOLOCK)
		WHERE SourceSectionCode = @PSourceSectionCode
		AND SourceSegmentStatusCode = @PSourceSegmentStatusCode
		AND ISNULL(SourceSegmentChoiceCode, 0) > 0
		AND ISNULL(SourceChoiceOptionCode, 0) > 0
		AND LinkSource = @PLinkSource
		AND TargetSectionCode = @PTargetSectionCode
		AND TargetSegmentStatusCode = @PTargetSegmentStatusCode
		AND LinkTarget = @PLinkTarget
		AND ProjectId = @PProjectId
		AND CustomerId = @PCustomerId
		AND ISNULL(IsDeleted, 0) = 0)
BEGIN
	DECLARE @SegmentId BIGINT = (SELECT SegmentId FROM ProjectSegmentStatus WITH (NOLOCK) WHERE CustomerId = @CustomerId
								AND ProjectId = @ProjectId AND SegmentStatusCode = @TargetSegmentStatusCode)

	DECLARE @SegmentDescription NVARCHAR(MAX) = (SELECT SegmentDescription FROM ProjectSegment WITH (NOLOCK) WHERE CustomerId = @CustomerId
								AND ProjectId = @ProjectId AND SegmentId = @SegmentId)

	IF(@SegmentDescription LIKE '%rstemp%')
		SET @IsSuccess = 0;

END

--CREATE
IF @PLinkActionType = @CreateLinkActionType_CNST AND @IsSuccess = 1
BEGIN
INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,
TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget,
LinkStatusTypeId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, ProjectId, CustomerId, SegmentLinkSourceTypeId)
	SELECT
		@PSourceSectionCode AS SourceSectionCode
	   ,@PSourceSegmentStatusCode AS SourceSegmentStatusCode
	   ,NULLIF(@PSourceSegmentCode,0) AS SourceSegmentCode
	   ,NULLIF(@PSourceSegmentChoiceCode, 0) AS SourceSegmentChoiceCode
	   ,NULLIF(@PSourceChoiceOptionCode, 0) AS SourceChoiceOptionCode
	   ,@PLinkSource AS LinkSource
	   ,@PTargetSectionCode AS TargetSectionCode
	   ,@PTargetSegmentStatusCode AS TargetSegmentStatusCode
	   ,@PTargetSegmentCode AS TargetSegmentCode
	   ,NULLIF(@PTargetSegmentChoiceCode, 0) AS TargetSegmentChoiceCode
	   ,NULLIF(@PTargetChoiceOptionCode, 0) AS TargetChoiceOptionCode
	   ,@PLinkTarget AS LinkTarget
	   ,@PLinkStatusTypeId AS LinkStatusTypeId
	   ,GETUTCDATE() AS CreateDate
	   ,@PUserId AS CreatedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,@PUserId AS ModifiedBy
	   ,@PProjectId AS ProjectId
	   ,@PCustomerId AS CustomerId
	   ,@PSegmentLinkSourceTypeId AS SegmentLinkSourceTypeId

SET @SavedSegmentLinkId = SCOPE_IDENTITY();
END
ELSE
--UPDATE
IF @PLinkActionType = @UpdateLinkActionType_CNST AND @IsSuccess = 1
BEGIN

UPDATE PSLNK
SET PSLNK.LinkStatusTypeId = @PLinkStatusTypeId
FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
WHERE PSLNK.SegmentLinkId = @PSegmentLinkId

SET @SavedSegmentLinkId = @PSegmentLinkId
END
ELSE
--DELETE
IF @PLinkActionType = @DeleteLinkActionType_CNST AND @IsSuccess = 1
BEGIN
UPDATE PSL
SET PSL.IsDeleted = 1
FROM ProjectSegmentLink PSL WITH (NOLOCK)
WHERE PSL.SegmentLinkId = @SegmentLinkId
AND PSL.SegmentLinkSourceTypeId = @UserSegmentLinkSourceTypeId_CNST;

SET @SavedSegmentLinkId = @SegmentLinkId
END

--SELECT FINAL RESULT
SELECT
	@SavedSegmentLinkId AS SegmentLinkId
   ,@IsSuccess AS IsSuccess
   ,@ErrorMsg AS ErrorMsg
END
GO


