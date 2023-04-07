/*
 Server name : SLCProject_SqlSlcOp005 ( Server 05)
 CSI 70766: Links are duplicating - 45618/Admin 1947
*/

USE SLCProject_SqlSlcOp005
GO

DROP TABLE IF EXISTS #TempDuplicateLinks

SELECT SegmentLinkId,
SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,
TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget,
LinkStatusTypeId, SegmentLinkSourceTypeId,
ROW_NUMBER() OVER (
            PARTITION BY SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,
				 		 TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget,
						 LinkStatusTypeId, SegmentLinkSourceTypeId
            ORDER BY SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,
				 		 TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget,
						 LinkStatusTypeId, SegmentLinkSourceTypeId
		) RowNum
INTO #TempDuplicateLinks
FROM ProjectSegmentLink WITH(NOLOCK)
WHERE CustomerId = 1947 AND ProjectId = 8615 AND SourceSectionCode = 10042239 AND ISNULL(IsDeleted, 0) = 0

--SELECT * FROM #TempDuplicateLinks WHERE RowNum > 1 

UPDATE PSL SET PSL.IsDeleted = 1
FROM ProjectSegmentLink PSL WITH(NOLOCK) 
INNER JOIN #TempDuplicateLinks T WITH(NOLOCK) ON T.SegmentLinkId = PSL.SegmentLinkId
WHERE T.RowNum > 1
AND PSL.CustomerId = 1947 AND PSL.ProjectId = 8615 AND PSL.SourceSectionCode = 10042239 AND ISNULL(IsDeleted, 0) = 0;
