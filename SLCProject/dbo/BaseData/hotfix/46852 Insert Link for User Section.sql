/*
 server name : SLCProject_SqlSlcOp004
 Customer Support 46852: Malfunctioning Links in Project Sections - Both USER and BSD Master Sections, All Projects
*/

DECLARE @IsSectionOpen bit =1
DECLARE @SourceSectionCode int =9
DECLARE @TargetSectionCode int =10016193
DECLARE @TargetProjectId   int =9957
DECLARE @CustomerId        int =1401
DECLARE @SourceProjectId   int =9957
--Soft Delete existing link
UPDATE PSL
SET IsDeleted = 1
FROM ProjectSegmentLink PSL WITH(NOLOCK)
WHERE TargetSectionCode = 10016193
AND Projectid = 9957
AND customerid = 1401

BEGIN -- Add records into ProjectSegmentLink                  
DROP TABLE IF EXISTS #ProjectSegmentLinkTemp;
CREATE TABLE #ProjectSegmentLinkTemp (
	SourceSectionCode INT
   ,SourceSegmentStatusCode INT
   ,SourceSegmentCode INT
   ,SourceSegmentChoiceCode INT
   ,SourceChoiceOptionCode INT
   ,LinkSource VARCHAR
   ,TargetSectionCode INT
   ,TargetSegmentStatusCode INT
   ,TargetSegmentCode INT
   ,TargetSegmentChoiceCode INT
   ,TargetChoiceOptionCode INT
   ,LinkTarget VARCHAR
   ,LinkStatusTypeId INT
   ,IsDeleted BIT
   ,CreateDate DATETIME2
   ,CreatedBy INT
   ,ModifiedBy INT
   ,ModifiedDate DATETIME2
   ,ProjectId INT
   ,CustomerId INT
   ,SegmentLinkCode INT
   ,SegmentLinkSourceTypeId INT
   ,
)
IF (@IsSectionOpen = 0)
BEGIN
INSERT INTO #ProjectSegmentLinkTemp
	SELECT
		(CASE
			WHEN MSLNK.SourceSectionCode = @SourceSectionCode THEN @TargetSectionCode
			ELSE MSLNK.SourceSectionCode
		END) AS SourceSectionCode
	   ,MSLNK.SourceSegmentStatusCode AS SourceSegmentStatusCode
	   ,MSLNK.SourceSegmentCode AS SourceSegmentCode
	   ,MSLNK.SourceSegmentChoiceCode AS SourceSegmentChoiceCode
	   ,MSLNK.SourceChoiceOptionCode AS SourceChoiceOptionCode
	   ,(CASE
			WHEN MSLNK.SourceSectionCode = @SourceSectionCode THEN 'U'
			ELSE MSLNK.LinkSource
		END) AS LinkSource
	   ,(CASE
			WHEN MSLNK.TargetSectionCode = @SourceSectionCode THEN @TargetSectionCode
			ELSE MSLNK.TargetSectionCode
		END) AS TargetSectionCode
	   ,MSLNK.TargetSegmentStatusCode AS TargetSegmentStatusCode
	   ,MSLNK.TargetSegmentCode AS TargetSegmentCode
	   ,MSLNK.TargetSegmentChoiceCode AS TargetSegmentChoiceCode
	   ,MSLNK.TargetChoiceOptionCode AS TargetChoiceOptionCode
	   ,(CASE
			WHEN MSLNK.TargetSectionCode = @SourceSectionCode THEN 'U'
			ELSE MSLNK.LinkTarget
		END) AS LinkTarget
	   ,MSLNK.LinkStatusTypeId AS LinkStatusTypeId
	   ,MSLNK.IsDeleted AS IsDeleted
	   ,GETUTCDATE() AS CreateDate
	   ,0 AS CreatedBy
	   ,0 AS ModifiedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,@TargetProjectId AS ProjectId
	   ,@CustomerId AS CustomerId
	   ,MSLNK.SegmentLinkCode AS SegmentLinkCode
	   ,(CASE
			WHEN MSLNK.SegmentLinkSourceTypeId = 1 THEN 5
			ELSE MSLNK.SegmentLinkSourceTypeId
		END) AS SegmentLinkSourceTypeId --INTO #ProjectSegmentLinkTemp          
	FROM SLCMaster..SegmentLink MSLNK WITH (NOLOCK)
	WHERE (MSLNK.SourceSectionCode = @SourceSectionCode
	OR MSLNK.TargetSectionCode = @SourceSectionCode)
	AND MSLNK.IsDeleted = 0
	AND MSLNK.SourceSectionCode = @SourceSectionCode
	AND @IsSectionOpen = 0
