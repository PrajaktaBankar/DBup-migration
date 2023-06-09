CREATE PROCEDURE [dbo].[usp_updateSectionNameAndID] 
@ProjectID int 
AS
BEGIN
DECLARE @PProjectID int = @ProjectID;
SET NOCOUNT ON;
--TODO: Get Updated(Section Name OR SectionID) Master Sections 
--BEGIN TRANSACTION

SELECT
	ps.SectionId AS pSectionId
   ,ps.mSectionId
   ,ps.SourceTag AS pSourceTag
   ,ps.Description AS pDescription
   ,ms.SourceTag
   ,ms.Description
   ,ms.SectionId
   ,COUNT(pss.SectionId) AS cnt INTO #AllSections
FROM ProjectSection AS ps WITH (NOLOCK)
INNER JOIN SLCMaster..Section AS ms WITH (NOLOCK)
	ON ps.mSectionId = ms.SectionCode
LEFT OUTER JOIN ProjectSegmentStatus AS pss WITH (NOLOCK)
	ON ps.SectionId = pss.SectionId
		AND pss.SegmentSource = 'M'
		AND pss.SegmentOrigin = 'U'
		AND pss.ParentSegmentStatusId = 0
WHERE ps.ProjectId = @PProjectID
AND ps.IsDeleted = 0
AND ms.IsDeleted = 0
AND (ps.SourceTag != ms.SourceTag
OR ps.Description != ms.Description)
AND ps.IsLastLevel = 1
AND ps.mSectionId IS NOT NULL
GROUP BY ps.SectionId
		,ps.mSectionId
		,ps.SourceTag
		,ps.Description
		,ms.SourceTag
		,ms.Description
		,ms.SectionId;

--SELECT * FROM #AllSections as s WHERE s.cnt = 0 ORDER BY SourceTag,Description;
UPDATE ps
SET ps.SourceTag = s.SourceTag
   ,ps.Description = s.Description
FROM #AllSections AS s
INNER JOIN ProjectSection AS ps  WITH (NOLOCK)
	ON ps.SectionId = s.pSectionId
WHERE s.cnt = 0;

--COMMIT TRANSACTION;
END

GO
