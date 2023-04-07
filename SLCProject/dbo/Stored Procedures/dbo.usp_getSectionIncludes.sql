
CREATE PROC [dbo].[usp_getSectionIncludes]
(
	@sectionId INT,
	@userId int =0
)
AS
BEGIN
	DECLARE @PsectionId INT = @sectionId;
	DECLARE @PuserId int = @userId;
--Set Nocount On
SET NOCOUNT ON;

		DECLARE @segmentStatusId BIGINT,@mSegmentId INT
		DECLARE @false BIT=0,@true BIT=1,@sectionCode int
		declare @ProjectId int,@CustomerId int,@msectionId int

SELECT
	@sectionCode = SectionCode
   ,@ProjectId = ProjectId
   ,@CustomerId = CustomerId
   ,@PuserId = UserId
   ,@msectionId = mSectionId
FROM projectSection WITH(NOLOCK)
WHERE sectionId = @PsectionId;

--invisible space replaced 
--UPPER(replace(msg.segmentDescription,'?',' '))

IF (@msectionId IS NULL)
BEGIN
SELECT TOP 1
	@segmentStatusId = pss.segmentStatusId
   ,@mSegmentId = pss.mSegmentId 
FROM projectSegmentStatus pss  WITH(NOLOCK)
INNER JOIN ProjectSegment msg  WITH(NOLOCK)
	ON pss.SegmentId = msg.segmentId
WHERE UPPER(REPLACE(msg.segmentDescription, '?', ' ')) = 'SECTION INCLUDES'
AND PSS.ProjectId = @ProjectId AND pss.sectionId = @PsectionId
AND pss.indentLevel = 2;
END

SELECT
	@segmentStatusId = pss.segmentStatusId
   ,@mSegmentId = pss.mSegmentId
FROM projectSegmentStatus pss  WITH(NOLOCK)
INNER JOIN slcMaster.dbo.segment msg  WITH(NOLOCK)
	ON pss.mSegmentId = msg.segmentId
WHERE UPPER(REPLACE(msg.segmentDescription, '?', ' ')) = 'SECTION INCLUDES'
AND PSS.ProjectId = @ProjectId AND pss.sectionId = @PsectionId
AND pss.indentLevel = 2;

IF (@segmentStatusId IS NULL)
BEGIN
EXECUTE usp_MapSegmentStatusFromMasterToProject @ProjectId = @ProjectId
												   ,@SectionId = @PSectionId
												   ,@CustomerId = @CustomerId
												   ,@UserId = @PUserId;
EXECUTE usp_MapSegmentChoiceFromMasterToProject @ProjectId = @ProjectId
												   ,@SectionId = @PSectionId
												   ,@CustomerId = @CustomerId
												   ,@UserId = @PUserId;
EXECUTE usp_MapProjectRefStands @ProjectId = @ProjectId
								   ,@SectionId = @PSectionId
								   ,@CustomerId = @CustomerId
								   ,@UserId = @PUserId;
END

SELECT
	@segmentStatusId = pss.segmentStatusId
   ,@mSegmentId = pss.mSegmentId
FROM projectSegmentStatus pss  WITH(NOLOCK)
INNER JOIN slcMaster.dbo.segment msg  WITH(NOLOCK)
	ON pss.mSegmentId = msg.segmentId
WHERE UPPER(REPLACE(msg.segmentDescription, '?', ' ')) = 'SECTION INCLUDES'
AND PSS.ProjectId = @ProjectId AND pss.sectionId = @PsectionId
AND pss.indentLevel = 2;

SELECT
	* INTO #temp
FROM (SELECT
		pss.SegmentStatusId AS PSegmentStatusId
	   ,pss.SegmentStatusCode
	   ,pss.mSegmentStatusId
	   ,pss.mSegmentId
	   ,pss.segmentId
	   ,pss.IsParentSegmentStatusActive
	   ,pss.SegmentStatusTypeId
	   ,msg.segmentDescription AS oldText
	   ,msg.segmentDescription
	   ,pss.SegmentOrigin
	   ,(CASE
			WHEN pss.SegmentStatusTypeId < 6 AND
				pss.IsParentSegmentStatusActive = 1 THEN @true
			ELSE @false
		END) AS IsActive
	FROM projectSegmentStatus pss  WITH(NOLOCK)
	INNER JOIN slcMaster.dbo.segment msg  WITH(NOLOCK)
		ON pss.mSegmentId = msg.segmentId
	WHERE pss.parentSegmentStatusId = @segmentStatusId
	AND PSS.ProjectId = @ProjectId AND pss.sectionId = @PsectionId
	AND SegmentOrigin = 'M'

	UNION

	SELECT
		pss.SegmentStatusId AS PSegmentStatusId
	   ,pss.SegmentStatusCode
	   ,pss.mSegmentStatusId
	   ,pss.mSegmentId
	   ,pss.segmentId
	   ,pss.IsParentSegmentStatusActive
	   ,pss.SegmentStatusTypeId
	   ,msg.segmentDescription AS oldText
	   ,msg.segmentDescription
	   ,pss.SegmentOrigin
	   ,(CASE
			WHEN pss.SegmentStatusTypeId < 6 AND
				pss.IsParentSegmentStatusActive = 1 THEN @true
			ELSE @false
		END) AS IsActive
	FROM projectSegmentStatus pss  WITH(NOLOCK)
	INNER JOIN [Projectsegment] msg  WITH(NOLOCK)
		ON pss.SegmentId = msg.segmentId
	WHERE pss.parentSegmentStatusId = @segmentStatusId
	AND PSS.ProjectId = @ProjectId AND pss.sectionId = @PsectionId
	AND pss.SegmentOrigin = 'U') AS x;



UPDATE t
SET t.segmentDescription = dbo.[fnGetSegmentDescriptionTextForChoice](t.PSegmentStatusId)
FROM #temp t
INNER JOIN [SLCMaster].[dbo].[SegmentChoice] sc  WITH(NOLOCK)
	ON t.mSegmentId = sc.segmentId
WHERE t.SegmentOrigin = 'M'

UPDATE t
SET t.segmentDescription = dbo.[fnGetSegmentDescriptionTextForChoice](t.PSegmentStatusId)
FROM #temp t
INNER JOIN [ProjectSegmentChoice] psc  WITH(NOLOCK)
	ON t.SegmentId = psc.segmentId
WHERE psc.ProjectId = @ProjectId AND psc.CustomerId = @CustomerId and psc.SectionId = @PsectionId and t.SegmentOrigin = 'U'

SELECT DISTINCT
	@sectionCode AS SectionCode
   ,PSegmentStatusId
   ,SegmentStatusCode
   ,SegmentStatusTypeId
   ,mSegmentStatusId
   ,IsParentSegmentStatusActive
   ,mSegmentId
   ,segmentId
   ,dbo.[fnGetSegmentDescriptionTextForRSAndGT](@ProjectId, @CustomerId, segmentDescription) AS segmentDescription
   ,SegmentOrigin
   ,IsActive
FROM #temp t
--SELECT * FROM #temp t ;
END
GO


