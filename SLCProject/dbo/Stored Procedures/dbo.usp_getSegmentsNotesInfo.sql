CREATE PROCEDURE [dbo].[usp_getSegmentsNotesInfo]  
(
 @SectionId INT
)
AS  
BEGIN
DECLARE @PSectionId INT = @SectionId;
DECLARE @IsMasterSection BIT;

SELECT
	@IsMasterSection =
	CASE
		WHEN mSectionId IS NULL THEN 0
		ELSE 1
	END
FROM ProjectSection WITH (NOLOCK)
WHERE SectionId = @PSectionId;

SELECT DISTINCT
	PSS.SegmentStatusId
   ,CASE
		WHEN (MN.SegmentStatusId IS NOT NULL AND
			@IsMasterSection = 1) THEN 1
		ELSE 0
	END AS HasMasterNote
   ,CASE
		WHEN (PN.SegmentStatusId IS NOT NULL) THEN 1
		ELSE 0
	END AS HasProjectNote
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
LEFT JOIN SLCMaster..Note MN WITH (NOLOCK)
	ON MN.SegmentStatusId = PSS.mSegmentStatusId
LEFT JOIN ProjectNote PN WITH (NOLOCK)
	ON PN.SegmentStatusId = PSS.SegmentStatusId
		AND PN.ProjectId = PSS.ProjectId
WHERE PSS.SectionId = @PSectionId
AND ISNULL(PSS.IsDeleted, 0) = 0;
END
 