use SLCProject
go

DECLARE @CustomerId int =375 ;

drop TABLE if EXISTS #tempProjectList ;

DECLARE @ProjectId nvarchar(50)=4027
DECLARE @TargetProjectId nvarchar(50)=4074

	print '@ProjectId' print @ProjectId print '@TargetProjectId' print @TargetProjectId
	--insert hyper link code start
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
	WHERE pssv.ProjectId = @TargetProjectId
	AND pssv.SegmentDescription LIKE '%{HL%'
	
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
			,PHL.HyperLinkId
		FROM ProjectHyperLink PHL WITH (NOLOCK)
		INNER JOIN #HyperLinkId HLID WITH (NOLOCK)
			ON PHL.HyperLinkId = HLID.HyperLinkId
			LEFT OUTER JOIN ProjectHyperLink rs WITH(NOLOCK)
			on rs.HyperLinkId=HLID.HyperLinkId
		WHERE PHL.ProjectId = @ProjectId --and rs.HyperLinkId is NULL
		ORDER BY PHL.HyperLinkId

	--UPDATE NEW HyperLinkId in SegmentDescription
	UPDATE PS
	set PS.SegmentDescription = REPLACE(PS.SegmentDescription, SUBSTRING(ps.SegmentDescription, CHARINDEX('{HL#', ps.SegmentDescription) + 4, 7), PHL.HyperLinkId ) 
	FROM ProjectHyperLink PHL WITH (NOLOCK)
	INNER JOIN ProjectSegment PS WITH (NOLOCK)
		ON PS.SegmentStatusId = PHL.SegmentStatusId
		AND PS.SegmentId = PHL.SegmentId
		AND PS.ProjectId = PHL.ProjectId
		AND PS.SectionId = PHL.SectionId
		AND PS.CustomerId = PHL.CustomerId
	WHERE PHL.ProjectId = @TargetProjectId and ps.SegmentDescription like '%{HL#%'
	--insert hyper link code end



