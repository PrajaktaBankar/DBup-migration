USE SLCProjecT
DECLARE @projectCount int=1;
DECLARE @ProjectId int=0;
DECLARE @CustomerId int=383;
DECLARE @UserID int = 0 --to indicate this was system

DROP TABLE if EXISTS #tempProject
SELECT ProjectId,CustomerId , null as status into #tempProject from Project WITH (NOLOCK) where CustomerId=@CustomerId 
--and ISNULL(IsPermanentDeleted,0)=0

WHILE(@projectCount>0)
BEGIN
select @projectCount=count(ProjectId) from #tempProject where isnull(status,0)=0
select top 1 @ProjectId= ProjectId from  #tempProject where isnull(status,0)=0
UPDATE #tempProject set status=1 where ProjectId=@ProjectId
print '@ProjectId' print @ProjectId

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
END

