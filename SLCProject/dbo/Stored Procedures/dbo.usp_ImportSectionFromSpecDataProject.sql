CREATE PROCEDURE usp_ImportSectionFromSpecDataProject  
(          
     @MasterSectionIdJson      nvarchar(max)                  
)                      
AS                      
BEGIN

 DECLARE @StepInprogress INT = 2;
  
 DECLARE @ProgressPer10 INT = 10;
  
 DECLARE @ProgressPer20 INT = 20;
  
 DECLARE @ProgressPer30 INT = 30;
  
 DECLARE @ProgressPer40 INT = 40;
  
 DECLARE @ProgressPer50 INT = 50;
  
 DECLARE @ProgressPer60 INT = 60;
  
 DECLARE @ProgressPer65 INT = 65;

 DECLARE @ProgressPer80 INT = 80;

 DECLARE @ProgressPer100 INT = 100;
  
 DECLARE @InputDataTable TABLE (  
  RowId INT  
    ,TargetSectionId INT  
    ,RequestId INT  
	,TargetProjectId int
	,UserName nvarchar(500)
	,SourceProjectId INT                    
,SourceSectionId INT
,SourceCustomerId INT  
,UserId INT  
,CustomerId INT 
 );


INSERT INTO @InputDataTable
	SELECT
		ROW_NUMBER() OVER (ORDER BY TargetSectionId ASC) AS RowId
	   ,TargetSectionId
	   ,RequestId
	   ,TargetProjectId
	   ,UserName
	   ,SourceProjectId
	   ,SourceSectionId
	   ,SourceCustomerId
	   ,UserId
	   ,CustomerId
	FROM OPENJSON(@MasterSectionIdJson)
	WITH (
	TargetSectionId INT '$.SectionId'
	, RequestId INT '$.RequestId'
	, TargetProjectId INT '$.ProjectId'
	, UserName NVARCHAR(500) '$.UserName'
	, SourceProjectId INT '$.SrcProjectId'
	, SourceSectionId INT '$.SrcSectionId'
	, SourceCustomerId INT '$.SrcCustomerId'
	, UserId INT '$.UserId'
	, CustomerId INT '$.CustomerId'
	);


DECLARE @CustomerId INT;
DECLARE @UserId INT;
DECLARE @SourceProjectId INT;
DECLARE @SourceSectionId INT;
DECLARE @PTargetProjectId INT;
DECLARE @TargetSectionId INT;
DECLARE @UserName NVARCHAR(500) = NULL;
DECLARE @RequestId INT;
DECLARE @PCustomerId INT = 0;
DECLARE @PUserId INT = 0;
DECLARE @PSourceProjectId INT = 0;
DECLARE @PSourceSectionId INT = 0;
DECLARE @TargetProjectId INT = 0;
DECLARE @PUserName NVARCHAR(500) = '';
DECLARE @IsCompleted BIT = 1;
DECLARE @ImportSource NVARCHAR(100) = 'SpecAPI';
DECLARE @PTargetSectionId INT;

DECLARE @RowCount INT = (SELECT
				COUNT(TargetSectionId)
			FROM @InputDataTable)
	   ,@n INT = 1;

WHILE (@n <= @RowCount)
BEGIN


SET @PCustomerId = 0
	  ;
SET @PUserId = 0
		  ;
SET @PSourceProjectId = 0
 ;
SET @PSourceSectionId = 0
 ;
SET @PTargetProjectId = 0
 ;
SET @TargetSectionId = 0
   ;


SELECT

	@PCustomerId = CustomerId
   ,@PUserId = UserId
   ,@PSourceProjectId = SourceProjectId
   ,@PSourceSectionId = SourceSectionId
   ,@PTargetProjectId = TargetProjectId
   ,@PTargetSectionId = TargetSectionId
   ,@PUserName = UserName
   ,@CustomerId = CustomerId
   ,@UserId = UserId
   ,@SourceProjectId = SourceProjectId
   ,@SourceSectionId = SourceSectionId
   ,@TargetProjectId = TargetProjectId
   ,@TargetSectionId = TargetSectionId
   ,@UserName = UserName
   ,@RequestId = RequestId
FROM @InputDataTable
WHERE RowId = @n




DECLARE @SectionCode INT = NULL;
DECLARE @SourceTag VARCHAR(10) = '';
DECLARE @mSectionId INT = 0;
DECLARE @Author NVARCHAR(MAX) = '';


--FETCH SECTIONS DETAILS INTO VARIABLES                      
SELECT
	@SectionCode = SectionCode
   ,@SourceTag = SourceTag
   ,@mSectionId = mSectionId
   ,@Author = Author