END
IF (@IsSectionOpen = 1)
BEGIN

INSERT INTO #ProjectSegmentLinkTemp
	SELECT
		PSL.SourceSectionCode
	   ,PSL.SourceSegmentStatusCode
	   ,PSL.SourceSegmentCode
	   ,PSL.SourceSegmentChoiceCode
	   ,PSL.SourceChoiceOptionCode
	   ,PSL.LinkSource
	   ,PSL.TargetSectionCode
	   ,PSL.TargetSegmentStatusCode
	   ,PSL.TargetSegmentCode
	   ,PSL.TargetSegmentChoiceCode
	   ,PSL.TargetChoiceOptionCode
	   ,PSL.LinkTarget
	   ,PSL.LinkStatusTypeId
	   ,PSL.IsDeleted
	   ,PSL.CreateDate
	   ,PSL.CreatedBy
	   ,PSL.ModifiedBy
	   ,PSL.ModifiedDate
	   ,PSL.ProjectId
	   ,PSL.CustomerId
	   ,PSL.SegmentLinkCode
	   ,(CASE
			WHEN PSL.SegmentLinkSourceTypeId = 1 THEN 5
			ELSE PSL.SegmentLinkSourceTypeId
		END) AS SegmentLinkSourceTypeId
	FROM ProjectSegmentLink PSL WITH (NOLOCK)
	WHERE PSL.ProjectId = @SourceProjectId
	AND (PSL.SourceSectionCode = @SourceSectionCode
	OR PSL.TargetSectionCode = @SourceSectionCode)
	AND PSL.CustomerId = @CustomerId
	AND ISNULL(PSL.IsDeleted, 0) = 0
	AND PSL.SourceSectionCode = @SourceSectionCode
	AND @IsSectionOpen = 1
END

--INSERT ProjectSegmentLink                                        
INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,                        
TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget,                        
LinkStatusTypeId, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId,                        
SegmentLinkCode, SegmentLinkSourceTypeId)                        
SELECT
	(CASE
		WHEN SrcPSL.SourceSectionCode = @SourceSectionCode THEN @TargetSectionCode
		ELSE SrcPSL.SourceSectionCode
	END) AS SourceSectionCode
   ,SrcPSL.SourceSegmentStatusCode
   ,SrcPSL.SourceSegmentCode
   ,SrcPSL.SourceSegmentChoiceCode
   ,SrcPSL.SourceChoiceOptionCode
   ,(CASE
		WHEN SrcPSL.SourceSectionCode = @SourceSectionCode THEN 'U'
		ELSE SrcPSL.LinkSource
	END) AS LinkSource
   ,(CASE
		WHEN SrcPSL.TargetSectionCode = @SourceSectionCode THEN @TargetSectionCode
		ELSE SrcPSL.TargetSectionCode
	END) AS TargetSectionCode
   ,SrcPSL.TargetSegmentStatusCode
   ,SrcPSL.TargetSegmentCode
   ,SrcPSL.TargetSegmentChoiceCode
   ,SrcPSL.TargetChoiceOptionCode
   ,(CASE
		WHEN (SrcPSL.SourceSectionCode = @SourceSectionCode AND
			SrcPSL.TargetSectionCode = @SourceSectionCode AND
			@IsSectionOpen = 1) THEN 'U'
		ELSE SrcPSL.LinkTarget
	END) AS LinkTarget
   ,SrcPSL.LinkStatusTypeId
   ,SrcPSL.IsDeleted
   ,SrcPSL.CreateDate AS CreateDate
   ,SrcPSL.CreatedBy AS CreatedBy
   ,SrcPSL.ModifiedBy AS ModifiedBy
   ,SrcPSL.ModifiedDate AS ModifiedDate
   ,@TargetProjectId AS ProjectId
   ,@CustomerId AS CustomerId
   ,SrcPSL.SegmentLinkCode
   ,SrcPSL.SegmentLinkSourceTypeId
FROM #ProjectSegmentLinkTemp AS SrcPSL WITH (NOLOCK)

UPDATE PSL
SET PSL.IsDeleted = 0
FROM ProjectSegmentLink PSL
WHERE TargetSegmentCode = 4
AND ProjectId = 9957
AND CustomerId = 1401
END
