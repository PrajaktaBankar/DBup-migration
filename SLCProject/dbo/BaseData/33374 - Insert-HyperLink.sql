use SLCProject
go
--Customer Support 33374: CH# Issues - Dewayne Dean - LDS Church - 40958 
-- Execute on server 03
DECLARE @TProjectId INT =6107
DECLARE @SProjectId INT =4027

DROP TABLE IF EXISTS #HyperLinkId
SELECT 
	SUBSTRING(pssv.SegmentDescription, CHARINDEX('{HL#', pssv.SegmentDescription) + 4, 7) AS HyperLinkId
   ,pssv.SegmentStatusId
   ,pssv.SegmentId
   ,pssv.SectionId
   ,pssv.ProjectId
   ,pssv.CustomerId
   ,pssv.SegmentDescription 
   INTO #HyperLinkId
FROM ProjectSegmentStatusView pssv   WITH (NOLOCK) INNER JOIN ProjectHyperLink phl   WITH (NOLOCK)
on phl.HyperLinkId=SUBSTRING(SegmentDescription, CHARINDEX('{HL#', SegmentDescription) + 4, 7) 
WHERE pssv.ProjectId = @TProjectId
AND pssv.SegmentDescription LIKE '%{HL%'
SELECT
	*
FROM #HyperLinkId WITH (NOLOCK)
ORDER BY HyperLinkId--24


INSERT INTO ProjectHyperLink (SectionId, SegmentId, SegmentStatusId, ProjectId, CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate,
CreatedBy, SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_LinkNo, A_HyperLinkId)
	SELECT
		HLID.SectionId
	   ,HLID.SegmentId
	   ,HLID.SegmentStatusId
	   ,HLID.ProjectId
	   ,HLID.CustomerId
	   ,PHL.LinkTarget
	   ,PHL.LinkText
	   ,PHL.LuHyperLinkSourceTypeId
	   ,GETUTCDATE() AS CreateDate
	   ,PHL.CreatedBy
	   ,PHL.SLE_DocID
	   ,PHL.SLE_SegmentID
	   ,PHL.SLE_StatusID
	   ,PHL.SLE_LinkNo
	   ,PHL.A_HyperLinkId
	FROM ProjectHyperLink PHL WITH (NOLOCK)
	INNER JOIN #HyperLinkId HLID WITH (NOLOCK)
		ON PHL.HyperLinkId = HLID.HyperLinkId
	WHERE PHL.ProjectId = @SProjectId
	--AND HLID.HyperLinkId IS NOT NULL
	ORDER BY PHL.HyperLinkId

---UPDATE NEW HyperLinkId in SegmentDescription
UPDATE PS
SET PS.SegmentDescription = REPLACE(PS.SegmentDescription, '{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '}', '{HL#' + CAST(PHL.HyperLinkId AS NVARCHAR(20)) + '}')
FROM ProjectHyperLink PHL WITH (NOLOCK)
INNER JOIN ProjectSegment PS WITH (NOLOCK)
	ON PS.SegmentStatusId = PHL.SegmentStatusId
	AND PS.SegmentId = PHL.SegmentId
	AND PS.ProjectId = PHL.ProjectId
	AND PS.SectionId = PHL.SectionId
	AND PS.CustomerId = PHL.CustomerId
WHERE PHL.ProjectId = @TProjectId 