FROM ProjectSection WITH (NOLOCK)
WHERE SectionId = @PSourceSectionId;

DROP TABLE IF EXISTS #SrcSegmentStatusTMP

SELECT
	PSST.* INTO #SrcSegmentStatusTMP
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
WHERE PSST.SectionId = @PSourceSectionId
AND PSST.ProjectId = @PSourceProjectId
AND ISNULL(PSST.IsDeleted, 0) = 0

--INSERT PROJECTSEGMENT STATUS                      
INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin,
IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId,
SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, IsPageBreak, A_SegmentStatusId)
	SELECT
		@TargetSectionId AS SectionId
	   ,PSS.ParentSegmentStatusId
	   ,PSS.mSegmentStatusId
	   ,PSS.mSegmentId
	   ,PSS.SegmentId
	   ,PSS.SegmentSource
	   ,PSS.SegmentOrigin
	   ,PSS.IndentLevel
	   ,PSS.SequenceNumber
	   ,PSS.SpecTypeTagId
	   ,PSS.SegmentStatusTypeId
	   ,PSS.IsParentSegmentStatusActive
	   ,@PTargetProjectId AS ProjectId
	   ,@PCustomerId AS CustomerId
	   ,PSS.SegmentStatusCode
	   ,PSS.IsShowAutoNumber
	   ,PSS.IsRefStdParagraph
	   ,PSS.FormattingJson
	   ,GETUTCDATE() AS CreateDate
	   ,@PUserId AS CreatedBy
	   ,@PUserId AS ModifiedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,PSS.IsPageBreak
	   ,PSS.SegmentStatusId
	FROM #SrcSegmentStatusTMP PSS



EXEC usp_MaintainImportProjectProgress NULL
									  ,@PTargetProjectId
									  ,NULL
									  ,@TargetSectionId
									  ,@UserId
									  ,@CustomerId
									  ,@StepInprogress
									  ,@ProgressPer10
									  ,0
									  ,@ImportSource
									  ,@RequestId;

--INSERT Tgt SegmentStatus into Temp tables   

DROP TABLE IF EXISTS #tmp_TgtSegmentStatus

SELECT
	PSST.* INTO #tmp_TgtSegmentStatus
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
WHERE PSST.SectionId = @TargetSectionId
AND PSST.ProjectId = @PTargetProjectId

DROP TABLE IF EXISTS #NewOldIdMapping

SELECT
	SegmentStatusId
   ,A_SegmentStatusId INTO #NewOldIdMapping
FROM #tmp_TgtSegmentStatus

--UPDATE PARENT SEGMENT STATUS ID                      
UPDATE TGT
SET TGT.ParentSegmentStatusId = t.SegmentStatusId
FROM #tmp_TgtSegmentStatus TGT
INNER JOIN #NewOldIdMapping t
	ON TGT.ParentSegmentStatusId = t.A_SegmentStatusId


--INSERT Src Segment into Temp tables                      
DROP TABLE IF EXISTS #tmp_SrcSegment

SELECT
	PSST_Src.SegmentStatusId AS NewSegmentStatusId
   ,@TargetSectionId AS SectionId
   ,@PTargetProjectId AS ProjectId
   ,@PCustomerId AS CustomerId
   ,PSG.SegmentDescription
   ,PSG.SegmentSource
   ,PSG.SegmentCode
   ,@PUserId AS CreatedBy
   ,GETUTCDATE() AS CreateDate
   ,@PUserId AS ModifiedBy
   ,GETUTCDATE() AS ModifiedDate
   ,PSG.SegmentId AS A_SegmentId
   ,BaseSegmentDescription INTO #tmp_SrcSegment
FROM ProjectSegment PSG WITH (NOLOCK)
INNER JOIN #tmp_TgtSegmentStatus PSST_Src
	ON PSG.SectionId = @PSourceSectionId
		AND PSG.SegmentStatusId = PSST_Src.A_SegmentStatusId
WHERE PSG.SectionId = @PSourceSectionId
AND PSG.ProjectId = @PSourceProjectId
AND ISNULL(PSG.IsDeleted, 0) = 0

--INSERT INTO PROJECTSEGMENT                      
INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription,
SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, A_SegmentId, BaseSegmentDescription)
	SELECT
		NewSegmentStatusId
	   ,SectionId
	   ,ProjectId
	   ,CustomerId
	   ,SegmentDescription
	   ,SegmentSource
	   ,SegmentCode
	   ,CreatedBy
	   ,CreateDate
	   ,ModifiedBy
	   ,ModifiedDate
	   ,A_SegmentId
	   ,BaseSegmentDescription
	FROM #tmp_SrcSegment

