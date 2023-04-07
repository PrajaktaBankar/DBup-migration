CREATE PROCEDURE [dbo].[usp_DeleteMasterSection_ApplyMasterUpdate] @ProjectId INT, @CustomerId INT AS
BEGIN
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;

DECLARE @MasterDataTypeId INT = ( SELECT TOP 1
		P.MasterDataTypeId
	FROM Project P WITH (NOLOCK)
	WHERE P.ProjectId = @PProjectId
	AND P.CustomerId = @PCustomerId);

DROP TABLE IF EXISTS #tmp_SectionsToBeDelete;
CREATE TABLE #tmp_SectionsToBeDelete (
	SectionId INT
   ,mSectionId INT
   ,SectionCode INT
);

DROP TABLE IF EXISTS #tmp_SegmentStatus;
CREATE TABLE #tmp_SegmentStatus (
	SectionId INT
   ,SegmentStatusId BIGINT
);

--INSERT SECTIONS TO BE DELETE
INSERT INTO #tmp_SectionsToBeDelete (SectionId, mSectionId, SectionCode)
	SELECT
		PS.SectionId
	   ,PS.mSectionId
	   ,PS.SectionCode
	FROM ProjectSection PS WITH (NOLOCK)
	INNER JOIN SLCMaster..Section MS WITH (NOLOCK)
		ON PS.mSectionId = MS.SectionId
	WHERE PS.ProjectId = @PProjectId
	AND PS.CustomerId = @PCustomerId
	AND PS.IsDeleted = 0
	AND MS.IsDeleted = 1;

--INSERT BASE LEVEL SEGMENT STATUS WHICH ARE OPENED IN PROJECT
INSERT INTO #tmp_SegmentStatus (SectionId, SegmentStatusId)
	SELECT
		PSST.SectionId
	   ,PSST.SegmentStatusId
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	WHERE PSST.ProjectId = @PProjectId
	AND PSST.CustomerId = @PCustomerId
	AND PSST.SequenceNumber = 0
	AND PSST.ParentSegmentStatusId = 0
	AND PSST.IndentLevel = 0;

--DO NOT DELETE THOSE SECTIONS WHICH ARE ALREADY OPENED IN PROJECT
DELETE SDL
	FROM #tmp_SegmentStatus PSST WITH (NOLOCK)
	INNER JOIN #tmp_SectionsToBeDelete SDL
		ON SDL.SectionId = PSST.SectionId;

--DO NOT DELETE THOSE SECTIONS WHICH ARE HAVING TARGETTED LINKS
DELETE SDL
	FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
	INNER JOIN #tmp_SectionsToBeDelete SDL
		ON PSLNK.TargetSectionCode = SDL.SectionCode
WHERE PSLNK.ProjectId = @PProjectId
	AND PSLNK.CustomerId = @PCustomerId;

--DELETE SECTIONS NOW
UPDATE PS
SET PS.IsDeleted = 1
FROM ProjectSection PS WITH (NOLOCK)
INNER JOIN #tmp_SectionsToBeDelete SDL WITH (NOLOCK)
	ON PS.SectionId = SDL.SectionId
WHERE PS.ProjectId = @PProjectId
AND PS.CustomerId = @PCustomerId;
END
GO


