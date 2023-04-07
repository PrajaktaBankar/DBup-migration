CREATE PROCEDURE [dbo].[usp_DataLoadFromSlcProjectIntoSpecLive]
AS  
BEGIN
--Set Nocount On
SET NOCOUNT ON;

--CREATE TABLE TO PUT DATA
DECLARE @SegmentsTable TABLE (
	ProjectId INT NULL
   ,CustomerId INT NULL
   ,SegmentStatusId BIGINT NULL,
   ParentSegmentStatusId BIGINT NULL,
   SegmentDescription NVARCHAR(MAX) NULL
);

--FIRST INSERT THOSE SEGMENTS WHICH STARTS WITH 'Manufacturer'
INSERT INTO @SegmentsTable (ProjectId, CustomerId, SegmentStatusId, ParentSegmentStatusId, SegmentDescription)
	SELECT
		PSSTV.ProjectId
	   ,PSSTV.CustomerId
	   ,PSSTV.SegmentStatusId
	   ,PSSTV.ParentSegmentStatusId
	   ,PSSTV.SegmentDescription
	FROM ProjectSegmentStatusView PSSTV (NOLOCK)
	WHERE PSSTV.SegmentDescription LIKE 'Manufacturer%'
	AND PSSTV.IsSegmentStatusActive = 1

--TODO--ALSO INSERT ML,PP TAGGED SEGMENTS LATER

--INSERT PARENTS OF ABOVE SEGMENTS
--FIRST INSERT THOSE SEGMENTS WHICH STARTS WITH 'Manufacturer'
INSERT INTO @SegmentsTable (ProjectId, CustomerId, SegmentStatusId, ParentSegmentStatusId, SegmentDescription)
	SELECT
		PPSSTV.ProjectId
	   ,PPSSTV.CustomerId
	   ,PPSSTV.SegmentStatusId
	   ,PPSSTV.ParentSegmentStatusId
	   ,PPSSTV.SegmentDescription
	FROM @SegmentsTable SGTBL
	INNER JOIN ProjectSegmentStatusView PPSSTV (NOLOCK)
		ON SGTBL.ParentSegmentStatusId = PPSSTV.SegmentStatusId

SELECT
	*
FROM @SegmentsTable
ORDER BY SegmentStatusId ASC
END
GO