--INSERT Tgt Segment into Temp tables    

DROP TABLE IF EXISTS #tmp_TgtSegment

SELECT
	PSG.SegmentId
   ,PSG.SegmentStatusId
   ,PSG.SectionId
   ,PSG.ProjectId
   ,PSG.CustomerId
   ,PSG.SegmentCode
   ,PSG.IsDeleted
   ,PSG.A_SegmentId
   ,PSG.BaseSegmentDescription INTO #tmp_TgtSegment
FROM ProjectSegment PSG WITH (NOLOCK)
WHERE PSG.SectionId = @TargetSectionId
AND PSG.ProjectId = @PTargetProjectId
AND ISNULL(PSG.IsDeleted, 0) = 0

--UPDATE SegmentId IN ProjectSegmentStatus Temp (Changed for CSI 37207)  
UPDATE PSST_Target
SET PSST_Target.SegmentId = PSG_Target.SegmentId
FROM #tmp_TgtSegmentStatus PSST_Target WITH (NOLOCK)
INNER JOIN ProjectSegmentStatus PSST_Source WITH (NOLOCK)
	ON PSST_Source.SectionId = @PSourceSectionId
	AND PSST_Target.SegmentStatusCode = PSST_Source.SegmentStatusCode
INNER JOIN ProjectSegment PSG_Source WITH (NOLOCK)
	ON PSST_Source.SectionId = PSG_Source.SectionId
	AND PSST_Source.SegmentId = PSG_Source.SegmentId
INNER JOIN #tmp_TgtSegment PSG_Target WITH (NOLOCK)
	ON PSG_Target.SectionId = @TargetSectionId
	AND PSG_Source.SegmentCode = PSG_Target.SegmentCode
WHERE PSST_Target.SectionId = @TargetSectionId

--UPDATE ParentSegmentStatusId IN ORIGINAL TABLES                      
UPDATE PSST
SET PSST.ParentSegmentStatusId = TMP.ParentSegmentStatusId
   ,PSST.SegmentId = TMP.SegmentId
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN #tmp_TgtSegmentStatus TMP WITH (NOLOCK)
	ON PSST.SegmentStatusId = TMP.SegmentStatusId
WHERE PSST.SectionId = @TargetSectionId
AND PSST.ProjectId = @PTargetProjectId

EXEC usp_MaintainImportProjectProgress NULL
									  ,@PTargetProjectId
									  ,NULL
									  ,@TargetSectionId
									  ,@UserId
									  ,@CustomerId
									  ,@StepInprogress
									  ,@ProgressPer20
									  ,0
									  ,@ImportSource
									  ,@RequestId;

--INSERT PROJECTSEGMENT CHOICE                      
INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource,
SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, A_SegmentChoiceId)
	SELECT
		@TargetSectionId AS SectionId
	   ,PS_Target.SegmentStatusId
	   ,PS_Target.SegmentId
	   ,PCH_Source.ChoiceTypeId
	   ,@PTargetProjectId AS ProjectId
	   ,@PCustomerId AS CustomerId
	   ,PCH_Source.SegmentChoiceSource
	   ,PCH_Source.SegmentChoiceCode
	   ,@PUserId AS CreatedBy
	   ,GETUTCDATE() AS CreateDate
	   ,@PUserId AS ModifiedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,SegmentChoiceId AS A_SegmentChoiceId
	FROM ProjectSegmentChoice PCH_Source WITH (NOLOCK)
	INNER JOIN #tmp_TgtSegment PS_Target WITH (NOLOCK)
		ON PCH_Source.SectionId = @PSourceSectionId
			AND PCH_Source.SegmentId = PS_Target.A_SegmentId
	WHERE PCH_Source.SectionId = @PSourceSectionId
	AND PCH_Source.ProjectId = @PSourceProjectId
	AND ISNULL(PCH_Source.IsDeleted, 0) = 0
--AND ISNULL(PS_Target.IsDeleted, 0) = 0                

DROP TABLE IF EXISTS #tgtProjectSegmentChoice

SELECT
	ProjectId
   ,SectionId
   ,CustomerId
   ,SegmentChoiceId
   ,A_SegmentChoiceId INTO #tgtProjectSegmentChoice
FROM ProjectSegmentChoice WITH (NOLOCK)
WHERE SectionId = @TargetSectionId
AND ProjectId = @PTargetProjectId

