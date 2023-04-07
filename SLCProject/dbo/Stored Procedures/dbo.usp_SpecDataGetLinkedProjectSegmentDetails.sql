CREATE procedure [dbo].[usp_SpecDataGetLinkedProjectSegmentDetails]
(
   @SegmentStatusJson NVARCHAR(max)
)
AS
BEGIN


DECLARE @TempMappingtable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,SectionId INT
   ,SegmentStatusId BIGINT
   ,RowId INT
)

INSERT INTO @TempMappingtable
	SELECT
		*
	   ,ROW_NUMBER() OVER (ORDER BY SegmentStatusId ASC) AS RowId
	FROM OPENJSON(@SegmentStatusJson)
	WITH (
	ProjectId INT '$.ProjectId',
	CustomerId INT '$.CustomerId',
	SectionId INT '$.SectionId',
	SegmentStatusId BIGINT '$.SegmentStatusId'
	);

DECLARE @SegmentTempTable TABLE (
	SegmentStatusId BIGINT
   ,SectionId INT
   ,ParentSegmentStatusId BIGINT
   ,mSegmentStatusId INT
   ,mSegmentId INT
   ,IndentLevel INT
   ,ProjectId INT
   ,SegmentId BIGINT
   ,CustomerId INT

)
DECLARE @SegmentStatusId BIGINT = 0;
DECLARE @SectionId INT = 0;
DECLARE @ProjectId INT = 0;

DECLARE @RowCount INT = (SELECT
		COUNT(SectionId)
	FROM @TempMappingtable);
DECLARE @n INT = 1;

WHILE (@RowCount >= @n)
BEGIN

SET @SegmentStatusId = 0;
SET @SectionId = 0;
SET @ProjectId = 0;;

SELECT
	@SegmentStatusId = pss.SegmentStatusId
   ,@SectionId = pss.SectionId
   ,@ProjectId = pss.ProjectId
FROM @TempMappingtable TMTBL
INNER JOIN ProjectSegmentStatus pss WITH (NOLOCK)
	ON pss.mSegmentStatusId = TMTBL.SegmentStatusId
		AND pss.ProjectId = TMTBL.ProjectId
		AND pss.CustomerId = TMTBL.CustomerId
WHERE RowId = @n
;
WITH cte
AS
(SELECT
		a.SegmentStatusId
	   ,a.SectionId
	   ,a.ParentSegmentStatusId
	   ,a.mSegmentStatusId
	   ,a.mSegmentId
	   ,a.IndentLevel
	   ,a.ProjectId
	   ,a.SegmentId
	   ,a.CustomerId

	FROM ProjectSegmentStatus a WITH (NOLOCK)
	WHERE a.SegmentStatusId = @SegmentStatusId
	AND ISNULL(a.IsDeleted, 0) = 0
	UNION ALL
	SELECT
		s.SegmentStatusId
	   ,s.SectionId
	   ,s.ParentSegmentStatusId
	   ,s.mSegmentStatusId
	   ,s.mSegmentId
	   ,s.IndentLevel
	   ,s.ProjectId
	   ,s.SegmentId
	   ,c.CustomerId
	FROM ProjectSegmentStatus s WITH (NOLOCK)
	JOIN cte c
		ON s.SegmentStatusId = c.ParentSegmentStatusId
		AND ISNULL(s.IsDeleted, 0) = 0
		AND s.IndentLevel > 0
		AND c.IndentLevel > 0)

INSERT INTO @SegmentTempTable (SegmentStatusId
, SectionId
, ParentSegmentStatusId
, mSegmentStatusId
, mSegmentId
, IndentLevel
, ProjectId
, SegmentId
, CustomerId)
	SELECT
		ss.SegmentStatusId
	   ,ss.SectionId
	   ,ss.ParentSegmentStatusId
	   ,ss.mSegmentStatusId
	   ,ss.mSegmentId
	   ,ss.IndentLevel
	   ,ss.ProjectId
	   ,ss.SegmentId
	   ,ss.CustomerId

	FROM ProjectSegmentStatus ss WITH (NOLOCK)
	WHERE ss.SegmentStatusId = @SegmentStatusId
	UNION
	SELECT
		C.SegmentStatusId
	   ,C.SectionId
	   ,C.ParentSegmentStatusId
	   ,C.mSegmentStatusId
	   ,C.mSegmentId
	   ,C.IndentLevel
	   ,C.ProjectId
	   ,C.SegmentId
	   ,C.CustomerId
	FROM cte C

SET @n = @n + 1;
	END

SELECT
	STBL.ProjectId
   ,STBL.CustomerId
   ,STBL.SectionId
   ,PS.SectionCode
   ,PSS.SegmentStatusCode
   ,PSS.SegmentSource
   ,STBL.SegmentStatusId
   ,PSS.IndentLevel
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
	ON PS.SectionId = PSS.SectionId
		AND PS.ProjectId = PSS.ProjectId
		AND ISNULL(PS.IsDeleted, 0) = 0
INNER JOIN @SegmentTempTable STBL
	ON PSS.SegmentStatusId = STBL.SegmentStatusId
		AND ISNULL(PSS.IsDeleted, 0) = 0

UNION
SELECT DISTINCT
	PSS.ProjectId
   ,PSS.CustomerId
   ,PS.SectionId
   ,PS.SectionCode
   ,PSS.SegmentStatusCode
   ,PSS.SegmentSource
   ,PSS.SegmentStatusId
   ,PSS.IndentLevel
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
	ON PS.SectionId = PSS.SectionId
		AND PS.ProjectId = PSS.ProjectId
		AND ISNULL(PS.IsDeleted, 0) = 0
INNER JOIN @SegmentTempTable STBL
	ON PSS.SectionId = STBL.SectionId
		AND PSS.ProjectId = STBL.ProjectId
		AND ISNULL(PSS.IsDeleted, 0) = 0
		AND PSS.IndentLevel = 0
END
GO


