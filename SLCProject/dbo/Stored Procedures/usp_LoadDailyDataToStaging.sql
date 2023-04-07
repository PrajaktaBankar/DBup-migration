CREATE PROCEDURE [dbo].[usp_LoadDailyDataToStaging]
AS  
BEGIN
	BEGIN TRY
	--SET NO-COUNT ON
	SET NOCOUNT ON;

	--TRUNCATE OLD DATA 
	-- Do this when loading data to BPMCore database server - because this might take some time over the network
	--EXEC [VM-QA-DBSLC].[BPMCore_Staging_SLC].sys.sp_executesql  N'Truncate table [dbo].[Stg_Project_Cloud];'
	--EXEC [VM-QA-DBSLC].[BPMCore_Staging_SLC].sys.sp_executesql  N'Truncate table [dbo].[Stg_ProjectSectionsCloud];'
	--EXEC [VM-QA-DBSLC].[BPMCore_Staging_SLC].sys.sp_executesql  N'Truncate table [dbo].[Stg_ProjectSegments_Cloud];'
	
	--load data to STG_PROJECT_CLOUD
	TRUNCATE TABLE BPMCORE_Staging_SLC..Stg_Project_Cloud

	EXEC USP_LOADDAILYDATATOPROJECT_CLOUD;

	 --load data to stg_ProjectSectionsCloud
	TRUNCATE TABLE BPMCORE_Staging_SLC..STG_ProjectSectionsCloud
	EXEC [usp_loaddailydatatoSProjectSections_Cloud]

	TRUNCATE TABLE BPMCore_Staging_SLC..Stg_ProjectSegments_Cloud

	if object_id('tempdb..#SegmentsTable') is not null
	drop table #SegmentsTable

	create TABLE #SegmentsTable  (
		ProjectId INT NULL
	   ,GlobalProjectID nvarchar(100) NULL
	   ,CustomerId INT NULL
	   ,SegmentStatusId BIGINT NULL
	   ,ParentSegmentStatusId BIGINT NULL
	   ,SegmentDescription NVARCHAR(MAX) NULL
	   ,SegmentSource NVARCHAR(MAX) NULL
	   ,SegmentOrigin NVARCHAR(MAX) NULL
	   ,mSegmentId INT NULL
	   ,mSegmentStatusId INT NULL
	   ,SegmentId BIGINT NULL
	   ,IndentLevel INT NULL
	   ,SequenceNumber INT NULL
	   ,SectionId INT NULL
	   ,mSectionId INT NULL
	   ,RequirementTagId INT NULL
	   ,RequirementTag nvarchar(10) NULL
	);

	CREATE CLUSTERED INDEX [IDX_SegmentsTable_SegmentStatusID] ON #SegmentsTable
	(
		[SegmentStatusId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]


	
	/*
	Gather paragraphs that are ML or PP tagged or start with Manufacturer word and are active and all of their parents recursively.
	*/
	
	;with cte_segments (ProjectID
						, CustomerId
						, SectionID
						, SegmentStatusId
						, mSegmentStatusId
						, ParentSegmentStatusId
						, SegmentDescription
						, SegmentSource
						, mSegmentId
						, SegmentId
						, SegmentOrigin
						, IndentLevel
						, SequenceNumber
						, mSectionId
						, RequirementTagId
						, GlobalProjectId)
	as
	(
			SELECT 
				 PSSTV.ProjectId
				,P.CustomerId
				,PSSTV.SectionID
				,PSSTV.SegmentStatusId
				,PSSTV.mSegmentStatusId
				,PSSTV.ParentSegmentStatusId
				,PSSTV.SegmentDescription
				,PSSTV.SegmentSource
				,PSSTV.mSegmentId
				,PSSTV.SegmentId
				,PSSTV.SegmentOrigin
				,PSSTV.IndentLevel
				,PSSTV.SequenceNumber
				,PSSTV.mSectionId
				,PSRT.RequirementTagId
				,P.GlobalProjectId				
			FROM SLCPROJECT..ProjectSegmentStatusView PSSTV (NOLOCK)
				inner JOIN SLCPROJECT..ProjectSegmentRequirementTag PSRT  (NOLOCK)
					ON PSSTV.SegmentStatusId=PSRT.SegmentStatusId 
				inner JOIN SLCPROJECT..LuProjectRequirementTag LPRT  (NOLOCK)
					ON PSRT.RequirementTagId = LPRT.RequirementTagId 
				INNER JOIN BPMCore_Staging_SLC..Stg_Project_Cloud P (NOLOCK)				
					ON P.LocalProjectId = PSSTV.ProjectId
				INNER JOIN BPMCore_Staging_SLC..Stg_ProjectSectionsCloud PS
					ON PS.LocalProjectId=PSSTV.ProjectId and PS.DocId=PSSTV.mSectionId
			WHERE PSSTV.IsSegmentStatusActive = 1
			AND (LPRT.TAGTYPE IN ('ML', 'PP') --ML,PP TAGGED SEGMENTS
					OR PSSTV.SegmentDescription LIKE 'Manufacturer%') 

			union all

			SELECT 
				 PSSTV.ProjectId
				,P.CustomerId
				,PSSTV.SectionId
				,PSSTV.SegmentStatusId
				,PSSTV.mSegmentStatusId
				,PSSTV.ParentSegmentStatusId
				,PSSTV.SegmentDescription
				,PSSTV.SegmentSource
				,PSSTV.mSegmentId
				,PSSTV.SegmentId
				,PSSTV.SegmentOrigin
				,PSSTV.IndentLevel
				,PSSTV.SequenceNumber
				,PSSTV.mSectionId
				, NULL --PSRT.RequirementTagId -- Parent paragraphs may not have tags
				,P.GlobalProjectId			
			FROM SLCPROJECT..ProjectSegmentStatusView PSSTV (NOLOCK)
				INNER JOIN cte_segments S on S.CustomerId=PSSTV.CustomerId 
														and s.ProjectID=PSSTV.ProjectId
														and S.SectionId=PSSTV.SectionId 
														and s.ParentSegmentStatusId=PSSTV.SegmentStatusId
				INNER JOIN BPMCore_Staging_SLC..Stg_Project_Cloud P (NOLOCK)				
					ON P.LocalProjectId = S.ProjectId
				INNER JOIN BPMCore_Staging_SLC..Stg_ProjectSectionsCloud PS
					ON PS.LocalProjectId=S.ProjectId 
						and PS.SectionId=S.SectionId

	)


	INSERT INTO #SegmentsTable (ProjectId
								, CustomerId
								, SectionId
								, SegmentStatusId
								, mSegmentStatusId
								, ParentSegmentStatusId
								, SegmentDescription
								, SegmentSource
								, mSegmentId
								, SegmentId
								, SegmentOrigin
								, IndentLevel
								, SequenceNumber
								, mSectionId
								, RequirementTagId
								, GlobalProjectID
								, RequirementTag)

	SELECT distinct PSSTV.ProjectId
		, PSSTV.CustomerId
		, PSSTV.SectionID
		, PSSTV.SegmentStatusId
		, mSegmentStatusId
		, ParentSegmentStatusId
		, SegmentDescription
	    , SegmentSource
		, mSegmentId
		, SegmentId
		, SegmentOrigin
		, IndentLevel
		, SequenceNumber
		, mSectionId
		, PSSTV.RequirementTagId
		, GlobalProjectID
		, '' 
	FROM cte_segments	PSSTV

	Update t set t.RequirementTag = LPRT.TagType
	from #SegmentsTable t
	INNER JOIN SLCPROJECT..ProjectSegmentRequirementTag PSRT  (NOLOCK)
					ON t.SegmentStatusId=PSRT.SegmentStatusId 
	INNER JOIN SLCPROJECT..LuProjectRequirementTag LPRT  (NOLOCK)
					ON PSRT.RequirementTagId = LPRT.RequirementTagId 

	UPDATE t 
		SET t.segmentDescription=SLCProject.dbo.fnGetSegmentDescriptionTextForChoice(t.SegmentStatusId)
		FROM #SegmentsTable t	 where CHARINDEX('{CH#', segmentdescription)>0
	
	--Update SegmentOrigins to Master/User for RF#

	UPDATE t 
		SET t.segmentDescription=SLCProject.dbo.fnGetSegmentDescriptionTextForRSAndGT_ForDataLoad(0,t.segmentDescription,t.ProjectId)
		FROM #SegmentsTable t	 where charindex('{RS#', segmentdescription)>0

	UPDATE t 
		SET t.segmentDescription=SLCProject.dbo.fnGetSegmentDescriptionTextForRSAndGT_ForDataLoad(0,t.segmentDescription,t.ProjectId)
		FROM #SegmentsTable t	 where charindex('{GT#', segmentdescription)>0

	 --Insert data into Stg_ProjectSegments_Cloud ---Project
	INSERT INTO Stg_ProjectSegments_Cloud (LocalProjectId,GlobalProjectId,CompanyId,SegmentDescription,DocId,
				Tag	,Hierarchy ,SequenceNum ,Origin ,StatusID, SegmentID ,ParentID, SectionId)
		SELECT 
		 ProjectId AS LocalProjectId
		,GlobalProjectID AS GlobalProjectId
		,CustomerId AS CompanyId
		,SegmentDescription AS SegmentDescription
		,mSectionId AS DocId
		,RequirementTag AS Tag
		,IndentLevel AS Hierarchy
		,SequenceNumber AS SequenceNum
		,SegmentOrigin AS Origin
		,SegmentStatusId AS StatusID
		,SegmentId AS SegmentID -- For User edited paragraphs use SegmentID
		,ParentSegmentStatusId AS ParentID
		, SectionID
		 FROM #SegmentsTable S WHERE S.SegmentOrigin='U'

	--Insert data into Stg_ProjectSegments_Cloud ---Master
	INSERT INTO Stg_ProjectSegments_Cloud (LocalProjectId,GlobalProjectId,CompanyId,SegmentDescription,DocId,Tag
		,Hierarchy ,SequenceNum	,Origin,StatusID, SegmentID,ParentID,SectionID)
		 SELECT 
		 ProjectId AS LocalProjectId
		,GlobalProjectID AS GlobalProjectId
		,CustomerId AS CompanyId
		,SegmentDescription AS SegmentDescription
		,mSectionId AS DocId
		,RequirementTag AS Tag
		,IndentLevel AS Hierarchy
		,SequenceNumber AS SequenceNum
		,SegmentOrigin AS Origin
		,SegmentStatusId AS StatusID
		,mSegmentId AS SegmentID --This is the difference in above statement
		,ParentSegmentStatusId AS ParentID
		,SectionId
		 FROM #SegmentsTable S WHERE S.SegmentOrigin='M'

		 -- Clean up html tag that remain
		UPDATE t 
		SET t.segmentDescription=BPMCore_Staging_SLC.dbo.fn_ReplaceCharacter(t.segmentDescription)
		FROM BPMCore_Staging_SLC.dbo.Stg_ProjectSegments_Cloud t	 		

		UPDATE t 
		SET t.segmentDescription=BPMCore_Staging_SLC.dbo.fn_CleanRemainingTags(t.segmentDescription)
		FROM BPMCore_Staging_SLC.dbo.Stg_ProjectSegments_Cloud t


	END TRY
	BEGIN CATCH
		
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
		DECLARE @ErrorLine INT;

		--SELECT 
		--	@ErrorMessage = ERROR_MESSAGE(),
		--	@ErrorSeverity = ERROR_SEVERITY(),
		--	@ErrorState = ERROR_STATE(),
		--	@ErrorLine = ERROR_LINE();

	    RAISERROR (@ErrorMessage, -- Message text.
		           @ErrorSeverity, -- Severity.
			       @ErrorState, -- State.
				   @ErrorLine --Line
				   );

	END CATCH;
END
GO