--INSERT INTO CHOICE OPTIONS                      
INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId,
CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, A_ChoiceOptionId)
	SELECT
		t.SegmentChoiceId
	   ,PCH_Source.SortOrder
	   ,PCH_Source.ChoiceOptionSource
	   ,PCH_Source.OptionJson
	   ,t.ProjectId
	   ,t.SectionId
	   ,t.CustomerId
	   ,PCH_Source.ChoiceOptionCode
	   ,@PUserId AS CreatedBy
	   ,GETUTCDATE() AS CreateDate
	   ,@PUserId AS ModifiedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,PCH_Source.ChoiceOptionId
	FROM ProjectChoiceOption PCH_Source (NOLOCK)
	INNER JOIN #tgtProjectSegmentChoice t
		ON PCH_Source.SectionId = @PSourceSectionId
			AND PCH_Source.SegmentChoiceId = t.A_SegmentChoiceId
	WHERE PCH_Source.SectionId = @PSourceSectionId
	AND PCH_Source.ProjectId = @PSourceProjectId
	AND ISNULL(PCH_Source.IsDeleted, 0) = 0

DROP TABLE #tgtProjectSegmentChoice


--INSERT SELECTED CHOICE OPTIONS OF MASTER CHOICE                    
INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId, OptionJson)
	SELECT
		SCHOP_Source.SegmentChoiceCode
	   ,SCHOP_Source.ChoiceOptionCode
	   ,SCHOP_Source.ChoiceOptionSource
	   ,SCHOP_Source.IsSelected
	   ,@TargetSectionId AS SectionId
	   ,@PTargetProjectId AS ProjectId
	   ,@PCustomerId AS CustomerId
	   ,SCHOP_Source.OptionJson
	FROM SelectedChoiceOption SCHOP_Source WITH (NOLOCK)
	WHERE SCHOP_Source.SectionId = @PSourceSectionId
	AND SCHOP_Source.ProjectId = @PSourceProjectId
	AND ISNULL(SCHOP_Source.IsDeleted, 0) = 0
--AND SCHOP_Source.ChoiceOptionSource = 'M'        


EXEC usp_MaintainImportProjectProgress NULL
									  ,@PTargetProjectId
									  ,NULL
									  ,@TargetSectionId
									  ,@UserId
									  ,@CustomerId
									  ,@StepInprogress
									  ,@ProgressPer30
									  ,0
									  ,@ImportSource
									  ,@RequestId;

--INSERT NOTE                      
INSERT INTO ProjectNote (SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId, CustomerId, Title, CreatedBy, ModifiedBy,
CreatedUserName, ModifiedUserName, IsDeleted, NoteCode, A_NoteId)
	SELECT
		t.SectionId
	   ,t.SegmentStatusId
	   ,PN.NoteText
	   ,GETUTCDATE() AS CreateDate
	   ,GETUTCDATE() AS ModifiedDate
	   ,t.ProjectId
	   ,t.CustomerId
	   ,PN.Title
	   ,t.CreatedBy
	   ,t.ModifiedBy
	   ,@PUserName AS CreatedUserName
	   ,@PUserName AS ModifiedUserName
	   ,PN.IsDeleted
	   ,PN.NoteCode
	   ,PN.NoteId AS A_NoteId
	FROM ProjectNote PN WITH (NOLOCK)
	INNER JOIN #tmp_TgtSegmentStatus t
		ON PN.SectionId = @PSourceSectionId
			AND PN.SegmentStatusId = t.A_SegmentStatusId
	WHERE PN.SectionId = @PSourceSectionId
	AND PN.ProjectId = @PSourceProjectId

DROP TABLE IF EXISTS #note

SELECT
	NoteId
   ,SectionId
   ,ProjectId
   ,CustomerId
   ,A_NoteId INTO #note
FROM ProjectNote WITH (NOLOCK)
WHERE SectionId = @TargetSectionId
AND ProjectId = @PTargetProjectId

--INSERT Project Note Images                      
INSERT INTO ProjectNoteImage (NoteId, SectionId, ImageId, ProjectId, CustomerId)
	SELECT
		t.NoteId
	   ,t.SectionId
	   ,ImageId
	   ,t.ProjectId
	   ,t.CustomerId
	FROM ProjectNoteImage PNI WITH (NOLOCK)
	INNER JOIN #note t WITH (NOLOCK)
		ON PNI.NoteId = t.A_NoteId
	WHERE PNI.SectionId = @PSourceSectionId
	AND PNI.ProjectId = @PSourceProjectId


