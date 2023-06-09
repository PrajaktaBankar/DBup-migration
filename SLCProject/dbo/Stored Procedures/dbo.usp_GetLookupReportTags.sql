
CREATE PROCEDURE [dbo].[usp_GetLookupReportTags]                    
@CustomerId INT   
AS    
BEGIN
  
DECLARE @PCustomerId INT = @CustomerId;

--DECLARE @ReportTagTbl TABLE(  
-- TagType NVARCHAR(MAX),  
-- TagName NVARCHAR(MAX),  
-- SegmentStatusCount INT,  
-- IsUserTag BIT,  
-- RequirementTagId INT,  
-- UserTagId INT,  
-- IsSystemTag BIT  
--);

--NOTE-Show IsSystem NP/NS/PL tags in lookup list only for migrated one  
--Creating temp table to get to know whether user tag of IsSystem   
SELECT
	PUT.UserTagId INTO #UsedIsSystemReportTagsTbl
FROM [dbo].ProjectUserTag PUT WITH (NOLOCK)
INNER JOIN [dbo].ProjectSegmentUserTag PSUT WITH (NOLOCK)
	ON PSUT.CustomerId = @PCustomerId AND PSUT.UserTagId = PUT.UserTagId
		--AND PSUT.CustomerId = PUT.CustomerId
WHERE PUT.CustomerId = @PCustomerId
AND PUT.IsSystemTag = 1
GROUP BY PUT.UserTagId

--INSERT VALUES IN ReportTag TABLE  
--INSERT INTO @ReportTagTbl (TagType, TagName, SegmentStatusCount, IsUserTag, RequirementTagId, UserTagId, IsSystemTag)
	SELECT
		LPRT.TagType
	   ,LPRT.Description as TagName
	   ,0 AS SegmentStatusCount
	   ,CAST(0 AS BIT) AS IsUserTag
	   ,LPRT.RequirementTagId
	   ,0 AS UserTagId
	   ,CAST(1 AS BIT) AS IsSystemTag
	FROM LuProjectRequirementTag LPRT WITH (NOLOCK)
	WHERE LPRT.IsActive = 1
	UNION ALL
	SELECT
		PUT.TagType
	   ,PUT.Description as TagName
	   ,0 AS SegmentStatusCount
	   ,CAST(1 AS BIT) AS IsUserTag
	   ,0 AS RequirementTagId
	   ,PUT.UserTagId
	   ,PUT.IsSystemTag
	FROM ProjectUserTag PUT WITH (NOLOCK)
	WHERE PUT.CustomerId = @PCustomerId
	AND PUT.IsSystemTag = 0
	UNION ALL
	SELECT
		PUT.TagType
	   ,PUT.Description as TagName
	   ,0 AS SegmentStatusCount
	   ,CAST(1 AS BIT) AS IsUserTag
	   ,0 AS RequirementTagId
	   ,PUT.UserTagId
	   ,PUT.IsSystemTag
	FROM [dbo].ProjectUserTag PUT WITH (NOLOCK)
	INNER JOIN #UsedIsSystemReportTagsTbl URTTBL
		ON PUT.UserTagId = URTTBL.UserTagId
	WHERE PUT.CustomerId = @PCustomerId
	AND PUT.IsSystemTag = 1

--SELECT
--	*
--FROM @ReportTagTbl
END
GO



