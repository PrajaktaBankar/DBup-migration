/*
 server name : SLCProject_SqlSlcOp003
 Customer Support 41683: SLC Submittal Report not reporting all data in project

 ---For references-----

*/

DECLARE @PProjectId INT = 5466;
DECLARE @PCustomerId INT = 1191;
DECLARE @PUserId INT = 19231;


DROP TABLE IF EXISTS #TempProjectSegmentStatus;
SELECT
PSS.SegmentStatusId
,PSS.mSegmentStatusId
,PSS.SectionId
,PSS.ProjectId
,PSS.CustomerId
INTO #TempProjectSegmentStatus
FROM [dbo].ProjectSegmentStatus PSS WITH (NOLOCK)
WHERE PSS.ProjectId = @PProjectId
AND PSS.CustomerId = @PCustomerId;

DROP TABLE IF EXISTS #TempProjectSegmentRequirementTag;
SELECT
PSRT.SectionId
,PSRT.ProjectId
,PSRT.CustomerId
,PSRT.mSegmentRequirementTagId
,PSRT.SegmentRequirementTagId
INTO #TempProjectSegmentRequirementTag
FROM [dbo].ProjectSegmentRequirementTag PSRT WITH (NOLOCK)
WHERE PSRT.ProjectId = @PProjectId
AND PSRT.CustomerId = @PCustomerId;

INSERT INTO [dbo].ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId, CreateDate, ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy, mSegmentRequirementTagId)
SELECT
PSST.SectionId
,PSST.SegmentStatusId
,MSRT.RequirementTagId
,GETUTCDATE() AS CreateDate
,GETUTCDATE() AS ModifiedDate
,@PProjectId AS ProjectId
,@PCustomerId AS CustomerId
,@PUserId AS CreatedBy
,@PUserId AS ModifiedBy
,MSRT.SegmentRequirementTagId AS mSegmentRequirementTagId
FROM [SLCMaster].[dbo].SegmentRequirementTag MSRT WITH (NOLOCK)
INNER JOIN [dbo].LuProjectRequirementTag LuPRT WITH (NOLOCK)
ON MSRT.RequirementTagId = LuPRT.RequirementTagId
INNER JOIN ProjectSection ps
ON MSRT.SectionId=ps.mSectionId
AND ps.CustomerId=@PCustomerId
AND ps.ProjectId=@PProjectId
INNER JOIN #TempProjectSegmentStatus PSST WITH (NOLOCK)
ON MSRT.SegmentStatusId = PSST.mSegmentStatusId
LEFT JOIN #TempProjectSegmentRequirementTag PSRT WITH (NOLOCK)
ON PSRT.SectionId = ps.SectionId
AND PSRT.ProjectId = @PProjectId
AND PSRT.CustomerId = @PCustomerId
AND PSRT.mSegmentRequirementTagId IS NOT NULL
AND PSRT.mSegmentRequirementTagId = MSRT.SegmentRequirementTagId
WHERE PSST.SectionId = ps.SectionId
AND PSST.ProjectId = @PProjectId
AND PSST.CustomerId = @PCustomerId
AND MSRT.SectionId = ps.mSectionId
AND PSRT.SegmentRequirementTagId IS NULL