EXEC usp_MaintainImportProjectProgress NULL
									  ,@PTargetProjectId
									  ,NULL
									  ,@TargetSectionId
									  ,@UserId
									  ,@CustomerId
									  ,@StepInprogress
									  ,@ProgressPer40
									  ,0
									  ,@ImportSource
									  ,@RequestId;

DROP TABLE #note

--INSERT ProjectSegmentImage                      
INSERT INTO ProjectSegmentImage (SectionId, ImageId, ProjectId, CustomerId, SegmentId, ImageStyle)
	SELECT
		@TargetSectionId AS SectionId
	   ,ImageId
	   ,@PTargetProjectId AS ProjectId
	   ,@PCustomerId AS CustomerId
	   ,0 AS SegmentId
	   ,PSI.ImageStyle
	FROM ProjectSegmentImage PSI WITH (NOLOCK)
	WHERE PSI.SectionId = @PSourceSectionId
	AND PSI.ProjectId = @PSourceProjectId

--INSERT ProjectReferenceStandard                      
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId, IsObsolete,
RefStdCode, PublicationDate, SectionId, CustomerId)
	SELECT
		@PTargetProjectId AS ProjectId
	   ,RefStandardId
	   ,RefStdSource
	   ,mReplaceRefStdId
	   ,RefStdEditionId
	   ,IsObsolete
	   ,RefStdCode
	   ,PublicationDate
	   ,@TargetSectionId AS SectionId
	   ,@PCustomerId AS CustomerId
	FROM ProjectReferenceStandard WITH (NOLOCK)
	WHERE SectionId = @PSourceSectionId
	AND ProjectId = @PSourceProjectId
	AND ISNULL(IsDeleted, 0) = 0

--INSERT ProjectSegmentReferenceStandard                            
INSERT INTO ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource, mRefStandardId, CreateDate,
CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, mSegmentId, RefStdCode, IsDeleted)
	SELECT
		@TargetSectionId AS SectionId
	   ,PS_Target.SegmentId
	   ,RefStandardId
	   ,RefStandardSource
	   ,mRefStandardId
	   ,GETUTCDATE() AS CreateDate
	   ,@PUserId AS CreatedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,@PUserId AS ModifiedBy
	   ,@PCustomerId AS CustomerId
	   ,@PTargetProjectId AS ProjectId
	   ,mSegmentId
	   ,RefStdCode
	   ,PSRS.IsDeleted
	FROM ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)
	--INNER JOIN #tmp_SrcSegment PS_Source WITH (NOLOCK)                            
	-- ON PSRS.SegmentId = PS_Source.SegmentId          
	INNER JOIN #tmp_TgtSegment PS_Target WITH (NOLOCK)
		ON PSRS.SegmentId = PS_Target.A_SegmentId
	WHERE PSRS.SectionId = @PSourceSectionId
	AND PSRS.ProjectId = @PSourceProjectId


EXEC usp_MaintainImportProjectProgress NULL
									  ,@PTargetProjectId
									  ,NULL
									  ,@TargetSectionId
									  ,@UserId
									  ,@CustomerId
									  ,@StepInprogress
									  ,@ProgressPer50 --Percent  
									  ,0
									  ,@ImportSource
									  ,@RequestId;


--INSERT ProjectSegmentRequirementTag                      
INSERT INTO ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId, CreateDate, ModifiedDate, ProjectId,
CustomerId, CreatedBy, ModifiedBy, mSegmentRequirementTagId)
	SELECT
		@TargetSectionId AS SectionId
	   ,PSS_Target.SegmentStatusId
	   ,PSRT.RequirementTagId
	   ,PSRT.CreateDate
	   ,PSRT.ModifiedDate
	   ,@PTargetProjectId AS ProjectId
	   ,@PCustomerId AS CustomerId
	   ,PSRT.CreatedBy
	   ,PSRT.ModifiedBy
	   ,PSRT.mSegmentRequirementTagId
	FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)
	--INNER JOIN #SrcSegmentStatusTMP PSS_Source WITH (NOLOCK)                      
	-- ON PSRT.SegmentStatusId = PSS_Source.SegmentStatusId                      
	INNER JOIN #tmp_TgtSegmentStatus PSS_Target WITH (NOLOCK)
		ON PSRT.SegmentStatusId = PSS_Target.A_SegmentStatusId
	WHERE PSRT.ProjectId = @PSourceProjectId
	AND PSRT.SectionId = @PSourceSectionId

