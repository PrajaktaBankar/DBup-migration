use SLCProject
go
declare @Customerid int = 783
declare @ProjectID int = 5188
declare @UserID int = 0 --to indicate this was system

--Customer Support 34308: Text tagged Non printing is printing (Grimm+Parker)
--Excute on server 03
--record inserted 7345
INSERT INTO ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId, CreateDate, ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy, mSegmentRequirementTagId)
	SELECT
		PSST.SectionId
	   ,PSST.SegmentStatusId
	   ,MSRT.RequirementTagId
	   ,GETUTCDATE() AS CreateDate
	   ,GETUTCDATE() AS ModifiedDate
	   ,@ProjectId AS ProjectID
	   ,@CustomerId AS CustomerId
	   ,@UserId AS CreatedBy
	   ,@UserId AS ModifiedBy
	   ,MSRT.SegmentRequirementTagId AS mSegmentRequirementTagId
	FROM SLCMaster..SegmentRequirementTag MSRT WITH (NOLOCK)
	INNER JOIN LuProjectRequirementTag LuPRT WITH (NOLOCK)
		ON MSRT.RequirementTagId = LuPRT.RequirementTagId
	INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)
		ON MSRT.SegmentStatusId = PSST.mSegmentStatusId
	LEFT JOIN ProjectSegmentRequirementTag PSRT WITH (NOLOCK)
		ON PSRT.ProjectId = @ProjectId
			AND PSRT.CustomerId = @CustomerId			
			AND PSRT.mSegmentRequirementTagId IS NOT NULL
			AND PSRT.mSegmentRequirementTagId = MSRT.SegmentRequirementTagId
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	AND PSRT.SegmentRequirementTagId IS NULL
	