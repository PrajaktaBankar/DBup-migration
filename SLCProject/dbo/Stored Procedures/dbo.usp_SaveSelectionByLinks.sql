CREATE PROCEDURE [dbo].[usp_SaveSelectionByLinks] 
(@ProjectId INT, @CustomerId INT, @UserId INT,
	@SegmentStatusListJson NVARCHAR(MAX), @SelectedChoiceOptionListJson NVARCHAR(MAX), @SegmentLinkListJson NVARCHAR(MAX))    
AS    
BEGIN
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PUserId INT = @UserId;
DECLARE @PSegmentStatusListJson NVARCHAR(MAX) = @SegmentStatusListJson;
DECLARE @PSelectedChoiceOptionListJson NVARCHAR(MAX) = @SelectedChoiceOptionListJson;
DECLARE @PSegmentLinkListJson NVARCHAR(MAX) = @SegmentLinkListJson;
--SET NO COUNT ON    
SET NOCOUNT ON;

--DECLARE TABLES
DROP TABLE IF EXISTS #SegmentStatusTbl
CREATE TABLE #SegmentStatusTbl (
	SegmentStatusId BIGINT NOT NULL
   ,SegmentStatusTypeId INT NOT NULL
   ,IsParentSegmentStatusActive BIT NOT NULL
);
CREATE NONCLUSTERED INDEX [TMPIX_#SegmentStatusTbl_SegmentStatusId]
ON #SegmentStatusTbl ([SegmentStatusId])

DROP TABLE IF EXISTS #SelectedChoiceOptionTbl
CREATE TABLE #SelectedChoiceOptionTbl (
	SelectedChoiceOptionId BIGINT NOT NULL
   ,IsSelected BIT NOT NULL
);
CREATE NONCLUSTERED INDEX [TMPIX_#SelectedChoiceOptionTbl_SelectedChoiceOptionId]
ON #SelectedChoiceOptionTbl ([SelectedChoiceOptionId])

DROP TABLE IF EXISTS #SegmentLinkTbl
CREATE TABLE #SegmentLinkTbl (
	SegmentLinkId BIGINT
);
CREATE NONCLUSTERED INDEX [TMPIX_#SegmentLinkTbl_SegmentLinkId]
ON #SegmentLinkTbl ([SegmentLinkId])

--CONVERT STRING JSONS INTO TABLES
IF @PSegmentStatusListJson != ''
BEGIN
INSERT INTO #SegmentStatusTbl
	SELECT
		*
	FROM OPENJSON(@PSegmentStatusListJson)
	WITH (
	SegmentStatusId BIGINT '$.SegmentStatusId',
	SegmentStatusTypeId INT '$.SegmentStatusTypeId',
	IsParentSegmentStatusActive BIT '$.IsParentSegmentStatusActive'
	);
END

IF @PSelectedChoiceOptionListJson != ''
BEGIN
INSERT INTO #SelectedChoiceOptionTbl
	SELECT
		*
	FROM OPENJSON(@PSelectedChoiceOptionListJson)
	WITH (
	SelectedChoiceOptionId BIGINT '$.SelectedChoiceOptionId',
	IsSelected BIT '$.IsSelected'
	);
END

IF @PSegmentLinkListJson != ''
BEGIN
INSERT INTO #SegmentLinkTbl
	SELECT
		*
	FROM OPENJSON(@PSegmentLinkListJson)
	WITH (
	SegmentLinkId BIGINT '$.SegmentLinkId'
	);
END

--UPDATE DATA IN TABLES
UPDATE PSST
SET PSST.SegmentStatusTypeId = SSTTBL.SegmentStatusTypeId
   ,PSST.IsParentSegmentStatusActive = SSTTBL.IsParentSegmentStatusActive
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN #SegmentStatusTbl SSTTBL
	ON PSST.SegmentStatusId = SSTTBL.SegmentStatusId
WHERE PSST.ProjectId = @PProjectId
AND PSST.CustomerId = @PCustomerId

UPDATE SCHOP
SET SCHOP.IsSelected = SCHOPTBL.IsSelected
FROM SelectedChoiceOption SCHOP WITH (NOLOCK)
INNER JOIN #SelectedChoiceOptionTbl SCHOPTBL
	ON SCHOP.SelectedChoiceOptionId = SCHOPTBL.SelectedChoiceOptionId
WHERE SCHOP.ProjectId = @PProjectId
AND SCHOP.CustomerId = @PCustomerId

UPDATE PSLNK
SET PSLNK.IsDeleted = 1
FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
INNER JOIN #SegmentLinkTbl SLT
	ON PSLNK.SegmentLinkId = SLT.SegmentLinkId
WHERE PSLNK.ProjectId = @PProjectId
AND PSLNK.CustomerId = @PCustomerId

UPDATE UF
SET UF.UserId = @PUserId
   ,UF.LastAccessed = GETUTCDATE()
FROM UserFolder UF WITH (NOLOCK)
WHERE UF.ProjectId = @PProjectId
AND UF.CustomerId = @PCustomerId

END;
GO