--INSERT ProjectSegmentUserTag                      
INSERT INTO ProjectSegmentUserTag (SectionId, SegmentStatusId, UserTagId, CreateDate, ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy)
	SELECT
		@TargetSectionId AS SectionId
	   ,PSS_Target.SegmentStatusId
	   ,PSUT.UserTagId
	   ,PSUT.CreateDate
	   ,PSUT.ModifiedDate
	   ,@PTargetProjectId AS ProjectId
	   ,@PCustomerId AS CustomerId
	   ,PSUT.CreatedBy
	   ,PSUT.ModifiedBy
	FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)
	--INNER JOIN #SrcSegmentStatusTMP PSS_Source WITH (NOLOCK)                      
	-- ON PSUT.SegmentStatusId = PSS_Source.SegmentStatusId                      
	INNER JOIN #tmp_TgtSegmentStatus PSS_Target WITH (NOLOCK)
		ON PSUT.SegmentStatusId = PSS_Target.A_SegmentStatusId
	WHERE PSUT.SectionId = @PSourceSectionId
	AND PSUT.ProjectId = @PSourceProjectId

EXEC usp_MaintainImportProjectProgress NULL
									  ,@PTargetProjectId
									  ,NULL
									  ,@TargetSectionId
									  ,@UserId
									  ,@CustomerId
									  ,2
									  ,@ProgressPer60 --Percent  
									  ,0
									  ,@ImportSource
									  ,@RequestId;


--INSERT Header                      
INSERT INTO Header (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy,
CreatedDate, ModifiedBy, ModifiedDate, TypeId)
	SELECT
		@PTargetProjectId AS ProjectId
	   ,@TargetSectionId AS SectionId
	   ,@PCustomerId AS CustomerId
	   ,Description
	   ,IsLocked
	   ,LockedByFullName
	   ,LockedBy
	   ,ShowFirstPage
	   ,@PUserId AS CreatedBy
	   ,GETUTCDATE() AS CreatedDate
	   ,ModifiedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,TypeId
	FROM Header WITH (NOLOCK)
	WHERE SectionId = @PSourceSectionId
	AND ProjectId = @PSourceProjectId

--INSERT Footer                            
INSERT INTO Footer (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, TypeId)
	SELECT
		@PTargetProjectId AS ProjectId
	   ,@TargetSectionId AS SectionId
	   ,@PCustomerId AS CustomerId
	   ,Description
	   ,IsLocked
	   ,LockedByFullName
	   ,LockedBy
	   ,ShowFirstPage
	   ,@PUserId AS CreatedBy
	   ,GETUTCDATE() AS CreatedDate
	   ,ModifiedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,TypeId
	FROM Footer WITH (NOLOCK)
	WHERE SectionId = @PSourceSectionId
	AND ProjectId = @PSourceProjectId

--INSERT ProjectSegmentGlobalTerm                      
INSERT INTO ProjectSegmentGlobalTerm (SectionId, SegmentId, mSegmentId, UserGlobalTermId, GlobalTermCode, CreatedDate,
CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, IsLocked, LockedByFullName, UserLockedId, IsDeleted)
	SELECT
		@TargetSectionId AS SectionId
	   ,PS_Target.SegmentId
	   ,mSegmentId
	   ,UserGlobalTermId
	   ,GlobalTermCode
	   ,GETUTCDATE() AS CreatedDate
	   ,@PUserId AS CreatedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,@PUserId AS ModifiedBy
	   ,@PCustomerId AS CustomerId
	   ,@PTargetProjectId AS ProjectId
	   ,IsLocked
	   ,LockedByFullName
	   ,UserLockedId
	   ,PSGT.IsDeleted
	FROM ProjectSegmentGlobalTerm PSGT WITH (NOLOCK)
	--INNER JOIN #tmp_SrcSegment PS_Source WITH (NOLOCK)                      
	-- ON PSGT.SegmentId = PS_Source.SegmentId                      
	INNER JOIN #tmp_TgtSegment PS_Target WITH (NOLOCK)
		ON PS_Target.SegmentId = PS_Target.A_SegmentId
	WHERE PSGT.SectionId = @PSourceSectionId
	AND PSGT.ProjectId = @PSourceProjectId

DROP TABLE IF EXISTS #PrjSegGblTerm

SELECT
	* INTO #PrjSegGblTerm
FROM ProjectSegmentGlobalTerm WITH (NOLOCK)
WHERE SectionId = @TargetSectionId
AND ProjectId = @PTargetProjectId

