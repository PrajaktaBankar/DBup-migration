use SLCPRoject;

--Execute script on Server 003
--Customer Support 33895: SLC - When Printing, Global Terms Become Red

GO
DECLARE @SProjectId INT =4027
DECLARE @TProjectId INT =5787

DROP TABLE IF EXISTS #hyperlinkids
DROP TABLE IF EXISTS #Totalhyperlinkids
SELECT DISTINCT
phl.HyperLinkId
,pss.SectionId
,pss.SegmentStatusId
,pss.SegmentId
,pss.ProjectId
,pss.CustomerId INTO #hyperlinkids
FROM ProjectSegment pss WITH (NOLOCK)
INNER JOIN ProjectHyperLink phl WITH (NOLOCK)
ON pss.SegmentDescription LIKE '%{HL#' + CAST(phl.HyperLinkId AS NVARCHAR(50)) + '}%'
WHERE phl.ProjectId = @SProjectId
AND pss.ProjectId = @TProjectId
AND pss.SegmentDescription LIKE '%{HL#%'
AND ISNULL(pss.IsDeleted, 0) = 0

INSERT INTO ProjectHyperLink (SectionId, SegmentId, SegmentStatusId, ProjectId, CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate,
CreatedBy, A_HyperLinkId)
SELECT
thl.SectionId
,thl.SegmentId
,thl.SegmentStatusId
,thl.ProjectId
,thl.CustomerId
,phl1.LinkTarget
,phl1.LinkText
,phl1.LuHyperLinkSourceTypeId
,GETUTCDATE() AS CreateDate
,phl1.CreatedBy
,phl1.HyperLinkId
FROM #hyperlinkids thl
INNER JOIN ProjectHyperLink phl1 WITH (NOLOCK)
ON phl1.HyperLinkId = thl.HyperLinkId
AND phl1.ProjectId = @SProjectId
LEFT OUTER JOIN ProjectHyperLink phl WITH (NOLOCK)
ON phl.ProjectId = thl.ProjectId
AND phl.CustomerId = thl.CustomerId
AND phl.SectionId = thl.SectionId
AND phl.SegmentId = thl.SegmentId
AND phl.SegmentStatusId = thl.SegmentStatusId
AND phl.ProjectId = @TProjectId
WHERE phl.SegmentId IS NULL

---UPDATE NEW HyperLinkId in SegmentDescription

DECLARE @SegmentStatusIdCount int=0;
SELECT  count(SegmentStatusId)as SegmentStatusIdCount into #Totalhyperlinkids FROM #hyperlinkids  GROUP BY SegmentStatusId 
SELECT @SegmentStatusIdCount= max(SegmentStatusIdCount) FROM #Totalhyperlinkids

WHILE(@SegmentStatusIdCount>0)
begin
UPDATE PS
SET PS.SegmentDescription = REPLACE(PS.SegmentDescription, '{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '}', '{HL#' + CAST(PHL.HyperLinkId AS NVARCHAR(20)) + '}')
FROM ProjectHyperLink PHL WITH (NOLOCK)
INNER JOIN ProjectSegment PS WITH (NOLOCK)
ON PS.SegmentStatusId = PHL.SegmentStatusId
AND PS.SegmentId = PHL.SegmentId
AND PS.ProjectId = PHL.ProjectId
AND PS.SectionId = PHL.SectionId
AND PS.CustomerId = PHL.CustomerId
AND PS.SegmentDescription LIKE '%{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '%'
INNER JOIN #hyperlinkids hlis
ON hlis.HyperLinkId = PHL.A_HyperLinkId and hlis.SegmentId = PHL.SegmentId
WHERE PHL.ProjectId = @TProjectId

SET @SegmentStatusIdCount =@SegmentStatusIdCount-1;
end;