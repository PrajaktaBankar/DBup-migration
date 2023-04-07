CREATE PROCEDURE [dbo].[usp_GetTagListForReport]   
(   
@ProjectId INT,   
@SectionId INT,   
@CustomerId INT   
)   
AS   
BEGIN   
  
declare @PCustomerId INT = @CustomerId;   
declare @PProjectId INT = @ProjectId;   
  
DROP TABLE IF EXISTS #TagsData;   
DROP TABLE IF EXISTS #UsedTagIds;   
  
CREATE TABLE #TagsData(   
TagType nvarchar(255),   
TagName NVARCHAR(500),   
SegmentStatusCount INT,   
IsUserTag BIT,   
RequirementTagId INT,   
UserTagId INT,   
IsSystemTag BIT,   
CreateDate DATETIME2,   
IsUsedInProject BIT   
);   
  
insert into #TagsData   
SELECT   
LPRT.TagType   
,LPRT.Description AS TagName   
,0 AS SegmentStatusCount   
,CAST(0 AS BIT) AS IsUserTag   
,LPRT.RequirementTagId   
,0 AS UserTagId   
,CAST(1 AS BIT) AS IsSystemTag   
,NULL AS CreateDate   
,CAST(0 as BIT) AS IsUsedInProject   
FROM LuProjectRequirementTag LPRT WITH (NOLOCK)   
WHERE LPRT.IsActive = 1   
UNION   
SELECT   
PUT.TagType   
,PUT.Description AS TagName   
,0 AS SegmentStatusCount   
,CAST(1 AS BIT) AS IsUserTag   
,0 AS RequirementTagId   
,PUT.UserTagId   
,CAST(PUT.IsSystemTag AS BIT) AS IsSystemTag   
,PUT.CreateDate   
,CAST(0 as BIT) AS IsUsedInProject   
FROM ProjectUserTag PUT WITH (NOLOCK)   
WHERE PUT.CustomerId = @PCustomerId  and ISNULL(PUT.IsDeleted,0)=0 
ORDER BY description;   
  
UPDATE TD SET IsUsedInProject = 1   
FROM #TagsData TD   
INNER JOIN ProjectSegmentRequirementTag PSRT WITH (NOLOCK)   
ON TD.RequirementTagId = PSRT.RequirementTagId   
INNER JOIN ProjectSegmentStatusView PSSV WITH (NOLOCK)   
ON PSRT.SegmentStatusId = PSSV.SegmentStatusId   
WHERE PSSV.ProjectId = @PProjectId   
AND PSSV.CustomerId = @PCustomerId   
AND PSSV.IsDeleted = 0   
AND PSSV.IsSegmentStatusActive <> 0;   
  
UPDATE TD SET IsUsedInProject = 1   
FROM #TagsData TD   
INNER JOIN ProjectSegmentUserTag PSUT WITH (NOLOCK)   
ON TD.UserTagId = PSUT.UserTagId   
INNER JOIN ProjectSegmentStatusView PSSV WITH (NOLOCK)   
ON PSUT.SegmentStatusId = PSSV.SegmentStatusId   
WHERE PSSV.ProjectId = @PProjectId   
AND PSSV.CustomerId = @PCustomerId   
AND PSSV.IsDeleted = 0   
AND PSSV.IsSegmentStatusActive <> 0;   
  
select * from #TagsData;   
  
END