--INSERT ProjectGlobalTerm                      
INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, Name, Value, GlobalTermSource, GlobalTermCode, CreatedDate, CreatedBy,
ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted)
	SELECT
		PGT_Source.mGlobalTermId
	   ,@PTargetProjectId ProjectId
	   ,@PCustomerId AS CustomerId
	   ,PGT_Source.Name
	   ,PGT_Source.value
	   ,PGT_Source.GlobalTermSource
	   ,PGT_Source.GlobalTermCode
	   ,GETUTCDATE() AS CreatedDate
	   ,@PUserId AS CreatedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,@PUserId AS ModifiedBy
	   ,PGT_Source.UserGlobalTermId
	   ,PGT_Source.IsDeleted
	FROM ProjectGlobalTerm PGT_Source WITH (NOLOCK)
	INNER JOIN #PrjSegGblTerm PSGT_Source WITH (NOLOCK)
		ON PGT_Source.GlobalTermCode = PSGT_Source.GlobalTermCode
	WHERE PSGT_Source.SectionId = @PSourceSectionId
	AND PGT_Source.ProjectId = @PSourceProjectId
	AND PSGT_Source.IsDeleted = 0


EXEC usp_MaintainImportProjectProgress NULL
									  ,@PTargetProjectId
									  ,NULL
									  ,@TargetSectionId
									  ,@UserId
									  ,@CustomerId
									  ,@StepInprogress
									  ,@ProgressPer65 --Percent  
									  ,0
									  ,@ImportSource
									  ,@RequestId;



DROP TABLE IF EXISTS #tmp_SrcSegmentLink

SELECT
	* INTO #tmp_SrcSegmentLink
FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
WHERE PSLNK.ProjectId = @PSourceProjectId
AND (PSLNK.SourceSectionCode = @SectionCode
OR PSLNK.TargetSectionCode = @SectionCode)
AND PSLNK.IsDeleted = 0;

DROP TABLE IF EXISTS #tmp_TgtSegmentLink


SELECT
	* INTO #tmp_TgtSegmentLink
FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
WHERE PSLNK.ProjectId = @PTargetProjectId
AND (PSLNK.SourceSectionCode = @SectionCode
OR PSLNK.TargetSectionCode = @SectionCode);

--INSERT ProjectSegmentLink                      
INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode,
SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource, TargetSectionCode,
TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode,
LinkTarget, LinkStatusTypeId, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate,
ProjectId, CustomerId, SegmentLinkSourceTypeId)
	SELECT
		PSLNK_Source.SourceSectionCode AS SourceSectionCode
	   ,PSLNK_Source.SourceSegmentStatusCode AS SourceSegmentStatusCode
	   ,PSLNK_Source.SourceSegmentCode AS SourceSegmentCode
	   ,PSLNK_Source.SourceSegmentChoiceCode AS SourceSegmentChoiceCode
	   ,PSLNK_Source.SourceChoiceOptionCode AS SourceChoiceOptionCode
	   ,PSLNK_Source.LinkSource AS LinkSource
	   ,PSLNK_Source.TargetSectionCode AS TargetSectionCode
	   ,PSLNK_Source.TargetSegmentStatusCode AS TargetSegmentStatusCode
	   ,PSLNK_Source.TargetSegmentCode AS TargetSegmentCode
	   ,PSLNK_Source.TargetSegmentChoiceCode AS TargetSegmentChoiceCode
	   ,PSLNK_Source.TargetChoiceOptionCode AS TargetChoiceOptionCode
	   ,PSLNK_Source.LinkTarget AS LinkTarget
	   ,PSLNK_Source.LinkStatusTypeId AS LinkStatusTypeId
	   ,PSLNK_Source.IsDeleted AS IsDeleted
	   ,GETUTCDATE() AS CreateDate
	   ,@PUserId AS CreatedBy
	   ,@PUserId AS ModifiedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,@PTargetProjectId AS ProjectId
	   ,@PCustomerId AS CustomerId
	   ,PSLNK_Source.SegmentLinkSourceTypeId AS SegmentLinkSourceTypeId
	FROM #tmp_SrcSegmentLink PSLNK_Source WITH (NOLOCK)
	LEFT JOIN #tmp_TgtSegmentLink PSLNK_Target WITH (NOLOCK)
		ON PSLNK_Source.SourceSectionCode = PSLNK_Target.SourceSectionCode
			AND PSLNK_Source.SourceSegmentStatusCode = PSLNK_Target.SourceSegmentStatusCode
			AND PSLNK_Source.SourceSegmentCode = PSLNK_Target.SourceSegmentCode
			AND ISNULL(PSLNK_Source.SourceSegmentChoiceCode, 0) = ISNULL(PSLNK_Target.SourceSegmentChoiceCode, 0)
			AND ISNULL(PSLNK_Source.SourceChoiceOptionCode, 0) = ISNULL(PSLNK_Target.SourceChoiceOptionCode, 0)
			AND PSLNK_Source.LinkSource = PSLNK_Target.LinkSource
			AND PSLNK_Source.TargetSectionCode = PSLNK_Target.TargetSectionCode
			AND PSLNK_Source.TargetSegmentStatusCode = PSLNK_Target.TargetSegmentStatusCode
			AND PSLNK_Source.TargetSegmentCode = PSLNK_Target.TargetSegmentCode
			AND ISNULL(PSLNK_Source.TargetSegmentChoiceCode, 0) = ISNULL(PSLNK_Target.TargetSegmentChoiceCode, 0)
			AND ISNULL(PSLNK_Source.TargetChoiceOptionCode, 0) = ISNULL(PSLNK_Target.TargetChoiceOptionCode, 0)
			AND PSLNK_Source.LinkTarget = PSLNK_Target.LinkTarget
			AND PSLNK_Source.SegmentLinkSourceTypeId = PSLNK_Target.SegmentLinkSourceTypeId
	WHERE PSLNK_Target.SegmentLinkId IS NULL

