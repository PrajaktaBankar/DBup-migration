CREATE PROCEDURE [dbo].[usp_SpecDataActivateDeactivateMappedSegment]
(    
   @SegmentStatusJson NVARCHAR(max)    
)    
AS
begin
DECLARE @TempMappingtable TABLE (    
ProjectId INT    
,CustomerId INT    
,SectionId INT    
,SegmentStatusId BIGINT    
,ActionTypeId INT    
,RowId INT    
)

INSERT INTO @TempMappingtable
	SELECT
		*
	   ,0

	FROM OPENJSON(@SegmentStatusJson)
	WITH (
	ProjectId INT '$.ProjectId',
	CustomerId INT '$.CustomerId',
	SectionId INT '$.SectionId',
	SegmentStatusId BIGINT '$.SegmentStatusId',
	ActionTypeId INT '$.ActionTypeId'
	);


DROP TABLE IF EXISTS #TempStatusTable

SELECT DISTINCT
	ProjectId
   ,CustomerId
   ,SectionId
   ,SegmentStatusId
   ,ActionTypeId INTO #TempStatusTable
FROM @TempMappingtable

DROP TABLE IF EXISTS #TempTableTempStatus

;
WITH cte
AS
(SELECT
		PSS.SegmentStatusId
	   ,PSS.ParentSegmentStatusId
	   ,PSS.SegmentStatusTypeId
	   ,pss.SectionId
	   ,pss.ProjectId
	FROM ProjectSegmentStatusview pss WITH (NOLOCK)
	INNER JOIN #TempStatusTable tmp
		ON pss.mSectionId = tmp.SectionId 
		AND pss.mSegmentStatusId = tmp.SegmentStatusId
		AND tmp.ProjectId = pss.ProjectId
		
	UNION ALL
	SELECT
		PSS.SegmentStatusId
	   ,PSS.ParentSegmentStatusId
	   ,PSS.SegmentStatusTypeId
	   ,pss.SectionId
	   ,pss.ProjectId
	FROM ProjectSegmentStatus pss WITH (NOLOCK)
	INNER JOIN cte c
		ON c.ParentSegmentStatusId = pss.SegmentStatusId
		AND pss.SectionId = c.SectionId
		AND pss.ProjectId = c.ProjectId
		 -- this is the recursion
)

SELECT
	SegmentStatusId
   ,ParentSegmentStatusId
   ,SegmentStatusTypeId
   ,SectionId
   ,ProjectId INTO #TempTableTempStatus
FROM cte

IF ((SELECT
			COUNT(*)
		FROM #TempTableTempStatus)
	= 0)
BEGIN

;
WITH cte
AS
(SELECT
		PSS.SegmentStatusId
	   ,PSS.ParentSegmentStatusId
	   ,PSS.SegmentStatusTypeId
	   ,pss.SectionId
	   ,pss.ProjectId
	FROM ProjectSegmentStatusview pss WITH (NOLOCK)
	INNER JOIN #TempStatusTable tmp
		ON pss.SegmentStatusId = tmp.SegmentStatusId
		AND pss.SectionId = tmp.SectionId
		AND tmp.ProjectId = pss.ProjectId
		
	UNION ALL
	SELECT
		PSS.SegmentStatusId
	   ,PSS.ParentSegmentStatusId
	   ,PSS.SegmentStatusTypeId
	   ,pss.SectionId
	   ,pss.ProjectId
	FROM ProjectSegmentStatus pss WITH (NOLOCK)
	INNER JOIN cte c
		ON c.ParentSegmentStatusId = pss.SegmentStatusId 
		AND  pss.SectionId = c.SectionId
		AND pss.ProjectId = c.ProjectId)
		 -- this is the recursion

UPDATE pss    
SET pss.IsParentSegmentStatusActive = 1    
,SegmentStatusTypeId = 2    
,SpecTypeTagId = 2    
FROM ProjectSegmentStatus pss WITH (NOLOCK)  
INNER JOIN cte c
 ON c.SegmentStatusId = pss.SegmentStatusId
		AND c.SectionId = pss.SectionId
		AND c.ProjectId = pss.ProjectId

END
ELSE
BEGIN


UPDATE pss    
SET pss.IsParentSegmentStatusActive = 1    
,SegmentStatusTypeId = 2    
,SpecTypeTagId = 2    
FROM ProjectSegmentStatus pss WITH (NOLOCK)  
INNER JOIN #TempTableTempStatus c
 ON c.SegmentStatusId = pss.SegmentStatusId
		AND c.SectionId = pss.SectionId
		AND c.ProjectId = pss.ProjectId


END
END
GO


