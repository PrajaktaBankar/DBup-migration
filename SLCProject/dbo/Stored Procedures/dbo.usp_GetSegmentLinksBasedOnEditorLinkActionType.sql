
CREATE PROCEDURE [dbo].[usp_GetSegmentLinksBasedOnEditorLinkActionType]
	@EditorLinkActionType INT NULL,    
	@ProjectId INT NULL,     
	@CustomerId INT NULL,     
	@SectionId INT NULL,     
	@SectionCode INT NULL,    
	@SegmentStatusCode BIGINT NULL,     
	@SegmentChoiceCode BIGINT NULL,    
	@SegmentLinkId BIGINT NULL,    
	@IsIncludeRsInSectionChanged BIT NULL,    
	@IsIncludeReInSectionChanged BIT NULL,    
	@IsActivateRsCitationChanged BIT NULL,  
	@SegmentStatusJson NVARCHAR(MAX) NULL = NULL  
AS        
BEGIN  
	DECLARE @PEditorLinkActionType INT = @EditorLinkActionType;  
	DECLARE @PProjectId INT = @ProjectId;  
	DECLARE @PCustomerId INT = @CustomerId;  
	DECLARE @PSectionId INT = @SectionId;  
	DECLARE @PSectionCode INT = @SectionCode  
	DECLARE @PSegmentStatusCode BIGINT = @SegmentStatusCode;  
	DECLARE @PSegmentChoiceCode BIGINT = @SegmentChoiceCode;  
	DECLARE @PSegmentLinkId BIGINT = @SegmentLinkId;  
	DECLARE @PIsIncludeRsInSectionChanged BIT = @IsIncludeRsInSectionChanged;  
	DECLARE @PIsIncludeReInSectionChanged BIT = @IsIncludeReInSectionChanged;  
	DECLARE @PIsActivateRsCitationChanged BIT = @IsActivateRsCitationChanged;  
	DECLARE @PSegmentStatusJson NVARCHAR(MAX) = @SegmentStatusJson;  
	--NOTE    
	--@EditorLinkActionType SegmentChoiceDelete = 8    
	--@EditorLinkActionType SegmentChoiceEdit = 14    
	--@EditorLinkActionType SegmentLinkCreate = 11    
	--@EditorLinkActionType SegmentLinkUpdate = 12    
	--@EditorLinkActionType SegmentLinkDelete = 13    
	--@EditorLinkActionType SegmentDelete = 15    
	--@EditorLinkActionType SegmentStatusToggle = 10    
	--@EditorLinkActionType RebuildSegmentStatus = 16    
	--@EditorLinkActionType RebuildSegmentStatus_SummaryInfo = 17    
	--@EditorLinkActionType RebuildImportedSectionFromProject = 18    
	--@EditorLinkActionType DeleteUserModification = 19  
	--@EditorLinkActionType AcceptNewParagraphUpdate = 20  
  
	--DECLARE @EditorLinkActionType INT = NULL;  
	--DECLARE @ProjectId INT = NULL;    
	--DECLARE @CustomerId INT = NULL;    
	--DECLARE @SectionId INT = NULL;    
	--DECLARE @SectionCode INT = NULL;  
	--DECLARE @SegmentStatusCode INT = NULL;     
	--DECLARE @SegmentChoiceCode INT = NULL;    
	--DECLARE @SegmentLinkId INT = NULL;    
	--DECLARE @IsIncludeRsInSectionChanged BIT = NULL;   
	--DECLARE @IsIncludeReInSectionChanged BIT = NULL;  
	--DECLARE @IsActivateRsCitationChanged BIT = NULL;  
	--DECLARE @SegmentStatusJson NVARCHAR(MAX) = NULL;  
  
	--VARIABLES  
	DECLARE @MasterSourceOfRecord_CNST NVARCHAR(1) = 'M';  
	DECLARE @UserSourceOfRecord_CNST NVARCHAR(1) = 'U';  
	DECLARE @SegmentSource CHAR(1) = NULL;  
  
	--CONSTANTS  
	DECLARE @RS_TAG INT = 22;  
	DECLARE @RT_TAG INT = 23;  
	DECLARE @RE_TAG INT = 24;  
	DECLARE @ST_TAG INT = 25;  
	DECLARE @MinUserSegmentLinkCode BIGINT = 10000001;  
  
	--TABLES  
	--1.  
	DROP TABLE IF EXISTS #SegmentLinksTable  
	CREATE TABLE #SegmentLinksTable (  
		 SegmentLinkId BIGINT NULL  
		,SourceSectionCode INT NULL  
		,SourceSegmentStatusCode BIGINT NULL  
		,SourceSegmentCode BIGINT NULL  
		,SourceSegmentChoiceCode BIGINT NULL  
		,SourceChoiceOptionCode BIGINT NULL  
		,LinkSource NVARCHAR(1) NULL  
		,TargetSectionCode INT NULL  
		,TargetSegmentStatusCode BIGINT NULL  
		,TargetSegmentCode BIGINT NULL  
		,TargetSegmentChoiceCode BIGINT NULL  
		,TargetChoiceOptionCode BIGINT NULL  
		,LinkTarget NVARCHAR(1) NULL  
		,LinkStatusTypeId INT NULL  
		,SegmentLinkCode BIGINT NULL  
		,SegmentLinkSourceTypeId INT NULL  
		,IsSrcLink BIT NULL  
		,IsTgtLink BIT NULL  
		,IsDeleted BIT NULL  
		,SourceOfRecord NVARCHAR(1) NULL  
	);  
  
	--2.  
	DROP TABLE IF EXISTS #SegmentStatusTable  
	CREATE TABLE #SegmentStatusTable (  
		-- ProjectId INT NULL  
		--,CustomerId INT NULL,
		 SegmentStatusId BIGINT NULL  
		,SegmentStatusCode BIGINT NULL  
		,SegmentSource CHAR(1) NULL  
		,SectionId INT NULL  
		,SectionCode INT NULL  
		,SegmentCode BIGINT NULL  
	);  
  
	--3.  
	DROP TABLE IF EXISTS #PresentChoiceOptionsTbl  
	CREATE TABLE #PresentChoiceOptionsTbl (  
		ChoiceOptionCode BIGINT NULL  
	);  
  
	--4.  
	DROP TABLE IF EXISTS #InputSegmentStatusTable  
	CREATE TABLE #InputSegmentStatusTable (  
		SegmentStatusId BIGINT NULL  
	);  
  
	--CALL FOR SEGMENT CHOICE EDIT    
	IF @PEditorLinkActionType = 14  
	BEGIN  
  
	--SET SEGMENT SOURCE    
	SET @SegmentSource = 'U';  
  
	--FIND CHOICE OPTIONS WHICH ARE PRESENT CURRENTLY IN DATABASE    
	INSERT INTO #PresentChoiceOptionsTbl (ChoiceOptionCode)  
		SELECT  
		PCHOP.ChoiceOptionCode  
		FROM ProjectSegmentStatus PSST WITH (NOLOCK)  
		INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)  
		ON PSST.SegmentId = PCH.SegmentId  
		INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)  
		ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId  
		WHERE PSST.SegmentStatusCode = @PSegmentStatusCode  
		AND PSST.SectionId = @PSectionId  
		AND PSST.ProjectId = @PProjectId  
		AND PSST.CustomerId = @PCustomerId
		AND PCH.ProjectId = @PProjectId AND PCH.CustomerId = @PCustomerId AND PCH.SectionId = @PSectionId
		AND PCH.SegmentChoiceCode = @PSegmentChoiceCode

	--FETCH THOSE LINKS WHOSE CHOICE OPTIONS ARE DELETED AND NEED TO DELETE    
	INSERT INTO #SegmentLinksTable (SegmentLinkId, SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,  
	TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId, SegmentLinkCode, SegmentLinkSourceTypeId,  
	IsSrcLink, IsTgtLink, SourceOfRecord)  
		SELECT  
		 PSLNK.SegmentLinkId  
		,PSLNK.SourceSectionCode  
		,PSLNK.SourceSegmentStatusCode  
		,PSLNK.SourceSegmentCode
		,ISNULL(PSLNK.SourceSegmentChoiceCode, 0)
		,ISNULL(PSLNK.SourceChoiceOptionCode, 0)
		,PSLNK.LinkSource  
		,PSLNK.TargetSectionCode  
		,PSLNK.TargetSegmentStatusCode  
		,PSLNK.TargetSegmentCode  
		,ISNULL(PSLNK.TargetSegmentChoiceCode, 0)   
		,ISNULL(PSLNK.TargetChoiceOptionCode, 0)  
		,PSLNK.LinkTarget  
		,PSLNK.LinkStatusTypeId  
		,ISNULL(PSLNK.SegmentLinkCode, 0) 
		,PSLNK.SegmentLinkSourceTypeId  
		,CAST(0 AS BIT) AS IsSrcLink  
		,CAST(1 AS BIT) AS IsTgtLink  
		,@UserSourceOfRecord_CNST AS SourceOfRecord  
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)  
		WHERE PSLNK.ProjectId = @PProjectId  
		AND PSLNK.CustomerId = @PCustomerId  
		AND PSLNK.SourceSegmentStatusCode = @PSegmentStatusCode  
		AND PSLNK.SourceSectionCode = @PSectionCode  
		AND PSLNK.SourceSegmentChoiceCode = @PSegmentChoiceCode  
		AND PSLNK.SourceChoiceOptionCode NOT IN (SELECT  
		ChoiceOptionCode  
		FROM #PresentChoiceOptionsTbl)  
		AND PSLNK.LinkSource = @SegmentSource  
		UNION
		SELECT  
		 PSLNK.SegmentLinkId  
		,PSLNK.SourceSectionCode  
		,PSLNK.SourceSegmentStatusCode  
		,PSLNK.SourceSegmentCode  
		,ISNULL(PSLNK.SourceSegmentChoiceCode, 0)  
		,ISNULL(PSLNK.SourceChoiceOptionCode, 0) 
		,PSLNK.LinkSource  
		,PSLNK.TargetSectionCode  
		,PSLNK.TargetSegmentStatusCode  
		,PSLNK.TargetSegmentCode  
		,ISNULL(PSLNK.TargetSegmentChoiceCode, 0)  
		,ISNULL(PSLNK.TargetChoiceOptionCode, 0)  
		,PSLNK.LinkTarget  
		,PSLNK.LinkStatusTypeId  
		,ISNULL(PSLNK.SegmentLinkCode, 0)  
		,PSLNK.SegmentLinkSourceTypeId  
		,CAST(1 AS BIT) AS IsSrcLink  
		,CAST(0 AS BIT) AS IsTgtLink  
		,@UserSourceOfRecord_CNST AS SourceOfRecord  
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)  
		WHERE PSLNK.ProjectId = @PProjectId  
		AND PSLNK.CustomerId = @PCustomerId  
		AND PSLNK.TargetSegmentStatusCode = @PSegmentStatusCode  
		AND PSLNK.TargetSectionCode = @PSectionCode  
		AND PSLNK.TargetSegmentChoiceCode = @PSegmentChoiceCode  
		AND PSLNK.TargetChoiceOptionCode NOT IN (SELECT  
		ChoiceOptionCode  
		FROM #PresentChoiceOptionsTbl)  
		AND PSLNK.LinkTarget = @SegmentSource  
	END  
	ELSE  
  
	--CALL FOR SEGMENT LINK CREATE,UPDATE OR DELETE    
	IF @PEditorLinkActionType IN (11, 12, 13)  
	BEGIN  
	INSERT INTO #SegmentLinksTable (SegmentLinkId, SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,  
	TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId, SegmentLinkCode, SegmentLinkSourceTypeId,  
	IsSrcLink, IsTgtLink, SourceOfRecord)  
		SELECT  
		PSLNK.SegmentLinkId  
		,PSLNK.SourceSectionCode  
		,PSLNK.SourceSegmentStatusCode  
		,PSLNK.SourceSegmentCode  
		,ISNULL(PSLNK.SourceSegmentChoiceCode, 0) 
		,ISNULL(PSLNK.SourceChoiceOptionCode, 0) 
		,PSLNK.LinkSource  
		,PSLNK.TargetSectionCode  
		,PSLNK.TargetSegmentStatusCode  
		,PSLNK.TargetSegmentCode  
		,ISNULL(PSLNK.TargetSegmentChoiceCode, 0)  
		,ISNULL(PSLNK.TargetChoiceOptionCode, 0)  
		,PSLNK.LinkTarget  
		,PSLNK.LinkStatusTypeId  
		,ISNULL(PSLNK.SegmentLinkCode, 0) 
		,PSLNK.SegmentLinkSourceTypeId  
		,CAST(0 AS BIT) AS IsSrcLink  
		,CAST(0 AS BIT) AS IsTgtLink  
		,@UserSourceOfRecord_CNST AS SourceOfRecord  
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)  
		WHERE PSLNK.SegmentLinkId = @PSegmentLinkId;  
	END  
  
	--CALL FOR SEGMENT CHOICE DELETE    
	ELSE  
	IF @PEditorLinkActionType = 8  
	BEGIN  
  
	--SET SEGMENT SOURCE    
	SET @SegmentSource = 'U';  
  
	INSERT INTO #SegmentLinksTable (SegmentLinkId, SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,  
	TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId, SegmentLinkCode, SegmentLinkSourceTypeId,  
	IsSrcLink, IsTgtLink, SourceOfRecord)  
		SELECT  
		 PSLNK.SegmentLinkId  
		,PSLNK.SourceSectionCode  
		,PSLNK.SourceSegmentStatusCode  
		,PSLNK.SourceSegmentCode  
		,ISNULL(PSLNK.SourceSegmentChoiceCode, 0)  
		,ISNULL(PSLNK.SourceChoiceOptionCode, 0)  
		,PSLNK.LinkSource  
		,PSLNK.TargetSectionCode  
		,PSLNK.TargetSegmentStatusCode  
		,PSLNK.TargetSegmentCode  
		,ISNULL(PSLNK.TargetSegmentChoiceCode, 0)  
		,ISNULL(PSLNK.TargetChoiceOptionCode, 0) 
		,PSLNK.LinkTarget  
		,PSLNK.LinkStatusTypeId  
		,ISNULL(PSLNK.SegmentLinkCode, 0) 
		,PSLNK.SegmentLinkSourceTypeId  
		,CAST(0 AS BIT) AS IsSrcLink  
		,CAST(1 AS BIT) AS IsTgtLink  
		,@UserSourceOfRecord_CNST AS SourceOfRecord  
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)  
		WHERE PSLNK.ProjectId = @PProjectId  
		AND PSLNK.CustomerId = @PCustomerId  
		AND PSLNK.SourceSegmentStatusCode = @PSegmentStatusCode  
		AND PSLNK.SourceSectionCode = @PSectionCode  
		AND PSLNK.SourceSegmentChoiceCode = @PSegmentChoiceCode  
		AND PSLNK.LinkSource = @SegmentSource  
		UNION  
		SELECT   
		 PSLNK.SegmentLinkId  
		,PSLNK.SourceSectionCode  
		,PSLNK.SourceSegmentStatusCode  
		,PSLNK.SourceSegmentCode  
		,ISNULL(PSLNK.SourceSegmentChoiceCode, 0)  
		,ISNULL(PSLNK.SourceChoiceOptionCode, 0) 
		,PSLNK.LinkSource  
		,PSLNK.TargetSectionCode  
		,PSLNK.TargetSegmentStatusCode  
		,PSLNK.TargetSegmentCode  
		,ISNULL(PSLNK.TargetSegmentChoiceCode, 0)
		,ISNULL(PSLNK.TargetChoiceOptionCode, 0)
		,PSLNK.LinkTarget  
		,PSLNK.LinkStatusTypeId  
		,ISNULL(PSLNK.SegmentLinkCode, 0)
		,PSLNK.SegmentLinkSourceTypeId  
		,CAST(1 AS BIT) AS IsSrcLink  
		,CAST(0 AS BIT) AS IsTgtLink  
		,@UserSourceOfRecord_CNST AS SourceOfRecord  
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)  
		WHERE PSLNK.ProjectId = @PProjectId  
		AND PSLNK.CustomerId = @PCustomerId  
		AND PSLNK.TargetSegmentStatusCode = @PSegmentStatusCode  
		AND PSLNK.TargetSectionCode = @PSectionCode  
		AND PSLNK.TargetSegmentChoiceCode = @PSegmentChoiceCode  
		AND PSLNK.LinkTarget = @SegmentSource  
	END  
  
	--CALL FOR SEGMENT DELETE    
	ELSE  
	IF @PEditorLinkActionType = 15  
	BEGIN  
  
	--SET SEGMENT SOURCE    
	SET @SegmentSource = 'U';  
  
	INSERT INTO #SegmentLinksTable (SegmentLinkId, SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,  
	TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId, SegmentLinkCode, SegmentLinkSourceTypeId,  
	IsSrcLink, IsTgtLink, SourceOfRecord)
		SELECT  
		 PSLNK.SegmentLinkId  
		,PSLNK.SourceSectionCode  
		,PSLNK.SourceSegmentStatusCode  
		,PSLNK.SourceSegmentCode  
		,ISNULL(PSLNK.SourceSegmentChoiceCode, 0) 
		,ISNULL(PSLNK.SourceChoiceOptionCode, 0)  
		,PSLNK.LinkSource  
		,PSLNK.TargetSectionCode  
		,PSLNK.TargetSegmentStatusCode  
		,PSLNK.TargetSegmentCode  
		,ISNULL(PSLNK.TargetSegmentChoiceCode, 0)  
		,ISNULL(PSLNK.TargetChoiceOptionCode, 0)  
		,PSLNK.LinkTarget  
		,PSLNK.LinkStatusTypeId  
		,ISNULL(PSLNK.SegmentLinkCode, 0) 
		,PSLNK.SegmentLinkSourceTypeId  
		,CAST(0 AS BIT) AS IsSrcLink  
		,CAST(1 AS BIT) AS IsTgtLink  
		,@UserSourceOfRecord_CNST AS SourceOfRecord  
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)  
		WHERE PSLNK.ProjectId = @PProjectId  
		AND PSLNK.CustomerId = @PCustomerId  
		AND PSLNK.SourceSegmentStatusCode = @PSegmentStatusCode  
		AND PSLNK.SourceSectionCode = @PSectionCode  
		AND PSLNK.LinkSource = @SegmentSource  
		UNION  
		SELECT
		 PSLNK.SegmentLinkId  
		,PSLNK.SourceSectionCode  
		,PSLNK.SourceSegmentStatusCode  
		,PSLNK.SourceSegmentCode  
		,ISNULL(PSLNK.SourceSegmentChoiceCode, 0)  
		,ISNULL(PSLNK.SourceChoiceOptionCode, 0) 
		,PSLNK.LinkSource  
		,PSLNK.TargetSectionCode  
		,PSLNK.TargetSegmentStatusCode  
		,PSLNK.TargetSegmentCode  
		,ISNULL(PSLNK.TargetSegmentChoiceCode, 0)
		,ISNULL(PSLNK.TargetChoiceOptionCode, 0)
		,PSLNK.LinkTarget  
		,PSLNK.LinkStatusTypeId  
		,ISNULL(PSLNK.SegmentLinkCode, 0)
		,PSLNK.SegmentLinkSourceTypeId  
		,CAST(1 AS BIT) AS IsSrcLink  
		,CAST(0 AS BIT) AS IsTgtLink  
		,@UserSourceOfRecord_CNST AS SourceOfRecord  
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)  
		WHERE PSLNK.ProjectId = @PProjectId  
		AND PSLNK.CustomerId = @PCustomerId  
		AND PSLNK.TargetSegmentStatusCode = @PSegmentStatusCode  
		AND PSLNK.TargetSectionCode = @PSectionCode  
		AND PSLNK.LinkTarget = @SegmentSource  
	END  
  
	--CALL FOR SEGMENT TOGGLE    
	ELSE  
	IF @PEditorLinkActionType = 10  
		OR @PEditorLinkActionType = 16  
	BEGIN  
  
	INSERT INTO #SegmentLinksTable (SegmentLinkId, SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,  
	TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId, SegmentLinkCode, SegmentLinkSourceTypeId,  
	IsSrcLink, IsTgtLink, SourceOfRecord, IsDeleted)  
		SELECT
		 PSLNK.SegmentLinkId  
		,PSLNK.SourceSectionCode  
		,PSLNK.SourceSegmentStatusCode  
		,PSLNK.SourceSegmentCode  
		,ISNULL(PSLNK.SourceSegmentChoiceCode, 0)
		,ISNULL(PSLNK.SourceChoiceOptionCode, 0) 
		,PSLNK.LinkSource  
		,PSLNK.TargetSectionCode  
		,PSLNK.TargetSegmentStatusCode  
		,PSLNK.TargetSegmentCode  
		,ISNULL(PSLNK.TargetSegmentChoiceCode, 0)  
		,ISNULL(PSLNK.TargetChoiceOptionCode, 0)  
		,PSLNK.LinkTarget  
		,PSLNK.LinkStatusTypeId  
		,ISNULL(PSLNK.SegmentLinkCode, 0)  
		,PSLNK.SegmentLinkSourceTypeId  
		,CAST(0 AS BIT) AS IsSrcLink  
		,CAST(1 AS BIT) AS IsTgtLink  
		,@UserSourceOfRecord_CNST AS SourceOfRecord  
		,PSLNK.IsDeleted  
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)  
		WHERE PSLNK.ProjectId = @PProjectId  
		AND PSLNK.CustomerId = @PCustomerId  
		AND PSLNK.SourceSegmentStatusCode = @PSegmentStatusCode  
		AND PSLNK.SourceSectionCode = @PSectionCode  
		UNION  
		SELECT 
		 PSLNK.SegmentLinkId  
		,PSLNK.SourceSectionCode  
		,PSLNK.SourceSegmentStatusCode  
		,PSLNK.SourceSegmentCode  
		,ISNULL(PSLNK.SourceSegmentChoiceCode, 0)  
		,ISNULL(PSLNK.SourceChoiceOptionCode, 0) 
		,PSLNK.LinkSource  
		,PSLNK.TargetSectionCode  
		,PSLNK.TargetSegmentStatusCode  
		,PSLNK.TargetSegmentCode  
		,ISNULL(PSLNK.TargetSegmentChoiceCode, 0)  
		,ISNULL(PSLNK.TargetChoiceOptionCode, 0)  
		,PSLNK.LinkTarget  
		,PSLNK.LinkStatusTypeId  
		,ISNULL(PSLNK.SegmentLinkCode, 0)  
		,PSLNK.SegmentLinkSourceTypeId  
		,CAST(1 AS BIT) AS IsSrcLink  
		,CAST(0 AS BIT) AS IsTgtLink  
		,@UserSourceOfRecord_CNST AS SourceOfRecord  
		,PSLNK.IsDeleted  
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)  
		WHERE PSLNK.ProjectId = @PProjectId  
		AND PSLNK.CustomerId = @PCustomerId  
		AND PSLNK.TargetSegmentStatusCode = @PSegmentStatusCode  
		AND PSLNK.TargetSectionCode = @PSectionCode  
		UNION  
		SELECT
		 MSLNK.SegmentLinkId  
		,MSLNK.SourceSectionCode  
		,MSLNK.SourceSegmentStatusCode  
		,MSLNK.SourceSegmentCode  
		,ISNULL(MSLNK.SourceSegmentChoiceCode, 0) 
		,ISNULL(MSLNK.SourceChoiceOptionCode, 0)  
		,MSLNK.LinkSource  
		,MSLNK.TargetSectionCode  
		,MSLNK.TargetSegmentStatusCode  
		,MSLNK.TargetSegmentCode  
		,ISNULL(MSLNK.TargetSegmentChoiceCode, 0) 
		,ISNULL(MSLNK.TargetChoiceOptionCode, 0)  
		,MSLNK.LinkTarget  
		,MSLNK.LinkStatusTypeId  
		,ISNULL(MSLNK.SegmentLinkCode, 0)  
		,MSLNK.SegmentLinkSourceTypeId  
		,CAST(0 AS BIT) AS IsSrcLink  
		,CAST(1 AS BIT) AS IsTgtLink  
		,@MasterSourceOfRecord_CNST AS SourceOfRecord  
		,MSLNK.IsDeleted  
		FROM SLCMaster..SegmentLink MSLNK WITH (NOLOCK)  
		WHERE MSLNK.SourceSegmentStatusCode = @PSegmentStatusCode  
		AND MSLNK.SourceSectionCode = @PSectionCode  
		UNION
		SELECT  
		 MSLNK.SegmentLinkId  
		,MSLNK.SourceSectionCode  
		,MSLNK.SourceSegmentStatusCode  
		,MSLNK.SourceSegmentCode  
		,ISNULL(MSLNK.SourceSegmentChoiceCode, 0)  
		,ISNULL(MSLNK.SourceChoiceOptionCode, 0) 
		,MSLNK.LinkSource  
		,MSLNK.TargetSectionCode  
		,MSLNK.TargetSegmentStatusCode  
		,MSLNK.TargetSegmentCode  
		,ISNULL(MSLNK.TargetSegmentChoiceCode, 0)  
		,ISNULL(MSLNK.TargetChoiceOptionCode, 0)  
		,MSLNK.LinkTarget  
		,MSLNK.LinkStatusTypeId  
		,ISNULL(MSLNK.SegmentLinkCode, 0)  
		,MSLNK.SegmentLinkSourceTypeId  
		,CAST(1 AS BIT) AS IsSrcLink  
		,CAST(0 AS BIT) AS IsTgtLink  
		,@MasterSourceOfRecord_CNST AS SourceOfRecord  
		,MSLNK.IsDeleted  
		FROM SLCMaster..SegmentLink MSLNK WITH (NOLOCK)  
		WHERE MSLNK.TargetSegmentStatusCode = @PSegmentStatusCode  
		AND MSLNK.TargetSectionCode = @PSectionCode  
	END  
  
	--CALL FOR RebuildSegmentStatus_SummaryInfo    
	ELSE  
	IF @PEditorLinkActionType = 17  
	BEGIN  
	INSERT INTO #SegmentStatusTable (SegmentStatusId, SegmentStatusCode, SegmentSource, SectionId, SectionCode, SegmentCode)  
		SELECT
		 ISNULL(PSST.SegmentStatusId, 0)  
		,ISNULL(PSST.SegmentStatusCode, 0)  
		,ISNULL(PSST.SegmentOrigin, '') AS SegmentSource  
		,ISNULL(PSST.SectionId, 0)  
		,ISNULL(PS.SectionCode, 0)  
		,0 AS SegmentCode
		FROM ProjectSegmentStatus PSST WITH (NOLOCK)  
		INNER JOIN ProjectSection PS WITH (NOLOCK)  
		ON PSST.SectionId = PS.SectionId  
		INNER JOIN ProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
		ON PSST.SegmentStatusId = PSRT.SegmentStatusId  
		WHERE PSST.ProjectId = @PProjectId  
		AND PSST.CustomerId = @PCustomerId  
		AND (PSST.IsDeleted IS NULL  
		OR PSST.IsDeleted = 0)  
		AND ((@PIsIncludeRsInSectionChanged = 1  
		AND PSRT.RequirementTagId = @RT_TAG)  
		OR (@PIsIncludeReInSectionChanged = 1  
		AND PSRT.RequirementTagId = @ST_TAG))  
	END  
  
	--CALL FOR RebuildImportedSectionFromProject    
	ELSE  
	IF @PEditorLinkActionType = 18  
	BEGIN  
  
	SELECT  
		@PSectionCode = SectionCode  
	FROM ProjectSection  WITH(NOLOCK)
	WHERE   SectionId = @PSectionId
	--AND ProjectId = @PProjectId;  
  
	INSERT INTO #SegmentLinksTable (SegmentLinkId, SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,  
	TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId, SegmentLinkCode, SegmentLinkSourceTypeId,  
	IsSrcLink, IsTgtLink, SourceOfRecord, IsDeleted)  
		SELECT DISTINCT
		 PSLNK.SegmentLinkId  
		,PSLNK.SourceSectionCode  
		,PSLNK.SourceSegmentStatusCode  
		,PSLNK.SourceSegmentCode  
		,ISNULL(PSLNK.SourceSegmentChoiceCode, 0)  
		,ISNULL(PSLNK.SourceChoiceOptionCode, 0)  
		,PSLNK.LinkSource  
		,PSLNK.TargetSectionCode  
		,PSLNK.TargetSegmentStatusCode  
		,PSLNK.TargetSegmentCode  
		,ISNULL(PSLNK.TargetSegmentChoiceCode, 0)  
		,ISNULL(PSLNK.TargetChoiceOptionCode, 0)  
		,PSLNK.LinkTarget  
		,PSLNK.LinkStatusTypeId  
		,ISNULL(PSLNK.SegmentLinkCode, 0)  
		,PSLNK.SegmentLinkSourceTypeId  
		,CAST(0 AS BIT) AS IsSrcLink  
		,CAST(0 AS BIT) AS IsTgtLink  
		,@UserSourceOfRecord_CNST AS SourceOfRecord  
		,PSLNK.IsDeleted  
		FROM ProjectSegmentLink PSLNK  WITH (NOLOCK)  
		WHERE PSLNK.ProjectId = @PProjectId  
		AND PSLNK.CustomerId = @PCustomerId  
		AND (PSLNK.SourceSectionCode = @PSectionCode  
		OR PSLNK.TargetSectionCode = @PSectionCode)  
		AND ((PSLNK.SegmentLinkCode >= @MinUserSegmentLinkCode)  
		OR (PSLNK.SourceSectionCode != PSLNK.TargetSectionCode))  
	END  
  
	--CALL FOR DELETE USER MODIFICATION   
	ELSE  
	IF @PEditorLinkActionType = 19  
	BEGIN  
  
	INSERT INTO #SegmentLinksTable (SegmentLinkId, SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,  
	TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId, SegmentLinkCode, SegmentLinkSourceTypeId,  
	IsSrcLink, IsTgtLink, SourceOfRecord, IsDeleted)  
		SELECT  
		 PSLNK.SegmentLinkId  
		,PSLNK.SourceSectionCode  
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
		,PSLNK.SegmentLinkCode  
		,PSLNK.SegmentLinkSourceTypeId  
		,CAST(0 AS BIT) AS IsSrcLink  
		,CAST(1 AS BIT) AS IsTgtLink  
		,@UserSourceOfRecord_CNST AS SourceOfRecord  
		,PSLNK.IsDeleted  
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)  
		WHERE PSLNK.ProjectId = @PProjectId  
		AND PSLNK.CustomerId = @PCustomerId  
		AND PSLNK.SourceSegmentStatusCode = @PSegmentStatusCode  
		AND PSLNK.SourceSectionCode = @PSectionCode  
		UNION  
		SELECT  
		 PSLNK.SegmentLinkId  
		,PSLNK.SourceSectionCode  
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
		,PSLNK.SegmentLinkCode  
		,PSLNK.SegmentLinkSourceTypeId  
		,CAST(1 AS BIT) AS IsSrcLink  
		,CAST(0 AS BIT) AS IsTgtLink  
		,@UserSourceOfRecord_CNST AS SourceOfRecord  
		,PSLNK.IsDeleted  
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)  
		WHERE PSLNK.ProjectId = @PProjectId  
		AND PSLNK.CustomerId = @PCustomerId  
		AND PSLNK.TargetSegmentStatusCode = @PSegmentStatusCode  
		AND PSLNK.TargetSectionCode = @PSectionCode  
	END  
  
	--CALL FOR ACCEPT NEW PARAGRAPH UPDATES  
	ELSE  
	IF @PEditorLinkActionType = 20  
	BEGIN  
  
	IF @PSegmentStatusJson != ''  
	BEGIN  
	INSERT INTO #InputSegmentStatusTable (SegmentStatusId)  
		SELECT  
		SegmentStatusId  
		FROM OPENJSON(@PSegmentStatusJson)  
		WITH (  
		SegmentStatusId BIGINT '$.SegmentStatusId'  
		);  
	END  
  
	INSERT INTO #SegmentStatusTable (SegmentStatusId, SegmentStatusCode, SegmentSource, SectionId, SectionCode, SegmentCode)
		SELECT
		 PSST.SegmentStatusId  
		,PSST.SegmentStatusCode  
		,PSST.SegmentOrigin AS SegmentSource  
		,PSST.SectionId  
		,PS.SectionCode  
		,0 AS SegmentCode  
		FROM ProjectSegmentStatus PSST WITH (NOLOCK)  
		INNER JOIN ProjectSection PS WITH (NOLOCK)  
		ON PSST.SectionId = PS.SectionId  
		INNER JOIN #InputSegmentStatusTable INPSST WITH (NOLOCK)  
		ON PSST.SegmentStatusId = INPSST.SegmentStatusId  
		WHERE PSST.ProjectId = @PProjectId  
		AND PSST.CustomerId = @PCustomerId  
		ORDER BY PSST.IndentLevel ASC  
	END  
  
	DELETE FROM #SegmentLinksTable  
	WHERE IsDeleted IS NOT NULL  
		AND IsDeleted = 1;  
  
	--DELETE ALREADY MAPPED MASTER RECORDS INTO PROJECT WHICH ARE ALSO FETCHED FROM MASTER DB    
	DELETE MSLNK  
		FROM #SegmentLinksTable MSLNK  
		INNER JOIN #SegmentLinksTable USLNK  
		ON MSLNK.SegmentLinkCode = USLNK.SegmentLinkCode  
		AND USLNK.SourceOfRecord = @UserSourceOfRecord_CNST  
	WHERE MSLNK.SourceOfRecord = @MasterSourceOfRecord_CNST
  
	--SELECT FINAL DATA    
	SELECT * FROM #SegmentLinksTable;  
	SELECT * FROM #SegmentStatusTable;
  
END
GO


