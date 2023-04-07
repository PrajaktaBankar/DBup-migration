CREATE PROCEDURE [dbo].[usp_ApplyNewParagraphsUpdates](
@SegmentStatusJson NVARCHAR(MAX)
)
AS
BEGIN

DECLARE @PSegmentStatusJson NVARCHAR(MAX)=@SegmentStatusJson;
--VARIABLES
DECLARE @ProjectId INT = 0;
DECLARE @CustomerId INT = 0;
DECLARE @SectionId INT = 0;
DECLARE @UserId INT = 0;

DECLARE @Loop_IndentLevel INT = 0;

--Temp table declartion #SegmentStatusTable for storing inputed segment
DROP TABLE IF EXISTS #SegmentStatusTable
CREATE TABLE #SegmentStatusTable (
ProjectId INT NULL
,CustomerId INT NULL
,SectionId INT NULL
,UserId INT NULL
,MSegmentStatusId INT NULL
,UISegmentStatusId BIGINT NULL
,SegmentStatusId BIGINT NULL
,ParentSegmentStatusId BIGINT NULL
,Action NVARCHAR(MAX) NULL
,IndentLevel INT NULL
,SequenceNumber DECIMAL(10, 4) NULL
,NewSegmentStatusId BIGINT NULL
,NewParentSegmentStatusId BIGINT NULL
,UserFullName NVARCHAR(MAX)
);

--INSERT DATA INTO TEMP TABLE FROM JSON STRING
INSERT INTO #SegmentStatusTable (ProjectId, CustomerId, SectionId, UserId,
MSegmentStatusId, UISegmentStatusId, SegmentStatusId, ParentSegmentStatusId, Action, IndentLevel, SequenceNumber, UserFullName)
SELECT
*
FROM OPENJSON(@PSegmentStatusJson)
WITH (
ProjectId INT '$.ProjectId',
CustomerId INT '$.CustomerId',
SectionId INT '$.SectionId',
UserId INT '$.UserId',
MSegmentStatusId INT '$.MSegmentStatusId',
UISegmentStatusId BIGINT '$.SegmentStatusId',
SegmentStatusId BIGINT '$.OriginalSegmentStatusId',
ParentSegmentStatusId BIGINT '$.OriginalParentSegmentStatusId',
Action NVARCHAR(MAX) '$.Action',
IndentLevel INT '$.IndentLevel',
SequenceNumber DECIMAL(10, 4) '$.OriginalSequenceNumber',
UserFullName NVARCHAR(MAX) '$.UserFullName'
);

--Fetch common properties into variables
SELECT TOP 1
@ProjectId = ProjectId
,@CustomerId = CustomerId
,@SectionId = SectionId
,@UserId = UserId
FROM #SegmentStatusTable WITH (NOLOCK)

--INSERT INTO ProjectSegmentStatus
--NOTE: SegmentId column of ProjectSegmentStatus temporarily used to store UI SegmentStatusId
--NOTE: ParentSegmentStatusId used to pass whatever came from UI either tempid/ originalid
INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId,
mSegmentId, SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber,
SpecTypeTagId, SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId,
CustomerId, SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph,
FormattingJson, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsPageBreak)
SELECT
@SectionId AS SectionId
,SST_Temp.ParentSegmentStatusId AS ParentSegmentStatusId
,MST.SegmentStatusId AS mSegmentStatusId
,MST.SegmentId AS mSegmentId
,SST_Temp.SegmentStatusId AS SegmentId
,'M' AS SegmentSource
,'M' AS SegmentOrigin
,SST_Temp.IndentLevel AS IndentLevel
,SST_Temp.SequenceNumber AS SequenceNumber
,MST.SpecTypeTagId AS SpecTypeTagId
,MST.SegmentStatusTypeId AS SegmentStatusTypeId
,MST.IsParentSegmentStatusActive AS IsParentSegmentStatusActive
,@ProjectId AS ProjectId
,@CustomerId AS CustomerId
,MST.SegmentStatusCode AS SegmentStatusCode
,MST.IsShowAutoNumber AS IsShowAutoNumber
,MST.IsRefStdParagraph AS IsRefStdParagraph
,MST.FormattingJson AS FormattingJson
,GETUTCDATE() AS CreateDate
,@UserId AS CreatedBy
,GETUTCDATE() AS ModifiedDate
,@UserId AS ModifiedBy
,CAST(0 AS BIT) AS IsPageBreak
FROM #SegmentStatusTable SST_Temp WITH (NOLOCK)
INNER JOIN SLCMaster..SegmentStatus MST WITH (NOLOCK)
ON SST_Temp.MSegmentStatusId = MST.SegmentStatusId
WHERE SST_Temp.Action = 'INSERT'

