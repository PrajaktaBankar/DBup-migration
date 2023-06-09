CREATE PROC [dbo].[usp_GetLinksCountForSegments]
(
	--@ProjectId INT = 11494,
	----@SectionId INT = 4884848,--4884811,
	--@SectionId INT = 4884848,
	--@CustomerId INT = 8,
	--@CatalogueType NVARCHAR(MAX) = 'FS'
	@ProjectId INT,
	@SectionId INT,
	@CustomerId INT,
	@CatalogueType NVARCHAR(MAX)
)
AS
BEGIN
	DECLARE @PProjectId INT = @ProjectId;
	DECLARE @PSectionId INT = @SectionId;
	DECLARE @PCustomerId INT = @CustomerId;
	DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;
--DECLARE @PageSize INT = 500;
--DECLARE @PageNumber INT = 1;

SELECT
	PSS.SegmentStatusId
   ,0 AS SourceLinks
   ,COUNT(1) AS TargetLinks
   ,PSS.SequenceNumber INTO #TempSourceLinks
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
INNER JOIN ProjectSegmentLink PSL WITH (NOLOCK)
	ON PSL.SourceSegmentStatusCode = PSS.SegmentStatusCode
		AND PSL.ProjectId = @PProjectId
		AND PSL.SegmentLinkSourceTypeId IN (1, 5)
WHERE PSS.SectionId = @PSectionId
AND PSL.CustomerId = @PCustomerId
AND PSS.ProjectId = @PProjectId
AND PSS.IsRefStdParagraph = 0
GROUP BY PSS.SegmentStatusId
		,PSS.SequenceNumber
--ORDER BY PSS.SequenceNumber

SELECT
	PSS.SegmentStatusId
   ,COUNT(1) AS SourceLinks
   ,0 AS TargetLinks
   ,PSS.SequenceNumber INTO #TempTargetLinks
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
INNER JOIN ProjectSegmentLink PSL WITH (NOLOCK)
	ON PSL.TargetSegmentStatusCode = PSS.SegmentStatusCode
		AND PSL.ProjectId = @PProjectId
WHERE PSS.SectionId = @PSectionId
AND PSL.CustomerId = @PCustomerId
AND PSS.ProjectId = @PProjectId
AND PSS.IsRefStdParagraph = 0
GROUP BY PSS.SegmentStatusId
		,PSS.SequenceNumber
--ORDER BY PSS.SequenceNumber

SELECT
	COALESCE(TTL.SegmentStatusId, TSL.SegmentStatusId) AS SegmentStatusId
   ,COALESCE(NULLIF(TTL.SourceLinks, 0), TSL.SourceLinks, 0) AS SourceLinkCount
   ,COALESCE(NULLIF(TTL.TargetLinks, 0), TSL.TargetLinks, 0) AS TargetLinkCount
   ,COALESCE(TTL.SequenceNumber, TSL.SequenceNumber) AS SequenceNumber
FROM #TempTargetLinks TTL
FULL OUTER JOIN #TempSourceLinks TSL
	ON TTL.SegmentStatusId = TSL.SegmentStatusId
ORDER BY SequenceNumber
END

GO
