/*
Customer Support 35374: Gray highlight appearing on active paragraphs in both SLC and in PDF format ( CID = 65294 / AID = 341 )
server 2
*/
USE [SLCProject_SqlSlcOp002]
GO
DECLARE @SectionId INT = 8245519;
UPDATE PS
SET PS.SegmentDescription = dbo.usf_RemoveHTMLFromText(SegmentDescription)
FROM ProjectSegment PS WITH (NOLOCK)
WHERE PS.SectionId = @SectionId
  AND ISNULL(PS.IsDeleted, 0) = 0
  AND PS.SegmentDescription like '%<span style="%' 
  AND PS.SegmentDescription like '%background-color:%';