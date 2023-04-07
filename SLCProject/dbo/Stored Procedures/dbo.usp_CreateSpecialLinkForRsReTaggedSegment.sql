CREATE PROCEDURE [dbo].[usp_CreateSpecialLinkForRsReTaggedSegment]    
@CustomerId INT, @ProjectId INT, @SectionId INT, @SegmentStatusId BIGINT, @UserId INT    
AS
BEGIN
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId
DECLARE @PUserId INT = @UserId;
--Set Nocount On
SET NOCOUNT ON;

DECLARE @SourceSectionCode INT;
DECLARE @SourceSegmentStatusCode BIGINT;
DECLARE @SourceSegmentCode BIGINT;
DECLARE @LinkSource NVARCHAR(1);
DECLARE @TargetSectionCode INT;
DECLARE @TargetSegmentStatusCode BIGINT;
DECLARE @TargetSegmentCode BIGINT;
DECLARE @LinkTarget NVARCHAR(1);
DECLARE @LinkStatusTypeId INT = 3;
DECLARE @SegmentLinkSourceTypeId INT = 2;

DECLARE @ParentSegmentStatusId BIGINT;
DECLARE @ParentSegmentId BIGINT;
DECLARE @SegmentId BIGINT;
DECLARE @mParentSegmentId INT;
DECLARE @mSegmentId INT;

SELECT @SourceSectionCode=SectionCode,
	@TargetSectionCode=SectionCode 
	FROM ProjectSection CPS WITH(NOLOCK)
WHERE SectionId=@PSectionId

SELECT @SourceSegmentStatusCode = CPSST.SegmentStatusCode
	  ,@LinkSource = CPSST.SegmentSource
	  ,@ParentSegmentStatusId=ParentSegmentStatusId
	  ,@mSegmentId=mSegmentId
	  ,@SegmentId=SegmentId
FROM ProjectSegmentStatus CPSST WITH(NOLOCK)
WHERE CPSST.SegmentStatusId = @PSegmentStatusId

SELECT @TargetSegmentStatusCode = PPSST.SegmentStatusCode
	  ,@LinkTarget = PPSST.SegmentSource
	  ,@mParentSegmentId=mSegmentId
	  ,@ParentSegmentId=SegmentId
FROM ProjectSegmentStatus PPSST WITH(NOLOCK)
WHERE PPSST.SegmentStatusId = @ParentSegmentStatusId

IF(ISNULL(@mSegmentId,0)=0)
BEGIN
	SELECT @SourceSegmentCode=SegmentCode
	FROM ProjectSegment PSG WITH(NOLOCK)
	WHERE SegmentId=@SegmentId
END
ELSE
BEGIN
	SELECT @SourceSegmentCode=SegmentCode
	FROM SLCMaster..Segment MSG WITH(NOLOCK)
	WHERE SegmentId=@mSegmentId
END

IF(ISNULL(@mParentSegmentId,0)=0)
BEGIN
	SELECT @TargetSegmentCode=SegmentCode
	FROM ProjectSegment PSG WITH(NOLOCK)
	WHERE SegmentId=@ParentSegmentId
END
ELSE
BEGIN
	SELECT @TargetSegmentCode=SegmentCode
	FROM SLCMaster..Segment MSG WITH(NOLOCK)
	WHERE SegmentId=@mParentSegmentId
END

EXEC usp_CreateSegmentLink @SourceSectionCode
						  ,@SourceSegmentStatusCode
						  ,@SourceSegmentCode
						  ,NULL
						  ,NULL
						  ,@LinkSource
						  ,@TargetSectionCode
						  ,@TargetSegmentStatusCode
						  ,@TargetSegmentCode
						  ,NULL
						  ,NULL
						  ,@LinkTarget
						  ,@LinkStatusTypeId
						  ,@PUserId
						  ,@PProjectId
						  ,@PCustomerId
						  ,@SegmentLinkSourceTypeId

END
GO


