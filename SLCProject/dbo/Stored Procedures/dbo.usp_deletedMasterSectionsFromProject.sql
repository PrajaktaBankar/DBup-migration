CREATE PROCEDURE [dbo].[usp_deletedMasterSectionsFromProject] -- usp_deletedMasterSectionsFromProject  11792,8
@ProjectId INT,@customerId INT NULL --, @userId INT NULL=0
AS
BEGIN
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PcustomerId INT = @customerId;
--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT OFF;

DROP TABLE IF EXISTS #ProjectsTbl;
DECLARE @LoopCount INT = 1 --@ProjectId INT = NULL

DECLARE @AllToBeDeleteSectionsTbl TABLE (
	ProjectID INT
   ,SectionCounts INT
)

DECLARE @ToBeDeleteSectionsTbl TABLE (
	SectionId INT
   ,mSectionId INT
   ,SectionCode INT
);

DECLARE @SegmentsWithSectionIdChoiceTbl TABLE (
	SegmentStatusId BIGINT
   ,SectionId INT NULL
   ,OptionJson NVARCHAR(MAX)
)

SELECT
	ROW_NUMBER() OVER (ORDER BY ProjectId DESC) AS RowId
   ,ProjectId INTO #ProjectsTbl
FROM Project AS p WITH (NOLOCK)
WHERE p.IsDeleted = 0
AND p.MasterDataTypeId = 1
AND COALESCE(p.IsPermanentDeleted, 0) = 0
AND p.ProjectId = @PProjectId
ORDER BY p.ProjectId DESC
--AND ProjectId IN (11);

DECLARE @ProjectsTblRowCount INT=(SELECT
		COUNT(1)
	FROM #ProjectsTbl)

WHILE @LoopCount <= @ProjectsTblRowCount
BEGIN
--BEGIN TRANSACTION;
SET @PProjectId = (SELECT
		ProjectId
	FROM #ProjectsTbl
	WHERE RowId = @LoopCount);

--INSERT TO BE DELETE SECTIONS
DELETE FROM @ToBeDeleteSectionsTbl;
INSERT INTO @ToBeDeleteSectionsTbl (SectionId, mSectionId, SectionCode)
	SELECT
		PS.SectionId
	   ,PS.mSectionId
	   ,PS.SectionCode
	FROM ProjectSection PS WITH (NOLOCK)
	INNER JOIN SLCMaster..Section MS WITH (NOLOCK)
		ON PS.mSectionId = MS.SectionId
	WHERE PS.ProjectID = @PProjectId
	AND PS.IsDeleted = 0
	AND MS.IsDeleted = 1
	AND PS.CustomerId = @PcustomerId;

IF ((SELECT
			COUNT(1)
		FROM @ToBeDeleteSectionsTbl)
	> 0)
BEGIN

--1. REMOVE OPENED SECTIONS FROM TOBE DELETE
DELETE X1
	FROM @ToBeDeleteSectionsTbl X1
	INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)
		ON X1.SectionId = PSST.SectionId
		AND PSST.SequenceNumber = 0
		AND PSST.IndentLevel = 0

--2. REMOVE CROSS LINKS SECTION FROM TOBE DELETE
DELETE X1
	FROM @ToBeDeleteSectionsTbl X1
	INNER JOIN ProjectSegmentLink PSLNK WITH (NOLOCK)
		ON X1.SectionCode = PSLNK.TargetSectionCode
		AND PSLNK.ProjectId = @PProjectId
		AND (PSLNK.LinkStatusTypeId = 2
		OR PSLNK.LinkStatusTypeId = 3)
--3. REMOVE SECTION ID REFERENCES SECTIONS

DELETE FROM @SegmentsWithSectionIdChoiceTbl;
INSERT INTO @SegmentsWithSectionIdChoiceTbl (SegmentStatusId, SectionId, OptionJson)
	SELECT DISTINCT
		PSST.SegmentStatusId
	   ,PSST.SectionId
	   ,CHOP.OptionJson
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN SLCMaster..SegmentChoice CH WITH (NOLOCK)
		ON PSST.mSegmentId = CH.SegmentId
	INNER JOIN SLCMaster..ChoiceOption CHOP WITH (NOLOCK)
		ON CH.SegmentChoiceId = CHOP.SegmentChoiceId
	WHERE PSST.ProjectID = @PProjectId
	AND PSST.SegmentOrigin = 'M'
	AND CHOP.OptionJson LIKE '%"OptionTypeName":"SectionID"%'
	--AND CONTAINS(CHOP.OptionJson ,'OptionTypeName:SectionID')
	AND PSST.CustomerId = @PcustomerId
	UNION ALL
	SELECT DISTINCT
		PSST.SegmentStatusId
	   ,PSST.SectionId
	   ,CHOP.OptionJson
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN ProjectSegmentChoice CH WITH (NOLOCK)
		ON PSST.SegmentId = CH.SegmentId
	INNER JOIN ProjectChoiceOption CHOP WITH (NOLOCK)
		ON CH.SegmentChoiceId = CHOP.SegmentChoiceId
	WHERE PSST.ProjectId = @PProjectId
	AND PSST.SegmentOrigin = 'U'
	AND CHOP.OptionJson LIKE '%"OptionTypeName":"SectionID"%'
	AND CH.IsDeleted = 0
	AND PSST.CustomerId = @PcustomerId



DELETE X2
	FROM @SegmentsWithSectionIdChoiceTbl AS X1
	CROSS APPLY @ToBeDeleteSectionsTbl AS X2
WHERE X1.OptionJson LIKE CONCAT('%"Id":', X2.SectionCode, '%')


--4.SELECT FINAL SECTIONS TO BE DELETE

INSERT INTO @AllToBeDeleteSectionsTbl (ProjectID, SectionCounts)
	SELECT
		@PProjectId AS ProjectId
	   ,COUNT(*) AS DeletedSections
	FROM @ToBeDeleteSectionsTbl sd
	INNER JOIN ProjectSection AS ps WITH (NOLOCK)
		ON sd.SectionId = ps.SectionId;

UPDATE ps
SET ps.IsDeleted = 1
FROM @ToBeDeleteSectionsTbl sd
INNER JOIN ProjectSection AS ps WITH (NOLOCK)
	ON sd.SectionId = ps.SectionId;

--COMMIT TRANSACTION;
--SELECT * FROM @ToBeDeleteSectionsTbl;
--SELECT * FROM @AllToBeDeleteSectionsTbl;
END
SET @LoopCount = @LoopCount + 1;
	END
	
END
GO


