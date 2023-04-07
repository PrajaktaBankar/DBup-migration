CREATE PROCEDURE [dbo].[usp_GetCommentsForReport]
(                    
@ProjectId INT,                    
@CustomerId INT,                                  
@SectionIdList NVARCHAR(MAX)              
)                        
AS 
BEGIN

DROP TABLE IF EXISTS #SectionIdTbl;
DROP TABLE IF EXISTS #SectionsTbl;
DROP TABLE IF EXISTS #CommentsTbl;
DROP TABLE IF EXISTS #ParentCommentsTbl;

DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionIdList NVARCHAR(MAX) = @SectionIdList;

-- Get source tag format
DECLARE @SourceTagFormat NVARCHAR(50) = '999999';
SELECT @SourceTagFormat = ISNULL(SourceTagFormat, '') 
FROM ProjectSummary PS WITH (NOLOCK) WHERE PS.CustomerId = @CustomerId AND PS.ProjectId = @PProjectId; 

-- Get project date and time format
DECLARE @DateFormat NVARCHAR(100), @ClockFormat NVARCHAR(20);
SELECT @DateFormat = ISNULL(DateFormat, 'MM-dd-yyyy'), @ClockFormat = ISNULL(ClockFormat, '12-hr') 
FROM ProjectDateFormat PS WITH (NOLOCK) WHERE PS.CustomerId =@CustomerId AND PS.ProjectId = @PProjectId; 

-- Convert section id string to table
SELECT splitdata AS SectionId 
INTO #SectionIdTbl
FROM dbo.fn_SplitString(@PSectionIdList, ',');

-- Get all comments for given sections
SELECT SC.SegmentCommentId, SC.ProjectId, SC.SectionId, SC.SegmentStatusId, SC.ParentCommentId, 
IIF(ISNULL(SC.ParentCommentId, 0) = 0, ISNULL(SC.CommentDescription, ''), '>>Reply: ' + ISNULL(SC.CommentDescription, '')) AS CommentDescription,
SC.CustomerId, SC.CreatedBy, SC.CreateDate, SC.ModifiedBy,
SC.ModifiedDate, SC.CommentStatusId,IIF(SC.CommentStatusId = 1, 'Open', 'Resolved') AS CommentStatusDescription,
SC.IsDeleted, SC.userFullName, PSS.SequenceNumber
INTO #CommentsTbl
FROM SegmentComment SC WITH(NOLOCK) 
INNER JOIN #SectionIdTbl S WITH(NOLOCK) ON S.SectionId = SC.SectionId
INNER JOIN ProjectSegmentStatus PSS WITH(NOLOCK) ON PSS.CustomerId = SC.CustomerId 
	AND PSS.ProjectId = SC.ProjectId AND PSS.SectionId = SC.SectionId AND PSS.SegmentStatusId = SC.SegmentStatusId
WHERE SC.CustomerId = @PCustomerId AND SC.ProjectId = @PProjectId
AND ISNULL(SC.IsDeleted, 0) = 0
AND ISNULL(PSS.IsDeleted, 0) = 0;

-- Get only parent comments from above result
SELECT * INTO #ParentCommentsTbl FROM #CommentsTbl WHERE ISNULL(ParentCommentId, 0) = 0;

-- Get section, sub folder and division details
SELECT PS.SectionId, PS.ParentSectionId, PS.SourceTag AS SectionNumber, PS.Author, PS.Description AS SectionName,
PSDiv.SourceTag AS DivisionNumber, PSDiv.Description AS DivisionName
INTO #SectionsTbl
FROM ProjectSection PS WITH(NOLOCK) 
INNER JOIN #SectionIdTbl S ON S.SectionId = PS.SectionId
INNER JOIN ProjectSection PSSub WITH(NOLOCK) ON PSSub.CustomerId = @PCustomerId AND PSSub.ProjectId = @PProjectId AND PSSub.SectionId = PS.ParentSectionId 
INNER JOIN ProjectSection PSDiv WITH(NOLOCK) ON PSDiv.CustomerId = @PCustomerId AND PSDiv.ProjectId = @PProjectId AND PSDiv.SectionId = PSSub.ParentSectionId
WHERE PS.CustomerId = @PCustomerId AND PS.ProjectId = @PProjectId;

-- Select final result
SELECT SC.SegmentCommentId, SC.ProjectId, SC.SectionId, SC.SegmentStatusId, SC.ParentCommentId, 
SC.CommentDescription, SC.CommentDescription,
SC.CustomerId, SC.CreatedBy, SC.CreateDate, SC.ModifiedBy,
SC.ModifiedDate, SC.CommentStatusId, 
CASE WHEN SC.ParentCommentId = 0 THEN SC.CommentStatusDescription ELSE PC.CommentStatusDescription END AS CommentStatusDescription,
SC.IsDeleted, SC.userFullName,
PS.SectionNumber, PS.Author, PS.SectionName,
PS.DivisionNumber, PS.DivisionName,
SC.SequenceNumber AS [Sequence], @SourceTagFormat AS SourceTagFormat,
ISNULL(@DateFormat, 'MM-dd-yyyy') AS [DateFormat], ISNULL(@ClockFormat, '12-hr') AS ClockFormat 
FROM #CommentsTbl SC INNER JOIN #SectionsTbl PS ON PS.SectionId = SC.SectionId
LEFT JOIN #ParentCommentsTbl PC ON PC.SegmentCommentId = SC.ParentCommentId
ORDER BY PS.DivisionNumber, PS.DivisionName, PS.SectionNumber, PS.Author, PS.SectionName,SC.SequenceNumber, SC.ParentCommentId

DROP TABLE IF EXISTS #SectionIdTbl;
DROP TABLE IF EXISTS #SectionsTbl;
DROP TABLE IF EXISTS #CommentsTbl;
DROP TABLE IF EXISTS #ParentCommentsTbl;

END