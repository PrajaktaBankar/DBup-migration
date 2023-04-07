CREATE PROCEDURE [dbo].[usp_GetSegmentsNotesMapping] -- [Obsolute]
(
 @ProjectId INT, 
 @SectionId INT, 
 @MSectionId INT
)  
AS    
BEGIN  
	DECLARE @PProjectId INT = @ProjectId;  
	DECLARE @PSectionId INT = @SectionId;  
	DECLARE @PMSectionId INT = @MSectionId;  
	DECLARE @IsMasterSection BIT;  
  
	--SELECT @IsMasterSection = CASE WHEN mSectionId IS NULL THEN 0 ELSE 1 END FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSectionId;
	SELECT @IsMasterSection = CASE WHEN @PMSectionId IS NULL THEN 0 ELSE 1 END;

	SELECT PSS.ProjectId, PSS.SegmentStatusId, PSS.mSegmentStatusId 
	INTO #ProjectSegmentStatus
	FROM ProjectSegmentStatus PSS WITH (NOLOCK)
	WHERE PSS.ProjectId = @PProjectId AND PSS.SectionId = @PSectionId  
	AND ISNULL(PSS.IsDeleted, 0) = 0;

	SELECT MN.SegmentStatusId
	INTO #MasterNotes
	FROM SLCMaster..Note MN WITH (NOLOCK)
	WHERE MN.SectionId = @PMSectionId

	SELECT PN.SegmentStatusId
	INTO #ProjectNotes
	FROM ProjectNote PN WITH (NOLOCK)
	WHERE PN.ProjectId = @PProjectId AND PN.SectionId = @PSectionId

 
	SELECT DISTINCT
	 PSS.SegmentStatusId  
	,CASE WHEN (MN.SegmentStatusId IS NOT NULL AND @IsMasterSection = 1) THEN 1 ELSE 0 END AS HasMasterNote  
	,CASE WHEN (PN.SegmentStatusId IS NOT NULL) THEN 1 ELSE 0 END AS HasProjectNote
	FROM #ProjectSegmentStatus PSS WITH (NOLOCK)  
	LEFT JOIN #MasterNotes MN WITH (NOLOCK)  
	 ON MN.SegmentStatusId = PSS.mSegmentStatusId  
	LEFT JOIN #ProjectNotes PN WITH (NOLOCK)
	 ON PN.SegmentStatusId = PSS.SegmentStatusId

END