EXEC usp_MaintainImportProjectProgress NULL
									  ,@PTargetProjectId
									  ,NULL
									  ,@TargetSectionId
									  ,@UserId
									  ,@CustomerId
									  ,@StepInprogress
									  ,@ProgressPer80 --Percent  
									  ,0
									  ,@ImportSource
									  ,@RequestId;

--- INSERT ProjectHyperLink                
INSERT INTO ProjectHyperLink (SectionId, SegmentId, SegmentStatusId, ProjectId,
CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy
, A_HyperLinkId)
	SELECT
		@TargetSectionId
	   ,PSS_Target.SegmentId
	   ,PSS_Target.SegmentStatusId
	   ,@PTargetProjectId
	   ,PSS_Target.CustomerId
	   ,LinkTarget
	   ,LinkText
	   ,LuHyperLinkSourceTypeId
	   ,GETUTCDATE()
	   ,@UserId
	   ,PHL.HyperLinkId
	FROM ProjectHyperLink PHL WITH (NOLOCK)
	INNER JOIN #tmp_TgtSegmentStatus PSS_Target
		ON PHL.SegmentStatusId = PSS_Target.A_SegmentStatusId
	WHERE PHL.SectionId = @PSourceSectionId
	AND PHL.ProjectId = @PSourceProjectId

---UPDATE NEW HyperLinkId in SegmentDescription               

DROP TABLE IF EXISTS #TotalCountSegmentStatusIdTbl

DECLARE @MultipleHyperlinkCount INT = 0;
SELECT
	COUNT(SegmentStatusId) AS TotalCountSegmentStatusId INTO #TotalCountSegmentStatusIdTbl
FROM ProjectHyperLink WITH (NOLOCK)
WHERE SectionId = @TargetSectionId
AND ProjectId = @PTargetProjectId
GROUP BY SegmentStatusId

SELECT
	@MultipleHyperlinkCount = MAX(TotalCountSegmentStatusId)
FROM #TotalCountSegmentStatusIdTbl
WHILE (@MultipleHyperlinkCount > 0)
BEGIN

UPDATE PS
SET PS.SegmentDescription = REPLACE(PS.SegmentDescription, '{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '}', '{HL#' + CAST(PHL.HyperLinkId AS NVARCHAR(20)) + '}')
FROM ProjectHyperLink PHL WITH (NOLOCK)
INNER JOIN ProjectSegment PS WITH (NOLOCK)
	ON PS.SegmentStatusId = PHL.SegmentStatusId
	AND PS.SegmentId = PHL.SegmentId
	AND PS.SectionId = PHL.SectionId
	AND PS.ProjectId = PHL.ProjectId
	AND PS.CustomerId = PHL.CustomerId
WHERE PHL.SectionId = @TargetSectionId
AND PHL.ProjectId = @PTargetProjectId
AND PS.SegmentDescription LIKE '%{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '}%'
AND PS.SegmentDescription LIKE '%{HL#%'

SET @MultipleHyperlinkCount = @MultipleHyperlinkCount - 1;
        
END

EXEC usp_MaintainImportProjectProgress NULL
									  ,@PTargetProjectId
									  ,NULL
									  ,@TargetSectionId
									  ,@UserId
									  ,@CustomerId
									  ,3
									  ,@ProgressPer100 --Percent  
									  ,0
									  ,@ImportSource
									  ,@RequestId;

SET @n = @n + 1;
end

END
