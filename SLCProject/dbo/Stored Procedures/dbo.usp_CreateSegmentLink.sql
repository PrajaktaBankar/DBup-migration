CREATE PROCEDURE [dbo].[usp_CreateSegmentLink]    
@SourceSectionCode INT, @SourceSegmentStatusCode BIGINT, @SourceSegmentCode BIGINT, @SourceSegmentChoiceCode BIGINT NULL, @SourceChoiceOptionCode BIGINT NULL, @LinkSource NVARCHAR(500),
@TargetSectionCode INT, @TargetSegmentStatusCode BIGINT, @TargetSegmentCode BIGINT, @TargetSegmentChoiceCode BIGINT NULL, @TargetChoiceOptionCode BIGINT NULL, @LinkTarget NVARCHAR(500),
@LinkStatusTypeId INT, @UserId INT, @ProjectId INT, @CustomerId INT, @SegmentLinkSourceTypeId INT
AS      
BEGIN
DECLARE @PSourceSectionCode INT = @SourceSectionCode
DECLARE @PSourceSegmentStatusCode BIGINT = @SourceSegmentStatusCode
DECLARE @PSourceSegmentCode BIGINT = @SourceSegmentCode
DECLARE @PSourceSegmentChoiceCode BIGINT = @SourceSegmentChoiceCode;
DECLARE @PSourceChoiceOptionCode BIGINT = @SourceChoiceOptionCode;
DECLARE @PLinkSource NVARCHAR(500) = @LinkSource;
DECLARE @PTargetSectionCode INT = @TargetSectionCode;
DECLARE @PTargetSegmentStatusCode BIGINT = @TargetSegmentStatusCode;
DECLARE @PTargetSegmentCode BIGINT = @TargetSegmentCode;
DECLARE @PTargetSegmentChoiceCode BIGINT = @TargetSegmentChoiceCode;
DECLARE @PTargetChoiceOptionCode BIGINT = @TargetChoiceOptionCode;
DECLARE @PLinkTarget NVARCHAR(500) = @LinkTarget;
DECLARE @PLinkStatusTypeId INT = @LinkStatusTypeId;
DECLARE @PUserId INT = @UserId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PSegmentLinkSourceTypeId INT = @SegmentLinkSourceTypeId;
--Set Nocount On
SET NOCOUNT ON;

INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,
TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget,
LinkStatusTypeId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, ProjectId, CustomerId, SegmentLinkSourceTypeId)
	SELECT
		@PSourceSectionCode AS SourceSectionCode
	   ,@PSourceSegmentStatusCode AS SourceSegmentStatusCode
	   ,@PSourceSegmentCode AS SourceSegmentCode
	   ,@PSourceSegmentChoiceCode AS SourceSegmentChoiceCode
	   ,@PSourceChoiceOptionCode AS SourceChoiceOptionCode
	   ,@PLinkSource AS LinkSource
	   ,@PTargetSectionCode AS TargetSectionCode
	   ,@PTargetSegmentStatusCode AS TargetSegmentStatusCode
	   ,@PTargetSegmentCode AS TargetSegmentCode
	   ,@PTargetSegmentChoiceCode AS TargetSegmentChoiceCode
	   ,@PTargetChoiceOptionCode AS TargetChoiceOptionCode
	   ,@PLinkTarget AS LinkTarget
	   ,@PLinkStatusTypeId AS LinkStatusTypeId
	   ,GETUTCDATE() AS CreateDate
	   ,@PUserId AS CreatedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,@PUserId AS ModifiedBy
	   ,@PProjectId AS ProjectId
	   ,@PCustomerId AS CustomerId
	   ,@PSegmentLinkSourceTypeId AS SegmentLinkSourceTypeId
END
GO


