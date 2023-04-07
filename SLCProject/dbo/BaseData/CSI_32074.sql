--Customer Support 32074: Hyperlink (HL#) issue in Div 22 and 23
--Execute this on Server 2

--1066 rows affected 
UPDATE ps 
SET ps.SegmentDescription = REPLACE(ps.SegmentDescription, '{HL#' + CAST(phl.HyperLinkId AS NVARCHAR(50)) + '}', phl.LinkText)	  
FROM ProjectSegment ps WITH (NOLOCK)
INNER JOIN ProjectHyperLink phl WITH (NOLOCK)
	ON phl.SegmentId = ps.SegmentId
	AND phl.SectionId = ps.SectionId
	AND phl.SegmentStatusId = ps.SegmentStatusId
	AND phl.ProjectId = ps.ProjectId
	AND phl.CustomerId = ps.CustomerId
WHERE ps.ProjectId = 5313
AND ps.SegmentDescription LIKE '%{HL#%'

------------------------------------------------------------------------------------------------------------------------------------------------
--run this query twice
--655 rows affected 

DROP TABLE IF EXISTS #HyperLinksCodesInSegmnetDesc, #TempProjectSegment1, #TempProjectSegment

CREATE Table #HyperLinksCodesInSegmnetDesc (ProjectId int, SectionId int, CustomerId int , HyperLinkId int ,
SegmentStatusId int , SegmentId int)

SELECT
	ps.SectionId
   ,ps.SegmentId
   ,ps.SegmentStatusId
   ,ps.ProjectId
   ,ps.CustomerId
   ,ps.SegmentDescription
   ,ROW_NUMBER() OVER (ORDER BY ps.CustomerId) AS RowNo INTO #TempProjectSegment
FROM ProjectSegment ps WITH (NOLOCK)
WHERE ps.ProjectId = 4791
AND ps.SegmentDescription LIKE '%{HL#%'
 
DECLARE @LoopCount INT = ( SELECT
		COUNT(SegmentId)
	FROM #TempProjectSegment);

WHILE @LoopCount > 0
BEGIN

DECLARE @CustomerId INT = 0;
DECLARE @SegmentDescription NVARCHAR(MAX) = '';
DECLARE @SectionId INT = 0;
DECLARE @SegmentStatusId INT = 0;
DECLARE @SegmentId INT = 0;
DECLARE @ModifiedBy INT = 0;
DECLARE @ProjectId INT = 0;
SELECT
	@SegmentDescription = TPSSV.SegmentDescription
   ,@SectionId = TPSSV.SectionId
   ,@CustomerId = TPSSV.CustomerId
   ,@SegmentStatusId = TPSSV.SegmentStatusId
   ,@SegmentId = TPSSV.SegmentId
   ,@ProjectId = TPSSV.ProjectId
FROM #TempProjectSegment TPSSV WITH (NOLOCK)
WHERE RowNo = @LoopCount;

INSERT INTO #HyperLinksCodesInSegmnetDesc (ProjectId, SectionId, CustomerId, HyperLinkId,
SegmentStatusId, SegmentId)
	SELECT
		@ProjectId AS ProjectId
	   ,@SectionId AS SectionId
	   ,@CustomerId AS CustomerId
	   ,Ids
	   ,@SegmentStatusId AS SegmentStatusId
	   ,@SegmentId AS SegmentId
	FROM [dbo].[fn_GetIdSegmentDescription](@SegmentDescription, '{HL#') 

SET @LoopCount = @LoopCount - 1;
END;

UPDATE ps 
SET ps.SegmentDescription = REPLACE(ps.SegmentDescription, '{HL#' + CAST(phl.HyperLinkId AS NVARCHAR(50)) + '}', phl.LinkText)
FROM #HyperLinksCodesInSegmnetDesc tempsd
INNER JOIN ProjectSegment ps with (NOLOCK)
	ON ps.ProjectId = tempsd.ProjectId
	AND ps.CustomerId = tempsd.CustomerId
	AND PS.SegmentStatusId = tempsd.SegmentStatusId
	AND PS.SegmentId = tempsd.SegmentId
INNER JOIN ProjectHyperLink phl with (NOLOCK)
	ON tempsd.HyperLinkId = phl.HyperLinkId 

------------------------------------------------------------------------------------------------------------------------------------------------------

DELETE FROM ProjectHyperLink 
WHERE ProjectId = 5313
-------------------------------------------------------------------------------------------------------------------------------------------------------
DELETE FROM ProjectHyperLink
WHERE ProjectId = 4791

-----------------------------------------------------------------------------------------------------------------------------------------------------