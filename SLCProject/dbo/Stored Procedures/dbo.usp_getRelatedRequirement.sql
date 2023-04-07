
CREATE PROCEDURE [dbo].[usp_getRelatedRequirement]
(
	@sectionId INT,
	@userId int =0
)
AS
BEGIN
	DECLARE @PsectionId INT = @sectionId;
	DECLARE @PuserId int = @userId;
--Set Nocount On
SET NOCOUNT ON
		
		DECLARE @segmentStatusId BIGINT,@mSegmentId INT
		DECLARE @false BIT=0,@true BIT=1,@sectionCode int
		declare @ProjectId int,@CustomerId int,@msectionId int

SELECT
	@sectionCode = SectionCode
   ,@ProjectId = ProjectId
   ,@CustomerId = CustomerId
   ,@userId = UserId
   ,@msectionId = mSectionId
FROM projectSection(nolock)
WHERE sectionId = @PsectionId;

IF (@msectionId IS NULL)
BEGIN
SELECT TOP 1
	@segmentStatusId = pss.segmentStatusId
   ,@mSegmentId = pss.mSegmentId
FROM  projectSegmentStatus pss (NOLOCK)
INNER JOIN  ProjectSegment msg (NOLOCK)
	ON pss.SegmentId = msg.segmentId
WHERE UPPER(REPLACE(msg.segmentDescription, '?', ' ')) = 'RELATED REQUIREMENTS'
AND PSS.ProjectId = @ProjectId AND pss.sectionId = @PsectionId
AND pss.indentLevel = 2;
END

SELECT
	@segmentStatusId = pss.segmentStatusId
   ,@mSegmentId = pss.mSegmentId
FROM  projectSegmentStatus pss (NOLOCK)
INNER JOIN slcMaster.dbo.segment msg (NOLOCK)
	ON pss.mSegmentId = msg.segmentId
WHERE UPPER(REPLACE(msg.segmentDescription, '?', ' ')) = 'RELATED REQUIREMENTS'
AND PSS.ProjectId = @ProjectId AND pss.sectionId = @PsectionId
AND pss.indentLevel = 2;

--invisible space replaced 
--UPPER(replace(msg.segmentDescription,'?',' '))

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
FROM  projectSegmentStatus pss (NOLOCK)
INNER JOIN slcMaster.dbo.segment msg (NOLOCK)
	ON pss.mSegmentId = msg.segmentId
WHERE UPPER(REPLACE(msg.segmentDescription, '?', ' ')) = 'RELATED REQUIREMENTS'
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
	   ,CONVERT(NVARCHAR(MAX), msg.segmentDescription) AS segmentDescription
	   ,pss.SegmentOrigin
	   ,(CASE
			WHEN pss.SegmentStatusTypeId < 6 AND
				pss.IsParentSegmentStatusActive = 1 THEN @true
			ELSE @false
		END) AS IsActive
	FROM projectSegmentStatus pss (NOLOCK)
	INNER JOIN slcMaster.dbo.segment msg (NOLOCK)
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
	   ,CONVERT(NVARCHAR(MAX), COALESCE(msg.BaseSegmentDescription, msg.segmentDescription)) AS segmentDescription
	   ,pss.SegmentOrigin
	   ,(CASE
			WHEN pss.SegmentStatusTypeId < 6 OR
				pss.IsParentSegmentStatusActive = 1 THEN @true
			ELSE @false
		END) AS IsActive
	FROM  projectSegmentStatus pss (NOLOCK)
	INNER JOIN [Projectsegment] msg (NOLOCK)
		ON pss.SegmentId = msg.segmentId
	WHERE pss.parentSegmentStatusId = @segmentStatusId
	AND PSS.ProjectId = @ProjectId AND pss.sectionId = @PsectionId
	AND pss.SegmentOrigin = 'U') AS x;

UPDATE t
SET t.segmentDescription = dbo.[fnGetSegmentDescriptionTextForChoice](t.PSegmentStatusId)
FROM #temp t
INNER JOIN [SLCMaster].[dbo].[SegmentChoice] sc (NOLOCK)
	ON t.mSegmentId = sc.segmentId
WHERE t.SegmentOrigin = 'M'

UPDATE t
SET t.segmentDescription = dbo.[fnGetSegmentDescriptionTextForChoice](t.PSegmentStatusId)
FROM #temp t
INNER JOIN [ProjectSegmentChoice] psc (NOLOCK)
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
   ,oldText
   ,dbo.[fnGetSegmentDescriptionTextForRSAndGT](@ProjectId, @CustomerId, segmentDescription) AS segmentDescription
   ,SegmentOrigin
   ,IsActive
FROM #temp t
END
GO



