
CREATE PROCEDURE [dbo].[usp_CreateReportTagsForSegment]
(
  @ReportTagsJson NVARCHAR(MAX),
  @CustomerId INT,
  @ProjectId INT,
  @SectionId INT,
  @SegmentStatusId BIGINT,
  @UserId INT
)
AS
BEGIN
  DECLARE @PReportTagsJson NVARCHAR(MAX) = @ReportTagsJson;
  DECLARE @PCustomerId INT = @CustomerId;
  DECLARE @PProjectId INT = @ProjectId;
  DECLARE @PSectionId INT = @SectionId;
  DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId;
  DECLARE @PUserId INT = @UserId;
--Set Nocount On
SET NOCOUNT ON;

	CREATE TABLE #ReportTagsTbl (
		CustomerId INT NULL,
		ProjectId INT NULL,
		SectionId INT NULL,
		SegmentStatusId BIGINT NULL,
		UserTagId INT NULL,
		CreateDate DATETIME2 NULL,
		CreatedBy INT NULL,
		ModifiedDate DATETIME2 NULL,
		ModifiedBy INT NULL,
		RequirementTagId INT NULL,
		MSegmentRequirementTagId INT NULL
	);

	INSERT INTO #ReportTagsTbl
	SELECT
		@PCustomerId AS CustomerId
	   ,@PProjectId AS ProjectId
	   ,@PSectionId AS SectionId
	   ,@PSegmentStatusId AS SegmentStatusId
	   ,UserTagId AS UserTagId
	   ,GETUTCDATE() AS CreateDate
	   ,@PUserId AS CreatedBy
	   ,NULL AS ModifiedDate
	   ,NULL AS ModifiedBy
	   ,requirementTagId AS RequirementTagId
	   ,NULL AS MSegmentRequirementTagId
	FROM OPENJSON(@PReportTagsJson)
	WITH (
	userTagId INT '$.UserTagId',
	createdBy NVARCHAR(MAX) '$.CreatedBy',
	modifiedBy INT '$.ModifiedBy',
	requirementTagId NVARCHAR(MAX) '$.RequirementTagId',
	mSegmentRequirementTagId NVARCHAR(MAX) '$.MSegmentRequirementTagId'
	);

	--Insert Master Tags
	INSERT INTO ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId, CreateDate,
	ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy, MSegmentRequirementTagId)
	SELECT
		t.SectionId
	   ,t.SegmentStatusId
	   ,t.RequirementTagId
	   ,t.CreateDate
	   ,t.ModifiedDate
	   ,t.ProjectId
	   ,t.CustomerId
	   ,t.CreatedBy
	   ,t.ModifiedBy
	   ,t.MSegmentRequirementTagId
	FROM #ReportTagsTbl t LEFT OUTER JOIN ProjectSegmentRequirementTag psrt WITH(NOLOCK)
	ON psrt.ProjectId = t.ProjectId and psrt.SectionId=t.SectionId and psrt.SegmentStatusId=t.SegmentStatusId and psrt.RequirementTagId=t.RequirementTagId
	WHERE ISNULL(t.RequirementTagId, 0) <> 0 and psrt.SegmentStatusId is NULL

	--Insert User Tags
	INSERT INTO ProjectSegmentUserTag (CustomerId, ProjectId, SectionId, SegmentStatusId,
	UserTagId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)
		SELECT
			CustomerId
		   ,ProjectId
		   ,SectionId
		   ,SegmentStatusId
		   ,UserTagId
		   ,CreateDate
		   ,CreatedBy
		   ,ModifiedDate
		   ,ModifiedBy
		FROM #ReportTagsTbl
		WHERE ISNULL(UserTagId, 0) <> 0
END
GO



