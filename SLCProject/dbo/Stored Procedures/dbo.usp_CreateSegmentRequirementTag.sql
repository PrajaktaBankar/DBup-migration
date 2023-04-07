CREATE PROCEDURE [dbo].[usp_CreateSegmentRequirementTag]    
@CustomerId INT, @ProjectId INT, @SectionId INT, @SegmentStatusId BIGINT, @TagType NVARCHAR(255) NULL, @UserId INT    
AS      
BEGIN
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId;
DECLARE @PTagType NVARCHAR(255) = @TagType;
DECLARE @PUserId INT = @UserId;

--Set Nocount On
SET NOCOUNT ON;

	IF EXISTS (SELECT TOP 1 1 FROM LuProjectRequirementTag WITH(NoLock) WHERE TagType = @PTagType)
	BEGIN
		SELECT DISTINCT RequirementTagId 
		INTO #RequirementTagIds
		FROM ProjectSegmentRequirementTag PSRT with(nolock) 
		WHERE PSRT.SegmentStatusId = @PSegmentStatusId
		AND PSRT.SectionId=@PSectionId AND PSRT.ProjectId=@PProjectId

		INSERT INTO ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId, CreateDate, ModifiedDate, ProjectId, CustomerId,
		CreatedBy, ModifiedBy)
			SELECT
				@PSectionId
			   ,@PSegmentStatusId
			   ,PRTG.RequirementTagId
			   ,GETUTCDATE()
			   ,GETUTCDATE()
			   ,@PProjectId
			   ,@PCustomerId
			   ,@PUserId
			   ,@PUserId
			FROM LuProjectRequirementTag PRTG WITH(NoLock) 
			LEFT OUTER JOIN #RequirementTagIds RTI
			ON PRTG.RequirementTagId=RTI.RequirementTagId
			WHERE PRTG.TagType = @PTagType AND RTI.RequirementTagId IS NULL
	END
END
GO