--Update new segment status id in temp table
UPDATE SST_Temp
SET SST_Temp.NewSegmentStatusId = PSST.SegmentStatusId
FROM #SegmentStatusTable SST_Temp WITH (NOLOCK)
INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)
ON SST_Temp.SegmentStatusId = PSST.SegmentId
WHERE PSST.ProjectId = @ProjectId
AND PSST.CustomerId = @CustomerId
AND PSST.SectionId = @SectionId
AND SST_Temp.Action = 'INSERT'

--Update parent segment status id in temp table
UPDATE SST_Temp
SET SST_Temp.NewParentSegmentStatusId = P_SST_Temp.NewSegmentStatusId
FROM #SegmentStatusTable SST_Temp WITH (NOLOCK)
INNER JOIN #SegmentStatusTable P_SST_Temp WITH (NOLOCK)
ON SST_Temp.ParentSegmentStatusId = P_SST_Temp.SegmentStatusId

--Set already added segment status id in new segment status id
UPDATE SST_Temp
SET SST_Temp.NewSegmentStatusId = SST_Temp.SegmentStatusId
FROM #SegmentStatusTable SST_Temp
WHERE SST_Temp.Action = 'UPDATE'

--Update parent segment status id in ProjectSegmentStatus table
UPDATE PSST
SET PSST.ParentSegmentStatusId = SST_Temp.NewParentSegmentStatusId
FROM #SegmentStatusTable SST_Temp WITH (NOLOCK)
INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)
ON SST_Temp.NewSegmentStatusId = PSST.SegmentStatusId
WHERE PSST.ProjectId = @ProjectId
AND PSST.CustomerId = @CustomerId
AND PSST.SectionId = @SectionId
AND SST_Temp.NewParentSegmentStatusId IS NOT NULL

--Clear SegmentId used for temp purpose
--NOTE: This should be last sentence
UPDATE PSST
SET PSST.SegmentId = NULL
FROM #SegmentStatusTable SST_Temp WITH (NOLOCK)
INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)
ON SST_Temp.NewSegmentStatusId = PSST.SegmentStatusId
WHERE PSST.ProjectId = @ProjectId
AND PSST.CustomerId = @CustomerId
AND PSST.SectionId = @SectionId
AND SST_Temp.Action = 'INSERT'

EXEC usp_MapSegmentChoiceFromMasterToProject @ProjectId = @ProjectId
,@SectionId = @SectionId
,@CustomerId = @CustomerId
,@UserId = @UserId;

EXEC usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @ProjectId
,@SectionId = @SectionId
,@CustomerId = @CustomerId
,@UserId = @UserId;
SELECT
PSST.ProjectId AS ProjectId
,PSST.CustomerId AS CustomerId
,PSST.SectionId AS SectionId
,@UserId AS UserId
,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId
,SST_Temp.UISegmentStatusId AS SegmentStatusId
,SST_Temp.ParentSegmentStatusId AS ParentSegmentStatusId
,SST_Temp.Action AS Action
,PSST.IndentLevel AS IndentLevel
,PSST.SequenceNumber AS SequenceNumber
,PSST.SegmentStatusId AS OriginalSegmentStatusId
,PSST.ParentSegmentStatusId AS OriginalParentSegmentStatusId
,SST_Temp.UserFullName
FROM #SegmentStatusTable SST_Temp
INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)
ON SST_Temp.NewSegmentStatusId = PSST.SegmentStatusId
WHERE PSST.ProjectId = @ProjectId
AND PSST.CustomerId = @CustomerId
AND PSST.SectionId = @SectionId

END
GO


