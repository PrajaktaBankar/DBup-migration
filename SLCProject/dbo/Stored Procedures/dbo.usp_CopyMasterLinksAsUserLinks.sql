CREATE PROCEDURE [dbo].[usp_CopyMasterLinksAsUserLinks]
(@ProjectId INT, @CustomerId INT, @SegmentStatusId BIGINT, @UserId INT,@SectionId INT=0)  
AS         
BEGIN
BEGIN TRY
	DECLARE @PProjectId INT = @ProjectId;
	DECLARE @PCustomerId INT = @CustomerId;
	DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId;
	DECLARE @PUserId INT = @UserId;
	DECLARE @PSectionId INT = @SectionId;

	--Set Nocount On
	SET NOCOUNT ON;

	DECLARE @SegmentLinkSourceTypeId INT = 5;
	DECLARE @SegmentStatusCode BIGINT = NULL;
	DECLARE @MasterSegmentCode INT = NULL;
	DECLARE @UserSegmentCode BIGINT = NULL;
	DECLARE @SegmentSource CHAR(1) = NULL;

	--FETCH SEGMENT STATUS CODE AND MASTER+USER SEGMENT CODES
	SELECT
		@SegmentStatusCode = PSST.SegmentStatusCode
	   ,@MasterSegmentCode = MSG.SegmentCode
	   ,@UserSegmentCode = PSG.SegmentCode
	   ,@SegmentSource = 'U'
	FROM ProjectSegmentStatus PSST with (NOLOCK)
	INNER JOIN ProjectSegment PSG with (NOLOCK)
		ON PSST.SectionId=PSG.SectionId 
		AND PSST.SegmentId = PSG.SegmentId
		AND PSST.ProjectId=PSG.ProjectId
		--AND PSST.CustomerId=PSG.CustomerId
	INNER JOIN SLCMaster..Segment MSG with (NOLOCK)
		ON PSST.mSegmentId = MSG.SegmentId
	WHERE PSST.SectionId=@SectionId
	AND PSST.SegmentStatusId = @pSegmentStatusId
	AND PSST.ProjectId = @PProjectId
	AND PSST.SegmentOrigin = 'U'
	AND PSST.SegmentSource = 'M'
	AND PSST.CustomerId = @PCustomerId

	--DELETE PREVIOUS ENTRIES
	--UPDATE PSL
	--SET PSL.IsDeleted=1

	BEGIN TRANSACTION
		DELETE PSL
		FROM ProjectSegmentLink PSL WITH (NOLOCK)
		WHERE PSL.ProjectId = @PProjectId
		AND PSL.CustomerId = @PCustomerId
		AND ((PSL.SourceSegmentStatusCode = @SegmentStatusCode
		AND PSL.LinkSource = @SegmentSource
		AND PSL.SegmentLinkSourceTypeId = @SegmentLinkSourceTypeId)
		OR (PSL.TargetSegmentStatusCode = @SegmentStatusCode
		AND PSL.LinkTarget = @SegmentSource
		AND PSL.SegmentLinkSourceTypeId = @SegmentLinkSourceTypeId))

	--COPY MASTER LINKS AS USER LINKS
		INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode,
		SourceChoiceOptionCode, LinkSource, TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode,
		TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId,
		CreateDate, CreatedBy, ModifiedBy, ModifiedDate,
		ProjectId, CustomerId, SegmentLinkSourceTypeId)
		--INSERT USER LINKS WHERE SOURCE STATUS CODE MATCHES IN PROJECT DB
		SELECT
			PSLNK.SourceSectionCode
			,PSLNK.SourceSegmentStatusCode
			,@UserSegmentCode AS SourceSegmentCode
			,PSLNK.SourceSegmentChoiceCode
			,PSLNK.SourceChoiceOptionCode
			,@SegmentSource AS LinkSource
			,PSLNK.TargetSectionCode
			,PSLNK.TargetSegmentStatusCode
			,PSLNK.TargetSegmentCode
			,PSLNK.TargetSegmentChoiceCode
			,PSLNK.TargetChoiceOptionCode
			,PSLNK.LinkTarget
			,PSLNK.LinkStatusTypeId
			,GETUTCDATE() AS CreateDate
			,@PUserId AS CreatedBy
			,@PUserId AS ModifiedBy
			,GETUTCDATE() AS ModifiedDate
			,PSLNK.ProjectId AS ProjectId
			,PSLNK.CustomerId AS CustomerId
			,@SegmentLinkSourceTypeId AS SegmentLinkSourceTypeId
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
		WHERE PSLNK.SourceSegmentStatusCode = @SegmentStatusCode
		AND PSLNK.LinkSource = 'M'
		AND PSLNK.ProjectId = @PProjectId
		AND PSLNK.SourceSegmentCode = @MasterSegmentCode
		AND PSLNK.CustomerId = @PCustomerId
		AND ISNULL(PSLNK.IsDeleted,0) = 0
		UNION
		--INSERT USER LINKS WHERE TARGET SEGMENT STATUS CODE MATCHES IN PROJECT DB
		SELECT
			PSLNK.SourceSectionCode
			,PSLNK.SourceSegmentStatusCode
			,PSLNK.SourceSegmentCode
			,PSLNK.SourceSegmentChoiceCode
			,PSLNK.SourceChoiceOptionCode
			,PSLNK.LinkSource
			,PSLNK.TargetSectionCode
			,PSLNK.TargetSegmentStatusCode
			,@UserSegmentCode AS TargetSegmentCode
			,PSLNK.TargetSegmentChoiceCode
			,PSLNK.TargetChoiceOptionCode
			,@SegmentSource AS LinkTarget
			,PSLNK.LinkStatusTypeId
			,GETUTCDATE() AS CreateDate
			,@PUserId AS CreatedBy
			,@PUserId AS ModifiedBy
			,GETUTCDATE() AS ModifiedDate
			,PSLNK.ProjectId AS ProjectId
			,PSLNK.CustomerId AS CustomerId
			,@SegmentLinkSourceTypeId AS SegmentLinkSourceTypeId
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
		WHERE PSLNK.TargetSegmentStatusCode = @SegmentStatusCode
		AND PSLNK.LinkTarget = 'M'
		AND PSLNK.ProjectId = @PProjectId
		AND PSLNK.TargetSegmentCode = @MasterSegmentCode
		AND PSLNK.CustomerId = @PCustomerId
		AND ISNULL(PSLNK.IsDeleted,0) = 0
		IF @@Trancount > 0 COMMIT TRANSACTION
END TRY
	
BEGIN CATCH
	IF @@TRANCOUNT > 0	ROLLBACK
	INSERT INTO BsdLogging..AutoSaveLogging
		VALUES('usp_CopyMasterLinksAsUserLinks',
		GETDATE(),
		ERROR_MESSAGE(),
		ERROR_NUMBER(),
		ERROR_Severity(),
		ERROR_LINE(),
		ERROR_STATE(),
		ERROR_PROCEDURE(),
		CONCAT('exec usp_CopyMasterLinksAsUserLinks ',ISNULL(@PProjectId, 0),',',ISNULL(@PSectionId, 0),',',ISNULL(@PCustomerId, 0),',',ISNULL(@UserId, 0),',',ISNULL(@SegmentStatusId, 0)),
		CONCAT(ISNULL(@SegmentLinkSourceTypeId, 0),',',ISNULL(@SegmentStatusCode, 0),',',ISNULL(@MasterSegmentCode, 0),',',ISNULL(@UserSegmentCode, 0),',',ISNULL(@SegmentSource, 0)))
END CATCH
END
