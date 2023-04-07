


CREATE PROCEDURE [dbo].[usp_ApplyIndividualUpdates]
@InpSegmentsJson nvarchar(max)      
AS      
BEGIN

SET NOCOUNT ON;

Declare  @tblSegments table
(
  RowId int, ProjectId INT , SectionId INT , CustomerId INT , UserId INT , SegmentStatusId BIGINT ,
  mSectionId INT ,  newVersionSegmentId BIGINT , MSegmentStatusId INT ,MasterStatusIsDelete bit
);

Insert into @tblSegments
SELECT   ROW_NUMBER() OVER (ORDER BY ProjectId ASC) AS RowId,*
 FROM OPENJSON(@InpSegmentsJson)
 WITH (
 ProjectId INT '$.ProjectId',
 SectionId INT '$.SectionId', CustomerId INT '$.CustomerId', UserId INT '$.UserId', SegmentStatusId BIGINT '$.PSegmentStatusId',
  mSectionId INT '$.MSectionId',  newVersionSegmentId BIGINT '$.UpdId', MSegmentStatusId INT '$.MSegmentStatusId',MasterStatusIsDelete bit '$.MasterStatusIsDelete'
 );

DECLARE @PProjectId AS INT, @PCustomerId AS INT, @PUserId AS INT

SELECT TOP 1 @PProjectId = ProjectId, @PCustomerId = CustomerId, @PUserId = UserId FROM @tblSegments;

--When @PMasterStatusIsDelete IS True
IF EXISTS (SELECT * FROM @tblSegments WHERE MasterStatusIsDelete = 1)
BEGIN

	;WITH Parent
	 AS (SELECT c1.SegmentStatusId
		 ,c1.ParentSegmentStatusId
		 ,Level = 1
	  FROM ProjectSegmentStatus c1 WITH (NOLOCK)
	  INNER JOIN @tblSegments S ON c1.ProjectId = S.ProjectId AND c1.CustomerId = S.CustomerId AND c1.SectionId = S.SectionId AND c1.SegmentStatusId = S.SegmentStatusId
		AND ISNULL(S.MasterStatusIsDelete, 0) = 1
	  WHERE ISNULL(S.MasterStatusIsDelete, 0) = 1
	  UNION ALL
	  SELECT c2.SegmentStatusId
		 ,c2.ParentSegmentStatusId
		 ,Level = Level + 1
	  FROM ProjectSegmentStatus c2 WITH (NOLOCK)
	  INNER JOIN Parent    
	   ON Parent.SegmentStatusId = c2.ParentSegmentStatusId)    
    
	UPDATE PSS
	SET PSS.IsDeleted = 1
	FROM ProjectSegmentStatus PSS WITH (NOLOCK)
	INNER JOIN Parent P WITH (NOLOCK) ON P.SegmentStatusId = PSS.SegmentStatusId
	WHERE PSS.ProjectId = @PProjectId AND PSS.CustomerId = @PCustomerId

END

