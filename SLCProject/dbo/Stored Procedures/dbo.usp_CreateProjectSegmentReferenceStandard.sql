

CREATE PROCEDURE [dbo].[usp_CreateProjectSegmentReferenceStandard]  
@ProjectId INT NULL, 
@RefStandardId INT NULL,
@RefStdSource CHAR NULL,
@RefStdCode INT NULL, 
@RefStdEditionId INT NULL,
@mReplaceRefStdId INT NULL,
@IsObsolete BIT NULL, 
@SectionId INT NULL, 
@CustomerId INT NULL,
@SegmentId BIGINT NULL,
@RefStandardSource CHAR  NULL,
@CreatedBy INT NULL,
@mRefStandardId INT NULL,
@mSegmentId INT NULL
AS      

BEGIN
DECLARE @PProjectId INT = @ProjectId
DECLARE @PRefStandardId INT = @RefStandardId;
DECLARE @PRefStdSource CHAR = @RefStdSource;
DECLARE @PRefStdCode INT = @RefStdCode;
DECLARE @PRefStdEditionId INT = @RefStdEditionId;
DECLARE @PmReplaceRefStdId INT = @mReplaceRefStdId;
DECLARE @PIsObsolete BIT = @IsObsolete;
DECLARE @PSectionId INT = @SectionId
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PSegmentId BIGINT = @SegmentId;
DECLARE @PRefStandardSource CHAR = @RefStandardSource;
DECLARE @PCreatedBy INT = @CreatedBy;
DECLARE @PmRefStandardId INT = @mRefStandardId;
DECLARE @PmSegmentId INT = @mSegmentId;
--Set Nocount On
SET NOCOUNT ON;

    DECLARE @ProjSegmentRefStdCount INT = NULL
	DECLARE @ProjRefStdCount INT = NULL
	DECLARE @ProjRefStdEditionId INT = NULL

SET @ProjSegmentRefStdCount = (SELECT
		COUNT(1)
	FROM ProjectSegmentReferenceStandard WITH (NOLOCK)
	WHERE ProjectId = @PProjectId AND SectionId = @PSectionId
	AND (SegmentId = @PSegmentId
	OR mSegmentId = @PmSegmentId)
	AND RefStdCode = @PRefStdCode
	AND RefStandardId = @PRefStandardId
	AND CustomerId = @PCustomerId
	AND IsDeleted = 0)

	SELECT
		SectionId,RefStdEditionId,RefStdSource INTO #TempProjectReferenceStandard
	FROM ProjectReferenceStandard WITH (NOLOCK)
	WHERE 
	RefStandardId = @PRefStandardId
	AND ProjectId = @PProjectId
	AND RefStdCode = @PRefStdCode
	AND CustomerId = @PCustomerId
	AND IsDeleted = 0

SET @ProjRefStdCount = (SELECT
		COUNT(1)
	FROM #TempProjectReferenceStandard WITH (NOLOCK)
	WHERE SectionId = @PSectionId
	)

    IF @PSegmentId = 0
        BEGIN
SET @PSegmentId = NULL;
  
        END
    IF @PmSegmentId = 0
        BEGIN
SET @PmSegmentId = NULL;
  
        END
  
    IF(ISNULL(@ProjRefStdCount,0)>0)
      BEGIN
 SELECT TOP 1
		@ProjRefStdEditionId = RefStdEditionId
	FROM #TempProjectReferenceStandard
	WHERE RefStdSource = 'U'
	OPTION (FAST 1)
	

	  IF ISNULL(@ProjRefStdEditionId,0) > 0
BEGIN
SET @PRefStdEditionId = @ProjRefStdEditionId
					END

INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, RefStdCode, RefStdEditionId,
mReplaceRefStdId, IsObsolete, SectionId, CustomerId, PublicationDate)
	VALUES (@PProjectId, @PRefStandardId, @RefStdSource, @PRefStdCode, @PRefStdEditionId, @PmReplaceRefStdId, @PIsObsolete, @PSectionId, @PCustomerId, NULL)
END


IF (ISNULL(@ProjSegmentRefStdCount, 0) > 0)
BEGIN
INSERT INTO ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource, mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, mSegmentId, RefStdCode)
	VALUES (@PSectionId, @PSegmentId, @PRefStandardId, @PRefStandardSource, @PmRefStandardId, GETUTCDATE(), @PCreatedBy, GETUTCDATE(), NULL, @PCustomerId, @PProjectId, @PmSegmentId, @PRefStdCode)
END


END
GO



