USE SLCProject
GO

DROP TABLE IF EXISTS #TempCustomer, #tempProjectSegmentRequirementTag

SELECT
	CustomerId
   ,ROW_NUMBER() OVER (ORDER BY CustomerId) AS RowNo INTO #TempCustomer
FROM Project WITH (NOLOCK)
WHERE ISNULL(IsMigrated, 0) = 1
GROUP BY CustomerId
ORDER BY RowNo

  SELECT
	*
FROM #TempCustomer order by RowNo desc

DECLARE @CustomerRowCount int=( SELECT
		COUNT(CustomerId)
	FROM #TempCustomer)

WHILE(@CustomerRowCount >0)
BEGIN

DECLARE @CustomerId int=( SELECT
	TOP 1
		CustomerId
	FROM #TempCustomer
	WHERE RowNo = @CustomerRowCount)

PRINT 'Customer No ' + CAST(@CustomerId AS NVARCHAR(20)) + ' Begin';

DROP TABLE IF EXISTS #tempProjectSegmentRequirementTag
--Delete master segment Requirement tag is inserted as mSegmentRequirementTagId 
--as null for same segment in slcProject database
select distinct
	psrt.SegmentRequirementTagId into #TempProjectSegmentRequirementTag
FROM ProjectSection ps WITH (NOLOCK)
INNER JOIN SLCMaster.dbo.SegmentRequirementTag slcmsrt WITH (NOLOCK)
	ON slcmsrt.SectionId = ps.mSectionId
INNER JOIN ProjectSegmentRequirementTag psrt WITH (NOLOCK)
	ON  ps.SectionId = psrt.SectionId
	    AND ps.ProjectId = psrt.ProjectId
		AND ps.CustomerId = psrt.CustomerId
		AND psrt.mSegmentRequirementTagId IS NULL
		AND psrt.RequirementTagId = slcmsrt.RequirementTagId
INNER JOIN ProjectSegmentStatus pss WITH (NOLOCK)
	ON   psrt.CustomerId = pss.CustomerId
		AND slcmsrt.SegmentStatusId = pss.mSegmentStatusId
		AND pss.SegmentStatusId = psrt.SegmentStatusId
		AND ps.CustomerId =  @CustomerId


DELETE psrt
	FROM ProjectSegmentRequirementTag psrt
	INNER JOIN #TempProjectSegmentRequirementTag tpsrt
		ON    CustomerId = @CustomerId and psrt.SegmentRequirementTagId = tpsrt.SegmentRequirementTagId
		
--Delete duplicate tag which is issystem flag is 1
DELETE FROM ProjectSegmentUserTag
WHERE CustomerId = @CustomerId
	AND UserTagId IN (SELECT
			UserTagId
		FROM ProjectUserTag WITH (NOLOCK)
		WHERE CustomerId = @CustomerId
		AND IsSystemTag = 1)
--Delete project User Tag which is issystem flag is 1
DELETE FROM ProjectUserTag
WHERE CustomerId = @CustomerId
	AND IsSystemTag = 1

SET @CustomerRowCount = @CustomerRowCount - 1;
	print 'Customer No '+cast(@CustomerId as nvarchar(20))+' End';
	if(@CustomerRowCount !=0)
	print 'Start Count '+ cast(@CustomerRowCount as nvarchar(20));

END

DROP TABLE IF EXISTS #TempCustomer, #tempProjectSegmentRequirementTag