IF EXISTS (SELECT * FROM @tblSegments WHERE MasterStatusIsDelete = 0)
BEGIN
	UPDATE pss     
	SET pss.mSegmentId = S.newVersionSegmentId
	FROM dbo.ProjectSegmentStatus pss WITH (NOLOCK)
	INNER JOIN @tblSegments S ON pss.ProjectId = S.ProjectId AND pss.CustomerId = S.CustomerId AND pss.SectionId = S.SectionId AND pss.SegmentStatusId = S.SegmentStatusId
		AND pss.mSegmentStatusId = S.MSegmentStatusId AND ISNULL(S.MasterStatusIsDelete, 0) = 0
	WHERE pss.ProjectId = @PProjectId AND pss.CustomerId = @PCustomerId AND ISNULL(S.MasterStatusIsDelete, 0) = 0

	--MAP CHOICES    
	INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, ProjectId, CustomerId, SectionId)
	SELECT
	MCH.SegmentChoiceCode
	,MCHOP.ChoiceOptionCode
	,MSCHOP.ChoiceOptionSource
	,MSCHOP.IsSelected
	,S.ProjectId
	,S.CustomerId
	,S.SectionId
	FROM SLCMaster.dbo.SegmentChoice AS MCH WITH (NOLOCK)
	INNER JOIN SLCMaster..ChoiceOption AS MCHOP WITH (NOLOCK)
	ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId
	INNER JOIN SLCMaster..SelectedChoiceOption AS MSCHOP WITH (NOLOCK)
	ON MCH.SegmentChoiceCode = MSCHOP.SegmentChoiceCode
	AND MCHOP.ChoiceOptionCode = MSCHOP.ChoiceOptionCode
	AND MCH.SectionId=MSCHOP.SectionId
	INNER JOIN @tblSegments S ON MCH.SectionId = S.mSectionId AND MCH.SegmentId = S.newVersionSegmentId AND ISNULL(S.MasterStatusIsDelete, 0) = 0
	WHERE ISNULL(S.MasterStatusIsDelete, 0) = 0;


	DROP TABLE IF EXISTS #t_ProjectSegmentStatusView;

	SELECT PS.SectionCode, PSST.SegmentStatusCode
		,(CASE WHEN PSST.SegmentStatusId IS NOT NULL AND PSST_PSG.SegmentId IS NOT NULL THEN PSST_PSG.SegmentCode
				WHEN PSST.SegmentStatusId IS NOT NULL AND PSST_MSG.SegmentId IS NOT NULL THEN PSST_MSG.SegmentCode
		  ELSE NULL END) AS SegmentCode
		,PS.SectionId
		,PSST.SegmentStatusId
		,PSST.ProjectId
		,PSST.CustomerId
		,PSST.mSegmentId
		,PSST.CreatedBy
	INTO #t_ProjectSegmentStatusView
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN ProjectSection PS WITH (NOLOCK) ON PSST.ProjectId = PS.ProjectId AND PSST.SectionId = PS.SectionId
	INNER JOIN @tblSegments S ON PSST.ProjectId = S.ProjectId AND PSST.SectionId = S.SectionId AND PSST.CustomerId = S.CustomerId AND PSST.SegmentStatusId = S.SegmentStatusId
		AND ISNULL(S.MasterStatusIsDelete, 0) = 0
	LEFT JOIN ProjectSegment PSST_PSG WITH (NOLOCK) ON PSST.SegmentId = PSST_PSG.SegmentId AND PSST.SegmentOrigin = 'U'
	LEFT JOIN SLCMaster..Segment PSST_MSG WITH (NOLOCK) ON PSST.mSegmentId = PSST_MSG.SegmentId AND PSST.SegmentOrigin = 'M'
	WHERE PSST.ProjectId = @PProjectId AND PSST.CustomerId = @PCustomerId AND ISNULL(S.MasterStatusIsDelete, 0) = 0;

	DECLARE @PSectionCode AS INT, @PSegmentStatusCode AS INT
	SELECT TOP 1 @PSectionCode = SectionCode, @PSegmentStatusCode = SegmentStatusCode FROM #t_ProjectSegmentStatusView;

	DROP TABLE IF EXISTS #t_ProjectSegmentLink;
	DROP TABLE IF EXISTS #PSegLink;

	DECLARE @MasterLinkSource NVARCHAR(MAX) = 'M', @MasterLinkTarget NVARCHAR(MAX) = 'M', @UserSegmentLinkSourceTypeId INT = 5, @MinUserSegmentLinkCode BIGINT = 10000000;

	SELECT
		PSLNK.SegmentLinkId
		,PSLNK.SourceSegmentCode
		,PSLNK.TargetSegmentCode
		,PSLNK.LinkStatusTypeId
		,PSLNK.IsDeleted
		,PSLNK.SegmentLinkCode
		,PSLNK.SourceSectionCode
		,PSLNK.SourceSegmentStatusCode
		,PSLNK.TargetSectionCode
		,PSLNK.TargetSegmentStatusCode
		,PSLNK.ProjectId
		,PSLNK.CustomerId
		,PSLNK.LinkSource
		,PSLNK.LinkTarget
		,PSLNK.SegmentLinkSourceTypeId
	INTO #PSegLink
	FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
	WHERE PSLNK.ProjectId = @PProjectId AND PSLNK.CustomerId = @PCustomerId AND ISNULL(PSLNK.IsDeleted, 0) = 0

	SELECT
		PSLNK.SegmentLinkId
		,PSLNK.SourceSegmentCode
		,PSLNK.TargetSegmentCode
		,PSLNK.LinkStatusTypeId
		,PSLNK.IsDeleted
		,PSLNK.SegmentLinkCode
		,PSLNK.SourceSectionCode
		,PSLNK.SourceSegmentStatusCode
		,PSLNK.TargetSectionCode
		,PSLNK.TargetSegmentStatusCode
	INTO #t_ProjectSegmentLink
	FROM #PSegLink PSLNK WITH (NOLOCK)
	INNER JOIN #t_ProjectSegmentStatusView PSTV WITH (NOLOCK) ON PSLNK.ProjectId = @PProjectId AND PSLNK.ProjectId = PSTV.ProjectId AND PSLNK.CustomerId = PSTV.CustomerId
		AND PSLNK.SourceSegmentStatusCode = PSTV.SegmentStatusCode
		--AND (PSLNK.SourceSegmentStatusCode = PSTV.SegmentStatusCode OR PSLNK.TargetSegmentStatusCode=PSTV.SegmentStatusCode)
	--INNER JOIN @tblSegments S ON PSLNK.ProjectId = S.ProjectId AND PSLNK.CustomerId = S.CustomerId
	WHERE PSLNK.ProjectId = @PProjectId AND PSLNK.CustomerId = @PCustomerId
	AND PSLNK.LinkSource = @MasterLinkSource AND PSLNK.LinkTarget = @MasterLinkTarget
	AND PSLNK.SegmentLinkSourceTypeId != @UserSegmentLinkSourceTypeId
	--AND PSLNK.IsDeleted = 0 --AND ISNULL(S.MasterStatusIsDelete, 0) = 0;
	--AND (PSLNK.SourceSegmentStatusCode = PSTV.SegmentStatusCode OR PSLNK.TargetSegmentStatusCode=PSTV.SegmentStatusCode)
	UNION ALL
	SELECT
		PSLNK.SegmentLinkId
		,PSLNK.SourceSegmentCode
		,PSLNK.TargetSegmentCode
		,PSLNK.LinkStatusTypeId
		,PSLNK.IsDeleted
		,PSLNK.SegmentLinkCode
		,PSLNK.SourceSectionCode
		,PSLNK.SourceSegmentStatusCode
		,PSLNK.TargetSectionCode
		,PSLNK.TargetSegmentStatusCode
	FROM #PSegLink PSLNK WITH (NOLOCK)
	INNER JOIN #t_ProjectSegmentStatusView PSTV WITH (NOLOCK) ON PSLNK.ProjectId = @PProjectId AND PSLNK.ProjectId = PSTV.ProjectId AND PSLNK.CustomerId = PSTV.CustomerId
		AND PSLNK.TargetSegmentStatusCode = PSTV.SegmentStatusCode
		--AND (PSLNK.SourceSegmentStatusCode = PSTV.SegmentStatusCode OR PSLNK.TargetSegmentStatusCode=PSTV.SegmentStatusCode)
	--INNER JOIN @tblSegments S ON PSLNK.ProjectId = S.ProjectId AND PSLNK.CustomerId = S.CustomerId
	WHERE PSLNK.ProjectId = @PProjectId AND PSLNK.CustomerId = @PCustomerId
	AND PSLNK.LinkSource = @MasterLinkSource AND PSLNK.LinkTarget = @MasterLinkTarget
	AND PSLNK.SegmentLinkSourceTypeId != @UserSegmentLinkSourceTypeId
	--AND PSLNK.IsDeleted = 0

	--SELECT
	--	PSLNK.SegmentLinkId
	--	,PSLNK.SourceSegmentCode
	--	,PSLNK.TargetSegmentCode
	--	,PSLNK.LinkStatusTypeId
	--	,PSLNK.IsDeleted
	--	,SegmentLinkCode
	--	,PSLNK.SourceSectionCode
	--	,PSLNK.SourceSegmentStatusCode
	--	,PSLNK.TargetSectionCode
	--	,PSLNK.TargetSegmentStatusCode
	--INTO #t_ProjectSegmentLink
	--FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
	--INNER JOIN #t_ProjectSegmentStatusView PSTV WITH (NOLOCK) ON PSLNK.ProjectId = @PProjectId
	--	AND (PSLNK.SourceSegmentStatusCode = PSTV.SegmentStatusCode OR PSLNK.TargetSegmentStatusCode=PSTV.SegmentStatusCode)
	--INNER JOIN @tblSegments S ON PSLNK.ProjectId = S.ProjectId AND PSLNK.CustomerId = S.CustomerId
	--WHERE PSLNK.ProjectId = @PProjectId AND PSLNK.CustomerId = @PCustomerId
	--AND PSLNK.LinkSource = @MasterLinkSource AND PSLNK.LinkTarget = @MasterLinkTarget
	--AND PSLNK.SegmentLinkSourceTypeId != @UserSegmentLinkSourceTypeId
	--AND PSLNK.IsDeleted = 0 AND ISNULL(S.MasterStatusIsDelete, 0) = 0;


	--WORK FOR APPLY UPDATES OF SEGMENT LINKS IN PROJECT DB     
	--WHERE SOURCE SEGMENT STATUS CODE MATCHES WITH CURRENTLY APPLYING SEGMENT STATUS    
	UPDATE PSLNK
	SET 	PSLNK.SourceSegmentCode = MSLNK.SourceSegmentCode
		,PSLNK.TargetSegmentCode = MSLNK.TargetSegmentCode
		,PSLNK.LinkStatusTypeId = MSLNK.LinkStatusTypeId
	FROM #t_ProjectSegmentStatusView SrcPSSTV WITH (NOLOCK)
	INNER JOIN SLCMaster..SegmentLink MSLNK WITH (NOLOCK) ON SrcPSSTV.SectionCode = MSLNK.SourceSectionCode AND SrcPSSTV.SegmentStatusCode = MSLNK.SourceSegmentStatusCode
		AND SrcPSSTV.SegmentCode = MSLNK.SourceSegmentCode
	INNER JOIN #t_ProjectSegmentStatusView TgtPSSTV WITH (NOLOCK) ON MSLNK.TargetSectionCode = TgtPSSTV.SectionCode AND MSLNK.TargetSegmentStatusCode = TgtPSSTV.SegmentStatusCode
		AND MSLNK.TargetSegmentCode = TgtPSSTV.SegmentCode AND TgtPSSTV.ProjectId = @PProjectId AND TgtPSSTV.CustomerId = @PCustomerId
	INNER JOIN #t_ProjectSegmentLink PSLNK WITH (NOLOCK) ON MSLNK.SegmentLinkCode = PSLNK.SegmentLinkCode
	INNER JOIN @tblSegments S ON SrcPSSTV.ProjectId = S.ProjectId AND SrcPSSTV.CustomerId = S.CustomerId AND SrcPSSTV.SectionId = S.SectionId
		AND SrcPSSTV.SegmentStatusId = S.SegmentStatusId
	WHERE SrcPSSTV.ProjectId = @PProjectId AND SrcPSSTV.CustomerId = @PCustomerId AND ISNULL(S.MasterStatusIsDelete, 0) = 0
	AND ((MSLNK.SourceSegmentCode != PSLNK.SourceSegmentCode) OR (MSLNK.TargetSegmentCode = PSLNK.TargetSegmentCode)
		OR (MSLNK.LinkStatusTypeId != PSLNK.LinkStatusTypeId))

	--WORK FOR APPLY UPDATES OF SEGMENT LINKS IN PROJECT DB     
	--WHERE TARGET SEGMENT STATUS CODE MATCHES WITH CURRENTLY APPLYING SEGMENT STATUS    
	UPDATE PSLNK
	SET PSLNK.SourceSegmentCode = MSLNK.SourceSegmentCode
		,PSLNK.TargetSegmentCode = MSLNK.TargetSegmentCode
		,PSLNK.LinkStatusTypeId = MSLNK.LinkStatusTypeId
	FROM #t_ProjectSegmentStatusView TgtPSSTV WITH (NOLOCK)
	INNER JOIN SLCMaster..SegmentLink MSLNK WITH (NOLOCK) ON TgtPSSTV.SectionCode = MSLNK.TargetSectionCode AND TgtPSSTV.SegmentStatusCode = MSLNK.TargetSegmentStatusCode
		AND TgtPSSTV.SegmentCode = MSLNK.TargetSegmentCode
	INNER JOIN #t_ProjectSegmentStatusView SrcPSSTV WITH (NOLOCK) ON MSLNK.SourceSectionCode = SrcPSSTV.SectionCode AND MSLNK.SourceSegmentStatusCode = SrcPSSTV.SegmentStatusCode
		AND MSLNK.SourceSegmentCode = SrcPSSTV.SegmentCode AND SrcPSSTV.ProjectId = @PProjectId AND SrcPSSTV.CustomerId = @PCustomerId
	INNER JOIN #t_ProjectSegmentLink PSLNK WITH (NOLOCK) ON MSLNK.SegmentLinkCode = PSLNK.SegmentLinkCode
	INNER JOIN @tblSegments S ON SrcPSSTV.ProjectId = S.ProjectId AND SrcPSSTV.CustomerId = S.CustomerId AND SrcPSSTV.SectionId = S.SectionId
		AND SrcPSSTV.SegmentStatusId = S.SegmentStatusId AND ISNULL(S.MasterStatusIsDelete, 0) = 0
	WHERE TgtPSSTV.ProjectId = @PProjectId AND TgtPSSTV.CustomerId = @PCustomerId AND ISNULL(S.MasterStatusIsDelete, 0) = 0
	AND ((MSLNK.SourceSegmentCode != PSLNK.SourceSegmentCode) OR (MSLNK.TargetSegmentCode = PSLNK.TargetSegmentCode) OR (MSLNK.LinkStatusTypeId != PSLNK.LinkStatusTypeId))


	--Make ProjectSegmentLink as IsDeleted = 1
	UPDATE PSLNK
	SET PSLNK.IsDeleted = 1
	FROM #t_ProjectSegmentStatusView SrcPSSTV WITH (NOLOCK)
	INNER JOIN #t_ProjectSegmentLink PSLNK WITH (NOLOCK) ON SrcPSSTV.SectionCode = PSLNK.SourceSectionCode AND SrcPSSTV.SegmentStatusCode = PSLNK.SourceSegmentStatusCode
		AND PSLNK.SegmentLinkCode < @MinUserSegmentLinkCode AND PSLNK.IsDeleted = 0
	INNER JOIN #t_ProjectSegmentStatusView TgtPSSTV WITH (NOLOCK) ON PSLNK.TargetSectionCode = TgtPSSTV.SectionCode AND PSLNK.TargetSegmentStatusCode = TgtPSSTV.SegmentStatusCode
		AND PSLNK.TargetSegmentCode = TgtPSSTV.SegmentCode
	INNER JOIN @tblSegments S ON SrcPSSTV.ProjectId = S.ProjectId AND SrcPSSTV.CustomerId = S.CustomerId AND SrcPSSTV.SectionId = S.SectionId
		AND SrcPSSTV.SegmentStatusId = S.SegmentStatusId AND ISNULL(S.MasterStatusIsDelete, 0) = 0
	LEFT JOIN SLCMaster..SegmentLink MSLNK WITH (NOLOCK) ON PSLNK.SegmentLinkCode = MSLNK.SegmentLinkCode
	WHERE SrcPSSTV.ProjectId = @PProjectId AND SrcPSSTV.CustomerId = @PCustomerId AND SrcPSSTV.SectionId = S.SectionId AND SrcPSSTV.SegmentStatusId = S.SegmentStatusId
		 AND ISNULL(S.MasterStatusIsDelete, 0) = 0 AND (MSLNK.SegmentLinkId IS NULL OR MSLNK.IsDeleted = 1)


	--Make ProjectSegmentLink as IsDeleted = 1
	UPDATE PSLNK
	SET PSLNK.IsDeleted = 1
	FROM #t_ProjectSegmentStatusView TgtPSSTV WITH (NOLOCK)
	INNER JOIN #t_ProjectSegmentLink PSLNK WITH (NOLOCK) ON TgtPSSTV.SectionCode = PSLNK.TargetSectionCode AND TgtPSSTV.SegmentStatusCode = PSLNK.TargetSegmentStatusCode
		AND PSLNK.SegmentLinkCode < @MinUserSegmentLinkCode AND PSLNK.IsDeleted = 0
	INNER JOIN #t_ProjectSegmentStatusView SrcPSSTV WITH (NOLOCK) ON PSLNK.SourceSectionCode = SrcPSSTV.SectionCode AND PSLNK.SourceSegmentStatusCode = SrcPSSTV.SegmentStatusCode
		AND PSLNK.SourceSegmentCode = SrcPSSTV.SegmentCode
	INNER JOIN @tblSegments S ON SrcPSSTV.ProjectId = S.ProjectId AND SrcPSSTV.CustomerId = S.CustomerId AND SrcPSSTV.SectionId = S.SectionId
		AND SrcPSSTV.SegmentStatusId = S.SegmentStatusId AND ISNULL(S.MasterStatusIsDelete, 0) = 0
	LEFT JOIN SLCMaster..SegmentLink MSLNK WITH (NOLOCK) ON PSLNK.SegmentLinkCode = MSLNK.SegmentLinkCode
	WHERE TgtPSSTV.ProjectId = @PProjectId AND TgtPSSTV.CustomerId = @PCustomerId AND TgtPSSTV.SectionId = S.SectionId AND TgtPSSTV.SegmentStatusId = S.SegmentStatusId
		AND (MSLNK.SegmentLinkId IS NULL OR MSLNK.IsDeleted = 1)

	UPDATE PSL
	SET PSL.SourceSegmentCode = PSLNK.SourceSegmentCode
		,PSL.TargetSegmentCode = PSLNK.TargetSegmentCode
		,PSL.LinkStatusTypeId = PSLNK.LinkStatusTypeId
		,PSL.IsDeleted = PSLNK.IsDeleted
	FROM ProjectSegmentLink PSL WITH (NOLOCK)
	INNER JOIN #t_ProjectSegmentLink PSLNK WITH (NOLOCK) ON PSL.SegmentLinkId = PSLNK.SegmentLinkId


	DROP TABLE IF EXISTS #LinksBeforeUpdate
	DROP TABLE IF Exists #tempSourceLink
	DROP TABLE IF EXISTS #tempTargetLink
	DROP TABLE IF EXISTS #tempNeedstoUpdateIsDelete
	DROP TABLE IF EXISTS #tblSegments_New;

	SELECT S.*, MS.SectionCode AS SectionCode, SG.SegmentCode AS SegmentCode, PV.SegmentStatusCode, PV.mSegmentId INTO #tblSegments_New FROM @tblSegments S
	INNER JOIN SLCMaster.dbo.Section MS WITH (NOLOCK) ON MS.SectionId = S.mSectionId
	INNER JOIN SLCMaster.dbo.Segment SG WITH (NOLOCK) ON S.mSectionId = SG.SectionId AND S.newVersionSegmentId = SG.UpdatedId
	INNER JOIN #t_ProjectSegmentStatusView PV ON S.ProjectId = PV.ProjectId AND S.CustomerId = PV.CustomerId AND S.SectionId = PV.SectionId AND S.SegmentStatusId = PV.SegmentStatusId
	WHERE ISNULL(S.MasterStatusIsDelete, 0) = 0

	SELECT PSL.* INTO #tempSourceLink FROM ProjectSegmentLink PSL WITH (NOLOCK)
	INNER JOIN #tblSegments_New S ON PSL.ProjectId = S.ProjectId AND PSL.CustomerId = S.CustomerId AND PSL.SourceSectionCode = S.SectionCode
		AND PSL.SourceSegmentStatusCode = S.SegmentStatusCode
	WHERE PSL.ProjectId = @PProjectId AND PSL.CustomerId = @PCustomerId AND ISNULL(PSL.IsDeleted,0) = 0 AND ISNULL(S.MasterStatusIsDelete, 0) = 0

	SELECT PSL.*, S.mSegmentId INTO #tempTargetLink FROM ProjectSegmentLink PSL WITH (NOLOCK)
	INNER JOIN #tblSegments_New S ON PSL.ProjectId = S.ProjectId AND PSL.CustomerId = S.CustomerId AND PSL.TargetSectionCode = S.SectionCode
		AND PSL.TargetSegmentStatusCode = S.SegmentStatusCode
	WHERE PSL.ProjectId = @PProjectId AND PSL.CustomerId = @PCustomerId AND ISNULL(PSL.IsDeleted,0)=0 AND ISNULL(S.MasterStatusIsDelete, 0) = 0


	--1] copy links in temp table
	SELECT PSL.*, S.mSegmentId INTO #LinksBeforeUpdate FROM ProjectSegmentLink PSL WITH (NOLOCK)
	INNER JOIN #tblSegments_New S ON PSL.ProjectId = S.ProjectId AND PSL.CustomerId = S.CustomerId AND PSL.SourceSectionCode = S.SectionCode AND PSL.SourceSegmentCode = S.SegmentCode
	WHERE PSL.ProjectId = @PProjectId AND PSL.CustomerId = @PCustomerId

    
	--2] update segment code in temp table    
	UPDATE L SET SourceSegmentCode = SG.SegmentCode
	FROM #LinksBeforeUpdate L WITH (NOLOCK)
	INNER JOIN #tblSegments_New S ON L.ProjectId = S.ProjectId AND L.CustomerId = S.CustomerId AND L.SourceSectionCode = S.SectionCode AND L.SourceSegmentCode = S.SegmentCode
	INNER JOIN SLCMaster.dbo.Segment SG WITH (NOLOCK) ON L.mSegmentId = SG.SegmentId
	WHERE L.ProjectId = @PProjectId AND L.CustomerId = @PCustomerId


	--3] join with master link table
	SELECT 
		t.SegmentLinkId
		,t.TargetSegmentStatusCode
		,t.TargetSectionCode
		,0 as SectionId
		,0 as mSectionId
	INTO #tempNeedstoUpdateIsDelete
	FROM #LinksBeforeUpdate t
	FULL OUTER JOIN SLCMaster.dbo.SegmentLink SL WITH (NOLOCK) ON t.SourceSectionCode = SL.SourceSectionCode AND t.SourceSegmentStatusCode = SL.SourceSegmentStatusCode
		AND t.SourceSegmentCode = SL.SourceSegmentCode AND t.TargetSectionCode = SL.TargetSectionCode AND t.TargetSegmentStatusCode = SL.TargetSegmentStatusCode
		AND t.TargetSegmentCode = SL.TargetSegmentCode
	WHERE t.ProjectId = @PProjectId AND t.LinkSource = 'M' AND t.SourceSegmentChoiceCode IS NULL AND SL.SourceSegmentChoiceCode IS NULL
		AND SL.SourceSectionCode IS NULL


	--4] set isdeleted =1 for null records    
	--UPDATE PSL SET PSL.IsDeleted = 1
	DELETE PSL
	FROM ProjectSegmentLink PSL WITH(NOLOCK)
	INNER JOIN #tempNeedstoUpdateIsDelete t ON PSL.SegmentLinkId = t.SegmentLinkId
	WHERE PSL.ProjectId = @PProjectId AND PSL.CustomerId = @PCustomerId AND PSL.SegmentLinkSourceTypeId != 5


	--5] Update Latest SegmentCode for Non NULL records For Source    
	--UPDATE PSL
	----SET PSL.SourceSegmentCode = @NewSegmentCode  //Deleting this as we are copying new links at section visit
	--SET PSL.IsDeleted=1
	DELETE PSL
	FROM ProjectSegmentLink PSL WITH (NOLOCK)
	INNER JOIN #tblSegments_New S WITH (NOLOCK) ON PSL.ProjectId = S.ProjectId AND PSL.CustomerId = S.CustomerId AND PSL.SourceSegmentCode = S.SegmentCode
	WHERE PSL.ProjectId = @PProjectId AND PSL.CustomerId = @PCustomerId
	AND ISNULL(PSL.IsDeleted,0) = 0 AND PSL.SegmentLinkSourceTypeId != 5


	--6] Update Latest SegmentCode for Non NULL records For Target    
	--UPDATE PSL
	----SET PSL.TargetSegmentCode = @NewSegmentCode  //Deleting this as we are copying new links at section visit
	--SET PSL.IsDeleted=1
	DELETE PSL
	FROM ProjectSegmentLink PSL WITH(NOLOCK)
	INNER JOIN #tblSegments_New S WITH (NOLOCK) ON PSL.ProjectId = S.ProjectId AND PSL.CustomerId = S.CustomerId AND PSL.TargetSegmentCode = S.SegmentCode
	WHERE PSL.ProjectId = @PProjectId AND PSL.CustomerId = @PCustomerId AND ISNULL(PSL.IsDeleted,0) = 0 AND PSL.SegmentLinkSourceTypeId != 5

	UPDATE t SET t.mSectionId = s.SectionId
	FROM SLCMaster.dbo.Section S 
	INNER JOIN #tempNeedstoUpdateIsDelete t ON S.SectionCode = t.TargetSectionCode
	WHERE ISNULL(S.IsDeleted,0) = 0

	UPDATE t SET t.SectionId = PS.SectionId
	FROM ProjectSection PS
	INNER JOIN #tempNeedstoUpdateIsDelete t ON PS.mSectionId = t.mSectionId
	WHERE PS.ProjectId = @PProjectId AND PS.IsLastLevel = 1 AND ISNULL(PS.IsDeleted,0) = 0
 
	UPDATE psl SET psl.isdeleted=0, psl.SourceSegmentCode = t.SourceSegmentCode
	FROM ProjectSegmentLink psl WITH (NOLOCK)
	INNER JOIN #LinksBeforeUpdate t ON t.SegmentLinkId = psl.SegmentLinkId
	WHERE psl.SegmentLinkSourceTypeId=5

	UPDATE psl SET psl.isdeleted = 0, psl.TargetSegmentCode = SG.SegmentCode
	FROM ProjectSegmentLink psl WITH(NOLOCK)
	INNER JOIN #tempTargetLink t ON t.SegmentLinkId = psl.SegmentLinkId
	INNER JOIN SLCMaster.dbo.Segment SG WITH (NOLOCK) ON t.mSegmentId = SG.SegmentId
	where psl.SegmentLinkSourceTypeId=5


	UPDATE PSS SET PSS.SegmentStatusTypeId = IIF(PSS.SegmentStatusTypeId = 1 ,2, IIF(PSS.SegmentStatusTypeId = 7,6,IIF(PSS.SegmentStatusTypeId = 8,9,PSS.SegmentStatusTypeId)))    
	FROM #tempNeedstoUpdateIsDelete t
	INNER JOIN ProjectSegmentStatus PSS With(NOLOCK) ON t.SectionId = PSS.SectionId AND t.TargetSegmentStatusCode = PSS.SegmentStatusCode
	WHERE PSS.ProjectId = @PProjectId AND PSS.CustomerId = @PCustomerId AND PSS.SegmentStatusTypeId NOt IN(2,3,4,5,6)

	DROP TABLE IF EXISTS #ProjectSegmentLinkTemp;
		SELECT
			 PSLNK.SourceSectionCode
			,PSLNK.SourceSegmentStatusCode
			,PSLNK.SourceSegmentCode
			,PSLNK.SourceSegmentChoiceCode
			,PSLNK.SourceChoiceOptionCode
			,PSLNK.LinkSource
			,PSLNK.TargetSectionCode
			,PSLNK.TargetSegmentStatusCode
			,PSLNK.TargetSegmentCode
			,PSLNK.TargetSegmentChoiceCode
			,PSLNK.TargetChoiceOptionCode
			,PSLNK.LinkTarget
			,PSLNK.LinkStatusTypeId
			,PSLNK.SegmentLinkId
			,PSLNK.CreatedBy
			,PSLNK.ModifiedBy
		   INTO #ProjectSegmentLinkTemp
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK) 
		INNER JOIN #t_ProjectSegmentStatusView PSSV WITH (NOLOCK) ON (PSLNK.SourceSectionCode = PSSV.SectionCode
		OR PSLNK.TargetSectionCode = PSSV.SectionCode) AND (PSLNK.SourceSegmentStatusCode = PSSV.SegmentStatusCode
		OR PSLNK.TargetSegmentStatusCode = PSSV.SegmentStatusCode)
		WHERE PSLNK.ProjectId = @PProjectId
		AND PSLNK.CustomerId = @PCustomerId
	
		INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,
		TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget,
		LinkStatusTypeId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, ProjectId, CustomerId, SegmentLinkCode, SegmentLinkSourceTypeId)
		SELECT
			MSLNK.SourceSectionCode AS SourceSectionCode
		   ,MSLNK.SourceSegmentStatusCode AS SourceSegmentStatusCode
		   ,MSLNK.SourceSegmentCode AS SourceSegmentCode
		   ,MSLNK.SourceSegmentChoiceCode AS SourceSegmentChoiceCode
		   ,MSLNK.SourceChoiceOptionCode AS SourceChoiceOptionCode
		   ,MSLNK.LinkSource AS LinkSource
		   ,MSLNK.TargetSectionCode AS TargetSectionCode
		   ,MSLNK.TargetSegmentStatusCode AS TargetSegmentStatusCode
		   ,MSLNK.TargetSegmentCode AS TargetSegmentCode
		   ,MSLNK.TargetSegmentChoiceCode AS TargetSegmentChoiceCode
		   ,MSLNK.TargetChoiceOptionCode AS TargetChoiceOptionCode
		   ,MSLNK.LinkTarget AS LinkTarget
		   ,MSLNK.LinkStatusTypeId AS LinkStatusTypeId
		   ,GETUTCDATE() AS CreateDate
		   ,@PUserId AS CreatedBy
		   ,GETUTCDATE() AS ModifiedDate
		   ,@PUserId AS ModifiedBy
		   ,@pProjectId AS ProjectId
		   ,@pCustomerId AS CustomerId
		   ,MSLNK.SegmentLinkCode AS SegmentLinkCode
		   ,MSLNK.SegmentLinkSourceTypeId AS SegmentLinkSourceTypeId
		FROM SLCMaster..SegmentLink MSLNK WITH (NOLOCK)
		LEFT JOIN #ProjectSegmentLinkTemp PSLNK WITH (NOLOCK)
			ON  MSLNK.SourceSectionCode = PSLNK.SourceSectionCode
				AND MSLNK.SourceSegmentStatusCode = PSLNK.SourceSegmentStatusCode
				AND MSLNK.SourceSegmentCode = PSLNK.SourceSegmentCode
				AND ISNULL(MSLNK.SourceSegmentChoiceCode, 0) = ISNULL(PSLNK.SourceSegmentChoiceCode, 0)
				AND ISNULL(MSLNK.SourceChoiceOptionCode, 0) = ISNULL(PSLNK.SourceChoiceOptionCode, 0)
				AND MSLNK.LinkSource = PSLNK.LinkSource
				AND MSLNK.TargetSectionCode = PSLNK.TargetSectionCode
				AND MSLNK.TargetSegmentStatusCode = PSLNK.TargetSegmentStatusCode
				AND MSLNK.TargetSegmentCode = PSLNK.TargetSegmentCode
				AND ISNULL(MSLNK.TargetSegmentChoiceCode, 0) = ISNULL(PSLNK.TargetSegmentChoiceCode, 0)
				AND ISNULL(MSLNK.TargetChoiceOptionCode, 0) = ISNULL(PSLNK.TargetChoiceOptionCode, 0)
				AND MSLNK.LinkTarget = PSLNK.LinkTarget
				AND MSLNK.LinkStatusTypeId = PSLNK.LinkStatusTypeId
	  WHERE 
	  MSLNK.IsDeleted = 0  
	  AND (MSLNK.SourceSectionCode = @PSectionCode
	  OR MSLNK.TargetSectionCode = @PSectionCode) 
	  AND (MSLNK.SourceSegmentStatusCode = @PSegmentStatusCode
	  OR MSLNK.TargetSegmentStatusCode = @PSegmentStatusCode) 
	  AND PSLNK.SegmentLinkId IS NULL

END

END    


GO


