Use [SLCProject]

ALTER PROCEDURE [dbo].[usp_DeleteProjectForJob]  
AS  
begin  
	SET NOCOUNT	ON
	DECLARE @ProjectTable AS TABLE(ProjectId INT,CustomerId INT);    
	DECLARE @DeletedProjectLog NVARCHAR(MAX);   
	DECLARE @TempDeletedRows INT;
	DECLARE @DeletedRows bigint;
	DECLARE @RowsToDelete INT=5000;
	DECLARE @StartTime datetime2
	DECLARE @EndTime datetime2
	DECLARE @DeleteStartTime datetime2
	DECLARE	@ProjectId int
	DECLARE @WaitTime varchar(15)='00:00:00:02'



	INSERT INTO @ProjectTable(ProjectId,CustomerId)  
	SELECT TOP 100 ProjectId,CustomerId FROM [dbo].[Project] WITH(NoLock) 
	WHERE IsPermanentDeleted=1 and  IsDeleted=1

	CREATE TABLE #temptable 
	([IdColumn] [bigint] NOT NULL primary key,
	)
	ALTER TABLE ApplyMasterUpdateLog NOCHECK CONSTRAINT ALL 
	ALTER TABLE CopyProjectHistory NOCHECK CONSTRAINT ALL 
	ALTER TABLE CopyProjectRequest NOCHECK CONSTRAINT ALL 
	ALTER TABLE ImportProjectHistory NOCHECK CONSTRAINT ALL 
	ALTER TABLE ImportProjectRequest NOCHECK CONSTRAINT ALL 
	ALTER TABLE ImportProjectRequest NOCHECK CONSTRAINT ALL 
	ALTER TABLE ImportProjectRequest NOCHECK CONSTRAINT ALL 
	ALTER TABLE ProjectLevelTrackChangesLogging NOCHECK CONSTRAINT ALL 
	ALTER TABLE ProjectPrintSetting NOCHECK CONSTRAINT ALL 
	ALTER TABLE SectionLevelTrackChangesLogging NOCHECK CONSTRAINT ALL 
	ALTER TABLE SegmentComment NOCHECK CONSTRAINT ALL 
	ALTER TABLE TrackAcceptRejectProjectSegmentHistory NOCHECK CONSTRAINT ALL 
	ALTER TABLE UserProjectAccessMapping NOCHECK CONSTRAINT ALL 
	ALTER TABLE ApplyMasterUpdateLog  NOCHECK CONSTRAINT ALL  
	ALTER TABLE LuProjectSectionIdSeparator NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectDateFormat   NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectPageSetting   NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectPaperSetting   NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectDisciplineSection NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectImage NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectMigrationException NOCHECK CONSTRAINT ALL  
	ALTER TABLE LinkedSections NOCHECK CONSTRAINT ALL  
	ALTER TABLE MaterialSection NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentTab NOCHECK CONSTRAINT ALL  
	ALTER TABLE MaterialSectionMapping NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectRevitFile NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectRevitFileMapping NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentTracking NOCHECK CONSTRAINT ALL  
	ALTER TABLE HeaderFooterGlobalTermUsage NOCHECK CONSTRAINT ALL  
	ALTER TABLE HeaderFooterReferenceStandardUsage NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectGlobalTerm NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectHyperLink NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectNote NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectReferenceStandard NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentGlobalTerm NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectNoteImage NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentImage NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentLink NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentReferenceStandard NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentRequirementTag NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentUserTag NOCHECK CONSTRAINT ALL  
	ALTER TABLE UserGlobalTerm NOCHECK CONSTRAINT ALL  
	ALTER TABLE Header NOCHECK CONSTRAINT ALL  
	ALTER TABLE Footer NOCHECK CONSTRAINT ALL  
	ALTER TABLE SelectedChoiceOption NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectChoiceOption NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentChoice NOCHECK CONSTRAINT ALL  
	ALTER TABLE PROJECTSEGMENT NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentStatus NOCHECK CONSTRAINT ALL  
	ALTER TABLE PROJECTSECTION NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSummary NOCHECK CONSTRAINT ALL  
	ALTER TABLE UserFolder NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectAddress NOCHECK CONSTRAINT ALL  
	ALTER TABLE ProjectExport NOCHECK CONSTRAINT ALL 

	ALTER TABLE PROJECT NOCHECK CONSTRAINT ALL  


	--Loop Starts
	while (select count(*) from @ProjectTable) > 0
	BEGIN
		SET @DeleteStartTime =GETDATE()

		SELECT top 1 @ProjectId = ProjectId from @ProjectTable
		--PRINT 'ProjectID==>' + Convert(varchar(25),@ProjectId)
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[DeletedLogHistory],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),@ProjectId,'Deleted ProjectId',GETDATE(),GETDATE(),null)  

		--****************************************************************************	
		--SelectedChoiceOption
		--PRINT 'SelectedChoiceOption - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT SelectedChoiceOptionId  FROM SelectedChoiceOption SCO WITH(NoLock) 
		WHERE projectid=@projectId
		
		--PRINT 'SelectedChoiceOption - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) SCO
			FROM SelectedChoiceOption SCO
			Inner Join #temptable t on sco.SelectedChoiceOptionId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'SelectedChoiceOption->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted SelectedChoiceOption',@StartTime,Getdate(),@DeletedRows)
	
		TRUNCATE TABLE #temptable 

	
		--ProjectNoteImage
		--PRINT 'ProjectNoteImage - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  NoteImageId  FROM ProjectNoteImage PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectNoteImage - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectNoteImage PSS
			Inner Join #temptable t on PSS.NoteImageId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectNoteImage->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectNoteImage',@StartTime,Getdate(),@DeletedRows) 

		TRUNCATE TABLE #temptable

	
		--ProjectNote
		--PRINT 'ProjectNote - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT NoteId  FROM ProjectNote PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectNote - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectNote PSS
			Inner Join #temptable t on PSS.NoteId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectNote->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectNote',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable


		
		--ProjectSegmentStatus
		--PRINT 'ProjectSegmentStatus - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT SegmentStatusId  FROM ProjectSegmentStatus PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectSegmentStatus - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectSegmentStatus PSS
			Inner Join #temptable t on PSS.SegmentStatusId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectSegmentStatus->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectSegmentStatus',@StartTime,Getdate(),@DeletedRows) 

		TRUNCATE TABLE #temptable 

		--TrackProjectSegment
		--PRINT 'TrackProjectSegment - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT TrackSegmentId  FROM TrackProjectSegment PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'TrackProjectSegment - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM TrackProjectSegment PSS
			Inner Join #temptable t on PSS.TrackSegmentId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'TrackProjectSegment->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted TrackProjectSegment',@StartTime,Getdate(),@DeletedRows) 

		TRUNCATE TABLE #temptable
	
		--ProjectSegmentChoice
		--PRINT 'ProjectSegmentChoice - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT


		INSERT INTO #temptable(IdColumn) 
		SELECT SegmentChoiceId  FROM ProjectSegmentChoice PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectSegmentChoice - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectSegmentChoice PSS
			Inner Join #temptable t on PSS.SegmentChoiceId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectSegmentChoice->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectSegmentChoice',@StartTime,Getdate(),@DeletedRows) 

		TRUNCATE TABLE #temptable

		--PROJECTSEGMENT
		--PRINT 'PROJECTSEGMENT - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT SegmentId  FROM PROJECTSEGMENT PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'PROJECTSEGMENT - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM PROJECTSEGMENT PSS
			Inner Join #temptable t on PSS.SegmentId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'PROJECTSEGMENT->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted PROJECTSEGMENT',@StartTime,Getdate(),@DeletedRows) 

		TRUNCATE TABLE #temptable

	
		--ProjectSegmentLink
		--PRINT 'ProjectSegmentLink - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT segmentLinkID  FROM ProjectSegmentLink PSS WITH(NoLock) 
		WHERE projectid=@projectId 

		--PRINT 'ProjectSegmentLink - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectSegmentLink PSS
			Inner Join #temptable t on PSS.segmentLinkID=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectSegmentLink->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectSegmentLink',@StartTime,Getdate(),@DeletedRows) 

		TRUNCATE TABLE #temptable

	
		--ProjectSegmentLink
		--PRINT 'ProjectChoiceOption - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  ChoiceOptionId  FROM ProjectChoiceOption PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectChoiceOption - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectChoiceOption PSS
			Inner Join #temptable t on PSS.ChoiceOptionId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectChoiceOption->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectChoiceOption',@StartTime,Getdate(),@DeletedRows) 

		TRUNCATE TABLE #temptable

	
		--ProjectSegmentRequirementTag
		--PRINT 'ProjectChoiceOption - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT SegmentRequirementTagId  FROM ProjectSegmentRequirementTag PSS WITH(NoLock) 
		WHERE projectid=@projectId 

		--PRINT 'ProjectSegmentRequirementTag - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectSegmentRequirementTag PSS
			Inner Join #temptable t on PSS.SegmentRequirementTagId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectSegmentRequirementTag->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectSegmentRequirementTag',@StartTime,Getdate(),@DeletedRows) 

		TRUNCATE TABLE #temptable


		--ProjectReferenceStandard
		--PRINT 'ProjectReferenceStandard - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT ProjRefStdID  FROM ProjectReferenceStandard PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectReferenceStandard - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectReferenceStandard PSS
			Inner Join #temptable t on PSS.ProjRefStdID=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectReferenceStandard->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectReferenceStandard',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	
		--LinkedSections
		--PRINT 'LinkedSections - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT
	
		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SELECT @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN

			DELETE TOP(@RowsToDelete) FROM LinkedSections WHERE ProjectID=@ProjectId
		
			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'LinkedSections->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
		   
		  WaitFor DELAY @WaitTime
   
   
		END
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted LinkedSections',@StartTime,Getdate(),@DeletedRows)  
		
  
		--MaterialSection
		--PRINT 'MaterialSection - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT
		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN

			DELETE TOP(@RowsToDelete) FROM MaterialSection WHERE ProjectID=@ProjectId
		
			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'MaterialSection->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
		   
		  WaitFor DELAY @WaitTime
   
		END
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted MaterialSection',@StartTime,Getdate(),@DeletedRows)  
	
		--ProjectSegmentTab
		--PRINT 'ProjectSegmentTab - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  SegmentTabId  FROM ProjectSegmentTab PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectSegmentTab - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectSegmentTab PSS
			Inner Join #temptable t on PSS.SegmentTabId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectSegmentTab->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectSegmentTab',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	

		--MaterialSectionMapping
		--PRINT 'MaterialSectionMapping - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT MaterialSectionMappingId  FROM MaterialSectionMapping PSS WITH(NoLock) 
		WHERE projectid=@projectId 

		--PRINT 'MaterialSectionMapping - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM MaterialSectionMapping PSS
			Inner Join #temptable t on PSS.MaterialSectionMappingId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'MaterialSectionMapping->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted MaterialSectionMapping',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable

	
		--ProjectRevitFile
		--PRINT 'ProjectRevitFile - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  RevitFileId  FROM ProjectRevitFile PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectRevitFile - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN

			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectRevitFile PSS
			Inner Join #temptable t on PSS.RevitFileId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectRevitFile->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectRevitFile',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable

		--ProjectRevitFileMapping
		--PRINT 'ProjectRevitFileMapping - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  ProjectRevitFileMappingId  FROM ProjectRevitFileMapping PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectRevitFileMapping - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN

			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectRevitFileMapping PSS
			Inner Join #temptable t on PSS.ProjectRevitFileMappingId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectRevitFileMapping->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectRevitFileMapping',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable

		--ProjectSegmentTracking
		--PRINT 'ProjectSegmentTracking - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  TrackId  FROM ProjectSegmentTracking PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectSegmentTracking - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN

			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectSegmentTracking PSS
			Inner Join #temptable t on PSS.TrackId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectSegmentTracking->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectSegmentTracking',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	

		--HeaderFooterGlobalTermUsage
		--PRINT 'HeaderFooterGlobalTermUsage - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  HeaderFooterGTId  FROM HeaderFooterGlobalTermUsage PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'HeaderFooterGlobalTermUsage - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN

			DELETE TOP(@RowsToDelete) PSS
			FROM HeaderFooterGlobalTermUsage PSS
			Inner Join #temptable t on PSS.HeaderFooterGTId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'HeaderFooterGlobalTermUsage->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted HeaderFooterGlobalTermUsage',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable

		
		--HeaderFooterReferenceStandardUsage
		--PRINT 'HeaderFooterReferenceStandardUsage - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  HeaderFooterRSId  FROM HeaderFooterReferenceStandardUsage PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'HeaderFooterReferenceStandardUsage - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM HeaderFooterReferenceStandardUsage PSS
			Inner Join #temptable t on PSS.HeaderFooterRSId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'HeaderFooterReferenceStandardUsage->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted HeaderFooterReferenceStandardUsage',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable


		--ProjectGlobalTerm
		--PRINT 'ProjectGlobalTerm - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  GlobalTermId  FROM ProjectGlobalTerm PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectGlobalTerm - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectGlobalTerm PSS
			Inner Join #temptable t on PSS.GlobalTermId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectGlobalTerm->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectGlobalTerm',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	
		--ProjectHyperLink
		--PRINT 'ProjectHyperLink - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  HyperLinkId  FROM ProjectHyperLink PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectHyperLink - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectHyperLink PSS
			Inner Join #temptable t on PSS.HyperLinkId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectHyperLink->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectHyperLink',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	
		--ProjectSegmentGlobalTerm
		--PRINT 'ProjectSegmentGlobalTerm - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  SegmentGlobalTermId  FROM ProjectSegmentGlobalTerm PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectSegmentGlobalTerm - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectSegmentGlobalTerm PSS
			Inner Join #temptable t on PSS.SegmentGlobalTermId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectSegmentGlobalTerm->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectSegmentGlobalTerm',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	
		--ProjectSegmentImage
		--PRINT 'ProjectSegmentImage - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  SegmentImageId  FROM ProjectSegmentImage PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectSegmentImage - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectSegmentImage PSS
			Inner Join #temptable t on PSS.SegmentImageId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectSegmentImage->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectSegmentImage',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	
		--ProjectSegmentReferenceStandard
		--PRINT 'ProjectSegmentReferenceStandard - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  SegmentRefStandardId  FROM ProjectSegmentReferenceStandard PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectSegmentReferenceStandard - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectSegmentReferenceStandard PSS
			Inner Join #temptable t on PSS.SegmentRefStandardId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectSegmentReferenceStandard->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectSegmentReferenceStandard',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	
		--ProjectSegmentUserTag
		--PRINT 'ProjectSegmentUserTag - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  SegmentUserTagId  FROM ProjectSegmentUserTag PSS WITH(NoLock) 
		WHERE projectid=@projectId 

		--PRINT 'ProjectSegmentUserTag - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectSegmentUserTag PSS
			Inner Join #temptable t on PSS.SegmentUserTagId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectSegmentUserTag->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectSegmentUserTag',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	
		--UserGlobalTerm
		--PRINT 'UserGlobalTerm - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT
	
		INSERT INTO #temptable(IdColumn) 
		SELECT  UserGlobalTermId  FROM UserGlobalTerm PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'UserGlobalTerm - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM UserGlobalTerm PSS
			Inner Join #temptable t on PSS.UserGlobalTermId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'UserGlobalTerm->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted UserGlobalTerm',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	
		--Header
		--PRINT 'Header - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  HeaderId  FROM Header PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'Header - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM Header PSS
			Inner Join #temptable t on PSS.HeaderId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'Header->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted Header',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	
		--Footer
		--PRINT 'Footer - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  FooterId  FROM Footer PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'Footer - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM Footer PSS
			Inner Join #temptable t on PSS.FooterId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'Footer->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted Footer',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	
	
		--ProjectMigrationException
		--PRINT 'ProjectMigrationException - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  MigrationExceptionId  FROM ProjectMigrationException PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectMigrationException - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectMigrationException PSS
			Inner Join #temptable t on PSS.MigrationExceptionId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectMigrationException->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectMigrationException',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	
		--PROJECTSECTION
		--PRINT 'ProjectSection - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  SectionId  FROM ProjectSection PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectSection - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectSection PSS
			Inner Join #temptable t on PSS.SectionId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectSection->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectSection',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	

		--ProjectSummary
		--PRINT 'ProjectSummary - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  ProjectSummaryId  FROM ProjectSummary PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectSummary - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectSummary PSS
			Inner Join #temptable t on PSS.ProjectSummaryId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectSummary->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectSummary',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable

		--UserFolder
		--PRINT 'UserFolder - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  UserFolderId  FROM UserFolder PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'UserFolder - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT


		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM UserFolder PSS
			Inner Join #temptable t on PSS.UserFolderId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'UserFolder->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted UserFolder',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable

		--ProjectAddress
		--PRINT 'ProjectAddress - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  AddressId  FROM ProjectAddress PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectAddress - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectAddress PSS
			Inner Join #temptable t on PSS.AddressId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectAddress->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectAddress',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	
		--LuProjectSectionIdSeparator
		--PRINT 'LuProjectSectionIdSeparator - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  id  FROM LuProjectSectionIdSeparator PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'LuProjectSectionIdSeparator - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM LuProjectSectionIdSeparator PSS
			Inner Join #temptable t on PSS.id=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'LuProjectSectionIdSeparator->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted LuProjectSectionIdSeparator',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable

		--ProjectDateFormat
		--PRINT 'ProjectDateFormat - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  ProjectDateFormatId  FROM ProjectDateFormat PSS WITH(NoLock) 
			WHERE projectid=@projectId

		--PRINT 'ProjectDateFormat - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectDateFormat PSS
			Inner Join #temptable t on PSS.ProjectDateFormatId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectDateFormat->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectDateFormat',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	  
		--ProjectPageSetting
		--PRINT 'ProjectPageSetting - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  ProjectPageSettingId  FROM ProjectPageSetting PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectPageSetting - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectPageSetting PSS
			Inner Join #temptable t on PSS.ProjectPageSettingId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectPageSetting->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectPageSetting',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable


		--ProjectPaperSetting
		--PRINT 'ProjectPaperSetting - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  ProjectPaperSettingId  FROM ProjectPaperSetting PSS WITH(NoLock) 
		WHERE projectid=@projectId 

		--PRINT 'ProjectPaperSetting - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectPaperSetting PSS
			Inner Join #temptable t on PSS.ProjectPaperSettingId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectPaperSetting->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectPaperSetting',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable

		--ProjectDisciplineSection
		--PRINT 'ProjectDisciplineSection - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  ID  FROM ProjectDisciplineSection PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectDisciplineSection - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectDisciplineSection PSS
			Inner Join #temptable t on PSS.ID=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectDisciplineSection->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectDisciplineSection',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable
	
		--ProjectExport
		--PRINT 'ProjectExport - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT  ProjectExportId  FROM ProjectExport PSS WITH(NoLock) 
		WHERE projectid=@projectId

		--PRINT 'ProjectExport - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) PSS
			FROM ProjectExport PSS
			Inner Join #temptable t on PSS.ProjectExportId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectExport->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectExport',@StartTime,Getdate(),@DeletedRows) 
		TRUNCATE TABLE #temptable

		
		--ApplyMasterUpdateLog
		--PRINT 'ApplyMasterUpdateLog - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT ID  FROM ApplyMasterUpdateLog  WITH(NoLock) 
		WHERE projectid=@projectId
		
		--PRINT 'ApplyMasterUpdateLog - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) DelTbl
			FROM ApplyMasterUpdateLog DelTbl
			Inner Join #temptable t on DelTbl.Id=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ApplyMasterUpdateLog->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ApplyMasterUpdateLog',@StartTime,Getdate(),@DeletedRows)
	
		TRUNCATE TABLE #temptable 


		--CopyProjectHistory
		--PRINT 'CopyProjectHistory - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT ID  FROM CopyProjectHistory  WITH(NoLock) 
		WHERE projectid=@projectId
		
		--PRINT 'CopyProjectHistory - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) DelTbl
			FROM CopyProjectHistory DelTbl
			Inner Join #temptable t on DelTbl.Id=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'CopyProjectHistory->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted CopyProjectHistory',@StartTime,Getdate(),@DeletedRows)
	
		TRUNCATE TABLE #temptable 


		--CopyProjectRequest
		--PRINT 'CopyProjectRequest - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT RequestId  FROM CopyProjectRequest  WITH(NoLock) 
		WHERE SourceProjectId=@projectId
		
		--PRINT 'CopyProjectRequest - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) DelTbl
			FROM CopyProjectRequest DelTbl
			Inner Join #temptable t on DelTbl.RequestId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'CopyProjectRequest->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted CopyProjectRequest',@StartTime,Getdate(),@DeletedRows)
	
		TRUNCATE TABLE #temptable 

		--CopyProjectRequest
		--PRINT 'CopyProjectRequest - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT RequestId  FROM CopyProjectRequest  WITH(NoLock) 
		WHERE SourceProjectId=@projectId
		
		--PRINT 'CopyProjectRequest - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) DelTbl
			FROM CopyProjectRequest DelTbl
			Inner Join #temptable t on DelTbl.RequestId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'CopyProjectRequest->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted CopyProjectRequest',@StartTime,Getdate(),@DeletedRows)
	
		TRUNCATE TABLE #temptable 


		--ImportProjectHistory
		--PRINT 'ImportProjectHistory - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT Id  FROM ImportProjectHistory  WITH(NoLock) 
		WHERE ProjectId=@projectId
		
		--PRINT 'ImportProjectHistory - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) DelTbl
			FROM ImportProjectHistory DelTbl
			Inner Join #temptable t on DelTbl.Id=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ImportProjectHistory->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ImportProjectHistory',@StartTime,Getdate(),@DeletedRows)
	
		TRUNCATE TABLE #temptable 


		--ImportProjectRequest
		--PRINT 'ImportProjectRequest - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT RequestId  FROM ImportProjectRequest  WITH(NoLock) 
		WHERE SourceProjectId=@projectId
		
		--PRINT 'ImportProjectRequest - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) DelTbl
			FROM ImportProjectRequest DelTbl
			Inner Join #temptable t on DelTbl.RequestId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ImportProjectRequest->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ImportProjectRequest',@StartTime,Getdate(),@DeletedRows)
	
		TRUNCATE TABLE #temptable 


		--PrintRequestDetails
		--PRINT 'PrintRequestDetails - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT PrintRequestId  FROM PrintRequestDetails  WITH(NoLock) 
		WHERE ProjectId=@projectId
		
		--PRINT 'PrintRequestDetails - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) DelTbl
			FROM PrintRequestDetails DelTbl
			Inner Join #temptable t on DelTbl.PrintRequestId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'PrintRequestDetails->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted PrintRequestDetails',@StartTime,Getdate(),@DeletedRows)
	
		TRUNCATE TABLE #temptable 

		--ProjectActivity
		--PRINT 'ProjectActivity - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT ActivityId  FROM ProjectActivity  WITH(NoLock) 
		WHERE ProjectId=@projectId
		
		--PRINT 'ProjectActivity - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) DelTbl
			FROM ProjectActivity DelTbl
			Inner Join #temptable t on DelTbl.ActivityId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectActivity->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectActivity',@StartTime,Getdate(),@DeletedRows)
	
		TRUNCATE TABLE #temptable 


		--ProjectLevelTrackChangesLogging
		--PRINT 'ProjectLevelTrackChangesLogging - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT ProjectChangeId  FROM ProjectLevelTrackChangesLogging  WITH(NoLock) 
		WHERE ProjectId=@projectId
		
		--PRINT 'ProjectLevelTrackChangesLogging - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) DelTbl
			FROM ProjectLevelTrackChangesLogging DelTbl
			Inner Join #temptable t on DelTbl.ProjectChangeId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectLevelTrackChangesLogging->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectLevelTrackChangesLogging',@StartTime,Getdate(),@DeletedRows)
	
		TRUNCATE TABLE #temptable 


		--ProjectLevelTrackChangesLogging
		--PRINT 'ProjectLevelTrackChangesLogging - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT ProjectChangeId  FROM ProjectLevelTrackChangesLogging  WITH(NoLock) 
		WHERE ProjectId=@projectId
		
		--PRINT 'ProjectLevelTrackChangesLogging - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) DelTbl
			FROM ProjectLevelTrackChangesLogging DelTbl
			Inner Join #temptable t on DelTbl.ProjectChangeId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectLevelTrackChangesLogging->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectLevelTrackChangesLogging',@StartTime,Getdate(),@DeletedRows)
		TRUNCATE TABLE #temptable 

		--ProjectPrintSetting
		--PRINT 'ProjectPrintSetting - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT ProjectPrintSettingId  FROM ProjectPrintSetting  WITH(NoLock) 
		WHERE ProjectId=@projectId
		
		--PRINT 'ProjectPrintSetting - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) DelTbl
			FROM ProjectPrintSetting DelTbl
			Inner Join #temptable t on DelTbl.ProjectPrintSettingId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'ProjectPrintSetting->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted ProjectPrintSetting',@StartTime,Getdate(),@DeletedRows)
	
		TRUNCATE TABLE #temptable 


		--SectionLevelTrackChangesLogging
		--PRINT 'SectionLevelTrackChangesLogging - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT SectionChangeId  FROM SectionLevelTrackChangesLogging  WITH(NoLock) 
		WHERE ProjectId=@projectId
		
		--PRINT 'SectionLevelTrackChangesLogging - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) DelTbl
			FROM SectionLevelTrackChangesLogging DelTbl
			Inner Join #temptable t on DelTbl.SectionChangeId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'SectionLevelTrackChangesLogging->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted SectionLevelTrackChangesLogging',@StartTime,Getdate(),@DeletedRows)
	
		TRUNCATE TABLE #temptable 

		--SegmentComment
		--PRINT 'SegmentComment - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT SegmentCommentId  FROM SegmentComment  WITH(NoLock) 
		WHERE ProjectId=@projectId
		
		--PRINT 'SegmentComment - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) DelTbl
			FROM SegmentComment DelTbl
			Inner Join #temptable t on DelTbl.SegmentCommentId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'SegmentComment->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted SegmentComment',@StartTime,Getdate(),@DeletedRows)
		TRUNCATE TABLE #temptable 	


		--TrackAcceptRejectProjectSegmentHistory
		--PRINT 'TrackAcceptRejectProjectSegmentHistory - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT TrackHistoryId  FROM TrackAcceptRejectProjectSegmentHistory  WITH(NoLock) 
		WHERE ProjectId=@projectId
		
		--PRINT 'TrackAcceptRejectProjectSegmentHistory - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) DelTbl
			FROM TrackAcceptRejectProjectSegmentHistory DelTbl
			Inner Join #temptable t on DelTbl.TrackHistoryId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'TrackAcceptRejectProjectSegmentHistory->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted TrackAcceptRejectProjectSegmentHistory',@StartTime,Getdate(),@DeletedRows)
	
		TRUNCATE TABLE #temptable 

		--PRINT 'UserProjectAccessMapping - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		INSERT INTO #temptable(IdColumn) 
		SELECT MappingId  FROM UserProjectAccessMapping  WITH(NoLock) 
		WHERE ProjectId=@projectId
		
		--PRINT 'UserProjectAccessMapping - Insert Completed'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) DelTbl
			FROM UserProjectAccessMapping DelTbl
			Inner Join #temptable t on DelTbl.MappingId=t.IdColumn

			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'UserProjectAccessMapping->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
			
			WaitFor DELAY @WaitTime
   
		END 

		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted UserProjectAccessMapping',@StartTime,Getdate(),@DeletedRows)
	
		TRUNCATE TABLE #temptable 

	
		 --PROJECT
		--PRINT 'Project - Started'
		--RAISERROR(N'', 0, 1) WITH NOWAIT

		SELECT @TempDeletedRows = 1,@DeletedRows=0;
		SET @StartTime=Getdate()
		WHILE (@TempDeletedRows > 0)
		BEGIN
			DELETE TOP(@RowsToDelete) FROM PROJECT WHERE ProjectID=@ProjectId
		
			SET @TempDeletedRows = @@ROWCOUNT;
			SET @DeletedRows= @DeletedRows+@TempDeletedRows;
			--PRINT 'Project->' + Convert(varchar(25),@DeletedRows) +'->' +Convert(varchar(20),getdate(),120)
			--RAISERROR(N'', 0, 1) WITH NOWAIT
		   
		  WaitFor DELAY @WaitTime
   
		END   
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Deleted Project',@StartTime,Getdate(),@DeletedRows)  

		--****************************************************************************

		DELETE @ProjectTable where ProjectId = @ProjectId
	
		INSERT INTO [dbo].[DeletedProjectLog]([DeletedDate],[ActionName],[StartTime],[EndTime],[RecordsDeleted]) 
		VALUES(GETDATE(),'Delete Completed',@DeleteStartTime,Getdate(),null)  

	end
	SET NOCOUNT	OFF
	--Loop Ends  
	ALTER TABLE ApplyMasterUpdateLog CHECK CONSTRAINT ALL  
	ALTER TABLE CopyProjectHistory CHECK CONSTRAINT ALL  
	ALTER TABLE CopyProjectRequest CHECK CONSTRAINT ALL  
	ALTER TABLE ImportProjectHistory CHECK CONSTRAINT ALL  
	ALTER TABLE ImportProjectRequest CHECK CONSTRAINT ALL 
	ALTER TABLE PrintRequestDetails CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectActivity CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectLevelTrackChangesLogging CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectPrintSetting CHECK CONSTRAINT ALL  
	ALTER TABLE SectionLevelTrackChangesLogging CHECK CONSTRAINT ALL  
	ALTER TABLE SegmentComment CHECK CONSTRAINT ALL  
	ALTER TABLE TrackAcceptRejectProjectSegmentHistory CHECK CONSTRAINT ALL  
	ALTER TABLE UserProjectAccessMapping CHECK CONSTRAINT ALL  
	ALTER TABLE ApplyMasterUpdateLog  CHECK CONSTRAINT ALL  
	ALTER TABLE LuProjectSectionIdSeparator CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectDateFormat   CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectPageSetting   CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectPaperSetting   CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectDisciplineSection CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectImage CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectMigrationException CHECK CONSTRAINT ALL  
	ALTER TABLE LinkedSections CHECK CONSTRAINT ALL  
	ALTER TABLE MaterialSection CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentTab CHECK CONSTRAINT ALL  
	ALTER TABLE MaterialSectionMapping CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectRevitFile CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectRevitFileMapping CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentTracking CHECK CONSTRAINT ALL  
	ALTER TABLE HeaderFooterGlobalTermUsage CHECK CONSTRAINT ALL  
	ALTER TABLE HeaderFooterReferenceStandardUsage CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectGlobalTerm CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectHyperLink CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectNote CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectReferenceStandard CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentGlobalTerm CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectNoteImage CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentImage CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentLink CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentReferenceStandard CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentRequirementTag CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentUserTag CHECK CONSTRAINT ALL  
	ALTER TABLE UserGlobalTerm CHECK CONSTRAINT ALL  
	ALTER TABLE Header CHECK CONSTRAINT ALL  
	ALTER TABLE Footer CHECK CONSTRAINT ALL  
	ALTER TABLE SelectedChoiceOption CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectChoiceOption CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentChoice CHECK CONSTRAINT ALL  
	ALTER TABLE PROJECTSEGMENT CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSegmentStatus CHECK CONSTRAINT ALL  
	ALTER TABLE PROJECTSECTION CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectSummary CHECK CONSTRAINT ALL  
	ALTER TABLE UserFolder CHECK CONSTRAINT ALL  
	ALTER TABLE ProjectAddress CHECK CONSTRAINT ALL
	ALTER TABLE ProjectExport CHECK CONSTRAINT ALL  
	ALTER TABLE PROJECT CHECK CONSTRAINT ALL  

  
END
GO
PRINT N'Altering [dbo].[getProjectListById]...';


GO
ALTER PROC [dbo].[getProjectListById]  
(  
 @projectId nvarchar(max)  
)  
AS  
BEGIN
  
DECLARE @PprojectId nvarchar(max) = @projectId;

SELECT
	P.ProjectId
	,P.Name
	,P.Description
FROM Project p WITH (NOLOCK)
INNER JOIN STRING_SPLIT(@PprojectId, ',') i
	ON p.ProjectId = i.value
WHERE ISNULL(P.IsDeleted,0) = 0
		And ISNULL(P.IsArchived,0)=0
END
GO
PRINT N'Altering [dbo].[usp_CreateGlobalTerms]...';


GO
ALTER PROCEDURE [dbo].[usp_CreateGlobalTerms]   
(
	@Name  NVARCHAR(max) NULL,  
	@Value NVARCHAR(max) NULL,  
	@CreatedBy INT NULL,  
	@CustomerId INT NULL,  
	@ProjectId INT NULL  
)
AS        
BEGIN  
  
	DECLARE @PName NVARCHAR(max) = @Name;  
	DECLARE @PValue NVARCHAR(max) = @Value;  
	DECLARE @PCreatedBy INT = @CreatedBy;  
	DECLARE @PCustomerId INT = @CustomerId;  
	DECLARE @PProjectId INT = @ProjectId;  
	
	SET NOCOUNT ON;  
  

	 DECLARE @GlobalTermCode INT = 0;  
	 DECLARE @UserGlobalTermId INT = NULL  
	 DECLARE @MaxGlobalTermCode INT = (SELECT TOP 1 GlobalTermCode FROM ProjectGlobalTerm WITH(NOLOCK) WHERE CustomerId = @PCustomerId ORDER BY GlobalTermCode DESC);
  
	 DECLARE @MinGlobalTermCode INT = 10000000;  
	 IF(@MinGlobalTermCode < @MinGlobalTermCode)  
		 BEGIN
			SET @MaxGlobalTermCode = @MinGlobalTermCode;
		 END
  
	INSERT INTO [UserGlobalTerm] ([Name], [Value], CreatedDate, CreatedBy, CustomerId, ProjectId, IsDeleted)  
	VALUES (@PName, @PValue, GETUTCDATE(), @PCreatedBy, @PCustomerId, @PProjectId, 0);
	SET @UserGlobalTermId = SCOPE_IDENTITY();
  
	SET @MaxGlobalTermCode = @MaxGlobalTermCode + 1;

	INSERT INTO [ProjectGlobalTerm] (ProjectId, CustomerId, [Name], [Value], GlobalTermSource, CreatedDate, CreatedBy, UserGlobalTermId, GlobalTermCode)  
	 SELECT  
		 P.ProjectId
		,@PCustomerId AS CustomerId
		,@PName AS [Name]
		,@PValue AS [Value]
		,'U' AS GlobalTermSource 
		,GETUTCDATE() AS CreatedDate
		,@PCreatedBy AS CreatedBy  
		,@UserGlobalTermId AS UserGlobalTermId 
		,@MaxGlobalTermCode AS GlobalTermCode
	 FROM Project P WITH(NOLOCK)
	 WHERE P.CustomerId = @PCustomerId AND ISNULL(P.IsDeleted, 0) = 0;
  
	SELECT @MaxGlobalTermCode AS GlobalTermCode;
  
END
GO
PRINT N'Altering [dbo].[usp_GetAllNotifications]...';


GO
ALTER PROCEDURE [dbo].[usp_GetAllNotifications]  
(      
 @CustomerId INT,      
 @UserId INT,      
 @IsSystemManager BIT=0      
)      
AS      
BEGIN      
 DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())      
   
 DECLARE @RES AS TABLE(RequestId INT,SourceProjectId INT,TargetProjectId INT,TargetSectionId INT,  
       RequestDateTime DATETIME,RequestDateTimeStr NVARCHAR(20),RequestExpiryDateTime DATETIME,  
       StatusId INT,IsNotify BIT,CompletedPercentage INT,[Source] NVARCHAR(200),  
       TaskName nvarchar(500),StatusDescription nvarchar(50),IsOfficeMaster BIT,RequestTypeId INT)  
   
 INSERT INTO @RES  
 SELECT CPR.RequestId    
 ,CPR.SourceProjectId    
 ,CPR.TargetProjectId    
 ,0  AS TargetSectionId        
 ,CPR.CreatedDate  AS RequestDateTime   
 ,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr  
 ,DATEADD(DAY,30,CPR.CreatedDate) AS RequestExpiryDateTime    
 ,CPR.StatusId    
 ,CPR.IsNotify    
 ,CPR.CompletedPercentage    
 ,'CopyProject' AS [Source]  
 ,CONVERT(nvarchar(500),'') AS TaskName  
 ,CONVERT(nvarchar(50),'') AS StatusDescription  
 ,0  
 ,0
 FROM CopyProjectRequest CPR WITH(NOLOCK)      
 WHERE CPR.CreatedById=@UserId    
 AND ISNULL(CPR.IsDeleted,0)=0      
 AND CPR.CreatedDate> @DateBefore30Days   
 
 INSERT INTO @RES  
 SELECT CPR.RequestId            
 ,0 AS SourceProjectId    
 ,CPR.SLCProd_ProjectId as TargetProjectId    
 ,0 as TargetSectionId       
 ,CPR.RequestDate AS RequestDateTime           
 ,FORMAT(CPR.RequestDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr  
 ,DATEADD(DAY,30,CPR.RequestDate) AS RequestExpiryDateTime            
 ,CPR.StatusId            
 ,CPR.IsNotify            
 ,CPR.ProgressInPercentage as CompletedPercentage         
 ,'UnArchiveProject' Source  
 ,CPR.ProjectName AS TaskName  
 ,CONVERT(nvarchar(50),'') AS StatusDescription  
 ,0  
 ,CPR.RequestType
  FROM UnArchiveProjectRequest CPR WITH(NOLOCK)           
  WHERE CPR.SLC_UserId=@UserId     
  AND ISNULL(CPR.IsDeleted,0)=0         
  AND CPR.RequestDate> @DateBefore30Days             
  
 UPDATE t  
 SET t.TaskName=P.Name,  
 t.IsOfficeMaster=p.IsOfficeMaster  
 FROM @RES t INNER JOIN Project P WITH(NOLOCK)       
 ON t.TargetProjectId=P.ProjectId  
 WHERE P.CustomerId=@CustomerId  
 AND t.[Source] in('CopyProject','UnArchiveProject')  
  
 INSERT INTO @RES  
 SELECT CPR.RequestId            
 ,CPR.SourceProjectId    
 ,CPR.TargetProjectId    
 ,CPR.TargetSectionId       
 ,CPR.CreatedDate AS RequestDateTime           
 ,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr  
 ,DATEADD(DAY,30,CPR.CreatedDate) AS RequestExpiryDateTime            
 ,CPR.StatusId            
 ,CPR.IsNotify            
 ,CPR.CompletedPercentage         
 ,CPR.Source  
 ,CONVERT(nvarchar(500),'') AS TaskName  
 ,CONVERT(nvarchar(50),'') AS StatusDescription  
 ,0  
 ,0
  FROM ImportProjectRequest CPR WITH(NOLOCK)           
  WHERE CPR.CreatedById=@UserId AND [Source] IN('SpecAPI','Import from Template')       
  AND ISNULL(CPR.IsDeleted,0)=0         
  AND CPR.CreatedDate> @DateBefore30Days             
  
 UPDATE t  
 SET t.TaskName=PS.Description  
 FROM @RES t INNER JOIN ProjectSection PS WITH(NOLOCK)       
 ON t.TargetSectionId=PS.SectionId  
 WHERE PS.CustomerId=@CustomerId  
 AND t.[Source] IN('SpecAPI','Import from Template')  
  
 UPDATE CPR  
 SET CPR.IsNotify = 1  
 ,ModifiedDate = GETUTCDATE()  
 FROM ImportProjectRequest CPR WITH (NOLOCK)  
 INNER JOIN @RES t  
 ON CPR.RequestId = t.RequestId  
 AND CPR.[Source]=t.[Source]  
 WHERE CPR.IsNotify = 0  
 AND t.[Source] IN('SpecAPI','Import from Template') 

 UPDATE CPR  
 SET CPR.IsNotify = 1  
 ,ModifiedDate = GETUTCDATE()  
 FROM CopyProjectRequest CPR WITH (NOLOCK)  
 INNER JOIN @RES t  
 ON CPR.RequestId = t.RequestId  
 WHERE CPR.IsNotify = 0  
 AND t.[Source] ='CopyProject'

 UPDATE CPR  
 SET CPR.IsNotify = 1  
 ,ModifiedDate = GETUTCDATE()  
 FROM UnArchiveProjectRequest CPR WITH (NOLOCK)  
 INNER JOIN @RES t  
 ON CPR.RequestId = t.RequestId  
 WHERE CPR.IsNotify = 0  
 AND t.[Source] ='UnArchiveProject'

  UPDATE t  
  SET t.StatusDescription=LCS.StatusDescription  
  FROM @RES t INNER JOIN LuCopyStatus LCS WITH(NOLOCK)       
  ON t.StatusId=LCS.CopyStatusId  

  SELECT * FROM @RES  
  ORDER BY RequestDateTimeStr DESC  
  --Check type sorting performance  
  
END
GO
PRINT N'Altering [dbo].[usp_GetDeletedProjects]...';


GO
ALTER PROCEDURE [dbo].[usp_GetDeletedProjects] -- EXEC GetDeletedProject @CustomerID = 8,  @UserID = 12, @IsOfficeMaster = 0                  
 @CustomerId INT NULL              
 ,@UserId INT NULL = NULL              
 ,@IsOfficeMaster BIT NULL = NULL              
 ,@IsSystemManager BIT NULL = 0                
AS              
BEGIN      
            
  DECLARE @PCustomerId INT = @CustomerId;      
            
  DECLARE @PUserId INT = @UserId;      
            
  DECLARE @PIsOfficeMaster BIT = @IsOfficeMaster;      
            
  DECLARE @PIsSystemManager BIT = @IsSystemManager;      
            
            
 CREATE TABLE #projectList  (              
   ProjectId INT              
    ,[Name] NVARCHAR(255)              
    ,ModifiedBy INT              
    ,ModifiedDate DATETIME2              
    ,ModifiedByFullName NVARCHAR(100)              
    ,ProjectAccessTypeId INT            
    ,IsProjectAccessible bit             
    ,ProjectAccessTypeName NVARCHAR(100)            
    )      
              
            
 IF(@PIsSystemManager=1)            
 BEGIN      
INSERT INTO #projectList      
 SELECT      
  p.ProjectId      
    ,LTRIM(RTRIM(p.[Name])) AS [Name]      
    ,p.ModifiedBy      
    ,p.ModifiedDate      
    ,p.ModifiedByFullName      
    ,psm.projectAccessTypeId      
    ,1 AS isProjectAccessible      
    ,'' AS projectAccessTypeName      
 FROM Project AS p WITH (NOLOCK)      
 INNER JOIN [ProjectSummary] psm WITH (NOLOCK)      
  ON psm.ProjectId = p.ProjectId      
 WHERE p.IsDeleted = 1      
 AND ISNULL(P.IsPermanentDeleted, 0) = 0      
 AND p.IsOfficeMaster = @PIsOfficeMaster      
 AND p.customerId = @PCustomerId  
      
END      
ELSE      
BEGIN      
CREATE TABLE #AccessibleProjectIds (      
 Projectid INT      
   ,ProjectAccessTypeId INT      
   ,IsProjectAccessible BIT      
   ,ProjectAccessTypeName NVARCHAR(100)      
   ,IsProjectOwner BIT      
);      
      
---Get all public,private and owned projects            
INSERT INTO #AccessibleProjectIds      
 SELECT      
  ps.Projectid      
    ,ps.ProjectAccessTypeId      
    ,0      
    ,''      
    ,IIF(ps.OwnerId = @PUserId, 1, 0)      
 FROM ProjectSummary ps WITH (NOLOCK)      
 WHERE (ps.ProjectAccessTypeId IN (1, 2)      
 OR ps.OwnerId = @PUserId)      
 AND ps.CustomerId = @PCustomerId      
      
--Update all public Projects as accessible            
UPDATE t      
SET t.IsProjectAccessible = 1      
FROM #AccessibleProjectIds t      
WHERE t.ProjectAccessTypeId = 1      
      
--Update all private Projects if they are accessible            
UPDATE t      
SET t.IsProjectAccessible = 1      
FROM #AccessibleProjectIds t      
INNER JOIN UserProjectAccessMapping u WITH (NOLOCK)      
 ON t.Projectid = u.ProjectId      
WHERE u.UserId = @PUserId      
AND u.IsActive = 1      
AND t.ProjectAccessTypeId = 2      
AND u.CustomerId = @PCustomerId      
      
--Get all accessible projects            
INSERT INTO #AccessibleProjectIds      
 SELECT      
  ps.Projectid      
    ,ps.ProjectAccessTypeId      
    ,1      
    ,''      
    ,IIF(ps.OwnerId = @PUserId, 1, 0)      
 FROM ProjectSummary ps WITH (NOLOCK)      
 INNER JOIN UserProjectAccessMapping upam WITH (NOLOCK)      
  ON upam.ProjectId = ps.ProjectId      
   AND upam.CustomerId = ps.CustomerId      
 LEFT OUTER JOIN #AccessibleProjectIds t      
  ON t.Projectid = ps.ProjectId      
 WHERE ps.ProjectAccessTypeId = 3      
 AND upam.UserId = @PUserId      
 AND t.Projectid IS NULL      
 AND ps.CustomerId = @PCustomerId      
 AND (upam.IsActive = 1      
 OR ps.OwnerId = @PUserId)      
      
      
UPDATE t      
SET t.IsProjectAccessible = t.IsProjectOwner      
FROM #AccessibleProjectIds t      
WHERE t.IsProjectOwner = 1      
      
INSERT INTO #projectList      
 SELECT      
  p.ProjectId      
    ,LTRIM(RTRIM(p.[Name])) AS [Name]      
    ,p.ModifiedBy      
    ,p.ModifiedDate      
    ,p.ModifiedByFullName      
    ,psm.projectAccessTypeId      
    ,t.isProjectAccessible      
    ,t.projectAccessTypeName      
 FROM Project AS p WITH (NOLOCK)      
 INNER JOIN [ProjectSummary] psm WITH (NOLOCK)      
  ON psm.ProjectId = p.ProjectId      
 INNER JOIN #AccessibleProjectIds t      
  ON t.Projectid = p.ProjectId      
 WHERE p.IsDeleted = 1      
 AND ISNULL(P.IsPermanentDeleted, 0) = 0      
 AND p.IsOfficeMaster = @PIsOfficeMaster      
 AND p.customerId = @PCustomerId  
END      
      
UPDATE t      
SET t.ProjectAccessTypeName = pt.Name      
FROM #projectList t      
INNER JOIN LuProjectAccessType pt WITH (NOLOCK)      
 ON t.ProjectAccessTypeId = pt.ProjectAccessTypeId;      
      
SELECT      
 ProjectId AS ProjectID      
   ,[Name] AS ProjectName      
   ,ModifiedBy AS DeletedBy      
   ,ModifiedDate AS DeletedOn      
   ,ModifiedByFullName AS DeletedByName      
   ,ProjectAccessTypeId      
   ,IsProjectAccessible      
   ,ProjectAccessTypeName      
FROM #projectList pl      
END
GO
PRINT N'Altering [dbo].[usp_GetExistingProjects]...';


GO
ALTER PROCEDURE [dbo].[usp_GetExistingProjects]          
(              
  @CustomerId INT,-- = 8,              
  @UserId INT,-- = 92,              
  @ParticipantEmailId NVARCHAR(MAX),-- = 'ALL',              
  @IsDesc BIT,-- = 1,              
  @PageNo INT,-- = 1,              
  @PageSize INT,-- = 15,              
  @ColName NVARCHAR(MAX),-- = 'CreateDate',              
  @SearchField NVARCHAR(MAX),-- = 'ALL',              
  @IsOfficeMaster BIT = 0,        
  @IsSystemManager BIT=0        
)              
AS              
BEGIN        
            
  DECLARE @PCustomerId INT = @CustomerId;        
  DECLARE @PUserId INT = @UserId;        
  DECLARE @PParticipantEmailId NVARCHAR(MAX) = @ParticipantEmailId;        
  DECLARE @PIsDesc BIT = @IsDesc;        
  DECLARE @PPageNo INT = @PageNo;        
  DECLARE @PPageSize INT = @PageSize;        
  DECLARE @PColName NVARCHAR(MAX) = @ColName;        
  DECLARE @PSearchField NVARCHAR(MAX) = @SearchField;        
  DECLARE @PIsOfficeMaster BIT = @IsOfficeMaster;        
  DECLARE @PIsSystemManager BIT = @IsSystemManager;        
        
 IF @PSearchField = 'ALL'              
 BEGIN        
SET @PSearchField = '';        
 END        
        
 CREATE TABLE #accesibleProjectIdList (        
 ProjectId INT        
   ,[Name] NVARCHAR(MAX)        
   ,IsOfficeMaster BIT        
   ,MasterDataTypeId INT        
   ,LastAccessed DATETIME2        
   ,ProjectAccessTypeId INT        
   ,IsProjectAccessible BIT        
   ,IsProjectOwner BIT        
   ,ProjectAccessTypeName NVARCHAR(100)        
   ,ProjectOwnerId INT        
   ,IsMigrated BIT         
   ,HasMigrationError BIT DEFAULT 0          
)        
        
 if(@PIsSystemManager=0)        
 BEGIN        
 INSERT INTO #accesibleProjectIdList        
 SELECT        
  P.ProjectId        
    ,P.[Name]        
    ,P.IsOfficeMaster        
    ,ISNULL(P.MasterDataTypeId, 0) AS MasterDataTypeId        
    ,UF.LastAccessed --, COALESCE(UF.UserId, 0) AS LastAccessUserId          
    ,ProjectAccessTypeId        
    ,IIF(ProjectAccessTypeId = 1, 1, 0) AS IsProjectAccessible        
    ,IIF(OwnerId = @PUserId, 1, 0) AS IsProjectOwner        
    ,''        
    ,COALESCE(PS.OwnerId,0) AS ProjectOwnerId        
 ,P.IsMigrated          
   ,0 as HasMigrationError       
 FROM Project P WITH (NOLOCK)        
 LEFT JOIN ProjectSummary PS WITH (NOLOCK)        
  ON P.ProjectId = PS.ProjectId        
 INNER JOIN UserFolder UF WITH (NOLOCK)        
  ON UF.ProjectId = P.ProjectId        
 WHERE P.CustomerID = @PCustomerId        
 and ISNULL(p.IsDeleted,0)=0 AND ISNULL(P.IsArchived,0)=0  
        
 UPDATE ap        
 SET ap.IsProjectAccessible = 1        
 FROM UserProjectAccessMapping UM WITH (NOLOCK)      
 INNER JOIN #accesibleProjectIdList ap        
  ON ap.projectId = um.projectId        
 WHERE UM.IsActive = 1        
 AND UM.customerId = @PCustomerId        
 AND UserId = @PUserId        
END        
        
IF (@PIsSystemManager = 1)        
BEGIN        
        
 INSERT INTO #accesibleProjectIdList        
 SELECT        
  P.ProjectId        
    ,P.[Name]        
    ,P.IsOfficeMaster        
    ,ISNULL(P.MasterDataTypeId, 0) AS MasterDataTypeId        
    ,UF.LastAccessed        
    ,ProjectAccessTypeId        
    ,1 AS IsProjectAccessible        
    ,IIF(OwnerId = @PUserId, 1, 0) AS IsProjectOwner        
    ,''        
    ,COALESCE(PS.OwnerId,0) AS ProjectOwnerId           
 ,P.IsMigrated          
   ,0 as HasMigrationError       
 FROM Project P WITH (NOLOCK)        
 LEFT JOIN ProjectSummary PS WITH (NOLOCK)        
  ON P.ProjectId = PS.ProjectId        
 INNER JOIN UserFolder UF WITH (NOLOCK)        
  ON UF.ProjectId = P.ProjectId        
 WHERE P.CustomerID = @PCustomerId        
 and ISNULL(p.IsDeleted,0)=0 and ISNULL(P.IsArchived,0)=0  
        
END        
        
update t        
set t.ProjectAccessTypeName=l.Name        
from #accesibleProjectIdList t inner join LuProjectAccessType l WITH(NOLOCK)        
on l.ProjectAccessTypeId=t.ProjectAccessTypeId        
        
update #accesibleProjectIdList        
set IsProjectAccessible=IsProjectOwner        
where IsProjectOwner=1        
        
DECLARE  @allProjectCount INT = COALESCE((SELECT                
    COUNT(P.ProjectId)                
   FROM Project AS P WITH (NOLOCK)             
   inner JOIN #accesibleProjectIdList t                
   ON t.Projectid=p.ProjectId                
   WHERE P.IsDeleted = 0                
   AND P.IsOfficeMaster = @PIsOfficeMaster                
   AND P.customerId = @PCustomerId  
   AND (IsProjectAccessible=1 or ProjectAccessTypeId=2 or IsProjectOwner=1)              
   AND (@PSearchField IS NULL OR P.[Name] LIKE '%' + COALESCE(@PSearchField, P.[Name]) + '%')            
   )                
  , 0);          
        
  UPDATE P        
SET P.HasMigrationError = 1        
FROM #accesibleProjectIdList P        
INNER JOIN ProjectMigrationException PME WITH (NOLOCK)        
 ON PME.ProjectId = P.ProjectId        
WHERE ISNULL(P.IsMigrated, 0) = 1 AND ISNULL(IsResolved,0)=0    
      
SELECT *,@allProjectCount AS allProjectCount        
 FROM #accesibleProjectIdList         
WHERE IsOfficeMaster = @IsOfficeMaster         
and (IsProjectAccessible=1 or ProjectAccessTypeId=2 or IsProjectOwner=1)   
AND [Name] LIKE '%' + REPLACE(@PSearchField, '_', '[_]') + '%'        
ORDER BY CASE        
 WHEN @PIsDesc = 1 THEN CASE        
   WHEN LOWER(@PColName) = 'name' THEN [Name]        
  END        
END DESC,        
CASE        
 WHEN @PIsDesc = 1 THEN CASE        
   WHEN LOWER(@PColName) = 'createdate' THEN LastAccessed        
  END        
END DESC,        
CASE        
 WHEN @PIsDesc = 0 THEN CASE        
   WHEN LOWER(@PColName) = 'name' THEN [Name]        
  END        
END,        
CASE        
 WHEN @PIsDesc = 0 THEN CASE        
   WHEN LOWER(@PColName) = 'createdate' THEN LastAccessed        
  END        
END        
OFFSET @PPageSize * (@PPageNo - 1) ROWS        
FETCH NEXT @PPageSize ROWS ONLY;        
END
GO
PRINT N'Altering [dbo].[usp_GetLimitAccessProjectList]...';


GO
ALTER PROCEDURE [dbo].[usp_GetLimitAccessProjectList]          
(          
 @UserId INT,          
 @LoggedUserId INT,          
 @CustomerId INT,          
 @IsSystemManager BIT,          
 @SearchText NVARCHAR(100)          
)          
AS          
BEGIN          
 DECLARE @PsearchField NVARCHAR(100) = REPLACE(@SearchText, '_', '[_]')         
 SET @PsearchField = REPLACE(@PSearchField, '%', '[%]')            
        
 IF(@IsSystemManager=1)          
 BEGIN          
  SELECT distinct P.Name,          
  PS.ProjectAccessTypeId,          
  P.ProjectId,          
  CAST(IIF(UPAM.ProjectId IS NOT NULL AND UPAM.IsActive=1 ,1,0) as BIT) AS IsSelected,          
  CAST(IIF(PS.OwnerId=@UserId,1,0) AS BIT) as IsProjectOwner          
  ,P.IsMigrated         
  ,CONVERT( bit,0) AS HasMigrationError       
  INTO #LimitAccessProjectListSM      
  FROM Project P WITH(NOLOCK)           
  INNER JOIN ProjectSummary PS WITH(NOLOCK)          
  ON P.ProjectId=PS.ProjectId           
  LEFT OUTER JOIN UserProjectAccessMapping UPAM WITH(NOLOCK)          
  ON UPAM.ProjectId=P.ProjectId          
  AND UPAM.UserId=@UserId AND P.CustomerId=UPAM.CustomerId          
  WHERE ISNULL(P.IsDeleted,0)=0 AND ISNULL(P.IsArchived,0)=0 
  AND P.CustomerId=@CustomerId           
  AND (ISNULL(PS.ProjectAccessTypeId,1)!=1)          
  AND (@PSearchField IS NULL OR P.[Name] LIKE '%' + COALESCE(@PSearchField, P.[Name]) + '%')          
      
 UPDATE P          
 SET P.HasMigrationError = 1          
 FROM #LimitAccessProjectListSM P          
 INNER JOIN ProjectMigrationException PME WITH (NOLOCK)          
 ON PME.ProjectId = P.ProjectId          
 WHERE ISNULL(P.IsMigrated, 0) = 1 AND ISNULL(IsResolved,0)=0    
 SELECT * FROM #LimitAccessProjectListSM     
 END          
 ELSE          
 BEGIN          
  SELECT distinct P.Name,PS.ProjectAccessTypeId,P.ProjectId,          
  CAST(IIF(UPAM.ProjectId IS NOT NULL and UPAM.IsActive=1 ,1,0) AS BIT) AS IsSelected,          
  CAST(IIF(PS.OwnerId=@UserId,1,0) AS BIT) as IsProjectOwner          
  ,P.IsMigrated         
  ,CONVERT( bit,0) AS HasMigrationError       
  INTO #LimitAccessProjectList      
  FROM Project P WITH(NOLOCK)           
  INNER JOIN ProjectSummary PS WITH(NOLOCK)          
  ON P.ProjectId=PS.ProjectId          
  LEFT OUTER JOIN UserProjectAccessMapping UPAM WITH(NOLOCK)          
  ON UPAM.ProjectId=P.ProjectId           
  AND UPAM.UserId=@UserId AND P.CustomerId=UPAM.CustomerId          
  WHERE ISNULL(P.IsDeleted,0)=0 AND ISNULL(P.IsArchived,0)=0 AND PS.OwnerId=@LoggedUserId    
  AND P.CustomerId=@CustomerId           
  AND (ISNULL(PS.ProjectAccessTypeId,1)!=1)          
  AND (@PSearchField IS NULL OR P.[Name] LIKE '%' + COALESCE(@PSearchField, P.[Name]) + '%')          
      
  UPDATE P          
 SET P.HasMigrationError = 1          
 FROM #LimitAccessProjectList P          
 INNER JOIN ProjectMigrationException PME WITH (NOLOCK)          
 ON PME.ProjectId = P.ProjectId          
 WHERE ISNULL(P.IsMigrated, 0) = 1   AND ISNULL(IsResolved,0)=0    
 SELECT * FROM #LimitAccessProjectList      
 END          
END
GO
PRINT N'Altering [dbo].[usp_GetNotificationProgress]...';


GO
ALTER PROCEDURE [dbo].[usp_GetNotificationProgress]
 @UserId int,  
 @RequestIdList nvarchar(100)='',  
 @CustomerId int,  
 @CopyProject BIT=0,  
 @ImportSection BIT=0,
 @unArchiveProject BIT=0
AS  
BEGIN  
 --find and mark as failed copy project requests which running loner(more than 30 mins)  
 --EXEC usp_UpdateLongRunningRequestsASFailed  
 DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())  
 DECLARE @RES AS TABLE(RequestId INT,SourceProjectId INT,TargetProjectId INT,TargetSectionId INT,  
       RequestDateTime DATETIME,RequestDateTimeStr NVARCHAR(20),RequestExpiryDateTime DATETIME,  
       StatusId INT,IsNotify BIT,CompletedPercentage INT,[Source] NVARCHAR(200),  
       TaskName nvarchar(500),StatusDescription nvarchar(50),IsOfficeMaster BIT,RequestTypeId INT)
  
 IF(@CopyProject=1)  
 BEGIN  
  INSERT INTO @RES  
  SELECT  CPR.RequestId  
  ,CPR.SourceProjectId    
  ,CPR.TargetProjectId    
  ,0  AS TargetSectionId  
  ,CPR.CreatedDate  AS RequestDateTime   
  ,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr  
  ,DATEADD(DAY,30,CPR.CreatedDate) AS RequestExpiryDateTime    
  ,CPR.StatusId    
  ,CPR.IsNotify    
  ,CPR.CompletedPercentage    
  ,'CopyProject' AS [Source]  
  ,CONVERT(nvarchar(500),'') AS TaskName  
  ,CONVERT(nvarchar(50),'') AS StatusDescription  
  ,0
  ,0
  FROM CopyProjectRequest CPR WITH (NOLOCK)  
  WHERE CPR.CreatedById = @UserId AND CPR.IsNotify = 0  
  AND ISNULL(CPR.IsDeleted, 0) = 0    
  AND CPR.CreatedDate> @DateBefore30Days    
    
  UPDATE t  
  SET t.TaskName=P.Name ,
	  t.IsOfficeMaster=P.IsOfficeMaster
  FROM @RES t INNER JOIN Project P WITH(NOLOCK)   
  ON P.ProjectId=t.TargetProjectId  
  WHERE P.CustomerId=@CustomerId  

  UPDATE CPR  
   SET CPR.IsNotify = 1  
   ,ModifiedDate = GETUTCDATE()  
    FROM CopyProjectRequest CPR WITH (NOLOCK)  
	INNER JOIN @RES t  
	ON CPR.RequestId = t.RequestId  
	WHERE CPR.IsNotify = 0   
 END  
  
 IF(@unArchiveProject=1)  
 BEGIN  
  INSERT INTO @RES  
  SELECT CPR.RequestId            
 ,0 AS SourceProjectId    
 ,CPR.SLCProd_ProjectId as TargetProjectId    
 ,0 as TargetSectionId       
 ,CPR.RequestDate AS RequestDateTime           
 ,FORMAT(CPR.RequestDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr  
 ,DATEADD(DAY,30,CPR.RequestDate) AS RequestExpiryDateTime            
 ,CPR.StatusId            
 ,CPR.IsNotify            
 ,CPR.ProgressInPercentage as CompletedPercentage         
 ,'UnArchiveProject' as Source  
 ,CPR.ProjectName AS TaskName  
 ,CONVERT(nvarchar(50),'') AS StatusDescription  
 ,0  
 ,CPR.RequestType
  FROM UnArchiveProjectRequest CPR WITH(NOLOCK)           
  WHERE CPR.SLC_UserId=@UserId AND CPR.IsNotify = 0
  AND ISNULL(CPR.IsDeleted,0)=0         
  AND CPR.RequestDate> @DateBefore30Days    
    
  UPDATE t  
  SET t.TaskName=P.Name ,
	  t.IsOfficeMaster=P.IsOfficeMaster
  FROM @RES t INNER JOIN Project P WITH(NOLOCK)   
  ON P.ProjectId=t.TargetProjectId  
  WHERE P.CustomerId=@CustomerId  

  UPDATE CPR  
   SET CPR.IsNotify = 1  
   ,ModifiedDate = GETUTCDATE()  
    FROM UnArchiveProjectRequest CPR WITH (NOLOCK)  
	INNER JOIN @RES t  
	ON CPR.RequestId = t.RequestId  
	WHERE CPR.IsNotify = 0   
	AND t.[Source]='unArchiveProject'
 END 

 IF(@ImportSection=1)  
 BEGIN  
  INSERT INTO @RES  
  SELECT CPR.RequestId    
  ,CPR.SourceProjectId    
  ,CPR.TargetProjectId    
  ,CPR.TargetSectionId   
  ,CPR.CreatedDate AS RequestDateTime   
  ,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr  
  ,DATEADD(DAY,30,CPR.CreatedDate) AS RequestExpiryDateTime    
  ,CPR.StatusId    
  ,CPR.IsNotify    
  ,CPR.CompletedPercentage     
  ,CPR.Source  
  ,CONVERT(nvarchar(500),'') AS TaskName  
  ,CONVERT(nvarchar(50),'') AS StatusDescription 
  ,0
  ,0
   FROM ImportProjectRequest CPR WITH(NOLOCK)   
   WHERE CPR.CreatedById=@UserId AND [Source] IN('SpecAPI','Import from Template')   
   AND ISNULL(CPR.IsDeleted,0)=0     
   AND CPR.IsNotify=0  
   AND CPR.CreatedDate> @DateBefore30Days    
  
  UPDATE t  
  SET t.TaskName=PS.Description  
  FROM @RES t INNER JOIN ProjectSection PS WITH(NOLOCK)       
  ON t.TargetSectionId=PS.SectionId  
  WHERE PS.CustomerId=@CustomerId  
  AND t.[Source] IN('SpecAPI','Import from Template')  

   UPDATE CPR  
	SET CPR.IsNotify = 1  
    ,ModifiedDate = GETUTCDATE()  
	FROM ImportProjectRequest CPR WITH (NOLOCK)  
	INNER JOIN @RES t  
	ON CPR.RequestId = t.RequestId  
	--AND CPR.[Source]=t.[Source]  
	WHERE CPR.IsNotify = 0   
 END   
  
 UPDATE t  
 SET t.StatusDescription=LCS.StatusDescription  
 FROM @RES t INNER JOIN LuCopyStatus LCS WITH(NOLOCK)       
 ON t.StatusId=LCS.CopyStatusId  
  
 SELECT * FROM @RES  
 ORDER BY RequestDateTimeStr DESC  
  
  
END
GO
PRINT N'Altering [dbo].[usp_GetProjectById]...';


GO
ALTER PROC [dbo].[usp_GetProjectById]
(
	@ProjectId INT
)
AS
BEGIN
SELECT
	p.ProjectId
   ,p.Name
   ,p.IsOfficeMaster
   ,ISNULL(p.TemplateId, 0) AS TemplateId
   ,p.MasterDataTypeId
   ,p.UserId
   ,p.CustomerId
   ,ps.SpecViewModeId
   ,ISNULL(p.CreateDate, GETUTCDATE()) AS CreateDate
   ,ISNULL(p.CreatedBy, 0) AS CreatedBy
   ,ISNULL(p.ModifiedBy, 0) AS ModifiedBy
   ,ISNULL(p.ModifiedDate, GETUTCDATE()) AS ModifiedDate
   ,ISNULL(p.IsDeleted, 0) AS IsDeleted
   ,ISNULL(p.IsMigrated, 0) AS IsMigrated
   ,ISNULL(p.IsLocked,0) AS IsLocked  
   ,ISNULL(p.IsPermanentDeleted, 0) AS IsPermanentDeleted
   ,ISNULL(p.ModifiedByFullName,'') As ModifiedByFullName
FROM Project p WITH(NOLOCK) inner join ProjectSummary ps with(nolock)
ON p.ProjectId=ps.ProjectId
WHERE p.ProjectId = @ProjectId
END
GO
PRINT N'Altering [dbo].[usp_GetProjectForImportSection]...';


GO
ALTER PROCEDURE usp_GetProjectForImportSection(
 @PageSize INT = 25,
 @PageNumber INT = 1,
 @IsOfficeMaster BIT,
 @TargetProjectId INT = 0,
 @CustomerId INT,
 @SearchName NVARCHAR(MAX) = NULL,
 @UserId INT,
 @IsSystemManager BIT = 0
)
AS
BEGIN

	DECLARE @PPageSize INT = @PageSize;
	DECLARE @PPageNumber INT = @PageNumber;
	DECLARE @PIsOfficeMaster BIT = @IsOfficeMaster;
	DECLARE @PTargetProjectId INT = @TargetProjectId;
	DECLARE @PCustomerId INT = @CustomerId;
	DECLARE @PUserId INT = @UserId;
	DECLARE @PSearchName NVARCHAR(MAX) = @SearchName;
	DECLARE @PIsSystemManager BIT = @IsSystemManager;

	-- Project Access Type constants
	DECLARE @PublicProjectAccess TINYINT = 1, @PrivateProjectAccess TINYINT = 2, @HiddenProjectAccess TINYINT = 3;

	DROP TABLE IF EXISTS #ProjectForImportSection;
	
	DECLARE @MasterDataTypeId INT = 0;
	SET @MasterDataTypeId = (SELECT TOP 1 P.MasterDataTypeId FROM Project P WITH (NOLOCK) WHERE P.ProjectId = @PTargetProjectId)
                              
	IF @PSearchName = ''
	BEGIN
		SET @PSearchName = NULL;
	END

	CREATE TABLE #ProjectForImportSection (
		ProjectId INT
	   ,[Name] NVARCHAR(500)
	   ,IsOfficeMaster BIT
	   ,CustomerId INT
	   ,ModifiedDate DATETIME2
	   ,OpenSectionCount INT
	   ,IsMigrated BIT
	   ,HasMigrationError BIT
	);

	IF (@PIsSystemManager = 0)
	BEGIN

		CREATE TABLE #AccessibleProjectIds (
			ProjectId INT
		   ,ProjectAccessTypeId INT
		   ,IsProjectAccessible BIT
		   ,ProjectAccessTypeName NVARCHAR(100)
		   ,IsProjectOwner BIT
		);
	      
		-- Get all public,private and owned projects                                  
		INSERT INTO #AccessibleProjectIds (ProjectId, ProjectAccessTypeId, IsProjectAccessible, ProjectAccessTypeName, IsProjectOwner)                  
		 SELECT                  
		  PS.ProjectId  
		 ,PS.ProjectAccessTypeId  
		 ,IIF(PS.ProjectAccessTypeId = @PublicProjectAccess, 1, 0) AS IsProjectAccessible
		 ,'' AS ProjectAccessTypeName  
		 ,IIF(ps.OwnerId = @PUserId, 1, 0)  
		 FROM ProjectSummary PS WITH (NOLOCK)  
		 WHERE PS.CustomerId = @PCustomerId  
		 AND (PS.ProjectAccessTypeId IN (@PublicProjectAccess, @PrivateProjectAccess) OR PS.OwnerId = @PUserId);

		-- Update all private Projects if they are accessible                                  
		UPDATE AP
		SET AP.IsProjectAccessible = 1  
		FROM #AccessibleProjectIds AP                 
		INNER JOIN UserProjectAccessMapping UPAM WITH (NOLOCK) 
			ON AP.ProjectId = AP.ProjectId 
			   AND AP.ProjectAccessTypeId = @PrivateProjectAccess
			   AND UPAM.CustomerId = @PCustomerId  
			   AND UPAM.UserId = @PUserId
			   AND UPAM.IsActive = 1
			   AND AP.ProjectAccessTypeId = @PrivateProjectAccess;  
                  
		-- Get all accessible projects                                  
		INSERT INTO #AccessibleProjectIds (ProjectId, ProjectAccessTypeId, IsProjectAccessible, ProjectAccessTypeName, IsProjectOwner)                  
		 SELECT
		  PS.ProjectId  
		 ,PS.ProjectAccessTypeId  
		 ,1 AS IsProjectAccessible  
		 ,'' AS ProjectAccessTypeName  
		 ,IIF(ps.OwnerId = @PUserId, 1, 0) AS IsProjectOwner
		 FROM ProjectSummary PS WITH (NOLOCK)                
		 INNER JOIN UserProjectAccessMapping UPAM WITH (NOLOCK)                  
		  ON UPAM.ProjectId = PS.ProjectId                  
		 LEFT OUTER JOIN #AccessibleProjectIds AP               
		  ON AP.ProjectId = PS.ProjectId
		 WHERE PS.CustomerId = @PCustomerId  
		 AND UPAM.UserId = @PUserId        
		 AND PS.ProjectAccessTypeId = @HiddenProjectAccess
		 AND AP.Projectid IS NULL
		 AND (UPAM.IsActive = 1 OR PS.OwnerId = @PUserId)  

		-- Insert Projects into temp table
		INSERT INTO #ProjectForImportSection
		SELECT
			 P.ProjectId
			,LTRIM(RTRIM(P.[Name])) AS [Name]
			,P.IsOfficeMaster
			,P.CustomerId AS CustomerId
			,UF.LastAccessed AS ModifiedDate
			,0 AS OpenSectionCount
			,ISNULL(P.IsMigrated, 0) AS IsMigrated
			,CONVERT(BIT,0) AS HasMigrationError
		FROM Project AS P WITH (NOLOCK)
		INNER JOIN UserFolder UF WITH (NOLOCK)
			ON UF.CustomerId = P.CustomerId AND UF.ProjectId = P.ProjectId
		INNER JOIN #AccessibleProjectIds AP ON AP.Projectid = P.ProjectId
		WHERE P.CustomerId = @PCustomerId
		AND P.IsOfficeMaster = @PIsOfficeMaster
		AND P.MasterDataTypeId = @MasterDataTypeId
		AND ISNULL(P.IsDeleted,0)=0
		AND ISNULL(P.IsArchived,0)=0
		AND ISNULL(P.IsPermanentDeleted, 0) = 0
		AND P.ProjectId != @PTargetProjectId
		AND (@PSearchName IS NULL OR P.[Name] LIKE '%' + COALESCE(@PSearchName, P.[Name]) + '%');

	END
	
	IF (@PIsSystemManager = 1)
	BEGIN

		-- Insert Projects into temp table
		INSERT INTO #ProjectForImportSection
		SELECT
			 P.ProjectId
			,LTRIM(RTRIM(P.[Name])) AS [Name]
			,P.IsOfficeMaster
			,P.CustomerId AS CustomerId
			,UF.LastAccessed AS ModifiedDate
			,0 AS OpenSectionCount
			,ISNULL(P.IsMigrated, 0) AS IsMigrated
			,CONVERT(BIT,0) AS HasMigrationError
		FROM Project AS P WITH (NOLOCK)
		INNER JOIN UserFolder UF WITH (NOLOCK)
			ON-- UF.CustomerId = P.CustomerId AND 
			UF.ProjectId = P.ProjectId
		WHERE P.CustomerId = @PCustomerId
		AND P.IsOfficeMaster = @PIsOfficeMaster
		AND P.MasterDataTypeId = @MasterDataTypeId
		AND ISNULL(P.IsDeleted,0)=0
		AND ISNULL(P.IsArchived,0)=0
		AND ISNULL(P.IsPermanentDeleted, 0) = 0	
		AND P.ProjectId != @PTargetProjectId
		AND (@PSearchName IS NULL OR P.[Name] LIKE '%' + COALESCE(@PSearchName, P.[Name]) + '%');
	END

	UPDATE P
	SET P.HasMigrationError = 1
	FROM #ProjectForImportSection P
	INNER JOIN ProjectMigrationException PME WITH (NOLOCK)
		ON PME.ProjectId = P.ProjectId
	WHERE ISNULL(P.IsMigrated, 0) = 1 AND ISNULL(IsResolved,0) = 0;


	-- Select Project for import from project list
	SELECT P.ProjectId                
		  ,P.CustomerId                
		  ,P.[Name]                
		  ,P.IsOfficeMaster                
		  ,P.ModifiedDate
		  ,COUNT(PS.SectionId) AS OpenSectionCount                
		  ,P.IsMigrated
		  ,P.HasMigrationError
	FROM #ProjectForImportSection P
	INNER JOIN ProjectSection PS WITH (NOLOCK) ON PS.ProjectId = P.ProjectId
	INNER JOIN ProjectSegmentStatus PSS WITH (NOLOCK) ON PSS.SectionId = PS.SectionId
													 AND PSS.ProjectId = PS.ProjectId
													 AND PSS.CustomerId = @CustomerId
													 AND PSS.IndentLevel = 0
													 AND PSS.ParentSegmentStatusId = 0
													 AND PSS.SequenceNumber = 0
													 AND ISNULL(PSS.IsDeleted, 0) = 0
													 AND ISNULL(PS.IsDeleted, 0) = 0
	GROUP BY P.ProjectId
			,P.CustomerId
			,P.[Name]
			,P.IsOfficeMaster
			,P.ModifiedDate
			,P.IsMigrated
			,P.HasMigrationError
		HAVING COUNT(PS.SectionId) > 0
		ORDER BY P.ModifiedDate DESC
		OFFSET @PPageSize * (@PPageNumber - 1) ROWS                
		FETCH NEXT @PPageSize ROWS ONLY;

	DROP TABLE IF EXISTS #ProjectForImportSection;

END
GO
PRINT N'Altering [dbo].[usp_GetProjects]...';


GO

ALTER PROCEDURE [dbo].[usp_GetProjects]                                 
  @CustomerId INT NULL                                    
 ,@UserId INT NULL = NULL                                    
 ,@ParticipantEmailId NVARCHAR(255) NULL = NULL                                    
 ,@IsDesc BIT NULL = NULL                                    
 ,@PageNo INT NULL = 1                                    
 ,@PageSize INT NULL = 100                                    
 ,@ColName NVARCHAR(255) NULL = NULL                                    
 ,@SearchField NVARCHAR(255) NULL = NULL                                    
 ,@DisciplineId NVARCHAR(MAX) NULL = ''                                    
 ,@CatalogueType NVARCHAR(MAX) NULL = 'FS'                                    
 ,@IsOfficeMasterTab BIT NULL = NULL                                    
 ,@IsSystemManager BIT NULL = 0                                      
AS                                    
BEGIN                                  
                                  
  DECLARE @PCustomerId INT = @CustomerId;                                  
  DECLARE @PUserId INT = @UserId;                                  
  DECLARE @PParticipantEmailId NVARCHAR(255) = @ParticipantEmailId;                                  
  DECLARE @PIsDesc BIT = @IsDesc;                                  
  DECLARE @PPageNo INT = @PageNo;                                  
  DECLARE @PPageSize INT = @PageSize;                                  
  DECLARE @PColName NVARCHAR(255) = @ColName;                                  
  DECLARE @PSearchField NVARCHAR(255) = @SearchField;                                  
  DECLARE @PDisciplineId NVARCHAR(MAX) = @DisciplineId;                                  
  DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;                                  
  DECLARE @PIsOfficeMasterTab BIT = @IsOfficeMasterTab;                                  
  DECLARE @PIsSystemManager BIT = @IsSystemManager;                                  
  DECLARE @OpenCommentStatusId INT = 1                                
  DECLARE @Order AS INT = CASE @PIsDesc                                    
    WHEN 1                                    
  THEN - 1                                    
    ELSE 1                                    
    END;                                  
                                  
 SET @PsearchField = REPLACE(@PSearchField, '_', '[_]')            
 SET @PsearchField = REPLACE(@PSearchField, '%', '[%]')            
  DECLARE @isnumeric AS INT = ISNUMERIC(@PSearchField);                                  
  IF @PSearchField = ''                                  
 SET @PSearchField = NULL;                                  
                                  
 DECLARE @allProjectCount AS INT = 0;                                  
 DECLARE @deletedProjectCount AS INT = 0;                                  
 DECLARE @archivedProjectCount AS INT=0;                                 
 DECLARE @officeMasterCount AS INT = 0;                                  
 DECLARE @deletedOfficeMasterCount AS INT = 0;                     
 CREATE TABLE #projectList  (                                    
   ProjectId INT                                    
    ,[Name] NVARCHAR(255)                                    
    ,[Description] NVARCHAR(255)                                    
    ,IsOfficeMaster BIT                                    
    ,TemplateId INT                                    
    ,CustomerId INT                                    
    ,LastAccessed DATETIME2                                    
    ,UserId INT                                    
    ,CreateDate DATETIME2                                    
    ,CreatedBy INT                                    
    ,ModifiedBy INT                                    
    ,ModifiedDate DATETIME2                                    
    ,allProjectCount INT                                    
    ,officeMasterCount INT                                    
    ,deletedOfficeMasterCount INT                                    
    ,deletedProjectCount INT                                    
    ,archivedProjectCount INT                    
    ,MasterDataTypeId INT                                    
    ,SpecViewModeId INT                                    
    ,LastAccessUserId INT              
    ,IsDeleted BIT                                    
 ,IsArchived BIT                    
    ,IsPermanentDeleted BIT                                    
    ,UnitOfMeasureValueTypeId INT                                    
    ,ModifiedByFullName NVARCHAR(100)            
    ,ProjectAccessTypeId INT                                  
    ,IsProjectAccessible bit                                   
    ,ProjectAccessTypeName NVARCHAR(100)                                  
    ,IsProjectOwner BIT                                  
    ,ProjectOwnerId INT                     
 ,IsMigrated BIT         
 ,HasMigrationError BIT DEFAULT 0      
 ,IsLocked BIT DEFAULT 0      
 ,LockedBy NVARCHAR(500)     
 ,LockedDate DateTIme2(7)      
    )                                    
                                  
 IF(@PIsSystemManager=1)                                  
 BEGIN                                  
  SET @allProjectCount = COALESCE((SELECT                                  
    COUNT(P.ProjectId)                  
   FROM dbo.Project AS P WITH (NOLOCK)                                  
   WHERE P.customerId = @PCustomerId                                  
   AND ISNULL(P.IsDeleted,0) = 0                          
   and ISNULL(p.IsArchived,0)= 0                            
   AND P.IsOfficeMaster = @PIsOfficeMasterTab                                  
   AND (@PSearchField IS NULL OR P.[Name] LIKE '%' + COALESCE(@PSearchField, P.[Name]) + '%')                              
   )                                  
  , 0);                                  
                              
                    
                        
 SET @deletedProjectCount = COALESCE((SELECT                                  
    COUNT(P.ProjectId)                                  
   FROM dbo.Project AS P WITH (NOLOCK)      
  INNER JOIN [ProjectSummary] psm WITH (NOLOCK)      
  ON psm.ProjectId = P.ProjectId   
   WHERE ISNULL(P.IsOfficeMaster, 0) = @PIsOfficeMasterTab                                  
   AND ISNULL(P.IsDeleted, 0) = 1                                  
   AND P.customerId = @PCustomerId                                  
   AND ISNULL(P.IsPermanentDeleted, 0) = 0)                                  
  , 0);                                 
                       
                       
    SET @archivedProjectCount = COALESCE((SELECT                                  
    COUNT(P.ProjectId)                                  
   FROM dbo.Project AS P WITH (NOLOCK)                                  
   WHERE ISNULL(P.IsOfficeMaster, 0) = @PIsOfficeMasterTab                                  
   AND  ISNULL(p.IsArchived,0)=1                    
   AND ISNULL(P.IsDeleted,0)=0                               
   AND P.customerId = @PCustomerId                                  
   ) , 0);                     
                    
                    
  SET @officeMasterCount = @allProjectCount;                                  
  SET @deletedOfficeMasterCount = @deletedProjectCount;                                  
                    
  INSERT INTO #projectList                                  
   SELECT                                  
    p.ProjectId                                  
      ,LTRIM(RTRIM(p.[Name])) AS [Name]                                  
      ,p.[Description]                                  
      ,p.IsOfficeMaster                                  
      ,COALESCE(p.TemplateId, 1) TemplateId                                  
      ,p.customerId                                  
      ,UF.LastAccessed                                  
      ,p.UserId                                  
      ,p.CreateDate                                  
      ,p.CreatedBy                                  
      ,p.ModifiedBy                                  
      ,p.ModifiedDate        
      ,@allProjectCount AS allprojectcount                                  
      ,@officeMasterCount AS officemastercount                                  
      ,@deletedOfficeMasterCount AS deletedOfficeMasterCount                                  
      ,@deletedProjectCount AS deletedProjectCount                                  
      ,@archivedProjectCount AS archiveprojectCount                    
   ,p.MasterDataTypeId                                  
      ,COALESCE(psm.SpecViewModeId, 0) AS SpecViewModeId                                  
      ,COALESCE(UF.UserId, 0) AS lastaccessuserid                  
      ,p.IsDeleted                    
   ,p.IsArchived                                  
      ,COALESCE(p.IsPermanentDeleted, 0) AS IsPermanentDeleted                                  
      ,psm.UnitOfMeasureValueTypeId                                  
      ,COALESCE(UF.LastAccessByFullName, 'NA') AS ModifiedByFullName                    
      ,psm.projectAccessTypeId                                  
      ,1 as isProjectAccessible                                  
      ,'' as projectAccessTypeName                                  
      ,iif(psm.OwnerId=@UserId,1,0) as IsProjectOwner                                  
      ,COALESCE(psm.OwnerId,0) AS ProjectOwnerId           
   ,P.IsMigrated        
   ,0 AS HasMigrationError                      
   ,ISNULL(P.IsLocked,0) as IsLocked    
   ,ISNULL(P.LockedBy,'') as   LockedBy   
   ,ISNULL(P.LockedDate,'') as  LockedDate     
   FROM dbo.Project AS p WITH (NOLOCK)                                  
   INNER JOIN [dbo].[ProjectSummary] psm WITH (NOLOCK)                                  
    ON psm.ProjectId = p.ProjectId                                  
   LEFT JOIN UserFolder UF WITH (NOLOCK)                                  
    ON UF.ProjectId = P.ProjectId                                  
     AND UF.customerId = p.customerId                                  
   WHERE ISNULL(p.IsDeleted,0)= 0               
   and ISNULL(p.IsArchived,0)= 0                        
   AND p.IsOfficeMaster = @PIsOfficeMasterTab                                  
   AND p.customerId = @PCustomerId                      
   AND (@PSearchField IS NULL OR p.[Name] LIKE '%' + COALESCE(@PSearchField, p.[Name]) + '%')                                  
   ORDER BY CASE                                  
    WHEN @PIsDesc = 1 THEN CASE                                  
      WHEN LOWER(@PColName) = 'name' THEN P.Name                                  
     END                       END DESC                                  
   , CASE                                  
    WHEN @PIsDesc = 1 THEN CASE                                  
      WHEN LOWER(@PColName) = 'Id' THEN P.[ProjectId]                                  
     END                                  
   END DESC                                  
   , CASE                                  
    WHEN @PIsDesc = 1 THEN CASE                                  
      WHEN LOWER(@PColName) = 'createdate' THEN UF.LastAccessed                                  
     END                                  
   END DESC                                  
   , CASE                                  
    WHEN @PIsDesc = 0 THEN CASE                                  
      WHEN LOWER(@PColName) = 'name' THEN P.Name                                  
     END                                  
   END                                  
   , CASE                                  
    WHEN @PIsDesc = 0 THEN CASE                                  
      WHEN LOWER(@PColName) = 'Id' THEN P.[ProjectId]                                  
     END                                  
   END                                  
   , CASE                                  
    WHEN @PIsDesc = 0 THEN CASE                                  
      WHEN LOWER(@PColName) = 'createdate' THEN UF.LastAccessed                                  
     END                                  
   END OFFSET @PPageSize * (@PPageNo - 1) ROWS                                 
                                  
   FETCH NEXT @PPageSize ROWS ONLY;                                  
                                  
 END                                  
 ELSE                                  
 BEGIN                                  
  CREATE TABLE #AccessibleProjectIds(                                    
   Projectid INT,                                    
   ProjectAccessTypeId INT,                                    
   IsProjectAccessible bit,                                    
   ProjectAccessTypeName NVARCHAR(100)  ,                                  
   IsProjectOwner BIT                                  
  );                                  
                                    
  ---Get all public,private and owned projects                                  
  INSERT INTO #AccessibleProjectIds(Projectid  ,ProjectAccessTypeId,  IsProjectAccessible,ProjectAccessTypeName,IsProjectOwner)                            
  SELECT ps.Projectid,ps.ProjectAccessTypeId,0,'',iif(ps.OwnerId=@UserId,1,0) FROM ProjectSummary ps WITH(NOLOCK)                                      
  where  (ps.ProjectAccessTypeId in(1,2) or ps.OwnerId=@UserId)                                  
  AND ps.CustomerId=@PCustomerId         
                              
  --Update all public Projects as accessible                                  
  UPDATE t                                  
  set t.IsProjectAccessible=1                                  
  from #AccessibleProjectIds t                                   
  where t.ProjectAccessTypeId=1                                  
                                  
  --Update all private Projects if they are accessible                                  
  UPDATE t        set t.IsProjectAccessible=1                                  
  from #AccessibleProjectIds t                                   
  inner join UserProjectAccessMapping u WITH(NOLOCK)                                  
  ON t.Projectid=u.ProjectId                                        
  where u.IsActive=1                                   
  and u.UserId=@UserId and t.ProjectAccessTypeId=2                                  
  AND u.CustomerId=@PCustomerId                                      
                                  
  --Get all accessible projects                                  
  INSERT INTO #AccessibleProjectIds  (Projectid  ,ProjectAccessTypeId,  IsProjectAccessible,ProjectAccessTypeName,IsProjectOwner)                            
  SELECT ps.Projectid,ps.ProjectAccessTypeId,1,'',iif(ps.OwnerId=@UserId,1,0) FROM ProjectSummary ps WITH(NOLOCK)                                   
  INNER JOIN UserProjectAccessMapping upam WITH(NOLOCK)                                  
  ON upam.ProjectId=ps.ProjectId                                
  LEFT outer JOIN #AccessibleProjectIds t                                  
  ON t.Projectid=ps.ProjectId                                  
  where ps.ProjectAccessTypeId=3 AND upam.UserId=@UserId and t.Projectid is null AND ps.CustomerId=@PCustomerId                                  
  AND(  upam.IsActive=1 OR ps.OwnerId=@UserId)                                     
                                  
  UPDATE t                                  
  set t.IsProjectAccessible=t.IsProjectOwner                                  
  from #AccessibleProjectIds t                                   
  where t.IsProjectOwner=1                                  
                                  
  SET @allProjectCount = COALESCE((SELECT                                  
    COUNT(P.ProjectId)                                  
   FROM dbo.Project AS P WITH (NOLOCK)                                  
   inner JOIN #AccessibleProjectIds t                                  
   ON t.Projectid=p.ProjectId                                  
   WHERE ISNULL(P.IsDeleted,0) = 0                       
   AND ISNULL(p.IsArchived,0)= 0                               
   AND P.IsOfficeMaster = @PIsOfficeMasterTab              
   AND P.customerId = @PCustomerId                                  
   AND (@PSearchField IS NULL OR P.[Name] LIKE '%' + COALESCE(@PSearchField, P.[Name]) + '%')                              
   )                                
  , 0);                                  
                                   
  SET @deletedProjectCount = COALESCE((SELECT                                  
    COUNT(P.ProjectId)                                  
   FROM dbo.Project AS P WITH (NOLOCK)                                  
   inner JOIN #AccessibleProjectIds t                                  
   ON t.Projectid=p.ProjectId                                  
   WHERE ISNULL(P.IsOfficeMaster, 0) = @PIsOfficeMasterTab                                  
   AND ISNULL(P.IsDeleted, 0) = 1                                  
   AND P.customerId = @PCustomerId                                  
   AND ISNULL(P.IsPermanentDeleted, 0) = 0)                                  
  , 0);                                  
                                  
  SET @archivedProjectCount = COALESCE((SELECT                                  
    COUNT(P.ProjectId)                                  
   FROM dbo.Project AS P WITH (NOLOCK)                                  
   inner JOIN #AccessibleProjectIds t                                  
   ON t.Projectid=p.ProjectId                                  
   WHERE ISNULL(P.IsOfficeMaster, 0) = @PIsOfficeMasterTab                                  
   AND ISNULL(P.IsArchived, 0) = 1                        
   and ISNULL(p.IsDeleted,0)=0                              
   AND P.customerId = @PCustomerId )             
  , 0);                                  
                    
                    
                    
  SET @officeMasterCount = @allProjectCount;                                  
  SET @deletedOfficeMasterCount = @deletedProjectCount;                                  
                    
   INSERT INTO #projectList                                  
   SELECT                                  
    p.ProjectId                                  
      ,LTRIM(RTRIM(p.[Name])) AS [Name]                                  
      ,p.[Description]                                  
      ,p.IsOfficeMaster                                  
      ,COALESCE(p.TemplateId, 1) TemplateId                                  
      ,p.customerId                                  
      ,UF.LastAccessed                                  
      ,p.UserId                                  
      ,p.CreateDate                                  
      ,p.CreatedBy                                  
      ,p.ModifiedBy                                  
      ,p.ModifiedDate                                  
      ,@allProjectCount AS allprojectcount                             
      ,@officeMasterCount AS officemastercount                                  
      ,@deletedOfficeMasterCount AS deletedOfficeMasterCount                                  
      ,@deletedProjectCount AS deletedProjectCount                      
      ,@archivedProjectCount AS archiveProjectcount                      
      ,p.MasterDataTypeId                                  
      ,COALESCE(psm.SpecViewModeId, 0) AS SpecViewModeId                                  
      ,COALESCE(UF.UserId, 0) AS lastaccessuserid                                  
      ,p.IsDeleted                        
      ,p.IsArchived                              
      ,COALESCE(p.IsPermanentDeleted, 0) AS IsPermanentDeleted                                  
      ,psm.UnitOfMeasureValueTypeId                                  
      ,COALESCE(UF.LastAccessByFullName, 'NA') AS ModifiedByFullName                    
      ,psm.projectAccessTypeId                                  
      ,t.isProjectAccessible                                  
      ,t.projectAccessTypeName                                  
      ,iif(psm.OwnerId=@UserId,1,0) as IsProjectOwner                                  
      ,COALESCE(psm.OwnerId,0) AS ProjectOwnerId                 
   ,P.IsMigrated        
      ,0 AS HasMigrationError          
   ,ISNULL(P.IsLocked,0) as IsLocked    
   ,P.LockedBy as LockedBy    
   ,P.LockedDate as LockedDate    
   FROM dbo.Project AS p WITH (NOLOCK)                                  
   INNER JOIN [dbo].[ProjectSummary] psm WITH (NOLOCK)                                  
    ON psm.ProjectId = p.ProjectId                                  
   inner JOIN #AccessibleProjectIds t                                  
   ON t.Projectid=p.ProjectId                                  
   LEFT JOIN UserFolder UF WITH (NOLOCK)                                  
    ON UF.ProjectId = P.ProjectId                                  
     AND UF.customerId = p.customerId                        
   WHERE p.IsDeleted = 0                      
   AND ISNULL(p.IsArchived,0)= 0                         
   AND p.IsOfficeMaster = @PIsOfficeMasterTab                                  
   AND p.customerId = @PCustomerId                                  
   AND (@PSearchField IS NULL OR p.[Name] LIKE '%' + COALESCE(@PSearchField, p.[Name]) + '%')                                  
   ORDER BY CASE                                  
    WHEN @PIsDesc = 1 THEN CASE                                  
      WHEN LOWER(@PColName) = 'name' THEN P.Name                                  
     END                                  
   END DESC                                  
   , CASE                                  
    WHEN @PIsDesc = 1 THEN CASE                                  
      WHEN LOWER(@PColName) = 'Id' THEN P.[ProjectId]                 
     END                                 
   END DESC                                  
   , CASE                       
    WHEN @PIsDesc = 1 THEN CASE                                  
      WHEN LOWER(@PColName) = 'createdate' THEN UF.LastAccessed                                  
     END                                  
   END DESC                                  
   , CASE                                  
    WHEN @PIsDesc = 0 THEN CASE                                  
      WHEN LOWER(@PColName) = 'name' THEN P.Name                          
     END                                  
   END                                  
   , CASE                                  
    WHEN @PIsDesc = 0 THEN CASE                                  
      WHEN LOWER(@PColName) = 'Id' THEN P.[ProjectId]                                  
     END                                  
   END                                  
   , CASE                                  
    WHEN @PIsDesc = 0 THEN CASE                                  
      WHEN LOWER(@PColName) = 'createdate' THEN UF.LastAccessed                                  
     END                                  
   END OFFSET @PPageSize * (@PPageNo - 1) ROWS                                  
                                  
   FETCH NEXT @PPageSize ROWS ONLY;                                  
 END                                  
                              
  UPDATE t                                  
  set t.ProjectAccessTypeName=pt.Name                                  
  from #projectList t inner join LuProjectAccessType pt  WITH (NOLOCK)              
  on t.ProjectAccessTypeId=pt.ProjectAccessTypeId                                  
                
 /* Removed old logic                              
 SELECT                                  
  ProjectId                                  
    ,[Name]                                  
    ,[Description]                                  
    ,IsOfficeMaster                                  
    ,TemplateId                                  
    ,customerId                                  
    ,LastAccessed                                  
    ,UserId                                  
    ,CreateDate                                  
    ,CreatedBy                                  
    ,ModifiedBy                                  
    ,ModifiedDate                                  
    ,allProjectCount                       
    ,officemastercount                                  
  ,MasterDataTypeId                                  
    ,SpecViewModeId                                  
    ,LastAccessUserId                                  
    ,pl.IsDeleted                    
    ,pl.IsArchived                                  
    ,pl.IsPermanentDeleted                                  
    ,ISNULL(pl.UnitOfMeasureValueTypeId, 0) AS UnitOfMeasureValueTypeId                                  
    ,deletedOfficeMasterCount                                  
    ,deletedProjectCount                                  
    ,archivedProjectCount                    
    ,COALESCE(SectionCount, 0) SectionCount                                  
    ,ModifiedByFullName                                  
    ,ProjectAccessTypeId                                  
    ,IsProjectAccessible                                  
    ,ProjectAccessTypeName                                  
    ,pl.IsProjectOwner                                  
    ,pl.ProjectOwnerId                                  
 FROM #projectList pl                                  
 OUTER APPLY (SELECT                                  
   COALESCE(COUNT(1), 0) SectionCount                                  
  FROM dbo.ProjectSection AS PS WITH (NOLOCK)                                  
  INNER JOIN ProjectSegmentStatus AS PSS WITH (NOLOCK)                                  
   ON PS.SectionId = PsS.SectionId                    
   AND PS.ProjectId = PsS.ProjectId                    
   AND PS.customerId = PSs.customerId                                  
  WHERE PS.customerId = Pl.customerId                                  
  AND PS.ProjectId = Pl.ProjectId                                  
  AND PS.IsLastLevel = 1                                  
  AND PSS.ParentSegmentStatusId = 0                                  
  AND PSS.SequenceNumber = 0                                  
  AND (                                  
  PSS.SegmentStatusTypeId > 0                                  
  AND PSS.SegmentStatusTypeId < 6                              
  )                                  
  GROUP BY ps.ProjectId) P                        
     ORDER by LastAccessed desc    */                  
                     
 /* New Logic*/          
       
       
UPDATE P        
SET P.HasMigrationError = 1        
FROM #projectList P        
INNER JOIN ProjectMigrationException PME WITH (NOLOCK)        
 ON PME.ProjectId = P.ProjectId        
WHERE ISNULL(P.IsMigrated, 0) = 1 AND ISNULL(IsResolved,0)=0      
      
DROP TABLE IF EXISTS #ProjectCommentCount  
-- To get Project wise Open Segment Comment (i.e. UnResolved - CommentStatusId=1) count          
SELECT SC.Projectid,COUNT(SC.SectionId) ProjectCommentCount 
INTO #ProjectCommentCount  
FROM SegmentComment SC WITH (NOLOCK)
WHERE SC.CustomerId=@CustomerId and SC.CommentStatusId=@OpenCommentStatusId and SC.ParentCommentId=0  and ISNULL(SC.IsDeleted, 0) = 0 
GROUP BY SC.ProjectId 

 ;WITH CTE_ActiveSection (ProjectId, TotalActiveSection)          
 AS          
 (Select PSS.ProjectId,Count(PSS.SectionId) as TotalActiveSections           
from #projectList pl with (nolock)          
INNER JOIN ProjectSection PS with (nolock) ON pl.ProjectId = PS.ProjectId          
INNER JOIN Projectsegmentstatus PSS  with (nolock)          
ON PSS.SectionId = PS.SectionId AND PSS.ProjectId = pl.ProjectId          
where PSS.CustomerId = @CustomerId           
AND ISNULL(PSS.ParentSegmentStatusId,0)=0          
AND PS.IsDeleted = 0          
AND ps.IsLastLevel = 1          
and PSS.SequenceNumber = 0 and (           
PSS.SegmentStatusTypeId > 0           
AND PSS.SegmentStatusTypeId < 6           
)          
GROUP by PSS.ProjectId,PSS.CustomerId)          
       
      
 Select           
     pl.ProjectId                                
    ,pl.[Name]                                
    ,pl.[Description]                                
    ,IsOfficeMaster                                
    ,pl.TemplateId                                
    ,pl.customerId                                
    ,LastAccessed                                
    ,pl.UserId                                
    ,pl.CreateDate                                
    ,pl.CreatedBy                                
    ,pl.ModifiedBy                                
    ,pl.ModifiedDate                                
    ,allProjectCount                                
    ,officemastercount                                
    ,MasterDataTypeId                                
    ,pl.SpecViewModeId                                
    ,LastAccessUserId                                
    ,pl.IsDeleted                  
    ,pl.IsArchived                                
    ,pl.IsPermanentDeleted                                
    ,ISNULL(pl.UnitOfMeasureValueTypeId, 0) AS UnitOfMeasureValueTypeId                                
    ,deletedOfficeMasterCount                                
    ,deletedProjectCount                                
    ,archivedProjectCount                  
    ,COALESCE(X.TotalActiveSection, 0) SectionCount                                
    ,ModifiedByFullName                                
    ,ProjectAccessTypeId                                
    ,IsProjectAccessible                                
    ,ProjectAccessTypeName                                
    ,pl.IsProjectOwner                                
    ,pl.ProjectOwnerId           
 ,pl.IsMigrated        
 ,pl.HasMigrationError        
 ,pl.IsLocked    
 ,pl.LockedBy  
 ,pl.LockedDate  
 ,ISNULL(PSC.ProjectCommentCount,0) ProjectCommentCount  
 from #projectList pl          
 LEFT JOIN #ProjectCommentCount PSC ON PSC.ProjectId = pl.ProjectId  
 LEFT JOIN CTE_ActiveSection X ON pl.ProjectId = X.ProjectId          
  ORDER by pl.LastAccessed desc          
          
 /**New logic end*********/          
                     
 SELECT                                  
    @archivedProjectCount AS ArchiveProjectCount                    
    ,@deletedProjectCount AS DeletedProjectCount                                  
    ,@deletedOfficeMasterCount AS DeletedOfficeMasterCount                      
    ,@officeMasterCount AS OfficeMasterCount                                  
    ,@allProjectCount AS TotalProjectCount;                                
END
GO
PRINT N'Altering [dbo].[usp_GetSegmentsForMLReportWithParagraph]...';


GO
ALTER PROCEDURE [dbo].[usp_GetSegmentsForMLReportWithParagraph]                   
(                  
@ProjectId INT,                  
@CustomerId INT,                  
@CatalogueType NVARCHAR(MAX)='FS',                  
@TCPrintModeId INT = 0,            
@TagId NVARCHAR(MAX)            
)                      
AS                      
BEGIN
      
          
              
DECLARE @PProjectId INT = @ProjectId;
      
          
DECLARE @PCustomerId INT = @CustomerId;
      
          
DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;
      
          
DECLARE @PTCPrintModeId INT = 0;
      
          
DECLARE @PTagId INT = convert(int,@TagId);

DECLARE @SegmentTypeId INT = 1
DECLARE @HeaderFooterTypeId INT = 3
          
          
CREATE table #SegmentStatusIds (SegmentStatusId int);

INSERT INTO #SegmentStatusIds (SegmentStatusId)
	(SELECT
		PSRT.SegmentStatusId
	FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)
	WHERE PSRT.ProjectId = @PProjectId
	AND PSRT.RequirementTagId = @TagId
	UNION ALL
	SELECT
		PSUT.SegmentStatusId
	FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)
	WHERE PSUT.ProjectId = @PProjectId
	AND PSUT.UserTagId = @TagId);

(SELECT
	PSS.SegmentStatusId
   ,PSS.SectionId
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
   ,PSS.ProjectId
   ,PSS.CustomerId
   ,PSS.SegmentStatusCode
   ,PSS.IsShowAutoNumber
   ,PSS.IsRefStdParagraph
   ,PSS.FormattingJson
   ,PSS.CreateDate
   ,PSS.CreatedBy
   ,PSS.ModifiedDate
   ,PSS.ModifiedBy
   ,PSS.IsPageBreak
   ,PSS.IsDeleted
   ,PSS.TrackOriginOrder
   ,PSS.mTrackDescription INTO #taggedSegment
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
WHERE PSS.ProjectId = @PProjectId
AND PSS.CustomerId = @PCustomerId
AND PSS.SegmentStatusId IN (SELECT
		SegmentStatusId
	FROM #SegmentStatusIds)
);

DELETE FROM #taggedSegment
WHERE SegmentStatusId IN (SELECT
			SegmentStatusId
		FROM ProjectSegmentStatusView PSST WITH (NOLOCK)
		WHERE PSST.ProjectId = @PProjectId
		AND PSST.CustomerId = @PCustomerId
		AND PSST.IsDeleted = 0
		AND PSST.IsSegmentStatusActive = 0);

WITH SegmentStatus (SegmentStatusId, SectionId, ParentSegmentStatusId, SegmentOrigin, IndentLevel, SequenceNumber, SegmentDescription)
AS
(SELECT
		SegmentStatusId
	   ,SectionId
	   ,ParentSegmentStatusId
	   ,SegmentOrigin
	   ,IndentLevel
	   ,SequenceNumber
	   ,CAST(NULL AS NVARCHAR(MAX)) AS SegmentDescription
	FROM ProjectSegmentStatus WITH (NOLOCK)
	WHERE SegmentStatusId IN (SELECT
			SegmentStatusId
		FROM #taggedSegment)
	UNION ALL
	SELECT
		PSS.SegmentStatusId
	   ,PSS.SectionId
	   ,PSS.ParentSegmentStatusId
	   ,PSS.SegmentOrigin
	   ,PSS.IndentLevel
	   ,PSS.SequenceNumber
	   ,NULL AS SegmentDescription
	FROM ProjectSegmentStatus PSS WITH (NOLOCK)
	JOIN SegmentStatus SG
		ON PSS.SegmentStatusId = SG.ParentSegmentStatusId
		AND PSS.IndentLevel > 1)

SELECT
	* INTO #TagReport
FROM SegmentStatus;

UPDATE SS
SET SS.SegmentDescription = pssv.SegmentDescription
FROM #TagReport SS
INNER JOIN ProjectSegmentStatusView pssv WITH (NOLOCK)
	ON pssv.SegmentStatusId = SS.SegmentStatusId;




DECLARE @MasterDataTypeId INT = (SELECT
		P.MasterDataTypeId
	FROM Project P WITH (NOLOCK)
	WHERE P.ProjectId = @PProjectId
	AND P.CustomerId = @PCustomerId);

DECLARE @SectionIdTbl TABLE (
	SectionId INT
);
DECLARE @CatalogueTypeTbl TABLE (
	TagType NVARCHAR(MAX)
);
DECLARE @OldKeywordFormat NVARCHAR(MAX) = '{\kw\';
DECLARE @NewKeywordFormat NVARCHAR(MAX) = '{KW#';

DECLARE @Lu_InheritFromSection INT = 1;
DECLARE @Lu_AllWithMarkups INT = 2;
DECLARE @Lu_AllWithoutMarkups INT = 3;

--CONVERT STRING INTO TABLE                      
INSERT INTO @SectionIdTbl (SectionId)
	SELECT DISTINCT
		SectionId
	FROM #TagReport;

--CONVERT CATALOGUE TYPE INTO TABLE                  
IF @PCatalogueType IS NOT NULL
	AND @PCatalogueType != 'FS'
BEGIN
INSERT INTO @CatalogueTypeTbl (TagType)
	SELECT
		*
	FROM dbo.fn_SplitString(@PCatalogueType, ',');

IF EXISTS (SELECT
		TOP 1
			1
		FROM @CatalogueTypeTbl
		WHERE TagType = 'OL')
BEGIN
INSERT INTO @CatalogueTypeTbl
	VALUES ('UO')
END
IF EXISTS (SELECT
		TOP 1
			1
		FROM @CatalogueTypeTbl
		WHERE TagType = 'SF')
BEGIN
INSERT INTO @CatalogueTypeTbl
	VALUES ('US')
END
END

--DROP TEMP TABLES IF PRESENT                      
DROP TABLE IF EXISTS #tmp_ProjectSegmentStatus;
DROP TABLE IF EXISTS #tmp_Template;
DROP TABLE IF EXISTS #tmp_SelectedChoiceOption;
DROP TABLE IF EXISTS #tmp_ProjectSection;

--FETCH SECTIONS DATA IN TEMP TABLE            
SELECT
	PS.SectionId
   ,PS.ParentSectionId
   ,PS.mSectionId
   ,PS.ProjectId
   ,PS.CustomerId
   ,PS.UserId
   ,PS.DivisionId
   ,PS.DivisionCode
   ,PS.Description
   ,PS.LevelId
   ,PS.IsLastLevel
   ,PS.SourceTag
   ,PS.Author
   ,PS.TemplateId
   ,PS.SectionCode
   ,PS.IsDeleted
   ,PS.SpecViewModeId
   ,PS.IsTrackChanges INTO #tmp_ProjectSection
FROM ProjectSection PS WITH (NOLOCK)
WHERE PS.ProjectId = @PProjectId
AND PS.CustomerId = @PCustomerId
ORDER BY PS.SourceTag

--FETCH SEGMENT STATUS DATA INTO TEMP TABLE               
PRINT 'FETCH SEGMENT STATUS DATA INTO TEMP TABLE'
SELECT
	PSST.SegmentStatusId
   ,PSST.SectionId
   ,PSST.ParentSegmentStatusId
   ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId
   ,ISNULL(PSST.mSegmentId, 0) AS mSegmentId
   ,ISNULL(PSST.SegmentId, 0) AS SegmentId
   ,PSST.SegmentSource
   ,TRIM(CONVERT(NCHAR(2), PSST.SegmentOrigin)) AS SegmentOrigin
   ,CASE
		WHEN PSST.IndentLevel > 8 THEN CAST(8 AS TINYINT)
		ELSE PSST.IndentLevel
	END AS IndentLevel
   ,PSST.SequenceNumber
   ,PSST.SegmentStatusTypeId
   ,PSST.SegmentStatusCode
   ,PSST.IsParentSegmentStatusActive
   ,PSST.IsShowAutoNumber
   ,PSST.FormattingJson
	-- ,STT.TagType                  
   ,ISNULL(PSST.SpecTypeTagId, 0) AS SpecTypeTagId
   ,PSST.IsRefStdParagraph
   ,PSST.IsPageBreak
   ,ISNULL(PSST.TrackOriginOrder, '') AS TrackOriginOrder INTO #tmp_ProjectSegmentStatus
FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)
--INNER JOIN #TagReport TR                  
-- ON PSST.SegmentStatusId = TR.SegmentStatusId                  
--LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK)                  
--ON PSST.SpecTypeTagId = STT.SpecTypeTagId                

WHERE PSST.ProjectId = @PProjectId
AND PSST.CustomerId = @PCustomerId
AND (PSST.IsDeleted IS NULL
OR PSST.IsDeleted = 0)
--AND ((PSST.SegmentStatusTypeId > 0                  
--AND PSST.SegmentStatusTypeId < 6                  
AND PSST.IsParentSegmentStatusActive = 1
AND PSST.SegmentStatusId IN (SELECT
		SegmentStatusId
	FROM #TagReport)
--OR (PSST.IsPageBreak = 1))                  
--AND (@PCatalogueType = 'FS'                  
--OR STT.TagType IN (SELECT                  
--  *                  
-- FROM @CatalogueTypeTbl)                  
--)                  

--SELECT SEGMENT STATUS DATA            
SELECT
	*
FROM #tmp_ProjectSegmentStatus PSST
ORDER BY PSST.SectionId, PSST.SequenceNumber
--SELECT SEGMENT DATA             
SELECT
	PSST.SegmentId
   ,PSST.SegmentStatusId
   ,PSST.SectionId
   ,(CASE
		WHEN @PTCPrintModeId = @Lu_AllWithoutMarkups THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')
		WHEN @PTCPrintModeId = @Lu_AllWithMarkups THEN COALESCE(PSG.SegmentDescription, '')
		WHEN @PTCPrintModeId = @Lu_InheritFromSection AND
			PS.IsTrackChanges = 1 THEN COALESCE(PSG.SegmentDescription, '')
		WHEN @PTCPrintModeId = @Lu_InheritFromSection AND
			PS.IsTrackChanges = 0 THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')
		ELSE COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')
	END) AS SegmentDescription
   ,PSG.SegmentSource
   ,PSG.SegmentCode
FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)
INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK)
	ON PSST.SectionId = PS.SectionId
INNER JOIN ProjectSegment AS PSG WITH (NOLOCK)
	ON PSST.SegmentId = PSG.SegmentId
INNER JOIN #TagReport TR
	ON TR.SectionId = PS.SectionId

WHERE PSG.ProjectId = @PProjectId
AND PSG.CustomerId = @PCustomerId

UNION
SELECT
	MSG.SegmentId
   ,PSST.SegmentStatusId
   ,PSST.SectionId
   ,CASE
		WHEN PSST.ParentSegmentStatusId = 0 AND
			PSST.SequenceNumber = 0 THEN PS.Description
		ELSE ISNULL(MSG.SegmentDescription, '')
	END AS SegmentDescription
   ,MSG.SegmentSource
   ,MSG.SegmentCode
FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)
INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK)
	ON PSST.SectionId = PS.SectionId
INNER JOIN SLCMaster..Segment AS MSG WITH (NOLOCK)
	ON PSST.mSegmentId = MSG.SegmentId
INNER JOIN #TagReport TR
	ON TR.SectionId = PS.SectionId
WHERE PS.ProjectId = @PProjectId
AND PS.CustomerId = @PCustomerId

--FETCH TEMPLATE DATA INTO TEMP TABLE                      
SELECT
	* INTO #tmp_Template
FROM (SELECT
		T.TemplateId
	   ,T.Name
	   ,T.TitleFormatId
	   ,T.SequenceNumbering
	   ,T.IsSystem
	   ,T.IsDeleted
	   ,0 AS SectionId
	   ,CAST(1 AS BIT) AS IsDefault
	FROM Template T WITH (NOLOCK)
	INNER JOIN Project P WITH (NOLOCK)
		ON T.TemplateId = COALESCE(P.TemplateId, 1)

	WHERE P.ProjectId = @PProjectId
	AND P.CustomerId = @PCustomerId) AS X






--SELECT TEMPLATE DATA                     
SELECT
	*
FROM #tmp_Template T

--SELECT TEMPLATE STYLE DATA                  

SELECT
	TS.TemplateStyleId
   ,TS.TemplateId
   ,TS.StyleId
   ,TS.Level
FROM TemplateStyle TS WITH (NOLOCK)
INNER JOIN #tmp_Template T WITH (NOLOCK)
	ON TS.TemplateId = T.TemplateId

--SELECT STYLE DATA                      
SELECT
	ST.StyleId
   ,ST.Alignment
   ,ST.IsBold
   ,ST.CharAfterNumber
   ,ST.CharBeforeNumber
   ,ST.FontName
   ,ST.FontSize
   ,ST.HangingIndent
   ,ST.IncludePrevious
   ,ST.IsItalic
   ,ST.LeftIndent
   ,ST.NumberFormat
   ,ST.NumberPosition
   ,ST.PrintUpperCase
   ,ST.ShowNumber
   ,ST.StartAt
   ,ST.Strikeout
   ,ST.Name
   ,ST.TopDistance
   ,ST.Underline
   ,ST.SpaceBelowParagraph
   ,ST.IsSystem
   ,ST.IsDeleted
   ,CAST(TS.Level AS INT) AS Level
   ,ISNULL(SPS.CustomLineSpacing,0) as CustomLineSpacing
   ,ISNULL(SPS.DefaultSpacesId,0) as  DefaultSpacesId
  ,ISNULL(SPS.BeforeSpacesId,0) as   BeforeSpacesId
  ,ISNULL(SPS.AfterSpacesId,0) as AfterSpacesId
FROM Style AS ST WITH (NOLOCK)
INNER JOIN TemplateStyle AS TS WITH (NOLOCK)
	ON ST.StyleId = TS.StyleId
INNER JOIN #tmp_Template T WITH (NOLOCK)
	ON TS.TemplateId = T.TemplateId
LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK) ON SPS.StyleId=ST.StyleId 


--FETCH SelectedChoiceOption INTO TEMP TABLE             
SELECT DISTINCT
	SCHOP.SegmentChoiceCode
   ,SCHOP.ChoiceOptionCode
   ,SCHOP.ChoiceOptionSource
   ,SCHOP.IsSelected
   ,SCHOP.ProjectId
   ,SCHOP.SectionId
   ,SCHOP.CustomerId
   ,0 AS SelectedChoiceOptionId
   ,SCHOP.OptionJson INTO #tmp_SelectedChoiceOption
FROM SelectedChoiceOption SCHOP WITH (NOLOCK)
INNER JOIN @SectionIdTbl SIDTBL
	ON SCHOP.SectionId = SIDTBL.SectionId
WHERE SCHOP.ProjectId = @PProjectId
AND SCHOP.CustomerId = @PCustomerId
AND ISNULL(SCHOP.IsDeleted, 0) = 0
--FETCH MASTER + USER CHOICES AND THEIR OPTIONS             
SELECT
	0 AS SegmentId
   ,MCH.SegmentId AS mSegmentId
   ,MCH.ChoiceTypeId
   ,'M' AS ChoiceSource
   ,ISNULL(MCH.SegmentChoiceCode, 0) AS SegmentChoiceCode
   ,ISNULL(MCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode
   ,PSCHOP.IsSelected
   ,PSCHOP.ChoiceOptionSource
   ,CASE
		WHEN PSCHOP.IsSelected = 1 AND
			PSCHOP.OptionJson IS NOT NULL THEN PSCHOP.OptionJson
		ELSE MCHOP.OptionJson
	END AS OptionJson
   ,MCHOP.SortOrder
   ,MCH.SegmentChoiceId
   ,MCHOP.ChoiceOptionId
   ,PSCHOP.SelectedChoiceOptionId
   ,PSST.SectionId
FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK)
	ON PSST.mSegmentId = MCH.SegmentId
INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)
	ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId
INNER JOIN #tmp_SelectedChoiceOption PSCHOP WITH (NOLOCK)
	ON MCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode
		AND MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode
		AND PSCHOP.ChoiceOptionSource = 'M'
UNION
SELECT
	PCH.SegmentId
   ,0 AS mSegmentId
   ,PCH.ChoiceTypeId
   ,PCH.SegmentChoiceSource AS ChoiceSource
   ,ISNULL(PCH.SegmentChoiceCode, 0) AS SegmentChoiceCode
   ,ISNULL(PCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode
   ,PSCHOP.IsSelected
   ,PSCHOP.ChoiceOptionSource
   ,PCHOP.OptionJson
   ,PCHOP.SortOrder
   ,PCH.SegmentChoiceId
   ,PCHOP.ChoiceOptionId
   ,PSCHOP.SelectedChoiceOptionId
   ,PSST.SectionId
FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
	ON PSST.SegmentId = PCH.SegmentId
		AND ISNULL(PCH.IsDeleted, 0) = 0
INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)
	ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId
		AND ISNULL(PCHOP.IsDeleted, 0) = 0
INNER JOIN #tmp_SelectedChoiceOption PSCHOP WITH (NOLOCK)
	ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode
		AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode
		AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource
		AND PSCHOP.ChoiceOptionSource = 'U'
WHERE PCH.ProjectId = @PProjectId
AND PCH.CustomerId = @PCustomerId
AND PCHOP.ProjectId = @PProjectId
AND PCHOP.CustomerId = @PCustomerId

--SELECT GLOBAL TERM DATA                 
SELECT
	PGT.GlobalTermId
   ,COALESCE(PGT.mGlobalTermId, 0) AS mGlobalTermId
   ,PGT.Name
   ,ISNULL(PGT.value, '') AS value
   ,PGT.CreatedDate
   ,PGT.CreatedBy
   ,PGT.ModifiedDate
   ,PGT.ModifiedBy
   ,PGT.GlobalTermSource
   ,PGT.GlobalTermCode
   ,COALESCE(PGT.UserGlobalTermId, 0) AS UserGlobalTermId
   ,GlobalTermFieldTypeId
FROM ProjectGlobalTerm PGT WITH (NOLOCK)
WHERE PGT.ProjectId = @PProjectId
AND PGT.CustomerId = @PCustomerId;

--SELECT SECTIONS DATA                

SELECT
	S.SectionId AS SectionId
   ,ISNULL(S.mSectionId, 0) AS mSectionId
   ,S.Description
   ,S.Author
   ,S.SectionCode
   ,S.SourceTag
   ,PS.SourceTagFormat
   ,ISNULL(D.DivisionCode, '') AS DivisionCode
   ,ISNULL(D.DivisionTitle, '') AS DivisionTitle
   ,ISNULL(D.DivisionId, 0) AS DivisionId
   ,S.IsTrackChanges
FROM #tmp_ProjectSection AS S WITH (NOLOCK)
LEFT JOIN SLCMaster..Division D WITH (NOLOCK)
	ON S.DivisionId = D.DivisionId
INNER JOIN ProjectSummary PS WITH (NOLOCK)
	ON S.ProjectId = PS.ProjectId
		AND S.CustomerId = PS.CustomerId
WHERE S.ProjectId = @PProjectId
AND S.CustomerId = @PCustomerId
AND S.IsLastLevel = 1
UNION
SELECT
	0 AS SectionId
   ,MS.SectionId AS mSectionId
   ,MS.Description
   ,MS.Author
   ,MS.SectionCode
   ,MS.SourceTag
   ,P.SourceTagFormat
   ,ISNULL(D.DivisionCode, '') AS DivisionCode
   ,ISNULL(D.DivisionTitle, '') AS DivisionTitle
   ,ISNULL(D.DivisionId, 0) AS DivisionId
   ,CONVERT(BIT, 0) AS IsTrackChanges
FROM SLCMaster..Section MS WITH (NOLOCK)
LEFT JOIN SLCMaster..Division D WITH (NOLOCK)
	ON MS.DivisionId = D.DivisionId
INNER JOIN ProjectSummary P WITH (NOLOCK)
	ON P.ProjectId = @PProjectId
		AND P.CustomerId = @PCustomerId
LEFT JOIN #tmp_ProjectSection PS WITH (NOLOCK)
	ON MS.SectionId = PS.mSectionId
		AND PS.ProjectId = @PProjectId
		AND PS.CustomerId = @PCustomerId
WHERE MS.MasterDataTypeId = @MasterDataTypeId
AND MS.IsLastLevel = 1
AND PS.SectionId IS NULL;

--SELECT SEGMENT REQUIREMENT TAGS DATA             
SELECT
	PSRT.SegmentStatusId
   ,PSRT.SegmentRequirementTagId
   ,PSST.mSegmentStatusId
   ,LPRT.RequirementTagId
   ,LPRT.TagType
   ,LPRT.Description AS TagName
   ,CASE
		WHEN PSRT.mSegmentRequirementTagId IS NULL THEN CAST(0 AS BIT)
		ELSE CAST(1 AS BIT)
	END AS IsMasterRequirementTag
   ,PSST.SectionId
FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)
INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)
	ON PSRT.RequirementTagId = LPRT.RequirementTagId
INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)
	ON PSRT.SegmentStatusId = PSST.SegmentStatusId
WHERE PSRT.ProjectId = @PProjectId
AND PSRT.CustomerId = @PCustomerId

--SELECT REQUIRED IMAGES DATA             
SELECT
	IMG.ImageId
   ,IMG.ImagePath
   ,PIMG.SectionId
   ,PIMG.ImageStyle
   ,IMG.LuImageSourceTypeId
FROM ProjectSegmentImage PIMG WITH (NOLOCK)
INNER JOIN ProjectImage IMG WITH (NOLOCK)
	ON PIMG.ImageId = IMG.ImageId
--INNER JOIN @SectionIdTbl SIDTBL	ON PIMG.SectionId = SIDTBL.SectionId //To resolved cross section images in headerFooter
WHERE PIMG.ProjectId = @PProjectId
AND PIMG.CustomerId = @PCustomerId
AND IMG.LuImageSourceTypeId in (@SegmentTypeId,@HeaderFooterTypeId)
UNION ALL -- This union to ge Note images  
 SELECT           
 PN.ImageId          
 ,IMG.ImagePath          
 ,PN.SectionId           
 ,NULL ImageStyle          
 ,IMG.LuImageSourceTypeId   
 FROM ProjectNoteImage PN  WITH (NOLOCK)       
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PN.ImageId = IMG.ImageId  
 INNER JOIN @SectionIdTbl SIDTBL ON PN.SectionId = SIDTBL.SectionId  
 WHERE PN.ProjectId = @PProjectId                
  AND PN.CustomerId = @PCustomerId  

--SELECT HYPERLINKS DATA                      
SELECT
	HLNK.HyperLinkId
   ,HLNK.LinkTarget
   ,HLNK.LinkText
   ,'U' AS Source
   ,HLNK.SectionId
FROM ProjectHyperLink HLNK WITH (NOLOCK)
INNER JOIN @SectionIdTbl SIDTBL
	ON HLNK.SectionId = SIDTBL.SectionId
WHERE HLNK.ProjectId = @PProjectId
AND HLNK.CustomerId = @PCustomerId

--SELECT SEGMENT USER TAGS DATA             
SELECT
	PSUT.SegmentUserTagId
   ,PSUT.SegmentStatusId
   ,PSUT.UserTagId
   ,PUT.TagType
   ,PUT.Description AS TagName
   ,PSUT.SectionId
FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)
INNER JOIN ProjectUserTag PUT WITH (NOLOCK)
	ON PSUT.UserTagId = PUT.UserTagId
INNER JOIN #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)
	ON PSUT.SegmentStatusId = PSST.SegmentStatusId
WHERE PSUT.ProjectId = @PProjectId
AND PSUT.CustomerId = @PCustomerId

--SELECT Project Summary information            
SELECT
	P.ProjectId AS ProjectId
   ,P.Name AS ProjectName
   ,'' AS ProjectLocation
   ,PS.IsPrintReferenceEditionDate AS IsPrintReferenceEditionDate
   ,PS.SourceTagFormat AS SourceTagFormat
   ,COALESCE(LState.StateProvinceAbbreviation, PA.StateProvinceName) + ', ' + COALESCE(LCity.City, PA.CityName) AS DbInfoProjectLocationKeyword
   ,ISNULL(PGT.value, '') AS ProjectLocationKeyword
   ,PS.UnitOfMeasureValueTypeId
FROM Project P WITH (NOLOCK)
INNER JOIN ProjectSummary PS WITH (NOLOCK)
	ON P.ProjectId = PS.ProjectId
INNER JOIN ProjectAddress PA WITH (NOLOCK)
	ON P.ProjectId = PA.ProjectId
INNER JOIN LuCountry LCountry WITH (NOLOCK)
	ON PA.CountryId = LCountry.CountryId
LEFT JOIN LuStateProvince LState WITH (NOLOCK)
	ON PA.StateProvinceId = LState.StateProvinceID
LEFT JOIN LuCity LCity WITH (NOLOCK)
	ON PA.CityId = LCity.CityId
LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK)
	ON P.ProjectId = PGT.ProjectId
		AND PGT.mGlobalTermId = 11
WHERE P.ProjectId = @PProjectId
AND P.CustomerId = @PCustomerId

--SELECT Header/Footer information                      
IF EXISTS (SELECT
		TOP 1
			1
		FROM Header WITH (NOLOCK)
		WHERE ProjectId = @PProjectId
		AND CustomerId = @PCustomerId
		AND DocumentTypeId = 2)
BEGIN
SELECT
	H.HeaderId
   ,ISNULL(H.ProjectId, @PProjectId) AS ProjectId
   ,ISNULL(H.SectionId, 0) AS SectionId
   ,ISNULL(H.CustomerId, @PCustomerId) AS CustomerId
   ,ISNULL(H.TypeId, 1) AS TypeId
   ,H.DateFormat
   ,H.TimeFormat
   ,ISNULL(H.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId
   ,REPLACE(ISNULL(H.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader
   ,REPLACE(ISNULL(H.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader
   ,REPLACE(ISNULL(H.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader
   ,REPLACE(ISNULL(H.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader
   ,H.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId
   ,H.IsShowLineAboveHeader AS IsShowLineAboveHeader
   ,H.IsShowLineBelowHeader AS IsShowLineBelowHeader
FROM Header H WITH (NOLOCK)
WHERE H.ProjectId = @PProjectId
AND H.CustomerId = @PCustomerId
AND H.DocumentTypeId = 2
END
ELSE
BEGIN
SELECT
	H.HeaderId
   ,ISNULL(H.ProjectId, @PProjectId) AS ProjectId
   ,ISNULL(H.SectionId, 0) AS SectionId
   ,ISNULL(H.CustomerId, @PCustomerId) AS CustomerId
   ,ISNULL(H.TypeId, 1) AS TypeId
   ,H.DateFormat
   ,H.TimeFormat
   ,ISNULL(H.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId
   ,REPLACE(ISNULL(H.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader
   ,REPLACE(ISNULL(H.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader
   ,REPLACE(ISNULL(H.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader
   ,REPLACE(ISNULL(H.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader
   ,H.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId
   ,H.IsShowLineAboveHeader AS IsShowLineAboveHeader
   ,H.IsShowLineBelowHeader AS IsShowLineBelowHeader
FROM Header H WITH (NOLOCK)
WHERE H.ProjectId IS NULL
AND H.CustomerId IS NULL
AND H.SectionId IS NULL
AND H.DocumentTypeId = 2
END
IF EXISTS (SELECT
		TOP 1
			1
		FROM Footer WITH (NOLOCK)
		WHERE ProjectId = @PProjectId
		AND CustomerId = @PCustomerId
		AND DocumentTypeId = 2)
BEGIN
SELECT
	F.FooterId
   ,ISNULL(F.ProjectId, @PProjectId) AS ProjectId
   ,ISNULL(F.SectionId, 0) AS SectionId
   ,ISNULL(F.CustomerId, @PCustomerId) AS CustomerId
   ,ISNULL(F.TypeId, 1) AS TypeId
   ,F.DateFormat
   ,F.TimeFormat
   ,ISNULL(F.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId
   ,REPLACE(ISNULL(F.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter
   ,REPLACE(ISNULL(F.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter
   ,REPLACE(ISNULL(F.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter
   ,REPLACE(ISNULL(F.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter
   ,F.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId
   ,F.IsShowLineAboveFooter AS IsShowLineAboveFooter
   ,F.IsShowLineBelowFooter AS IsShowLineBelowFooter

FROM Footer F WITH (NOLOCK)
WHERE F.ProjectId = @PProjectId
AND F.CustomerId = @PCustomerId
AND F.DocumentTypeId = 2
END
ELSE
BEGIN
SELECT
	F.FooterId
   ,ISNULL(F.ProjectId, @PProjectId) AS ProjectId
   ,ISNULL(F.SectionId, 0) AS SectionId
   ,ISNULL(F.CustomerId, @PCustomerId) AS CustomerId
   ,ISNULL(F.TypeId, 1) AS TypeId
   ,F.DateFormat
   ,F.TimeFormat
   ,ISNULL(F.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId
   ,REPLACE(ISNULL(F.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter
   ,REPLACE(ISNULL(F.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter
   ,REPLACE(ISNULL(F.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter
   ,REPLACE(ISNULL(F.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter
   ,F.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId
   ,F.IsShowLineAboveFooter AS IsShowLineAboveFooter
   ,F.IsShowLineBelowFooter AS IsShowLineBelowFooter
FROM Footer F WITH (NOLOCK)
WHERE F.ProjectId IS NULL
AND F.CustomerId IS NULL
AND F.SectionId IS NULL
AND F.DocumentTypeId = 2
END
--SELECT PageSetup INFORMATION                  
SELECT
	PageSetting.ProjectPageSettingId AS ProjectPageSettingId
   ,PaperSetting.ProjectPaperSettingId AS ProjectPaperSettingId
   ,ISNULL(PageSetting.MarginTop, 1.00) AS MarginTop
   ,ISNULL(PageSetting.MarginBottom, 1.00) AS MarginBottom
   ,ISNULL(PageSetting.MarginLeft, 1.00) AS MarginLeft
   ,ISNULL(PageSetting.MarginRight, 1.00) AS MarginRight
   ,ISNULL(PageSetting.EdgeHeader, 0.05) AS EdgeHeader
   ,ISNULL(PageSetting.EdgeFooter, 0.05) AS EdgeFooter
   ,PageSetting.IsMirrorMargin AS IsMirrorMargin
   ,PageSetting.ProjectId AS ProjectId
   ,PageSetting.CustomerId AS CustomerId
   ,PaperSetting.PaperName AS PaperName
   ,ISNULL(PaperSetting.PaperWidth, 0.00) AS PaperWidth
   ,ISNULL(PaperSetting.PaperHeight, 0.00) AS PaperHeight
   ,PaperSetting.PaperOrientation AS PaperOrientation
   ,PaperSetting.PaperSource AS PaperSource
FROM ProjectPageSetting PageSetting WITH (NOLOCK)
INNER JOIN ProjectPaperSetting PaperSetting WITH (NOLOCK)
	ON PageSetting.ProjectId = PaperSetting.ProjectId
WHERE PageSetting.ProjectId = @PProjectId
END
GO
PRINT N'Altering [dbo].[usp_GetSegmentsForPrint]...';


GO
ALTER PROCEDURE [dbo].[usp_GetSegmentsForPrint] (                  
 @ProjectId INT                  
 ,@CustomerId INT                  
 ,@SectionIdsString NVARCHAR(MAX)                  
 ,@UserId INT                  
 ,@CatalogueType NVARCHAR(MAX)                  
 ,@TCPrintModeId INT = 1                  
 ,@IsActiveOnly BIT = 1                
              
 )                  
AS                  
BEGIN                  
 DECLARE @PProjectId INT = @ProjectId;                  
 DECLARE @PCustomerId INT = @CustomerId;                  
 DECLARE @PSectionIdsString NVARCHAR(MAX) = @SectionIdsString;                  
 DECLARE @PUserId INT = @UserId;                  
 DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;                  
 DECLARE @PTCPrintModeId INT = @TCPrintModeId;                  
 DECLARE @PIsActiveOnly BIT = @IsActiveOnly;                  
 DECLARE @IsFalse BIT = 0;                  
 DECLARE @SProjectId NVARCHAR(20) = convert(NVARCHAR, @ProjectId);                  
 DECLARE @STCPrintModeId NVARCHAR(2) = convert(NVARCHAR, @TCPrintModeId);                  
 DECLARE @SIsActiveOnly NVARCHAR(2) = convert(NVARCHAR, @IsActiveOnly);                  
 DECLARE @SCustomerId NVARCHAR(20) = convert(NVARCHAR, @CustomerId);                  
 DECLARE @SUserId NVARCHAR(20) = convert(NVARCHAR, @UserId);                  
 DECLARE @MasterDataTypeId INT = (                  
   SELECT P.MasterDataTypeId                  
   FROM Project P WITH (NOLOCK)                  
   WHERE P.ProjectId = @PProjectId                  
    AND P.CustomerId = @PCustomerId                  
   );                  
 DECLARE @SectionIdTbl TABLE (SectionId INT);                  
 DECLARE @CatalogueTypeTbl TABLE (TagType NVARCHAR(MAX));                  
 DECLARE @OldKeywordFormat NVARCHAR(MAX) = '{\kw\';                  
 DECLARE @NewKeywordFormat NVARCHAR(MAX) = '{KW#';                  
 DECLARE @Lu_InheritFromSection INT = 1;                  
 DECLARE @Lu_AllWithMarkups INT = 2;                  
 DECLARE @Lu_AllWithoutMarkups INT = 3;                 
 DECLARE @ImagSegment int =1      
 DECLARE @ImageHeaderFooter int =3      
 DECLARE @State VARCHAR(50)=''  
 DECLARE @City VARCHAR(50)=''  
                  
 --CONVERT STRING INTO TABLE                                      
 INSERT INTO @SectionIdTbl (SectionId)                  
 SELECT *                  
 FROM dbo.fn_SplitString(@PSectionIdsString, ',');                  
                  
 --CONVERT CATALOGUE TYPE INTO TABLE                                  
 IF @PCatalogueType IS NOT NULL                  
  AND @PCatalogueType != 'FS'                  
 BEGIN                  
  INSERT INTO @CatalogueTypeTbl (TagType)                  
  SELECT *                  
  FROM dbo.fn_SplitString(@PCatalogueType, ',');                  
                  
  IF EXISTS (                  
    SELECT *                  
    FROM @CatalogueTypeTbl                  
    WHERE TagType = 'OL'                  
    )                  
  BEGIN                  
   INSERT INTO @CatalogueTypeTbl                  
   VALUES ('UO')                  
  END                  
                  
  IF EXISTS (                  
    SELECT TOP 1 1                  
    FROM @CatalogueTypeTbl                  
    WHERE TagType = 'SF'                  
    )                  
  BEGIN                  
   INSERT INTO @CatalogueTypeTbl                  
   VALUES ('US')                  
  END                  
 END                  
  
 IF EXISTS (SELECT COUNT(1) FROM ProjectAddress PA  WITH (NOLOCK) WHERE Projectid=@PProjectId AND PA.StateProvinceId=99999999 AND PA.StateProvinceName IS NULL)  
 BEGIN  
  SELECT @State = ISNULL(concat(rtrim(VALUE),','),'') FROM ProjectGlobalTerm  WITH (NOLOCK)  
  WHERE Projectid = @PProjectId AND (NAME = 'Project Location State' OR Name ='Project Location Province')  
 END  
 ELSE  
 BEGIN  
  SELECT @State = CONCAT(RTRIM(SP.StateProvinceAbbreviation),', ') FROM LuStateProvince SP WITH (NOLOCK)  
  INNER JOIN ProjectAddress PA WITH (NOLOCK) ON PA.StateProvinceId = SP.StateProvinceID   
  WHERE ProjectId = @PProjectId  
 END  
   
 IF EXISTS(SELECT COUNT(1) FROM ProjectAddress PA  WITH (NOLOCK) WHERE ProjectId = @PProjectId AND PA.CityId=99999999 AND PA.CityName IS NULL)  
 BEGIN  
  SELECT @City =ISNULL(VALUE,'') FROM ProjectGlobalTerm  WITH (NOLOCK) WHERE ProjectId = @PProjectId AND NAME = 'Project Location City'  
 END  
 ELSE  
 BEGIN  
  SELECT @City = CITY FROM LuCity C WITH (NOLOCK) INNER JOIN ProjectAddress PA ON PA.CityId = C.CityId   
 END  
  
                  
 --DROP TEMP TABLES IF PRESENT                                      
 DROP TABLE                  
                  
 IF EXISTS #tmp_ProjectSegmentStatus;                  
  DROP TABLE                  
                  
 IF EXISTS #tmp_Template;                  
  DROP TABLE                  
                  
 IF EXISTS #tmp_SelectedChoiceOption;                  
  DROP TABLE                  
                  
 IF EXISTS #tmp_ProjectSection;                  
  --FETCH SECTIONS DATA IN TEMP TABLE                                  
  SELECT PS.SectionId                  
   ,PS.ParentSectionId                  
   ,PS.mSectionId                  
   ,PS.ProjectId                  
   ,PS.CustomerId                  
   ,PS.UserId                  
   ,PS.DivisionId      
   ,PS.DivisionCode                  
   ,PS.Description                  
   ,PS.LevelId                  
   ,PS.IsLastLevel                  
   ,PS.SourceTag                  
   ,PS.Author                  
   ,PS.TemplateId                  
   ,PS.SectionCode                  
   ,PS.IsDeleted                  
   ,PS.SpecViewModeId                  
   ,PS.IsTrackChanges                  
  INTO #tmp_ProjectSection                  
  FROM ProjectSection PS WITH (NOLOCK)                  
  WHERE PS.ProjectId = @PProjectId                  
   AND PS.CustomerId = @PCustomerId                  
   AND ISNULL(PS.IsDeleted, 0) = 0;                  
                  
 --FETCH SEGMENT STATUS DATA INTO TEMP TABLE                              
 SELECT PSST.SegmentStatusId            
  ,PSST.SectionId                  
  ,PSST.ParentSegmentStatusId                  
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId                  
  ,ISNULL(PSST.mSegmentId, 0) AS mSegmentId                  
  ,ISNULL(PSST.SegmentId, 0) AS SegmentId             
  ,PSST.SegmentSource                  
  ,trim(convert(NCHAR(2), PSST.SegmentOrigin)) AS SegmentOrigin                  
  ,CASE                   
   WHEN PSST.IndentLevel > 8                  
    THEN CAST(8 AS TINYINT)                  
   ELSE PSST.IndentLevel                  
   END AS IndentLevel                  
  ,PSST.SequenceNumber                  
  ,PSST.SegmentStatusTypeId                  
  ,PSST.SegmentStatusCode                  
  ,PSST.IsParentSegmentStatusActive                  
  ,PSST.IsShowAutoNumber                  
  ,PSST.FormattingJson                  
  ,STT.TagType                  
  ,ISNULL(PSST.SpecTypeTagId, 0) AS SpecTypeTagId                  
  ,PSST.IsRefStdParagraph                  
  ,PSST.IsPageBreak                  
  ,ISNULL(PSST.TrackOriginOrder, '') AS TrackOriginOrder                  
  ,PSST.MTrackDescription                  
 INTO #tmp_ProjectSegmentStatus                  
 FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl SIDTBL ON PSST.SectionId = SIDTBL.SectionId                  
 LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK) ON PSST.SpecTypeTagId = STT.SpecTypeTagId                  
 WHERE PSST.ProjectId = @PProjectId                  
  AND PSST.CustomerId = @PCustomerId                  
  AND (                  
   PSST.IsDeleted IS NULL                  
   OR PSST.IsDeleted = 0                  
   )                  
  AND (                  
   @PIsActiveOnly = @IsFalse                  
   OR (                  
    PSST.SegmentStatusTypeId > 0                  
    AND PSST.SegmentStatusTypeId < 6                  
    AND PSST.IsParentSegmentStatusActive = 1                  
    )                  
   OR (PSST.IsPageBreak = 1)                  
   )                  
  AND (                  
   @PCatalogueType = 'FS'                  
   OR STT.TagType IN (                  
    SELECT TagType                  
    FROM @CatalogueTypeTbl                  
    )                  
   )                  
                  
 --SELECT SEGMENT STATUS DATA                                      
 SELECT *                  
 FROM #tmp_ProjectSegmentStatus PSST   WITH (NOLOCK)            
 ORDER BY PSST.SectionId                  
  ,PSST.SequenceNumber;                  
   
DROP TABLE IF EXISTS #tmpProjectSegmentStatusForNote;     
 --FETCH SegmentStatusId AND MSegmentStatusId DATA INTO TEMP TABLE       
SELECT PSST.SegmentStatusId              
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId                    
 INTO #tmpProjectSegmentStatusForNote                    
 FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)                    
 INNER JOIN @SectionIdTbl SIDTBL ON PSST.SectionId = SIDTBL.SectionId                   
 WHERE PSST.ProjectId = @PProjectId   
 AND PSST.CustomerId = @PCustomerId    
  
 --SELECT SEGMENT DATA                                      
 SELECT PSST.SegmentId                  
  ,PSST.SegmentStatusId                  
  ,PSST.SectionId                  
  ,(                  
   CASE                   
    WHEN @PTCPrintModeId = @Lu_AllWithoutMarkups                  
     THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                  
    WHEN @PTCPrintModeId = @Lu_AllWithMarkups                  
     THEN COALESCE(PSG.SegmentDescription, '')                  
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                  
     AND PS.IsTrackChanges = 1                  
     THEN COALESCE(PSG.SegmentDescription, '')                  
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                  
     AND PS.IsTrackChanges = 0                  
     THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                  
    ELSE COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                  
    END                  
   ) AS SegmentDescription                  
  ,PSG.SegmentSource                  
  ,PSG.SegmentCode                  
 FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                  
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId                  
 INNER JOIN ProjectSegment AS PSG WITH (NOLOCK) ON PSST.SegmentId = PSG.SegmentId                  
 WHERE PSG.ProjectId = @PProjectId                  
  AND PSG.CustomerId = @PCustomerId                  
                   
 UNION                  
                   
 SELECT MSG.SegmentId                  
  ,PSST.SegmentStatusId                  
  ,PSST.SectionId                  
  ,CASE                   
   WHEN PSST.ParentSegmentStatusId = 0                AND PSST.SequenceNumber = 0                  
    THEN PS.Description                  
   ELSE ISNULL(MSG.SegmentDescription, '')                  
   END AS SegmentDescription                  
  ,MSG.SegmentSource                  
  ,MSG.SegmentCode                  
 FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                  
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId                  
 INNER JOIN SLCMaster..Segment AS MSG WITH (NOLOCK) ON PSST.mSegmentId = MSG.SegmentId                  
 WHERE PS.ProjectId = @PProjectId                  
  AND PS.CustomerId = @PCustomerId                  
                  
 --FETCH TEMPLATE DATA INTO TEMP TABLE                                      
 SELECT *                  
 INTO #tmp_Template                  
 FROM (                  
  SELECT T.TemplateId                  
   ,T.Name                  
   ,T.TitleFormatId                  
   ,T.SequenceNumbering                  
   ,T.IsSystem                  
   ,T.IsDeleted                  
   ,0 AS SectionId            
   ,T.ApplyTitleStyleToEOS              
   ,CAST(1 AS BIT) AS IsDefault                  
  FROM Template T WITH (NOLOCK)                  
  INNER JOIN Project P WITH (NOLOCK) ON T.TemplateId = COALESCE(P.TemplateId, 1)                  
  WHERE P.ProjectId = @PProjectId                  
   AND P.CustomerId = @PCustomerId                  
                    
  UNION                  
                    
  SELECT T.TemplateId                  
   ,T.Name                  
   ,T.TitleFormatId                  
   ,T.SequenceNumbering                  
   ,T.IsSystem                
   ,T.IsDeleted                  
   ,PS.SectionId                  
   ,T.ApplyTitleStyleToEOS              
   ,CAST(0 AS BIT) AS IsDefault                  
  FROM Template T WITH (NOLOCK)                  
  INNER JOIN #tmp_ProjectSection PS WITH (NOLOCK) ON T.TemplateId = PS.TemplateId                  
  INNER JOIN @SectionIdTbl SIDTBL ON PS.SectionId = SIDTBL.SectionId                  
  WHERE PS.ProjectId = @PProjectId                  
   AND PS.CustomerId = @PCustomerId                  
   AND PS.TemplateId IS NOT NULL                  
  ) AS X                  
                  
 --SELECT TEMPLATE DATA                                      
 SELECT *                  
 FROM #tmp_Template T                  
                  
 --SELECT TEMPLATE STYLE DATA                                      
 SELECT TS.TemplateStyleId                  
  ,TS.TemplateId                  
  ,TS.StyleId                  
  ,TS.LEVEL                  
 FROM TemplateStyle TS WITH (NOLOCK)                  
 INNER JOIN #tmp_Template T WITH (NOLOCK) ON TS.TemplateId = T.TemplateId                  
                  
 --SELECT STYLE DATA                                      
 SELECT ST.StyleId                  
  ,ST.Alignment                  
  ,ST.IsBold                  
  ,ST.CharAfterNumber                  
  ,ST.CharBeforeNumber                  
  ,ST.FontName                  
  ,ST.FontSize                  
  ,ST.HangingIndent                  
  ,ST.IncludePrevious                  
  ,ST.IsItalic                  
  ,ST.LeftIndent                  
  ,ST.NumberFormat                  
  ,ST.NumberPosition          
  ,ST.PrintUpperCase                  
  ,ST.ShowNumber                  
  ,ST.StartAt                  
  ,ST.Strikeout                  
  ,ST.Name                  
  ,ST.TopDistance                  
  ,ST.Underline                  
  ,ST.SpaceBelowParagraph                  
  ,ST.IsSystem                  
  ,ST.IsDeleted                  
  ,CAST(TS.LEVEL AS INT) AS LEVEL         
  ,ISNULL(SPS.CustomLineSpacing,0) as CustomLineSpacing    
  ,ISNULL(SPS.DefaultSpacesId,0) as  DefaultSpacesId    
  ,ISNULL(SPS.BeforeSpacesId,0) as   BeforeSpacesId    
  ,ISNULL(SPS.AfterSpacesId,0) as AfterSpacesId           
 FROM Style AS ST WITH (NOLOCK)                  
 INNER JOIN TemplateStyle AS TS WITH (NOLOCK) ON ST.StyleId = TS.StyleId                  
 INNER JOIN #tmp_Template T WITH (NOLOCK) ON TS.TemplateId = T.TemplateId      
  LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK) ON SPS.StyleId=ST.StyleId              
                  
 -- insert missing sco entries                      
 INSERT INTO SelectedChoiceOption                  
 SELECT psc.SegmentChoiceCode                  
  ,pco.ChoiceOptionCode                  
  ,pco.ChoiceOptionSource                  
  ,slcmsco.IsSelected                  
  ,psc.SectionId                  
  ,psc.ProjectId                  
  ,pco.CustomerId                  
  ,NULL AS OptionJson                  
  ,0 AS IsDeleted                  
 FROM ProjectSegmentChoice psc WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl stb ON psc.SectionId = stb.SectionId                  
 INNER JOIN ProjectChoiceOption pco WITH (NOLOCK) ON pco.SegmentChoiceId = psc.SegmentChoiceId                  
  AND pco.SectionId = psc.SectionId                  
  AND pco.ProjectId = psc.ProjectId                  
  AND pco.CustomerId = psc.CustomerId    
 LEFT OUTER JOIN SelectedChoiceOption sco WITH (NOLOCK) ON pco.ChoiceOptionCode = sco.ChoiceOptionCode                  
  AND pco.SectionId = sco.SectionId                  
  AND pco.ProjectId = sco.ProjectId                  
  AND pco.CustomerId = sco.CustomerId                  
  AND sco.ChoiceOptionSource = pco.ChoiceOptionSource                  
 INNER JOIN SLCMaster.dbo.SelectedChoiceOption slcmsco WITH (NOLOCK) ON slcmsco.ChoiceOptionCode = pco.ChoiceOptionCode                  
 WHERE sco.SelectedChoiceOptionId IS NULL                  
  AND pco.CustomerId = @PCustomerId                  
  AND pco.ProjectId = @PProjectId                  
  AND ISNULL(pco.IsDeleted, 0) = 0                  
  AND ISNULL(psc.IsDeleted, 0) = 0                  
                  
 -- insert missing sco entries                      
 INSERT INTO BsdLogging..DBLogging (                  
  ArtifactName                  
  ,DBServerName                  
  ,DBServerIP                  
  ,CreatedDate                  
  ,LevelType                  
  ,InputData                  
  ,ErrorProcedure                  
  ,ErrorMessage                  
  )                  
 VALUES (                  
  'usp_GetSegmentsForPrint'                  
  ,@@SERVERNAME                  
  ,convert(NVARCHAR, CONNECTIONPROPERTY('local_net_address'))                  
  ,Getdate()                  
  ,'Information'                  
  ,('ProjectId: ' + @SProjectId + ' TCPrintModeId: ' + @STCPrintModeId + ' CustomerId: ' + @SCustomerId + ' UserId:' + @SUserId + ' IsActiveOnly:' + @SIsActiveOnly + ' CatalogueType:' + @PCatalogueType + ' SectionIdsString:' + @PSectionIdsString)        
  
    
       
       
          
  ,'Insert'                  
  ,('Scenario 1: SelectedChoiceOption Rows Inserted - ' + convert(NVARCHAR, @@ROWCOUNT))                  
  )                  
                  
 -- Mark isdeleted =0 for SelectedChoiceOption                    
 UPDATE sco                  
 SET sco.isdeleted = 0                  
 FROM ProjectSegmentChoice psc WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl stb  ON psc.SectionId = stb.SectionId                  
 INNER JOIN ProjectChoiceOption pco WITH (NOLOCK) ON pco.SegmentChoiceId = psc.SegmentChoiceId                  
  AND pco.SectionId = psc.SectionId                  
  AND pco.ProjectId = psc.ProjectId     
  AND pco.CustomerId = psc.CustomerId                  
 LEFT OUTER JOIN SelectedChoiceOption sco WITH (NOLOCK) ON pco.ChoiceOptionCode = sco.ChoiceOptionCode                  
  AND pco.SectionId = sco.SectionId                  
  AND pco.ProjectId = sco.ProjectId                  
  AND pco.CustomerId = sco.CustomerId                  
  AND sco.ChoiceOptionSource = pco.ChoiceOptionSource                  
 WHERE ISNULL(sco.IsDeleted, 0) = 1                  
  AND pco.CustomerId = @PCustomerId                  
  AND pco.ProjectId = @PProjectId                  
  AND ISNULL(pco.IsDeleted, 0) = 0                  
  AND ISNULL(psc.IsDeleted, 0) = 0                  
  AND psc.SegmentChoiceSource = 'U'                  
                  
 --                    
 INSERT INTO BsdLogging..DBLogging (                  
  ArtifactName                  
  ,DBServerName                  
  ,DBServerIP                  
  ,CreatedDate                  
  ,LevelType                  
  ,InputData                  
  ,ErrorProcedure                  
  ,ErrorMessage                  
  )                  
 VALUES (                  
  'usp_GetSegmentsForPrint'                  
  ,@@SERVERNAME                  
  ,convert(NVARCHAR, CONNECTIONPROPERTY('local_net_address'))                  
  ,Getdate()                  
  ,'Information'                  
  ,('ProjectId: ' + @SProjectId + ' TCPrintModeId: ' + @STCPrintModeId + ' CustomerId: ' + @SCustomerId + ' UserId:' + @SUserId + ' IsActiveOnly:' + @SIsActiveOnly + ' CatalogueType:' + @PCatalogueType + ' SectionIdsString:' + @PSectionIdsString)         
 
     
      
        
         
  ,'Update'    
  ,('Scenario 2: SelectedChoiceOption Rows Updated - ' + convert(NVARCHAR, @@ROWCOUNT))                  
  )                  
                  
 --FETCH SelectedChoiceOption INTO TEMP TABLE                                      
 SELECT DISTINCT SCHOP.SegmentChoiceCode                  
  ,SCHOP.ChoiceOptionCode                  
  ,SCHOP.ChoiceOptionSource              ,SCHOP.IsSelected                  
  ,SCHOP.ProjectId                  
  ,SCHOP.SectionId                  
  ,SCHOP.CustomerId                  
  ,0 AS SelectedChoiceOptionId                  
  ,SCHOP.OptionJson                  
 INTO #tmp_SelectedChoiceOption                  
 FROM SelectedChoiceOption SCHOP WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl SIDTBL ON SCHOP.SectionId = SIDTBL.SectionId                  
 WHERE SCHOP.ProjectId = @PProjectId                  
  AND SCHOP.CustomerId = @PCustomerId                  
  AND IsNULL(SCHOP.IsDeleted, 0) = 0                  
                  
 --FETCH MASTER + USER CHOICES AND THEIR OPTIONS                                        
 SELECT 0 AS SegmentId                  
  ,MCH.SegmentId AS mSegmentId                  
  ,MCH.ChoiceTypeId                  
  ,'M' AS ChoiceSource                  
  ,ISNULL(MCH.SegmentChoiceCode, 0) AS SegmentChoiceCode                
  ,ISNULL(MCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode                  
  ,PSCHOP.IsSelected                  
  ,PSCHOP.ChoiceOptionSource                  
  ,CASE                   
   WHEN PSCHOP.IsSelected = 1                  
    AND PSCHOP.OptionJson IS NOT NULL                  
    THEN PSCHOP.OptionJson                  
   ELSE MCHOP.OptionJson                  
   END AS OptionJson                  
  ,MCHOP.SortOrder                  
  ,MCH.SegmentChoiceId                  
  ,MCHOP.ChoiceOptionId                  
  ,PSCHOP.SelectedChoiceOptionId                  
  ,PSST.SectionId                  
 FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)                  
 INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK) ON PSST.mSegmentId = MCH.SegmentId                  
 INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK) ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId                  
 INNER JOIN #tmp_SelectedChoiceOption PSCHOP WITH (NOLOCK) ON MCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode                  
  AND MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode                  
  AND PSCHOP.ChoiceOptionSource = 'M'                  
                   
 UNION                  
                   
 SELECT PCH.SegmentId                  
  ,0 AS mSegmentId                  
  ,PCH.ChoiceTypeId                  
  ,PCH.SegmentChoiceSource AS ChoiceSource                  
  ,ISNULL(PCH.SegmentChoiceCode, 0) AS SegmentChoiceCode                  
  ,ISNULL(PCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode                  
  ,PSCHOP.IsSelected                  
  ,PSCHOP.ChoiceOptionSource                  
  ,PCHOP.OptionJson                  
  ,PCHOP.SortOrder                  
  ,PCH.SegmentChoiceId                  
  ,PCHOP.ChoiceOptionId                  
  ,PSCHOP.SelectedChoiceOptionId                  
  ,PSST.SectionId                  
 FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)                  
 INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK) ON PSST.SegmentId = PCH.SegmentId                  
  AND ISNULL(PCH.IsDeleted, 0) = 0                  
 INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK) ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId                  
  AND ISNULL(PCHOP.IsDeleted, 0) = 0                  
 INNER JOIN #tmp_SelectedChoiceOption PSCHOP WITH (NOLOCK) ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode                  
  AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode                  
AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource                  
  AND PSCHOP.ChoiceOptionSource = 'U'                  
 WHERE PCH.ProjectId = @PProjectId                  
  AND PCH.CustomerId = @PCustomerId                  
  AND PCHOP.ProjectId = @PProjectId                  
  AND PCHOP.CustomerId = @PCustomerId                  
  AND ISNULL(PCH.IsDeleted, 0) = 0                  
  AND ISNULL(PCHOP.IsDeleted, 0) = 0                  
                  
 --SELECT GLOBAL TERM DATA                                      
 SELECT PGT.GlobalTermId                  
  ,COALESCE(PGT.mGlobalTermId, 0) AS mGlobalTermId                  
  ,PGT.Name                  
  ,ISNULL(PGT.value, '') AS value                  
  ,PGT.CreatedDate                  
  ,PGT.CreatedBy                  
  ,PGT.ModifiedDate                  
  ,PGT.ModifiedBy                  
  ,PGT.GlobalTermSource                  
  ,PGT.GlobalTermCode                  
  ,COALESCE(PGT.UserGlobalTermId, 0) AS UserGlobalTermId                  
  ,GlobalTermFieldTypeId                  
 FROM ProjectGlobalTerm PGT WITH (NOLOCK)                  
 WHERE PGT.ProjectId = @PProjectId                  
  AND PGT.CustomerId = @PCustomerId;                  
                  
 --SELECT SECTIONS DATA                                      
 SELECT S.SectionId AS SectionId                  
  ,ISNULL(S.mSectionId, 0) AS mSectionId                  
  ,S.Description                  
  ,S.Author                  
  ,S.SectionCode                  
  ,S.SourceTag                  
  ,PS.SourceTagFormat                  
  ,ISNULL(D.DivisionCode, '') AS DivisionCode                  
  ,ISNULL(D.DivisionTitle, '') AS DivisionTitle                  
  ,ISNULL(D.DivisionId, 0) AS DivisionId                  
  ,S.IsTrackChanges                  
 FROM #tmp_ProjectSection AS S WITH (NOLOCK)                  
 LEFT JOIN SLCMaster..Division D WITH (NOLOCK) ON S.DivisionId = D.DivisionId                  
 INNER JOIN ProjectSummary PS WITH (NOLOCK) ON S.ProjectId = PS.ProjectId                  
  AND S.CustomerId = PS.CustomerId                  
 WHERE S.ProjectId = @PProjectId                  
  AND S.CustomerId = @PCustomerId                  
  AND S.IsLastLevel = 1                  
AND ISNULL(S.IsDeleted, 0) = 0                  
                   
 UNION                  
                   
 SELECT 0 AS SectionId                  
  ,MS.SectionId AS mSectionId                  
  ,MS.Description                  
  ,MS.Author                  
  ,MS.SectionCode                  
  ,MS.SourceTag                  
  ,P.SourceTagFormat                  
  ,ISNULL(D.DivisionCode, '') AS DivisionCode                  
  ,ISNULL(D.DivisionTitle, '') AS DivisionTitle                  
  ,ISNULL(D.DivisionId, 0) AS DivisionId                  
  ,CONVERT(BIT, 0) AS IsTrackChanges                  
 FROM SLCMaster..Section MS WITH (NOLOCK)                  
 LEFT JOIN SLCMaster..Division D WITH (NOLOCK) ON MS.DivisionId = D.DivisionId                  
 INNER JOIN ProjectSummary P WITH (NOLOCK) ON P.ProjectId = @PProjectId                  
  AND P.CustomerId = @PCustomerId                  
 LEFT JOIN #tmp_ProjectSection PS WITH (NOLOCK) ON MS.SectionId = PS.mSectionId                  
  AND PS.ProjectId = @PProjectId                  
  AND PS.CustomerId = @PCustomerId                  
 WHERE MS.MasterDataTypeId = @MasterDataTypeId                  
  AND MS.IsLastLevel = 1                  
  AND PS.SectionId IS NULL                  
  AND ISNULL(PS.IsDeleted, 0) = 0                  
                  
 --SELECT SEGMENT REQUIREMENT TAGS DATA                                      
 SELECT PSRT.SegmentStatusId                  
  ,PSRT.SegmentRequirementTagId                  
  ,PSST.mSegmentStatusId                  
  ,LPRT.RequirementTagId                  
  ,LPRT.TagType                  
  ,LPRT.Description AS TagName                  
  ,CASE                   
   WHEN PSRT.mSegmentRequirementTagId IS NULL                  
    THEN CAST(0 AS BIT)                  
   ELSE CAST(1 AS BIT)                  
   END AS IsMasterRequirementTag                  
  ,PSST.SectionId                  
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)                  
 INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK) ON PSRT.RequirementTagId = LPRT.RequirementTagId                  
INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK) ON PSRT.SegmentStatusId = PSST.SegmentStatusId                  
 WHERE PSRT.ProjectId = @PProjectId                  
  AND PSRT.CustomerId = @PCustomerId                  
                       
 --SELECT REQUIRED IMAGES DATA                                      
 SELECT             
  PIMG.SegmentImageId            
 ,IMG.ImageId            
 ,IMG.ImagePath            
 ,PIMG.ImageStyle            
 ,PIMG.SectionId             
 ,IMG.LuImageSourceTypeId     
          
 FROM ProjectSegmentImage PIMG WITH (NOLOCK)                  
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PIMG.ImageId = IMG.ImageId                  
 --INNER JOIN @SectionIdTbl SIDTBL ON PIMG.SectionId = SIDTBL.SectionId    //To resolved cross section images in headerFooter               
 WHERE PIMG.ProjectId = @PProjectId                  
  AND PIMG.CustomerId = @PCustomerId                  
  AND IMG.LuImageSourceTypeId IN(@ImagSegment,@ImageHeaderFooter)    
UNION ALL -- This union to ge Note images    
 SELECT             
  0 SegmentImageId            
 ,PN.ImageId            
 ,IMG.ImagePath            
 ,NULL ImageStyle            
 ,PN.SectionId             
 ,IMG.LuImageSourceTypeId     
 FROM ProjectNoteImage PN  WITH (NOLOCK)         
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PN.ImageId = IMG.ImageId    
 INNER JOIN @SectionIdTbl SIDTBL ON PN.SectionId = SIDTBL.SectionId    
 WHERE PN.ProjectId = @PProjectId                  
  AND PN.CustomerId = @PCustomerId       
 UNION ALL -- This union to ge Master Note images     
 select     
  0 SegmentImageId              
 ,NI.ImageId              
 ,MIMG.ImagePath              
 ,NULL ImageStyle              
 ,NI.SectionId               
 ,MIMG.LuImageSourceTypeId      
from slcmaster..NoteImage NI with (nolock)    
INNER JOIN ProjectSection PS with (nolock) on NI.SectionId = PS.mSectionId    
INNER JOIN @SectionIdTbl SIDTBL ON PS.SectionId = SIDTBL.SectionId    
INNER JOIN SLCMaster..Image MIMG WITH (NOLOCK) ON MIMG.ImageId = NI.ImageId    
                  
 --SELECT HYPERLINKS DATA                                      
 SELECT HLNK.HyperLinkId                  
  ,HLNK.LinkTarget                  
  ,HLNK.LinkText                  
  ,'U' AS Source                  
  ,HLNK.SectionId                  
 FROM ProjectHyperLink HLNK WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl SIDTBL ON HLNK.SectionId = SIDTBL.SectionId                  
 WHERE HLNK.ProjectId = @PProjectId                  
  AND HLNK.CustomerId = @PCustomerId                  
  UNION ALL -- To get Master Hyperlinks  
  SELECT MLNK.HyperLinkId                  
  ,MLNK.LinkTarget                  
  ,MLNK.LinkText                  
  ,'M' AS Source                  
  ,MLNK.SectionId                  
 FROM slcmaster..Hyperlink MLNK WITH (NOLOCK)   
 INNER JOIN #tmpProjectSegmentStatusForNote PSS WITH (NOLOCK) ON  MLNK.SegmentStatusId = PSS.mSegmentStatusId  
                
 --SELECT SEGMENT USER TAGS DATA                                      
 SELECT PSUT.SegmentUserTagId                  
  ,PSUT.SegmentStatusId                  
  ,PSUT.UserTagId                  
  ,PUT.TagType                  
  ,PUT.Description AS TagName                  
  ,PSUT.SectionId                  
 FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)                  
 INNER JOIN ProjectUserTag PUT WITH (NOLOCK) ON PSUT.UserTagId = PUT.UserTagId                  
 INNER JOIN #tmp_ProjectSegmentStatus PSST WITH (NOLOCK) ON PSUT.SegmentStatusId = PSST.SegmentStatusId                  
 WHERE PSUT.ProjectId = @PProjectId                  
  AND PSUT.CustomerId = @PCustomerId           
    
 --SELECT Project Summary information                                      
 SELECT P.ProjectId AS ProjectId                  
  ,P.Name AS ProjectName                  
  ,'' AS ProjectLocation                  
  ,PS.IsPrintReferenceEditionDate AS IsPrintReferenceEditionDate                  
  ,PS.SourceTagFormat AS SourceTagFormat                  
  ,CONCAT(@State,@City) AS DbInfoProjectLocationKeyword                  
  ,ISNULL(PGT.value, '') AS ProjectLocationKeyword                  
  ,PS.UnitOfMeasureValueTypeId                  
 FROM Project P WITH (NOLOCK)                  
 INNER JOIN ProjectSummary PS WITH (NOLOCK) ON P.ProjectId = PS.ProjectId                  
 INNER JOIN ProjectAddress PA WITH (NOLOCK) ON P.ProjectId = PA.ProjectId                  
 LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK) ON P.ProjectId = PGT.ProjectId                  
  AND PGT.mGlobalTermId = 11                  
 WHERE P.ProjectId = @PProjectId                  
  AND P.CustomerId = @PCustomerId                  
                  
 --SELECT REFERENCE STD DATA                                   
 SELECT MREFSTD.RefStdId              
  ,COALESCE(MREFSTD.RefStdName, '') AS RefStdName                  
  ,'M' AS RefStdSource                  
  ,COALESCE(MREFSTD.ReplaceRefStdId, 0) AS ReplaceRefStdId                  
  ,'M' AS ReplaceRefStdSource                  
  ,MREFSTD.IsObsolete                  
  ,COALESCE(MREFSTD.RefStdCode, 0) AS RefStdCode                  
 FROM SLCMaster..ReferenceStandard MREFSTD WITH (NOLOCK)                  
 WHERE MREFSTD.MasterDataTypeId = CASE                   
   WHEN @MasterDataTypeId = 2                  
    OR @MasterDataTypeId = 3                  
    THEN 1                  
   ELSE @MasterDataTypeId                  
   END                  
                   
 UNION                  
                   
 SELECT PREFSTD.RefStdId                  
  ,PREFSTD.RefStdName                  
  ,'U' AS RefStdSource                  
  ,COALESCE(PREFSTD.ReplaceRefStdId, 0) AS ReplaceRefStdId                  
  ,COALESCE(PREFSTD.ReplaceRefStdSource, '') AS ReplaceRefStdSource                  
  ,PREFSTD.IsObsolete                  
  ,COALESCE(PREFSTD.RefStdCode, 0) AS RefStdCode                  
 FROM ReferenceStandard PREFSTD WITH (NOLOCK)                  
 WHERE PREFSTD.CustomerId = @PCustomerId                  
                  
 --SELECT REFERENCE EDITION DATA                                      
 SELECT MREFEDN.RefStdId                  
  ,MREFEDN.RefStdEditionId                  
  ,MREFEDN.RefEdition                  
  ,MREFEDN.RefStdTitle                  
  ,MREFEDN.LinkTarget                  
  ,'M' AS RefEdnSource                  
 FROM SLCMaster..ReferenceStandardEdition MREFEDN WITH (NOLOCK)                  
 WHERE MREFEDN.MasterDataTypeId = CASE                   
   WHEN @MasterDataTypeId = 2                  
    OR @MasterDataTypeId = 3                  
    THEN 1                  
   ELSE @MasterDataTypeId                  
   END                  
                   
 UNION                  
                   
 SELECT PREFEDN.RefStdId                  
  ,PREFEDN.RefStdEditionId                  
  ,PREFEDN.RefEdition                  
  ,PREFEDN.RefStdTitle                  
  ,PREFEDN.LinkTarget                  
  ,'U' AS RefEdnSource                  
 FROM ReferenceStandardEdition PREFEDN WITH (NOLOCK)                  
 WHERE PREFEDN.CustomerId = @PCustomerId                  
                  
 --SELECT ProjectReferenceStandard MAPPING DATA                                      
 SELECT PREFSTD.RefStandardId                  
  ,PREFSTD.RefStdSource                  
  ,COALESCE(PREFSTD.mReplaceRefStdId, 0) AS mReplaceRefStdId                  
  ,PREFSTD.RefStdEditionId                  
  ,SIDTBL.SectionId                  
 FROM ProjectReferenceStandard PREFSTD WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl SIDTBL ON PREFSTD.SectionId = SIDTBL.SectionId                  
 WHERE PREFSTD.ProjectId = @PProjectId                  
  AND PREFSTD.CustomerId = @PCustomerId                  
                  
 --SELECT Header/Footer information                                      
 SELECT X.HeaderId                  
  ,ISNULL(X.ProjectId, @PProjectId) AS ProjectId         
  ,ISNULL(X.SectionId, 0) AS SectionId                  
  ,ISNULL(X.CustomerId, @PCustomerId) AS CustomerId                  
  ,ISNULL(X.TypeId, 1) AS TypeId                  
  ,X.DATEFORMAT                  
  ,X.TimeFormat                  
  ,ISNULL(X.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                  
  ,REPLACE(ISNULL(X.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader                  
  ,REPLACE(ISNULL(X.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader                  
  ,REPLACE(ISNULL(X.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader                  
  ,REPLACE(ISNULL(X.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader                  
  ,X.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId     
  ,X.IsShowLineAboveHeader as  IsShowLineAboveHeader    
  ,X.IsShowLineBelowHeader as  IsShowLineBelowHeader             
 FROM (                  
  SELECT H.*                  
  FROM Header H WITH (NOLOCK)                  
  INNER JOIN @SectionIdTbl S ON H.SectionId = S.SectionId                  
  WHERE H.ProjectId = @PProjectId                  
   AND H.DocumentTypeId = 1                  
   AND (                  
    ISNULL(H.HeaderFooterCategoryId, 1) = 1                  
    OR H.HeaderFooterCategoryId = 4                  
    )                  
                    
  UNION                  
                    
  SELECT H.*                  
  FROM Header H WITH (NOLOCK)                  
  WHERE H.ProjectId = @PProjectId                  
   AND H.DocumentTypeId = 1                  
   AND (ISNULL(H.HeaderFooterCategoryId, 1) = 1)                  
   AND (                  
    H.SectionId IS NULL                  
    OR H.SectionId <= 0                  
    )                  
                    
  UNION                  
                    
  SELECT H.*                  
  FROM Header H WITH (NOLOCK)                  
  LEFT JOIN Header TEMP                  
  WITH (NOLOCK) ON TEMP.ProjectId = @PProjectId                  
  WHERE H.CustomerId IS NULL                  
   AND TEMP.HeaderId IS NULL                  
   AND H.DocumentTypeId = 1                  
  ) AS X                  
                  
 SELECT X.FooterId                  
  ,ISNULL(X.ProjectId, @PProjectId) AS ProjectId                  
  ,ISNULL(X.SectionId, 0) AS SectionId                  
  ,ISNULL(X.CustomerId, @PCustomerId) AS CustomerId                  
  ,ISNULL(X.TypeId, 1) AS TypeId                  
  ,X.DATEFORMAT                  
  ,X.TimeFormat                  
  ,ISNULL(X.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                  
  ,REPLACE(ISNULL(X.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter                  
  ,REPLACE(ISNULL(X.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter                  
  ,REPLACE(ISNULL(X.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter                  
  ,REPLACE(ISNULL(X.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter                  
  ,X.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId      
  ,X.IsShowLineAboveFooter as  IsShowLineAboveFooter    
  ,X.IsShowLineBelowFooter as  IsShowLineBelowFooter                  
 FROM (            
  SELECT F.*                  
  FROM Footer F WITH (NOLOCK)                  
  INNER JOIN @SectionIdTbl S ON F.SectionId = S.SectionId                  
  WHERE F.ProjectId = @PProjectId                  
   AND F.DocumentTypeId = 1                  
   AND (                  
    ISNULL(F.HeaderFooterCategoryId, 1) = 1                  
    OR F.HeaderFooterCategoryId = 4                  
    )                  
                    
  UNION                  
                    
  SELECT F.*                  
  FROM Footer F WITH (NOLOCK)                  
  WHERE F.ProjectId = @PProjectId                  
   AND F.DocumentTypeId = 1         
   AND (ISNULL(F.HeaderFooterCategoryId, 1) = 1)                  
   AND (                  
    F.SectionId IS NULL                  
    OR F.SectionId <= 0                  
    )                  
                    
  UNION                  
                    
  SELECT F.*                  
  FROM Footer F WITH (NOLOCK)                  
  LEFT JOIN Footer TEMP                  
  WITH (NOLOCK) ON TEMP.ProjectId = @PProjectId                  
  WHERE F.CustomerId IS NULL                  
   AND F.DocumentTypeId = 1                  
   AND TEMP.FooterId IS NULL                  
  ) AS X                  
                  
 --SELECT PageSetup INFORMATION                                      
 SELECT PageSetting.ProjectPageSettingId AS ProjectPageSettingId                  
  ,PaperSetting.ProjectPaperSettingId AS ProjectPaperSettingId                  
  ,ISNULL(PageSetting.MarginTop, 1.00) AS MarginTop                  
  ,ISNULL(PageSetting.MarginBottom, 1.00) AS MarginBottom                  
  ,ISNULL(PageSetting.MarginLeft, 1.00) AS MarginLeft                  
  ,ISNULL(PageSetting.MarginRight, 1.00) AS MarginRight                  
  ,ISNULL(PageSetting.EdgeHeader, 0.05) AS EdgeHeader                  
  ,ISNULL(PageSetting.EdgeFooter, 0.05) AS EdgeFooter                  
  ,PageSetting.IsMirrorMargin AS IsMirrorMargin                  
  ,PageSetting.ProjectId AS ProjectId                  
  ,PageSetting.CustomerId AS CustomerId                  
  ,PaperSetting.PaperName AS PaperName                  
  ,ISNULL(PaperSetting.PaperWidth, 0.00) AS PaperWidth                  
  ,ISNULL(PaperSetting.PaperHeight, 0.00) AS PaperHeight                  
  ,PaperSetting.PaperOrientation AS PaperOrientation                  
  ,PaperSetting.PaperSource AS PaperSource                  
 FROM ProjectPageSetting PageSetting WITH (NOLOCK)                  
 INNER JOIN ProjectPaperSetting PaperSetting WITH (NOLOCK) ON PageSetting.ProjectId = PaperSetting.ProjectId                
 WHERE PageSetting.ProjectId = @PProjectId                  
    
/*Start - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/    
SELECT   
NoteId  
,PN.SectionId    
,PSS.SegmentStatusId     
,PSS.mSegmentStatusId     
,CASE WHEN Title != '' THEN CONCAT(Title,'<br/>', NoteText)   
 ELSE NoteText END NoteText    
,PN.ProjectId  
,PN.CustomerId  
,PN.IsDeleted  
,NoteCode ,  
PN.Title  
FROM ProjectNote PN WITH (NOLOCK)   
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK) ON PN.SegmentStatusId = PSS.SegmentStatusId     
WHERE PN.ProjectId=@PProjectId and PN.CustomerId=@PCustomerId AND ISNULL(PN.IsDeleted, 0) = 0    
UNION ALL    
SELECT NoteId    
,0 SectionId    
,PSS.SegmentStatusId     
,PSS.mSegmentStatusId     
,NoteText    
,@PProjectId As ProjectId     
,@PCustomerId As CustomerId     
,0 IsDeleted    
,0 NoteCode ,  
'' As Title  
 FROM SLCMaster..Note MN  WITH (NOLOCK)  
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK)  
ON MN.SegmentStatusId = PSS.mSegmentStatusId   
/*End - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/    
END
GO
PRINT N'Altering [dbo].[usp_GetSegmentsForSection]...';


GO
ALTER PROCEDURE [dbo].[usp_GetSegmentsForSection]  
@ProjectId INT,      
@SectionId INT,       
@CustomerId INT,       
@UserId INT,       
@CatalogueType NVARCHAR (50) NULL='FS'      
AS                                      
BEGIN    
            
 SET NOCOUNT ON;        
            
 DECLARE @PProjectId INT = @ProjectId;                             
         
 DECLARE @PSectionId INT = @SectionId;                              
 DECLARE @PCustomerId INT = @CustomerId;                              
 DECLARE @PUserId INT = @UserId;                              
 DECLARE @PCatalogueType NVARCHAR (50) = @CatalogueType;                              
            
 --Set mSectionId                                
 DECLARE @MasterSectionId AS INT, @SectionTemplateId AS INT, @SectionTitle NVARCHAR(500) = ''; 
 --SET @MasterSectionId = (SELECT TOP 1 mSectionId FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSectionId);            
                                
 DECLARE @MasterDataTypeId INT;        
 DECLARE @ProjectTemplateId AS INT;                            
 --SET @MasterDataTypeId = (SELECT TOP 1 MasterDataTypeId FROM Project WITH (NOLOCK) WHERE ProjectId = @PProjectId);             
 SELECT TOP 1 @MasterDataTypeId = MasterDataTypeId, @ProjectTemplateId = ISNULL(TemplateId, 1) FROM Project WITH (NOLOCK) WHERE ProjectId = @PProjectId        
            
 --FIND TEMPLATE ID FROM                                 
 --DECLARE @ProjectTemplateId AS INT = (SELECT TOP 1 ISNULL(TemplateId, 1) FROM Project WITH (NOLOCK) WHERE ProjectId = @PProjectId);                              
 --DECLARE @SectionTemplateId AS INT = ( SELECT TOP 1 TemplateId FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSectionId);            
   
 SELECT TOP 1  @MasterSectionId = mSectionId, @SectionTemplateId = TemplateId, @SectionTitle = [Description]  
 FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSectionId;       
   
 DECLARE @DocumentTemplateId INT = 0;            
 DECLARE @IsMasterSection INT = CASE WHEN @MasterSectionId IS NULL THEN 0 ELSE 1 END;    
  
                              
 IF (@SectionTemplateId IS NOT NULL AND @SectionTemplateId > 0)                              
  BEGIN                              
   SET @DocumentTemplateId = @SectionTemplateId;            
  END                                
 ELSE                                
  BEGIN                              
   SET @DocumentTemplateId = @ProjectTemplateId;                              
  END                          
                              
 --CatalogueTypeTbl table                              
 DECLARE @CatalogueTypeTbl TABLE (TagType NVARCHAR(10));            
                              
 IF @PCatalogueType IS NOT NULL AND @PCatalogueType != 'FS'                              
 BEGIN                              
  INSERT INTO @CatalogueTypeTbl (TagType)             
  SELECT splitdata AS TagType FROM fn_SplitString(@PCatalogueType, ',');            
                              
  IF EXISTS (SELECT TOP 1 1 FROM @CatalogueTypeTbl WHERE TagType = 'OL')                              
  BEGIN                              
   INSERT INTO @CatalogueTypeTbl VALUES ('UO')                              
  END                              
  IF EXISTS (SELECT TOP 1 1 FROM @CatalogueTypeTbl WHERE TagType = 'SF')                              
  BEGIN                              
   INSERT INTO @CatalogueTypeTbl VALUES ('US')                              
  END                              
 END
       
--IF @IsMasterSection = 1  
-- BEGIN -- Data Mapping SP's                  
--   EXECUTE usp_MapSegmentStatusFromMasterToProject @ProjectId = @PProjectId                              
--  ,@SectionId = @PSectionId                              
--  ,@CustomerId = @PCustomerId                              
--  ,@UserId = @PUserId  
--  ,@MasterSectionId =@MasterSectionId;                              
--   EXECUTE usp_MapSegmentChoiceFromMasterToProject @ProjectId = @PProjectId                    
--  ,@SectionId = @PSectionId                              
--  ,@CustomerId = @PCustomerId                              
--  ,@UserId = @PUserId  
--  ,@MasterSectionId =@MasterSectionId;                              
--   EXECUTE usp_MapProjectRefStands @ProjectId = @PProjectId                   
--    ,@SectionId = @PSectionId                              
--    ,@CustomerId = @PCustomerId                              
--    ,@UserId = @PUserId  
--    ,@MasterSectionId=@MasterSectionId;                              
--   EXECUTE usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @PProjectId                              
--    ,@SectionId = @PSectionId                              
--    ,@CustomerId = @PCustomerId                              
--    ,@UserId = @PUserId  
--     ,@MasterSectionId=@MasterSectionId;            
--   EXECUTE usp_MapSegmentLinkFromMasterToProject @ProjectId = @PProjectId                            
--   ,@SectionId = @PSectionId                              
--   ,@CustomerId = @PCustomerId                              
--   ,@UserId = @PUserId;                              
--   EXECUTE usp_UpdateSegmentStatus_ApplyMasterUpdate @ProjectId = @PProjectId                              
--    ,@CustomerId = @PCustomerId                              
--    ,@SectionId = @PSectionId       
--    -- NOT IN USE hence commented                         
--   --EXECUTE usp_DeleteSegmentRequirementTag_ApplyMasterUpdate @ProjectId = @PProjectId                              
--   --,@CustomerId = @PCustomerId                              
--   --,@SectionId = @PSectionId                    
-- END        
        
 DROP TABLE IF EXISTS #ProjectSegmentStatus;                        
 SELECT                          
  PSS.ProjectId                          
    ,PSS.CustomerId                          
    ,PSS.SectionId                     
    ,PSS.SegmentStatusId                               
    ,PSS.ParentSegmentStatusId                          
    ,ISNULL(PSS.mSegmentStatusId, 0) AS mSegmentStatusId                          
    ,ISNULL(PSS.mSegmentId, 0) AS mSegmentId                          
    ,ISNULL(PSS.SegmentId, 0) AS SegmentId                          
    ,PSS.SegmentSource                          
    ,TRIM(PSS.SegmentOrigin) as SegmentOrigin                  
    ,PSS.IndentLevel                          
    ,ISNULL(MSST.IndentLevel, 0) AS MasterIndentLevel                          
    ,PSS.SequenceNumber                          
    ,PSS.SegmentStatusTypeId                          
    ,PSS.SegmentStatusCode                          
    ,PSS.IsParentSegmentStatusActive                          
    ,PSS.IsShowAutoNumber                          
    ,PSS.FormattingJson                          
    ,STT.TagType                          
    ,CASE                          
   WHEN PSS.SpecTypeTagId IS NULL THEN 0                          
   ELSE PSS.SpecTypeTagId                          
  END AS SpecTypeTagId                          
    ,PSS.IsRefStdParagraph                          
    ,PSS.IsPageBreak                          
    ,PSS.IsDeleted                          
    ,MSST.SpecTypeTagId AS MasterSpecTypeTagId                          
    ,ISNULL(MSST.ParentSegmentStatusId, 0) AS MasterParentSegmentStatusId                          
    ,CASE                          
   WHEN MSST.SegmentStatusId IS NOT NULL AND                          
    MSST.SpecTypeTagId = PSS.SpecTypeTagId THEN CAST(1 AS BIT)                          
   ELSE CAST(0 AS BIT)                          
  END AS IsMasterSpecTypeTag                          
    ,PSS.TrackOriginOrder AS TrackOriginOrder                    
    ,PSS.MTrackDescription                    
    INTO #ProjectSegmentStatus                          
 FROM ProjectSegmentStatus AS PSS WITH (NOLOCK)                          
 LEFT JOIN SLCMaster..SegmentStatus MSST WITH (NOLOCK)                          
  ON PSS.mSegmentStatusId = MSST.SegmentStatusId                          
 LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK)                          
  ON PSS.SpecTypeTagId = STT.SpecTypeTagId                          
 WHERE PSS.SectionId = @PSectionId                          
 AND PSS.ProjectId = @PProjectId                          
 AND PSS.CustomerId = @PCustomerId                          
 AND ISNULL(PSS.IsDeleted, 0) = 0                          
 AND (@PCatalogueType = 'FS'                          
 OR STT.TagType IN (SELECT  TagType FROM @CatalogueTypeTbl))    
    
    
 BEGIN -- Fetching Master and Project Notes    
  SELECT Distinct MN.SegmentStatusId    
  INTO #MasterNotes    
  FROM SLCMaster..Note MN WITH (NOLOCK)    
  WHERE MN.SectionId = @MasterSectionId;    
    
  SELECT Distinct PN.SegmentStatusId    
  INTO #ProjectNotes    
  FROM ProjectNote PN WITH (NOLOCK)    
  WHERE PN.SectionId = @PSectionId AND PN.ProjectId = @PProjectId  
 END    
    
    
 SELECT        
  PSS.SegmentStatusId        
 ,PSS.ParentSegmentStatusId        
 ,PSS.mSegmentStatusId        
 ,PSS.mSegmentId        
 ,PSS.SegmentId        
 ,PSS.SegmentSource        
 ,PSS.SegmentOrigin        
 ,PSS.IndentLevel        
 ,PSS.MasterIndentLevel        
 ,PSS.SequenceNumber        
 ,PSS.SegmentStatusTypeId        
 ,PSS.SegmentStatusCode        
 ,PSS.IsParentSegmentStatusActive        
 ,PSS.IsShowAutoNumber        
 ,PSS.FormattingJson        
 ,PSS.TagType        
 ,PSS.SpecTypeTagId        
 ,PSS.IsRefStdParagraph    
 ,PSS.IsPageBreak        
 ,PSS.IsDeleted        
 ,PSS.MasterSpecTypeTagId        
 ,PSS.MasterParentSegmentStatusId        
 ,PSS.IsMasterSpecTypeTag        
 ,PSS.TrackOriginOrder        
 ,PSS.MTrackDescription    
 ,CASE WHEN (MN.SegmentStatusId IS NOT NULL AND @IsMasterSection = 1) THEN 1 ELSE 0 END AS HasMasterNote      
 ,CASE WHEN (PN.SegmentStatusId IS NOT NULL) THEN 1 ELSE 0 END AS HasProjectNote    
 FROM #ProjectSegmentStatus PSS WITH (NOLOCK)    
 LEFT JOIN #MasterNotes MN WITH (NOLOCK)      
  ON MN.SegmentStatusId = PSS.mSegmentStatusId      
 LEFT JOIN #ProjectNotes PN WITH (NOLOCK)    
  ON PN.SegmentStatusId = PSS.SegmentStatusId    
 ORDER BY SequenceNumber;        
    
                          
 SELECT                          
  *                          
 FROM (SELECT                          
   PSG.SegmentId                          
  ,PSST.SegmentStatusId                          
  ,PSG.SectionId                          
  ,ISNULL(PSG.SegmentDescription, '') AS SegmentDescription                          
  ,PSG.SegmentSource                          
  ,PSG.SegmentCode                          
  FROM #ProjectSegmentStatus AS PSST WITH (NOLOCK)                          
  INNER JOIN ProjectSegment AS PSG WITH (NOLOCK)                          
   ON PSST.SegmentId = PSG.SegmentId                          
   AND PSST.SectionId = PSG.SectionId                          
   AND PSST.ProjectId = PSG.ProjectId                          
   AND PSST.CustomerId = PSG.CustomerId                          
  WHERE PSG.SectionId = @PSectionId                          
  AND ISNULL(PSST.IsDeleted, 0) = 0                          
  UNION ALL                          
  SELECT                          
   MSG.SegmentId                          
  ,PST.SegmentStatusId                          
  ,PST.SectionId                          
  ,CASE WHEN PST.ParentSegmentStatusId = 0 AND PST.SequenceNumber = 0 THEN @SectionTitle ELSE ISNULL(MSG.SegmentDescription, '') END AS SegmentDescription                          
  ,MSG.SegmentSource  
  ,MSG.SegmentCode                          
  FROM #ProjectSegmentStatus AS PST WITH (NOLOCK)                          
  --INNER JOIN ProjectSection AS PS WITH (NOLOCK)                          
  -- ON PST.SectionId = PS.SectionId                          
  INNER JOIN SLCMaster.dbo.Segment AS MSG WITH (NOLOCK)                          
   ON PST.mSegmentId = MSG.SegmentId                             
  ) AS X        
          
		  --NOTE- @Sanjay - Create new SP usp_GetSectionChoices hence commented                    
 ----NOTE -- Need to fetch distinct SelectedChoiceOption records     
 --DROP TABLE IF EXISTS #SelectedChoiceOptionTempMaster    SELECT DISTINCT   
 -- SCHOP.SegmentChoiceCode   
 --   ,SCHOP.ChoiceOptionCode   
 --   ,SCHOP.ChoiceOptionSource   
 --   ,SCHOP.IsSelected   
 --   ,SCHOP.ProjectId   
 --   ,SCHOP.SectionId   
 --   ,SCHOP.CustomerId   
 --   ,0 AS SelectedChoiceOptionId   
 --   ,SCHOP.OptionJson  
 --INTO #SelectedChoiceOptionTempMaster   
 --FROM SelectedChoiceOption SCHOP WITH (NOLOCK)   
 --WHERE SCHOP.SectionId = @PSectionId      
 --AND SCHOP.ProjectId = @PProjectId  
 --AND SCHOP.CustomerId = @PCustomerId   
 --AND ISNULL(SCHOP.IsDeleted, 0) = 0  
 --AND SCHOP.ChoiceOptionSource = 'M'    
  
 ----NOTE -- Need to fetch distinct SelectedChoiceOption records     
 --DROP TABLE IF EXISTS #SelectedChoiceOptionTempProject  
 --SELECT DISTINCT   
 -- SCHOP.SegmentChoiceCode   
 --   ,SCHOP.ChoiceOptionCode   
 --   ,SCHOP.ChoiceOptionSource   
 --   ,SCHOP.IsSelected   
 --   ,SCHOP.ProjectId   
 --   ,SCHOP.SectionId   
 --   ,SCHOP.CustomerId   
 --   ,0 AS SelectedChoiceOptionId   
 --   ,SCHOP.OptionJson  
 --INTO #SelectedChoiceOptionTempProject   
 --FROM SelectedChoiceOption SCHOP WITH (NOLOCK)   
 --WHERE SCHOP.SectionId = @PSectionId      
 --AND SCHOP.ProjectId = @PProjectId  
 --AND SCHOP.CustomerId = @PCustomerId   
 --AND ISNULL(SCHOP.IsDeleted, 0) = 0  
 --AND SCHOP.ChoiceOptionSource = 'U'    
  
   
 ----FETCH MASTER + USER CHOICES AND THEIR OPTIONS  
 --SELECT    
 -- 0 AS SegmentId    
 --   ,MCH.SegmentId AS mSegmentId    
 --   ,MCH.ChoiceTypeId    
 --   ,'M' AS ChoiceSource    
 --   ,ISNULL(MCH.SegmentChoiceCode, 0) AS SegmentChoiceCode    
 --   ,ISNULL(MCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode    
 --   ,PSCHOP.IsSelected    
 --   ,PSCHOP.ChoiceOptionSource    
 --   ,CASE    
 --  WHEN PSCHOP.IsSelected = 1 AND    
 --   PSCHOP.OptionJson IS NOT NULL THEN PSCHOP.OptionJson    
 --  ELSE MCHOP.OptionJson    
 -- END AS OptionJson    
 --   ,MCHOP.SortOrder    
 --   ,MCH.SegmentChoiceId    
 --   ,MCHOP.ChoiceOptionId    
 --   ,PSCHOP.SelectedChoiceOptionId    
 --FROM #ProjectSegmentStatus PSST WITH (NOLOCK)    
 --INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK)    
 -- ON PSST.mSegmentId = MCH.SegmentId AND MCH.SectionId=@MasterSectionId  
 --INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)    
 -- ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId    
 --INNER JOIN #SelectedChoiceOptionTempMaster PSCHOP WITH (NOLOCK)    
 --  --AND PSCHOP.ChoiceOptionSource = 'M'    
 --  ON PSCHOP.SectionId = @PSectionId    
 --  AND PSCHOP.ProjectId = @PProjectId    
 --  AND MCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode    
 --  AND MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode    
 --WHERE  
 --PSST.SectionId = @PSectionId   AND   
 --MCH.SectionId = @MasterSectionId     
 --AND PSST.ProjectId = @PProjectId    
 --AND PSST.CustomerId = @PCustomerId    
 --AND ISNULL(PSST.IsDeleted, 0) = 0    
 --UNION ALL    
 --SELECT    
 -- PCH.SegmentId    
 --   ,0 AS mSegmentId    
 --   ,PCH.ChoiceTypeId    
 --   ,PCH.SegmentChoiceSource AS ChoiceSource    
 --   ,ISNULL(PCH.SegmentChoiceCode, 0) AS SegmentChoiceCode    
 --   ,ISNULL(PCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode    
 --   ,PSCHOP.IsSelected    
 --   ,PSCHOP.ChoiceOptionSource    
 --   ,PCHOP.OptionJson    
 --   ,PCHOP.SortOrder    
 --   ,PCH.SegmentChoiceId    
 --   ,PCHOP.ChoiceOptionId    
 --   ,PSCHOP.SelectedChoiceOptionId    
 --FROM #ProjectSegmentStatus PSST WITH (NOLOCK)    
 --INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)    
 -- ON PSST.SegmentId = PCH.SegmentId AND PCH.SectionId = PSST.SectionId  
 --  AND ISNULL(PCH.IsDeleted, 0) = 0    
 --INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)    
 -- ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId AND PCHOP.SectionId = PCH.SectionId  
 --  AND ISNULL(PCHOP.IsDeleted, 0) = 0    
 --INNER JOIN #SelectedChoiceOptionTempProject PSCHOP WITH (NOLOCK)    
 -- ON PCHOP.SectionId = PSCHOP.SectionId    
 -- AND PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode    
 --  AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode    
 --  --AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource    
 --  AND PSCHOP.SectionId = @PSectionId    
 --  AND PSCHOP.ProjectId = @PProjectId    
 --  --AND PSCHOP.ChoiceOptionSource = 'U'    
 --WHERE PCH.SectionId = @PSectionId  
 --AND PSST.ProjectId = @PProjectId    
 --AND PSST.SectionId = @PSectionId    
 --AND PSST.CustomerId = @PCustomerId    
 --AND ISNULL(PSST.IsDeleted, 0) = 0                             
                             
 --FETCH SEGMENT REQUIREMENT TAGS LIST                                
 SELECT                              
  PSRT.SegmentStatusId                              
    ,PSRT.SegmentRequirementTagId                              
    ,Temp.mSegmentStatusId                              
    ,LPRT.RequirementTagId                              
    ,LPRT.TagType                             
    ,LPRT.Description AS TagName                              
    ,CASE                              
   WHEN PSRT.mSegmentRequirementTagId IS NULL THEN CAST(0 AS BIT)                              
   ELSE CAST(1 AS BIT)                              
  END AS IsMasterRequirementTag                              
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)                              
 INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)                              
  ON PSRT.RequirementTagId = LPRT.RequirementTagId                              
 INNER JOIN #ProjectSegmentStatus Temp WITH (NOLOCK)                              
  ON PSRT.SegmentStatusId = Temp.SegmentStatusId                              
 WHERE        
  PSRT.SectionId = @PSectionId        
 AND PSRT.ProjectId = @PProjectId        
  AND PSRT.CustomerId = @PCustomerId        
 AND ISNULL(PSRT.IsDeleted,0)=0    
END
GO
PRINT N'Altering [dbo].[usp_GetSummaryInfo]...';


GO
ALTER PROCEDURE [dbo].[usp_GetSummaryInfo]            
(  
 @ProjectId int,   
 @CustomerId int,   
 @IsSummaryInfoPage bit = 0  
)  
AS  
BEGIN            
             
 DECLARE @PProjectId int = @ProjectId;            
 DECLARE @PCustomerId int = @CustomerId;            
 DECLARE @ActiveSectionsCount INT = 0;  
 DECLARE @TotalSectionsCount INT = 0; 
 
 -- Only fetch total and active sections count if @IsSummaryInfoPage is true  
 IF(@IsSummaryInfoPage = 1)  
 BEGIN
	
	DROP TABLE IF EXISTS #TempProjectSection;
	SELECT PS.SectionId
	INTO #TempProjectSection
	FROM ProjectSection PS WITH (NOLOCK)            
	WHERE PS.CustomerId = @PCustomerId
		AND PS.ProjectId = @PProjectId
		AND PS.IsLastLevel = 1            
		AND PS.IsDeleted = 0;

  SET @TotalSectionsCount = (SELECT COUNT(1) FROM #TempProjectSection);

  SET @ActiveSectionsCount = (SELECT            
    COUNT(1)            
   FROM #TempProjectSection PS WITH (NOLOCK)            
   INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)            
    ON PS.SectionId = PSST.SectionId            
   WHERE PSST.ProjectId = @PProjectId            
   AND PSST.CustomerId = @PCustomerId
   AND PSST.ParentSegmentStatusId = 0            
   AND PSST.SegmentStatusTypeId > 0            
   AND PSST.SegmentStatusTypeId < 6); 
   
   DROP TABLE IF EXISTS #TempProjectSection;           
 END 
 
	 --Used to get Global Term For GT with name ProjectId in Master          
	--DECLARE @ProjectIdGlobalTermCode INT = 2;           
	DECLARE @ProjectIdGlobalTermName NVARCHAR(50) = 'Project ID', @GTValue NVARCHAR(100) = '';
	SELECT TOP 1 @GTValue = PG.[value] FROM ProjectGlobalTerm PG WHERE PG.ProjectId = @PProjectId AND PG.[Name] = @ProjectIdGlobalTermName; 

	 SELECT            
		 P.ProjectId
		,@GTValue AS GlobalTermProjectIdValue            
		,P.[Name] AS ProjectName          
		,P.CreatedBy            
		,UF.UserId AS ModifiedBy            
		,@ActiveSectionsCount AS ActiveSectionsCount            
		,@TotalSectionsCount AS TotalSectionsCount            
		,PSMRY.SpecViewModeId  
		,PSMRY.TrackChangesModeId  
		,P.IsMigrated AS IsMigratedProject            
		,PAdress.CountryId            
		,LC.CountryName            
		,ISNULL(PAdress.StateProvinceId, 0) AS StateProvinceId            
		,ISNULL(LS.StateProvinceName, PAdress.StateProvinceName) AS StateProvinceName            
		,ISNULL(PAdress.CityId, 0) AS CityId            
		,ISNULL(LCity.City, PAdress.CityName) AS City            
		,PSMRY.ProjectTypeId            
		,PSMRY.FacilityTypeId            
		,PSMRY.ActualSizeId AS ProjectSize            
		,PSMRY.ActualCostId AS ProjectCost            
		,PSMRY.SizeUoM AS ProjectSizeUOM            
		,P.CreateDate AS CreateDate            
		,UF.LastAccessed AS ModifiedDate            
		,PSMRY.LastMasterUpdate            
		,PSMRY.IsActivateRsCitation            
		,PSMRY.IsPrintReferenceEditionDate            
		,PSMRY.IsIncludeRsInSection            
		,PSMRY.IsIncludeReInSection            
		,PSMRY.SourceTagFormat            
		,PSMRY.UnitOfMeasureValueTypeId            
		,P.IsNamewithHeld            
		,P.MasterDataTypeId            
		,LMDT.[Description] AS MasterDataTypeName            
		,LC.CountryCode          
		,PSMRY.ProjectAccessTypeId      
		,PSMRY.OwnerId      
	 FROM Project P WITH (NOLOCK)            
	 INNER JOIN LuMasterDataType LMDT WITH (NOLOCK)            
	  ON LMDT.MasterDataTypeId = P.MasterDataTypeId            
	 INNER JOIN ProjectSummary PSMRY WITH (NOLOCK)            
	  ON P.ProjectId = PSMRY.ProjectId            
	 INNER JOIN UserFolder UF WITH (NOLOCK)            
	  ON P.ProjectId = UF.ProjectId            
	 INNER JOIN ProjectAddress PAdress WITH (NOLOCK)            
	  ON P.ProjectId = PAdress.ProjectId            
	 INNER JOIN LuCountry LC WITH (NOLOCK)            
	  ON PAdress.CountryId = LC.CountryId            
	 LEFT OUTER JOIN LuStateProvince LS WITH (NOLOCK)            
	  ON PAdress.StateProvinceId = LS.StateProvinceID            
	 LEFT OUTER JOIN LuCity LCity WITH (NOLOCK)            
	  ON PAdress.CityId = LCity.CityId            
	 --LEFT OUTER JOIN ProjectGlobalTerm PGT WITH (NOLOCK)            
	 -- ON PGT.ProjectId =P.ProjectId             
	 WHERE P.ProjectId = @PProjectId            
	 AND P.CustomerId = @PCustomerId;
	 --AND PGT.[Name] = @ProjectIdGlobalTermName
END

-- EXEC [usp_GetSummaryInfo] 8932, 641, 1
GO
PRINT N'Altering [dbo].[usp_GetUpdates]...';


GO
ALTER PROCEDURE [dbo].[usp_GetUpdates]                        
@projectId INT NULL, @sectionId INT NULL, @customerId INT NULL, @userId INT NULL=0,@CatalogueType NVARCHAR (50) NULL='FS'                        
AS                        
BEGIN  
DECLARE @PprojectId INT = @projectId;  
DECLARE @PsectionId INT = @sectionId;  
DECLARE @PcustomerId INT = @customerId;  
DECLARE @PuserId INT = @userId;  
DECLARE @PCatalogueType NVARCHAR (50) = @CatalogueType;  
                        
DECLARE @totalRecords INT  
                       
--SET MASTER SECTION ID                        
DECLARE @mSectionId AS INT = ( SELECT TOP 1  
  mSectionId  
 FROM ProjectSection WITH (NOLOCK)  
 WHERE SectionId = @PsectionId  
 AND ProjectId = @PprojectId);  
  
--DECLARE VARIABLES                        
DECLARE @CURRENT_VERSION_T AS BIT = 1;  
DECLARE @CURRENT_VERSION_F AS BIT = 0;  
  
--  
DECLARE @MasterDataTypeId INT = 0;  
SELECT  
 @MasterDataTypeId = P.MasterDataTypeId  
FROM Project P WITH (NOLOCK)  
WHERE P.ProjectId = @PprojectId  
AND P.CustomerId = @PcustomerId  
  
--FETCH ALL SEGMENT STATUS WITH MASTER SOURCES          
DROP TABLE IF EXISTS #pss  
SELECT  
 SegmentStatusId  
   ,SectionId  
   ,ParentSegmentStatusId  
   ,mSegmentStatusId  
   ,mSegmentId  
   ,SegmentId  
   ,SegmentSource  
   ,SegmentOrigin  
   ,IndentLevel  
   ,SequenceNumber  
   ,SpecTypeTagId  
   ,SegmentStatusTypeId  
   ,IsParentSegmentStatusActive  
   ,ProjectId  
   ,CustomerId  
   ,SegmentStatusCode  
   ,IsShowAutoNumber  
   ,IsRefStdParagraph  
   ,FormattingJson  
   ,CreateDate  
   ,CreatedBy  
   ,ModifiedDate  
   ,ModifiedBy  
   ,IsPageBreak  
   ,SLE_DocID  
   ,SLE_ParentID  
   ,SLE_SegmentID  
   ,SLE_ProjectSegID  
   ,SLE_StatusID  
   ,A_SegmentStatusId  
   ,IsDeleted  
   ,TrackOriginOrder  
   ,MTrackDescription INTO #pss  
FROM [ProjectSegmentStatus] WITH (NOLOCK)  
WHERE SectionId = @PsectionId  
AND ProjectId = @PprojectId  
AND CustomerId = @PcustomerId  
AND ISNULL(IsDeleted,0)=0  
AND SegmentSource = 'M'  
AND IsRefStdParagraph = 0  
AND (@PCatalogueType = 'FS'  
OR SpecTypeTagId IN (1, 2))  
  
  
--FETCH TEMP SEGMENT DATA   
DROP TABLE IF EXISTS #temp_segments  
  
DROP TABLE IF EXISTS #temp  
SELECT  
 ms.SegmentId  
   ,ms.SegmentStatusId  
   ,ms.SectionId  
   ,ms.SegmentDescription  
   ,ms.SegmentSource  
   ,ms.Version  
   ,ms.SegmentCode  
   ,ms.UpdatedId  
   ,ms.CreateDate  
   ,ms.ModifiedDate  
   ,ms.PublicationDate  
   ,ms.MasterDataTypeId  
   ,pss.SectionId AS PSectionId  
   ,pss.SegmentId AS PSegmentId  
   ,pss.SegmentStatusId AS PSegmentStatusId  
   ,pss.SegmentOrigin  
   ,ISNULL(pss.IsDeleted, 0) AS ProjectSegmentIsDelete  
   ,CONVERT(BIT, 0) AS MasterSegmentIsDelete INTO #temp_segments  
FROM #pss AS pss  
INNER JOIN [SLCMaster].[dbo].[Segment] AS ms WITH (NOLOCK)  
 ON ms.SegmentId = pss.mSegmentId  
WHERE pss.SectionId = @PsectionId  
AND ms.UpdatedId IS NOT NULL  
UNION  
SELECT  
 ms.SegmentId  
   ,ms.SegmentStatusId  
   ,ms.SectionId  
   ,ms.SegmentDescription  
   ,ms.SegmentSource  
   ,ms.Version  
   ,ms.SegmentCode  
   ,ms.UpdatedId  
   ,ms.CreateDate  
   ,ms.ModifiedDate  
   ,ms.PublicationDate  
   ,ms.MasterDataTypeId  
   ,pss.SectionId AS PSectionId  
   ,pss.SegmentId AS PSegmentId  
   ,pss.SegmentStatusId AS PSegmentStatusId  
   ,pss.SegmentOrigin  
   ,ISNULL(pss.IsDeleted, 0) AS ProjectSegmentIsDelete  
   ,ISNULL(SS.IsDeleted, 0) AS MasterSegmentIsDelete  
FROM ProjectSegmentStatus AS pss WITH (NOLOCK)  
INNER JOIN SLCMaster..SegmentStatus SS WITH (NOLOCK)  
 ON pss.mSegmentStatusId = SS.SegmentStatusId  
INNER JOIN [SLCMaster].[dbo].[Segment] AS ms WITH (NOLOCK)  
 ON ms.SegmentId = pss.mSegmentId  
WHERE pss.SectionId = @PsectionId  
AND SS.IsRefStdParagraph = 0  
AND SS.IsDeleted = 1  
AND (pss.IsDeleted = 0  
OR pss.IsDeleted IS NULL);  
  
--GET VERSIONS OF THEM ALSO        
DROP TABLE IF EXISTS #temp;  
;  
WITH updates  
AS  
(SELECT  
  *  
    ,@CURRENT_VERSION_T AS isCurrentVersion  
 FROM #temp_segments  
 UNION ALL  
 SELECT  
  c.SegmentId  
    ,c.SegmentStatusId  
    ,c.SectionId  
    ,c.SegmentDescription  
    ,c.SegmentSource  
    ,c.Version  
    ,c.SegmentCode  
    ,c.UpdatedId  
    ,c.CreateDate  
    ,c.ModifiedDate  
    ,c.PublicationDate  
    ,c.MasterDataTypeId  
    ,updates.PSectionId  
    ,updates.PSegmentId  
    ,updates.PSegmentStatusId  
    ,updates.SegmentOrigin  
    ,@CURRENT_VERSION_F AS isCurrentVersion  
    ,updates.ProjectSegmentIsDelete  
  --,updates.ProjectSegmentIsDelete      
    ,updates.MasterSegmentIsDelete  
 FROM [SLCMaster].[dbo].[Segment] AS c WITH (NOLOCK)  
 INNER JOIN updates  
  ON c.SegmentId = updates.UpdatedId  
  AND c.SectionId = updates.SectionId  
 WHERE c.SectionId = @mSectionId)  
  
--SELECT MANUFACTURER DATA SEGMENT VERSION DATA                        
SELECT  
 u.SegmentId AS MSegmentId  
   ,u.SegmentStatusId AS MSegmentStatusId  
   ,u.SectionId AS MSectionId  
   ,u.SegmentDescription  
 --,dbo.fnGetSegmentDescriptionTextForChoice (u.SegmentId,'M') as SegmentDescription                        
   ,u.SegmentSource  
   ,u.SegmentCode  
   ,u.PublicationDate  
   ,u.UpdatedId AS NextVersionSegmentId  
   ,u.UpdatedId  
   ,u.PSectionId  
   ,u.PSegmentId  
   ,u.isCurrentVersion  
   ,u.[Version]  
   ,@PprojectId AS ProjectId  
   ,u.PSegmentStatusId  
   ,u.SegmentOrigin  
   ,u.SegmentDescription AS displayText  
   ,u.ProjectSegmentIsDelete  
   ,u.MasterSegmentIsDelete  
 --   ,dbo.fnGetSegmentDescriptionTextForChoice (u.SegmentId,'M') AS displayText                        
   ,IIF(lu.RequirementTagId IN (11), @CURRENT_VERSION_T, @CURRENT_VERSION_F) AS MANUFACTURER INTO #temp  
FROM updates AS u  
LEFT OUTER JOIN [SLCMaster].[dbo].[SegmentRequirementTag] AS lu WITH (NOLOCK)  
 ON lu.[SegmentStatusId] = u.SegmentStatusId  
  AND lu.[SectionId] = u.SectionId;  
  
--UPDATE DESCRIPTIONS FOR UPDATE      
--UPDATE t                        
--SET t.displayText = REPLACE(t.displayText, CONCAT('{GT#', gt.GlobalTermCode, '}'), gt.value),                  
--t.SegmentDescription=REPLACE(t.SegmentDescription, CONCAT('{GT#', gt.GlobalTermCode, '}'), gt.value)                  
--FROM #temp AS t                        
--INNER JOIN [dbo].[ProjectGlobalTerm] AS gt                        
-- ON t.projectId = gt.projectId                        
--WHERE gt.globalTermSource = 'M'                        
--AND t.displayText LIKE CONCAT('%{GT#', gt.GlobalTermCode, '}%');          
  
SELECT  
 @totalRecords = COUNT(*)  
FROM #temp AS t  
INNER JOIN [ProjectGlobalTerm] AS gt WITH (NOLOCK)  
 ON t.projectId = gt.projectId  
WHERE gt.globalTermSource = 'M'  
AND t.displayText LIKE CONCAT('%{GT#', gt.GlobalTermCode, '}%');  
  
WHILE (@totalRecords > 0)  
BEGIN  
UPDATE t  
SET t.displayText = REPLACE(t.displayText, CONCAT('{GT#', gt.GlobalTermCode, '}'), gt.value)  
   ,t.SegmentDescription = REPLACE(t.SegmentDescription, CONCAT('{GT#', gt.GlobalTermCode, '}'), gt.value)  
FROM #temp AS t  
INNER JOIN [ProjectGlobalTerm] AS gt WITH (NOLOCK)  
 ON t.projectId = gt.projectId  
WHERE gt.globalTermSource = 'M'  
AND t.displayText LIKE CONCAT('%{GT#', gt.GlobalTermCode, '}%');  
  
IF EXISTS (SELECT  
   *  
  FROM #temp AS t  
  INNER JOIN [ProjectGlobalTerm] AS gt WITH (NOLOCK)  
   ON t.projectId = gt.projectId  
  WHERE gt.globalTermSource = 'M'  
  AND t.displayText LIKE CONCAT('%{GT#', gt.GlobalTermCode, '}%'))  
BEGIN  
SELECT  
 @totalRecords = @totalRecords + 1  
END  
ELSE  
BEGIN  
SELECT  
 @totalRecords = 0  
END  
END  
  
UPDATE t  
SET t.displayText = REPLACE(t.displayText, CONCAT('{RS#', rs.RefStdCode, '}'), rs.RefStdName)  
   ,t.SegmentDescription = REPLACE(t.SegmentDescription, CONCAT('{RS#', rs.RefStdCode, '}'), rs.RefStdName)  
FROM #temp AS t  
INNER JOIN [SLCMaster].[dbo].[SegmentReferenceStandard] AS srs WITH (NOLOCK)  
 ON t.MSegmentId = srs.SegmentId  
INNER JOIN [SLCMaster].[dbo].[ReferenceStandard] AS rs WITH (NOLOCK)  
 ON rs.[RefStdId] = srs.[RefStandardId]  
WHERE t.displayText LIKE CONCAT('%{RS#', rs.RefStdCode, '}%');  
  
--SELECT SEGMENTS FINALLY                        
SELECT  
 *  
FROM #temp;  
  
--SELECT RS UPDATES    
DROP TABLE IF EXISTS #RSupdTemp  
SELECT DISTINCT  
 pss.SegmentStatusId  
   ,srs.SegmentRefStandardId  
   ,rs.RefStdId  
   ,rs.RefStdName  
   ,rs.ReplaceRefStdId  
   ,rs.RefStdCode  
   ,rse.RefStdEditionId  
   ,rse.RefEdition  
   ,rse.RefStdTitle  
   ,rse.LinkTarget INTO #RSupdTemp  
FROM #pss AS PSS  
INNER JOIN [SLCMaster].dbo.SegmentReferenceStandard AS SRS WITH (NOLOCK)  
 ON pss.mSegmentId = srs.SegmentId  
INNER JOIN [SLCMaster].dbo.ReferenceStandard AS RS WITH (NOLOCK)  
 ON RS.RefStdId = SRS.RefStandardId  
INNER JOIN [SLCMaster].[dbo].[ReferenceStandardEdition] AS RSE WITH (NOLOCK)  
 ON RSE.RefStdId = rs.RefStdId  
WHERE RS.IsObsolete = 1;  
  
DROP TABLE IF EXISTS #SegRefStd  
;  
WITH RSupdates  
AS  
(SELECT  
  *  
    ,@CURRENT_VERSION_T AS isCurrentVersion  
 FROM #RSupdTemp  
 UNION ALL  
 SELECT  
  rsu.SegmentStatusId  
    ,rsu.SegmentRefStandardId  
    ,rs.RefStdId  
    ,rs.RefStdName  
    ,rs.ReplaceRefStdId  
    ,rs.RefStdCode  
    ,rse.RefStdEditionId  
    ,rse.RefEdition  
    ,rse.RefStdTitle  
    ,rse.LinkTarget  
    ,@CURRENT_VERSION_F AS isCurrentVersion  
 FROM [SLCMaster].dbo.ReferenceStandard AS RS WITH (NOLOCK)  
 INNER JOIN RSupdates AS rsu  
  ON rs.RefStdCode = rsu.RefStdCode  
 INNER JOIN [SLCMaster].[dbo].[ReferenceStandardEdition] AS RSE WITH (NOLOCK)  
  ON RSE.RefStdId = rs.RefStdId  
 WHERE rs.RefStdId = rsu.ReplaceRefStdId)  
--SELECT DISTINCT                        
-- *        
  
--FROM RSupdates;                        
  
  
SELECT  
 * INTO #SegRefStd  
FROM (SELECT  
  PrjRefStd.ProjectId  
    ,PrjRefStd.SectionId  
    ,PrjRefStd.CustomerId  
    ,PrjRefStd.RefStandardId  
    ,'M' AS [Source]  
    ,RS.RefStdName  
  
 FROM ProjectReferenceStandard PrjRefStd WITH (NOLOCK)  
 INNER JOIN SLCMaster..SegmentReferenceStandard SRS WITH (NOLOCK)  
  ON PrjRefStd.RefStandardId = SRS.RefStandardId  
  AND PrjRefStd.RefStdSource = 'M'  
 INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)  
  ON SRS.SegmentId = PSST.mSegmentId  
 INNER JOIN SLCMaster..ReferenceStandardEdition MEDN WITH (NOLOCK)  
  ON PrjRefStd.RefStandardId = MEDN.RefStdId  
 INNER JOIN SLCMaster..ReferenceStandard RS WITH (NOLOCK)  
  ON RS.RefStdId = MEDN.RefStdId  
  
 WHERE PrjRefStd.SectionId = @PsectionId  
 AND PrjRefStd.ProjectId = @PprojectId  
 AND PrjRefStd.RefStdSource = 'M'  
 AND PrjRefStd.CustomerId = @PcustomerId  
 AND PrjRefStd.IsDeleted = 0  
 AND MEDN.RefStdEditionId > PrjRefStd.RefStdEditionId  
 AND PSST.SectionId = @PsectionId  
 AND PSST.ProjectId = @PprojectId  
 AND (PSST.IsDeleted IS NULL  
 OR PSST.IsDeleted = 0)  
 GROUP BY PrjRefStd.ProjectId  
   ,PrjRefStd.SectionId  
   ,PrjRefStd.CustomerId  
   ,PrjRefStd.RefStandardId  
   ,RS.RefStdName) T1  
  
DROP TABLE IF EXISTS #RefStdEdOld  
SELECT  
 * INTO #RefStdEdOld  
FROM (SELECT  
  OLDEDN.LinkTarget AS OldLinkTarget  
    ,OLDEDN.RefStdTitle AS OldRefStdTitle  
    ,OLDEDN.RefEdition AS OldRefEdition  
    ,OLDEDN.RefStdEditionId AS OldRefStdEditionId  
    ,PrjRefStd.RefStandardId AS PrjRefStdId  
 FROM ProjectReferenceStandard PrjRefStd WITH (NOLOCK)  
 INNER JOIN SLCMaster..ReferenceStandardEdition OLDEDN WITH (NOLOCK)  
  ON PrjRefStd.RefStdEditionId = OLDEDN.RefStdEditionId  
 WHERE PrjRefStd.SectionId = @PsectionId  
 AND PrjRefStd.ProjectId = @PprojectId  
 AND PrjRefStd.RefStdSource = 'M'  
 AND PrjRefStd.CustomerId = @PcustomerId  
 --AND PrjRefStd.RefStandardId = X1.RefStandardId  
 AND PrjRefStd.IsDeleted = 0) T2  
  
DROP TABLE IF EXISTS #RefStdEdNew  
SELECT  
 RefStdId AS PrjRefStdId  
   ,MAX(RefStdEditionId) AS NewRefStdEditionId  
   ,CAST('' AS NVARCHAR(MAX)) AS NewRefStdTitle  
   ,CAST('' AS NVARCHAR(MAX)) AS NewLinkTarget  
   ,CAST('' AS NVARCHAR(MAX)) AS NewRefEdition INTO #RefStdEdNew  
FROM SLCMaster..ReferenceStandardEdition WITH (NOLOCK)  
WHERE MasterDataTypeId = @MasterDataTypeId  
GROUP BY RefStdId  
UPDATE t  
SET t.NewRefStdTitle = e.RefStdTitle  
   ,t.NewLinkTarget = e.LinkTarget  
   ,t.NewRefEdition = e.RefEdition  
FROM #RefStdEdNew t WITH (NOLOCK)  
INNER JOIN SLCMaster..ReferenceStandardEdition e WITH (NOLOCK)  
 ON e.RefStdEditionId = t.NewRefStdEditionId  
 AND e.RefStdId = t.PrjRefStdId  

DROP TABLE if EXISTS #RefStdWithOldNewEdId  
DROP TABLE if EXISTS #NewRSInfo  
SELECT RT.RefStdId AS RefStdId    
   ,MAX(PRT.RefStdEditionId) AS OldRefStdEditionId    
   ,MAX(RSE.RefStdEditionId) AS NewRefStdEditionId    
   ,PRT.ProjectId   
   ,PRT.SectionId  
   ,PRT.CustomerId  
   INTO #RefStdWithOldNewEdId  
FROM ReferenceStandard RT   WITH(NOLOCK)INNER JOIN ProjectReferenceStandard  PRT    
on RT.RefStdId=PRT.RefStandardId and RT.CustomerId=PRT.CustomerId and RT.RefStdSource=PRT.RefStdSource   
INNER JOIN ReferenceStandardEdition RSE  WITH(NOLOCK) on PRT.RefStandardId =RSE.RefStdId   
where PRT.SectionId=@sectionId  AND PRT.ProjectId=@projectId and RT.CustomerId=@customerId and RT.RefStdSource='U'  
and  ISNULL( RT.IsDeleted,0) = 0 and ISNULL( PRT.IsDeleted ,0) = 0 
GROUP BY RT.RefStdId,PRT.ProjectId ,PRT.SectionId  
   ,PRT.CustomerId  
   --select * from #RefStdWithOldNewEdId  
     
SELECT   
    RSE.LinkTarget AS NewLinkTarget  
   ,RSE.RefEdition AS NewRefEdition  
   ,RSE.RefStdTitle AS NewRefStdTitle  
   ,RSE.RefStdEditionId AS NewRefStdEditionId  
   ,RT.RefStdId  as RefStandardId  
   INTO #NewRSInfo  
FROM ReferenceStandard RT WITH(NOLOCK)INNER JOIN #RefStdWithOldNewEdId  PRT    
on RT.RefStdId=PRT.RefStdId  
INNER JOIN ReferenceStandardEdition RSE  WITH(NOLOCK) on PRT.RefStdId =RSE.RefStdId  and RSE.RefStdEditionId=PRT.NewRefStdEditionId  
where RT.CustomerId=@customerId and RT.RefStdSource='U'  AND ISNULL( RT.IsDeleted,0) = 0 AND PRT.OldRefStdEditionId != PRT.NewRefStdEditionId 
--Drop table if exists #RefStdEdNew          
--Select *,null as MaxRefStdEditionId  into #RefStdEdNew          
--from          
--(          
--SELECT  MEDN.LinkTarget AS NewLinkTarget          
--    ,MEDN.RefEdition AS NewRefEdition          
--    ,MEDN.RefStdTitle AS NewRefStdTitle          
--    ,MEDN.RefStdEditionId AS NewRefStdEditionId          
--    ,PrjRefStd.RefStandardId As PrjRefStdId          
-- FROM ProjectReferenceStandard PrjRefStd WITH(NOLOCK)          
-- INNER JOIN SLCMaster..ReferenceStandardEdition MEDN WITH(NOLOCK)          
--  ON PrjRefStd.RefStandardId = MEDN.RefStdId          
-- WHERE PrjRefStd.ProjectId = @PprojectId          
-- AND PrjRefStd.RefStdSource = 'M'          
-- AND PrjRefStd.SectionId = @PsectionId          
-- AND PrjRefStd.CustomerId = @PcustomerId          
-- AND PrjRefStd.IsDeleted = 0          
-- --AND PrjRefStd.RefStandardId = X1.RefStandardId          
-- AND MEDN.RefStdEditionId > PrjRefStd.RefStdEditionId          
-- --ORDER BY MEDN.RefStdEditionId DESC          
--)T3          
  
  
DROP TABLE IF EXISTS #ProjRefStd  
SELECT  
 * INTO #ProjRefStd  
FROM (SELECT  
  PrjRefStd.ProjectId  
    ,PrjRefStd.SectionId  
    ,PrjRefStd.CustomerId  
    ,PrjRefStd.RefStandardId  
    ,'M' AS [Source]  
    ,RS.RefStdName  
 FROM ProjectReferenceStandard PrjRefStd WITH (NOLOCK)  
 INNER JOIN SLCMaster..ReferenceStandardEdition edition WITH (NOLOCK)  
  ON PrjRefStd.RefStandardId = edition.RefStdId  
 INNER JOIN SLCMaster..ReferenceStandard RS WITH (NOLOCK)  
  ON RS.RefStdId = edition.RefStdId  
 WHERE PrjRefStd.SectionId = @PsectionId  
 AND PrjRefStd.ProjectId = @PprojectId  
 AND PrjRefStd.CustomerId = @PcustomerId  
 AND PrjRefStd.RefStdSource = 'M'  
 AND PrjRefStd.IsDeleted = 0  
 AND edition.RefStdEditionId > PrjRefStd.RefStdEditionId  
 GROUP BY PrjRefStd.ProjectId  
   ,PrjRefStd.SectionId  
   ,PrjRefStd.CustomerId  
   ,PrjRefStd.RefStandardId  
   ,RS.RefStdName) Ta  
  
DROP TABLE IF EXISTS #PRefStdOld  
SELECT  
 * INTO #PRefStdOld  
FROM (SELECT  
  OLDEDN.LinkTarget AS OldLinkTarget  
    ,OLDEDN.RefStdTitle AS OldRefStdTitle  
    ,OLDEDN.RefEdition AS OldRefEdition  
    ,OLDEDN.RefStdEditionId AS OldRefStdEditionId  
    ,PrjRefStd.RefStandardId AS PrjRefStdId  
 FROM ProjectReferenceStandard PrjRefStd WITH (NOLOCK)  
 INNER JOIN SLCMaster..ReferenceStandardEdition OLDEDN WITH (NOLOCK)  
  ON PrjRefStd.RefStdEditionId = OLDEDN.RefStdEditionId  
 WHERE PrjRefStd.SectionId = @PsectionId  
 AND PrjRefStd.ProjectId = @PprojectId  
 AND PrjRefStd.CustomerId = @PcustomerId  
 AND PrjRefStd.RefStdSource = 'M'  
 AND PrjRefStd.IsDeleted = 0  
--AND PrjRefStd.RefStandardId = X1.RefStandardId  
) Tb  
  
--DROP TABLE IF EXISTS #PRefStdNew  
--SELECT  
-- * INTO #PRefStdNew  
--FROM (SELECT  
--  MEDN.LinkTarget AS NewLinkTarget  
--    ,MEDN.RefEdition AS NewRefEdition  
--    ,MEDN.RefStdTitle AS NewRefStdTitle  
--    ,MEDN.RefStdEditionId AS NewRefStdEditionId  
--    ,PrjRefStd.RefStandardId AS PrjRefStdId  
-- FROM ProjectReferenceStandard PrjRefStd WITH (NOLOCK)  
-- INNER JOIN SLCMaster..ReferenceStandardEdition MEDN WITH (NOLOCK)  
--  ON PrjRefStd.RefStandardId = MEDN.RefStdId  
-- WHERE PrjRefStd.ProjectId = @PprojectId  
-- AND PrjRefStd.RefStdSource = 'M'  
-- AND PrjRefStd.SectionId = @PsectionId  
-- AND PrjRefStd.CustomerId = @PcustomerId  
-- --AND PrjRefStd.RefStandardId = X1.RefStandardId  
-- AND PrjRefStd.IsDeleted = 0  
-- AND MEDN.RefStdEditionId > PrjRefStd.RefStdEditionId  
----ORDER BY MEDN.RefStdEditionId DESC  
--) Tc  
  
  
  
;  
WITH cte1  
AS  
(SELECT  
  ROW_NUMBER() OVER (PARTITION BY RefStandardId ORDER BY RefStandardId) Rownum  
    ,ProjectId  
    ,SectionId  
    ,CustomerId  
    ,RefStandardId  
    ,Source  
    ,RefStdName  
    ,OldLinkTarget  
    ,OldRefStdTitle  
    ,OldRefEdition  
    ,OldRefStdEditionId  
    ,NewLinkTarget  
    ,NewRefEdition  
    ,NewRefStdTitle  
    ,NewRefStdEditionId  
 FROM #SegRefStd R1  
 INNER JOIN #RefStdEdOld R2  
  ON R1.RefStandardId = R2.PrjRefStdId  
 INNER JOIN #RefStdEdNew R3  
  ON R1.RefStandardId = R3.PrjRefStdId),  
cte2  
AS  
(SELECT  
  ROW_NUMBER() OVER (PARTITION BY RefStandardId ORDER BY RefStandardId) Rownum  
    ,ProjectId  
    ,SectionId  
    ,CustomerId  
    ,RefStandardId  
    ,Source  
    ,RefStdName  
    ,OldLinkTarget  
    ,OldRefStdTitle  
    ,OldRefEdition  
    ,OldRefStdEditionId  
    ,NewLinkTarget  
    ,NewRefEdition  
    ,NewRefStdTitle  
    ,NewRefStdEditionId  
 FROM #ProjRefStd R1  
 INNER JOIN #PRefStdOld R2  
  ON R1.RefStandardId = R2.PrjRefStdId  
 INNER JOIN #RefStdEdNew R3  
  ON R1.RefStandardId = R3.PrjRefStdId)  
  
SELECT  
 ProjectId  
   ,SectionId  
   ,CustomerId  
   ,RefStandardId  
   ,Source  
   ,RefStdName  
   ,OldLinkTarget  
   ,OldRefStdTitle  
   ,OldRefEdition  
   ,OldRefStdEditionId  
   ,NewLinkTarget  
   ,NewRefEdition  
   ,NewRefStdTitle  
   ,NewRefStdEditionId  
FROM cte1  
WHERE Rownum = 1  
UNION  
SELECT  
 ProjectId  
   ,SectionId  
   ,CustomerId  
   ,RefStandardId  
   ,Source  
   ,RefStdName  
   ,OldLinkTarget  
   ,OldRefStdTitle  
   ,OldRefEdition  
   ,OldRefStdEditionId  
   ,NewLinkTarget  
   ,NewRefEdition  
   ,NewRefStdTitle  
   ,NewRefStdEditionId  
FROM cte2  
WHERE Rownum = 1  
UNION  
SELECT   
    PRT.ProjectId   
   ,PRT.SectionId  
   ,PRT.CustomerId  
   ,RT.RefStdId  as RefStandardId  
   ,RT.RefStdSource AS [Source]  
   ,RefStdName  
   ,RSE.LinkTarget AS OldLinkTarget  
   ,RSE.RefStdTitle AS OldRefStdTitle  
   ,RSE.RefEdition AS OldRefEdition  
   ,RSE.RefStdEditionId AS OldRefStdEditionId  
   ,NewLinkTarget  
   ,NewRefEdition  
   ,NewRefStdTitle  
   ,NRSI.NewRefStdEditionId  
FROM ReferenceStandard RT   WITH(NOLOCK)INNER JOIN #RefStdWithOldNewEdId  PRT    
on RT.RefStdId=PRT.RefStdId  
INNER JOIN ReferenceStandardEdition RSE  WITH(NOLOCK) on PRT.RefStdId =RSE.RefStdId  and RSE.RefStdEditionId=PRT.OldRefStdEditionId  
INNER JOIN #NewRSInfo NRSI on NRSI.RefStandardId =RSE.RefStdId   
where RT.CustomerId=@PcustomerId and RT.RefStdSource='U' AND ISNULL( RT.IsDeleted,0) = 0  
  
  
--GET SEGMENT CHOICES                        
SELECT  
DISTINCT  
 SCH.SegmentChoiceId  
   ,SCH.SegmentChoiceCode  
   ,SCH.SectionId  
   ,SCH.ChoiceTypeId  
   ,SCH.SegmentId  
FROM SLCMaster..SegmentChoice SCH WITH (NOLOCK)  
INNER JOIN #temp TMPSG  
 ON SCH.SegmentId = TMPSG.MSegmentId  
  
--GET SEGMENT CHOICES OPTIONS                        
SELECT DISTINCT  
 CHOP.SegmentChoiceId  
   ,CAST(CHOP.ChoiceOptionId AS BIGINT) AS ChoiceOptionId  
   ,CHOP.SortOrder  
   ,SCHOP.IsSelected  
   ,CHOP.ChoiceOptionCode  
   ,CHOP.OptionJson  
FROM SLCMaster..SegmentChoice SCH WITH (NOLOCK)  
INNER JOIN SLCMaster..ChoiceOption CHOP WITH (NOLOCK)  
 ON SCH.SegmentChoiceId = CHOP.SegmentChoiceId  
INNER JOIN SLCMaster..SelectedChoiceOption SCHOP WITH (NOLOCK)  
 ON SCHOP.ChoiceOptionCode = CHOP.ChoiceOptionCode  
INNER JOIN #temp TMPSG  
 ON SCH.SegmentId = TMPSG.MSegmentId  
  
--GET REF STD'S                        
--SELECT      
-- RS.RefStdId      
--   ,RS.RefStdName      
--   ,ISNULL(RS.ReplaceRefStdId,0) AS ReplaceRefStdId    
--   ,RS.IsObsolete      
--   ,RS.RefStdCode      
--FROM [SLCMaster].dbo.ReferenceStandard AS RS WITH (NOLOCK);  
  
--GET SECTIONS LIST    -- TODO - Remove sections from here                    
SELECT  
 MS.SectionId  
   ,MS.SectionCode  
   ,MS.Description  
   ,MS.SourceTag  
FROM SLCMaster..Section MS WITH (NOLOCK)  
WHERE MS.MasterDataTypeId = @MasterDataTypeId  
AND MS.IsLastLevel = 1  
ORDER BY MS.SourceTag ASC  
END
GO
PRINT N'Altering [dbo].[usp_UnArchiveProject]...';


GO
ALTER PROC usp_UnArchiveProject  
(  
 @CustomerId INT,  
 @ArchiveProjectId INT,  
 @UserId INT,  
 @ModifiedByFullName NVARCHAR(50)=''  
)  
AS  
BEGIN  
  
 UPDATE P  
 SET P.IsArchived=0
	 --P.IsShowMigrationPopup=0
 FROM Project P WITH(NOLOCK)  
 WHERE P.ProjectId=@ArchiveProjectId  AND P.CustomerId=@CustomerId
  
 UPDATE UF  
 SET UF.UserId=@UserId,  
  UF.LastAccessed=GETUTCDATE(),  
  LastAccessByFullName=@ModifiedByFullName  
 FROM UserFolder UF WITH(NOLOCK)  
 WHERE UF.ProjectId=@ArchiveProjectId  
 AND UF.CustomerId=@CustomerId
END
GO
PRINT N'Altering [dbo].[usp_CreateSegmentsForImportedSectionForImportProject]...';


GO
ALTER PROCEDURE [dbo].[usp_CreateSegmentsForImportedSectionForImportProject]  
@IsAutoSelectParagraph BIT ,  
@InpSegmentJson NVARCHAR(MAX)  
AS    
      
BEGIN  
    
DECLARE @PInpSegmentJson NVARCHAR(MAX) = @InpSegmentJson;  
--Set Nocount On    
SET NOCOUNT ON;  
    
DECLARE @ProjectId INT;  
    
DECLARE @SectionId INT;  
    
DECLARE @CustomerId INT;  
    
DECLARE @UserId INT;  
    
    
 --DECLARE INP SEGMENT TABLE     
 CREATE TABLE #InpSegmentTableVar(      
 RowId INT NULL ,      
 SectionId INT,      
 ParentSegmentStatusId INT,    
 IndentLevel TINYINT,    
 SegmentStatusTypeId INT DEFAULT 2,    
 IsParentSegmentStatusActive BIT,    
 SpecTypeTagId INT NULL,    
 ProjectId INT,    
 CustomerId INT DEFAULT 0,    
 CreatedBy INT DEFAULT 0,    
 IsRefStdParagraph BIT DEFAULT 0,    
 SequenceNumber DECIMAL(18,4) DEFAULT 2,    
 TempSegmentStatusId INT NULL,    
 SegmentStatusId INT NULL 
 );  
    
    
 --PUT FETCHED INP RESULT IN LOCAL TABLE VARIABLE     
IF @PInpSegmentJson != ''    
BEGIN  
INSERT INTO #InpSegmentTableVar  
 SELECT  
  *  
 FROM OPENJSON(@PInpSegmentJson)  
 WITH (  
 RowId INT '$.RowId',  
 SectionId INT '$.SectionId',  
 ParentSegmentStatusId INT '$.ParentSegmentStatusId',  
 IndentLevel TINYINT '$.IndentLevel',  
 SegmentStatusTypeId INT '$.SegmentStatusTypeId',  
 IsParentSegmentStatusActive BIT '$.IsParentSegmentStatusActive',  
 SpecTypeTagId INT '$.SpecTypeTagId',  
 ProjectId INT '$.ProjectId',  
 CustomerId NVARCHAR(MAX) '$.CustomerId',  
 CreatedBy INT '$.CreatedBy',  
 IsRefStdParagraph BIT '$.IsRefStdParagraph',  
 SequenceNumber DECIMAL(18, 4) '$.SequenceNumber',  
 TempSegmentStatusId BIT '$.TempSegmentStatusId',  
 SegmentStatusId INT '$.SegmentStatusId' 
 );  
END  
  
SELECT TOP 1  
 @ProjectId = ProjectId  
   ,@SectionId = SectionId  
   ,@CustomerId = CustomerId  
   ,@UserId = CreatedBy  
FROM #InpSegmentTableVar  
  
--SET PROPER DIVISION ID FOR IMPORTED SECTION  
EXEC usp_SetDivisionIdForUserSection @ProjectId  
         ,@SectionId  
         ,@CustomerId  
  
   
--UPDATE SOME VALUES IN TABLE TO DEFAULT    
UPDATE INPTBL  
SET INPTBL.SegmentStatusTypeId = (CASE  
  WHEN @IsAutoSelectParagraph = 1 THEN 2  
  ELSE 6  
 END)  
   ,INPTBL.TempSegmentStatusId = INPTBL.SegmentStatusId  
   ,INPTBL.IsParentSegmentStatusActive = (  
 CASE  
  WHEN @IsAutoSelectParagraph = 1 THEN 1  
  WHEN INPTBL.SequenceNumber = 0 THEN 1  
  ELSE 0  
 END)  
FROM #InpSegmentTableVar INPTBL  
  
----INSERT DATA IN SegmentStatus    
----NOTE -- HERE Saving TempSegmentStatusId in ParentSegmentStatusId for join purpose    
INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId,  
SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId,  
SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId,  
IsShowAutoNumber, CreateDate, CreatedBy, IsRefStdParagraph,  
mSegmentStatusId, mSegmentId)  
 SELECT  
  INPTBL.SectionId  
    ,INPTBL.TempSegmentStatusId AS ParentSegmentStatusId  
    ,NULL AS SegmentId  
    ,'U' AS SegmentSource  
    ,'U' AS SegmentOrigin  
    ,INPTBL.IndentLevel  
    ,INPTBL.SequenceNumber  
    ,CASE  
   WHEN INPTBL.SpecTypeTagId = 0 THEN NULL  
   ELSE INPTBL.SpecTypeTagId  
  END AS SpecTypeTagId  
    ,INPTBL.SegmentStatusTypeId  
    ,INPTBL.IsParentSegmentStatusActive  
    ,INPTBL.ProjectId  
    ,INPTBL.CustomerId  
    ,1 AS IsShowAutoNumber  
    ,GETUTCDATE() AS CreateDate  
    ,INPTBL.CreatedBy  
    ,INPTBL.IsRefStdParagraph 
    ,0 AS mSegmentStatusId  
    ,0 AS mSegmentId  
 FROM #InpSegmentTableVar INPTBL  
 ORDER BY INPTBL.RowId ASC  
  
----UPDATE Corrected SegmentStatusId IN INP TBL    
UPDATE INPTBL  
SET INPTBL.SegmentStatusId = PSST.SegmentStatusId  
FROM #InpSegmentTableVar INPTBL  
INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)  
 ON INPTBL.ProjectId = @ProjectId  
 AND INPTBL.CustomerId = @CustomerId  
 AND INPTBL.SectionId = @SectionId  
 AND INPTBL.TempSegmentStatusId = PSST.ParentSegmentStatusId  
 AND PSST.SectionId = @SectionId  
 AND psst.ProjectId = @ProjectId  
 AND PSST.CustomerId = @CustomerId  
  
----NOW UPDATE PARENT SEGMENT STATUS ID TO -1 WHICH WILL GET UPDATED LATER FROM API    
UPDATE PSST  
SET PSST.ParentSegmentStatusId = -1  
FROM ProjectSegmentStatus PSST WITH (NOLOCK)  
WHERE PSST.ProjectId = @ProjectId  
AND PSST.SectionId = @SectionId  
AND PSST.CustomerId = @CustomerId  
  
----INSERT INTO PROJECT SEGMENT    
INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription,  
SegmentSource, CreatedBy, CreateDate)  
 SELECT  
  INPTBL.SegmentStatusId  
    ,INPTBL.SectionId  
    ,INPTBL.ProjectId  
    ,INPTBL.CustomerId  
    ,'' AS SegmentDescription  
    ,'U' AS SegmentSource  
    ,INPTBL.CreatedBy  
    ,GETUTCDATE() AS CreateDate 
 FROM #InpSegmentTableVar INPTBL  
  
----UPDATE SEGMENT ID IN SEGMENT STATUS    
UPDATE PSST  
SET PSST.SegmentId = PSG.SegmentId  
FROM ProjectSegmentStatus PSST WITH (NOLOCK)  
INNER JOIN ProjectSegment PSG WITH (NOLOCK)  
 ON PSST.SegmentStatusId = PSG.SegmentStatusId  
WHERE PSST.ProjectId = @ProjectId  
AND PSST.CustomerId = @CustomerId  
AND PSST.SectionId = @SectionId  
  
----SELECT RESULT GRID    
SELECT  
 INPTBL.SegmentStatusId  
   ,INPTBL.TempSegmentStatusId  
   ,PSST.SegmentId  
FROM #InpSegmentTableVar INPTBL  
INNER JOIN ProjectSegmentStatus PSST (NOLOCK)  
 ON PSST.ProjectId = @ProjectId  
  AND PSST.CustomerId = @CustomerId  
  AND PSST.SectionId = @SectionId  
  AND PSST.SegmentStatusId = INPTBL.SegmentStatusId  
END
GO
PRINT N'Altering [dbo].[usp_GetSegmentLinkDetailsNew]...';


GO
ALTER PROCEDURE [dbo].[usp_GetSegmentLinkDetailsNew] (    
 @InpSegmentLinkJson NVARCHAR(MAX)  
)   
AS            
BEGIN              
--PARAMETER SNIFFING CARE              
DECLARE @PInpSegmentLinkJson NVARCHAR(MAX) = @InpSegmentLinkJson;             
              
/** [BLOCK] LOCAL VARIABLES **/              
BEGIN              
--SET NO COUNT ON                  
SET NOCOUNT ON;              
                
--DECLARE TYPES OF LINKS                  
DECLARE @P2P INT = 1;              
DECLARE @P2C INT = 2;              
            
DECLARE @C2P INT = 3;              
DECLARE @C2C INT = 4;              
               
--DECLARE TAGS VARIABLES                
DECLARE @RS_TAG INT = 22;              
DECLARE @RT_TAG INT = 23;              
DECLARE @RE_TAG INT = 24;              
DECLARE @ST_TAG INT = 25;              
              
--DECLARE LOOPED VARIABLES                  
DECLARE @LoopedSectionId INT = 0;              
DECLARE @LoopedSegmentStatusCode INT = 0;              
DECLARE @LoopedSegmentSource CHAR(1) = '';              
               
--DECALRE COMMON VARIABLES FROM INP JSON                
DECLARE @ProjectId INT = 0;              
DECLARE @CustomerId INT = 0;              
DECLARE @UserId INT = 0;              
        
--DECLARE FIELD WHICH SHOWS RECORD TYPE                
DECLARE @SourceOfRecord_Master VARCHAR(1) = 'M';              
DECLARE @SourceOfRecord_Project VARCHAR(1) = 'U';              
              
DECLARE @Master_LinkTypeId INT = 1;              
DECLARE @RS_LinkTypeId INT = 2;              
DECLARE @RE_LinkTypeId INT = 3;              
DECLARE @LinkManE_LinkTypeId INT = 4;         
DECLARE @USER_LinkTypeId INT = 5;              
              
--DECLARE VARIABLES USED IN UNIQUE SECTION CODES COUNT                  
DECLARE @UniqueSectionCodesLoopCnt INT = 1;              
DECLARE @InpSegmentLinkLoopCnt INT = 1;              
              
--DECLARE VARIABLES FOR ITERATIONS              
DECLARE @MaxIteration INT = 2;        
        
--DECLARE INP SEGMENT LINK VAR              
DROP TABLE IF EXISTS #InputDataTable              
CREATE TABLE #InputDataTable (              
   RowId INT NOT NULL PRIMARY KEY              
   ,ProjectId INT NOT NULL              
   ,CustomerId INT NOT NULL              
   ,SectionId INT NOT NULL              
   ,SectionCode INT NOT NULL              
   ,SegmentStatusCode INT NULL              
   ,SegmentSource CHAR(1) NULL              
   ,UserId INT NOT NULL              
);  
              
--CREATE TEMP TABLE TO STORE SEGMENT LINK IN DATA              
DROP TABLE IF EXISTS #SegmentLinkTable              
CREATE TABLE #SegmentLinkTable (              
 SegmentLinkId INT              
   ,SourceSectionCode INT              
   ,SourceSegmentStatusCode INT              
   ,SourceSegmentCode INT              
   ,SourceSegmentChoiceCode INT              
   ,SourceChoiceOptionCode INT              
   ,LinkSource CHAR(1)              
   ,TargetSectionCode INT              
   ,TargetSegmentStatusCode INT              
   ,TargetSegmentCode INT              
   ,TargetSegmentChoiceCode INT              
   ,TargetChoiceOptionCode INT              
   ,LinkTarget CHAR(1)              
   ,LinkStatusTypeId INT              
   ,IsDeleted BIT              
   ,SegmentLinkCode INT              
   ,SegmentLinkSourceTypeId INT              
   ,IsTgtLink BIT          
   ,IsSrcLink BIT              
   ,SourceOfRecord CHAR(1)              
   ,Iteration INT            
   ,ProjectId INT  -- Added By Bhushan  
);  
              
--CREATE TEMP TABLE TO STORE SEGMENT STATUS DATA              
DROP TABLE IF EXISTS #SegmentStatusTable              
CREATE TABLE #SegmentStatusTable (              
 ProjectId INT              
   ,SectionId INT              
   ,CustomerId INT              
   ,SegmentStatusId INT              
   ,SegmentStatusCode INT              
   ,SegmentStatusTypeId INT              
   ,IsParentSegmentStatusActive BIT              
   ,ParentSegmentStatusId INT              
   ,SectionCode INT              
   ,SegmentSource CHAR(1)           
   ,SegmentOrigin CHAR(1)              
   ,ChildCount INT              
   ,SrcLinksCnt INT              
   ,TgtLinksCnt INT              
   ,SequenceNumber DECIMAL(18, 4)              
   ,mSegmentStatusId INT              
   ,SegmentCode INT              
   ,mSegmentId INT              
   ,SegmentId INT              
   ,IsFetchedDbLinkResult BIT              
);              
              
--CREATE TEMP TABLE TO STORE UNIQUE TARGET SECTION CODE DATA              
DROP TABLE IF EXISTS #TargetSectionCodeTable              
CREATE TABLE #TargetSectionCodeTable (              
 Id INT              
   ,SectionCode INT              
   ,SectionId INT              
);              
              
--CREATE TEMP TABLE TO STORE CHOICES DATA              
DROP TABLE IF EXISTS #SegmentChoiceTable              
CREATE TABLE #SegmentChoiceTable (              
 ProjectId INT              
   ,SectionId INT              
   ,CustomerId INT              
   ,SegmentChoiceCode INT              
  ,SegmentChoiceSource CHAR(1)              
   ,ChoiceTypeId INT              
   ,ChoiceOptionCode INT              
   ,ChoiceOptionSource CHAR(1)              
   ,IsSelected BIT              
   ,SectionCode INT              
   ,SegmentStatusId INT              
   ,mSegmentId INT              
   ,SegmentId INT              
   ,SelectedChoiceOptionId INT              
);              
END                  
/** [BLOCK] FETCH INPUT DATA INTO TEMP TABLE **/              
BEGIN              
--PUT FETCHED INP RESULT IN LOCAL TABLE VARIABLE                 
IF @PInpSegmentLinkJson != ''              
BEGIN              
INSERT INTO #InputDataTable              
 SELECT              
  ROW_NUMBER() OVER (ORDER BY ProjectId ASC) AS RowId              
    ,ProjectId              
    ,CustomerId              
    ,SectionId              
    ,SectionCode              
    ,SegmentStatusCode              
    ,SegmentSource              
    ,UserId              
 FROM OPENJSON(@PInpSegmentLinkJson)              
 WITH (              
 ProjectId INT '$.ProjectId',              
 CustomerId INT '$.CustomerId',              
 SectionId INT '$.SectionId',              
 SectionCode INT '$.SectionCode',              
 SegmentStatusCode INT '$.SegmentStatusCode',              
 SegmentSource CHAR(1) '$.SegmentSource',              
 UserId INT '$.UserId'              
 );              
END              
END              
              
/** [BLOCK] FETCH COMMON INPUT DATA INTO VARIABLES **/              
BEGIN              
--SET COMMON VARIABLES FROM INP JSON                
SELECT TOP 1   
    @ProjectId = ProjectId              
   ,@CustomerId = CustomerId              
   ,@UserId = UserId              
FROM #InputDataTable
OPTION (FAST 1);             
END  
    
-- Create #ProjectSection table and store ProjectSection data  
-- Note : This is then used to identify that target sections are opned and if not then insert data  
BEGIN  
 DROP TABLE IF EXISTS #ProjectSection;  
 CREATE TABLE #ProjectSection (              
  SectionId INT NOT NULL PRIMARY KEY              
    ,SectionCode INT NOT NULL  
    ,IsLastLevel BIT NULL  
    ,mSectionId INT NULL  
 );  
 INSERT INTO #ProjectSection  
 SELECT PS.SectionId, PS.SectionCode, PS.IsLastLevel, PS.mSectionId    
 FROM ProjectSection PS with (nolock)
 WHERE PS.ProjectId = @ProjectId AND PS.IsDeleted = 0;  
END             
              
/** [BLOCK] MAP CLICKED SECTION DATA IF NOT OPENED **/              
BEGIN              
--LOOP INP SEGMENT LINK TABLE TO MAP SEGMENT STATUS AND CHOICES IF SECTION STATUS IS CLICKED                
declare @InputDataTableRowCount INT=(SELECT              
  COUNT(1)              
 FROM #InputDataTable)              
WHILE @InpSegmentLinkLoopCnt <= @InputDataTableRowCount              
BEGIN              
IF EXISTS (SELECT TOP 1              
   1             
  FROM #InputDataTable              
  WHERE RowId = @InpSegmentLinkLoopCnt              
  AND SegmentStatusCode <= 0)              
BEGIN              
SET @LoopedSectionId = 0;              
SET @LoopedSegmentStatusCode = 0;              
SET @LoopedSegmentSource = '';              
              
SELECT              
 @LoopedSectionId = SectionId              
FROM #InputDataTable              
WHERE RowId = @InpSegmentLinkLoopCnt   
OPTION (FAST 1);           
 
 DECLARE @HasProjectSegmentStatus INT =0;
        
SELECT TOP 1              
   @HasProjectSegmentStatus = COUNT(1)             
  FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)              
  WHERE PSST.ProjectId = @ProjectId              
  AND PSST.CustomerId = @CustomerId              
  AND PSST.SectionId = @LoopedSectionId 
  OPTION (FAST 1);   
IF (@HasProjectSegmentStatus = 0)             
BEGIN              
EXEC usp_MapSegmentStatusFromMasterToProject @ProjectId = @ProjectId              
           ,@SectionId = @LoopedSectionId              
            ,@CustomerId = @CustomerId              
            ,@UserId = @UserId;              
END              
 
 DECLARE @HasSelectedChoiceOption INT = 0;

SELECT TOP 1 @HasSelectedChoiceOption = COUNT(1)              
  FROM SelectedChoiceOption AS PSCHOP WITH (NOLOCK)              
  WHERE PSCHOP.SectionId = @LoopedSectionId              
  AND PSCHOP.ProjectId = @ProjectId               
  AND PSCHOP.ChoiceOptionSource = 'M'               
  AND PSCHOP.CustomerId = @CustomerId
   OPTION (FAST 1); 
IF (@HasSelectedChoiceOption = 0)              
BEGIN              
EXEC usp_MapSegmentChoiceFromMasterToProject @ProjectId = @ProjectId              
            ,@SectionId = @LoopedSectionId              
            ,@CustomerId = @CustomerId              
            ,@UserId = @UserId;              
END              
 
 DECLARE @HasProjectSegmentRequirementTag INT = 0;
 SELECT TOP 1 @HasProjectSegmentRequirementTag = COUNT(1)             
  FROM ProjectSegmentRequirementTag AS PSRT WITH (NOLOCK)              
  WHERE PSRT.ProjectId = @ProjectId              
  AND PSRT.CustomerId = @CustomerId              
  AND PSRT.SectionId = @LoopedSectionId
  OPTION (FAST 1);              
IF (@HasProjectSegmentRequirementTag = 0)             
BEGIN              
EXEC usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @ProjectId              
              ,@SectionId = @LoopedSectionId              
              ,@CustomerId = @CustomerId              
              ,@UserId = @UserId;              
END              
              
--EXEC dbo.usp_MapSegmentLinkFromMasterToProject @ProjectId = @ProjectId              
--             ,@SectionId = @LoopedSectionId              
--             ,@CustomerId = @CustomerId              
--        ,@UserId = @UserId;              
              
--FETCH TOP MOST SEGMENT STATUS CODE FROM SEGMENT STATUS ITS SOURCE                  
SELECT TOP 1              
 @LoopedSegmentStatusCode = SegmentStatusCode              
   ,@LoopedSegmentSource = SegmentOrigin              
FROM ProjectSegmentStatus WITH (NOLOCK)              
WHERE SectionId = @LoopedSectionId              
AND ProjectId = @ProjectId              
AND CustomerId = @CustomerId              
AND ParentSegmentStatusId = 0
OPTION (FAST 1);             
              
UPDATE TMPTBL              
SET TMPTBL.SegmentStatusCode = @LoopedSegmentStatusCode              
   ,TMPTBL.SegmentSource = @LoopedSegmentSource              
FROM #InputDataTable TMPTBL WITH (NOLOCK)              
WHERE TMPTBL.RowId = @InpSegmentLinkLoopCnt              
END              
              
SET @InpSegmentLinkLoopCnt = @InpSegmentLinkLoopCnt + 1;              
               
END;              
END              
              
/** [BLOCK] GET RQEUIRED LINKS **/              
BEGIN              
  
-- Start : Create #ProjectSegmentLink table for quering links for project/section  
DROP TABLE IF EXISTS #ProjectSegmentLink;  
CREATE TABLE #ProjectSegmentLink (  
 SegmentLinkId INT NOT NULL PRIMARY KEY,  
 SourceSectionCode INT,  
 SourceSegmentStatusCode INT,  
 SourceSegmentCode INT,  
 SourceSegmentChoiceCode INT,  
 SourceChoiceOptionCode INT,  
 LinkSource CHAR(1),  
 TargetSectionCode INT,  
 TargetSegmentStatusCode INT,  
 TargetSegmentCode INT,  
 TargetSegmentChoiceCode INT,  
 TargetChoiceOptionCode INT,  
 LinkTarget CHAR(1),  
 LinkStatusTypeId INT,  
 IsDeleted INT,  
 SegmentLinkCode INT,  
 SegmentLinkSourceTypeId INT,  
 ProjectId INT,  
 CustomerId INT,  
);  
INSERT INTO #ProjectSegmentLink  
SELECT  
  PSL.SegmentLinkId              
    ,PSL.SourceSectionCode              
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
    ,PSL.SegmentLinkCode              
    ,PSL.SegmentLinkSourceTypeId  
 ,PSL.ProjectId  
 ,PSL.CustomerId  
FROM ProjectSegmentLink PSL with (nolock) 
WHERE PSL.ProjectId = @ProjectId and PSL.CustomerId = @CustomerId
-- End : Create #ProjectSegmentLink table for quering links for project/section  
   
--Print '--1. FETCH SRC LINKS FROM SLCProject..ProjectSegmentLink '           
--1. FETCH SRC LINKS FROM SLCProject..ProjectSegmentLink              
INSERT INTO #SegmentLinkTable              
 SELECT DISTINCT              
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
    ,PSLNK.IsDeleted              
    ,PSLNK.SegmentLinkCode              
    ,PSLNK.SegmentLinkSourceTypeId              
    ,0 AS IsTgtLink              
    ,1 AS IsSrcLink              
    ,@SourceOfRecord_Project AS SourceOfRecord              
    ,NULL AS Iteration          
 ,TMP.ProjectId -- Added by Bhushan              
 FROM #InputDataTable TMP WITH (NOLOCK)              
 INNER JOIN #ProjectSegmentLink PSLNK WITH (NOLOCK)              
 ON TMP.ProjectId = PSLNK.ProjectId AND             
  TMP.SectionCode = PSLNK.TargetSectionCode              
   AND TMP.SegmentStatusCode = PSLNK.TargetSegmentStatusCode              
   AND TMP.SegmentSource = PSLNK.LinkTarget              
 WHERE PSLNK.ProjectId = @ProjectId              
 AND PSLNK.CustomerId = @CustomerId              
 --AND PSLNK.IsDeleted = 0              
          
--Print '--2. FETCH TGT LINKS FROM SLCProject..ProjectSegmentLink'      --2. FETCH TGT LINKS FROM SLCProject..ProjectSegmentLink              
;WITH ProjectLinksCTE              
AS              
(SELECT              
  PSLNK.*              
    ,1 AS Iteration         
 FROM #InputDataTable TMP WITH (NOLOCK)              
 INNER JOIN #ProjectSegmentLink PSLNK WITH (NOLOCK)              
 ON TMP.ProjectId = PSLNK.ProjectId AND             
  TMP.SectionCode = PSLNK.SourceSectionCode              
  AND TMP.SegmentStatusCode = PSLNK.SourceSegmentStatusCode              
  AND TMP.SegmentSource = PSLNK.LinkSource              
 WHERE PSLNK.ProjectId = @ProjectId              
 AND PSLNK.CustomerId = @CustomerId              
 --AND PSLNK.IsDeleted = 0              
 UNION ALL              
 SELECT              
  PSLNK.*              
    ,CTE.Iteration + 1 AS Iteration              
 FROM ProjectLinksCTE CTE              
 INNER JOIN #ProjectSegmentLink PSLNK WITH (NOLOCK)              
 ON CTE.ProjectId = PSLNK.ProjectId AND             
   CTE.TargetSectionCode = PSLNK.SourceSectionCode              
  AND CTE.TargetSegmentStatusCode = PSLNK.SourceSegmentStatusCode              
  AND CTE.LinkTarget = PSLNK.LinkSource              
 WHERE PSLNK.ProjectId = @ProjectId              
 AND PSLNK.CustomerId = @CustomerId              
 --AND PSLNK.IsDeleted = 0              
 AND CTE.Iteration < @MaxIteration)        
              
INSERT INTO #SegmentLinkTable              
 SELECT DISTINCT              
  CTE.SegmentLinkId              
    ,CTE.SourceSectionCode              
    ,CTE.SourceSegmentStatusCode              
    ,CTE.SourceSegmentCode              
    ,CTE.SourceSegmentChoiceCode              
    ,CTE.SourceChoiceOptionCode              
    ,CTE.LinkSource              
    ,CTE.TargetSectionCode              
    ,CTE.TargetSegmentStatusCode              
    ,CTE.TargetSegmentCode              
    ,CTE.TargetSegmentChoiceCode              
    ,CTE.TargetChoiceOptionCode              
    ,CTE.LinkTarget              
    ,CTE.LinkStatusTypeId              
    ,CTE.IsDeleted              
    ,CTE.SegmentLinkCode              
    ,CTE.SegmentLinkSourceTypeId              
    ,1 AS IsTgtLink              
    ,0 AS IsSrcLink              
    ,@SourceOfRecord_Project AS SourceOfRecord              
    ,CTE.Iteration            
 ,@ProjectId -- Added by Bhushan            
 FROM ProjectLinksCTE CTE              
              
--3. FETCH TGT LINKS FROM SLCMaster..SegmentLink              
;              
WITH MasterLinksCTE              
AS              
(SELECT              
  MSLNK.*              
    ,1 AS Iteration              
 FROM #InputDataTable TMP WITH (NOLOCK)              
 INNER JOIN SLCMaster..SegmentLink MSLNK WITH (NOLOCK)              
  ON TMP.SectionCode = MSLNK.SourceSectionCode              
  AND TMP.SegmentStatusCode = MSLNK.SourceSegmentStatusCode              
  AND TMP.SegmentSource = MSLNK.LinkSource          
 WHERE MSLNK.IsDeleted = 0              
 UNION ALL              
 SELECT              
  MSLNK.*              
    ,CTE.Iteration + 1 AS Iteration              
 FROM MasterLinksCTE CTE              
 INNER JOIN SLCMaster..SegmentLink MSLNK WITH (NOLOCK)              
  ON CTE.TargetSectionCode = MSLNK.SourceSectionCode              
  AND CTE.TargetSegmentStatusCode = MSLNK.SourceSegmentStatusCode              
  AND CTE.LinkTarget = MSLNK.LinkSource              
 WHERE MSLNK.IsDeleted = 0              
 AND CTE.Iteration < @MaxIteration)              
              
INSERT INTO #SegmentLinkTable              
 SELECT DISTINCT              
  CTE.SegmentLinkId              
    ,CTE.SourceSectionCode              
    ,CTE.SourceSegmentStatusCode                  
 ,CTE.SourceSegmentCode              
    ,CTE.SourceSegmentChoiceCode              
    ,CTE.SourceChoiceOptionCode              
    ,CTE.LinkSource              
    ,CTE.TargetSectionCode              
    ,CTE.TargetSegmentStatusCode              
    ,CTE.TargetSegmentCode              
    ,CTE.TargetSegmentChoiceCode              
    ,CTE.TargetChoiceOptionCode              
    ,CTE.LinkTarget              
    ,CTE.LinkStatusTypeId              
    ,CTE.IsDeleted              
    ,CTE.SegmentLinkCode              
    ,CTE.SegmentLinkSourceTypeId              
    ,1 AS IsTgtLink              
    ,0 AS IsSrcLink              
    ,@SourceOfRecord_Master AS SourceOfRecord              
    ,CTE.Iteration          
  ,@ProjectId -- Added by Bhushan               
 FROM MasterLinksCTE CTE              
          
--Print '--4. FETCH SRC LINKS FROM SLCProject..ProjectSegmentLink FOR SETTING HIGHEST PRIORITY'          
--4. FETCH SRC LINKS FROM SLCProject..ProjectSegmentLink FOR SETTING HIGHEST PRIORITY              
INSERT INTO #SegmentLinkTable              
 SELECT DISTINCT              
  SLNK.SegmentLinkId              
    ,SLNK.SourceSectionCode              
    ,SLNK.SourceSegmentStatusCode              
    ,SLNK.SourceSegmentCode              
    ,SLNK.SourceSegmentChoiceCode              
    ,SLNK.SourceChoiceOptionCode              
    ,SLNK.LinkSource              
    ,SLNK.TargetSectionCode              
    ,SLNK.TargetSegmentStatusCode              
    ,SLNK.TargetSegmentCode              
    ,SLNK.TargetSegmentChoiceCode              
    ,SLNK.TargetChoiceOptionCode              
    ,SLNK.LinkTarget              
    ,SLNK.LinkStatusTypeId              
    ,SLNK.IsDeleted              
    ,SLNK.SegmentLinkCode       
    ,SLNK.SegmentLinkSourceTypeId              
    ,0 AS IsTgtLink              
    ,1 AS IsSrcLink              
    ,@SourceOfRecord_Project AS SourceOfRecord              
    ,NULL AS Iteration          
 ,@ProjectId AS ProjectId -- Added by Bhushan  
 FROM #SegmentLinkTable SLT WITH (NOLOCK)              
 INNER JOIN #ProjectSegmentLink SLNK WITH (NOLOCK)        
 ON SLT.ProjectId = SLNK.ProjectId -- Added by Bhushan            
   AND SLT.TargetSectionCode = SLNK.TargetSectionCode              
   AND SLT.TargetSegmentStatusCode = SLNK.TargetSegmentStatusCode              
   AND SLT.TargetSegmentCode = SLNK.TargetSegmentCode              
   AND SLT.LinkTarget = SLNK.LinkTarget              
 LEFT JOIN #SegmentLinkTable TMP WITH (NOLOCK)              
  ON SLNK.SegmentLinkCode = TMP.SegmentLinkCode              
 WHERE SLNK.ProjectId = @ProjectId              
 AND SLNK.CustomerId = @CustomerId              
 --AND SLNK.IsDeleted = 0  
 AND SLT.IsTgtLink = 1              
 AND TMP.SegmentLinkCode IS NULL              
              
--5. FETCH SRC LINKS FROM SLCMaster..SegmentLink FOR SETTING HIGHEST PRIORITY              
INSERT INTO #SegmentLinkTable              
 SELECT DISTINCT              
  SLNK.SegmentLinkId              
    ,SLNK.SourceSectionCode              
    ,SLNK.SourceSegmentStatusCode              
    ,SLNK.SourceSegmentCode              
    ,SLNK.SourceSegmentChoiceCode              
    ,SLNK.SourceChoiceOptionCode              
    ,SLNK.LinkSource              
    ,SLNK.TargetSectionCode              
    ,SLNK.TargetSegmentStatusCode              
    ,SLNK.TargetSegmentCode              
    ,SLNK.TargetSegmentChoiceCode              
    ,SLNK.TargetChoiceOptionCode              
    ,SLNK.LinkTarget              
    ,SLNK.LinkStatusTypeId        
    ,SLNK.IsDeleted              
    ,SLNK.SegmentLinkCode              
    ,SLNK.SegmentLinkSourceTypeId              
    ,0 AS IsTgtLink              
    ,1 AS IsSrcLink              
    ,@SourceOfRecord_Master AS SourceOfRecord              
    ,NULL AS Iteration          
 ,@ProjectId -- Added by Bhushan                
 FROM #SegmentLinkTable SLT WITH (NOLOCK)              
 INNER JOIN SLCMaster..SegmentLink SLNK WITH (NOLOCK)              
  ON SLT.TargetSectionCode = SLNK.TargetSectionCode              
   AND SLT.TargetSegmentStatusCode = SLNK.TargetSegmentStatusCode              
   AND SLT.TargetSegmentCode = SLNK.TargetSegmentCode              
   AND SLT.LinkTarget = SLNK.LinkTarget              
 LEFT JOIN #SegmentLinkTable TMP WITH (NOLOCK)              
  ON SLNK.SegmentLinkCode = TMP.SegmentLinkCode              
 WHERE SLNK.IsDeleted = 0              
 AND SLT.IsTgtLink = 1              
 AND TMP.SegmentLinkCode IS NULL              
              
--DELETE ALREADY MAPPED MASTER RECORDS INTO PROJECT WHICH ARE ALSO FETCHED FROM MASTER DB                
DELETE MSLNK              
 FROM #SegmentLinkTable MSLNK WITH (NOLOCK)              
 INNER JOIN #SegmentLinkTable USLNK WITH (NOLOCK)              
  ON MSLNK.SegmentLinkCode = USLNK.SegmentLinkCode              
WHERE MSLNK.SourceOfRecord = @SourceOfRecord_Master              
 AND USLNK.SourceOfRecord = @SourceOfRecord_Project              
END              
              
/** [BLOCK] FIND UNIQUE TARGET SECTIONS WHOSE DATA TO BE MAPPED **/              
BEGIN             
  
SELECT DISTINCT TargetSectionCode AS SectionCode   
INTO #DistinctTargetSectionCode  
FROM #SegmentLinkTable  
  
INSERT INTO #TargetSectionCodeTable              
 SELECT   
     ROW_NUMBER() OVER (ORDER BY X.SectionCode) AS Id              
    ,X.SectionCode              
    ,PS.SectionId              
 FROM #DistinctTargetSectionCode X  
 INNER JOIN #ProjectSection PS WITH (NOLOCK)              
  ON PS.SectionCode = X.SectionCode              
 LEFT JOIN ProjectSegmentStatus PSST WITH (NOLOCK)              
  ON
   PS.SectionId = PSST.SectionId              
   AND PSST.ParentSegmentStatusId = 0              
   AND PSST.IndentLevel = 0
   AND PSST.ProjectId = @ProjectId
 WHERE     
  PS.IsLastLevel = 1              
 AND PS.mSectionId IS NOT NULL  
 AND ISNULL(PSST.IsDeleted, 0) = 0  
 AND PSST.SegmentStatusId IS NULL  
END         
      
-- Note this can be done in background and need to resume the task from here onwards       
              
/** [BLOCK] LOOP TO MAP TARGET SECTIONS DATA **/              
BEGIN              
 declare @TargetSectionCodeTableRowCount INT=(SELECT              
  COUNT(1)              
 FROM #TargetSectionCodeTable WITH (NOLOCK))              
WHILE @UniqueSectionCodesLoopCnt <= @TargetSectionCodeTableRowCount              
BEGIN              
SET @LoopedSectionId = 0;              
SELECT TOP 1  
  @LoopedSectionId =SectionId              
 FROM #TargetSectionCodeTable WITH (NOLOCK)              
 WHERE Id = @UniqueSectionCodesLoopCnt
 OPTION (FAST 1);            
  

DECLARE @LoopedHasProjectSegmentStatus INT;
SELECT TOP 1 @LoopedHasProjectSegmentStatus = COUNT(1)
 FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)              
 WHERE PSST.SectionId = @LoopedSectionId
 AND PSST.ProjectId = @ProjectId              
 AND PSST.CustomerId = @CustomerId
  OPTION (FAST 1);
           
IF (@LoopedHasProjectSegmentStatus = 0)
BEGIN              
EXEC dbo.usp_MapSegmentStatusFromMasterToProject @ProjectId = @ProjectId              
            ,@SectionId = @LoopedSectionId              
            ,@CustomerId = @CustomerId              
            ,@UserId = @UserId;              
END              

DECLARE @LoopedHasSelectedChoiceOption INT;
SELECT TOP 1 @LoopedHasSelectedChoiceOption = COUNT(1)
  FROM SelectedChoiceOption AS PSCHOP WITH (NOLOCK)
  WHERE PSCHOP.SectionId = @LoopedSectionId
  AND PSCHOP.ProjectId = @ProjectId              
  AND PSCHOP.CustomerId = @CustomerId
  AND PSCHOP.ChoiceOptionSource = 'M'
  OPTION (FAST 1);
           
IF (@LoopedHasSelectedChoiceOption = 0)
BEGIN              
EXEC dbo.usp_MapSegmentChoiceFromMasterToProject @ProjectId = @ProjectId              
            ,@SectionId = @LoopedSectionId              
            ,@CustomerId = @CustomerId              
            ,@UserId = @UserId;           
END              
 
 DECLARE @LoopedHasProjectSegmentRequirementTag INT = 0;
  SELECT @LoopedHasProjectSegmentRequirementTag = COUNT(1)             
  FROM ProjectSegmentRequirementTag AS PSRT WITH (NOLOCK)              
  WHERE PSRT.ProjectId = @ProjectId              
  AND PSRT.CustomerId = @CustomerId              
  AND PSRT.SectionId = @LoopedSectionId  
    OPTION (FAST 1);          
IF ( @LoopedHasProjectSegmentRequirementTag = 0)          
BEGIN              
EXEC dbo.usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @ProjectId              
              ,@SectionId = @LoopedSectionId              
              ,@CustomerId = @CustomerId              
              ,@UserId = @UserId;              
END              
              
--EXEC dbo.usp_MapSegmentLinkFromMasterToProject @ProjectId = @ProjectId              
--             ,@SectionId = @LoopedSectionId              
--             ,@CustomerId = @CustomerId              
--  ,@UserId = @UserId;              
              
SET @UniqueSectionCodesLoopCnt = @UniqueSectionCodesLoopCnt + 1;              
END;            
END              
  
      
/** [BLOCK] GET SEGMENT STATUS DATA **/              
BEGIN              
INSERT INTO #SegmentStatusTable              
 --GET SEGMENT STATUS FOR PASSED INPUT DATA              
 SELECT DISTINCT              
     PSST.ProjectId              
    ,PSST.SectionId              
    ,PSST.CustomerId              
    ,PSST.SegmentStatusId              
    ,PSST.SegmentStatusCode              
    ,PSST.SegmentStatusTypeId              
    ,PSST.IsParentSegmentStatusActive              
    ,PSST.ParentSegmentStatusId              
    ,PS.SectionCode              
    ,PSST.SegmentOrigin AS SegmentSource              
    ,PSST.SegmentSource AS SegmentOrigin              
    ,0 AS ChildCount              
    ,0 AS SrcLinksCnt              
    ,0 AS TgtLinksCnt              
    ,PSST.SequenceNumber              
    ,PSST.mSegmentStatusId              
    ,(CASE            
	  WHEN PSST.SegmentSource = 'M' THEN PSST.mSegmentId
	  ELSE 0
	 END) AS SegmentCode
    ,PSST.mSegmentId              
    ,PSST.SegmentId              
  ,0 AS IsFetchedDbLinkResult              
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)              
 INNER JOIN #ProjectSection PS WITH (NOLOCK)              
  ON PSST.SectionId = PS.SectionId              
 INNER JOIN #InputDataTable IDT WITH (NOLOCK)              
  ON PS.SectionCode = IDT.SectionCode              
   AND PSST.SegmentStatusCode = IDT.SegmentStatusCode              
 WHERE PSST.ProjectId = @ProjectId              
 AND PSST.CustomerId = @CustomerId              
 --AND PS.IsDeleted = 0              
 UNION              
 --GET SEGMENT STATUS OF SOURCE RECORDS FROM FETCHED TGT LINKS              
 SELECT DISTINCT              
  PSST.ProjectId              
    ,PSST.SectionId              
    ,PSST.CustomerId              
    ,PSST.SegmentStatusId              
    ,PSST.SegmentStatusCode              
    ,PSST.SegmentStatusTypeId              
    ,PSST.IsParentSegmentStatusActive              
    ,PSST.ParentSegmentStatusId              
    ,PS.SectionCode              
    ,PSST.SegmentOrigin AS SegmentSource              
    ,PSST.SegmentSource AS SegmentOrigin              
    ,0 AS ChildCount              
    ,0 AS SrcLinksCnt              
    ,0 AS TgtLinksCnt              
    ,PSST.SequenceNumber              
    ,PSST.mSegmentStatusId              
    ,0 AS SegmentCode              
    ,PSST.mSegmentId              
    ,PSST.SegmentId              
    ,0 AS IsFetchedDbLinkResult              
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)              
 INNER JOIN #ProjectSection PS WITH (NOLOCK)              
  ON PSST.SectionId = PS.SectionId              
 INNER JOIN #SegmentLinkTable SRC_SLT WITH (NOLOCK)              
  ON PS.SectionCode = SRC_SLT.SourceSectionCode              
   AND PSST.SegmentStatusCode = SRC_SLT.SourceSegmentStatusCode              
 WHERE PSST.ProjectId = @ProjectId              
 AND PSST.CustomerId = @CustomerId              
 --AND PS.IsDeleted = 0              
 AND SRC_SLT.IsTgtLink = 1              
 UNION              
 --GET SEGMENT STATUS OF TARGET RECORDS FROM FETCHED TGT LINKS              
 SELECT DISTINCT              
  PSST.ProjectId              
    ,PSST.SectionId              
    ,PSST.CustomerId              
    ,PSST.SegmentStatusId              
    ,PSST.SegmentStatusCode              
    ,PSST.SegmentStatusTypeId              
    ,PSST.IsParentSegmentStatusActive              
    ,PSST.ParentSegmentStatusId              
    ,PS.SectionCode              
    ,PSST.SegmentOrigin AS SegmentSource              
    ,PSST.SegmentSource AS SegmentOrigin              
    ,0 AS ChildCount              
    ,0 AS SrcLinksCnt              
    ,0 AS TgtLinksCnt              
    ,PSST.SequenceNumber              
    ,PSST.mSegmentStatusId              
   ,0 AS SegmentCode              
    ,PSST.mSegmentId              
    ,PSST.SegmentId              
    ,0 AS IsFetchedDbLinkResult              
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)              
 INNER JOIN #ProjectSection PS WITH (NOLOCK)              
  ON PSST.SectionId = PS.SectionId              
 INNER JOIN #SegmentLinkTable TGT_SLT WITH (NOLOCK)              
  ON PS.SectionCode = TGT_SLT.TargetSectionCode              
   AND PSST.SegmentStatusCode = TGT_SLT.TargetSegmentStatusCode              
 WHERE PSST.ProjectId = @ProjectId              
 AND PSST.CustomerId = @CustomerId              
 --AND PS.IsDeleted = 0              
 AND TGT_SLT.IsTgtLink = 1              
 UNION              
 --GET SEGMENT STATUS OF CHILD RECORDS FROM PASSED INPUT DATA              
 SELECT DISTINCT              
  CPSST.ProjectId              
    ,CPSST.SectionId              
    ,CPSST.CustomerId              
    ,CPSST.SegmentStatusId              
    ,CPSST.SegmentStatusCode              
    ,CPSST.SegmentStatusTypeId              
    ,CPSST.IsParentSegmentStatusActive              
    ,CPSST.ParentSegmentStatusId              
    ,PS.SectionCode              
    ,CPSST.SegmentOrigin AS SegmentSource              
    ,CPSST.SegmentSource AS SegmentOrigin              
    ,0 AS ChildCount              
    ,0 AS SrcLinksCnt              
    ,0 AS TgtLinksCnt              
    ,CPSST.SequenceNumber              
    ,CPSST.mSegmentStatusId              
    ,0 AS SegmentCode              
    ,CPSST.mSegmentId              
    ,CPSST.SegmentId              
    ,0 AS IsFetchedDbLinkResult              
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)              
 INNER JOIN #ProjectSection PS WITH (NOLOCK)              
  ON PSST.SectionId = PS.SectionId              
 INNER JOIN ProjectSegmentStatus CPSST WITH (NOLOCK)              
  ON PSST.SegmentStatusId = CPSST.ParentSegmentStatusId              
 INNER JOIN #InputDataTable IDT WITH (NOLOCK)              
  ON PS.SectionCode = IDT.SectionCode              
   AND PSST.SegmentStatusCode = IDT.SegmentStatusCode              
 WHERE PSST.ProjectId = @ProjectId              
 AND PSST.CustomerId = @CustomerId              
 --AND PS.IsDeleted = 0              
 UNION              
 --GET SEGMENT STATUS OF CHILD RECORDS FOR TGT RECORDS FROM TGT LINKS              
 SELECT DISTINCT              
  CPSST.ProjectId              
    ,CPSST.SectionId              
    ,CPSST.CustomerId              
    ,CPSST.SegmentStatusId              
    ,CPSST.SegmentStatusCode              
    ,CPSST.SegmentStatusTypeId              
    ,CPSST.IsParentSegmentStatusActive              
    ,CPSST.ParentSegmentStatusId              
    ,PS.SectionCode              
    ,CPSST.SegmentOrigin AS SegmentSource              
    ,CPSST.SegmentSource AS SegmentOrigin              
    ,0 AS ChildCount              
    ,0 AS SrcLinksCnt              
    ,0 AS TgtLinksCnt              
    ,CPSST.SequenceNumber              
    ,CPSST.mSegmentStatusId              
    ,0 AS SegmentCode              
    ,CPSST.mSegmentId              
    ,CPSST.SegmentId              
    ,0 AS IsFetchedDbLinkResult              
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)              
 INNER JOIN #ProjectSection PS WITH (NOLOCK)              
  ON PSST.SectionId = PS.SectionId              
 INNER JOIN ProjectSegmentStatus CPSST WITH (NOLOCK)              
  ON PSST.SegmentStatusId = CPSST.ParentSegmentStatusId              
 INNER JOIN #SegmentLinkTable TGT_SLT WITH (NOLOCK)              
  ON PS.SectionCode = TGT_SLT.TargetSectionCode              
   AND PSST.SegmentStatusCode = TGT_SLT.TargetSegmentStatusCode              
   AND TGT_SLT.Iteration <= @MaxIteration              
 WHERE PSST.ProjectId = @ProjectId              
 AND PSST.CustomerId = @CustomerId              
 --AND PS.IsDeleted = 0              
 AND TGT_SLT.IsTgtLink = 1              
 UNION              
 --GET SEGMENT STATUS OF PARENT RECORDS FROM PASSED INPUT DATA              
 SELECT              
  PPSST.ProjectId              
    ,PPSST.SectionId              
    ,PPSST.CustomerId              
    ,PPSST.SegmentStatusId              
    ,PPSST.SegmentStatusCode              
    ,PPSST.SegmentStatusTypeId              
    ,PPSST.IsParentSegmentStatusActive              
    ,PPSST.ParentSegmentStatusId              
    ,PS.SectionCode              
    ,PPSST.SegmentOrigin AS SegmentSource              
    ,PPSST.SegmentSource AS SegmentOrigin              
    ,0 AS ChildCount              
    ,0 AS SrcLinksCnt              
    ,0 AS TgtLinksCnt              
    ,PPSST.SequenceNumber              
    ,PPSST.mSegmentStatusId              
    ,0 AS SegmentCode              
    ,PPSST.mSegmentId              
    ,PPSST.SegmentId              
    ,0 AS IsFetchedDbLinkResult              
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)              
 INNER JOIN #ProjectSection PS WITH (NOLOCK)              
  ON PSST.SectionId = PS.SectionId              
 INNER JOIN ProjectSegmentStatus PPSST WITH (NOLOCK)              
  ON PSST.ParentSegmentStatusId = PPSST.SegmentStatusId              
 INNER JOIN #InputDataTable IDT WITH (NOLOCK)              
  ON PS.SectionCode = IDT.SectionCode              
   AND PSST.SegmentStatusCode = IDT.SegmentStatusCode              
 WHERE PSST.ProjectId = @ProjectId              
 AND PSST.CustomerId = @CustomerId              
 --AND PS.IsDeleted = 0              
 UNION              
 --GET SEGMENT STATUS OF PARENT RECORDS FOR TGT RECORDS FROM TGT LINKS              
 SELECT              
  PPSST.ProjectId              
    ,PPSST.SectionId              
    ,PPSST.CustomerId              
    ,PPSST.SegmentStatusId              
    ,PPSST.SegmentStatusCode              
    ,PPSST.SegmentStatusTypeId              
    ,PPSST.IsParentSegmentStatusActive              
    ,PPSST.ParentSegmentStatusId              
    ,PS.SectionCode              
    ,PPSST.SegmentOrigin AS SegmentSource              
    ,PPSST.SegmentSource AS SegmentOrigin              
    ,0 AS ChildCount              
    ,0 AS SrcLinksCnt              
    ,0 AS TgtLinksCnt              
    ,PPSST.SequenceNumber              
    ,PPSST.mSegmentStatusId              
    ,0 AS SegmentCode              
    ,PPSST.mSegmentId              
    ,PPSST.SegmentId              
    ,0 AS IsFetchedDbLinkResult              
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)              
 INNER JOIN #ProjectSection PS WITH (NOLOCK)              
  ON PSST.SectionId = PS.SectionId              
 INNER JOIN ProjectSegmentStatus PPSST WITH (NOLOCK)              
  ON PSST.ParentSegmentStatusId = PPSST.SegmentStatusId              
 INNER JOIN #SegmentLinkTable TGT_SLT WITH (NOLOCK)              
  ON PS.SectionCode = TGT_SLT.TargetSectionCode              
   AND PSST.SegmentStatusCode = TGT_SLT.TargetSegmentStatusCode              
   AND TGT_SLT.Iteration <= @MaxIteration              
 WHERE PSST.ProjectId = @ProjectId              
 AND PSST.CustomerId = @CustomerId              
 --AND PS.IsDeleted = 0              
 AND TGT_SLT.IsTgtLink = 1              
 UNION              
 --GET SEGMENT STATUS OF SOURCE RECORDS FROM SRC LINKS              
 SELECT DISTINCT              
  PSST.ProjectId              
    ,PSST.SectionId              
    ,PSST.CustomerId              
    ,PSST.SegmentStatusId              
    ,PSST.SegmentStatusCode              
    ,PSST.SegmentStatusTypeId              
    ,PSST.IsParentSegmentStatusActive              
    ,PSST.ParentSegmentStatusId              
    ,PS.SectionCode              
    ,PSST.SegmentOrigin AS SegmentSource              
    ,PSST.SegmentSource AS SegmentOrigin              
    ,0 AS ChildCount              
    ,0 AS SrcLinksCnt              
    ,0 AS TgtLinksCnt              
    ,PSST.SequenceNumber              
    ,PSST.mSegmentStatusId              
    ,0 AS SegmentCode              
    ,PSST.mSegmentId              
    ,PSST.SegmentId              
    ,0 AS IsFetchedDbLinkResult              
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)              
 INNER JOIN ProjectSection PS WITH (NOLOCK)              
  ON PSST.SectionId = PS.SectionId              
 INNER JOIN #SegmentLinkTable SRC_SLT WITH (NOLOCK)              
  ON PS.SectionCode = SRC_SLT.SourceSectionCode              
   AND PSST.SegmentStatusCode = SRC_SLT.SourceSegmentStatusCode              
 WHERE PSST.ProjectId = @ProjectId              
 AND PSST.CustomerId = @CustomerId              
 --AND PS.IsDeleted = 0              
 AND ((PSST.IsParentSegmentStatusActive = 1              
 AND SRC_SLT.SegmentLinkSourceTypeId IN (@Master_LinkTypeId, @USER_LinkTypeId))              
 OR (              
 SRC_SLT.SegmentLinkSourceTypeId IN (@RS_LinkTypeId, @RE_LinkTypeId, @LinkManE_LinkTypeId)))              
 AND PSST.SegmentStatusTypeId < 6              
 AND SRC_SLT.IsSrcLink = 1              
              
--VIMP: In link engine SegmentSource => SegmentOrigin && SegmentOrigin => SegmentSource              
--VIMP: UPDATE PROPER VERSION OF SEGMENT CODE IN ProjectSegmentStatus TEMP TABLE              
UPDATE TMPSST              
SET TMPSST.SegmentCode = TMPSST.mSegmentId              
FROM #SegmentStatusTable TMPSST WITH (NOLOCK)              
WHERE TMPSST.SegmentSource = 'M'              
              
UPDATE TMPSST           
SET TMPSST.SegmentCode = PSG.SegmentCode              
FROM #SegmentStatusTable TMPSST WITH (NOLOCK)              
INNER JOIN ProjectSegment PSG WITH (NOLOCK)              
 ON TMPSST.SegmentId = PSG.SegmentId              
WHERE TMPSST.SegmentSource = 'U'              
END              
              
/** [BLOCK] SET CHILD COUNT AND TGT LINKS COUNT TO SEGMENT STATUS **/              
BEGIN              
--DELETE UNWANTED LINKS WHOSE VERSION DOESN'T MATCH              
DELETE SLNK              
 FROM #SegmentLinkTable SLNK WITH (NOLOCK)              
 LEFT JOIN #SegmentStatusTable SST WITH (NOLOCK)              
  ON SLNK.SourceSegmentStatusCode = SST.SegmentStatusCode              
  AND SLNK.SourceSegmentCode = SST.SegmentCode              
  AND SLNK.SourceSectionCode = SST.SectionCode              
WHERE SST.SegmentStatusId IS NULL              
              
DELETE SLNK            
 FROM #SegmentLinkTable SLNK WITH (NOLOCK)              
 LEFT JOIN #SegmentStatusTable SST WITH (NOLOCK)              
  ON SLNK.TargetSegmentStatusCode = SST.SegmentStatusCode              
  AND SLNK.TargetSegmentCode = SST.SegmentCode              
  AND SLNK.TargetSectionCode = SST.SectionCode              
WHERE SST.SegmentStatusId IS NULL              
              
--SET CHILD COUNT              
UPDATE ORIGINAL_TMPSST              
SET ORIGINAL_TMPSST.ChildCount = DUPLICATE_TMPSST.ChildCount              
FROM #SegmentStatusTable ORIGINAL_TMPSST              
INNER JOIN (SELECT DISTINCT              
  TMPSST.SegmentStatusId              
    ,COUNT(1) AS ChildCount              
 FROM #SegmentStatusTable TMPSST WITH (NOLOCK)              
 INNER JOIN dbo.ProjectSegmentStatus PSST WITH (NOLOCK)              
  ON TMPSST.SegmentStatusId = PSST.ParentSegmentStatusId              
 WHERE PSST.ProjectId = @ProjectId              
 AND PSST.CustomerId = @CustomerId              
 GROUP BY TMPSST.SegmentStatusId) DUPLICATE_TMPSST              
 ON ORIGINAL_TMPSST.SegmentStatusId = DUPLICATE_TMPSST.SegmentStatusId;              
          
--Print '--SET TGT LINKS COUNT FROM SLCProject'              
--SET TGT LINKS COUNT FROM SLCProject              
UPDATE ORIGINAL_TMPSST              
SET ORIGINAL_TMPSST.TgtLinksCnt = DUPLICATE_TMPSST.TgtLinksCnt              
FROM #SegmentStatusTable ORIGINAL_TMPSST              
INNER JOIN (SELECT DISTINCT              
  TMPSST.SegmentStatusId              
    ,COUNT(1) TgtLinksCnt              
 FROM #SegmentStatusTable TMPSST WITH (NOLOCK)              
 INNER JOIN #ProjectSegmentLink SLNK WITH (NOLOCK)              
 ON TMPSST.ProjectId = SLNK.ProjectId AND            
  TMPSST.SectionCode = SLNK.SourceSectionCode              
  AND TMPSST.SegmentStatusCode = SLNK.SourceSegmentStatusCode              
  AND TMPSST.SegmentCode = SLNK.SourceSegmentCode              
  AND TMPSST.SegmentSource = SLNK.LinkSource              
 LEFT JOIN #SegmentLinkTable TMPSLNK WITH (NOLOCK)              
  ON SLNK.SegmentLinkId = TMPSLNK.SegmentLinkId              
  AND TMPSLNK.SourceOfRecord = @SourceOfRecord_Project              
 WHERE SLNK.ProjectId = @ProjectId              
 AND SLNK.CustomerId = @CustomerId              
 AND SLNK.IsDeleted = 0              
 AND SLNK.SegmentLinkSourceTypeId = 5              
 AND TMPSLNK.SegmentLinkId IS NULL              
 GROUP BY TMPSST.SegmentStatusId) DUPLICATE_TMPSST              
 ON ORIGINAL_TMPSST.SegmentStatusId = DUPLICATE_TMPSST.SegmentStatusId;              
              
--SET TGT LINKS COUNT FROM SLCMaster              
UPDATE ORIGINAL_TMPSST              
SET ORIGINAL_TMPSST.TgtLinksCnt = ORIGINAL_TMPSST.TgtLinksCnt + DUPLICATE_TMPSST.TgtLinksCnt              
FROM #SegmentStatusTable ORIGINAL_TMPSST              
INNER JOIN (SELECT DISTINCT              
  TMPSST.SegmentStatusId              
    ,COUNT(1) TgtLinksCnt              
 FROM #SegmentStatusTable TMPSST WITH (NOLOCK)              
 INNER JOIN SLCMaster..SegmentLink SLNK WITH (NOLOCK)              
  ON TMPSST.SectionCode = SLNK.SourceSectionCode              
  AND TMPSST.SegmentStatusCode = SLNK.SourceSegmentStatusCode              
  AND TMPSST.SegmentCode = SLNK.SourceSegmentCode              
  AND TMPSST.SegmentSource = SLNK.LinkSource              
 LEFT JOIN #SegmentLinkTable TMPSLNK WITH (NOLOCK)              
  ON SLNK.SegmentLinkId = TMPSLNK.SegmentLinkId              
  AND TMPSLNK.SourceOfRecord = @SourceOfRecord_Master              
 WHERE SLNK.IsDeleted = 0              
 AND TMPSLNK.SegmentLinkId IS NULL              
 GROUP BY TMPSST.SegmentStatusId) DUPLICATE_TMPSST              
 ON ORIGINAL_TMPSST.SegmentStatusId = DUPLICATE_TMPSST.SegmentStatusId;              
END              
              
/** [BLOCK] GET SEGMENT CHOICE DATA **/              
BEGIN              
INSERT INTO #SegmentChoiceTable              
 --GET CHOICES FOR SOURCE RECORDS FROM LINKS FROM SLCMaster              
 SELECT DISTINCT              
  PSST.ProjectId              
    ,PSST.SectionId              
    ,PSST.CustomerId              
    ,CH.SegmentChoiceCode              
    ,CH.SegmentChoiceSource              
    ,CH.ChoiceTypeId              
    ,CHOP.ChoiceOptionCode              
    ,CHOP.ChoiceOptionSource              
    ,SCHOP.IsSelected              
    ,PSST.SectionCode              
    ,PSST.SegmentStatusId              
    ,PSST.mSegmentId              
    ,PSST.SegmentId              
    ,SCHOP.SelectedChoiceOptionId              
 FROM #SegmentStatusTable PSST WITH (NOLOCK)              
 INNER JOIN SLCMaster..SegmentChoice CH WITH (NOLOCK)              
  ON PSST.mSegmentId = CH.SegmentId              
 INNER JOIN SLCMaster..ChoiceOption CHOP WITH (NOLOCK)              
  ON CH.SegmentChoiceId = CHOP.SegmentChoiceId              
 INNER JOIN SelectedChoiceOption SCHOP WITH (NOLOCK)              
  ON SCHOP.CustomerId = PSST.CustomerId  
   AND SCHOP.ProjectId = PSST.ProjectId  
   AND SCHOP.SectionId = PSST.SectionId  
   AND SCHOP.SegmentChoiceCode = CH.SegmentChoiceCode  
   AND SCHOP.ChoiceOptionCode = CHOP.ChoiceOptionCode  
   AND SCHOP.ChoiceOptionSource = 'M'  
 INNER JOIN #SegmentLinkTable SRC_SLT WITH (NOLOCK)              
  ON SCHOP.SegmentChoiceCode = SRC_SLT.SourceSegmentChoiceCode              
   AND SCHOP.ChoiceOptionSource = SRC_SLT.LinkSource              
 --WHERE   
 --SCHOP.ProjectId = @ProjectId              
 --AND SCHOP.CustomerId = @CustomerId              
 --AND SCHOP.ChoiceOptionSource = 'M'  
 UNION              
 --GET CHOICES FOR TARGET RECORDS FROM LINKS FROM SLCMaster              
 SELECT DISTINCT              
  PSST.ProjectId              
    ,PSST.SectionId              
    ,PSST.CustomerId              
    ,CH.SegmentChoiceCode              
    ,CH.SegmentChoiceSource              
    ,CH.ChoiceTypeId              
    ,CHOP.ChoiceOptionCode              
    ,CHOP.ChoiceOptionSource              
    ,SCHOP.IsSelected              
    ,PSST.SectionCode              
    ,PSST.SegmentStatusId              
    ,PSST.mSegmentId              
    ,PSST.SegmentId              
    ,SCHOP.SelectedChoiceOptionId              
 FROM #SegmentStatusTable PSST WITH (NOLOCK)              
 INNER JOIN SLCMaster..SegmentChoice CH WITH (NOLOCK)              
  ON PSST.mSegmentId = CH.SegmentId              
 INNER JOIN SLCMaster..ChoiceOption CHOP WITH (NOLOCK)              
  ON CH.SegmentChoiceId = CHOP.SegmentChoiceId              
 INNER JOIN SelectedChoiceOption SCHOP WITH (NOLOCK)              
  ON SCHOP.CustomerId = PSST.CustomerId  
   AND SCHOP.ProjectId = PSST.ProjectId  
   AND SCHOP.SectionId = PSST.SectionId  
   AND SCHOP.SegmentChoiceCode = CH.SegmentChoiceCode  
   AND SCHOP.ChoiceOptionCode = CHOP.ChoiceOptionCode  
   AND SCHOP.ChoiceOptionSource = 'M'       
 INNER JOIN #SegmentLinkTable TGT_SLT WITH (NOLOCK)              
  ON SCHOP.SegmentChoiceCode = TGT_SLT.TargetSegmentChoiceCode              
   AND SCHOP.ChoiceOptionSource = TGT_SLT.LinkTarget              
 --WHERE SCHOP.ProjectId = @ProjectId              
 --AND SCHOP.CustomerId = @CustomerId              
 --AND SCHOP.ChoiceOptionSource = 'M'              
 UNION              
 --GET CHOICES FOR SOURCE RECORDS FROM LINKS FROM SLCProject              
 SELECT              
  PSST.ProjectId              
    ,PSST.SectionId              
    ,PSST.CustomerId              
    ,CH.SegmentChoiceCode              
    ,CH.SegmentChoiceSource              
    ,CH.ChoiceTypeId              
    ,CHOP.ChoiceOptionCode              
    ,CHOP.ChoiceOptionSource              
    ,SCHOP.IsSelected              
    ,PSST.SectionCode              
    ,PSST.SegmentStatusId              
    ,PSST.mSegmentId              
    ,PSST.SegmentId              
    ,SCHOP.SelectedChoiceOptionId              
 FROM #SegmentStatusTable PSST WITH (NOLOCK)              
 INNER JOIN ProjectSegmentChoice CH WITH (NOLOCK)              
 ON CH.SectionId = PSST.SectionId and            
   PSST.SegmentId = CH.SegmentId              
 INNER JOIN ProjectChoiceOption CHOP WITH (NOLOCK)              
 ON CHOP.SectionId = PSST.SectionId  and            
   CH.SegmentChoiceId = CHOP.SegmentChoiceId              
 INNER JOIN SelectedChoiceOption SCHOP WITH (NOLOCK)              
 ON SCHOP.CustomerId = PSST.CustomerId  
   AND SCHOP.ProjectId = PSST.ProjectId  
   AND SCHOP.SectionId = PSST.SectionId  
   AND SCHOP.SegmentChoiceCode = CH.SegmentChoiceCode  
   AND SCHOP.ChoiceOptionCode = CHOP.ChoiceOptionCode  
   AND SCHOP.ChoiceOptionSource = 'U'       
 INNER JOIN #SegmentLinkTable SRC_SLT WITH (NOLOCK)              
  ON SCHOP.SegmentChoiceCode = SRC_SLT.SourceSegmentChoiceCode              
  AND SCHOP.ChoiceOptionSource = SRC_SLT.LinkSource              
 --WHERE SCHOP.ProjectId = @ProjectId              
 --AND SCHOP.CustomerId = @CustomerId              
 --AND SCHOP.ChoiceOptionSource = 'U'              
 UNION              
 --GET CHOICES FOR TARGET RECORDS FROM LINKS FROM SLCProject              
 SELECT              
  PSST.ProjectId              
    ,PSST.SectionId              
    ,PSST.CustomerId              
    ,CH.SegmentChoiceCode              
    ,CH.SegmentChoiceSource              
    ,CH.ChoiceTypeId              
    ,CHOP.ChoiceOptionCode              
    ,CHOP.ChoiceOptionSource              
    ,SCHOP.IsSelected              
    ,PSST.SectionCode              
    ,PSST.SegmentStatusId              
    ,PSST.mSegmentId              
    ,PSST.SegmentId              
    ,SCHOP.SelectedChoiceOptionId              
 FROM #SegmentStatusTable PSST WITH (NOLOCK)              
 INNER JOIN ProjectSegmentChoice CH WITH (NOLOCK)              
 ON CH.SectionId = PSST.SectionId and            
   PSST.SegmentId = CH.SegmentId              
 INNER JOIN ProjectChoiceOption CHOP WITH (NOLOCK)              
 ON CHOP.SectionId = PSST.SectionId  and            
  CH.SegmentChoiceId = CHOP.SegmentChoiceId              
 INNER JOIN SelectedChoiceOption SCHOP WITH (NOLOCK)              
  ON SCHOP.CustomerId = PSST.CustomerId  
   AND SCHOP.ProjectId = PSST.ProjectId  
   AND SCHOP.SectionId = PSST.SectionId  
   AND SCHOP.SegmentChoiceCode = CH.SegmentChoiceCode  
   AND SCHOP.ChoiceOptionCode = CHOP.ChoiceOptionCode  
   AND SCHOP.ChoiceOptionSource = 'U'               
 INNER JOIN #SegmentLinkTable TGT_SLT WITH (NOLOCK)              
  ON SCHOP.SegmentChoiceCode = TGT_SLT.TargetSegmentChoiceCode              
   AND SCHOP.ChoiceOptionSource = TGT_SLT.LinkTarget              
 --WHERE   
 --SCHOP.ProjectId = @ProjectId              
 --AND SCHOP.CustomerId = @CustomerId              
 --AND SCHOP.ChoiceOptionSource = 'U'              
END              
              
/** [BLOCK] SET IsFetchedDbLinkResult **/              
BEGIN              
--UPDATE PSST              
--SET PSST.IsFetchedDbLinkResult = CAST(1 AS BIT)              
--FROM #SegmentStatusTable PSST WITH (NOLOCK)              
--INNER JOIN #InputDataTable IDT WITH (NOLOCK)              
-- ON PSST.SectionCode = IDT.SectionCode              
-- AND PSST.SegmentStatusCode = IDT.SegmentStatusCode              
-- AND PSST.SegmentSource = IDT.SegmentSource              
              
UPDATE PSST      
SET PSST.IsFetchedDbLinkResult = CAST(1 AS BIT)              
FROM #SegmentLinkTable SLT WITH (NOLOCK)              
INNER JOIN #SegmentStatusTable PSST WITH (NOLOCK)              
 ON SLT.TargetSectionCode = PSST.SectionCode              
 AND SLT.TargetSegmentStatusCode = PSST.SegmentStatusCode              
 AND SLT.TargetSegmentCode = PSST.SegmentCode              
 AND SLT.LinkTarget = PSST.SegmentSource              
WHERE SLT.Iteration < @MaxIteration              
END              
              
/** [BLOCK] FETCH FINAL DATA **/              
BEGIN              
--SELECT LINK RESULT          
               
SELECT              
DISTINCT              
 SLNK.SegmentLinkId              
   ,SLNK.SourceSectionCode              
   ,SLNK.SourceSegmentStatusCode              
   ,SLNK.SourceSegmentCode              
   ,COALESCE(SLNK.SourceSegmentChoiceCode, 0) AS SourceSegmentChoiceCode              
   ,COALESCE(SLNK.SourceChoiceOptionCode, 0) AS SourceChoiceOptionCode              
   ,SLNK.LinkSource              
   ,SLNK.TargetSectionCode              
   ,SLNK.TargetSegmentStatusCode              
   ,SLNK.TargetSegmentCode              
   ,COALESCE(SLNK.TargetSegmentChoiceCode, 0) AS TargetSegmentChoiceCode              
   ,COALESCE(SLNK.TargetChoiceOptionCode, 0) AS TargetChoiceOptionCode              
   ,SLNK.LinkTarget              
   ,SLNK.LinkStatusTypeId              
   ,CASE              
  WHEN SLNK.SourceSegmentChoiceCode IS NULL AND              
   SLNK.TargetSegmentChoiceCode IS NULL THEN @P2P              
  WHEN SLNK.SourceSegmentChoiceCode IS NULL AND              
   SLNK.TargetSegmentChoiceCode IS NOT NULL THEN @P2C              
  WHEN SLNK.SourceSegmentChoiceCode IS NOT NULL AND              
   SLNK.TargetSegmentChoiceCode IS NULL THEN @C2P              
  WHEN SLNK.SourceSegmentChoiceCode IS NOT NULL AND              
   SLNK.TargetSegmentChoiceCode IS NOT NULL THEN @C2C              
 END AS SegmentLinkType              
   ,SLNK.SourceOfRecord              
   ,SLNK.SegmentLinkCode              
   ,SLNK.SegmentLinkSourceTypeId              
   ,SLNK.IsDeleted              
   ,@ProjectId AS ProjectId              
   ,@CustomerId AS CustomerId              
FROM #SegmentLinkTable SLNK WITH (NOLOCK)              
          
          
              
SELECT              
 PSST.ProjectId              
   ,PSST.SectionId              
   ,PSST.CustomerId              
   ,PSST.SegmentStatusId              
   ,COALESCE(PSST.SegmentStatusCode, 0) AS SegmentStatusCode              
   ,PSST.SegmentStatusTypeId              
   ,PSST.IsParentSegmentStatusActive              
   ,PSST.ParentSegmentStatusId              
   ,COALESCE(PSST.SectionCode, 0) AS SectionCode              
   ,PSST.SegmentSource              
   ,PSST.SegmentOrigin              
   ,PSST.ChildCount              
   ,PSST.SrcLinksCnt              
   ,PSST.TgtLinksCnt              
   ,COALESCE(PSST.SequenceNumber, 0) AS SequenceNumber              
   ,COALESCE(PSST.mSegmentStatusId, 0) AS mSegmentStatusId              
   ,COALESCE(PSST.SegmentCode, 0) AS SegmentCode              
   ,COALESCE(PSST.mSegmentId, 0) AS mSegmentId              
   ,COALESCE(PSST.SegmentId, 0) AS SegmentId              
   ,PSST.IsFetchedDbLinkResult              
FROM #SegmentStatusTable PSST WITH (NOLOCK)              
             
          
               
SELECT              
 SCH.ProjectId              
   ,SCH.SectionId              
   ,SCH.CustomerId              
   ,COALESCE(SCH.SegmentChoiceCode, 0) AS SegmentChoiceCode              
   ,SCH.SegmentChoiceSource              
   ,SCH.ChoiceTypeId              
   ,COALESCE(SCH.ChoiceOptionCode, 0) AS ChoiceOptionCode              
   ,SCH.ChoiceOptionSource              
   ,SCH.IsSelected              
   ,COALESCE(SCH.SectionCode, 0) AS SectionCode              
   ,SCH.SegmentStatusId              
   ,COALESCE(SCH.mSegmentId, 0) AS mSegmentId              
   ,COALESCE(SCH.SegmentId, 0) AS SegmentId              
   ,SCH.SelectedChoiceOptionId              
FROM #SegmentChoiceTable SCH WITH (NOLOCK)              
               
SELECT          
 PSRT.SegmentRequirementTagId AS SegmentRequirementTagId          
   ,COALESCE(PSST.mSegmentStatusId, 0) AS mSegmentStatusId          
   ,PSRT.RequirementTagId AS RequirementTagId          
   ,PSST.SegmentStatusId AS SegmentStatusId          
   ,@SourceOfRecord_Project AS SourceOfRecord          
FROM #SegmentStatusTable PSST WITH (NOLOCK)          
INNER JOIN ProjectSegmentRequirementTag PSRT WITH (NOLOCK)          
 ON PSRT.SegmentStatusId = PSST.SegmentStatusId 
	AND PSRT.RequirementTagId IN (@RS_TAG, @RT_TAG, @RE_TAG, @ST_TAG) 
WHERE PSRT.ProjectId = @ProjectId          
AND PSRT.CustomerId = @CustomerId          
AND ISNULL(PSRT.IsDeleted,0)=0          
               
SELECT              
 PSMRY.ProjectId              
   ,PSMRY.CustomerId              
   ,PSMRY.IsIncludeRsInSection              
   ,PSMRY.IsIncludeReInSection              
   ,PSMRY.IsActivateRsCitation              
FROM ProjectSummary PSMRY WITH (NOLOCK)              
WHERE PSMRY.ProjectId = @ProjectId              
AND PSMRY.CustomerId = @CustomerId           
           
END             
      
DROP TABLE IF EXISTS #ProjectSection;  
DROP TABLE IF EXISTS #ProjectSegmentLink;  
              
END
GO
PRINT N'Altering [dbo].[usp_GetSpecViewMode]...';


GO
ALTER PROCEDURE [dbo].[usp_GetSpecViewMode]  
(
	@ProjectId int,
	@CustomerId int
)
AS
BEGIN

	DECLARE @PProjectId int = @ProjectId;  
	DECLARE @PCustomerId int = @CustomerId;

	SELECT TOP 1 PS.SpecViewModeId
	FROM ProjectSummary PS WITH (NOLOCK)  
	WHERE PS.ProjectId = @PProjectId AND PS.CustomerId = @PCustomerId 
	OPTION (FAST 1);  
  
END;
GO
PRINT N'Altering [dbo].[usp_InsertNewProjectSummary]...';


GO
ALTER PROCEDURE [dbo].[usp_InsertNewProjectSummary]    
@ProjectId INT,          
@CustomerId  INT,          
@UserId   INT,          
@ProjectTypeId  INT,          
@FacilityTypeId  INT,          
@SizeUoM  INT,          
@IsIncludeRsInSection  BIT,          
@IsIncludeReInSection  BIT,          
@SpecViewModeId  INT,          
@UnitOfMeasureValueTypeId  INT,          
@SourceTagFormat  VARCHAR(10),          
@IsActivateRsCitation  BIT,          
@ActualCostId  INT,          
@ActualSizeId  INT      
      
AS          
BEGIN      
          
DECLARE @PProjectId INT = @ProjectId;      
DECLARE @PCustomerId INT = @CustomerId;      
DECLARE @PUserId INT = @UserId;      
DECLARE @PProjectTypeId INT = @ProjectTypeId;      
DECLARE @PFacilityTypeId INT = @FacilityTypeId;      
DECLARE @PSizeUoM INT = @SizeUoM;      
DECLARE @PIsIncludeRsInSection BIT = @IsIncludeRsInSection;      
DECLARE @PIsIncludeReInSection BIT = @IsIncludeReInSection;      
DECLARE @PSpecViewModeId  INT = @SpecViewModeId;      
DECLARE @PUnitOfMeasureValueTypeId INT = @UnitOfMeasureValueTypeId;      
DECLARE @PSourceTagFormat  VARCHAR(10) = @SourceTagFormat;      
DECLARE @PIsActivateRsCitation BIT = @IsActivateRsCitation;      
DECLARE @PActualCostId INT = @ActualCostId;      
DECLARE @PActualSizeId INT =@ActualSizeId;      
    
-- Get Project Default Privacy Settings    
DECLARE @PProjectOriginType int = 1; -- NON Migrated SLC Project    
DECLARE @ProjectAccessTypeId int = 0;    
DECLARE @ProjectOwnerTypeId int = 0;    
DECLARE @OwnerId int =null;    
DECLARE @IsOfficeMaster bit = (select IsOfficeMaster from Project WITH(NOLOCK) where ProjectId = @ProjectId and CustomerId = @CustomerId);    
    
IF NOT EXISTS(select 1 from ProjectDefaultPrivacySetting pdps WITH(NOLOCK)    
    where CustomerId = @PCustomerId and ProjectOriginTypeId = @PProjectOriginType and IsOfficeMaster = @IsOfficeMaster)  
BEGIN  
select @ProjectAccessTypeId = ProjectAccessTypeId,     
    @ProjectOwnerTypeId = ProjectOwnerTypeId from ProjectDefaultPrivacySetting pdps WITH(NOLOCK)    
    where CustomerId = 0 and ProjectOriginTypeId = @PProjectOriginType and IsOfficeMaster = @IsOfficeMaster;
	--Used CustomerId = 0 to fetch default setting;
END  
ELSE   
BEGIN  
select @ProjectAccessTypeId = ProjectAccessTypeId,     
    @ProjectOwnerTypeId = ProjectOwnerTypeId from ProjectDefaultPrivacySetting pdps WITH(NOLOCK)    
    where CustomerId = @PCustomerId and ProjectOriginTypeId = @PProjectOriginType and IsOfficeMaster = @IsOfficeMaster;    
END  
    
IF(@ProjectOwnerTypeId > 1) -- If Default owner type 'user who has created the project'    
BEGIN    
 SET @OwnerId = @PUserId;    
END    
-- Else Set the Project Owner to the 'Not Assigned' - ie. @null    
      
INSERT INTO ProjectSummary (ProjectId      
, CustomerId      
, UserId      
, ProjectTypeId      
, FacilityTypeId      
, SizeUoM      
, IsIncludeRsInSection      
, IsIncludeReInSection      
, SpecViewModeId      
, UnitOfMeasureValueTypeId      
, LastMasterUpdate      
, BudgetedCostId      
, BudgetedCost      
, ActualCost      
, EstimatedArea      
, SourceTagFormat      
, IsActivateRsCitation      
, SpecificationIssueDate      
, SpecificationModifiedDate      
, ActualCostId      
, ActualSizeId      
, EstimatedSizeId      
, EstimatedSizeUoM      
, ProjectAccessTypeId    
, OwnerId)      
 VALUES (@PProjectId, @PCustomerId, @PUserId, @PProjectTypeId, @PFacilityTypeId, @PSizeUoM, @PIsIncludeRsInSection, @PIsIncludeReInSection, @PSpecViewModeId, @PUnitOfMeasureValueTypeId, NULL, NULL, NULL, NULL, NULL, @PSourceTagFormat, @PIsActivateRsCitation, NULL, NULL, @PActualCostId, @PActualSizeId, NULL, NULL,@ProjectAccessTypeId,@OwnerId)      
      
END
GO
PRINT N'Altering [dbo].[usp_CheckDeletedGT]...';


GO
ALTER PROCEDURE [dbo].[usp_CheckDeletedGT]
(
	@ProjectId INT, 
	@CustomerId INT,
	@GlobalTermCode INT
)
AS
BEGIN
	DECLARE @PProjectId INT = @ProjectId;
	DECLARE @PCustomerId INT = @CustomerId;
	DECLARE @PGlobalTermCode INT = @GlobalTermCode;

	SELECT TOP 1 ISNULL(PGT.IsDeleted, 0) AS IsDeleted
	FROM ProjectGlobalTerm PGT WITH (NOLOCK)
	WHERE PGT.CustomerId = @PCustomerId
	AND PGT.ProjectId = @PProjectId
	AND PGT.GlobalTermCode = @PGlobalTermCode
	OPTION (FAST 1);

END
GO
PRINT N'Altering [dbo].[usp_CheckDeletedRefStd]...';


GO
ALTER PROCEDURE [dbo].[usp_CheckDeletedRefStd]    
(
	@RefStdId INT
)     
AS
BEGIN  
    
	DECLARE @PRefStdId INT = @RefStdId;  
	SELECT TOP 1 IsDeleted
	FROM ReferenceStandard WITH (NOLOCK)  
	WHERE RefStdId = @PRefStdId
	--WHERE RefStdCode = @PRefStdCode  
	OPTION (FAST 1);
  
END;
GO
PRINT N'Altering [dbo].[usp_checkedRSLockedUnlocked]...';


GO
ALTER procedure [dbo].[usp_checkedRSLockedUnlocked]
(
@refStdId int ,@IsLockedById int , @IsLockedByFullName nvarchar(max) 
)
AS
Begin
DECLARE @PrefStdId int = @refStdId;
DECLARE @PIsLockedById int = @IsLockedById;
DECLARE @PIsLockedByFullName nvarchar(max) = @IsLockedByFullName;

	Declare @IsLocked bit;

SELECT top 1 @IsLocked = IsLocked FROM ReferenceStandard WITH(NOLOCK) WHERE RefStdId = @PrefStdId

IF (@IsLocked != 1 OR ISNULL(@IsLocked, 0) = 0)
BEGIN
	UPDATE rs 
	SET rs.IsLocked = 1
	   ,rs.IsLockedByFullName = @PIsLockedByFullName
	   ,rs.IsLockedById = @PIsLockedById
	   from ReferenceStandard rs WITH(NOLOCK)
	WHERE rs.RefStdId = @PrefStdId;
END;

SELECT
	refstd.RefStdId
   ,refstd.RefStdName
   ,refstd.RefStdSource
   ,refstd.RefStdCode
   ,refstd.CustomerId
   ,refstd.IsDeleted
   ,refstd.IsLocked
   ,refstd.IsLockedByFullName
   ,refstd.IsLockedById
   ,refStdEdtn.RefEdition
   ,refStdEdtn.LinkTarget
   ,refStdEdtn.RefStdTitle
FROM ReferenceStandard refstd WITH (NOLOCK)
INNER JOIN ReferenceStandardEdition refStdEdtn WITH (NOLOCK)
	ON refstd.RefStdId = refStdEdtn.RefStdId
WHERE refstd.RefStdId = @PrefStdId;

END;
GO
PRINT N'Altering [dbo].[usp_CheckSectionIsLocked]...';


GO
ALTER PROCEDURE [dbo].[usp_CheckSectionIsLocked]  
(
	@SectionId INT
)
AS    
BEGIN  
    
	DECLARE @PSectionId INT  = @SectionId;  

	SELECT
		 PS.SectionId  
		,PS.ParentSectionId  
		,PS.mSectionId  
		,PS.ProjectId  
		,PS.CustomerId  
		,PS.UserId  
		,PS.DivisionId  
		,ISNULL(PS.DivisionCode, 0) AS DivisionCode  
		,ISNULL(PS.[Description], '') AS [Description]  
		,PS.LevelId  
		,PS.IsLastLevel  
		,ISNULL(PS.SourceTag, '') AS SourceTag  
		,PS.Author  
		,PS.TemplateId  
		,PS.SectionCode  
		,ISNULL(PS.IsDeleted, 0) AS IsDeleted  
		,ISNULL(PS.IsLocked, 0) AS IsLocked  
		,PS.LockedBy  
		,ISNULL(PS.LockedByFullName, '') AS LockedByFullName  
		,PS.CreateDate  
		,PS.CreatedBy  
		,PS.ModifiedBy  
		,PS.ModifiedDate  
		,PS.FormatTypeId  
		,PS.SpecViewModeId  
		,PS.IsLockedImportSection  
	FROM ProjectSection PS WITH (NOLOCK)  
	WHERE PS.SectionId = @PSectionId
	OPTION (FAST 1);
  
END
GO
PRINT N'Altering [dbo].[usp_CreateNewSegment]...';


GO
ALTER PROCEDURE [dbo].[usp_CreateNewSegment]      
@SectionId INT NULL, @ParentSegmentStatusId INT NULL, @IndentLevel TINYINT NULL, @SpecTypeTagId INT NULL,     
@SegmentStatusTypeId INT NULL, @IsParentSegmentStatusActive BIT NULL, @ProjectId INT NULL, @CustomerId INT NULL,     
@CreatedBy INT NULL, @SegmentDescription NVARCHAR (MAX) NULL, @IsRefStdParagraph BIT NULL=0, @SequenceNumber DECIMAL (18) NULL=2      
AS      
BEGIN

DECLARE @PSectionId INT = @SectionId;
DECLARE @PParentSegmentStatusId INT = @ParentSegmentStatusId;
DECLARE @PIndentLevel TINYINT = @IndentLevel;
DECLARE @PSpecTypeTagId INT = @SpecTypeTagId;
DECLARE @PSegmentStatusTypeId INT = @SegmentStatusTypeId;
DECLARE @PIsParentSegmentStatusActive BIT = @IsParentSegmentStatusActive;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PCreatedBy INT = @CreatedBy;
DECLARE @PSegmentDescription NVARCHAR (MAX) = @SegmentDescription;
DECLARE @PIsRefStdParagraph BIT = @IsRefStdParagraph;
DECLARE @PSequenceNumber DECIMAL (18) = @SequenceNumber;


INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId, IsShowAutoNumber, FormattingJson, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsRefStdParagraph)
	SELECT
		@PSectionId AS SectionId
	   ,@PParentSegmentStatusId
	   ,0 AS mSegmentStatusId
	   ,0 AS mSegmentId
	   ,0 AS SegmentId
	   ,'U' AS SegmentSource
	   ,'U' AS SegmentOrigin
	   ,@PIndentLevel AS IndentLevel
	   ,@PSequenceNumber AS SequenceNumber
	   ,(CASE
			WHEN @PSpecTypeTagId = 0 THEN NULL
			ELSE @PSpecTypeTagId
		END) AS SpecTypeTagId
	   ,@PSegmentStatusTypeId AS SegmentStatusTypeId
	   ,@PIsParentSegmentStatusActive AS IsParentSegmentStatusActive
	   ,@PProjectId AS ProjectId
	   ,@PCustomerId AS CustomerId
	   ,1 AS IsShowAutoNumber
	   ,NULL AS FormattingJson
	   ,GETUTCDATE() AS CreateDate
	   ,@PCreatedBy AS CreatedBy
	   ,NULL AS ModifiedDate
	   ,NULL AS ModifiedBy
	   ,@PIsRefStdParagraph AS IsRefStdParagraph;

DECLARE @SegmentStatusId AS INT = SCOPE_IDENTITY();

INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription, SegmentSource, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)
	SELECT
		@SegmentStatusId AS SegmentStatusId
	   ,@PSectionId AS SectionId
	   ,@PProjectId AS ProjectId
	   ,@PCustomerId AS CustomerId
	   ,@PSegmentDescription AS SegmentDescription
	   ,'U' AS SegmentSource
	   ,@PCreatedBy AS CreatedBy
	   ,GETUTCDATE() AS CreateDate
	   ,NULL AS ModifiedDate
	   ,NULL AS ModifiedBy;

DECLARE @SegmentId AS INT = SCOPE_IDENTITY();

UPDATE PSS
SET PSS.SegmentId = @SegmentId
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
WHERE PSS.SegmentStatusId = @SegmentStatusId;


DECLARE @SegmentStatusCode INT, @SegmentCode INT;
SELECT @SegmentStatusCode = PSS.SegmentStatusCode FROM ProjectSegmentStatus PSS WITH (NOLOCK) WHERE PSS.SegmentStatusId = @SegmentStatusId;
SELECT @SegmentCode = PS.SegmentCode FROM ProjectSegment PS WITH (NOLOCK) WHERE PS.SegmentId = @SegmentId

SELECT
	@SegmentStatusId AS SegmentStatusId
   ,@ParentSegmentStatusId AS ParentSegmentStatusId
   ,@SegmentId AS SegmentId
   ,@SegmentStatusCode AS SegmentStatusCode
   ,@SegmentCode AS SegmentCode;


--NOW CREATE SEGMENT REQUIREMENT TAG IF SEGMENT IS OF RS TYPE
IF ISNULL(@PIsRefStdParagraph, 0) = 1
	BEGIN
		EXEC usp_CreateSegmentRequirementTag @PCustomerId
											,@PProjectId
											,@PSectionId
											,@SegmentStatusId
											,'RS'
											,@PCreatedBy
		EXEC usp_CreateSpecialLinkForRsReTaggedSegment @PCustomerId
													  ,@PProjectId
													  ,@PSectionId
													  ,@SegmentStatusId
													  ,@PCreatedBy
--START- Added Block for Regression Bug 40872
DECLARE @RSCode INT = 0 , @RsSegmentDescription nvarchar(max)=@SegmentDescription,@PRefStandardId INT = 0 , @PRefStdCode INT = 0;    
		  
		  SELECT @RSCode = LEFT(Val, PATINDEX('%[^0-9]%', Val + 'a') - 1)     
		  FROM (SELECT SUBSTRING(@RsSegmentDescription, PATINDEX('%[0-9]%', @RsSegmentDescription), LEN(@RsSegmentDescription)) Val) RSCode

SELECT TOP 1 
@PRefStandardId = RefStdId,
@PRefStdCode = RefStdCode
FROM ReferenceStandard WITH (NOLOCK) WHERE RefStdCode=@RSCode AND CustomerId= @CustomerId

INSERT INTO ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource, mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, mSegmentId, RefStdCode)
	VALUES (@PSectionId, @SegmentId, @PRefStandardId, 'U', 0, GETUTCDATE(), @PCreatedBy, GETUTCDATE(), NULL, @PCustomerId, @PProjectId, null, @PRefStdCode)

--END Block

	END


END
GO
PRINT N'Altering [dbo].[usp_GetAllComments]...';


GO
ALTER PROCEDURE [dbo].[usp_GetAllComments]
(
	@ProjectId INT,
	@SectionId INT,
	@CustomerId INT,
	@UserId INT,
	@CommentStatusId INT,
	@CommentUserList NVARCHAR(1024) = ''
)
AS
BEGIN  
    
	DECLARE @PProjectId INT = @ProjectId, @PSectionId INT = @SectionId, @PCustomerId INT = @CustomerId;  
	DECLARE @PUserId INT = @UserId, @PCommentStatusId INT = @CommentStatusId;  
  
	DECLARE @COMMENT_USER_TBL AS TABLE(USERID INT);
	INSERT INTO @COMMENT_USER_TBL VALUES (@PUserId);
        
	CREATE TABLE #TempSegmentCommentTbl(SegmentCommentId INT,        
		ProjectId INT ,        
		SectionId INT ,        
		SegmentStatusId  INT,        
		ParentCommentId INT,        
		CommentDescription  NVARCHAR(MAX),        
		CustomerId  INT,        
		CreatedBy INT,        
		CreateDate DATETIME2,        
		ModifiedBy INT,        
		ModifiedDate DATETIME2,        
		CommentStatusId  INT,        
		IsDeleted BIT,        
		UserFullName nvarchar(200),      
		CommentStatusDescription NVARCHAR(MAX)        
	)

	-- Insert all comments and replies into temp table
	INSERT INTO #TempSegmentCommentTbl
	SELECT  
		 SegmentCommentId  
		,ProjectId  
		,SectionId  
		,SegmentStatusId  
		,ParentCommentId  
		,CommentDescription  
		,CustomerId  
		,CreatedBy  
		,CreateDate  
		,ModifiedBy  
		,ModifiedDate  
		,CommentStatusId  
		,IsDeleted  
		,UserFullName  
		,IIF(CommentStatusId = 1, 'UnResolved', 'Resolved') AS CommentStatusDescription 
		--,CS.[Description] AS CommentStatusDescription
	FROM SegmentComment WITH (NOLOCK)
	--INNER JOIN LuCommentStatus CS WITH (NOLOCK) ON T.CommentStatusId = CS.CommentStatusId   
	WHERE SectionId = @PSectionId  
		AND ProjectId = @PProjectId  
		AND CustomerId = @PCustomerId
		AND ISNULL(IsDeleted, 0) = 0;
  
	-- Select Only Parent Comments
	SELECT  
	    SegmentCommentId  
	   ,ProjectId  
	   ,SectionId  
	   ,SegmentStatusId  
	   ,ParentCommentId  
	   ,CommentDescription  
	   ,CustomerId  
	   ,CreatedBy  
	   ,CreateDate  
	   ,ModifiedBy  
	   ,ModifiedDate  
	   ,CommentStatusId  
	   ,IsDeleted  
	   ,UserFullName  
	   ,CommentStatusDescription  
	FROM #TempSegmentCommentTbl WITH (NOLOCK)
	WHERE ParentCommentId = 0
	ORDER BY CreateDate DESC;
  
	-- Select Only Reply Comments
	SELECT  
		SC.SegmentCommentId  
	   ,SC.ProjectId  
	   ,SC.SectionId  
	   ,SC.SegmentStatusId  
	   ,SC.ParentCommentId  
	   ,SC.CommentDescription  
	   ,SC.CustomerId  
	   ,SC.CreatedBy  
	   ,SC.CreateDate  
	   ,SC.ModifiedBy  
	   ,SC.ModifiedDate  
	   ,SC.CommentStatusId  
	   ,SC.IsDeleted  
	   ,SC.UserFullName  
	   ,IIF(SC.CommentStatusId = 1, 'UnResolve', 'Resolved') AS CommentStatusDescription  
	FROM #TempSegmentCommentTbl SC WITH (NOLOCK)
	WHERE ISNULL(SC.ParentCommentId, 0) <> 0
	ORDER BY CreateDate DESC;

END  

--EXEC [usp_GetAllCommentsPrasad] 8814, 8911299, 641, 19911, 0, ''
GO
PRINT N'Altering [dbo].[usp_GetDefaultDateFormat]...';


GO
ALTER PROCEDURE [dbo].[usp_GetDefaultDateFormat]   -- EXEC [dbo].[usp_GetDefaultDateFormat] 1977,2  
(      
 @ProjectId int,        
 @MasterDataTypeId int      
)      
AS          
BEGIN        
          
 DECLARE @PProjectId int = @ProjectId;        
 DECLARE @PMasterDataTypeId int = @MasterDataTypeId;      
      
 DROP TABLE IF EXISTS #ProjectDateFormatTemp;    
    
 SELECT TOP 1      
  PDF.ProjectDateFormatId        
  ,PDF.MasterDataTypeId        
  ,ISNULL(PDF.ProjectId, 0) AS ProjectId        
  ,ISNULL(PDF.CustomerId, 0) AS CustomerId        
  ,ISNULL(PDF.UserId, 0) AS UserId      
  ,PDF.ClockFormat        
  ,PDF.[DateFormat]        
 INTO #ProjectDateFormatTemp      
 FROM [ProjectDateFormat] PDF WITH (NOLOCK)        
 WHERE PDF.ProjectId = @PProjectId AND PDF.MasterDataTypeId = @PMasterDataTypeId;      
        
  IF NOT EXISTS(SELECT TOP 1 1 FROM #ProjectDateFormatTemp)        
  BEGIN        
   SELECT        
    PDF.ProjectDateFormatId        
    ,PDF.MasterDataTypeId        
    ,ISNULL(PDF.ProjectId, 0) AS ProjectId        
    ,ISNULL(PDF.CustomerId, 0) AS CustomerId        
    ,ISNULL(PDF.UserId, 0) AS UserId        
    ,PDF.ClockFormat        
    ,PDF.[DateFormat]        
   FROM [ProjectDateFormat] PDF WITH (NOLOCK)        
   WHERE PDF.MasterDataTypeId = @PMasterDataTypeId   
    AND PDF.ProjectId IS NULL   
    AND PDF.CustomerId IS NULL   
    AND PDF.UserId IS NULL;  
  END    
  ELSE  
  BEGIN  
   SELECT * FROM #ProjectDateFormatTemp;  
  END  
END
GO
PRINT N'Altering [dbo].[usp_GetGlobalTerms]...';


GO
ALTER PROCEDURE [dbo].[usp_GetGlobalTerms]     
(    
	@CustomerID INT,    
	@ProjectID INT    
)    
AS    
BEGIN  

DECLARE @PCustomerID INT = @CustomerID;  
DECLARE @PProjectID INT = @ProjectID;  
  
	SELECT
		GlobalTermId  
	   ,ProjectId  
	   ,CustomerId  
	   ,ISNULL(MGlobalTermId, 0) AS MGlobalTermId  
	   ,[Name]
	   ,ISNULL([Value], '') AS [Value]  
	   ,ISNULL(OldValue, '') AS OldValue
	   ,GlobalTermSource  
	   ,GlobalTermCode  
	   ,CreatedDate  
	   ,CreatedBy  
	   ,ISNULL(IsDeleted, 0) AS IsDeleted  
	   ,ISNULL(UserGlobalTermId, 0) AS UserGlobalTermId  
	   ,ISNULL(GlobalTermFieldTypeId, 1) AS GlobalTermFieldTypeId  
	   ,COALESCE(ModifiedDate, NULL) AS ModifiedDate  
	   ,ISNULL(ModifiedBy, 0) AS ModifiedBy  
	FROM ProjectGlobalTerm WITH (NOLOCK)  
	WHERE CustomerId = @PCustomerID
	AND ProjectId = @PProjectID
	AND ISNULL(IsDeleted, 0) = 0
	ORDER BY [Name]
END

--EXEC [usp_GetGlobalTerms] 641, 8340
GO
PRINT N'Altering [dbo].[usp_GetImportSectionProgress]...';


GO
ALTER PROCEDURE usp_GetImportSectionProgress       
@UserId INT              
AS              
BEGIN  
       
  -- Select Import Progress into #ImportProgress  
  SELECT  
 CPR.RequestId     
   ,CPR.TargetProjectId AS ProjectId  
   ,CPR.TargetSectionId AS SectionId  
   ,PS.[Description] AS [TaskName]  
   ,CPR.CreatedById AS UserId  
   ,CPR.CustomerId  
   ,CPR.CompletedPercentage  
   ,CPR.StatusId  
   ,CPR.CreatedDate AS RequestDateTime  
   ,LCS.StatusDescription  
   ,CPR.IsNotify  
   ,CPR.ModifiedDate  
   ,CPR.source
  ,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr  
   ,DATEADD(DAY, 30, CPR.CreatedDate) AS RequestExpiryDateTime          
 INTO #ImportProgress  
 FROM ImportProjectRequest CPR WITH (NOLOCK)         
 INNER JOIN LuCopyStatus LCS WITH (NOLOCK)          
  ON LCS.CopyStatusId = CPR.StatusId          
   INNER JOIN ProjectSection PS WITH(NOLOCK)    
    ON PS.SectionId=CPR.TargetSectionId    
 WHERE CPR.CreatedById = @UserId  
 AND Source IN('SpecAPI','Import from Template')  
 AND ISNULL(CPR.IsDeleted, 0) = 0  
 AND (CPR.IsNotify = 0 OR DATEADD(SECOND, 7, CPR.ModifiedDate) > GETUTCDATE())  
  
   -- Update Fetched records as Notified  
   UPDATE IPR    
   SET IPR.IsNotify = 1    
   FROM ImportProjectRequest IPR WITH (NOLOCK)      
   INNER JOIN #ImportProgress ImPrg  
   ON IPR.RequestId = ImPrg.RequestId    
     
   -- Fetch Imprort Progress notifications       
   SELECT * FROM #ImportProgress  
          
          
END
GO
PRINT N'Altering [dbo].[usp_GetNotesDetails]...';


GO
ALTER PROCEDURE [dbo].[usp_GetNotesDetails]
(
 @ProjectId INT,
 @SectionId INT,
 @mSectionId INT,
 @CatalogueType VARCHAR(50) NULL = 'FS'
)
AS
BEGIN
	DECLARE @PmSectionId INT = @mSectionId;
	DECLARE @PSectionId INT = @SectionId;
	DECLARE @PCatalogueType varchar(50) = @CatalogueType;

	-- Drop temp tables if already present
	DROP TABLE IF EXISTS #TempSectionNotes;
	DROP TABLE IF EXISTS #ImageTable;
	DROP TABLE IF EXISTS #HyperLinkTable;

	DECLARE @CatalogueTypeTbl TABLE (TagType NVARCHAR(MAX));

	--CONVERT CATALOGUE TYPE INTO TABLE
	IF @PCatalogueType IS NOT NULL AND @PCatalogueType != 'FS'
	BEGIN
		INSERT INTO @CatalogueTypeTbl (TagType)
		SELECT * FROM dbo.fn_SplitString(@PCatalogueType, ',');

		IF EXISTS (SELECT * FROM @CatalogueTypeTbl WHERE TagType = 'OL')
		BEGIN
			INSERT INTO @CatalogueTypeTbl VALUES ('UO');
		END

		IF EXISTS (SELECT * FROM @CatalogueTypeTbl WHERE TagType = 'SF')
		BEGIN
			INSERT INTO @CatalogueTypeTbl VALUES ('US');
		END
	END

	DECLARE @ImageFormat VARCHAR(50) = 'IMG#';
	DECLARE @HLFormat VARCHAR(50) = 'HL#';

	--NoteId, SegmentStatusId, NoteText, SectionId, SegmentId, MasterDataTypeId, CreateDate, ModifiedDate, PublicationDate, MasterNoteTypeId
	SELECT *
	INTO #TempSectionNotes
	FROM (SELECT
			N.NoteId
		   ,PSST.SegmentStatusId
		   ,'' AS Title
		   ,0 AS IsDeleted
		   ,dbo.ModifyNoteStringWtihNewLineAndSpaces(N.NoteText) AS NoteText
		   ,N.CreateDate
		   ,N.ModifiedDate
		   ,'System' AS CreatedUserName
		   ,'System' AS ModifiedUserName
		   ,'M' AS NoteType
		   ,PSST.SequenceNumber
		   ,'M' AS [Source]

		FROM SLCMaster..Note N WITH (NOLOCK)
		INNER JOIN ProjectSegmentStatus PSST WITH(NOLOCK)
			ON N.SegmentStatusId = PSST.mSegmentStatusId
			AND PSST.SectionId = @PSectionId
		LEFT OUTER JOIN SLCMaster..LuSpecTypeTag AS STT WITH (NOLOCK)
			ON PSST.SpecTypeTagId = STT.SpecTypeTagId
		WHERE N.SectionId = @PmSectionId
		AND PSST.SectionId = @PSectionId
		AND (@PCatalogueType = 'FS'
		OR STT.TagType IN (SELECT TagType FROM @CatalogueTypeTbl)
		)
		UNION
		SELECT
			PN.NoteId
		   ,PN.SegmentStatusId
		   ,COALESCE(PN.Title, '') AS Title
		   ,PN.IsDeleted
		   ,PN.NoteText
		   ,PN.CreateDate
		   ,PN.ModifiedDate
		   ,(CASE WHEN PN.CreatedUserName IS NOT NULL THEN PN.CreatedUserName
		   WHEN PN.CreatedUserName IS NULL AND PN.ModifiedUserName IS NOT NULL THEN PN.ModifiedUserName END) AS CreatedUserName
		   ,PN.ModifiedUserName
		   ,'U' AS NoteType
		   ,PSST.SequenceNumber
		   ,'U' AS [Source]

		FROM ProjectNote PN WITH (NOLOCK)
		INNER JOIN ProjectSegmentStatus PSST WITH(NOLOCK)
			ON PN.SegmentStatusId = PSST.SegmentStatusId
		LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK)
			ON PSST.SpecTypeTagId = STT.SpecTypeTagId

		WHERE PN.SectionId = @PSectionId
		AND PN.IsDeleted = 0
		AND PN.ProjectId = @ProjectId
		AND (@PCatalogueType = 'FS'
		OR STT.TagType IN (SELECT TagType FROM @CatalogueTypeTbl)
		)) AS X
		ORDER BY SequenceNumber ASC, NoteId DESC

	DECLARE @imageNotes VARCHAR(MAX)
	SET @imageNotes = '';
		DECLARE @hlNotes VARCHAR(max)
	SET @hlNotes = '';

	--Gets all matched IMG notes
	SELECT
		@imageNotes = @imageNotes + COALESCE(TN.NoteText + ',', ' ')
	FROM #TempSectionNotes AS TN
	WHERE TN.NoteText LIKE '%{IMG%';

	--Gets all matched HL notes
	SELECT
		@hlNotes = @hlNotes + COALESCE(TN.NoteText + ',', ' ')
	FROM #TempSectionNotes AS TN
	WHERE TN.NoteText LIKE '%{HL%';

	--Gets all notes used in section
	SELECT * FROM #TempSectionNotes;

	--Gets all images used in notes
	--ImageId	ImagePath	LuImageSourceTypeId	CreateDate	ModifiedDate	PublicationDate
	DROP TABLE IF EXISTS #ImageTable;
	CREATE TABLE #ImageTable (
		ImageId INT
	   ,ImagePath NVARCHAR(MAX)
	   ,[Source] NVARCHAR(MAX)
	)

	-- Fetch Master Images 
	INSERT INTO #ImageTable
	SELECT
		ImageId AS ImageId
		,ImagePath AS ImagePath
		,'M' AS [Source]
	FROM SLCMaster..[Image] I WITH(NOLOCK)
	WHERE I.ImageId
	IN (SELECT DISTINCT CONVERT(INT, Ids) AS ImageId
		FROM dbo.fn_GetIdSegmentDescription(@imageNotes, @ImageFormat))

	INSERT INTO #ImageTable
		SELECT
			PPI.ImageId AS ImageId
		   ,ImagePath AS ImagePath
		   ,'U' AS [Source]
		FROM [ProjectImage] PPI WITH(NOLOCK)
		INNER JOIN [ProjectNoteImage] PNI WITH(NOLOCK)
			ON PPI.ImageId = PNI.ImageId
		WHERE PNI.ProjectId = @ProjectId AND PNI.SectionId = @PSectionId

	-- Fetch Master Images only if master section
	INSERT INTO #ImageTable
		SELECT
			I.ImageId AS ImageId
			,I.ImagePath AS ImagePath
			,'U' AS [Source]
		FROM SLCMaster..[Image] I WITH(NOLOCK)
		LEFT JOIN #ImageTable TIMG
			ON I.ImageId = TIMG.ImageId
				AND TIMG.[Source] = 'U'
		WHERE I.ImageId
		IN (SELECT DISTINCT CONVERT(INT, Ids) AS ImageId
			FROM dbo.fn_GetIdSegmentDescription(@imageNotes, @ImageFormat))
		AND TIMG.ImageId IS NULL

	SELECT * FROM #ImageTable;

	--Gets all hyper links used in notes
	--HyperLinkId	SectionId	SegmentId	SegmentStatusId	LinkTarget	LinkText	LuHyperLinkSourceTypeId	CreateDate	ModifiedDate

	DROP TABLE IF EXISTS #HyperLinkTable;
	CREATE TABLE #HyperLinkTable (
		HyperLinkId INT
	   ,HyperLinkCode INT
	   ,SegmentStatusId INT
	   ,LinkTarget NVARCHAR(512)
	   ,LinkText NVARCHAR(MAX)
	   ,[Source] NVARCHAR(MAX)
	)

	-- Fetch Master HyperLinks only if master section
	IF(ISNULL(@mSectionId, 0) > 0)
	BEGIN
		INSERT INTO #HyperLinkTable
			SELECT
				HyperLinkId AS HyperLinkId
				,0 AS HyperLinkCode
				,ISNULL(SegmentStatusId, 0) AS SegmentStatusId
				,LinkTarget AS LinkTarget
				,LinkText AS LinkText
				,'M' AS [Source]
			FROM SLCMaster..HyperLink HL WITH(NOLOCK)
			WHERE HL.SectionId = @mSectionId;
	END

	INSERT INTO #HyperLinkTable
		SELECT
			HL.HyperLinkId AS HyperLinkId
		   ,HL.A_HyperLinkId AS HyperLinkCode
		   ,ISNULL(HL.SegmentStatusId, 0) AS SegmentStatusId
		   ,LinkTarget AS LinkTarget
		   ,LinkText AS LinkText
		   ,'U' AS [Source]
		FROM ProjectHyperLink HL WITH(NOLOCK)
		WHERE HL.ProjectId = @ProjectId AND HL.SectionId = @SectionId;

	SELECT * FROM #HyperLinkTable;

	-- Drop temp tables after use
	DROP TABLE IF EXISTS #TempSectionNotes;
	DROP TABLE IF EXISTS #ImageTable;
	DROP TABLE IF EXISTS #HyperLinkTable;

END

-- EXEC usp_GetNotesDetails 10856, 9005780, NULL, 'FS'
GO
PRINT N'Altering [dbo].[usp_GetNotificationCount]...';


GO
ALTER PROCEDURE [dbo].[usp_GetNotificationCount]
	@UserId int,
	@CustomerId int
AS
BEGIN
	DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())      

	DECLARE @RES AS Table(CopyProject INT,SpecApiSection INT,CreateSectionFromTemplate INT,UnArchiveProjectsCount INT)
	DECLARE @COUNT INT=0
	INSERT INTO @RES(CopyProject)
	SELECT COUNT(1) FROM CopyProjectRequest cp WITH(NOLOCK)
	WHERE cp.CreatedById=@UserId AND ISNULL(cp.IsDeleted,0)=0
	AND cp.StatusId IN(1,2)
	AND CP.CreatedDate> @DateBefore30Days   


	SELECT @COUNT=COUNT(1) FROM ImportProjectRequest cp WITH(NOLOCK)
	WHERE cp.CreatedById=@UserId AND ISNULL(cp.IsDeleted,0)=0
	AND cp.StatusId IN(1,2) and Source='SpecAPI' --verify
	AND CP.CreatedDate> @DateBefore30Days   

	UPDATE @RES
	SET SpecApiSection=@COUNT

	SET @COUNT=0
	SELECT @COUNT=COUNT(1) FROM ImportProjectRequest cp WITH(NOLOCK)
	WHERE cp.CreatedById=@UserId AND ISNULL(cp.IsDeleted,0)=0
	AND cp.StatusId IN(1,2) and Source='Import from Template'
	AND CP.CreatedDate> @DateBefore30Days   

	UPDATE @RES
	SET CreateSectionFromTemplate=@COUNT

	SET @COUNT=0
	SELECT @COUNT=COUNT(1) FROM UnArchiveProjectRequest cp WITH(NOLOCK)
	WHERE cp.SLC_UserId=@UserId AND ISNULL(cp.IsDeleted,0)=0
	AND cp.StatusId IN(1,2)
	AND CP.RequestDate > @DateBefore30Days   

	UPDATE @RES
	SET UnArchiveProjectsCount=@COUNT

	SELECT * FROM @RES
END
GO
PRINT N'Altering [dbo].[usp_GetProjectSegmentReferenceStandards]...';


GO
 ALTER PROCEDURE [dbo].[usp_GetProjectSegmentReferenceStandards]       
@RefStandardId INT NULL,    
@RefStdCode INT  NULL,    
@CustomerId INT NULL    
AS           
BEGIN  
    
DECLARE @PRefStandardId INT = @RefStandardId;  
DECLARE @PRefStdCode INT = @RefStdCode;  
DECLARE @PCustomerId INT = @CustomerId;  
DROP TABLE IF EXISTS #tmpUserReferenceStandard  
  
SELECT  
 RS.SegmentRefStandardId  
   ,RS.RefStandardId  
   ,RS.ProjectId  
   ,RS.RefStandardSource  
   ,RS.CustomerId  
   INTO #tmpUserReferenceStandard  
FROM [ProjectSegmentReferenceStandard] RS WITH (NOLOCK)  
WHERE RS.RefStandardId = @PRefStandardId  
AND RS.RefStdCode = @PRefStdCode  
AND RS.CustomerId = @PCustomerId  
AND RS.IsDeleted = 0  

-- To check RS is lock/unlock status and check RS use status in any project 
SELECT TOP 1
	refstd.RefStdId
   ,refstd.RefStdSource
   ,refstd.RefStdCode
   ,refstd.CustomerId
   ,refstd.IsDeleted
   ,refstd.IsLocked
   ,refstd.IsLockedByFullName
   ,refstd.IsLockedById
   ,RS.*
FROM ReferenceStandard refstd WITH (NOLOCK)
LEFT JOin #tmpUserReferenceStandard RS ON refstd.RefStdId = RS.RefStandardId
LEFT JOIN Project P with (nolock)   ON P.ProjectId = RS.ProjectId and (ISNULL(P.IsPermanentDeleted,0) = 0  OR ISNULL(P.IsDeleted,0) = 0 )
WHERE refstd.RefStdId = @PRefStandardId;

/*  
--Added this change to filter used Reference from Permanently Deleted Projects  
SELECT  
 RS.*  
FROM #tmpUserReferenceStandard RS  
INNER JOIN Project P with (nolock)  
 ON P.ProjectId = RS.ProjectId  
WHERE ISNULL(P.IsPermanentDeleted,0) = 0  
OR ISNULL(P.IsDeleted,0) = 0  
ORDER BY RS.RefStandardId;  */
  
END
GO
PRINT N'Altering [dbo].[usp_GetReferenceStandards]...';


GO
ALTER PROCEDURE [dbo].[usp_GetReferenceStandards]               
(                        
  @ProjectId INT= NULL,                 
  @CustomerId INT =NULL,             
  @MasterDataTypeId INT =NULL            
)                    
AS                       
BEGIN            
DECLARE @PProjectId INT = @ProjectId;            
--DECLARE @PSectionId INT = @SectionId;            
DECLARE @PCustomerId INT = @CustomerId;            
DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;            
            
--Set Nocount On              
SET NOCOUNT ON;            
--SET STATISTICS TIME ON;            
              
IF(@PMasterDataTypeId = 2 OR @PMasterDataTypeId=3)            
BEGIN            
SET @PMasterDataTypeId = 1            
END            
            
--FIND USED REF STD AND THEIR EDITIONS                
SELECT            
 RefStandardId            
   ,RefStdEditionId            
   ,RefStdCode INTO #MappedRefStds            
FROM [dbo].ProjectReferenceStandard WITH(NOLOCK)            
WHERE ProjectId = @PProjectid            
AND CustomerId = @PCustomerId            
AND ISNULL(IsDeleted,0) = 0            
            
--CREATE TABLE OF REF STD'S OF MASTER ONLY                
            
SELECT MAX(RSE.RefStdEditionId) as RefStdEditionId,RSE.RefStdId            
INTo #RefStdTbl FROM [SLCMaster].dbo.ReferenceStandardEdition RSE WITH(NOLOCK) GROUP BY RSE.RefStdId            
            
SELECT MAX(RSE.RefStdEditionId) as RefStdEditionId,RSE.RefStdId            
INTo #RefStdProj FROM [dbo].ReferenceStandardEdition RSE WITH(NOLOCK) GROUP BY RSE.RefStdId            
            
--SELECT            
-- RS.RefStdId            
--   ,RefEdition.RefStdEditionId INTO #RefStdTbl            
--FROM [SLCMaster].dbo.ReferenceStandard RS (NOLOCK)            
--CROSS APPLY (SELECT TOP 1            
--  RSE.RefStdEditionId            
-- FROM [SLCMaster].dbo.ReferenceStandardEdition RSE (NOLOCK)            
-- WHERE RSE.RefStdId = RS.RefStdCode            
-- ORDER BY RSE.RefStdEditionId DESC) RefEdition            
            
----UPDATE EDITION ID ACCORDING TO APPLY UPDATE FUNCTIONALITY                
UPDATE RefStd            
SET RefStd.RefStdEditionId = MREF.RefStdEditionId            
FROM #RefStdTbl RefStd WITH(NOLOCK)            
INNER JOIN #MappedRefStds MREF WITH(NOLOCK)            
 ON RefStd.RefStdId = MREF.RefStandardId            
INNER JOIN [SLCMaster].dbo.ReferenceStandard RS WITH(NOLOCK)            
    ON  MREF.RefStdCode=RS.RefStdCode              
            
            
DECLARE @MasterReferenceStandard TABLE            
(RefStdId int            
--,MasterDataTypeId int            
,RefStdName varchar(100)            
,ReplaceRefStdId int            
,IsObsolete bit            
,RefStdCode int            
--,CreateDate datetime2            
--,ModifiedDate datetime2            
--,PublicationDate datetime2            
,RefStdEditionId INT            
)            
            
DECLARE @MasterReferenceStandardEdition TABLE            
(RefStdEditionId int            
,RefStdId int            
,RefEdition varchar(150)            
,RefStdTitle varchar(500)            
,LinkTarget varchar(300)            
--,CreateDate datetime2            
--,ModifiedDate datetime2            
--,PublicationDate datetime2            
--,MasterDataTypeId int            
)            
            
DECLARE @ReferenceStandard TABLE            
(RefStdId int            
,RefStdName varchar(100)            
,RefStdSource char(1)            
,ReplaceRefStdId int            
,ReplaceRefStdSource char(1)            
,mReplaceRefStdId int            
,IsObsolete bit            
,RefStdCode int            
,CreateDate datetime2            
,CreatedBy int            
,ModifiedDate datetime2            
,ModifiedBy int            
,CustomerId int            
,IsDeleted bit            
,IsLocked bit            
,IsLockedByFullName nvarchar(100)            
,IsLockedById int            
,A_RefStdId int            
,RefStdEditionId INT            
)            
            
DECLARE @ReferenceStandardEdition TABLE            
(RefStdEditionId int            
,RefEdition varchar(150)            
,RefStdTitle varchar(300)            
,LinkTarget varchar(500)            
--,CreateDate datetime2            
--,CreatedBy int            
--,RefStdId int            
--,CustomerId int            
--,ModifiedDate datetime2            
--,ModifiedBy int            
--,A_RefStdEditionId int            
)            
            
insert into @MasterReferenceStandard            
select RS.RefStdId,RS.RefStdName,RS.ReplaceRefStdId,RS.IsObsolete,RS.RefStdCode            
,RefStd.RefStdEditionId from [SLCMaster].dbo.ReferenceStandard RS WITH (NOLOCK)            
INNER JOIN #RefStdTbl RefStd WITH(NOLOCK)            
ON RS.RefStdId = RefStd.RefStdId            
AND RS.MasterDataTypeId = @PMasterDataTypeId            
            
insert into @MasterReferenceStandardEdition            
select RSE.RefStdEditionId, RSE.RefStdId , RSE.RefEdition , RSE.RefStdTitle, RSE.LinkTarget             
from [SLCMaster].dbo.ReferenceStandardEdition RSE WITH(NOLOCK)            
INNER JOIN #RefStdTbl RefStd WITH(NOLOCK)            
ON RSE.RefStdId = RefStd.RefStdId            
AND RSE.MasterDataTypeId = @PMasterDataTypeId            
            
insert into @ReferenceStandard            
select PRS.RefStdId  
,PRS.RefStdName  
,PRS.RefStdSource  
,PRS.ReplaceRefStdId  
,PRS.ReplaceRefStdSource  
,PRS.mReplaceRefStdId  
,PRS.IsObsolete  
,PRS.RefStdCode  
,PRS.CreateDate  
,PRS.CreatedBy  
,PRS.ModifiedDate  
,PRS.ModifiedBy  
,PRS.CustomerId  
,PRS.IsDeleted  
,PRS.IsLocked  
,PRS.IsLockedByFullName  
,PRS.IsLockedById  
,PRS.A_RefStdId, RSP.RefStdEditionId from [dbo].ReferenceStandard PRS WITH (NOLOCK)            
inner join #RefStdProj RSP  WITH (NOLOCK)            
on PRS.RefStdId = RSP.RefStdId             
WHERE ISNULL(PRS.IsDeleted,0) = 0            
            
insert into @ReferenceStandardEdition            
select PRSE.RefStdEditionId, PRSE.RefEdition,PRSE.RefStdTitle,PRSE.LinkTarget            
from [dbo].ReferenceStandardEdition PRSE WITH (NOLOCK)            
WHERE PRSE.CustomerId= @PCustomerId            
            
--DROP TABLE IF EXISTS #ProjectReferenceStandard            
DECLARE @table_RefStandardWithEditionId TABLE (            
    RefStdId int,            
 RefStdEditionId int            
);            
SELECT RefStandardId,RefStdEditionId,CustomerId,RefStdSource INTO #ProjectReferenceStandard           
FROM ProjectReferenceStandard  PRT  WITH(NOLOCK) where PRT.ProjectId=@PProjectId    and PRT.CustomerId=@PCustomerId and PRT.RefStdSource='U' AND ISNULL(PRT.IsDeleted,0) = 0  
            
INSERT INTO  @table_RefStandardWithEditionId             
--RS list with edition which is not yet used            
SELECT RT.RefStdId AS RefStdId            
   ,MAX(RSE.RefStdEditionId) AS RefStdEditionId            
  FROM ReferenceStandard RT  WITH(NOLOCK) left outer join #ProjectReferenceStandard  PRT             
on RT.RefStdId=PRT.RefStandardId and RT.CustomerId=PRT.CustomerId and RT.RefStdSource=PRT.RefStdSource            
INNER JOIN ReferenceStandardEdition RSE  WITH(NOLOCK) on RT.RefStdId=RSE.RefStdId            
where RT.CustomerId=@PCustomerId and RT.RefStdSource='U' AND   ISNULL(RT.IsDeleted,0) = 0  AND          
PRT.RefStandardId is null            
GROUP BY RT.RefStdId UNION           
--RS list with edition which is in used            
SELECT RT.RefStdId AS RefStdId            
   ,MAX(PRT.RefStdEditionId) AS RefStdEditionId            
FROM ReferenceStandard RT   WITH(NOLOCK)INNER JOIN #ProjectReferenceStandard  PRT            
on RT.RefStdId=PRT.RefStandardId and RT.CustomerId=PRT.CustomerId and RT.RefStdSource=PRT.RefStdSource           
--INNER JOIN ReferenceStandardEdition RSE  WITH(NOLOCK) on PRT.RefStandardId =RSE.RefStdId           
where RT.CustomerId=@PCustomerId and RT.RefStdSource='U'  AND   ISNULL(RT.IsDeleted,0) = 0 GROUP BY RT.RefStdId             
SELECT            
 RS.RefStdId            
   ,RS.RefStdName            
   ,ISNULL(RS.ReplaceRefStdId, 0) AS ReplaceRefStdId            
   ,'M' AS RefStdSource            
   ,RS.IsObsolete            
   ,RS.RefStdCode            
   ,CAST(0 AS BIT) AS IsLocked            
   ,NULL AS IsLockedByFullName            
   ,NULL AS IsLockedById            
   ,CAST(0 AS BIT) AS IsDeleted            
   ,RSE.RefStdEditionId            
   ,RSE.RefEdition            
   ,RSE.RefStdTitle            
   ,RSE.LinkTarget            
FROM @MasterReferenceStandard RS             
--INNER JOIN #RefStdTbl RefStd WITH(NOLOCK)            
-- ON RS.RefStdId = RefStd.RefStdId            
--  AND RS.MasterDataTypeId = @PMasterDataTypeId            
INNER JOIN @MasterReferenceStandardEdition RSE            
 ON RS.RefStdId = RSE.RefStdId            
  AND RS.RefStdEditionId = RSE.RefStdEditionId            
  --AND RSE.MasterDataTypeId = @PMasterDataTypeId            
UNION            
SELECT            
 PRS.RefStdId            
   ,PRS.RefStdName            
   ,PRS.ReplaceRefStdId            
   ,PRS.RefStdSource            
   ,PRS.IsObsolete            
   ,COALESCE(PRS.RefStdCode, 0) AS RefStdCode            
   ,CAST(0 AS BIT) AS IsLocked            
   ,PRS.IsLockedByFullName            
   ,PRS.IsLockedById            
   ,PRS.IsDeleted            
   ,PRSE.RefStdEditionId            
   ,PRSE.RefEdition            
   ,PRSE.RefStdTitle            
   ,PRSE.LinkTarget             
FROM ReferenceStandard PRS WITH(NOLOCK)            
inner join ReferenceStandardEdition PRSE  WITH(NOLOCK)            
on PRSE.RefStdId = PRS.RefStdId            
INNER JOIN @table_RefStandardWithEditionId tvn            
on tvn.RefStdId=prs.RefStdId and tvn.RefStdEditionId=prse.RefStdEditionId            
where PRS.CustomerId=@PCustomerId and ISNULL(PRS.IsDeleted,0) = 0  --and PRS.RefStdSource='U'            
            
ORDER BY RS.RefStdName;            
            
END
GO
PRINT N'Altering [dbo].[usp_GetSectionforImportSection]...';


GO
ALTER PROCEDURE usp_GetSectionforImportSection
(
 @ProjectId INT,      
 @CustomerId INT       
)      
 AS      
 BEGIN    
     
	DECLARE @PProjectId INT = @ProjectId;
	DECLARE @PCustomerId INT = @CustomerId;

	DROP TABLE IF EXISTS #SubDivision;
	DROP TABLE IF EXISTS #TempOpenSection;

	-- Select Project for import from project list
	SELECT  DISTINCT  
	    PS.SectionId  
	   ,PS.ParentSectionId  
	   ,PS.mSectionId  
	   ,PS.ProjectId  
	   ,PS.CustomerId  
	   ,PS.UserId  
	   ,PS.DivisionId  
	   ,PS.DivisionCode  
	   ,PS.[Description]  
	   ,PS.LevelId  
	   ,PS.IsLastLevel  
	   ,PS.SourceTag  
	   ,PS.Author  
	   ,PS.TemplateId  
	   ,PS.SectionCode  
	   ,PS.IsDeleted  
	   ,PS.IsLocked  
	   ,PS.LockedBy  
	   ,PS.FormatTypeId  
	   ,PS.SpecViewModeId
	   ,(CASE WHEN PSS.SegmentStatusTypeId < 6 AND PSS.IsParentSegmentStatusActive = 1 THEN 1 ELSE 0 END) AS IsActive 
	INTO #TempOpenSection
	FROM ProjectSection PS WITH (NOLOCK)
	INNER JOIN ProjectSegmentStatus PSS WITH (NOLOCK) ON PSS.SectionId = PS.SectionId
													 AND PSS.ProjectId = PS.ProjectId
													 AND PSS.CustomerId = @CustomerId
													 AND PSS.IndentLevel = 0
													 AND PSS.ParentSegmentStatusId = 0
													 AND PSS.SequenceNumber = 0
													 AND ISNULL(PSS.IsDeleted, 0) = 0
													 AND ISNULL(PS.IsDeleted, 0) = 0
  WHERE PS.ProjectId = @PProjectId AND PS.CustomerId = @PCustomerId
  ORDER BY PS.SourceTag;

  -- Update master deleted sections as deleted
	UPDATE TOS
	SET TOS.IsDeleted = 1  
	FROM #TempOpenSection TOS
	INNER JOIN SLCMaster..Section MS WITH (NOLOCK)
	ON MS.SectionId = TOS.mSectionId AND MS.IsDeleted = 1;

	-- Select SubDivisions into #SubDivision
	SELECT DISTINCT  
	    PS.SectionId  
	   ,PS.ParentSectionId  
	   ,PS.mSectionId  
	   ,PS.ProjectId  
	   ,PS.CustomerId  
	   ,PS.UserId  
	   ,PS.DivisionId  
	   ,PS.DivisionCode  
	   ,PS.[Description]  
	   ,PS.LevelId  
	   ,PS.IsLastLevel  
	   ,PS.SourceTag  
	   ,PS.Author  
	   ,PS.TemplateId  
	   ,PS.SectionCode  
	   ,PS.IsDeleted  
	   ,PS.IsLocked  
	   ,PS.LockedBy  
	   ,PS.FormatTypeId  
	   ,PS.SpecViewModeId
	INTO #SubDivision  
	FROM ProjectSection PS WITH (NOLOCK)  
	INNER JOIN #TempOpenSection PS3 ON PS.SectionId = PS3.ParentSectionId  
	WHERE PS.ProjectId = @PProjectId  
	AND PS.IsLastLevel = 0  
	AND PS.CustomerId = @PCustomerId  
	AND ISNULL(PS.IsDeleted, 0) = 0
	ORDER BY PS.SourceTag;

	-- Select Divisions
	SELECT DISTINCT  
		PS.SectionId  
	   ,PS.ParentSectionId  
	   ,PS.mSectionId  
	   ,PS.ProjectId  
	   ,PS.CustomerId  
	   ,PS.UserId  
	   ,PS.DivisionId  
	   ,PS.DivisionCode  
	   ,PS.[Description]  
	   ,PS.LevelId
	   ,PS.IsLastLevel
	   ,PS.SourceTag
	   ,PS.Author
	   ,PS.TemplateId  
	   ,PS.SectionCode  
	   ,PS.IsDeleted  
	   ,PS.IsLocked  
	   ,PS.LockedBy  
	   ,PS.FormatTypeId  
	   ,PS.SpecViewModeId  
	FROM ProjectSection PS WITH (NOLOCK)  
	INNER JOIN #SubDivision PS2  
	 ON PS.SectionId = PS2.ParentSectionId  
	WHERE PS.ProjectId = @PProjectId  
	AND PS.IsLastLevel = 0  
	AND PS.CustomerId = @PCustomerId  
	AND ISNULL(PS.IsDeleted, 0) = 0;
	
	-- Select Sub Division
	SELECT * FROM #SubDivision;

	-- Select Open Leaf Sections
	SELECT * FROM #TempOpenSection;

	DROP TABLE IF EXISTS #SubDivision;
	DROP TABLE IF EXISTS #TempOpenSection;

END
GO
PRINT N'Altering [dbo].[usp_GetSourceTargetLinksCount]...';


GO
ALTER PROCEDURE usp_GetSourceTargetLinksCount  
(@ProjectId INT, @SectionId INT, @CustomerId INT, @SectionCode INT, @MasterDataTypeId TINYINT = 1, @CatalogueType NVARCHAR(100) = 'FS') 
AS    
BEGIN
  
--PARAMETER SNIFFING CARE  
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;
DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;
  
--VARIABLES  
--DECLARE @PMasterDataTypeId INT = ( SELECT  
--  P.MasterDataTypeId  
-- FROM Project P WITH (NOLOCK)  
-- WHERE P.ProjectId = @PProjectId  
-- AND P.CustomerId = @PCustomerId);  
  
--CONSTANTS  
DECLARE @MasterSegmentLinkSourceTypeId_CNST INT = 1;
DECLARE @UserSegmentLinkSourceTypeId_CNST INT = 5;

--TABLES  
--1.SegmentStatus of Section and their SrcLinksCount and TgtLinksCount  
DROP TABLE IF EXISTS #ResultTable
CREATE TABLE #ResultTable (
	ProjectId INT NOT NULL
   ,SectionId INT NOT NULL
   ,CustomerId INT NOT NULL
   ,SectionCode INT NULL
   ,SegmentStatusCode INT NULL
   ,SegmentCode INT NULL
   ,SegmentSource CHAR(1) NULL
   ,SrcLinksCnt INT NULL
   ,TgtLinksCnt INT NULL
   ,SegmentDescription NVARCHAR(MAX) NULL
   ,SequenceNumber DECIMAL(10, 4) NULL
   ,SegmentStatusId INT NULL
   ,SegmentId INT NULL
   ,mSegmentId INT NULL
   ,IndentLevel INT NULL
   ,SpecTypeTagId INT NULL
);
CREATE NONCLUSTERED INDEX [TMPIX_#ResultTable_SectionCode_SegmentStatusCode_SegmentCode_SegmentSource]
ON #ResultTable ([SectionCode], [SegmentStatusCode], [SegmentCode], [SegmentSource])

--2.Lookup SpecTypeTagsId Tables  
DROP TABLE IF EXISTS #SpecTypeTagIdTable
CREATE TABLE #SpecTypeTagIdTable (
	SpecTypeTagId INT
);

--3.Distinct SegmentStatus from Links tables  
DROP TABLE IF EXISTS #DistinctSegmentStatus
CREATE TABLE #DistinctSegmentStatus (
	ProjectId INT NULL
   ,CustomerId INT NULL
   ,SegmentStatusCode INT NULL
   ,SegmentSource CHAR(1) NULL
   ,SectionCode INT NULL
   ,SegmentCode INT NULL
   ,IsDeleted BIT NULL
);
CREATE NONCLUSTERED INDEX [TMPIX_#DistinctSegmentStatus_SectionCode_SegmentStatusCode_SegmentCode_SegmentSource]
ON #DistinctSegmentStatus ([SectionCode], [SegmentStatusCode], [SegmentCode], [SegmentSource])

--4.Section's of Project table  
DROP TABLE IF EXISTS #SectionsTable
CREATE TABLE #SectionsTable (
	SectionId INT NULL
   ,SectionCode INT NULL
);
CREATE NONCLUSTERED INDEX [TMPIX_#SectionsTable_SectionCode]
ON #SectionsTable ([SectionCode])

--5.All Src and Tgt Links Table  
DROP TABLE IF EXISTS #SegmentLinksTable
CREATE TABLE #SegmentLinksTable (
	ProjectId INT NULL
   ,CustomerId INT NULL
   ,SourceSectionCode INT NULL
   ,SourceSegmentStatusCode INT NULL
   ,SourceSegmentCode INT NULL
   ,SourceSegmentChoiceCode INT NULL
   ,SourceChoiceOptionCode INT NULL
   ,LinkSource NVARCHAR(MAX) NULL
   ,TargetSectionCode INT NULL
   ,TargetSegmentStatusCode INT NULL
   ,TargetSegmentCode INT NULL
   ,TargetSegmentChoiceCode INT NULL
   ,TargetChoiceOptionCode INT NULL
   ,LinkTarget NVARCHAR(MAX) NULL
   ,LinkStatusTypeId INT NULL
   ,SegmentLinkCode INT NULL
   ,SegmentLinkSourceTypeId INT NULL
   ,IsSrcLink INT NULL
   ,IsTgtLink INT NULL
   ,IsDeleted BIT NULL
);

--INSERT SEGMENT STATUS IN THIS LIST  
INSERT INTO #ResultTable (ProjectId, SectionId, CustomerId, SegmentStatusCode,
SequenceNumber, SegmentCode, SegmentDescription, SegmentSource, SectionCode,
SrcLinksCnt, TgtLinksCnt, SegmentStatusId, SegmentId, mSegmentId, IndentLevel, SpecTypeTagId)
	SELECT
		PSSTV.ProjectId
	   ,PSSTV.SectionId
	   ,PSSTV.CustomerId
	   ,PSSTV.SegmentStatusCode
	   ,PSSTV.SequenceNumber
	   ,PSSTV.SegmentCode
	   ,PSSTV.SegmentDescription
	   ,CAST(PSSTV.SegmentOrigin AS CHAR(1)) AS SegmentSource
	   ,PSSTV.SectionCode
	   ,0 AS SrcLinksCnt
	   ,0 AS TgtLinksCnt
	   ,PSSTV.SegmentStatusId
	   ,PSSTV.SegmentId
	   ,PSSTV.mSegmentId
	   ,PSSTV.IndentLevel
	   ,(CASE
			WHEN PSSTV.SpecTypeTagId IS NOT NULL THEN PSSTV.SpecTypeTagId
			ELSE 0
		END) AS SpecTypeTagId
	FROM ProjectSegmentStatusView PSSTV WITH (NOLOCK)
	WHERE PSSTV.ProjectId = @PProjectId
	AND PSSTV.SectionId = @PSectionId
	AND PSSTV.CustomerId = @PCustomerId
	AND ISNULL(PSSTV.IsDeleted, 0) = 0

-- To get SpecTypeTagId when entitlement is Outline/ShortForm
DECLARE @CatalogueTypeTbl TABLE (TagType NVARCHAR(10));                
 IF @PCatalogueType IS NOT NULL AND @PCatalogueType != 'FS'                                  
 BEGIN                                  
  INSERT INTO @CatalogueTypeTbl (TagType)                 
  SELECT splitdata AS TagType FROM fn_SplitString(@PCatalogueType, ',');                
                                  
  IF EXISTS (SELECT TOP 1 1 FROM @CatalogueTypeTbl WHERE TagType = 'OL')                                  
  BEGIN                                  
   INSERT INTO @CatalogueTypeTbl VALUES ('UO')                                  
  END                                  
  IF EXISTS (SELECT TOP 1 1 FROM @CatalogueTypeTbl WHERE TagType = 'SF')                                  
  BEGIN                                  
   INSERT INTO @CatalogueTypeTbl VALUES ('US')                                  
  END                                  
 END 

--REMOVE THOSE TO WHOME THERE IS DO NOT HAVE ACCESS DEPENDS UPON CATALOGUE TYPE  
IF @PCatalogueType != 'FS'
BEGIN
INSERT INTO #SpecTypeTagIdTable (SpecTypeTagId)
	SELECT
		SpecTypeTagId
	FROM LuProjectSpecTypeTag WITH (NOLOCK)
	WHERE TagType IN (select TagType from @CatalogueTypeTbl);
	--WHERE TagType IN (SELECT * FROM dbo.fn_SplitString(@PCatalogueType, ','));

DELETE RT
	FROM #ResultTable RT
WHERE RT.SpecTypeTagId NOT IN (SELECT
			TBL.SpecTypeTagId
		FROM #SpecTypeTagIdTable TBL)
END

--TODO--BELOW CODE NEED TO BE MOVE IN COMMON SP  
--INSERT SOURCE AND TARGET LINKS FROM PROJECT DB  
INSERT INTO #SegmentLinksTable (ProjectId, CustomerId,
SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode,
SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,
TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode,
TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId,
IsSrcLink, IsTgtLink, SegmentLinkSourceTypeId, IsDeleted, SegmentLinkCode)
	--INSERT SOURCE LINKS FROM PROJECT DB  
	SELECT
		PSLNK.ProjectId
	   ,PSLNK.CustomerId
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
	   ,1 AS IsSrcLink
	   ,0 AS IsTgtLink
	   ,PSLNK.SegmentLinkSourceTypeId
	   ,PSLNK.IsDeleted
	   ,PSLNK.SegmentLinkCode
	FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
	INNER JOIN #ResultTable INPJSON WITH (NOLOCK)
		ON PSLNK.TargetSectionCode = INPJSON.SectionCode
			AND PSLNK.TargetSegmentStatusCode = INPJSON.SegmentStatusCode
			AND PSLNK.TargetSegmentCode = INPJSON.SegmentCode
			AND PSLNK.LinkTarget = INPJSON.SegmentSource
	WHERE PSLNK.ProjectId = @PProjectId
	AND PSLNK.CustomerId = @PCustomerId
	AND PSLNK.SegmentLinkSourceTypeId IN (@MasterSegmentLinkSourceTypeId_CNST, @UserSegmentLinkSourceTypeId_CNST)
	AND ISNULL(PSLNK.IsDeleted, 0) = 0
	UNION
	--INSERT TARGET LINKS FROM PROJECT DB  
	SELECT
		PSLNK.ProjectId
	   ,PSLNK.CustomerId
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
	   ,0 AS IsSrcLink
	   ,1 AS IsTgtLink
	   ,PSLNK.SegmentLinkSourceTypeId
	   ,PSLNK.IsDeleted
	   ,PSLNK.SegmentLinkCode
	FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
	INNER JOIN #ResultTable INPJSON WITH (NOLOCK)
		ON PSLNK.SourceSectionCode = INPJSON.SectionCode
			AND PSLNK.SourceSegmentStatusCode = INPJSON.SegmentStatusCode
			AND PSLNK.SourceSegmentCode = INPJSON.SegmentCode
			AND PSLNK.LinkSource = INPJSON.SegmentSource
	WHERE PSLNK.ProjectId = @PProjectId
	AND PSLNK.CustomerId = @PCustomerId
	AND PSLNK.SegmentLinkSourceTypeId IN (@MasterSegmentLinkSourceTypeId_CNST, @UserSegmentLinkSourceTypeId_CNST)
	AND ISNULL(PSLNK.IsDeleted, 0) = 0

--FETCH SECTIONS OF PROJECT IN TEMP TABLE  
INSERT INTO #SectionsTable (SectionId, SectionCode)
	SELECT
		PS.SectionId
	   ,PS.SectionCode
	FROM ProjectSection PS WITH (NOLOCK)
	WHERE PS.ProjectId = @PProjectId
	AND PS.CustomerId = @PCustomerId
	AND PS.IsLastLevel = 1
	AND ISNULL(PS.IsDeleted, 0) = 0

--DELETE THOSE LINKS WHOSE LINK SOURCE TYPE IS NOT MASTER OR USER  
--DELETE FROM #SegmentLinksTable  
--WHERE SegmentLinkSourceTypeId NOT IN (@MasterSegmentLinkSourceTypeId_CNST, @UserSegmentLinkSourceTypeId_CNST)  

--DELETE WHICH ARE SOFT DELETED IN DB  
--DELETE FROM #SegmentLinksTable  
--WHERE IsDeleted = 1  

--DELETE SOURCE LINKS WHOSE SECTIONS ARE NOT AVAILABLE IN PROJECT  
DELETE SLNK
	FROM #SegmentLinksTable SLNK WITH (NOLOCK)
	LEFT JOIN #SectionsTable S WITH (NOLOCK)
		ON SLNK.SourceSectionCode = S.SectionCode
WHERE S.SectionId IS NULL

--DELETE TARGET LINKS WHOSE SECTIONS ARE NOT AVAILABLE IN PROJECT  
DELETE SLNK
	FROM #SegmentLinksTable SLNK WITH (NOLOCK)
	LEFT JOIN #SectionsTable S WITH (NOLOCK)
		ON SLNK.TargetSectionCode = S.SectionCode
WHERE S.SectionId IS NULL

--FETCH DISTINCT SEGMENT STATUS CODE  
INSERT INTO #DistinctSegmentStatus (ProjectId, CustomerId, SegmentStatusCode, SectionCode)
	SELECT DISTINCT
		X.ProjectId
	   ,X.CustomerId
	   ,X.SegmentStatusCode
	   ,X.SectionCode
	FROM (SELECT DISTINCT
			SLNKS.ProjectId AS ProjectId
		   ,SLNKS.CustomerId AS CustomerId
		   ,SLNKS.SourceSegmentStatusCode AS SegmentStatusCode
		   ,SLNKS.SourceSectionCode AS SectionCode
		FROM #SegmentLinksTable SLNKS UNION
		SELECT DISTINCT
			SLNKS.ProjectId AS ProjectId
		   ,SLNKS.CustomerId AS CustomerId
		   ,SLNKS.TargetSegmentStatusCode AS SegmentStatusCode
		   ,SLNKS.TargetSectionCode AS SectionCode
		FROM #SegmentLinksTable SLNKS) AS X

UPDATE DSTSG
SET DSTSG.SegmentCode = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SegmentCode
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SegmentCode
	END)
   ,DSTSG.SegmentSource = CAST((CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SegmentOrigin
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SegmentOrigin
	END) AS CHAR(1))
   ,DSTSG.SectionCode = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.SectionCode
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.SectionCode
	END)
   ,DSTSG.IsDeleted = (CASE
		WHEN PSSTV.SegmentStatusId IS NOT NULL THEN PSSTV.IsDeleted
		WHEN MSSTV.SegmentStatusId IS NOT NULL THEN MSSTV.IsDeleted
	END)
FROM #DistinctSegmentStatus DSTSG WITH (NOLOCK)
LEFT JOIN ProjectSegmentStatusView PSSTV WITH (NOLOCK)
	ON DSTSG.ProjectId = PSSTV.ProjectId
	AND DSTSG.CustomerId = PSSTV.CustomerId
	AND DSTSG.SectionCode = PSSTV.SectionCode
	AND DSTSG.SegmentStatusCode = PSSTV.SegmentStatusCode
	AND ISNULL(PSSTV.IsDeleted, 0) = 0

LEFT JOIN SLCMaster..SegmentStatusView MSSTV WITH (NOLOCK)
	ON DSTSG.SegmentStatusCode = MSSTV.SegmentStatusCode
	AND ISNULL(MSSTV.IsDeleted, 0) = 0

--DELETE UNMATCHED SEGMENT CODE IN SRC AND TGT LINKS AS WELL  
DELETE SLNK
	FROM #SegmentLinksTable SLNK
	LEFT JOIN #DistinctSegmentStatus DSST WITH (NOLOCK)
		ON SLNK.SourceSectionCode = DSST.SectionCode
		AND SLNK.SourceSegmentStatusCode = DSST.SegmentStatusCode
		AND SLNK.SourceSegmentCode = DSST.SegmentCode
		AND SLNK.LinkSource = DSST.SegmentSource
WHERE (SLNK.IsSrcLink = 1
	AND DSST.SegmentStatusCode IS NULL)

DELETE SLNK
	FROM #SegmentLinksTable SLNK
	LEFT JOIN #DistinctSegmentStatus DSST WITH (NOLOCK)
		ON SLNK.TargetSectionCode = DSST.SectionCode
		AND SLNK.TargetSegmentStatusCode = DSST.SegmentStatusCode
		AND SLNK.TargetSegmentCode = DSST.SegmentCode
		AND SLNK.LinkTarget = DSST.SegmentSource
WHERE (SLNK.IsTgtLink = 1
	AND DSST.SegmentStatusCode IS NULL)

DELETE SLNK
	FROM #SegmentLinksTable SLNK
	LEFT JOIN SegmentChoiceView SCHV WITH (NOLOCK)
		ON SCHV.ProjectId = @PProjectId
		AND SCHV.CustomerId = @PCustomerId
		AND SLNK.SourceSectionCode = SCHV.SectionCode
		AND SLNK.SourceSegmentStatusCode = SCHV.SegmentStatusCode
		AND SLNK.SourceSegmentCode = SCHV.SegmentCode
		AND SLNK.SourceSegmentChoiceCode = SCHV.SegmentChoiceCode
		AND SLNK.SourceChoiceOptionCode = SCHV.ChoiceOptionCode
		AND SLNK.LinkSource = SCHV.ChoiceOptionSource
WHERE SCHV.ProjectId = @PProjectId
	AND SCHV.SectionId = @PSectionId
	AND SLNK.IsSrcLink = 1
	AND ISNULL(SLNK.SourceSegmentChoiceCode, 0) > 0
	AND ISNULL(SLNK.SourceChoiceOptionCode, 0) > 0
	AND SLNK.LinkSource = 'U'
	AND SCHV.SegmentStatusId IS NULL

DELETE SLNK
	FROM #SegmentLinksTable SLNK
	LEFT JOIN SegmentChoiceView SCHV WITH (NOLOCK)
		ON SCHV.ProjectId = @PProjectId
		AND SCHV.CustomerId = @PCustomerId
		AND SLNK.TargetSectionCode = SCHV.SectionCode
		AND SLNK.TargetSegmentStatusCode = SCHV.SegmentStatusCode
		AND SLNK.TargetSegmentCode = SCHV.SegmentCode
		AND SLNK.TargetSegmentChoiceCode = SCHV.SegmentChoiceCode
		AND SLNK.TargetChoiceOptionCode = SCHV.ChoiceOptionCode
		AND SLNK.LinkTarget = SCHV.ChoiceOptionSource
WHERE SCHV.ProjectId = @PProjectId
	AND SCHV.SectionId = @PSectionId
	AND SLNK.IsTgtLink = 1
	AND ISNULL(SLNK.TargetSegmentChoiceCode, 0) > 0
	AND ISNULL(SLNK.TargetChoiceOptionCode, 0) > 0
	AND SLNK.LinkTarget = 'U'
	AND SCHV.SegmentStatusId IS NULL

--UPDATE TGT LINKS COUNT  
UPDATE TBL
SET TBL.TgtLinksCnt = X.TgtLinksCnt
FROM #ResultTable TBL
INNER JOIN (SELECT
		SourceSegmentStatusCode
	   ,LinkSource
	   ,COUNT(1) AS TgtLinksCnt
	FROM #SegmentLinksTable
	WHERE IsTgtLink = 1
	GROUP BY SourceSegmentStatusCode
			,LinkSource
			,IsTgtLink) X
	ON TBL.SegmentStatusCode = X.SourceSegmentStatusCode
	AND TBL.SegmentSource = X.LinkSource

--UPDATE SRC LINKS COUNT  
UPDATE TBL
SET TBL.SrcLinksCnt = X.SrcLinksCnt
FROM #ResultTable TBL
INNER JOIN (SELECT
		TargetSegmentStatusCode
	   ,LinkTarget
	   ,COUNT(1) AS SrcLinksCnt
	FROM #SegmentLinksTable
	WHERE IsSrcLink = 1
	GROUP BY TargetSegmentStatusCode
			,LinkTarget
			,IsSrcLink) X
	ON TBL.SegmentStatusCode = X.TargetSegmentStatusCode
	AND TBL.SegmentSource = X.LinkTarget

--DELETE UNWANTED RECORDS FROM RESULT LINKS TABLE  
DELETE FROM #ResultTable
WHERE SrcLinksCnt <= 0
	AND TgtLinksCnt <= 0

SELECT * FROM #ResultTable WITH (NOLOCK)
ORDER BY SequenceNumber ASC

--FETCH CHOICE LIST  
--DROP TABLE IF EXISTS #t  

SELECT
	t.SegmentStatusCode
   ,psc.SegmentChoiceCode
   ,CAST(pco.OptionJson AS NVARCHAR(MAX)) AS OptionJson
   ,psc.ChoiceTypeId
   ,pco.ChoiceOptionCode
   ,pco.SortOrder
   ,CAST(0 AS BIT) AS IsSelected INTO #t
FROM ProjectSegmentChoice psc WITH (NOLOCK)
INNER JOIN ProjectChoiceOption pco WITH (NOLOCK)
	ON psc.SegmentChoiceId = pco.SegmentChoiceId
		AND pco.ProjectId = @PProjectId
		AND pco.SectionId = @PSectionId
INNER JOIN #ResultTable t
	ON t.mSegmentId = psc.SegmentId
WHERE psc.ProjectId = @PProjectId
AND psc.CustomerId = @PCustomerId
AND psc.SectionId = @PSectionId;


INSERT INTO #t
	SELECT
		t.SegmentStatusCode
	   ,sc.SegmentChoiceCode
	   ,CAST(co.OptionJson AS NVARCHAR(MAX)) AS OptionJson
	   ,sc.ChoiceTypeId
	   ,co.ChoiceOptionCode
	   ,co.SortOrder
	   ,CAST(0 AS BIT) AS IsSelected
	FROM SLCMaster..SegmentChoice sc WITH (NOLOCK)
	INNER JOIN SLCMaster..ChoiceOption co WITH (NOLOCK)
		ON sc.SegmentChoiceId = co.SegmentChoiceId
	INNER JOIN #ResultTable t
		ON t.mSegmentId = sc.SegmentId;

INSERT INTO #t
	SELECT
		t.SegmentStatusCode
	   ,psc.SegmentChoiceCode
	   ,CAST(pco.OptionJson AS NVARCHAR(MAX)) AS OptionJson
	   ,psc.ChoiceTypeId
	   ,pco.ChoiceOptionCode
	   ,pco.SortOrder
	   ,CAST(0 AS BIT) AS IsSelected
	FROM #ResultTable t
	INNER JOIN ProjectSegmentChoice psc WITH (NOLOCK)
		ON t.SegmentStatusId = psc.SegmentStatusId
	INNER JOIN ProjectChoiceOption pco WITH (NOLOCK)
		ON psc.SegmentChoiceId = pco.SegmentChoiceId
			AND pco.ProjectId = @PProjectId
			AND pco.SectionId = @PSectionId
	WHERE psc.ProjectId = @PProjectId
	AND psc.CustomerId = @PCustomerId
	AND psc.SectionId = @PSectionId
	AND ISNULL(pco.IsDeleted, 0) = 0;

SELECT	* FROM #t;

--UPDATE t
--SET t.IsSelected = sco.IsSelected
--FROM #t t
--INNER JOIN SelectedChoiceOption sco WITH (NOLOCK)
--	ON t.ChoiceOptionCode = sco.ChoiceOptionCode
--WHERE sco.SectionId = @SectionId
--AND ISNULL(sco.IsDeleted, 0) = 0
--AND sco.IsSelected = 1

--SELECT  
-- RT.SegmentStatusCode  
--   ,SCHV.SegmentChoiceCode  
--   ,SCHV.ChoiceOptionCode  
--   ,SCHV.SortOrder  
--   ,SCHV.IsSelected  
--   ,SCHV.OptionJson  
--   ,SCHV.ChoiceTypeId  
--FROM SegmentChoiceView SCHV WITH (NOLOCK)  
--INNER JOIN #ResultTable RT WITH (NOLOCK)  
-- ON SCHV.SegmentStatusId = RT.SegmentStatusId  
--WHERE SCHV.ProjectId = @PProjectId  
--AND SCHV.CustomerId = @PCustomerId  
--AND SCHV.SectionId = @PSectionId  
--AND SCHV.IsSelected = 1  

----Fetch SECTION LIST  
--SELECT
--	PS.SectionCode
--   ,PS.SourceTag
--   ,PS.[Description] AS Description
--FROM ProjectSection PS WITH (NOLOCK)
--WHERE PS.ProjectId = @PProjectId
--AND PS.CustomerId = @PCustomerId
--AND PS.IsLastLevel = 1
--UNION
--SELECT
--	MS.SectionCode
--   ,MS.SourceTag
--   ,CAST(MS.Description AS NVARCHAR(500)) AS Description
--FROM SLCMaster..Section MS WITH (NOLOCK)
--LEFT JOIN ProjectSection PS WITH (NOLOCK)
--	ON PS.ProjectId = @PProjectId
--		AND PS.CustomerId = @PCustomerId
--		AND PS.mSectionId = MS.SectionId
--WHERE MS.MasterDataTypeId = @PMasterDataTypeId
--AND MS.IsLastLevel = 1
--AND PS.SectionId IS NULL
END
GO
PRINT N'Altering [dbo].[usp_GetTemplates]...';


GO
ALTER PROCEDURE [dbo].[usp_GetTemplates]
(      
 @CustomerId INT,      
 @masterDataTypeId INT      
)      
AS      
BEGIN      
 DECLARE @PCustomerId INT = @CustomerId;      
 --DECLARE @PmasterDataTypeId INT = @masterDataTypeId;      
    
 SELECT      
     T.TemplateId      
    ,T.[Name]      
    ,T.TitleFormatId      
    ,T.SequenceNumbering      
    ,T.CustomerId      
    ,T.IsSystem      
    --,T.IsDeleted      
    --,T.CreatedBy      
    --,T.CreateDate      
    --,T.ModifiedBy      
    --,T.ModifiedDate      
    ,T.MasterDataTypeId      
    --,T.A_TemplateId      
    ,T.ApplyTitleStyleToEOS      
 FROM Template T WITH (NOLOCK)    
 WHERE (T.CustomerId = @PCustomerId OR T.IsSystem = 1) AND ISNULL(T.IsDeleted, 0) = 0
END;

--EXEC usp_GetTemplates 641, 1
GO
PRINT N'Altering [dbo].[usp_GetUpdatesCount]...';


GO
ALTER PROCEDURE [dbo].[usp_GetUpdatesCount]  
@ProjectId INT, @SectionId INT, @CustomerId INT, @CatalogueType NVARCHAR(50) = 'FS'      
AS      
BEGIN  
DECLARE @PProjectId INT = @ProjectId;  
DECLARE @PSectionId INT = @SectionId;  
DECLARE @PCustomerId INT = @CustomerId;  
DECLARE @PCatalogueType NVARCHAR(50) = @CatalogueType;  
--DECLARE @ProjectId INT = 0;  
--DECLARE @SectionId INT = 0;  
--DECLARE @CustomerId INT = 0;  
--DECLARE @CatalogueType NVARCHAR(50) = '';  
  
--VARIABLES        
  
--FINAL TABLE CONTAINS [SEGMENTS UPDATES] OF VARIOUS TYPES        
DROP TABLE IF EXISTS #SegmentUpdatesTable;  
CREATE TABLE #SegmentUpdatesTable (  
 SegmentStatusId INT NULL  
   , --Project SegmentStatusId        
 ParentSegmentStatusId INT NULL  
   , --Project ParentSegmentStatusId        
 mSegmentStatusId INT NULL  
   , --Master SegmentStatusId        
 mSegmentId INT NULL  
   , --Master SegmentId        
 SegmentSource CHAR(1) NULL  
   , --SegmentSource        
 SegmentOrigin CHAR(2) NULL  
   , --SegmentOrigin        
 IndentLevel TINYINT NULL  
   , --IndentLevel        
 MasterIndentLevel TINYINT NULL  
   , --Master IndentLevel        
 UpdateType NVARCHAR(MAX) NULL  
   , --Update Type        
 ScenarioA BIT NULL  
   , --Is Delete ScenarioA        
 ScenarioB BIT NULL  
   , --Is Delete ScenarioB        
 ScenarioC BIT NULL  
   , --Is Delete ScenarioC        
);  
  
--TEMP TABLE USED TO STORE DELETED SEGMENTS COUNT        
DROP TABLE IF EXISTS #DeletedSegmentsTable;  
CREATE TABLE #DeletedSegmentsTable (  
 Id INT NULL  
   , -- Row Id        
 SegmentStatusId INT NULL  
   , --Project SegmentStatusId        
);  
  
--TABLE TO STORE DELETED SEGMENTS HIERARCHY        
DROP TABLE IF EXISTS #DeletedSegmentsHierarchy;  
CREATE TABLE #DeletedSegmentsHierarchy (  
 SegmentStatusId INT NULL  
   , --Project SegmentStatusId        
 ParentSegmentStatusId INT NULL  
   , --Project ParentSegmentStatusId        
 mSegmentStatusId INT NULL  
   , --Master SegmentStatusId        
 mSegmentId INT NULL  
   , --Master SegmentId        
 SegmentSource CHAR(1) NULL  
   , --SegmentSource        
 SegmentOrigin CHAR(2) NULL  
   , --SegmentOrigin        
 IndentLevel TINYINT NULL  
   , --IndentLevel        
 MasterIndentLevel TINYINT NULL  
   , --Master IndentLevel        
 ReferencedSegmentStatusId INT NULL --Original SegmentStatusId whose sub hierarchy is        
);  
  
--TABLE TO STORE RS UPDATES        
DROP TABLE IF EXISTS #RSUpdatesTable;  
CREATE TABLE #RSUpdatesTable (  
 RefStandardId INT NULL  
   ,RefStdName NVARCHAR(100) NULL  
);  
  
--TABLE TO STORE User RS UPDATES        
DROP TABLE IF EXISTS #URSUpdatesTable;  
CREATE TABLE #URSUpdatesTable (  
 RefStandardId INT NULL  
   ,RefStdName NVARCHAR(100) NULL  
);  
  
--TABLE TO STORE NEW PARAGRAPH UPDATES    
DROP TABLE IF EXISTS #MutedParagraphUpdatesTable;  
CREATE TABLE #MutedParagraphUpdatesTable (  
 mSegmentStatusId INT NULL  
   ,mSegmentId INT NULL  
);  
  
--TABLE TO STORE SPECTYPETAGID'S    
DROP TABLE IF EXISTS #LuSpecTypeTagTable;  
CREATE TABLE #LuSpecTypeTagTable (  
 SpecTypeTagId INT NULL  
);  
  
DECLARE @UpdateType_TEXT NVARCHAR(MAX) = 'TEXT';  
DECLARE @UpdateType_DELETE NVARCHAR(MAX) = 'DELETE';  
DECLARE @UpdateType_MANUFACTURER NVARCHAR(MAX) = 'MANUFACTURER';  
DECLARE @RequirementTagId_ML INT = 11;  
DECLARE @UpdatesCount INT = 0;  
  
DECLARE @DeletedSegmentsCount INT = NULL;  
DECLARE @DeletedSegmentsLoopCount INT = NULL;  
DECLARE @LoopedSegmentStatusId INT = NULL;  
  
DECLARE @mSectionId INT = NULL;  
  
--GET mSectionId    
SELECT  
 @mSectionId = PS.mSectionId  
FROM ProjectSection PS WITH (NOLOCK)  
INNER JOIN SLCMaster..Section MS WITH (NOLOCK)  
 ON PS.mSectionId = MS.SectionId  
WHERE PS.SectionId = @PSectionId  
AND PS.ProjectId = @PProjectId  
AND PS.CustomerId = @PCustomerId  
AND ISNULL( MS.IsDeleted,0) = 0  
AND PS.Author != 'USER'  
  
IF @mSectionId IS NOT NULL  
 AND @mSectionId > 0  
BEGIN  
  
--IF undefined CAME FROM UI THEN SET TO FS  
IF @CatalogueType = 'undefined'  
BEGIN  
SET @CatalogueType = 'FS';  
END  
  
--CALCULATE SPECTYPETAG ID'S  
IF @CatalogueType != 'FS'    
BEGIN  
INSERT INTO #LuSpecTypeTagTable (SpecTypeTagId)  
 SELECT  
  SpecTypeTagId  
 FROM LuProjectSpecTypeTag WITH (NOLOCK)  
 WHERE TagType IN (SELECT  
   *  
  FROM dbo.fn_SplitString(@CatalogueType, ','))  
END  
  
--FETCH [MASTER TEXT UPDATES], [MANUFACTURER UPDATES] AND [MASTER SEGMENT DELETE UPDATES] OF NORMAL SCENARIOS        
INSERT INTO #SegmentUpdatesTable (SegmentStatusId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId,  
SegmentSource, SegmentOrigin, IndentLevel, MasterIndentLevel, UpdateType)  
 SELECT DISTINCT  
  PSST.SegmentStatusId AS SegmentStatusId  
    ,PSST.ParentSegmentStatusId AS ParentSegmentStatusId  
    ,PSST.mSegmentStatusId AS mSegmentStatusId  
    ,PSST.mSegmentId AS mSegmentId  
    ,PSST.SegmentSource AS SegmentSource  
    ,PSST.SegmentOrigin AS SegmentOrigin  
    ,PSST.IndentLevel AS IndentLevel  
    ,MST.IndentLevel AS MasterIndentLevel  
    ,(CASE  
   WHEN ISNULL(PSST.IsDeleted, 0) = 0 AND  
    ISNULL(MST.IsDeleted, 0) = 0 AND  
    ISNULL(MSG.UpdatedId, 0) > 0 AND  
    MSRT.SegmentRequirementTagId IS NOT NULL THEN @UpdateType_MANUFACTURER  
   WHEN ISNULL(PSST.IsDeleted, 0) = 0 AND  
    ISNULL(MST.IsDeleted, 0) = 0 AND  
    ISNULL(MSG.UpdatedId, 0) > 0 AND  
    MSRT.SegmentRequirementTagId IS NULL THEN @UpdateType_TEXT  
   WHEN ISNULL(PSST.IsDeleted, 0) = 0 AND  
    ISNULL(MST.IsDeleted, 0) > 0 THEN @UpdateType_DELETE  
  END) AS UpdateType  
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)  
 INNER JOIN SLCMaster..SegmentStatus MST WITH (NOLOCK)  
  ON PSST.mSegmentStatusId = MST.SegmentStatusId  
 INNER JOIN SLCMaster..Segment MSG WITH (NOLOCK)  
  ON PSST.mSegmentId = MSG.SegmentId  
 LEFT JOIN #LuSpecTypeTagTable TMPLST  
  ON PSST.SpecTypeTagId = TMPLST.SpecTypeTagId  
 LEFT JOIN SLCMaster..SegmentRequirementTag MSRT WITH (NOLOCK)  
  ON MST.SegmentStatusId = MSRT.SegmentStatusId  
   AND MSRT.RequirementTagId = @RequirementTagId_ML  
 WHERE PSST.SectionId = @PSectionId  
 AND PSST.ProjectId = @PProjectId  
 AND PSST.CustomerId = @PCustomerId  
 AND PSST.SegmentSource = 'M'  
 AND PSST.IsRefStdParagraph = 0  
 AND PSST.mSegmentId IS NOT NULL  
 AND ((  
 ISNULL(PSST.IsDeleted, 0) = 0  
 AND ISNULL(MST.IsDeleted, 0) = 0  
 AND ISNULL(MSG.UpdatedId, 0) > 0  
 )  
 OR (  
 ISNULL(PSST.IsDeleted, 0) = 0  
 AND ISNULL(MST.IsDeleted, 0) > 0  
 ))  
 AND ((@CatalogueType = 'FS')  
 OR (TMPLST.SpecTypeTagId IS NOT NULL))  
  
--PUSH DELETED SEGMENTS INTO ONE TABLE        
INSERT INTO #DeletedSegmentsTable (Id, SegmentStatusId)  
 SELECT  
  ROW_NUMBER() OVER (ORDER BY SegmentStatusId ASC)  
    ,SegmentStatusId  
 FROM #SegmentUpdatesTable  
 WHERE UpdateType = @UpdateType_DELETE  
  
SET @DeletedSegmentsCount = (SELECT  
  COUNT(*)  
 FROM #DeletedSegmentsTable);  
  
--FETCH DELETED SEGMENTS AND THEIR SUB HIERARCHY INTO TEMP TABLE        
;  
WITH CTE_SubHierarchy  
AS  
(  
 --GET DELETED SEGMENTS        
 SELECT  
  UT.SegmentStatusId AS SegmentStatusId  
    ,UT.ParentSegmentStatusId AS ParentSegmentStatusId  
    ,UT.mSegmentStatusId AS mSegmentStatusId  
    ,UT.mSegmentId AS mSegmentId  
    ,CAST(UT.SegmentSource AS CHAR(1)) AS SegmentSource  
    ,CAST(UT.SegmentOrigin AS CHAR(2)) SegmentOrigin  
    ,UT.IndentLevel AS IndentLevel  
    ,UT.SegmentStatusId AS ReferencedSegmentStatusId  
 FROM #SegmentUpdatesTable UT  
 WHERE UT.UpdateType = @UpdateType_DELETE  
 UNION ALL  
 --GET SUB HIERARCHY OF DELETED SEGMENTS        
 SELECT  
  CPSST.SegmentStatusId AS SegmentStatusId  
    ,CPSST.ParentSegmentStatusId AS ParentSegmentStatusId  
    ,CPSST.mSegmentStatusId AS mSegmentStatusId  
    ,CPSST.mSegmentId AS mSegmentId  
    ,CAST(CPSST.SegmentSource AS CHAR(1)) AS SegmentSource  
    ,CAST(CPSST.SegmentOrigin AS CHAR(2)) AS SegmentOrigin  
    ,CPSST.IndentLevel AS IndentLevel  
    ,CTE.ReferencedSegmentStatusId AS ReferencedSegmentStatusId  
 FROM CTE_SubHierarchy CTE  
 INNER JOIN ProjectSegmentStatus CPSST WITH (NOLOCK)  
  ON CTE.SegmentStatusId = CPSST.ParentSegmentStatusId  
 WHERE CPSST.SectionId = @PSectionId
 AND CPSST.ProjectId = @PProjectId  
 AND CPSST.CustomerId = @PCustomerId )  
  
INSERT INTO #DeletedSegmentsHierarchy (SegmentStatusId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId,  
SegmentSource, SegmentOrigin, IndentLevel, ReferencedSegmentStatusId)  
 SELECT  
  SegmentStatusId  
    ,ParentSegmentStatusId  
    ,mSegmentStatusId  
    ,mSegmentId  
    ,SegmentSource  
    ,SegmentOrigin  
    ,IndentLevel  
    ,ReferencedSegmentStatusId  
 FROM CTE_SubHierarchy  
  
--UPDATE MASTER INDENT LEVEL IN HIERARCHY        
UPDATE PSST  
SET PSST.MasterIndentLevel = MST.IndentLevel  
FROM #DeletedSegmentsHierarchy PSST  
INNER JOIN SLCMaster..SegmentStatus MST WITH (NOLOCK)  
 ON PSST.mSegmentStatusId = MST.SegmentStatusId  
  
--LOOP DELETED SEGMENTS TO FIND THEIR COMPLEX SCENARIOS A,B,C IF ANY        
SET @DeletedSegmentsLoopCount = 1;  
        
WHILE(@DeletedSegmentsLoopCount <= @DeletedSegmentsCount)        
BEGIN  
SET @LoopedSegmentStatusId = (SELECT  
  SegmentStatusId  
 FROM #DeletedSegmentsTable  
 WHERE Id = @DeletedSegmentsLoopCount);  
      
DECLARE @ScenarioA BIT = NULL;  
DECLARE @ScenarioB BIT = NULL;  
DECLARE @ScenarioC BIT = NULL;  
         
--SCENARIO A        
IF EXISTS (SELECT TOP 1  
  SegmentStatusId  
 FROM #DeletedSegmentsHierarchy  
 WHERE ReferencedSegmentStatusId = @LoopedSegmentStatusId  
 AND IndentLevel != MasterIndentLevel)  
BEGIN  
SET @ScenarioA = 1;  
END  
     
--SCENARIO B        
IF EXISTS (SELECT TOP 1  
  SegmentStatusId  
 FROM #DeletedSegmentsHierarchy  
 WHERE ReferencedSegmentStatusId = @LoopedSegmentStatusId  
 AND SegmentSource = 'U'  
 AND SegmentOrigin = 'U')  
BEGIN  
SET @ScenarioB = 1;  
END  
    
--SCENARIO C        
IF EXISTS (SELECT TOP 1  
  SegmentStatusId  
 FROM #DeletedSegmentsHierarchy  
 WHERE ReferencedSegmentStatusId = @LoopedSegmentStatusId  
 AND SegmentSource = 'M'  
 AND SegmentOrigin = 'U')  
BEGIN  
SET @ScenarioC = 1;  
END  
  
UPDATE #SegmentUpdatesTable  
SET @ScenarioA = @ScenarioA  
   ,@ScenarioB = @ScenarioB  
   ,@ScenarioC = @ScenarioC  
WHERE SegmentStatusId = @LoopedSegmentStatusId;  
  
SET @DeletedSegmentsLoopCount = @DeletedSegmentsLoopCount + 1;  
END  
  
--FETCH RS UPDATES        
INSERT INTO #RSUpdatesTable (RefStandardId, RefStdName)  
 SELECT  
  RS.RefStdId AS RefStandardId  
    ,RS.RefStdName AS RefStdName  
 FROM ProjectReferenceStandard ProjRefStd WITH (NOLOCK)  
 INNER JOIN SLCMaster..ReferenceStandardEdition Edn WITH (NOLOCK)  
  ON ProjRefStd.RefStandardId = Edn.RefStdId  
 INNER JOIN SLCMaster..ReferenceStandard RS WITH (NOLOCK)  
  ON RS.RefStdId = Edn.RefStdId  
 WHERE ProjRefStd.SectionId = @PSectionId  
 AND ProjRefStd.ProjectId = @PProjectId  
 AND ProjRefStd.CustomerId = @PCustomerId  
 AND ISNULL( ProjRefStd.IsDeleted,0) = 0  
 AND ProjRefStd.RefStdSource = 'M'  
 AND Edn.RefStdEditionId > ProjRefStd.RefStdEditionId  
 GROUP BY RS.RefStdId,RS.RefStdName;

--GET MUTED PARAGRAPH UPDATES COUNT    
IF EXISTS (SELECT TOP 1  
   PSST.SegmentStatusId  
  FROM ProjectSegmentStatus PSST WITH (NOLOCK)  
  WHERE PSST.SectionId = @PSectionId
  AND PSST.ProjectId = @PProjectId  
  AND PSST.CustomerId = @PCustomerId)  
BEGIN  
INSERT INTO #MutedParagraphUpdatesTable (mSegmentStatusId, mSegmentId)  
 SELECT  
  MST.SegmentStatusId AS mSegmentStatusId  
    ,MSG.SegmentId AS mSegmentId  
 FROM SLCMaster..SegmentStatus MST WITH (NOLOCK)  
 INNER JOIN SLCMaster..Segment MSG WITH (NOLOCK)  
  ON MST.SegmentId = MSG.SegmentId  
 LEFT JOIN ProjectSegmentStatus PSST WITH (NOLOCK)  
  ON PSST.ProjectId = @PProjectId  
   AND PSST.CustomerId = @PCustomerId  
   AND PSST.SectionId = @PSectionId  
   AND PSST.mSegmentStatusId IS NOT NULL  
   AND PSST.mSegmentStatusId > 0  
   AND PSST.mSegmentStatusId = MST.SegmentStatusId  
 WHERE MST.SectionId = @mSectionId  
 AND ISNULL(MST.IsDeleted, 0) = 0  
 AND PSST.SegmentStatusId IS NULL  
END  
  
END  

--FETCH User RS UPDATES    
INSERT INTO #URSUpdatesTable (RefStandardId, RefStdName)  
 SELECT  
  RS.RefStdId AS RefStandardId  
    ,RS.RefStdName AS RefStdName  
 FROM ProjectReferenceStandard ProjRefStd WITH (NOLOCK)  
 INNER JOIN ReferenceStandardEdition Edn WITH (NOLOCK)  
  ON ProjRefStd.RefStandardId = Edn.RefStdId  
 INNER JOIN ReferenceStandard RS WITH (NOLOCK)  
  ON RS.RefStdId = Edn.RefStdId  
 WHERE ProjRefStd.SectionId = @PSectionId  
 AND ProjRefStd.ProjectId = @PProjectId  
 AND ProjRefStd.CustomerId = @PCustomerId  
 AND ISNULL( ProjRefStd.IsDeleted,0) = 0  
 AND ProjRefStd.RefStdSource = 'U'  
 AND ISNULL( RS.IsDeleted,0) = 0  
 AND Edn.RefStdEditionId > ProjRefStd.RefStdEditionId  
 GROUP BY RS.RefStdId, RS.RefStdName;  

  
--CALCULATE FINAL COUNT        
	SET @UpdatesCount = (SELECT COUNT(1) FROM #SegmentUpdatesTable);
	SET @UpdatesCount = @UpdatesCount + (SELECT COUNT(1) FROM #RSUpdatesTable);
	SET @UpdatesCount = @UpdatesCount + (SELECT COUNT(1) FROM #URSUpdatesTable);
	SET @UpdatesCount = @UpdatesCount + (SELECT COUNT(1) FROM #MutedParagraphUpdatesTable);

	--SELECT FINAL RESULT        
	SELECT @PProjectId AS ProjectId, @PSectionId AS SectionId, @PCustomerId AS CustomerId, @UpdatesCount AS UpdatesCount;

END
GO
PRINT N'Altering [dbo].[usp_LockUnLockUsersSection]...';


GO
ALTER PROCEDURE [dbo].[usp_LockUnLockUsersSection]     
@ProjectId INT NULL,     
@CustomerId INT NULL,    
@UserId INT NULL=NULL,     
@SectionId INT NULL=NULL,    
@UserName VARCHAR (50) NULL=NULL     
AS    
BEGIN
   
DECLARE @PProjectId INT = @ProjectId;  
DECLARE @PCustomerId INT = @CustomerId;  
DECLARE @PUserId INT = @UserId;  
DECLARE @PSectionId INT = @SectionId;  
DECLARE @PUserName VARCHAR (50) = @UserName;  
    
DECLARE @IsLocked BIT = 0, @IsLockedImportSection BIT = 0;

-- check if target section is already locked    
SELECT @IsLocked= IIF(LockedBy <> @PUserId AND IsLocked = 1, 1, 0), @IsLockedImportSection=IsLockedImportSection 
FROM [projectSection] WITH (NOLOCK) WHERE SectionId = @PSectionId OPTION (FAST 1)
      
IF(@IsLocked=0)      
	BEGIN  
	-- Release lock if any section is locked earlier    
		UPDATE PS  
		SET IsLocked = 0  
		   ,LockedBy = 0  
		   ,LockedByFullName = ''  
		FROM ProjectSection PS WITH (NOLOCK)  
		WHERE ProjectId = @PProjectId  
		AND CustomerId = @PCustomerId  
		AND LockedBy = @PUserId
		AND IsLastLevel = 1
		AND IsLocked = 1;
  
		UPDATE PS  
		SET IsLocked = 1  
		   ,LockedBy = @PUserId  
		   ,LockedByFullName = @PUserName  
		   ,ModifiedBy = @PUserId  
		   ,ModifiedDate = GETUTCDATE()  
		FROM ProjectSection PS WITH (NOLOCK)  
		WHERE SectionId = @PSectionId;  

	END  
ELSE
	BEGIN  
		SET @IsLocked = 1;
	END

-- Select section lock info
SELECT @IsLocked AS IsLocked,@IsLockedImportSection AS IsLockedImportSection   

END
GO
PRINT N'Altering [dbo].[usp_RealeaseRefStdLock]...';


GO
ALTER PROCEDURE [dbo].[usp_RealeaseRefStdLock]  
	@RefStdId int,  
	@LockedByUserId INT     
AS   
BEGIN
	DECLARE @PrefStdId int = @refStdId;    
	DECLARE @PLockedByUserId int = @LockedByUserId;    
  
	IF (@PrefStdId > 0)  
	BEGIN  
		 UPDATE RS    
		 SET RS.IsLocked = 0    
		   ,RS.IsLockedById = NULL    
		   ,RS.IsLockedByFullName = NULL    
		 FROM ReferenceStandard RS WITH (NOLOCK)    
		 WHERE RS.RefStdId = @PrefStdId AND RS.IsLockedById = @PLockedByUserId AND RS.IsLocked = 1;    
	END
    
	SELECT    
		RefStdId    
	   ,RefStdName    
	   ,RefStdSource    
	   ,ReplaceRefStdId    
	   ,ReplaceRefStdSource    
	   ,mReplaceRefStdId    
	   ,IsObsolete    
	   ,RefStdCode    
	   ,CreateDate    
	   ,CreatedBy    
	   ,ModifiedDate    
	   ,ModifiedBy    
	   ,CustomerId    
	   ,IsDeleted    
	   ,IsLocked    
	   ,IsLockedByFullName    
	   ,IsLockedById    
	FROM ReferenceStandard WITH (NOLOCK)    
	WHERE RefStdId = @PrefStdId;    
    
END;
GO
PRINT N'Altering [dbo].[usp_RemoveNotification]...';


GO
ALTER PROC usp_RemoveNotification
(  
 @RequestId INT,
 @Source NVARCHAR(50)
)  
AS  
BEGIN  
	IF(@Source='CopyProject')
	BEGIN
		UPDATE CPR  
		SET CPR.IsDeleted=1,  
		ModifiedDate=GETUTCDATE()  
		FROM CopyProjectRequest CPR WITH(NOLOCK)  
		WHERE CPR.StatusId NOT IN(2) AND CPR.RequestId=@RequestId  
	END
	ELSE IF(@Source='unArchiveProject')
	BEGIN
		UPDATE CPR  
		SET CPR.IsDeleted=1,  
		ModifiedDate=GETUTCDATE()  
		FROM UnArchiveProjectRequest CPR WITH(NOLOCK)  
		WHERE CPR.StatusId NOT IN(1,2) AND CPR.RequestId=@RequestId  
	END
	ELSE IF(@Source='SpecAPI')
	BEGIN
		UPDATE CPR  
		SET CPR.IsDeleted=1,  
		ModifiedDate=GETUTCDATE()  
		FROM ImportProjectRequest CPR WITH(NOLOCK)  
		WHERE CPR.StatusId NOT IN(1,2) AND CPR.RequestId=@RequestId  
	END
END
GO
PRINT N'Altering [dbo].[usp_SpecDataSetSegmentChoiceOption]...';


GO
ALTER procedure [dbo].[usp_SpecDataSetSegmentChoiceOption]
(
   @SegmentStatusJson NVARCHAR(max)
)
AS
BEGIN

DECLARE @TempMappingtable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,SectionId INT
   ,SegmentChoiceId INT
   ,ChoiceOptionId INT
   ,SegmentStatusId INT
   ,OptionJson nvarchar(MAX)
   ,RowId INT
)

INSERT INTO @TempMappingtable
	SELECT
		*
	   ,ROW_NUMBER() OVER (ORDER BY ProjectId ASC) AS RowId
	FROM OPENJSON(@SegmentStatusJson)
	WITH (
	ProjectId INT '$.ProjectId',
	CustomerId INT '$.CustomerId',
	SectionId INT '$.SectionId',
	SegmentChoiceId INT '$.SegmentChoiceId',
	ChoiceOptionId INT '$.ChoiceOptionId'
	, SegmentStatusId INT '$.SegmentStatusId'
	, OptionJson NVARCHAR(MAX) '$.OptionJson'
	);

DECLARE @CustomerId INT = 0;
DECLARE @ProjectId INT = 0;

SELECT TOP 1
	@CustomerId = CustomerId
   ,@ProjectId = ProjectId
FROM @TempMappingtable

DECLARE @SingleSelectionChoiceTable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,SectionId INT
   ,SegmentChoiceId INT
   ,ChoiceOptionId INT
   ,SegmentStatusId INT
   ,OptionJson NVARCHAR(MAX)
)

SELECT DISTINCT
	slcmsc.ChoiceTypeId
   ,slcmsc.SectionId
   ,slcmsc.SegmentChoiceCode
   ,slcmsc.SegmentStatusId INTO #SlcMasterChoiceTempTable
FROM SLCMaster..SegmentChoice slcmsc WITH (NOLOCK)
INNER JOIN @TempMappingtable TMT
	ON slcmsc.SectionId = TMT.SectionId
		AND slcmsc.SegmentStatusId = TMT.SegmentStatusId
		AND TMT.SegmentChoiceId = slcmsc.SegmentChoiceCode

INSERT INTO @SingleSelectionChoiceTable (ProjectId, CustomerId, SectionId, SegmentChoiceId,
ChoiceOptionId, SegmentStatusId, OptionJson)
	SELECT DISTINCT
		TMT.ProjectId
	   ,TMT.CustomerId
	   ,TMT.SectionId
	   ,TMT.SegmentChoiceId
	   ,TMT.ChoiceOptionId
	   ,TMT.SegmentStatusId
	   ,TMT.OptionJson
	FROM #SlcMasterChoiceTempTable slcmsc 
	INNER JOIN @TempMappingtable TMT
		ON slcmsc.SectionId = TMT.SectionId
			AND slcmsc.SegmentStatusId = TMT.SegmentStatusId
			AND TMT.SegmentChoiceId = slcmsc.SegmentChoiceCode
			AND slcmsc.ChoiceTypeId = 1

DECLARE @SingleSelectionFinalChoiceTable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,SectionId INT
   ,SegmentChoiceId INT
   ,ChoiceOptionId INT
   ,SegmentStatusId INT
   ,OptionJson NVARCHAR(MAX)
)

INSERT INTO @SingleSelectionFinalChoiceTable
	SELECT
		ProjectId
	   ,CustomerId
	   ,SectionId
	   ,SegmentChoiceId
	   ,ChoiceOptionId
	   ,SegmentStatusId
	   ,OptionJson
	FROM (SELECT
			*
		   ,ROW_NUMBER() OVER (PARTITION BY SegmentChoiceId ORDER BY ChoiceOptionId DESC) AS RowNo
		FROM @SingleSelectionChoiceTable) AS X
	WHERE X.RowNo = 1

DECLARE @MultipleSelectionChoiceTable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,SectionId INT
   ,SegmentChoiceId INT
   ,ChoiceOptionId INT
   ,SegmentStatusId INT
   ,OptionJson NVARCHAR(MAX)
)

INSERT INTO @MultipleSelectionChoiceTable (ProjectId, CustomerId, SectionId, SegmentChoiceId,
ChoiceOptionId, SegmentStatusId, OptionJson)
	SELECT DISTINCT
		TMT.ProjectId
	   ,TMT.CustomerId
	   ,TMT.SectionId
	   ,TMT.SegmentChoiceId
	   ,TMT.ChoiceOptionId
	   ,TMT.SegmentStatusId
	   ,TMT.OptionJson
	FROM #SlcMasterChoiceTempTable slcmsc 
	INNER JOIN @TempMappingtable TMT
		ON slcmsc.SectionId = TMT.SectionId
			AND slcmsc.SegmentStatusId = TMT.SegmentStatusId
			AND TMT.SegmentChoiceId = slcmsc.SegmentChoiceCode
			AND slcmsc.ChoiceTypeId > 1

DROP TABLE IF EXISTS #ChoiceTempTable

SELECT DISTINCT
	SCO.SelectedChoiceOptionId
   ,SCO.SegmentChoiceCode
   ,SCO.ChoiceOptionCode
   ,SCO.ProjectId
   ,SCO.CustomerId
   ,SCO.SectionId
   ,0 AS IsSelected
   ,SCO.OptionJson
   ,TMTBL.SectionId AS mSectionId INTO #ChoiceTempTable
FROM @TempMappingtable TMTBL
INNER JOIN ProjectSection ps WITH (NOLOCK)
	ON ps.mSectionId = TMTBL.SectionId
		AND ps.ProjectId = TMTBL.ProjectId
		AND ps.CustomerId = TMTBL.CustomerId
INNER JOIN SelectedChoiceOption SCO WITH (NOLOCK)
	ON ps.SectionId = SCO.SectionId
		AND SCO.ProjectId = TMTBL.ProjectId
		AND SCO.SegmentChoiceCode = TMTBL.SegmentChoiceId
		AND SCO.CustomerId = TMTBL.CustomerId
		AND SCO.ChoiceOptionSource = 'M'
WHERE SCO.ProjectId = @ProjectId
AND SCO.CustomerId = @CustomerId


IF ((SELECT
			COUNT(SegmentStatusId)
		FROM @SingleSelectionChoiceTable)
	> 0)
BEGIN

UPDATE SCO
SET SCO.IsSelected = 1
   ,SCO.OptionJson = IIF(TMTBL.OptionJson = '', NULL, TMTBL.OptionJson)
FROM #ChoiceTempTable SCO
INNER JOIN @SingleSelectionFinalChoiceTable TMTBL
	ON TMTBL.SectionId = SCO.mSectionId
	AND SCO.SegmentChoiceCode = TMTBL.SegmentChoiceId
	AND SCO.ChoiceOptionCode = TMTBL.ChoiceOptionId

END

IF ((SELECT
			COUNT(SegmentStatusId)
		FROM @MultipleSelectionChoiceTable)
	> 0)
BEGIN
UPDATE SCO
SET SCO.IsSelected = 1
   ,SCO.OptionJson = IIF(TMTBL.OptionJson = '', NULL, TMTBL.OptionJson)
FROM #ChoiceTempTable SCO WITH (NOLOCK)
INNER JOIN @MultipleSelectionChoiceTable TMTBL
	ON TMTBL.SectionId = SCO.mSectionId
	AND SCO.SegmentChoiceCode = TMTBL.SegmentChoiceId
	AND SCO.ChoiceOptionCode = TMTBL.ChoiceOptionId

END

UPDATE SCO
SET SCO.IsSelected = CHT.IsSelected
   ,SCO.OptionJson = CHT.OptionJson
FROM #ChoiceTempTable CHT
INNER JOIN SelectedChoiceOption SCO WITH (NOLOCK)
	ON SCO.SelectedChoiceOptionId = CHT.SelectedChoiceOptionId
WHERE SCO.SectionId = CHT.SectionId
AND SCO.ProjectId = @ProjectId
AND SCO.CustomerId = @CustomerId

END
GO
PRINT N'Altering [dbo].[usp_UpdateReferenceStatdard]...';


GO
ALTER Procedure [dbo].[usp_UpdateReferenceStatdard]    
(    
@inpRefStdDtoJson nvarchar(max)    
)    
As    
Begin    
DECLARE @PinpRefStdDtoJson nvarchar(max) = @inpRefStdDtoJson;    
  Declare @ReferenceStandard Table(    
  [RefStdId] int,    
  [ModifiedBy] int    
 );    
    
  Declare @ReferenceStandardEdition Table(    
 [RefStdEditionId] int,    
 [RefEdition] nvarchar(255),    
 [RefStdTitle] nvarchar(1024),    
 [LinkTarget] nvarchar(1024),    
 [CreatedBy] int,    
 [RefStdId] int,    
 [CustomerId] int,    
 [ModifiedBy] int,    
 [A_RefStdEditionId] int    
 );    
    
 Declare @inpRefStdTbl Table(    
   ReferenceStandard nvarchar(max),    
   ReferenceStandardEdition nvarchar(max)    
 );    
    
INSERT INTO @inpRefStdTbl (ReferenceStandard, ReferenceStandardEdition)    
 SELECT    
  *    
 FROM OPENJSON(@PinpRefStdDtoJson)    
 WITH (    
 ReferenceStandard NVARCHAR(MAX) AS JSON,    
 ReferenceStandardEdition NVARCHAR(MAX) AS JSON    
 );    
    
DECLARE @refStndJson NVARCHAR(MAX);    
DECLARE @refStndEdtnJson NVARCHAR(MAX);    
    
SELECT    
 @refStndJson = ReferenceStandard    
   ,@refStndEdtnJson = ReferenceStandardEdition    
FROM @inpRefStdTbl;    
    
INSERT INTO @ReferenceStandard ([RefStdId], [ModifiedBy])    
 SELECT    
  *    
 FROM OPENJSON(@refStndJson)    
 WITH (    
 [RefStdId] INT '$.Id',    
 ModifiedBy INT '$.ModifiedBy'    
 );    
    
INSERT INTO @ReferenceStandardEdition ([RefStdEditionId], [RefEdition], [RefStdTitle], [LinkTarget], [CreatedBy],    
[RefStdId], [CustomerId], [ModifiedBy], [A_RefStdEditionId])    
 SELECT    
  *    
 FROM OPENJSON(@refStndEdtnJson)    
 WITH (    
 [RefStdEditionId] INT '$.RefStdEditionId',    
 RefEdition NVARCHAR(255) '$.RefEdition',    
 RefStdTitle NVARCHAR(1024) '$.RefStdTitle',    
 LinkTarget NVARCHAR(1024) '$.LinkTarget',    
 CreatedBy INT '$.CreatedBy',    
 RefStdId INT '$.RefStdId',    
 CustomerId INT '$.CustomerId',    
 [ModifiedBy] INT '$.ModifiedBy',    
 [A_RefStdEditionId] INT '$.A_RefStdEditionId'    
 );    
    
UPDATE refstd    
SET refstd.ModifiedDate = GETUTCDATE()    
   ,refstd.ModifiedBy = temp_refStd.ModifiedBy    
   ,refstd.Islocked =    
 CASE    
  WHEN refstd.IsLocked = 1 THEN 0    
  ELSE refstd.IsLocked    
 END    
   ,refstd.IsLockedById =    
 CASE    
  WHEN refstd.IsLocked = 1 THEN NULL    
  ELSE refstd.IsLockedById    
 END    
   ,refstd.IsLockedByFullName =    
 CASE    
  WHEN refstd.IsLocked = 1 THEN NULL    
  ELSE refstd.IsLockedByFullName    
 END    
FROM @ReferenceStandard temp_refStd    
INNER JOIN ReferenceStandard refstd WITH (NOLOCK)    
 ON refstd.RefStdId = temp_refStd.RefStdId    
  
  INSERT INTO ReferenceStandardEdition ( [RefEdition], [RefStdTitle],[LinkTarget], [CreateDate],[CreatedBy],    
[RefStdId], [CustomerId], [ModifiedBy], [A_RefStdEditionId])   
select  [RefEdition], [RefStdTitle], [LinkTarget], GETUTCDATE(),[CreatedBy],    
[RefStdId], [CustomerId], [ModifiedBy], [A_RefStdEditionId]   
from @ReferenceStandardEdition   
  
--UPDATE refStdEdtn    
--SET refStdEdtn.RefEdition = temp_refStdEdtn.RefEdition    
--   ,refStdEdtn.RefStdTitle = temp_refStdEdtn.RefStdTitle    
--   ,refStdEdtn.LinkTarget = temp_refStdEdtn.LinkTarget    
--   ,refStdEdtn.ModifiedDate = GETUTCDATE()    
--   ,refStdEdtn.ModifiedBy = temp_refStdEdtn.ModifiedBy    
--FROM @ReferenceStandardEdition temp_refStdEdtn    
--INNER JOIN ReferenceStandardEdition refStdEdtn WITH (NOLOCK)    
-- ON temp_refStdEdtn.RefStdEditionId = refStdEdtn.RefStdEditionId    
    
SELECT    
 *    
FROM ReferenceStandard WITH (NOLOCK)    
WHERE RefStdId = (SELECT    
  RefStdId    
 FROM @ReferenceStandard );    
END;
GO
PRINT N'Altering [dbo].[usp_UpdateSegmentsRSMapping]...';


GO
ALTER PROCEDURE [dbo].[usp_UpdateSegmentsRSMapping]    
(    
 @SegmentStatusId INT NULL = 0,    
 @IsDeleted INT NULL = 0,    
 @ProjectId INT = NULL,    
 @SectionId INT = NULL,    
 @CustomerId INT = NULL,    
 @UserId INT = NULL,    
 @SegmentId INT = NULL,    
 @MSegmentId INT = NULL,    
 @SegmentDescription NVARCHAR(MAX) = NULL    
)    
AS    
BEGIN    
 DECLARE @PSegmentStatusId INT = @SegmentStatusId;    
 DECLARE @PIsDeleted INT = @IsDeleted;    
 DECLARE @PProjectId INT = @ProjectId;    
 DECLARE @PSectionId INT = @SectionId;    
 DECLARE @PCustomerId INT = @CustomerId;    
 DECLARE @PUserId INT = @UserId;    
 DECLARE @PSegmentId INT = @SegmentId;    
 DECLARE @PMSegmentId INT = @MSegmentId;    
 DECLARE @PSegmentDescription NVARCHAR(MAX) = @SegmentDescription;    
    
SET NOCOUNT ON;    
               
    
 DECLARE @SegmentRS TABLE(RSCode INT NULL);    
 CREATE TABLE #UserSegmentRS (    
     CustomerId INT NULL,    
  ProjectId INT NULL,    
  SectionId INT NULL,    
  SegmentId INT NULL,    
  mSegmentId INT NULL,    
  RefStandardId INT NULL,    
  RefStandardSource CHAR(1) NULL,    
  RefStdCode INT NULL,       
  mRefStandardId INT NULL,    
  CreatedDate DATETIME NULL,    
  CreatedBy INT NULL,     
  ModifiedDate DATETIME NULL,    
  ModifiedBy INT NULL    
 );    
    
 IF @PIsDeleted = 1 AND @PSegmentStatusId > 0 -- Only proceed if SegmentStatusId is not zero    
 BEGIN    
SET @PSegmentDescription = '';    
--SELECT    
-- @PProjectId = ProjectId    
--   ,@PSectionId = SectionId    
--   ,@PCustomerId = CustomerId    
--   ,@PUserId = 0    
--   ,@PSegmentId = SegmentId    
--   ,@PMSegmentId = MSegmentId    
--FROM ProjectSegmentStatus WITH (NOLOCK)    
--WHERE SegmentStatusId = @PSegmentStatusId    
END    
 BEGIN TRY    
  INSERT INTO @SegmentRS    
  SELECT    
   *    
  FROM (SELECT    
    [value] AS RSCode    
   FROM STRING_SPLIT(dbo.[udf_GetCodeFromFormat](@PSegmentDescription, '{RS#'), ',')    
   UNION ALL    
   SELECT    
    *    
   FROM dbo.[udf_GetRSUsedInChoice](@PSegmentDescription, @PProjectId, @PSectionId)) AS SegmentRSTbl    
 END TRY    
 BEGIN CATCH    
  insert into BsdLogging..AutoSaveLogging    
  values('usp_UpdateSegmentsRSMapping',    
  getdate(),    
  ERROR_MESSAGE(),    
  ERROR_NUMBER(),    
  ERROR_Severity(),    
  ERROR_LINE(),    
  ERROR_STATE(),    
  ERROR_PROCEDURE(),    
  concat('SELECT * FROM dbo.[udf_GetRSUsedInChoice](',@PSegmentDescription,',',@PProjectId,',',@PSectionId,')'),    
  @PSegmentDescription    
 )    
 END CATCH    
--Use below variable to find ref std's which are USER CREATED by checking RefStdCode column    
DECLARE @MinUserRefStdCode INT = 10000000;    
    
--Calculate count of user ref std's which came from UI segment description    
DECLARE @RefStdCount_UI INT = (SELECT    
  COUNT(1)    
 FROM @SegmentRS    
 WHERE RSCode > @MinUserRefStdCode);    
    
--Calculate count of user ref std's which are in mapping table for that segment in DB    
DECLARE @RefStdCount_MPTBL INT = (SELECT    
  COUNT(1)    
 FROM ProjectSegmentReferenceStandard WITH (NOLOCK)    
 WHERE ProjectId=@PProjectId    
 AND RefStdCode > @MinUserRefStdCode    
 AND SegmentId = @PSegmentId);    
    
--Call below logic if data is available in either UI segment's description or in mapping table    
IF (@RefStdCount_UI > 0    
 OR @RefStdCount_MPTBL > 0)    
BEGIN    
INSERT INTO #UserSegmentRS    
 SELECT    
  @PCustomerId AS CustomerId    
    ,@PProjectId AS ProjectId    
    ,@PSectionId AS SectionId    
    ,@PSegmentId AS SegmentId    
    ,@PMSegmentId AS mSegmentId    
    ,RS.RefStdId AS RefStandardId    
    ,RS.RefStdSource AS RefStandardSource    
    ,RS.RefStdCode AS RefStdCode    
    ,0 AS mRefStandardId    
    ,GETUTCDATE() AS CreatedDate    
    ,@PUserId AS CreatedBy    
    ,NULL AS ModifiedDate    
    ,NULL AS ModifiedBy    
    
 FROM @SegmentRS SRS    
 LEFT JOIN ReferenceStandard RS WITH (NOLOCK)    
  ON RS.RefStdCode = SRS.RSCode    
  and RS.CustomerId  = @PCustomerId    
 WHERE RS.CustomerId = @PCustomerId     AND RS.RefStdSource = 'U'    
 AND ISNULL(RS.IsDeleted,0) = 0    
 UNION    
 SELECT    
  @PCustomerId AS CustomerId    
    ,@PProjectId AS ProjectId    
    ,@PSectionId AS SectionId    
    ,@PSegmentId AS SegmentId    
    ,@PMSegmentId AS mSegmentId    
    ,0 AS RefStandardId    
    ,'M' AS RefStandardSource    
    ,MRS.RefStdCode AS RefStdCode    
    ,MRS.RefStdId AS mRefStandardId    
    ,GETUTCDATE() AS CreatedDate    
    ,@PUserId AS CreatedBy    
    ,NULL AS ModifiedDate    
    ,NULL AS ModifiedBy    
 FROM @SegmentRS SRS    
 INNER JOIN SLCMaster..ReferenceStandard MRS WITH (NOLOCK)    
  ON MRS.RefStdCode = SRS.RSCode    
   AND MRS.RefStdCode IS NOT NULL    
    
--Delete Unsed RS for Segment    
    
UPDATE PSRS    
SET PSRS.IsDeleted = 1    
FROM ProjectSegmentReferenceStandard PSRS  WITH (NOLOCK)    
LEFT JOIN #UserSegmentRS URS WITH (NOLOCK)    
 ON PSRS.RefStdCode = URS.RefStdCode    
 AND PSRS.ProjectId = URS.ProjectId    
WHERE PSRS.ProjectId = @PProjectId    
AND PSRS.SectionId = @PSectionId    
AND (PSRS.SegmentId = @PSegmentId    
OR PSRS.mSegmentId = @PMSegmentId    
OR PSRS.SegmentId = 0)    
AND ISNULL(PSRS.IsDeleted,0) = 0    
    
IF @PIsDeleted = 0--Only proceed if IsDeleted is zero    
BEGIN    
--Insert Used Reference Standard for Segment    
INSERT INTO ProjectSegmentReferenceStandard (SectionId,    
SegmentId,    
RefStandardId,    
RefStandardSource,    
mRefStandardId,    
CreateDate,    
CreatedBy,    
ModifiedDate,    
ModifiedBy,    
CustomerId,    
ProjectId,    
mSegmentId,    
RefStdCode)    
 SELECT DISTINCT    
  URS.SectionId    
    ,URS.SegmentId    
    ,URS.RefStandardId    
    ,URS.RefStandardSource    
    ,URS.mRefStandardId    
    ,GETUTCDATE() AS CreatedDate    
    ,URS.CreatedBy    
    ,GETUTCDATE() AS ModifiedDate    
    ,URS.ModifiedBy    
    ,URS.CustomerId    
    ,URS.ProjectId    
    ,URS.mSegmentId    
    ,URS.RefStdCode    
 FROM #UserSegmentRS URS with (nolock)    
 WHERE URS.SectionId = @PSectionId    
 AND URS.ProjectId = @PProjectId    
    
SELECT DISTINCT MAX(RefStdEditionId) AS RefStdEditionId,    
 RefStdId INTO #TM FROM SLCMaster.dbo.ReferenceStandardEdition WITH (NOLOCK)    
 GROUP BY RefStdId    
    
 SELECT DISTINCT MAX(RefStdEditionId) AS RefStdEditionId,    
 RefStdId INTO #TP FROM ReferenceStandardEdition WITH (NOLOCK)    
 GROUP BY RefStdId    
    
    
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId, IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId)    
 SELECT DISTINCT    
  FinalPRS.*    
 FROM (SELECT    
   PSRS.ProjectId    
     ,PSRS.mRefStandardId AS RefStandardId    
     ,PSRS.RefStandardSource AS RefStdSource    
     ,ISNULL(MREFSTD.ReplaceRefStdId, 0) AS mReplaceRefStdId    
     ,(CASE    
    WHEN PRS.ProjRefStdId IS NOT NULL THEN PRS.RefStdEditionId    
    ELSE M.RefStdEditionId    
   END) AS RefStdEditionId    
     ,CAST(0 AS BIT) AS IsObsolete    
     ,PSRS.RefStdCode    
     ,GETUTCDATE() AS PublicationDate    
     ,PSRS.SectionId    
     ,PSRS.CustomerId    
  FROM ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)    
  INNER JOIN SLCMaster..ReferenceStandard MREFSTD WITH (NOLOCK)    
   ON PSRS.mRefStandardId = MREFSTD.RefStdId    
  LEFT JOIN ProjectReferenceStandard PRS  WITH (NOLOCK)    
   ON PSRS.ProjectId = PRS.ProjectId    
   AND PSRS.CustomerId = PRS.CustomerId    
   --AND PSRS.SectionId = PRS.SectionId    
   AND PSRS.mRefStandardId = PRS.RefStandardId    
   AND PRS.RefStdSource = 'M'    
   AND PRS.IsDeleted = 0    
    
  LEFT JOIN #TM T    
   ON T.RefStdId = PSRS.mRefStandardId    
  LEFT JOIN SLCMaster.dbo.ReferenceStandardEdition M WITH (NOLOCK)    
   ON T.RefStdId=M.RefStdId AND T.RefStdEditionId=M.RefStdEditionId    
    
  --CROSS APPLY (SELECT    
  -- TOP 1    
  --  RSE.RefStdEditionId    
  -- FROM SLCMaster..ReferenceStandardEdition RSE WITH (NOLOCK)    
  -- WHERE RSE.RefStdId = PSRS.mRefStandardId    
  -- ORDER BY RSE.RefStdEditionId DESC) AS MREFEDN    
    
  WHERE    
  PSRS.SectionId = @PSectionId    
  AND PSRS.ProjectId =  @PProjectId    
  AND PSRS.RefStandardSource = 'M'    
  AND PSRS.CustomerId = @PCustomerId    
  AND PSRS.IsDeleted = 0    
  UNION    
  SELECT    
   PSRS.ProjectId    
     ,PSRS.RefStandardId    
     ,PSRS.RefStandardSource AS RefStdSource    
     ,0 AS mReplaceRefStdId    
     ,(CASE    
    WHEN PRS.ProjRefStdId IS NOT NULL THEN PRS.RefStdEditionId    
    ELSE U.RefStdEditionId    
   END) AS RefStdEditionId    
     ,CAST(0 AS BIT) AS IsObsolete    
     ,PSRS.RefStdCode    
     ,GETUTCDATE() AS PublicationDate    
     ,PSRS.SectionId    
     ,PSRS.CustomerId    
  FROM ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)    
    
  INNER JOIN ReferenceStandard UREFSTD WITH (NOLOCK)    
   ON PSRS.RefStandardId = UREFSTD.RefStdId    
    
  LEFT JOIN ProjectReferenceStandard PRS WITH (NOLOCK)    
   ON PSRS.ProjectId = PRS.ProjectId    
   AND PSRS.CustomerId = PRS.CustomerId    
   AND PRS.IsDeleted = 0    
   --AND PSRS.SectionId = PRS.SectionId    
   AND PSRS.RefStandardId = PRS.RefStandardId    
   AND PRS.RefStdSource = 'U'    
    
  LEFT JOIN #TP T     
  ON T.RefStdId= PSRS.RefStandardId    
  LEFT JOIN ReferenceStandardEdition U WITH (NOLOCK)    
  ON T.RefStdId= U.RefStdId AND T.RefStdEditionId=U.RefStdEditionId    
  WHERE PSRS.SectionId = @PSectionId    
  AND PSRS.ProjectId =  @PProjectId    
  AND PSRS.RefStandardSource = 'U'    
  AND PSRS.CustomerId = @PCustomerId    
  AND PSRS.IsDeleted = 0) AS FinalPRS    
    
 LEFT JOIN ProjectReferenceStandard TEMPPRS WITH (NOLOCK)    
  ON FinalPRS.ProjectId = TEMPPRS.ProjectId    
   AND FinalPRS.RefStandardId = TEMPPRS.RefStandardId    
   AND FinalPRS.RefStdSource = TEMPPRS.RefStdSource    
   AND FinalPRS.RefStdEditionId = TEMPPRS.RefStdEditionId    
   AND FinalPRS.RefStdCode = TEMPPRS.RefStdCode    
   AND FinalPRS.SectionId = TEMPPRS.SectionId    
   AND FinalPRS.CustomerId = TEMPPRS.CustomerId    
   AND TEMPPRS.IsDeleted = 0    
    
 WHERE TEMPPRS.ProjRefStdId IS NULL    
END    
  
--UPDATE PRS    
--SET PRS.IsDeleted = 1    
-- FROM ProjectReferenceStandard PRS  WITH (NOLOCK)    
-- LEFT JOIN ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)    
--  ON PSRS.SectionId = PRS.SectionId    
--  AND PSRS.ProjectId = PRS.ProjectId    
--  AND PSRS.RefStdCode = PRS.RefStdCode    
--WHERE PRS.SectionId = @PSectionId    
-- AND PRS.CustomerId = @PCustomerId    
-- AND PRS.ProjectId = @PProjectId    
-- AND PSRS.RefStdCode IS NULL    
  
DROP TABLE if EXISTS #PSRSData  
SELECT   
PRS.ProjectId  
,PRS.RefStandardId  
,PRS.RefStdSource  
,PRS.mReplaceRefStdId  
,PRS.RefStdEditionId  
,PRS.IsObsolete  
,PRS.RefStdCode  
,PRS.PublicationDate  
,PRS.SectionId  
,PRS.CustomerId  
,PRS.ProjRefStdId  
,PRS.IsDeleted,PSRS.IsDeleted AS SegIsDeleted  
INTO #PSRSData  
FROM ProjectReferenceStandard PRS WITH (NOLOCK)    
left JOIN ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)    
ON PSRS.SectionId = PRS.SectionId    
AND PSRS.RefStdCode = PRS.RefStdCode   
WHERE PRS.SectionId = @PSectionId    
AND PRS.ProjectId = @PProjectId    
AND PRS.CustomerId = @PCustomerId      
AND ISNULL(PRS.IsDeleted,0)=0    
  
IF NOT EXISTS(select 1,1 from #PSRSData WHERE SegIsDeleted=0)  
BEGIN  
 UPDATE PRS set PRS.IsDeleted=1  
 FROM ProjectReferenceStandard PRS  WITH (NOLOCK)  INNER JOIN #PSRSData D ON D.SectionId = PRS.SectionId    
 AND D.RefStdCode = PRS.RefStdCode   
END  
  
  
END    
END
GO
PRINT N'Altering [dbo].[usp_ValidateGlobalTerms]...';


GO
ALTER PROCEDURE [dbo].[usp_ValidateGlobalTerms]      
(
	@Name NVARCHAR(255),
	@CustomerId INT
)
AS         
BEGIN  
	DECLARE @PName NVARCHAR(255) = @Name;  
	DECLARE @PCustomerId INT= @CustomerId;  
	SET NOCOUNT ON;

	DECLARE @IsNameAlreadyExist BIT = 0;

	IF EXISTS(SELECT TOP 1 1 FROM [SLCMaster].dbo.GlobalTerm MGT WITH (NOLOCK) WHERE MGT.[Name] = @PName)
		BEGIN
			SET @IsNameAlreadyExist = 1;
		END

	
	IF(@IsNameAlreadyExist = 0)
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM UserGlobalTerm GT WITH (NOLOCK) WHERE GT.[Name] = @PName  
																   AND GT.CustomerId = @PCustomerId 
																   AND ISNULL(GT.IsDeleted, 0) = 0)
		BEGIN
			SET @IsNameAlreadyExist = 1;
		END
	END

	SELECT @IsNameAlreadyExist AS IsNameAlreadyExist;
END
GO
PRINT N'Altering [dbo].[usp_ValidateReferenceStandards]...';


GO
ALTER PROCEDURE [dbo].[usp_ValidateReferenceStandards]          
@RefStdName NVARCHAR(max) NULL,        
@MasterDataTypeId INT,        
@CustomerId  INT         
AS                   
BEGIN          
DECLARE @PRefStdName nvarchar(max) = @RefStdName;              
DECLARE @PMasterDataTypeId INT=@MasterDataTypeId        
DECLARE @PCustomerId  INT=@CustomerId        

	DECLARE @IsNameAlreadyExist BIT = 0;

	IF EXISTS(SELECT TOP 1 1 FROM ReferenceStandard PRS WITH (NOLOCK) WHERE PRS.CustomerId=@PCustomerId 
																  AND  PRS.RefStdName = @PRefStdName 
																  AND ISNULL(PRS.IsDeleted, 0) = 0)
			BEGIN
				SET @IsNameAlreadyExist = 1;
			END
	SELECT @IsNameAlreadyExist AS IsNameAlreadyExist
END
-- EXEC usp_ValidateReferenceStandards 'NFRC 400', 1, 235
GO
PRINT N'Creating [dbo].[sp_UnArchiveProject]...';


GO
CREATE PROCEDURE [dbo].[sp_UnArchiveProject]  
AS  
BEGIN  
    
 DECLARE @ErrorCode INT = 0  
 DECLARE @Return_Message VARCHAR(1024)  
 DECLARE @ErrorStep VARCHAR(50)  
 DECLARE @NumberRecords int, @RowCount int  
 DECLARE @RequestId AS INT  
  
 IF OBJECT_ID('tempdb..#tmpUnArchiveCycleIDs') IS NOT NULL DROP TABLE #tmpUnArchiveCycleIDs  
 CREATE TABLE #tmpUnArchiveCycleIDs  
 (  
  RowID     INT IDENTITY(1, 1),   
  SLC_CustomerId   INT NOT NULL,  
  SLC_UserId    INT NOT NULL,  
  SLC_ArchiveProjectId INT NOT NULL,  
  OldSLC_ProjectID  INT NULL,  
  SLC_ServerId   INT NULL,  
  MigrateStatus   INT NULL,  
  CreatedDate    DATETIME NULL,  
  MovedDate    DATETIME NULL,  
  MigratedDate   DATETIME NULL,  
  IsProcessed    BIT NULL DEFAULT((0)),  
  Archive_ServerId  INT NOT NULL  
 )  
  
 DECLARE @IsProjectMigrationFailed AS INT = 0  
  
 INSERT INTO #tmpUnArchiveCycleIDs (SLC_CustomerId, SLC_UserId, SLC_ArchiveProjectId, OldSLC_ProjectID, SLC_ServerId, IsProcessed, Archive_ServerId)  
 SELECT AP.SLC_CustomerId, AP.SLC_UserId, AP.SLC_ArchiveProjectId, AP.SLC_ProdProjectId AS OldSLC_ProjectID, AP.SLC_ServerId, 0 AS IsProcessed, AP.Archive_ServerId  
 FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] AP WITH (NOLOCK)  
 INNER JOIN [SLCADMIN].[Authentication].[dbo].[CustomerTenantDbServer] CS ON CS.CustomerId = AP.SLC_CustomerId   
  AND AP.SLC_ServerId IN (SELECT TenantDbServerId FROM [SLCADMIN].[Authentication].[dbo].[LuTenantDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName'))  
 WHERE AP.InProgressStatusId = 3 --UnArchiveInitiated  
  AND AP.ProcessInitiatedById = 3 --SLC  
  AND AP.DisplayTabId = 2 --ArchivedTab  
  AND AP.IsArchived = 1  
  AND AP.SLC_ServerId IN (SELECT TenantDbServerId FROM [SLCADMIN].[Authentication].[dbo].[LuTenantDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName'))  
  
 -- Get the number of records in the temporary table  
 SET @NumberRecords = @@ROWCOUNT  
 SET @RowCount = 1  
  
 -- loop through all records in the temporary table using the WHILE loop construct  
 WHILE @RowCount <= @NumberRecords  
 BEGIN  
  
  --Set IsProjectMigrationFailed to 0 to reset it  
  SET @IsProjectMigrationFailed = 0  
  SET @RequestId = 0  
  
  DECLARE @OldSLC_ProjectID INT = 0  
  
  DECLARE @CustomerID INT, @SubscriptionID INT, @SLE_ProjectID INT, @MigrateStatus INT, @MigratedDate DATETIME, @SLC_CustomerId INT, @SLC_UserId INT, @ProjectID INT, @IsProcessed INT, @CycleID BIGINT = 0  
   , @SLC_ServerId INT, @Archive_ServerId INT  
  --Get next CycleID  
  SELECT @SLC_CustomerId = SLC_CustomerId, @SLC_UserId = SLC_UserId, @ProjectID = SLC_ArchiveProjectId, @OldSLC_ProjectID = OldSLC_ProjectID, @SLC_ServerId = SLC_ServerId, @IsProcessed = IsProcessed  
   ,@Archive_ServerId = Archive_ServerId  
  FROM #tmpUnArchiveCycleIDs WHERE RowID = @RowCount AND IsProcessed = 0  
  
  --Call Unarchive Project for SLC Project procedure depend on the ArchiveServer mapping  
  IF @Archive_ServerId = 1  
  BEGIN  
   EXECUTE [SLCProject].[dbo].[sp_UnArchiveProject_ArchServer01] @SLC_CustomerId, @SLC_UserId, @ProjectID, @OldSLC_ProjectID, @Archive_ServerId  
  END  
  ELSE IF @Archive_ServerId = 2  
  BEGIN  
   EXECUTE [SLCProject].[dbo].[sp_UnArchiveProject_ArchServer02] @SLC_CustomerId, @SLC_UserId, @ProjectID, @OldSLC_ProjectID, @Archive_ServerId  
  END  
  
  --Update Processed to 1  
  UPDATE A  
  SET A.IsProcessed = 1  
  FROM #tmpUnArchiveCycleIDs A  
  WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID;  
  
  SET @RowCount = @RowCount + 1  
 END  
  
 DROP TABLE #tmpUnArchiveCycleIDs  
  
END
GO
PRINT N'Creating [dbo].[usp_AddProjectActivity]...';


GO
CREATE PROCEDURE [dbo].[usp_AddProjectActivity](
@ProjectId INT NULL,
@UserId INT NULL,    
@CustomerId INT NULL,  
@ProjectName NVARCHAR(100) NULL,
@UserEmail  NVARCHAR(100) NULL,
@ProjectActivityTypeId TINYINT  
)
AS 
BEGIN
INSERT INTO ProjectActivity ( 
  ProjectId
, UserId
, CustomerId
, ProjectName
, UserEmail
, ProjectActivityTypeId
, CreatedDate
)
	VALUES (@ProjectId,@UserId,@CustomerId,@ProjectName,@UserEmail,@ProjectActivityTypeId,GETUTCDATE() )
END
GO
PRINT N'Creating [dbo].[usp_ApplyProjectDefaultSetting]...';


GO
CREATE PROCEDURE [dbo].[usp_ApplyProjectDefaultSetting] (    
@IsOfficeMaster BIT,      
@ProjectId INT,  
@UserId INT,      
@CustomerId INT  
)    
AS      
BEGIN    
DECLARE @PIsOfficeMaster BIT = @IsOfficeMaster;    
DECLARE @PUserId INT = @UserId;    
DECLARE @PCustomerId INT = @CustomerId;    
    
--Insert add user into the Project Team Member list     
INSERT INTO UserProjectAccessMapping    
SELECT     
 @ProjectId AS ProjectId    
   ,@PUserId AS UserId    
   ,PDPS.CustomerId    
   ,PDPS.CreatedBy    
   ,GETUTCDATE() AS CreateDate    
   ,PDPS.ModifiedBy    
   ,GETUTCDATE() AS ModifiedDate    
   ,CAST(1 AS BIT) AS IsActive FROM ProjectDefaultPrivacySetting PDPS WITH(NOLOCK)    
WHERE PDPS.CustomerId=@CustomerId     
AND PDPS.ProjectAccessTypeId IN (2,3)  --Private,Hidden    
AND ProjectOriginTypeId=1 --Not Assigned    
AND ProjectOwnerTypeId=1 --Projects that are created or copied in SLC    
AND PDPS.IsOfficeMaster=@IsOfficeMaster    
    
END
GO
PRINT N'Creating [dbo].[usp_CreateImportUserTag]...';


GO
CREATE PROCEDURE  [dbo].[usp_CreateImportUserTag] 
(  
	@CustomerId INT,
	@UserId INT,
	@TagType VARCHAR(5),  
	@Description VARCHAR(MAX)
)  
AS
BEGIN
	DECLARE @SortOrder INT = 0;
	DECLARE @UserTagId INT = 0;

SET @SortOrder = (SELECT
		COUNT(1)
	FROM ProjectUserTag WITH (NOLOCK)
	WHERE CustomerId = @CustomerId)
SET @SortOrder = @SortOrder + 1
	
	IF NOT EXISTS (SELECT TOP 1
		1
	FROM ProjectUserTag WITH (NOLOCK)
	WHERE CustomerId = @CustomerId
	AND TagType = @TagType)
BEGIN
INSERT INTO ProjectUserTag (CustomerId, TagType, [Description], SortOrder, IsSystemTag, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)
	VALUES (@CustomerId, @TagType, @Description, @SortOrder, 0, GETUTCDATE(), @UserId, GETUTCDATE(), @UserId);
SET @UserTagId = SCOPE_IDENTITY();
    END
	ELSE
	BEGIN
SET @UserTagId = (SELECT DISTINCT
		UserTagId
	FROM ProjectUserTag WITH (NOLOCK)
	WHERE CustomerId = @CustomerId
	AND TagType = @TagType)
	END

SELECT
	@UserTagId AS UserTagId

END
GO
PRINT N'Creating [dbo].[usp_CreateTargetSection]...';


GO
CREATE PROCEDURE usp_CreateTargetSection
	@SourceSectionId INT ,
	@ProjectId INT,
	@CustomerId INT,
	@UserId INT,
	@SourceTag VARCHAR(10),
	@Author NVARCHAR(10),
	@Description NVARCHAR(500),
	@ParentSectionId INT,
	@TargetSectionId INT OUTPUT 
AS
BEGIN
	--DECLARE @TargetSectionId INT = 0;
	SET @TargetSectionId = 0; 

	BEGIN -- Create New/Target Section

		--DECLARE @ParentSectionId INT = 0;
		--DECLARE @ParentSectionIdTable TABLE (ParentSectionId INT);    
    
		---- Calculate ParentSectionId                  
		--INSERT INTO @ParentSectionIdTable (ParentSectionId)                  
		--EXEC usp_GetParentSectionIdForImportedSection @ProjectId, @CustomerId, @UserId, @SourceTag;                  
   
		--SELECT TOP 1 @ParentSectionId = ParentSectionId FROM @ParentSectionIdTable;
            
		-- Insert Target Section
		INSERT INTO ProjectSection (ParentSectionId, ProjectId, CustomerId, UserId,                  
		DivisionId, DivisionCode, Description, LevelId, IsLastLevel, SourceTag,                  
		Author, TemplateId,CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted, FormatTypeId, SpecViewModeId,   
		IsLockedImportSection,IsTrackChanges,IsTrackChangeLock,TrackChangeLockedBy)
		SELECT
		 @ParentSectionId AS ParentSectionId
		,@ProjectId AS ProjectId
		,@CustomerId AS CustomerId
		,@UserId AS UserId
		,NULL AS DivisionId
		,NULL AS DivisionCode
		,@Description AS [Description]
		,PS.LevelId AS LevelId                  
		,1 AS IsLastLevel                  
		,@SourceTag AS SourceTag                  
		,@Author AS Author                  
		,PS.TemplateId AS TemplateId                  
		,GETUTCDATE() AS CreateDate                  
		,@UserId AS CreatedBy                  
		,GETUTCDATE() AS ModifiedDate                  
		,@UserId AS ModifiedBy                  
		,0 AS IsDeleted    
		,PS.FormatTypeId AS FormatTypeId                  
		,PS.SpecViewModeId AS SpecViewModeId  
		,PS.IsLockedImportSection AS IsLockedImportSection
		,PS.IsTrackChanges AS IsTrackChanges	
		,PS.IsTrackChangeLock AS IsTrackChangeLock	
		,PS.TrackChangeLockedBy As TrackChangeLockedBy
		FROM ProjectSection PS WITH (NOLOCK)
		WHERE PS.SectionId = @SourceSectionId;
    
		SET @TargetSectionId = SCOPE_IDENTITY();

		EXEC usp_SetDivisionIdForUserSection @ProjectId                
         ,@TargetSectionId                
         ,@CustomerId; 

		SELECT @TargetSectionId AS TargetSectionId;

	END

END
GO
PRINT N'Creating [dbo].[usp_DeleteCustomerDataForPDFExport]...';


GO

CREATE PROCEDURE  [dbo].[usp_DeleteCustomerDataForPDFExport]   
AS  
BEGIN 
	Truncate Table TemplatePDF
	Truncate Table TemplateStylePDF
	Truncate Table StylePDF
	Truncate Table ProjectUserTagPDF
	Truncate Table ReferenceStandardPDF
	Truncate Table ReferenceStandardEditionPDF
	Truncate Table ProjectPrintSettingPDF
END
GO
PRINT N'Creating [dbo].[usp_GetCustomerDataForPDFExport]...';


GO

CREATE PROCEDURE  [dbo].[usp_GetCustomerDataForPDFExport] 
   @CustomerId INT=0
AS  
BEGIN  
  
	SELECT [TemplateId],[Name],[TitleFormatId],[SequenceNumbering],[CustomerId],[IsSystem],[IsDeleted],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[MasterDataTypeId],[A_TemplateId],[ApplyTitleStyleToEOS]
	FROM [dbo].[Template]  WITH (NOLOCK)
	WHERE ISNull(CustomerID,0)= @CustomerId

	SELECT [TemplateStyleId],[TemplateId],[StyleId],[Level],[CustomerId],[A_TemplateStyleId]
	FROM [dbo].[TemplateStyle]  WITH (NOLOCK)
	WHERE ISNull(CustomerID,0)= @CustomerId


	SELECT [StyleId],[Alignment],[IsBold],[CharAfterNumber],[CharBeforeNumber],[FontName],[FontSize],[HangingIndent],[IncludePrevious],[IsItalic],[LeftIndent]
		  ,[NumberFormat],[NumberPosition],[PrintUpperCase],[ShowNumber],[StartAt],[Strikeout],[Name],[TopDistance],[Underline],[SpaceBelowParagraph]
		  ,[IsSystem],[CustomerId],[IsDeleted],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[Level],[MasterDataTypeId],[A_StyleId]
	FROM [dbo].[Style]  WITH (NOLOCK)
	WHERE ISNull(CustomerID,0)= @CustomerId

	SELECT [UserTagId],[CustomerId],[TagType],[Description],[SortOrder],[IsSystemTag],[CreateDate],[CreatedBy],[ModifiedDate],[ModifiedBy],[A_UserTagId]
	FROM [dbo].[ProjectUserTag]  WITH (NOLOCK)
	WHERE ISNull(CustomerID,0)= @CustomerId

	SELECT [RefStdId],[RefStdName],[RefStdSource],[ReplaceRefStdId],[ReplaceRefStdSource],[mReplaceRefStdId],[IsObsolete],[RefStdCode],[CreateDate],[CreatedBy],[ModifiedDate]
		  ,[ModifiedBy],[CustomerId],[IsDeleted],[IsLocked],[IsLockedByFullName],[IsLockedById],[A_RefStdId]
	FROM [dbo].[ReferenceStandard]  WITH (NOLOCK)
	WHERE ISNull(CustomerID,0)= @CustomerId


	SELECT [RefStdEditionId],[RefEdition],[RefStdTitle],[LinkTarget],[CreateDate],[CreatedBy],[RefStdId],[CustomerId],[ModifiedDate],[ModifiedBy],[A_RefStdEditionId]
	FROM [dbo].[ReferenceStandardEdition]  WITH (NOLOCK)
	WHERE ISNull(CustomerID,0)= @CustomerId

	IF (IsNull(@CustomerId,0)=0)
	Begin
	Select [ProjectPrintSettingId]
		  ,[ProjectId]
		  ,[CustomerId]
		  ,[CreatedBy]
		  ,[CreateDate]
		  ,[ModifiedBy]
		  ,[ModifiedDate]
		  ,[IsExportInMultipleFiles]
		  ,[IsBeginSectionOnOddPage]
		  ,[IsIncludeAuthorInFileName]
		  ,[TCPrintModeId]
		  ,[IsIncludePageCount]
		  ,[IsIncludeHyperLink]
		  ,[KeepWithNext]
		  ,[IsPrintMasterNote]
		  ,[IsPrintProjectNote]
		  ,[IsPrintNoteImage]
		  ,[IsPrintIHSLogo] 
	From ProjectPrintSetting WITH (NOLOCK)
	Where ProjectId is null and CustomerId is null
	End

END
GO
PRINT N'Creating [dbo].[usp_GetMigratedProjectAccessTypeId]...';


GO
CREATE PROCEDURE usp_GetMigratedProjectAccessTypeId  
@CustomerId INT,  
@IsOfficeMaster BIT = 0  
AS  
BEGIN  
DECLARE @PCustomerId int = @CustomerId;  
      
DECLARE @PIsOfficeMaster bit = @IsOfficeMaster;  
      
DECLARE @ProjectOrigineType int = (SELECT ProjectOriginTypeId FROM LuProjectOriginType WITH (NOLOCK)  
         WHERE [Name] = 'Migrated Project');  
  
DROP TABLE IF EXISTS #TempProjDefaultPrivacySetting;  
  
SELECT  
    CustomerId  
   ,ProjectAccessTypeId  
   ,ProjectOriginTypeId  
   ,IsOfficeMaster INTO #TempProjDefaultPrivacySetting  
FROM ProjectDefaultPrivacySetting WITH (NOLOCK)  
WHERE CustomerId = 0 -- Here CustomerId = 0 used purposefully to get Default Settings  
AND ProjectOriginTypeId = @ProjectOrigineType  
AND IsOfficeMaster = @PIsOfficeMaster;  
  
UPDATE t  
SET t.ProjectAccessTypeId = pdps.ProjectAccessTypeId  
FROM #TempProjDefaultPrivacySetting t  
JOIN ProjectDefaultPrivacySetting pdps WITH (NOLOCK)  
 ON t.IsOfficeMaster = pdps.IsOfficeMaster  
 AND t.ProjectOriginTypeId = pdps.ProjectOriginTypeId  
 AND pdps.CustomerId = @PCustomerId;  
  
SELECT ProjectAccessTypeId FROM #TempProjDefaultPrivacySetting;  
  
END;
GO
PRINT N'Creating [dbo].[usp_GetMigratedProjectDefaultPrivacySetting]...';


GO
CREATE PROCEDURE usp_GetMigratedProjectDefaultPrivacySetting        
@CustomerId int,        
@UserId int,      
@IsOfficeMaster bit,      
@ProjectAccessTypeId int OUTPUT,      
@ProjectOwnerId int OUTPUT      
AS        
BEGIN    
        
DECLARE @PCustomerId int = @CustomerId;    

DECLARE @PIsOfficeMaster bit = @IsOfficeMaster;  
  
SET @ProjectOwnerId = NULL;      
   
DECLARE @ProjectOrigineType int = (SELECT ProjectOriginTypeId FROM LuProjectOriginType WITH (NOLOCK)    
        WHERE [Name] = 'Migrated Project');    
  
DECLARE @ProjectOwnerTypeId INT = NULL;    
SELECT    
 CustomerId    
   ,ProjectAccessTypeId    
   ,ProjectOwnerTypeId    
   ,ProjectOriginTypeId    
   ,IsOfficeMaster INTO #ProjDefaultPrivacySetting    
FROM ProjectDefaultPrivacySetting WITH(NOLOCK)    
WHERE CustomerId = 0    
AND ProjectOriginTypeId = @ProjectOrigineType    
AND IsOfficeMaster = @PIsOfficeMaster;    
    
UPDATE t    
SET t.ProjectAccessTypeId = pdps.ProjectAccessTypeId    
   ,t.ProjectOwnerTypeId = pdps.ProjectOwnerTypeId    
FROM #ProjDefaultPrivacySetting t    
JOIN ProjectDefaultPrivacySetting pdps WITH(NOLOCK)    
 ON t.IsOfficeMaster = pdps.IsOfficeMaster    
 AND t.ProjectOriginTypeId = pdps.ProjectOriginTypeId    
 AND pdps.CustomerId = @PCustomerId;    
    
    
SELECT TOP 1    
 @ProjectAccessTypeId = ProjectAccessTypeId    
   ,@ProjectOwnerTypeId = ProjectOwnerTypeId    
FROM #ProjDefaultPrivacySetting;    
    
IF (@ProjectOwnerTypeId = 3)    
 SET @ProjectOwnerId = @UserId;    
END
GO
PRINT N'Creating [dbo].[usp_GetMigrationProjectsForPDFGeneration]...';


GO
CREATE PROCEDURE [dbo].[usp_GetMigrationProjectsForPDFGeneration] 
          
AS          
BEGIN 

    SELECT ProjectId,CustomerId,P.Name AS ProjectName,ISNULL(AP.ArchiveProjectId,0) AS ArchiveProjectId, slc_prodprojectid
	FROM [dbo].Project P WITH(NOLOCK)
	LEFT OUTER JOIN	[ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] AP WITH(NOLOCK) 
		ON P.ProjectId =AP.slc_prodprojectid and P.CustomerId=AP.SLC_CustomerID
	WHERE IsShowMigrationPopup = 1 AND
	ISNULL(PDFGenerationStatusId,0)=0 AND 
	ISNULL(P.IsDeleted,0)=0 
END
GO
PRINT N'Creating [dbo].[usp_GetProjectCommentCount]...';


GO

CREATE PROCEDURE [dbo].[usp_GetProjectCommentCount]  
(  
 @TenantProjectList NVARCHAR(MAX) NULL = NULL  
)  
AS  
BEGIN  
 DROP TABLE IF EXISTS #ProjectCommentCount;  
 DROP TABLE IF EXISTS #TenantProjectTable;  
  
  SELECT *   
  INTO #TenantProjectTable  
  FROM    
  OPENJSON ( @TenantProjectList )    
  WITH (     
  TenantName VARCHAR(200) '$.TenantName' ,    
  SharedProjectId INT '$.SharedProjectId',    
  SharedToUserId INT '$.SharedToUserId',    
  SharedToCustomerId INT '$.SharedToCustomerId',  
  SharedByCustomerId INT '$.SharedByCustomerId',  
  CommentCount INT '$.CommentCount'    
  )  
  
  DECLARE @OpenCommentStatusId INT = 1;  

  SELECT SC.ProjectId, COUNT(SC.SectionId) AS ProjectCommentCount  
  INTO #ProjectCommentCount 
  FROM #TenantProjectTable TPT  
  LEFT JOIN SegmentComment SC WITH (NOLOCK) ON SC.ProjectId = TPT.SharedProjectId  
  WHERE SC.CommentStatusId=@OpenCommentStatusId AND SC.ParentCommentId= 0 AND ISNULL(SC.IsDeleted, 0) = 0     
  GROUP BY SC.ProjectId
  
  UPDATE TPT
  SET TPT.CommentCount = PCC.ProjectCommentCount
  FROM #TenantProjectTable TPT
  INNER JOIN #ProjectCommentCount PCC ON TPT.SharedProjectId = PCC.ProjectId
  
  SELECT * FROM #TenantProjectTable TPT  

 END
GO
PRINT N'Creating [dbo].[usp_GetProjectDefaultAdminTypes]...';


GO
CREATE PROCEDURE usp_GetProjectDefaultAdminTypes    
as    
begin    
select ProjectOwnerTypeId,[Name],[Description],IsActive, SortOrder 
		from LuProjectOwnerType WITH(NOLOCK) order by SortOrder desc;
end
GO
PRINT N'Creating [dbo].[usp_GetProjectDefaultPrivacySettingByCustomer]...';


GO
CREATE PROCEDURE usp_GetProjectDefaultPrivacySettingByCustomer      
(      
@CustomerId int      
)      
AS      
BEGIN  
      
DECLARE @PCustomerId int = @CustomerId;  
  
DROP TABLE IF EXISTS #projectPrivacySettings;  
  
SELECT  
 CustomerId  
   ,ProjectAccessTypeId  
   ,ProjectOwnerTypeId  
   ,ProjectOriginTypeId  
   ,IsOfficeMaster INTO #projectPrivacySettings  
FROM ProjectDefaultPrivacySetting WITH (NOLOCK)  
WHERE CustomerId = 0;  
  
--select * from #projectPrivacySettings  
UPDATE t  
SET t.ProjectAccessTypeId = pps.ProjectAccessTypeId  
   ,t.ProjectOwnerTypeId = pps.ProjectOwnerTypeId  
FROM #projectPrivacySettings t  
JOIN ProjectDefaultPrivacySetting pps WITH (NOLOCK)  
 ON   
 t.ProjectOriginTypeId = pps.ProjectOriginTypeId  
 AND t.IsOfficeMaster = pps.IsOfficeMaster  
 where pps.CustomerId = @PCustomerId;  
  
select * from #projectPrivacySettings;  
END;
GO
PRINT N'Creating [dbo].[usp_GetProjectSectionCommentCount]...';


GO
CREATE PROCEDURE [dbo].[usp_GetProjectSectionCommentCount]                                       
  @ProjectId INT       
AS                                          
BEGIN

  DECLARE @PProjectId INT = @ProjectId;       
  DECLARE @PCommentStatusId INT = 1; -- (CommentstatusId  1 means OpenComment and 2 means ResolvedComments)      
  DECLARE @ParentCommentId INT = 0;


	SELECT SC.SectionId
	INTO #TempSectionIdTbl
	FROM SegmentComment AS SC WITH(NOLOCK)
	WHERE SC.ProjectId = @PProjectId AND SC.CommentStatusId = @PCommentStatusId
	AND SC.ParentCommentId=@ParentCommentId AND ISNULL(SC.IsDeleted, 0) = 0;

	SELECT SC.SectionId, COUNT(SC.SectionId) AS CommentCount
	FROM #TempSectionIdTbl AS SC WITH(NOLOCK)
	GROUP BY SC.SectionId;
                                                        
END
GO
PRINT N'Creating [dbo].[usp_GetSegmentsForPrintPDF]...';


GO

CREATE PROCEDURE [dbo].[usp_GetSegmentsForPrintPDF] (                  
 @ProjectId INT                  
 ,@CustomerId INT                  
 ,@SectionIdsString NVARCHAR(MAX)                  
 ,@UserId INT                  
 ,@CatalogueType NVARCHAR(MAX)                  
 ,@TCPrintModeId INT = 1                  
 ,@IsActiveOnly BIT = 1                
              
 )                  
AS                  
BEGIN                  
 DECLARE @PProjectId INT = @ProjectId;                  
 DECLARE @PCustomerId INT = @CustomerId;                  
 DECLARE @PSectionIdsString NVARCHAR(MAX) = @SectionIdsString;                  
 DECLARE @PUserId INT = @UserId;                  
 DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;                  
 DECLARE @PTCPrintModeId INT = @TCPrintModeId;                  
 DECLARE @PIsActiveOnly BIT = @IsActiveOnly;                  
 DECLARE @IsFalse BIT = 0;                  
 DECLARE @SProjectId NVARCHAR(20) = convert(NVARCHAR, @ProjectId);                  
 DECLARE @STCPrintModeId NVARCHAR(2) = convert(NVARCHAR, @TCPrintModeId);                  
 DECLARE @SIsActiveOnly NVARCHAR(2) = convert(NVARCHAR, @IsActiveOnly);                  
 DECLARE @SCustomerId NVARCHAR(20) = convert(NVARCHAR, @CustomerId);                  
 DECLARE @SUserId NVARCHAR(20) = convert(NVARCHAR, @UserId);                  
 DECLARE @MasterDataTypeId INT = (                  
   SELECT P.MasterDataTypeId                  
   FROM Project P WITH (NOLOCK)                  
   WHERE P.ProjectId = @PProjectId                  
    AND P.CustomerId = @PCustomerId                  
   );                  
 DECLARE @SectionIdTbl TABLE (SectionId INT);                  
 DECLARE @CatalogueTypeTbl TABLE (TagType NVARCHAR(MAX));                  
 DECLARE @OldKeywordFormat NVARCHAR(MAX) = '{\kw\';                  
 DECLARE @NewKeywordFormat NVARCHAR(MAX) = '{KW#';                  
 DECLARE @Lu_InheritFromSection INT = 1;                  
 DECLARE @Lu_AllWithMarkups INT = 2;                  
 DECLARE @Lu_AllWithoutMarkups INT = 3;                 
 DECLARE @ImagSegment int =1      
 DECLARE @ImageHeaderFooter int =3      
                  
 --CONVERT STRING INTO TABLE                                      
 INSERT INTO @SectionIdTbl (SectionId)                  
 SELECT *                  
 FROM dbo.fn_SplitString(@PSectionIdsString, ',');                  
                  
 --CONVERT CATALOGUE TYPE INTO TABLE                                  
 IF @PCatalogueType IS NOT NULL                  
  AND @PCatalogueType != 'FS'                  
 BEGIN                  
  INSERT INTO @CatalogueTypeTbl (TagType)                  
  SELECT *                  
  FROM dbo.fn_SplitString(@PCatalogueType, ',');                  
                  
  IF EXISTS (                  
    SELECT *                  
    FROM @CatalogueTypeTbl                  
    WHERE TagType = 'OL'                  
    )                  
  BEGIN                  
   INSERT INTO @CatalogueTypeTbl                  
   VALUES ('UO')                  
  END                  
                  
  IF EXISTS (                  
    SELECT TOP 1 1                  
    FROM @CatalogueTypeTbl                  
    WHERE TagType = 'SF'                  
    )                  
  BEGIN                  
   INSERT INTO @CatalogueTypeTbl                  
   VALUES ('US')                  
  END                  
 END                  
                  
 --DROP TEMP TABLES IF PRESENT                                      
 DROP TABLE                  
                  
 IF EXISTS #tmp_ProjectSegmentStatus;                  
  DROP TABLE                  
                  
 IF EXISTS #tmp_Template;                  
  DROP TABLE                  
                  
 IF EXISTS #tmp_SelectedChoiceOption;                  
  DROP TABLE                  
                  
 IF EXISTS #tmp_ProjectSection;                  
  --FETCH SECTIONS DATA IN TEMP TABLE                                  
  SELECT PS.SectionId                  
   ,PS.ParentSectionId                  
   ,PS.mSectionId                  
   ,PS.ProjectId                  
   ,PS.CustomerId                  
   ,PS.UserId                  
   ,PS.DivisionId      
   ,PS.DivisionCode                  
   ,PS.Description                  
   ,PS.LevelId                  
   ,PS.IsLastLevel                  
   ,PS.SourceTag                  
   ,PS.Author                  
   ,PS.TemplateId                  
   ,PS.SectionCode                  
   ,PS.IsDeleted                  
   ,PS.SpecViewModeId                  
   ,PS.IsTrackChanges                  
  INTO #tmp_ProjectSection                  
  FROM ProjectSection PS WITH (NOLOCK)                  
  WHERE PS.ProjectId = @PProjectId                  
   AND PS.CustomerId = @PCustomerId                  
   AND ISNULL(PS.IsDeleted, 0) = 0;                  
                  
 --FETCH SEGMENT STATUS DATA INTO TEMP TABLE                              
 SELECT PSST.SegmentStatusId            
  ,PSST.SectionId                  
  ,PSST.ParentSegmentStatusId                  
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId                  
  ,ISNULL(PSST.mSegmentId, 0) AS mSegmentId                  
  ,ISNULL(PSST.SegmentId, 0) AS SegmentId             
  ,PSST.SegmentSource                  
  ,trim(convert(NCHAR(2), PSST.SegmentOrigin)) AS SegmentOrigin                  
  ,CASE                   
   WHEN PSST.IndentLevel > 8                  
    THEN CAST(8 AS TINYINT)                  
   ELSE PSST.IndentLevel                  
   END AS IndentLevel                  
  ,PSST.SequenceNumber                  
  ,PSST.SegmentStatusTypeId                  
  ,PSST.SegmentStatusCode                  
  ,PSST.IsParentSegmentStatusActive                  
  ,PSST.IsShowAutoNumber                  
  ,PSST.FormattingJson                  
  ,STT.TagType                  
  ,ISNULL(PSST.SpecTypeTagId, 0) AS SpecTypeTagId                  
  ,PSST.IsRefStdParagraph                  
  ,PSST.IsPageBreak                  
  ,ISNULL(PSST.TrackOriginOrder, '') AS TrackOriginOrder                  
  ,PSST.MTrackDescription                  
 INTO #tmp_ProjectSegmentStatus                  
 FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl SIDTBL ON PSST.SectionId = SIDTBL.SectionId                  
 LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK) ON PSST.SpecTypeTagId = STT.SpecTypeTagId                  
 WHERE PSST.ProjectId = @PProjectId                  
  AND PSST.CustomerId = @PCustomerId                  
  AND (                  
   PSST.IsDeleted IS NULL                  
   OR PSST.IsDeleted = 0                  
   )                  
  AND (                  
   @PIsActiveOnly = @IsFalse                  
   OR (                  
    PSST.SegmentStatusTypeId > 0                  
    AND PSST.SegmentStatusTypeId < 6                  
    AND PSST.IsParentSegmentStatusActive = 1                  
    )                  
   OR (PSST.IsPageBreak = 1)                  
   )                  
  AND (                  
   @PCatalogueType = 'FS'                  
   OR STT.TagType IN (                  
    SELECT TagType                  
    FROM @CatalogueTypeTbl                  
    )                  
   )                  
                  
 --SELECT SEGMENT STATUS DATA                                      
 SELECT *                  
 FROM #tmp_ProjectSegmentStatus PSST                  
 ORDER BY PSST.SectionId                  
  ,PSST.SequenceNumber;                  
   
DROP TABLE IF EXISTS #tmpProjectSegmentStatusForNote;     
 --FETCH SegmentStatusId AND MSegmentStatusId DATA INTO TEMP TABLE       
SELECT PSST.SegmentStatusId              
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId                    
 INTO #tmpProjectSegmentStatusForNote                    
 FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)                    
 INNER JOIN @SectionIdTbl SIDTBL ON PSST.SectionId = SIDTBL.SectionId                   
 WHERE PSST.ProjectId = @PProjectId   
 AND PSST.CustomerId = @PCustomerId    
  
 --SELECT SEGMENT DATA                                      
 SELECT PSST.SegmentId                  
  ,PSST.SegmentStatusId                  
  ,PSST.SectionId                  
  ,(                  
   CASE                   
    WHEN @PTCPrintModeId = @Lu_AllWithoutMarkups                  
     THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                  
    WHEN @PTCPrintModeId = @Lu_AllWithMarkups                  
     THEN COALESCE(PSG.SegmentDescription, '')                  
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                  
     AND PS.IsTrackChanges = 1                  
     THEN COALESCE(PSG.SegmentDescription, '')                  
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                  
     AND PS.IsTrackChanges = 0                  
     THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                  
    ELSE COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                  
    END                  
   ) AS SegmentDescription                  
  ,PSG.SegmentSource                  
  ,PSG.SegmentCode                  
 FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                  
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId                  
 INNER JOIN ProjectSegment AS PSG WITH (NOLOCK) ON PSST.SegmentId = PSG.SegmentId                  
 WHERE PSG.ProjectId = @PProjectId                  
  AND PSG.CustomerId = @PCustomerId                  
                   
 UNION                  
                   
 SELECT MSG.SegmentId                  
  ,PSST.SegmentStatusId                  
  ,PSST.SectionId                  
  ,CASE                   
   WHEN PSST.ParentSegmentStatusId = 0                AND PSST.SequenceNumber = 0                  
    THEN PS.Description                  
   ELSE ISNULL(MSG.SegmentDescription, '')                  
   END AS SegmentDescription                  
  ,MSG.SegmentSource                  
  ,MSG.SegmentCode                  
 FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                  
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId                  
 INNER JOIN SLCMaster..Segment AS MSG WITH (NOLOCK) ON PSST.mSegmentId = MSG.SegmentId                  
 WHERE PS.ProjectId = @PProjectId                  
  AND PS.CustomerId = @PCustomerId                  
                  
 --FETCH TEMPLATE DATA INTO TEMP TABLE                                      
 SELECT *                  
 INTO #tmp_Template                  
 FROM (                  
  SELECT T.TemplateId                  
   ,T.Name                  
   ,T.TitleFormatId                  
   ,T.SequenceNumbering                  
   ,T.IsSystem                  
   ,T.IsDeleted                  
   ,0 AS SectionId                 
   ,T.ApplyTitleStyleToEOS              
   ,CAST(1 AS BIT) AS IsDefault                  
  --FROM Template T WITH (NOLOCK)                  
  FROM TemplatePDF T WITH (NOLOCK) 
  INNER JOIN Project P WITH (NOLOCK) ON T.TemplateId = COALESCE(P.TemplateId, 1)                  
  WHERE P.ProjectId = @PProjectId                  
   AND P.CustomerId = @PCustomerId                  
                    
  UNION                  
                    
  SELECT T.TemplateId                  
   ,T.Name                  
   ,T.TitleFormatId                  
   ,T.SequenceNumbering                  
   ,T.IsSystem                
   ,T.IsDeleted                  
   ,PS.SectionId                  
   ,T.ApplyTitleStyleToEOS              
   ,CAST(0 AS BIT) AS IsDefault                  
  --FROM Template T WITH (NOLOCK)       
  FROM TemplatePDF T WITH (NOLOCK) 
  INNER JOIN #tmp_ProjectSection PS WITH (NOLOCK) ON T.TemplateId = PS.TemplateId                  
  INNER JOIN @SectionIdTbl SIDTBL ON PS.SectionId = SIDTBL.SectionId                  
  WHERE PS.ProjectId = @PProjectId                  
   AND PS.CustomerId = @PCustomerId                  
   AND PS.TemplateId IS NOT NULL       
  ) AS X                  
                  
 --SELECT TEMPLATE DATA                                      
 SELECT *                  
 FROM #tmp_Template T                  
                  
 --SELECT TEMPLATE STYLE DATA                                      
 SELECT TS.TemplateStyleId                  
  ,TS.TemplateId                  
  ,TS.StyleId                  
  ,TS.LEVEL                  
 --FROM TemplateStyle TS WITH (NOLOCK)        
 FROM TemplateStylePDF TS WITH (NOLOCK)        
 INNER JOIN #tmp_Template T WITH (NOLOCK) ON TS.TemplateId = T.TemplateId                  
                  
 --SELECT STYLE DATA                                      
 SELECT ST.StyleId                  
  ,ST.Alignment                  
  ,ST.IsBold                  
  ,ST.CharAfterNumber                  
  ,ST.CharBeforeNumber                  
  ,ST.FontName                  
  ,ST.FontSize                  
  ,ST.HangingIndent                  
  ,ST.IncludePrevious                  
  ,ST.IsItalic                  
  ,ST.LeftIndent                  
  ,ST.NumberFormat                  
  ,ST.NumberPosition          
  ,ST.PrintUpperCase                  
  ,ST.ShowNumber                  
  ,ST.StartAt                  
  ,ST.Strikeout                  
  ,ST.Name                  
  ,ST.TopDistance                  
  ,ST.Underline                  
  ,ST.SpaceBelowParagraph                  
  ,ST.IsSystem                  
  ,ST.IsDeleted                  
  ,CAST(TS.LEVEL AS INT) AS LEVEL         
  ,ISNULL(SPS.CustomLineSpacing,0) as CustomLineSpacing    
  ,ISNULL(SPS.DefaultSpacesId,0) as  DefaultSpacesId    
  ,ISNULL(SPS.BeforeSpacesId,0) as   BeforeSpacesId    
  ,ISNULL(SPS.AfterSpacesId,0) as AfterSpacesId           
 --FROM Style AS ST WITH (NOLOCK)                  
 --INNER JOIN TemplateStyle AS TS WITH (NOLOCK) ON ST.StyleId = TS.StyleId   
 FROM StylePDF AS ST WITH (NOLOCK)                  
 INNER JOIN TemplateStylePDF AS TS WITH (NOLOCK) ON ST.StyleId = TS.StyleId   
 INNER JOIN #tmp_Template T WITH (NOLOCK) ON TS.TemplateId = T.TemplateId      
  LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK) ON SPS.StyleId=ST.StyleId              
                  
 -- insert missing sco entries                      
 INSERT INTO SelectedChoiceOption                  
 SELECT psc.SegmentChoiceCode                  
  ,pco.ChoiceOptionCode                  
  ,pco.ChoiceOptionSource                  
  ,slcmsco.IsSelected                  
  ,psc.SectionId                  
  ,psc.ProjectId                  
  ,pco.CustomerId                  
  ,NULL AS OptionJson                  
  ,0 AS IsDeleted                  
 FROM ProjectSegmentChoice psc WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl stb ON psc.SectionId = stb.SectionId                  
 INNER JOIN ProjectChoiceOption pco WITH (NOLOCK) ON pco.SegmentChoiceId = psc.SegmentChoiceId                  
  AND pco.SectionId = psc.SectionId                  
  AND pco.ProjectId = psc.ProjectId                  
  AND pco.CustomerId = psc.CustomerId                  
 LEFT OUTER JOIN SelectedChoiceOption sco WITH (NOLOCK) ON pco.ChoiceOptionCode = sco.ChoiceOptionCode                  
  AND pco.SectionId = sco.SectionId                  
  AND pco.ProjectId = sco.ProjectId                  
  AND pco.CustomerId = sco.CustomerId                  
  AND sco.ChoiceOptionSource = pco.ChoiceOptionSource                  
 INNER JOIN SLCMaster.dbo.SelectedChoiceOption slcmsco WITH (NOLOCK) ON slcmsco.ChoiceOptionCode = pco.ChoiceOptionCode                  
 WHERE sco.SelectedChoiceOptionId IS NULL                  
  AND pco.CustomerId = @PCustomerId                  
  AND pco.ProjectId = @PProjectId                  
  AND ISNULL(pco.IsDeleted, 0) = 0                  
  AND ISNULL(psc.IsDeleted, 0) = 0                  
 
              
 -- Mark isdeleted =0 for SelectedChoiceOption                    
 UPDATE sco                  
 SET sco.isdeleted = 0                  
 FROM ProjectSegmentChoice psc WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl stb ON psc.SectionId = stb.SectionId                  
 INNER JOIN ProjectChoiceOption pco WITH (NOLOCK) ON pco.SegmentChoiceId = psc.SegmentChoiceId                  
  AND pco.SectionId = psc.SectionId                  
  AND pco.ProjectId = psc.ProjectId     
  AND pco.CustomerId = psc.CustomerId                  
 LEFT OUTER JOIN SelectedChoiceOption sco WITH (NOLOCK) ON pco.ChoiceOptionCode = sco.ChoiceOptionCode                  
  AND pco.SectionId = sco.SectionId                  
  AND pco.ProjectId = sco.ProjectId                  
  AND pco.CustomerId = sco.CustomerId                  
  AND sco.ChoiceOptionSource = pco.ChoiceOptionSource                  
 WHERE ISNULL(sco.IsDeleted, 0) = 1                  
  AND pco.CustomerId = @PCustomerId                  
  AND pco.ProjectId = @PProjectId                  
  AND ISNULL(pco.IsDeleted, 0) = 0                  
  AND ISNULL(psc.IsDeleted, 0) = 0                  
  AND psc.SegmentChoiceSource = 'U'                  
                  
  
 --FETCH SelectedChoiceOption INTO TEMP TABLE                                      
 SELECT DISTINCT SCHOP.SegmentChoiceCode                  
  ,SCHOP.ChoiceOptionCode                  
  ,SCHOP.ChoiceOptionSource              ,SCHOP.IsSelected                  
  ,SCHOP.ProjectId                  
  ,SCHOP.SectionId                  
  ,SCHOP.CustomerId                  
  ,0 AS SelectedChoiceOptionId                  
  ,SCHOP.OptionJson                  
 INTO #tmp_SelectedChoiceOption                  
 FROM SelectedChoiceOption SCHOP WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl SIDTBL ON SCHOP.SectionId = SIDTBL.SectionId                  
 WHERE SCHOP.ProjectId = @PProjectId                  
  AND SCHOP.CustomerId = @PCustomerId                  
  AND IsNULL(SCHOP.IsDeleted, 0) = 0                  
                  
 --FETCH MASTER + USER CHOICES AND THEIR OPTIONS                                        
 SELECT 0 AS SegmentId                  
  ,MCH.SegmentId AS mSegmentId                  
  ,MCH.ChoiceTypeId                  
  ,'M' AS ChoiceSource                  
  ,ISNULL(MCH.SegmentChoiceCode, 0) AS SegmentChoiceCode                
  ,ISNULL(MCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode                  
  ,PSCHOP.IsSelected                  
  ,PSCHOP.ChoiceOptionSource                  
  ,CASE                   
   WHEN PSCHOP.IsSelected = 1                  
    AND PSCHOP.OptionJson IS NOT NULL                  
    THEN PSCHOP.OptionJson                  
   ELSE MCHOP.OptionJson                  
   END AS OptionJson                  
  ,MCHOP.SortOrder                  
  ,MCH.SegmentChoiceId                  
  ,MCHOP.ChoiceOptionId            
  ,PSCHOP.SelectedChoiceOptionId                  
  ,PSST.SectionId                  
 FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)                  
 INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK) ON PSST.mSegmentId = MCH.SegmentId                  
 INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK) ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId                  
 INNER JOIN #tmp_SelectedChoiceOption PSCHOP WITH (NOLOCK) ON MCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode                  
  AND MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode                  
  AND PSCHOP.ChoiceOptionSource = 'M'                  
                   
 UNION                  
                   
 SELECT PCH.SegmentId                  
  ,0 AS mSegmentId                  
  ,PCH.ChoiceTypeId                  
  ,PCH.SegmentChoiceSource AS ChoiceSource                  
  ,ISNULL(PCH.SegmentChoiceCode, 0) AS SegmentChoiceCode                  
  ,ISNULL(PCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode                  
  ,PSCHOP.IsSelected                  
  ,PSCHOP.ChoiceOptionSource                  
  ,PCHOP.OptionJson                  
  ,PCHOP.SortOrder                  
  ,PCH.SegmentChoiceId                  
  ,PCHOP.ChoiceOptionId                    
  ,PSCHOP.SelectedChoiceOptionId                  
  ,PSST.SectionId                  
 FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)                  
 INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK) ON PSST.SegmentId = PCH.SegmentId                  
  AND ISNULL(PCH.IsDeleted, 0) = 0                  
 INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK) ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId                  
  AND ISNULL(PCHOP.IsDeleted, 0) = 0                  
 INNER JOIN #tmp_SelectedChoiceOption PSCHOP WITH (NOLOCK) ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode                  
  AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode                  
AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource                  
  AND PSCHOP.ChoiceOptionSource = 'U'                  
 WHERE PCH.ProjectId = @PProjectId                  
  AND PCH.CustomerId = @PCustomerId                  
  AND PCHOP.ProjectId = @PProjectId                  
  AND PCHOP.CustomerId = @PCustomerId                  
  AND ISNULL(PCH.IsDeleted, 0) = 0                  
  AND ISNULL(PCHOP.IsDeleted, 0) = 0                  
                  
 --SELECT GLOBAL TERM DATA                                      
 SELECT PGT.GlobalTermId                  
  ,COALESCE(PGT.mGlobalTermId, 0) AS mGlobalTermId                  
  ,PGT.Name                  
  ,ISNULL(PGT.value, '') AS value                  
  ,PGT.CreatedDate                  
  ,PGT.CreatedBy                  
  ,PGT.ModifiedDate                  
  ,PGT.ModifiedBy                  
  ,PGT.GlobalTermSource                  
  ,PGT.GlobalTermCode                  
  ,COALESCE(PGT.UserGlobalTermId, 0) AS UserGlobalTermId                  
  ,GlobalTermFieldTypeId                  
 FROM ProjectGlobalTerm PGT WITH (NOLOCK)                  
 WHERE PGT.ProjectId = @PProjectId                  
  AND PGT.CustomerId = @PCustomerId;                  
                  
 --SELECT SECTIONS DATA                                      
 SELECT S.SectionId AS SectionId                  
  ,ISNULL(S.mSectionId, 0) AS mSectionId                  
  ,S.Description                  
  ,S.Author                  
  ,S.SectionCode                  
  ,S.SourceTag                  
  ,PS.SourceTagFormat                  
  ,ISNULL(D.DivisionCode, '') AS DivisionCode                  
  ,ISNULL(D.DivisionTitle, '') AS DivisionTitle                  
  ,ISNULL(D.DivisionId, 0) AS DivisionId                  
  ,S.IsTrackChanges                  
 FROM #tmp_ProjectSection AS S WITH (NOLOCK)                  
 LEFT JOIN SLCMaster..Division D WITH (NOLOCK) ON S.DivisionId = D.DivisionId                  
 INNER JOIN ProjectSummary PS WITH (NOLOCK) ON S.ProjectId = PS.ProjectId                  
  AND S.CustomerId = PS.CustomerId                  
 WHERE S.ProjectId = @PProjectId                  
  AND S.CustomerId = @PCustomerId                  
  AND S.IsLastLevel = 1                  
AND ISNULL(S.IsDeleted, 0) = 0                  
                   
 UNION                  
                   
 SELECT 0 AS SectionId                  
  ,MS.SectionId AS mSectionId                  
  ,MS.Description                  
  ,MS.Author                  
  ,MS.SectionCode                  
  ,MS.SourceTag                  
  ,P.SourceTagFormat                  
  ,ISNULL(D.DivisionCode, '') AS DivisionCode                  
  ,ISNULL(D.DivisionTitle, '') AS DivisionTitle                  
  ,ISNULL(D.DivisionId, 0) AS DivisionId                  
  ,CONVERT(BIT, 0) AS IsTrackChanges                  
 FROM SLCMaster..Section MS WITH (NOLOCK)                  
 LEFT JOIN SLCMaster..Division D WITH (NOLOCK) ON MS.DivisionId = D.DivisionId                  
 INNER JOIN ProjectSummary P WITH (NOLOCK) ON P.ProjectId = @PProjectId                  
  AND P.CustomerId = @PCustomerId                  
 LEFT JOIN #tmp_ProjectSection PS WITH (NOLOCK) ON MS.SectionId = PS.mSectionId                  
  AND PS.ProjectId = @PProjectId                  
  AND PS.CustomerId = @PCustomerId                  
 WHERE MS.MasterDataTypeId = @MasterDataTypeId                  
  AND MS.IsLastLevel = 1                  
  AND PS.SectionId IS NULL                  
  AND ISNULL(PS.IsDeleted, 0) = 0                  
                  
 --SELECT SEGMENT REQUIREMENT TAGS DATA                                      
 SELECT PSRT.SegmentStatusId                  
  ,PSRT.SegmentRequirementTagId                  
  ,PSST.mSegmentStatusId                  
  ,LPRT.RequirementTagId                  
  ,LPRT.TagType                  
  ,LPRT.Description AS TagName                  
  ,CASE                   
   WHEN PSRT.mSegmentRequirementTagId IS NULL                  
    THEN CAST(0 AS BIT)                  
   ELSE CAST(1 AS BIT)                  
   END AS IsMasterRequirementTag                  
  ,PSST.SectionId                  
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)                  
 INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK) ON PSRT.RequirementTagId = LPRT.RequirementTagId                  
INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK) ON PSRT.SegmentStatusId = PSST.SegmentStatusId                  
 WHERE PSRT.ProjectId = @PProjectId                  
  AND PSRT.CustomerId = @PCustomerId                  
                       
 --SELECT REQUIRED IMAGES DATA                                      
 SELECT             
  PIMG.SegmentImageId            
 ,IMG.ImageId            
 ,IMG.ImagePath            
 ,PIMG.ImageStyle            
 ,PIMG.SectionId             
 ,IMG.LuImageSourceTypeId     
          
 FROM ProjectSegmentImage PIMG WITH (NOLOCK)                  
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PIMG.ImageId = IMG.ImageId                  
 --INNER JOIN @SectionIdTbl SIDTBL ON PIMG.SectionId = SIDTBL.SectionId    //To resolved cross section images in headerFooter               
 WHERE PIMG.ProjectId = @PProjectId                  
  AND PIMG.CustomerId = @PCustomerId                  
  AND IMG.LuImageSourceTypeId IN(@ImagSegment,@ImageHeaderFooter)    
UNION ALL -- This union to ge Note images    
 SELECT             
  0 SegmentImageId            
 ,PN.ImageId            
 ,IMG.ImagePath            
 ,NULL ImageStyle            
 ,PN.SectionId             
 ,IMG.LuImageSourceTypeId     
 FROM ProjectNoteImage PN  WITH (NOLOCK)         
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PN.ImageId = IMG.ImageId    
 INNER JOIN @SectionIdTbl SIDTBL ON PN.SectionId = SIDTBL.SectionId    
 WHERE PN.ProjectId = @PProjectId                  
  AND PN.CustomerId = @PCustomerId   
 UNION ALL -- This union to ge Master Note images   
 select   
  0 SegmentImageId            
 ,NI.ImageId            
 ,MIMG.ImagePath            
 ,NULL ImageStyle            
 ,NI.SectionId             
 ,MIMG.LuImageSourceTypeId    
from slcmaster..NoteImage NI with (nolock)  
INNER JOIN ProjectSection PS with (nolock) on NI.SectionId = PS.mSectionId  
INNER JOIN @SectionIdTbl SIDTBL ON PS.SectionId = SIDTBL.SectionId  
INNER JOIN SLCMaster..Image MIMG WITH (NOLOCK) ON MIMG.ImageId = NI.ImageId                  
                  
 --SELECT HYPERLINKS DATA                                      
 SELECT HLNK.HyperLinkId                  
  ,HLNK.LinkTarget                  
  ,HLNK.LinkText                  
  ,'U' AS Source                  
  ,HLNK.SectionId                  
 FROM ProjectHyperLink HLNK WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl SIDTBL ON HLNK.SectionId = SIDTBL.SectionId                  
 WHERE HLNK.ProjectId = @PProjectId                  
  AND HLNK.CustomerId = @PCustomerId                  
  UNION ALL -- To get Master Hyperlinks  
  SELECT MLNK.HyperLinkId                  
  ,MLNK.LinkTarget                  
  ,MLNK.LinkText                  
  ,'M' AS Source                  
  ,MLNK.SectionId                  
 FROM slcmaster..Hyperlink MLNK WITH (NOLOCK)   
 INNER JOIN #tmpProjectSegmentStatusForNote PSS WITH (NOLOCK) ON  MLNK.SegmentStatusId = PSS.mSegmentStatusId  
                
 --SELECT SEGMENT USER TAGS DATA                                      
 SELECT PSUT.SegmentUserTagId                  
  ,PSUT.SegmentStatusId                  
  ,PSUT.UserTagId                  
  ,PUT.TagType                  
  ,PUT.Description AS TagName                  
  ,PSUT.SectionId                  
 FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)                  
 --INNER JOIN ProjectUserTag PUT WITH (NOLOCK) ON PSUT.UserTagId = PUT.UserTagId            
 INNER JOIN ProjectUserTagPDF PUT WITH (NOLOCK) ON PSUT.UserTagId = PUT.UserTagId            
 INNER JOIN #tmp_ProjectSegmentStatus PSST WITH (NOLOCK) ON PSUT.SegmentStatusId = PSST.SegmentStatusId                  
 WHERE PSUT.ProjectId = @PProjectId                  
  AND PSUT.CustomerId = @PCustomerId           
    
 --SELECT Project Summary information                                      
 SELECT P.ProjectId AS ProjectId                  
  ,P.Name AS ProjectName                  
  ,'' AS ProjectLocation                  
  ,PS.IsPrintReferenceEditionDate AS IsPrintReferenceEditionDate                  
  ,PS.SourceTagFormat AS SourceTagFormat                  
  ,COALESCE(CASE                   
    WHEN len(LState.StateProvinceAbbreviation) > 0                  
     THEN LState.StateProvinceAbbreviation              ELSE PA.StateProvinceName                  
    END + ', ' + CASE                   
    WHEN len(LCity.City) > 0                  
     THEN LCity.City                  
    ELSE PA.CityName                  
    END, '') AS DbInfoProjectLocationKeyword                  
  ,ISNULL(PGT.value, '') AS ProjectLocationKeyword                  
  ,PS.UnitOfMeasureValueTypeId                  
 FROM Project P WITH (NOLOCK)                  
 INNER JOIN ProjectSummary PS WITH (NOLOCK) ON P.ProjectId = PS.ProjectId                  
 INNER JOIN ProjectAddress PA WITH (NOLOCK) ON P.ProjectId = PA.ProjectId                  
 INNER JOIN LuCountry LCountry WITH (NOLOCK) ON PA.CountryId = LCountry.CountryId                  
 LEFT JOIN LuStateProvince LState WITH (NOLOCK) ON PA.StateProvinceId = LState.StateProvinceID                  
 LEFT JOIN LuCity LCity WITH (NOLOCK) ON (                  
PA.CityId = LCity.CityId                  
   OR PA.CityName = LCity.City                  
   )                  
  AND LCity.StateProvinceId = PA.StateProvinceId                  
 LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK) ON P.ProjectId = PGT.ProjectId                  
  AND PGT.mGlobalTermId = 11                  
 WHERE P.ProjectId = @PProjectId                  
  AND P.CustomerId = @PCustomerId                  
                  
 --SELECT REFERENCE STD DATA                                   
 SELECT MREFSTD.RefStdId              
  ,COALESCE(MREFSTD.RefStdName, '') AS RefStdName                  
  ,'M' AS RefStdSource                  
  ,COALESCE(MREFSTD.ReplaceRefStdId, 0) AS ReplaceRefStdId                  
  ,'M' AS ReplaceRefStdSource                  
  ,MREFSTD.IsObsolete                  
  ,COALESCE(MREFSTD.RefStdCode, 0) AS RefStdCode                  
 FROM SLCMaster..ReferenceStandard MREFSTD WITH (NOLOCK)                  
 WHERE MREFSTD.MasterDataTypeId = CASE                   
   WHEN @MasterDataTypeId = 2                  
    OR @MasterDataTypeId = 3                  
    THEN 1                  
   ELSE @MasterDataTypeId                  
   END                  
                   
 UNION                  
                   
 SELECT PREFSTD.RefStdId                  
  ,PREFSTD.RefStdName                  
  ,'U' AS RefStdSource                  
  ,COALESCE(PREFSTD.ReplaceRefStdId, 0) AS ReplaceRefStdId                  
  ,COALESCE(PREFSTD.ReplaceRefStdSource, '') AS ReplaceRefStdSource                  
  ,PREFSTD.IsObsolete                  
  ,COALESCE(PREFSTD.RefStdCode, 0) AS RefStdCode                  
 --FROM ReferenceStandard PREFSTD WITH (NOLOCK)    
 FROM ReferenceStandardPDF PREFSTD WITH (NOLOCK)    
 WHERE PREFSTD.CustomerId = @PCustomerId                  
 
 --SELECT REFERENCE EDITION DATA New Implementation for performance improvement.  
  
 DECLARE @MRSEdition TABLE(RefStdId INT,RefStdEditionId INT,RefEdition VARCHAR(150) , RefStdTitle VARCHAR(500), LinkTarget VARCHAR(500),RefEdnSource CHAR(1))  
 DECLARE @PRSEdition TABLE(RefStdId INT,RefStdEditionId INT,RefEdition VARCHAR(150) , RefStdTitle VARCHAR(500), LinkTarget VARCHAR(500),RefEdnSource CHAR(1))  
   
 INSERT into @MRSEdition  
 SELECT MREFEDN.RefStdId                  
  ,MREFEDN.RefStdEditionId                  
  ,MREFEDN.RefEdition                  
  ,MREFEDN.RefStdTitle                  
  ,MREFEDN.LinkTarget                  
  ,'M' AS RefEdnSource                  
 FROM SLCMaster..ReferenceStandardEdition MREFEDN WITH (NOLOCK)                  
 WHERE MREFEDN.MasterDataTypeId = CASE                   
   WHEN @MasterDataTypeId = 2                  
    OR @MasterDataTypeId = 3                  
    THEN 1                  
   ELSE @MasterDataTypeId                  
   END   
  
 INSERT into @PRSEdition    
 SELECT PREFEDN.RefStdId                  
  ,PREFEDN.RefStdEditionId                  
  ,PREFEDN.RefEdition                  
  ,PREFEDN.RefStdTitle                  
  ,PREFEDN.LinkTarget                  
  ,'U' AS RefEdnSource                  
 --FROM ReferenceStandardEdition PREFEDN WITH (NOLOCK)   
 FROM ReferenceStandardEditionPDF PREFEDN WITH (NOLOCK)   
 WHERE PREFEDN.CustomerId = @PCustomerId        
   
 select * from @MRSEdition  
 union   
 select * from @PRSEdition  

                  
 --SELECT ProjectReferenceStandard MAPPING DATA                                      
 SELECT PREFSTD.RefStandardId                  
  ,PREFSTD.RefStdSource                  
  ,COALESCE(PREFSTD.mReplaceRefStdId, 0) AS mReplaceRefStdId                  
  ,PREFSTD.RefStdEditionId                  
  ,SIDTBL.SectionId                  
 FROM ProjectReferenceStandard PREFSTD WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl SIDTBL ON PREFSTD.SectionId = SIDTBL.SectionId                  
 WHERE PREFSTD.ProjectId = @PProjectId                  
  AND PREFSTD.CustomerId = @PCustomerId                  
                  
 --SELECT Header/Footer information                                      
 SELECT X.HeaderId                  
  ,ISNULL(X.ProjectId, @PProjectId) AS ProjectId                  
  ,ISNULL(X.SectionId, 0) AS SectionId                  
  ,ISNULL(X.CustomerId, @PCustomerId) AS CustomerId                  
  ,ISNULL(X.TypeId, 1) AS TypeId                  
  ,X.DATEFORMAT                  
  ,X.TimeFormat                  
  ,ISNULL(X.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                  
  ,REPLACE(ISNULL(X.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader                  
  ,REPLACE(ISNULL(X.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader                  
  ,REPLACE(ISNULL(X.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader                  
  ,REPLACE(ISNULL(X.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader                  
  ,X.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId     
  ,X.IsShowLineAboveHeader as  IsShowLineAboveHeader    
  ,X.IsShowLineBelowHeader as  IsShowLineBelowHeader             
 FROM (                  
  SELECT H.*                  
  FROM Header H WITH (NOLOCK)                  
  INNER JOIN @SectionIdTbl S ON H.SectionId = S.SectionId                  
  WHERE H.ProjectId = @PProjectId                  
   AND H.DocumentTypeId = 1                  
   AND (                  
    ISNULL(H.HeaderFooterCategoryId, 1) = 1                  
    OR H.HeaderFooterCategoryId = 4                  
    )                  
                    
  UNION                  
                    
  SELECT H.*                  
  FROM Header H WITH (NOLOCK)                  
  WHERE H.ProjectId = @PProjectId                  
   AND H.DocumentTypeId = 1                  
   AND (ISNULL(H.HeaderFooterCategoryId, 1) = 1)                  
   AND (                  
    H.SectionId IS NULL                  
    OR H.SectionId <= 0                  
    )                  
                    
  UNION                  
                    
  SELECT H.*                  
  FROM Header H WITH (NOLOCK)                  
  LEFT JOIN Header TEMP                  
  WITH (NOLOCK) ON TEMP.ProjectId = @PProjectId                  
  WHERE H.CustomerId IS NULL                  
   AND TEMP.HeaderId IS NULL                  
   AND H.DocumentTypeId = 1                  
  ) AS X                  
                  
 SELECT X.FooterId                  
  ,ISNULL(X.ProjectId, @PProjectId) AS ProjectId                  
  ,ISNULL(X.SectionId, 0) AS SectionId                  
  ,ISNULL(X.CustomerId, @PCustomerId) AS CustomerId                  
  ,ISNULL(X.TypeId, 1) AS TypeId                  
  ,X.DATEFORMAT                  
  ,X.TimeFormat                  
  ,ISNULL(X.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                  
  ,REPLACE(ISNULL(X.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter                  
  ,REPLACE(ISNULL(X.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter                  
  ,REPLACE(ISNULL(X.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter                  
  ,REPLACE(ISNULL(X.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter                  
  ,X.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId      
  ,X.IsShowLineAboveFooter as  IsShowLineAboveFooter    
  ,X.IsShowLineBelowFooter as  IsShowLineBelowFooter                  
 FROM (            
  SELECT F.*                  
  FROM Footer F WITH (NOLOCK)                  
  INNER JOIN @SectionIdTbl S ON F.SectionId = S.SectionId                  
  WHERE F.ProjectId = @PProjectId                  
   AND F.DocumentTypeId = 1                  
   AND (                  
    ISNULL(F.HeaderFooterCategoryId, 1) = 1                  
    OR F.HeaderFooterCategoryId = 4                  
    )                  
                    
  UNION                  
                    
  SELECT F.*                  
  FROM Footer F WITH (NOLOCK)                  
  WHERE F.ProjectId = @PProjectId                  
   AND F.DocumentTypeId = 1                  
   AND (ISNULL(F.HeaderFooterCategoryId, 1) = 1)                  
   AND (                  
    F.SectionId IS NULL                  
    OR F.SectionId <= 0                  
    )                  
                    
  UNION                  
                    
  SELECT F.*                  
  FROM Footer F WITH (NOLOCK)           
  LEFT JOIN Footer TEMP                  
  WITH (NOLOCK) ON TEMP.ProjectId = @PProjectId                  
  WHERE F.CustomerId IS NULL                  
   AND F.DocumentTypeId = 1                  
   AND TEMP.FooterId IS NULL                  
  ) AS X                  
                  
 --SELECT PageSetup INFORMATION                                      
 SELECT PageSetting.ProjectPageSettingId AS ProjectPageSettingId                  
  ,PaperSetting.ProjectPaperSettingId AS ProjectPaperSettingId                  
  ,ISNULL(PageSetting.MarginTop, 1.00) AS MarginTop                  
  ,ISNULL(PageSetting.MarginBottom, 1.00) AS MarginBottom                  
  ,ISNULL(PageSetting.MarginLeft, 1.00) AS MarginLeft                  
  ,ISNULL(PageSetting.MarginRight, 1.00) AS MarginRight                  
  ,ISNULL(PageSetting.EdgeHeader, 0.05) AS EdgeHeader                  
  ,ISNULL(PageSetting.EdgeFooter, 0.05) AS EdgeFooter                  
  ,PageSetting.IsMirrorMargin AS IsMirrorMargin                  
  ,PageSetting.ProjectId AS ProjectId                  
  ,PageSetting.CustomerId AS CustomerId                  
  ,PaperSetting.PaperName AS PaperName                  
  ,ISNULL(PaperSetting.PaperWidth, 0.00) AS PaperWidth                  
  ,ISNULL(PaperSetting.PaperHeight, 0.00) AS PaperHeight                  
  ,PaperSetting.PaperOrientation AS PaperOrientation                  
  ,PaperSetting.PaperSource AS PaperSource                  
 FROM ProjectPageSetting PageSetting WITH (NOLOCK)                  
 INNER JOIN ProjectPaperSetting PaperSetting WITH (NOLOCK) ON PageSetting.ProjectId = PaperSetting.ProjectId                
 WHERE PageSetting.ProjectId = @PProjectId                  
    
/*Start - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/    
SELECT   
NoteId  
,PN.SectionId    
,PSS.SegmentStatusId SegmentStatusId    
,PSS.mSegmentStatusId mSegmentStatusId    
,CASE WHEN Title != '' THEN CONCAT(Title,'<br/>', NoteText)   
 ELSE NoteText END NoteText    
,PN.ProjectId  
,PN.CustomerId  
,PN.IsDeleted  
,NoteCode  
,PN.Title
FROM ProjectNote PN WITH (NOLOCK)   
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK) ON PN.SegmentStatusId = PSS.SegmentStatusId     
WHERE PN.ProjectId=@PProjectId and PN.CustomerId=@PCustomerId AND ISNULL(PN.IsDeleted, 0) = 0    
UNION ALL    
SELECT NoteId    
,0 SectionId    
,PSS.SegmentStatusId SegmentStatusId    
,PSS.mSegmentStatusId mSegmentStatusId    
,NoteText    
,@PProjectId ProjectId     
,@PCustomerId CustomerId     
,0 IsDeleted    
,0 NoteCode
,'' As Title
 FROM SLCMaster..Note MN  WITH (NOLOCK)  
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK)  
ON MN.SegmentStatusId = PSS.mSegmentStatusId   
/*End - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/    
END
GO
PRINT N'Creating [dbo].[usp_GetSpecDataSectionListPDF]...';


GO

CREATE PROCEDURE [dbo].[usp_GetSpecDataSectionListPDF]     
(                
 @ProjectId INT        
)                
AS                
BEGIN
                
            
DECLARE @PProjectId INT = @ProjectId;

DROP TABLE IF EXISTS #ProjectInfoTbl;
DROP TABLE IF EXISTS #ActiveSectionsTbl;
DROP TABLE IF EXISTS #DistinctDivisionTbl;
DROP TABLE IF EXISTS #ActiveSectionsIdsTbl;

SELECT
	P.ProjectId
   ,p.CustomerId
   ,p.UserId
   ,P.[Name] AS ProjectName
   ,P.MasterDataTypeId
   ,PS.SourceTagFormat
   ,PS.SpecViewModeId
   ,PS.UnitOfMeasureValueTypeId
   ,P.CreatedBy
   ,P.CreateDate INTO #ProjectInfoTbl
FROM Project P WITH (NOLOCK)
INNER JOIN ProjectSummary PS WITH (NOLOCK)
	ON PS.ProjectId = P.ProjectId
WHERE P.ProjectId = @PProjectId

SELECT
	PIT.ProjectId
   ,PIT.CustomerId
   ,P.CreatedBy AS CreatedBy
   ,IsNull(P.ModifiedByFullName,'') AS CreatedByFullName
   ,P.CreateDate AS LocalDate
   ,P.[Name] AS ProjectName
   ,PIT.MasterDataTypeId
   ,P.[Description] AS FileName
   ,'' AS FilePath
   ,'In Progress' AS FileStatus
   ,'' AS LocalTime
FROM #ProjectInfoTbl PIT
INNER JOIN Project P WITH (NOLOCK)
	ON P.ProjectId = @PProjectId

SELECT
	SectionId INTO #ActiveSectionsIdsTbl
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
WHERE PSST.ProjectId = @PProjectId
AND PSST.SequenceNumber = 0
AND PSST.IndentLevel = 0
AND PSST.SegmentStatusTypeId < 6
AND ISNULL(PSST.IsDeleted, 0) = 0

SELECT
	PS.ProjectId
   ,PS.CustomerId
   ,PS.SectionId
   ,PS.UserId
   ,PS.SourceTag
   ,PS.[Description] AS SectionName
   ,PS.DivisionId
   ,PS.Author INTO #ActiveSectionsTbl
FROM #ActiveSectionsIdsTbl AST WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
	ON PS.SectionId = AST.SectionId


SELECT
	AST.ProjectId
   ,AST.CustomerId
   ,AST.SectionId
   ,AST.UserId
   ,AST.SourceTag
   ,AST.SectionName
   ,AST.DivisionId
   ,AST.Author
   ,PIT.ProjectName
   ,PIT.MasterDataTypeId
   ,PIT.SourceTagFormat
   ,PIT.SpecViewModeId
   ,PIT.UnitOfMeasureValueTypeId
FROM #ActiveSectionsTbl AST
INNER JOIN #ProjectInfoTbl PIT
	ON PIT.ProjectId = AST.ProjectId
ORDER BY AST.SourceTag

IF NOT EXISTS (SELECT TOP 1
			1
		FROM ProjectPrintSetting WITH (NOLOCK)
		WHERE ProjectId = @PProjectId)
BEGIN
SELECT
	@PProjectId AS ProjectId
   ,IsExportInMultipleFiles
   ,IsBeginSectionOnOddPage
   ,IsIncludeAuthorInFileName
   ,TCPrintModeId
   ,IsIncludePageCount
   ,IsIncludeHyperLink
   ,KeepWithNext
   ,IsPrintMasterNote  
   ,IsPrintProjectNote  
   ,IsPrintNoteImage  
   ,IsPrintIHSLogo   
FROM ProjectPrintSettingPDF WITH (NOLOCK)
WHERE CustomerId IS NULL
AND ProjectId IS NULL
AND CreatedBy IS NULL
END
ELSE
BEGIN
SELECT
	@PProjectId AS ProjectId
   ,CustomerId AS CustomerId
   ,CreatedBy AS CreatedBy
   ,IsExportInMultipleFiles
   ,IsBeginSectionOnOddPage
   ,IsIncludeAuthorInFileName
   ,TCPrintModeId
   ,IsIncludePageCount
   ,IsIncludeHyperLink
   ,KeepWithNext
   ,IsNull(IsPrintMasterNote,0) as IsPrintMasterNote  
   ,IsNull(IsPrintProjectNote,0) as IsPrintProjectNote  
   ,IsNull(IsPrintNoteImage,0) as IsPrintNoteImage  
   ,IsNull(IsPrintIHSLogo,0) as IsPrintIHSLogo   
FROM ProjectPrintSetting WITH (NOLOCK)
WHERE ProjectId = @PProjectId

END

END
GO
PRINT N'Creating [dbo].[usp_GetTransferredProjectDefaultPrivacySetting]...';


GO
CREATE procedure usp_GetTransferredProjectDefaultPrivacySetting  
@CustomerId int,  
@IsOfficeMaster bit  
AS  
BEGIN  
DECLARE @PCustomerId int = @CustomerId;  
DECLARE @PIsOfficeMaster bit = @IsOfficeMaster;  
DECLARE @ProjectOrigineType int = 3; -- Transferred Project  
  
SELECT  
 CustomerId  
   ,ProjectAccessTypeId  
   ,ProjectOwnerTypeId  
   ,ProjectOriginTypeId  
   ,IsOfficeMaster INTO #ProjDefaultPrivacySetting  
FROM ProjectDefaultPrivacySetting WITH(NOLOCK)
WHERE CustomerId = 0  
AND ProjectOriginTypeId = @ProjectOrigineType  
AND IsOfficeMaster = @PIsOfficeMaster;  
  
UPDATE t  
SET t.ProjectAccessTypeId = pdps.ProjectAccessTypeId  
   ,t.ProjectOwnerTypeId = pdps.ProjectOwnerTypeId  
FROM #ProjDefaultPrivacySetting t  
JOIN ProjectDefaultPrivacySetting pdps WITH(NOLOCK)
 ON t.IsOfficeMaster = pdps.IsOfficeMaster  
 AND t.ProjectOriginTypeId = pdps.ProjectOriginTypeId  
 AND pdps.CustomerId = @PCustomerId;  
  
SELECT  
 ProjectAccessTypeId  
   ,ProjectOwnerTypeId  
FROM #ProjDefaultPrivacySetting;  
END
GO
PRINT N'Creating [dbo].[usp_InsertUnArchiveNotification]...';


GO
CREATE PROCEDURE [dbo].[usp_InsertUnArchiveNotification]  
(  
 @ArchiveProjectId INT,  
 @ProdProjectId INT,  
 @SLC_UserId INT,  
 @SLC_CustomerId INT,  
 @ProjectName NVARCHAR(500),  
 @RequestType INT  
)  
AS  
BEGIN  
	--Check wether notification is present and status is Queued/Running
	DECLARE @RequestId INT=(SELECT TOP 1 RequestId from UnArchiveProjectRequest WITH(NOLOCK) where SLC_ArchiveProjectId=@ArchiveProjectId
				AND SLC_CustomerId=@SLC_CustomerId and IsDeleted=0 and StatusId IN(1,2))
	IF(isnull(@RequestId,0)>0)
	BEGIN
		UPDATE APR
		SET APR.StatusId=1,
			APR.ProgressInPercentage=0,
			APR.IsNotify=0,
			APR.RequestDate=GETUTCDATE()
		FROM UnArchiveProjectRequest APR WITH(NOLOCK)
		WHERE APR.RequestId=@RequestId
	END
	ELSE
	BEGIN
		INSERT INTO UnArchiveProjectRequest  
		 (SLC_ArchiveProjectId,SLCProd_ProjectId,SLC_CustomerId,SLC_UserId,  
		 RequestDate,RequestType,StatusId,IsNotify,ProgressInPercentage,  
		 EmailFlag,IsDeleted,ProjectName,ModifiedDate)  
		VALUES(@ArchiveProjectId,@ProdProjectId,@SLC_CustomerId,@SLC_UserId,  
		  GETUTCDATE(),@RequestType,1,0,0,  
		  0,0,@ProjectName,GETUTCDATE())         
	END

END
GO
PRINT N'Creating [dbo].[usp_ProjectLevelTrackChangesLogging]...';


GO
CREATE PROCEDURE [dbo].[usp_ProjectLevelTrackChangesLogging](
@UserId INT NULL,  
@ProjectId INT NULL,  
@CustomerId INT NULL,  
@UserEmail  NVARCHAR(100) NULL,  
@PriviousTrackChangeModeId INT NULL ,
@CurrentTrackChangeModeId INT NULL 
)
AS 
BEGIN
INSERT INTO ProjectLevelTrackChangesLogging ( UserId
, ProjectId
, CustomerId
, UserEmail
, PriviousTrackChangeModeId
, CurrentTrackChangeModeId
, CreatedDate
)
	VALUES ( @UserId,@ProjectId, @CustomerId, @UserEmail,@PriviousTrackChangeModeId,@CurrentTrackChangeModeId,GETUTCDATE() )
END
GO
PRINT N'Creating [dbo].[usp_SaveProjectDefaultPrivacySetting]...';


GO
CREATE PROCEDURE usp_SaveProjectDefaultPrivacySetting    
(    
@CustomerId int,    
@UserId int,    
@ProjectAccessTypeId int,    
@ProjectOwnerTypeId int,    
@ProjectOriginTypeId int,    
@IsOfficeMaster bit    
)    
AS    
BEGIN    
DECLARE @PCustomerId int = @CustomerId;    
DECLARE @PUserId int = @UserId;    
DECLARE @PProjectAccessTypeId int = @ProjectAccessTypeId;    
DECLARE @PProjectOwnerTypeId int = @ProjectOwnerTypeId;    
DECLARE @PProjectOriginTypeId int = @ProjectOriginTypeId;    
DECLARE @PIsOfficeMaster bit = @IsOfficeMaster;    
  
IF(@PProjectOriginTypeId = 2)  
BEGIN  
 update PS set PS.ProjectAccessTypeId = @PProjectAccessTypeId  
  from Project P WITH(NOLOCK)          
  join ProjectSummary PS WITH(NOLOCK)
  ON P.ProjectId = PS.ProjectId      
  where P.CustomerId=@CustomerId AND Isnull(p.isDeleted,0)=0 and P.IsShowMigrationPopup=1          
  and ISNULL(p.IsArchived,0)=0  AND ISNULL(p.IsOfficeMaster,0)=@IsOfficeMaster;   
END  
  
DECLARE @ID INT = ( SELECT TOP 1    
  Id    
 FROM ProjectDefaultPrivacySetting WITH (NOLOCK)    
 WHERE CustomerId = @PCustomerId    
 AND ProjectOriginTypeId = @PProjectOriginTypeId    
 AND IsOfficeMaster = @PIsOfficeMaster);    
    
IF (@ID IS NULL)    
BEGIN    
 INSERT INTO ProjectDefaultPrivacySetting (CustomerId, ProjectAccessTypeId, ProjectOwnerTypeId, ProjectOriginTypeId, IsOfficeMaster, CreatedBy, CreatedDate)    
 VALUES (@PCustomerId, @PProjectAccessTypeId, @PProjectOwnerTypeId, @PProjectOriginTypeId, @PIsOfficeMaster, @PUserId, GETUTCDATE());    
END    
ELSE    
BEGIN -- add new    
 UPDATE p    
 SET p.ProjectAccessTypeId = @PProjectAccessTypeId    
    ,p.ProjectOwnerTypeId = @PProjectOwnerTypeId    
    ,p.ModifiedBy = @PUserId    
    ,p.ModifiedDate = GETUTCDATE()    
 FROM ProjectDefaultPrivacySetting p WITH (NOLOCK)    
 WHERE p.CustomerId = @PCustomerId    
 AND p.ProjectOriginTypeId = @PProjectOriginTypeId    
 AND p.IsOfficeMaster = @PIsOfficeMaster;    
END    
END;
GO
PRINT N'Creating [dbo].[usp_SectionLevelTrackChangesLogging]...';


GO
CREATE PROCEDURE [dbo].[usp_SectionLevelTrackChangesLogging](
@UserId INT NULL,  
@ProjectId INT NULL,  
@CustomerId INT NULL,  
@UserEmail  NVARCHAR(100) NULL,   
@SectionId Int=NULL,
@IsTrackChanges BIT=1,
@IsTrackChangeLock BIT=0
)
AS 
BEGIN
INSERT INTO SectionLevelTrackChangesLogging ( UserId
, ProjectId
, SectionId
, CustomerId
, UserEmail
, IsTrackChanges
, IsTrackChangeLock
, CreatedDate
)
	VALUES ( @UserId,@ProjectId, @SectionId,@CustomerId,@UserEmail, @IsTrackChanges,@IsTrackChangeLock, GETUTCDATE() )
END
GO
PRINT N'Creating [dbo].[usp_SetLockUnlockProject]...';


GO
CREATE PROCEDURE [dbo].[usp_SetLockUnlockProject]                                         
  @ProjectId INT           
 ,@UserId INT        
 ,@IsLocked BIT = 0        
 ,@LockedBy NVARCHAR(500)      
 
                                       
AS                                        
BEGIN                                      
                                      
  DECLARE @PProjectId INT = @ProjectId;       
  DECLARE @PUserId INT = @UserId;                                      
  DECLARE @PIsLocked BIT = @IsLocked;                                      
  DECLARE @PLockedBy NVARCHAR(500) = @LockedBy;                                      
                            
     
 UPDATE P       
 SET p.IsLocked = @PIsLocked ,      
 P.ModifiedBy = @UserId,      
 p.ModifiedDate = GETUTCDATE(),      
 p.LockedBy = @PLockedBy,      
 p.LockedDate = GETUTCDATE()      
 from project P with(NOLOCK)        
 WHERE ProjectId = @PProjectId;          
END;
GO
PRINT N'Creating [dbo].[usp_SetProjectSegemntNoteMappingData]...';


GO
CREATE PROCEDURE [dbo].[usp_SetProjectSegemntNoteMappingData] 
(@ProjectId INT,  
@CustomerId INT,  
@segmentNoteMappingDataJson NVARCHAR(MAX)
) 
 
AS  
BEGIN  
 
 DECLARE @SegmentMappingNoteTbl TABLE (  
	mSectionId INT,
    NoteText NVARCHAR(2000),
    Title NVARCHAR(2000),
    mSegmentId INT,
    mSegmentStatusId INT,
	SectionId INT
 )  
  
 DECLARE @DistinctSectionTbl TABLE (SectionId INT)
 INSERT INTO @SegmentMappingNoteTbl  
  SELECT  
   *   
  FROM OPENJSON(@segmentNoteMappingDataJson)  
  WITH (  
  mSectionId INT '$.mSectionId',  
  NoteText NVARCHAR(2000) '$.NoteText',  
  Title NVARCHAR(2000) '$.Title',  
  mSegmentId INT '$.mSegmentId',  
  mSegmentStatusId INT '$.mSegmentStatusId',
  SectionId INT '$.SectionId'
  );  

INSERT  INTO ProjectNote(SectionId,SegmentStatusId,NoteText,CreateDate,ProjectId,CustomerId,Title,CreatedBy,IsDeleted) 
 SELECT pss.SectionId,pss.SegmentStatusId,smnt.NoteText,GETUTCDATE(),pss.ProjectId,pss.CustomerId,smnt.Title,pss.CustomerId as CreatedBy,0 as IsDeleted	 
 FROM @SegmentMappingNoteTbl smnt  
 INNER JOIN ProjectSegmentStatus pss WITH (NOLOCK)
 ON smnt.SectionId=pss.SectionId and smnt.mSegmentId=pss.mSegmentId and smnt.mSegmentStatusId=pss.mSegmentStatusId
 WHERE pss.ProjectId=@ProjectId and pss.CustomerId=@CustomerId
  
END
GO
PRINT N'Altering [dbo].[usp_CopyProject]...';


GO
ALTER PROCEDURE [dbo].[usp_CopyProject]    
(    
 @PSourceProjectId  INT    
,@PTargetProjectId INT    
,@PCustomerId INT    
,@PUserId INT    
,@PRequestId INT      
)    
AS    
BEGIN    
--Handle Parameter Sniffing    
DECLARE @SourceProjectId INT = @PSourceProjectId;    
DECLARE @TargetProjectId INT = @PTargetProjectId;    
DECLARE @CustomerId INT = @PCustomerId;    
DECLARE @UserId INT = @PUserId;    
DECLARE @RequestId INT = @PRequestId;    
      
--Progress Variables    
DECLARE @CopyStart_Description NVARCHAR(50) = 'Copy Started';    
DECLARE @CopyGlobalTems_Description NVARCHAR(50) = 'Global Terms Copied';    
DECLARE @CopySections_Description NVARCHAR(50) = 'Sections Copied';    
DECLARE @CopySegmentStatus_Description NVARCHAR(50) = 'Segment Status Copied';    
DECLARE @CopySegments_Description NVARCHAR(50) = 'Segments Copied';    
DECLARE @CopySegmentChoices_Description NVARCHAR(50) = 'Choices Copied';    
DECLARE @CopySegmentLinks_Description NVARCHAR(50) = 'Segment Links Copied';    
DECLARE @CopyNotes_Description NVARCHAR(50) = 'Notes Copied';    
DECLARE @CopyImages_Description NVARCHAR(50) = 'Images Copied';    
DECLARE @CopyRefStds_Description NVARCHAR(50) = 'Reference Standards Copied';    
DECLARE @CopyTags_Description NVARCHAR(50) = 'Segment Tags Copied';    
DECLARE @CopyHeaderFooter_Description NVARCHAR(50) = 'Header and Footer Copied';    
DECLARE @CopyProjectHyperLink_Description NVARCHAR(50) = 'Project Hyper Link Copied';    
DECLARE @CopyComplete_Description NVARCHAR(50) = 'Copy Completed';    
DECLARE @CopyFailed_Description NVARCHAR(50) = 'Copy Failed';    
DECLARE @CustomerName NVARCHAR(20) = '';    
DECLARE @UserName NVARCHAR(20) = '';    
    
DECLARE @CopyStart_Percentage FLOAT = 5;    
DECLARE @CopyGlobalTems_Percentage FLOAT = 10;    
DECLARE @CopySections_Percentage FLOAT = 15;    
DECLARE @CopySegmentStatus_Percentage FLOAT = 35;    
DECLARE @CopySegments_Percentage FLOAT = 45;    
DECLARE @CopySegmentChoices_Percentage FLOAT = 55;    
DECLARE @CopySegmentLinks_Percentage FLOAT = 70;    
DECLARE @CopyNotes_Percentage FLOAT = 75;    
DECLARE @CopyImages_Percentage FLOAT = 80;    
DECLARE @CopyRefStds_Percentage FLOAT = 85;    
DECLARE @CopyTags_Percentage FLOAT = 90;    
DECLARE @CopyHeaderFooter_Percentage FLOAT = 95;    
DECLARE @CopyProjectHyperLink_Percentage FLOAT = 97;    
DECLARE @CopyComplete_Percentage FLOAT = 100;    
DECLARE @CopyFailed_Percentage FLOAT = 100;    
DECLARE @CopyStart_Step INT = 2;    
DECLARE @CopyGlobalTems_Step INT = 3;    
DECLARE @CopySections_Step INT = 4;    
DECLARE @CopySegmentStatus_Step INT = 5;    
DECLARE @CopySegments_Step INT = 6;    
DECLARE @CopySegmentChoices_Step INT = 7;    
DECLARE @CopySegmentLinks_Step INT = 8;    
DECLARE @CopyNotes_Step INT = 9;    
DECLARE @CopyImages_Step INT = 10;    
DECLARE @CopyRefStds_Step INT = 11;    
DECLARE @CopyTags_Step INT = 12;    
DECLARE @CopyHeaderFooter_Step INT = 13;    
DECLARE @CopyProjectHyperLink_Step INT = 14;    
DECLARE @CopyComplete_Step FLOAT = 15;    
DECLARE @CopyFailed_Step FLOAT = 16;    
    
--Variables    
DECLARE @MasterDataTypeId INT = ( SELECT TOP 1    
  MasterDataTypeId    
 FROM Project WITH (NOLOCK)    
 WHERE ProjectId = @SourceProjectId    
 AND CustomerId = @CustomerId);    
    
DECLARE @StateProvinceName NVARCHAR(100) = (SELECT TOP 1    
  IIF(LUS.StateProvinceName IS NULL, PADR.StateProvinceName, LUS.StateProvinceName) AS StateProvinceName    
 FROM ProjectAddress PADR WITH (NOLOCK)    
 LEFT OUTER JOIN LuStateProvince LUS WITH (NOLOCK)    
  ON LUS.StateProvinceID = PADR.StateProvinceId    
 WHERE PADR.ProjectId = @TargetProjectId    
 AND PADR.CustomerId = @CustomerId);    
    
DECLARE @City NVARCHAR(100) = (SELECT TOP 1    
  IIF(LUC.City IS NULL, PADR.CityName, LUC.City) AS City    
 FROM ProjectAddress PADR WITH (NOLOCK)    
 LEFT OUTER JOIN LuCity LUC WITH (NOLOCK)    
  ON LUC.CityId = PADR.CityId    
 WHERE PADR.ProjectId = @TargetProjectId    
 AND PADR.CustomerId = @CustomerId);    
    
--Temp Tables        
DROP TABLE IF EXISTS #tmp_SrcSection;    
DROP TABLE IF EXISTS #tmp_TgtSection;    
DROP TABLE IF EXISTS #SrcSegmentStatusCPTMP;    
DROP TABLE IF EXISTS #tmp_TgtSegmentStatus;    
DROP TABLE IF EXISTS #tmp_SrcSegment;    
DROP TABLE IF EXISTS #tmp_TgtSegment;    
DROP TABLE IF EXISTS #tmp_SrcSegmentChoice;    
DROP TABLE IF EXISTS #tmp_SrcSelectedChoiceOption;    
DROP TABLE IF EXISTS #tmp_TgtSegmentChoice;    
DROP TABLE IF EXISTS #tmp_SrcSegmentLink;    
DROP TABLE IF EXISTS #tmp_TgtProjectNote;    
DROP TABLE IF EXISTS #tmp_SrcProjectSegmentRequirementTag;    
    
         
DECLARE @id_control INT    
DECLARE @results INT     
    
BEGIN TRY    
EXEC usp_MaintainCopyProjectHistory @TargetProjectId    
     ,@CopyStart_Description    
     ,@CopyStart_Description    
     ,1 --IsCompleted        
     ,@CopyStart_Step --Step       
     ,@RequestId    
    
EXEC usp_MaintainCopyProjectProgress @SourceProjectId    
   ,@TargetProjectId    
   ,@UserId    
   ,@CustomerId    
   ,2 --Status        
   ,@CopyStart_Percentage --Percent        
   ,0 --IsInsertRecord     
   ,@CustomerName    
   ,@UserName;    
    
--UPDATE TemplateId,ModifiedDate,ModifiedByFullName in target project                    
UPDATE P          
SET P.TemplateId = P_Src.TemplateId,    
P.IsLocked = P_Src.IsLocked,    
P.LockedBy = CASE WHEN ISNULL(P_Src.IsLocked,0) = 1 THEN P_Src.LockedBy    
   ELSE NULL END,    
P.LockedDate = CASE WHEN ISNULL(P_Src.IsLocked,0) = 1 THEN P_Src.LockedDate    
   ELSE NULL END    
--,P.ModifiedBy = P_Src.ModifiedBy                    
--,P.ModifiedDate = P_Src.ModifiedDate                    
--,P.ModifiedByFullName = P_Src.ModifiedByFullName                     
FROM Project P WITH (NOLOCK)          
INNER JOIN Project P_Src WITH (NOLOCK)          
 ON P_Src.ProjectId = @SourceProjectId          
WHERE P.ProjectId = @TargetProjectId;          
          
--UPDATE LastAccessed and LastAccessByFullName in target project         
-- Resolved Bug 38772 - Removing this update statement.    
--UPDATE UF          
--SET --UF.LastAccessed = UF_Src.LastAccessed                    
--UF.LastAccessByFullName = UF_Src.LastAccessByFullName          
--FROM UserFolder UF WITH (NOLOCK)          
--INNER JOIN UserFolder UF_Src WITH (NOLOCK)          
-- ON UF_Src.ProjectId = @SourceProjectId          
--WHERE UF.ProjectId = @TargetProjectId;          
    
--INSERT ProjectGlobalTerm        
INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, [Name], [Value], GlobalTermSource, GlobalTermCode,    
CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted, GlobalTermFieldTypeId)    
 SELECT    
  PGT_Src.mGlobalTermId AS mGlobalTermId    
    ,@TargetProjectId AS ProjectId    
    ,@CustomerId AS CustomerId    
    ,PGT_Src.Name AS [Name]    
    ,(CASE    
   WHEN PGT_Src.Name = 'Project Name' THEN CAST(P.Name AS NVARCHAR(300))    
   WHEN PGT_Src.Name = 'Project ID' THEN CAST(P.ProjectId AS NVARCHAR(300))    
   WHEN (PGT_Src.Name = 'Project Location State' AND    
    PGT_Src.GlobalTermFieldTypeId = 3) THEN CAST(@StateProvinceName AS NVARCHAR(300))    
   WHEN (PGT_Src.Name = 'Project Location City' AND    
    PGT_Src.GlobalTermFieldTypeId = 3) THEN CAST(@City AS NVARCHAR(300))    
   WHEN (PGT_Src.Name = 'Project Location Province' AND    
    PGT_Src.GlobalTermFieldTypeId = 3) THEN CAST(@StateProvinceName AS NVARCHAR(500))    
   ELSE PGT_Src.Value    
  END) AS [Value]    
    ,PGT_Src.GlobalTermSource AS GlobalTermSource    
    ,PGT_Src.GlobalTermCode AS GlobalTermCode    
    ,PGT_Src.CreatedDate AS CreatedDate    
    ,PGT_Src.CreatedBy AS CreatedBy    
    ,PGT_Src.ModifiedDate AS ModifiedDate    
    ,PGT_Src.ModifiedBy AS ModifiedBy    
    ,PGT_Src.UserGlobalTermId AS UserGlobalTermId    
    ,ISNULL(PGT_Src.IsDeleted, 0) AS IsDeleted    
    ,PGT_Src.GlobalTermFieldTypeId    
 FROM ProjectGlobalTerm PGT_Src WITH (NOLOCK)    
 INNER JOIN Project P WITH (NOLOCK)    
  ON P.ProjectId = @TargetProjectId    
 WHERE PGT_Src.ProjectId = @SourceProjectId;    
    
EXEC usp_MaintainCopyProjectHistory @TargetProjectId    
     ,@CopyGlobalTems_Description    
     ,@CopyGlobalTems_Description    
     ,1 --IsCompleted        
     ,@CopyGlobalTems_Step --Step        
     ,@RequestId    
    
EXEC usp_MaintainCopyProjectProgress @SourceProjectId    
   ,@TargetProjectId    
   ,@UserId    
   ,@CustomerId    
   ,2 --Status        
   ,@CopyGlobalTems_Percentage --Percent        
   ,0 --IsInsertRecord        
   ,@CustomerName    
 ,@UserName;    
    
--Copy source sections in temp table    
SELECT    
 PS.*,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo INTO #tmp_SrcSection    
FROM ProjectSection PS WITH (NOLOCK)    
WHERE PS.ProjectId = @SourceProjectId    
AND PS.CustomerId = @CustomerId    
AND ISNULL(PS.IsDeleted, 0) = 0;    
     
SET @results = 1    
SET @id_control = 0    
     
DECLARE @ProjectSection INT    
DECLARE @ProjectSegmentStatus  INT    
DECLARE @ProjectSegment INT    
DECLARE @ProjectSegmentChoice INT    
DECLARE @ProjectChoiceOption INT    
DECLARE @SelectedChoiceOption INT    
DECLARE @ProjectSegmentLink INT    
DECLARE @ProjectHyperLink INT    
DECLARE @ProjectNote INT    
    
IF(EXISTS(SELECT TOP 1 1 FROM SLCMaster..LuTableInsertBatchSize WITH(NOLOCK) WHERE Servername=@@servername))    
BEGIN    
 SELECT TOP 1 @ProjectSection=ProjectSection,    
  @ProjectSegmentStatus=ProjectSegmentStatus,    
  @ProjectSegment =ProjectSegment ,    
  @ProjectSegmentChoice =ProjectSegmentChoice ,    
  @ProjectChoiceOption =ProjectChoiceOption ,    
  @SelectedChoiceOption =SelectedChoiceOption ,    
  @ProjectSegmentLink =ProjectSegmentLink ,    
  @ProjectHyperLink =ProjectHyperLink ,    
  @ProjectNote =ProjectNote     
  FROM SLCMaster..LuTableInsertBatchSize WITH(NOLOCK)     
  WHERE Servername=@@servername    
END    
ELSE    
BEGIN    
 SELECT TOP 1 @ProjectSection=ProjectSection,    
  @ProjectSegmentStatus=ProjectSegmentStatus,    
  @ProjectSegment =ProjectSegment ,    
  @ProjectSegmentChoice =ProjectSegmentChoice ,    
  @ProjectChoiceOption =ProjectChoiceOption ,    
  @SelectedChoiceOption =SelectedChoiceOption ,    
  @ProjectSegmentLink =ProjectSegmentLink ,    
  @ProjectHyperLink =ProjectHyperLink ,    
  @ProjectNote =ProjectNote     
  FROM SLCMaster..LuTableInsertBatchSize WITH(NOLOCK)     
  WHERE Servername IS NULL    
END    
 WHILE(@results>0)    
 BEGIN    
 --INSERT ProjectSection    
 INSERT INTO ProjectSection (ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode,    
 Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, CreateDate, CreatedBy,    
 ModifiedBy, ModifiedDate, FormatTypeId, SpecViewModeId, A_SectionId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy)    
  SELECT    
   PS_Src.ParentSectionId    
  ,PS_Src.mSectionId AS mSectionId    
  ,@TargetProjectId AS ProjectId    
  ,@CustomerId AS CustomerId    
  ,@UserId AS UserId    
  ,PS_Src.DivisionId AS DivisionId    
  ,PS_Src.DivisionCode AS DivisionCode    
  ,PS_Src.Description AS Description    
  ,PS_Src.LevelId AS LevelId    
  ,PS_Src.IsLastLevel AS IsLastLevel    
  ,PS_Src.SourceTag AS SourceTag    
  ,PS_Src.Author AS Author    
  ,PS_Src.TemplateId AS TemplateId    
  ,PS_Src.SectionCode AS SectionCode    
  ,PS_Src.IsDeleted AS IsDeleted    
  ,PS_Src.CreateDate AS CreateDate    
  ,PS_Src.CreatedBy AS CreatedBy    
  ,PS_Src.ModifiedBy AS ModifiedBy    
  ,PS_Src.ModifiedDate AS ModifiedDate    
  ,PS_Src.FormatTypeId AS FormatTypeId    
  ,PS_Src.SpecViewModeId AS SpecViewModeId    
  ,PS_Src.SectionId AS A_SectionId      
  ,IsTrackChanges      
  ,IsTrackChangeLock      
  ,COALESCE(TrackChangeLockedBy, 0) AS TrackChangeLockedBy      
  FROM #tmp_SrcSection PS_Src WITH (NOLOCK)    
  WHERE PS_Src.ProjectId = @SourceProjectId    
  AND SrNo > @id_control    
      AND SrNo <= @id_control + @ProjectSection    
 SET @results = @@ROWCOUNT    
   -- next batch    
   SET @id_control = @id_control + @ProjectSection    
     
 END    
--Copy target sections in temp table    
SELECT    
 PS.SectionId    
   ,PS.ParentSectionId    
   ,PS.ProjectId    
   ,PS.CustomerId    
  ,PS.IsLastLevel    
   ,PS.SectionCode    
   ,PS.IsDeleted    
   ,PS.A_SectionId     
   --,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo    
   INTO #tmp_TgtSection    
FROM ProjectSection PS WITH (NOLOCK)    
WHERE PS.ProjectId = @TargetProjectId    
AND ISNULL(PS.IsDeleted, 0) = 0;    
    
SELECT    
 SectionId    
   ,A_SectionId INTO #NewOldSectionIdMapping    
FROM #tmp_TgtSection    
    
--UPDATE ParentSectionId in TGT Section table    
UPDATE TGT_TMP    
SET TGT_TMP.ParentSectionId = NOSM.SectionId    
FROM #tmp_TgtSection TGT_TMP WITH (NOLOCK)    
INNER JOIN #NewOldSectionIdMapping NOSM WITH (NOLOCK)    
 ON TGT_TMP.ParentSectionId = NOSM.A_SectionId    
WHERE TGT_TMP.ProjectId = @TargetProjectId;    
    
    
--UPDATE ParentSectionId in original table    
UPDATE PS    
SET PS.ParentSectionId = PS_TMP.ParentSectionId    
FROM ProjectSection PS WITH (NOLOCK)    
INNER JOIN #tmp_TgtSection PS_TMP    
 ON PS.SectionId = PS_TMP.SectionId    
WHERE PS.ProjectId = @TargetProjectId    
AND PS.CustomerId = @CustomerId;    
    
EXEC usp_MaintainCopyProjectHistory @TargetProjectId    
     ,@CopySections_Description    
     ,@CopySections_Description    
     ,1 --IsCompleted        
     ,@CopySections_Step --Step        
     ,@RequestId    
    
EXEC usp_MaintainCopyProjectProgress @SourceProjectId    
   ,@TargetProjectId    
   ,@UserId    
   ,@CustomerId    
   ,2 --Status        
   ,@CopySections_Percentage --Percent        
   ,0 --IsInsertRecord        
   ,@CustomerName    
   ,@UserName;    
    
--Copy source segment status in temp table        
SELECT    
 PSST.*     
 ,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo    
 INTO #SrcSegmentStatusCPTMP    
FROM ProjectSegmentStatus PSST WITH (NOLOCK)    
WHERE PSST.ProjectId = @SourceProjectId    
AND PSST.CustomerId = @CustomerId    
AND ISNULL(PSST.IsDeleted, 0) = 0    
    
SET @results = 1     
SET @id_control = 0     
    
WHILE(@results>0)    
BEGIN    
 --INSERT ProjectSegmentStatus        
 INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin,    
 IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId,    
 SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson, CreateDate, CreatedBy, ModifiedBy,    
 ModifiedDate, IsPageBreak, IsDeleted, A_SegmentStatusId)    
  SELECT    
   PS.SectionId AS SectionId    
    ,PSST_Src.ParentSegmentStatusId AS ParentSegmentStatusId    
    ,PSST_Src.mSegmentStatusId AS mSegmentStatusId    
    ,PSST_Src.mSegmentId AS mSegmentId    
    ,PSST_Src.SegmentId AS SegmentId    
    ,PSST_Src.SegmentSource AS SegmentSource    
    ,PSST_Src.SegmentOrigin AS SegmentOrigin    
    ,PSST_Src.IndentLevel AS IndentLevel    
    ,PSST_Src.SequenceNumber AS SequenceNumber    
    ,PSST_Src.SpecTypeTagId AS SpecTypeTagId    
    ,PSST_Src.SegmentStatusTypeId AS SegmentStatusTypeId    
    ,PSST_Src.IsParentSegmentStatusActive AS IsParentSegmentStatusActive    
    ,@TargetProjectId AS ProjectId    
    ,@CustomerId AS CustomerId    
    ,PSST_Src.SegmentStatusCode AS SegmentStatusCode    
    ,PSST_Src.IsShowAutoNumber AS IsShowAutoNIsPageBreakumber    
    ,PSST_Src.IsRefStdParagraph AS IsRefStdParagraph    
    ,PSST_Src.FormattingJson AS FormattingJson    
    ,PSST_Src.CreateDate AS CreateDate    
    ,PSST_Src.CreatedBy AS CreatedBy    
    ,PSST_Src.ModifiedBy AS ModifiedBy    
    ,PSST_Src.ModifiedDate AS ModifiedDate    
    ,PSST_Src.IsPageBreak AS IsPageBreak    
    ,PSST_Src.IsDeleted AS IsDeleted    
    ,PSST_Src.SegmentStatusId AS A_SegmentStatusId    
  FROM #SrcSegmentStatusCPTMP PSST_Src WITH (NOLOCK)    
  INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)    
  ON PSST_Src.SectionId = PS.A_SectionId    
  AND PSST_Src.SrNo > @id_control    
     AND PSST_Src.SrNo <= @id_control + @ProjectSegmentStatus    
     
 SET @results = @@ROWCOUNT    
   -- next batch    
   SET @id_control = @id_control + @ProjectSegmentStatus    
END    
--Copy target segment status in temp table        
SELECT    
 PSST.SegmentStatusId    
   ,PSST.SectionId    
   ,PSST.ParentSegmentStatusId    
   ,PSST.SegmentId    
   ,PSST.ProjectId    
   ,PSST.CustomerId    
   ,PSST.SegmentStatusCode    
   ,PSST.IsDeleted    
   ,PSST.A_SegmentStatusId INTO #tmp_TgtSegmentStatus    
FROM ProjectSegmentStatus PSST WITH (NOLOCK)    
WHERE PSST.ProjectId = @TargetProjectId    
AND PSST.CustomerId = @CustomerId    
AND ISNULL(PSST.IsDeleted, 0) = 0    
    
SELECT    
 SegmentStatusId    
   ,A_SegmentStatusId INTO #NewOldSegmentStatusIdMapping    
FROM #tmp_TgtSegmentStatus    
    
--UPDATE ParentSegmentStatusId in temp table        
UPDATE CPSST    
SET CPSST.ParentSegmentStatusId = PPSST.SegmentStatusId    
FROM #tmp_TgtSegmentStatus CPSST WITH (NOLOCK)    
INNER JOIN #NewOldSegmentStatusIdMapping PPSST WITH (NOLOCK)    
 ON CPSST.ParentSegmentStatusId = PPSST.A_SegmentStatusId    
WHERE CPSST.ProjectId = @TargetProjectId    
AND CPSST.CustomerId = @CustomerId;    
    
--UPDATE ParentSegmentStatusId in original table    
UPDATE PSS    
SET PSS.ParentSegmentStatusId = PSS_TMP.ParentSegmentStatusId    
FROM ProjectSegmentStatus PSS WITH (NOLOCK)    
INNER JOIN #tmp_TgtSegmentStatus PSS_TMP    
 ON PSS.SegmentStatusId = PSS_TMP.SegmentStatusId    
 AND PSS.ProjectId = @TargetProjectId    
WHERE PSS.ProjectId = @TargetProjectId    
AND PSS.CustomerId = @CustomerId;    
    
EXEC usp_MaintainCopyProjectHistory @TargetProjectId    
     ,@CopySegmentStatus_Description    
     ,@CopySegmentStatus_Description    
     ,1 --IsCompleted        
     ,@CopySegmentStatus_Step --Step        
     ,@RequestId    
    
EXEC usp_MaintainCopyProjectProgress @SourceProjectId    
   ,@TargetProjectId    
   ,@UserId    
   ,@CustomerId    
   ,2 --Status        
   ,@CopySegmentStatus_Percentage --Percent        
   ,0 --IsInsertRecord        
   ,@CustomerName    
   ,@UserName;    
    
--Copy source segments in temp table        
SELECT PSG.* ,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo    
 INTO #tmp_SrcSegment    
FROM ProjectSegment PSG WITH (NOLOCK)    
WHERE PSG.ProjectId = @SourceProjectId    
AND PSG.CustomerId = @CustomerId    
AND ISNULL(PSG.IsDeleted, 0) = 0    
    
SET @results = 1     
SET @id_control = 0    
    
WHILE(@results>0)    
BEGIN    
 INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription,    
 SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted, A_SegmentId, BaseSegmentDescription)    
  SELECT    
   PSST.SegmentStatusId AS SegmentStatusId    
  ,PS.SectionId AS SectionId    
  ,@TargetProjectId AS ProjectId    
  ,@CustomerId AS CustomerId    
  ,PSG_Src.SegmentDescription AS SegmentDescription    
  ,PSG_Src.SegmentSource AS SegmentSource    
  ,PSG_Src.SegmentCode AS SegmentCode    
  ,PSG_Src.CreatedBy AS CreatedBy    
  ,PSG_Src.CreateDate AS CreateDate    
  ,PSG_Src.ModifiedBy AS ModifiedBy    
  ,PSG_Src.ModifiedDate AS ModifiedDate    
  ,PSG_Src.IsDeleted AS IsDeleted    
  ,PSG_Src.SegmentId AS A_SegmentId    
  ,PSG_Src.BaseSegmentDescription AS BaseSegmentDescription    
  FROM #tmp_SrcSegment PSG_Src WITH (NOLOCK)    
  INNER JOIN #tmp_tgtSection PS WITH (NOLOCK)    
  ON PSG_Src.SectionId = PS.A_SectionId    
  INNER JOIN #tmp_TgtSegmentStatus PSST WITH (NOLOCK)    
  ON PSG_Src.SegmentStatusId = PSST.A_SegmentStatusId    
  AND PSG_Src.SrNo > @id_control    
     AND PSG_Src.SrNo <= @id_control + @ProjectSegment    
      
  SET @results = @@ROWCOUNT    
  -- next batch    
  SET @id_control = @id_control + @ProjectSegment    
END    
    
--Copy target segments in temp table        
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
WHERE PSG.ProjectId = @TargetProjectId    
AND PSG.CustomerId = @CustomerId    
AND ISNULL(PSG.IsDeleted, 0) = 0    
    
--UPDATE SegmentId in temp table        
UPDATE PSST    
SET PSST.SegmentId = PSG.SegmentId    
FROM #tmp_TgtSegmentStatus PSST WITH (NOLOCK)    
INNER JOIN #tmp_TgtSegment PSG WITH (NOLOCK)    
ON PSST.SectionId = PSG.SectionId    
AND PSST.SegmentId = PSG.A_SegmentId    
AND PSST.SegmentId IS NOT NULL    
    
----UPDATE ParentSegmentStatusId and SegmentId in original table        
UPDATE PSST    
SET --PSST.ParentSegmentStatusId = PSST_TMP.ParentSegmentStatusId,        
PSST.SegmentId = PSST_TMP.SegmentId    
FROM ProjectSegmentStatus PSST WITH (NOLOCK)    
INNER JOIN #tmp_TgtSegmentStatus PSST_TMP WITH (NOLOCK)    
 ON PSST.SegmentStatusId = PSST_TMP.SegmentStatusId    
 AND PSST.ProjectId = PSST_TMP.ProjectId    
 AND PSST.SegmentId IS NOT NULL    
WHERE PSST.ProjectId = @TargetProjectId    
AND PSST.CustomerId = @CustomerId;    
    
EXEC usp_MaintainCopyProjectHistory @TargetProjectId    
     ,@CopySegments_Description    
     ,@CopySegments_Description    
     ,1 --IsCompleted        
     ,@CopySegments_Step --Step        
     ,@RequestId    
    
EXEC usp_MaintainCopyProjectProgress @SourceProjectId    
   ,@TargetProjectId    
   ,@UserId    
   ,@CustomerId    
   ,2 --Status        
   ,@CopySegments_Percentage --Percent        
   ,0 --IsInsertRecord        
   ,@CustomerName    
   ,@UserName;    
    
--Copy source choices in temp table        
SELECT    
 PCH.*     
 ,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo    
 INTO #tmp_SrcSegmentChoice    
FROM ProjectSegmentChoice PCH WITH (NOLOCK)    
WHERE PCH.ProjectId = @SourceProjectId    
AND PCH.CustomerId = @CustomerId    
AND ISNULL(PCH.IsDeleted, 0) = 0    
    
SET @results = 1    
SET @id_control = 0    
    
WHILE(@results>0)    
BEGIN    
 --INSERT ProjectSegmentChoice        
 INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource,    
 SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted, A_SegmentCHoiceId)    
 SELECT PS.SectionId AS SectionId    
 ,PSG.SegmentStatusId    
 ,PSG.SegmentId AS SegmentId    
 ,PCH_Src.ChoiceTypeId AS ChoiceTypeId    
 ,@TargetProjectId AS ProjectId    
 ,@CustomerId AS CustomerId    
 ,PCH_Src.SegmentChoiceSource AS SegmentChoiceSource    
 ,PCH_Src.SegmentChoiceCode AS SegmentChoiceCode    
 ,PCH_Src.CreatedBy AS CreatedBy    
 ,PCH_Src.CreateDate AS CreateDate    
 ,PCH_Src.ModifiedBy AS ModifiedBy    
 ,PCH_Src.ModifiedDate AS ModifiedDate    
 ,PCH_Src.IsDeleted AS IsDeleted    
 ,PCH_Src.SegmentChoiceId AS A_SegmentCHoiceId    
 FROM #tmp_SrcSegmentChoice PCH_Src WITH (NOLOCK)    
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)    
 ON PCH_Src.SectionId = PS.A_SectionId    
 INNER JOIN #tmp_TgtSegment PSG WITH (NOLOCK)    
 ON PS.SectionId = PSG.SectionId    
 AND PCH_Src.SegmentId = PSG.A_SegmentId    
 INNER JOIN #SrcSegmentStatusCPTMP SRCS    
 ON PCH_Src.SegmentId = SRCS.SegmentId    
 WHERE ISNULL(SRCS.IsDeleted, 0) = 0    
 AND PCH_Src.SrNo > @id_control    
    AND PCH_Src.SrNo <= @id_control + @ProjectSegmentChoice    
      
 SET @results = @@ROWCOUNT    
 -- next batch    
 SET @id_control = @id_control + @ProjectSegmentChoice    
END    
    
--Copy target choices in temp table        
SELECT PCH.*     
 ,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo    
 INTO #tmp_TgtSegmentChoice    
FROM ProjectSegmentChoice PCH WITH (NOLOCK)    
WHERE PCH.ProjectId = @TargetProjectId    
AND PCH.CustomerId = @CustomerId    
AND ISNULL(PCH.IsDeleted, 0) = 0    
    
SET @results = 1     
SET @id_control = 0    
    
WHILE(@results>0)    
BEGIN    
 --INSERT ProjectChoiceOption      
 INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId,    
 CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted, A_ChoiceOptionId)    
 SELECT PCH.SegmentChoiceId AS SegmentChoiceId    
  ,PCHOP_Src.SortOrder AS SortOrder    
  ,PCHOP_Src.ChoiceOptionSource AS ChoiceOptionSource    
  ,PCHOP_Src.OptionJson AS OptionJson    
  ,@TargetProjectId AS ProjectId    
  ,PCH.SectionId AS SectionId    
  ,@CustomerId AS CustomerId    
  ,PCHOP_Src.ChoiceOptionCode AS ChoiceOptionCode    
  ,PCHOP_Src.CreatedBy AS CreatedBy    
  ,PCHOP_Src.CreateDate AS CreateDate    
  ,PCHOP_Src.ModifiedBy AS ModifiedBy    
  ,PCHOP_Src.ModifiedDate AS ModifiedDate    
  ,PCHOP_Src.IsDeleted AS IsDeleted    
  ,PCHOP_Src.ChoiceOptionId AS A_ChoiceOptionId    
  FROM ProjectChoiceOption PCHOP_Src WITH (NOLOCK)    
  INNER JOIN #tmp_TgtSegmentChoice PCH WITH (NOLOCK)    
  ON PCH.A_SegmentChoiceId = PCHOP_Src.SegmentChoiceId    
  AND ISNULL(PCH.IsDeleted, 0) = ISNULL(PCHOP_Src.IsDeleted, 0)    
  WHERE PCHOP_Src.ProjectId = @SourceProjectId    
  AND PCHOP_Src.CustomerId = @CustomerId    
  AND PCH.SrNo > @id_control    
     AND PCH.SrNo <= @id_control + @ProjectChoiceOption    
      
  SET @results = @@ROWCOUNT    
  -- next batch    
  SET @id_control = @id_control + @ProjectChoiceOption    
END    
--Copy source choices in temp table        
SELECT    
 SCO_Src.*     
 ,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo    
 INTO #tmp_SrcSelectedChoiceOption    
FROM SelectedChoiceOption SCO_Src WITH (NOLOCK)    
WHERE SCO_Src.ProjectId = @SourceProjectId    
AND SCO_Src.CustomerId = @CustomerId    
AND ISNULL(SCO_Src.IsDeleted, 0) = 0    
    
SET @results = 1    
SET @id_control = 0    
    
WHILE(@results>0)    
BEGIN    
 --INSERT SelectedChoiceOption        
 INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected,    
 SectionId, ProjectId, CustomerId, OptionJson, IsDeleted)    
 SELECT PSCHOP_Src.SegmentChoiceCode AS SegmentChoiceCode    
 ,PSCHOP_Src.ChoiceOptionCode AS ChoiceOptionCode    
 ,PSCHOP_Src.ChoiceOptionSource AS ChoiceOptionSource    
 ,PSCHOP_Src.IsSelected AS IsSelected    
 ,PSC.SectionId AS SectionId    
 ,@TargetProjectId AS ProjectId    
 ,@CustomerId AS CustomerId    
 ,PSCHOP_Src.OptionJson AS OptionJson    
 ,PSCHOP_Src.IsDeleted AS IsDeleted    
 FROM #tmp_SrcSelectedChoiceOption PSCHOP_Src WITH (NOLOCK)    
 INNER JOIN #NewOldSectionIdMapping PSC WITH (NOLOCK)    
 ON PSCHOP_Src.Sectionid = PSC.A_SectionId    
 AND PSCHOP_Src.ProjectId = @SourceProjectId    
 WHERE PSCHOP_Src.ProjectId = @SourceProjectId    
 AND PSCHOP_Src.CustomerId = @CustomerId    
 AND PSCHOP_Src.SrNo > @id_control    
    AND PSCHOP_Src.SrNo <= @id_control + @SelectedChoiceOption    
      
 SET @results = @@ROWCOUNT    
 -- next batch    
 SET @id_control = @id_control + @SelectedChoiceOption    
END    
    
EXEC usp_MaintainCopyProjectHistory @TargetProjectId    
     ,@CopySegmentChoices_Description    
     ,@CopySegmentChoices_Description    
     ,1 --IsCompleted        
     ,@CopySegmentChoices_Step --Step        
     ,@RequestId    
    
EXEC usp_MaintainCopyProjectProgress @SourceProjectId    
   ,@TargetProjectId    
   ,@UserId    
   ,@CustomerId    
   ,2 --Status        
   ,@CopySegmentChoices_Percentage --Percent        
   ,0 --IsInsertRecord        
   ,@CustomerName    
   ,@UserName;    
    
SELECT *    
 ,ROW_NUMBER() OVER (ORDER BY TargetSectionCode) AS SrNo    
 INTO #tmp_SrcSegmentLink    
FROM ProjectSegmentLink WITH (NOLOCK)    
WHERE ProjectId = @SourceProjectId    
AND CustomerId = @CustomerId    
AND ISNULL(IsDeleted, 0) = 0    
    
SET @results = 1     
SET @id_control = 0     
    
WHILE(@results>0)    
BEGIN    
 --INSERT ProjectSegmentLink        
 INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,    
 TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget,    
 LinkStatusTypeId, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId,    
 SegmentLinkCode, SegmentLinkSourceTypeId)    
 SELECT PSL_Src.SourceSectionCode    
 ,PSL_Src.SourceSegmentStatusCode    
 ,PSL_Src.SourceSegmentCode    
 ,PSL_Src.SourceSegmentChoiceCode    
 ,PSL_Src.SourceChoiceOptionCode    
 ,PSL_Src.LinkSource    
 ,PSL_Src.TargetSectionCode    
 ,PSL_Src.TargetSegmentStatusCode    
 ,PSL_Src.TargetSegmentCode    
 ,PSL_Src.TargetSegmentChoiceCode    
 ,PSL_Src.TargetChoiceOptionCode    
 ,PSL_Src.LinkTarget    
 ,PSL_Src.LinkStatusTypeId    
 ,PSL_Src.IsDeleted    
 ,PSL_Src.CreateDate AS CreateDate    
 ,PSL_Src.CreatedBy AS CreatedBy    
 ,PSL_Src.ModifiedBy AS ModifiedBy    
 ,PSL_Src.ModifiedDate AS ModifiedDate    
 ,@TargetProjectId AS ProjectId    
 ,@CustomerId AS CustomerId    
 ,PSL_Src.SegmentLinkCode    
 ,PSL_Src.SegmentLinkSourceTypeId    
  FROM #tmp_SrcSegmentLink AS PSL_Src WITH (NOLOCK)    
  where PSL_Src.SrNo > @id_control    
 AND PSL_Src.SrNo <= @id_control + @ProjectSegmentLink    
      
 SET @results = @@ROWCOUNT    
 -- next batch    
 SET @id_control = @id_control + @ProjectSegmentLink    
END       
    
EXEC usp_MaintainCopyProjectHistory @TargetProjectId    
     ,@CopySegmentLinks_Description    
     ,@CopySegmentLinks_Description         
     ,1 --IsCompleted        
     ,@CopySegmentLinks_Step --Step        
     ,@RequestId    
    
EXEC usp_MaintainCopyProjectProgress @SourceProjectId    
   ,@TargetProjectId    
   ,@UserId    
   ,@CustomerId    
   ,2 --Status        
   ,@CopySegmentLinks_Percentage --Percent        
   ,0 --IsInsertRecord        
   ,@CustomerName    
   ,@UserName;    
    
--INSERT ProjectNote       
    
SELECT    
 PS.SectionId AS SectionId    
    ,PSST.SegmentStatusId AS SegmentStatusId    
    ,PNT_Src.NoteText AS NoteText    
    ,PNT_Src.CreateDate AS CreateDate    
    ,PNT_Src.ModifiedDate AS ModifiedDate    
    ,@TargetProjectId AS ProjectId    
    ,@CustomerId AS CustomerId    
   ,PNT_Src.Title AS Title    
    ,PNT_Src.CreatedBy AS CreatedBy    
    ,PNT_Src.ModifiedBy AS ModifiedBy    
    ,PNT_Src.CreatedUserName    
    ,PNT_Src.ModifiedUserName    
    ,PNT_Src.IsDeleted AS IsDeleted    
    ,PNT_Src.NoteCode AS NoteCode    
    ,PNT_Src.NoteId AS A_NoteId    
 ,ROW_NUMBER() OVER (ORDER BY PSST.SegmentStatusId) AS SrNo    
 into #PN FROM ProjectNote PNT_Src WITH (NOLOCK)    
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)    
  ON PNT_Src.SectionId = PS.A_SectionId    
 INNER JOIN #tmp_TgtSegmentStatus PSST WITH (NOLOCK)    
  ON PNT_Src.SegmentStatusId = PSST.A_SegmentStatusId    
 WHERE PNT_Src.ProjectId = @SourceProjectId    
 AND PNT_Src.CustomerId = @CustomerId;    
     
 SET @results = 1     
SET @id_control = 0    
    
WHILE(@results>0)    
BEGIN    
 INSERT INTO ProjectNote (SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId,    
 CustomerId, Title, CreatedBy, ModifiedBy, CreatedUserName, ModifiedUserName, IsDeleted, NoteCode, A_NoteId)    
 select SectionId,SegmentStatusId,NoteText,CreateDate,ModifiedDate,ProjectId    
    ,CustomerId,Title,CreatedBy,ModifiedBy,CreatedUserName,ModifiedUserName,IsDeleted,NoteCode,A_NoteId    
 FROM #PN WHERE SrNo > @id_control    
 AND SrNo <= @id_control + @ProjectNote    
      
 SET @results = @@ROWCOUNT    
 -- next batch    
 SET @id_control = @id_control + @ProjectNote    
END    
    
EXEC usp_MaintainCopyProjectHistory @TargetProjectId    
     ,@CopyNotes_Description    
     ,@CopyNotes_Description    
     ,1 --IsCompleted        
     ,@CopyNotes_Step --Step        
     ,@RequestId    
    
EXEC usp_MaintainCopyProjectProgress @SourceProjectId    
   ,@TargetProjectId    
   ,@UserId    
   ,@CustomerId    
   ,2 --Status        
   ,@CopyNotes_Percentage --Percent        
   ,0 --IsInsertRecord        
   ,@CustomerName    
   ,@UserName;    
    
--Insert Target ProjectNote in Temp Table        
SELECT    
 PN.NoteId    
   ,PN.SectionId    
   ,PN.ProjectId    
   ,PN.CustomerId    
   ,PN.IsDeleted    
   ,PN.A_NoteId     
   INTO #tmp_TgtProjectNote    
FROM ProjectNote PN WITH (NOLOCK)    
WHERE PN.ProjectId = @TargetProjectId    
AND PN.CustomerId = @CustomerId    
AND ISNULL(IsDeleted, 0) = 0    
    
 --INSERT ProjectNoteImage        
 INSERT INTO ProjectNoteImage (NoteId, SectionId, ImageId, ProjectId, CustomerId)    
 SELECT PN.NoteId AS NoteId    
  ,PS.SectionId AS SectionId    
  ,PNTI_Src.ImageId AS ImageId    
  ,@TargetProjectId AS ProjectId    
  ,@CustomerId AS CustomerId    
  FROM ProjectNoteImage PNTI_Src WITH (NOLOCK)    
  INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)    
  ON PNTI_Src.SectionId = PS.A_SectionId    
  INNER JOIN #tmp_TgtProjectNote PN WITH (NOLOCK)    
  ON PN.SectionId=PS.SectionId    
  AND PN.ProjectId = @TargetProjectId    
  AND PNTI_Src.NoteId = PN.A_NoteId    
  WHERE PNTI_Src.ProjectId = @SourceProjectId    
  AND PNTI_Src.CustomerId = @CustomerId    
      
--INSERT ProjectSegmentImage        
INSERT INTO ProjectSegmentImage (SectionId, ImageId, ProjectId, CustomerId, SegmentId,ImageStyle)    
 SELECT    
  PS.SectionId AS SectionId    
    ,PSI_Src.ImageId AS ImageId    
    ,@TargetProjectId AS ProjectId    
    ,@CustomerId AS CustomerId    
    ,0 AS SegmentId        
 ,PSI_Src.ImageStyle        
 FROM ProjectSegmentImage PSI_Src WITH (NOLOCK)    
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)    
  ON PSI_Src.SectionId = PS.A_SectionId    
 WHERE PSI_Src.ProjectId = @SourceProjectId    
 AND PSI_Src.CustomerId = @CustomerId;    
      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId    
     ,@CopyImages_Description    
     ,@CopyImages_Description    
     ,1 --IsCompleted        
     ,@CopyImages_Step --Step        
     ,@RequestId    
    
EXEC usp_MaintainCopyProjectProgress @SourceProjectId    
   ,@TargetProjectId    
   ,@UserId    
   ,@CustomerId    
   ,2 --Status        
   ,@CopyImages_Percentage --Percent        
   ,0 --IsInsertRecord        
   ,@CustomerName    
   ,@UserName;    
    
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId,    
IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId, IsDeleted)    
 SELECT    
  @TargetProjectId AS ProjectId    
    ,PRS_Src.RefStandardId AS RefStandardId    
    ,PRS_Src.RefStdSource AS RefStdSource    
    ,PRS_Src.mReplaceRefStdId AS mReplaceRefStdId    
    ,PRS_Src.RefStdEditionId AS RefStdEditionId    
    ,PRS_Src.IsObsolete AS IsObsolete    
    ,PRS_Src.RefStdCode AS RefStdCode    
    ,PRS_Src.PublicationDate AS PublicationDate    
    ,PS.SectionId AS SectionId    
    ,@CustomerId AS CustomerId    
    ,PRS_Src.IsDeleted AS IsDeleted    
 FROM ProjectReferenceStandard PRS_Src WITH (NOLOCK)    
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)    
  ON PRS_Src.SectionId = PS.A_SectionId    
 WHERE PRS_Src.ProjectId = @SourceProjectId    
 AND PRS_Src.CustomerId = @CustomerId;    
    
INSERT INTO ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource,    
mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId,    
mSegmentId, RefStdCode, IsDeleted)    
 SELECT    
  PS.SectionId AS SectionId    
    ,PSG.SegmentId AS SegmentId    
    ,PSRS_Src.RefStandardId AS RefStandardId    
    ,PSRS_Src.RefStandardSource AS RefStandardSource    
    ,PSRS_Src.mRefStandardId AS mRefStandardId    
    ,PSRS_Src.CreateDate AS CreateDate    
    ,PSRS_Src.CreatedBy AS CreatedBy    
    ,PSRS_Src.ModifiedDate AS ModifiedDate    
    ,PSRS_Src.ModifiedBy AS ModifiedBy    
    ,@CustomerId AS CustomerId    
    ,@TargetProjectId AS ProjectId    
    ,PSRS_Src.mSegmentId AS mSegmentId    
    ,PSRS_Src.RefStdCode AS RefStdCode    
    ,PSRS_Src.IsDeleted AS IsDeleted    
 FROM ProjectSegmentReferenceStandard PSRS_Src WITH (NOLOCK)    
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)    
  ON PSRS_Src.SectionId = PS.A_SectionId    
 INNER JOIN #tmp_TgtSegment PSG WITH (NOLOCK)    
  ON PS.SectionId = PSG.SectionId    
   AND PSRS_Src.SegmentId = PSG.A_SegmentId    
 WHERE PSRS_Src.ProjectId = @SourceProjectId    
 AND PSRS_Src.CustomerId = @CustomerId;    
    
EXEC usp_MaintainCopyProjectHistory @TargetProjectId    
     ,@CopyRefStds_Description    
     ,@CopyRefStds_Description    
     ,1 --IsCompleted        
     ,@CopyRefStds_Step --Step        
     ,@RequestId    
    
EXEC usp_MaintainCopyProjectProgress @SourceProjectId    
   ,@TargetProjectId    
   ,@UserId    
   ,@CustomerId    
   ,2 --Status        
   ,@CopyRefStds_Percentage --Percent        
   ,0 --IsInsertRecord        
   ,@CustomerName    
   ,@UserName;    
    
--Copy source ProjectSegmentRequirementTag in temp table        
SELECT    
 PSRT.* INTO #tmp_SrcProjectSegmentRequirementTag    
FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)    
WHERE PSRT.ProjectId = @SourceProjectId    
AND PSRT.CustomerId = @CustomerId    
AND ISNULL(PSRT.IsDeleted, 0) = 0    
    
--INSERT ProjectSegmentRequirementTag        
INSERT INTO ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId, CreateDate,    
ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy, mSegmentRequirementTagId, IsDeleted)    
 SELECT    
  PS.SectionId    
    ,PSST.SegmentStatusId    
    ,PSRT_Src.RequirementTagId    
    ,PSRT_Src.CreateDate    
    ,PSRT_Src.ModifiedDate    
    ,@TargetProjectId AS ProjectId    
    ,@CustomerId AS CustomerId    
    ,PSRT_Src.CreatedBy    
    ,PSRT_Src.ModifiedBy    
    ,PSRT_Src.mSegmentRequirementTagId    
    ,PSRT_Src.IsDeleted    
 FROM #tmp_SrcProjectSegmentRequirementTag PSRT_Src WITH (NOLOCK)    
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)    
  ON PSRT_Src.SectionId = PS.A_SectionId    
 INNER JOIN #tmp_TgtSegmentStatus PSST WITH (NOLOCK)    
  --ON PS.SectionId = PSST.SectionId        
  ON PSRT_Src.SegmentStatusId = PSST.A_SegmentStatusId    
 WHERE PSRT_Src.ProjectId = @SourceProjectId    
 AND PSRT_Src.CustomerId = @CustomerId;    
    
--INSERT ProjectSegmentUserTag        
INSERT INTO ProjectSegmentUserTag (SectionId, SegmentStatusId, UserTagId, CreateDate, ModifiedDate,    
ProjectId, CustomerId, CreatedBy, ModifiedBy, IsDeleted)    
 SELECT    
  PS.SectionId    
    ,PSST.SegmentStatusId    
    ,PSUT_Src.UserTagId    
    ,PSUT_Src.CreateDate    
    ,PSUT_Src.ModifiedDate    
    ,@TargetProjectId AS ProjectId    
    ,@CustomerId AS CustomerId    
    ,PSUT_Src.CreatedBy    
    ,PSUT_Src.ModifiedBy    
    ,PSUT_Src.IsDeleted    
 FROM ProjectSegmentUserTag PSUT_Src WITH (NOLOCK)    
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)    
  ON PSUT_Src.SectionId = PS.A_SectionId    
 INNER JOIN #tmp_TgtSegmentStatus PSST WITH (NOLOCK)    
  --ON PS.SectionId = PSST.SectionId        
  ON PSUT_Src.SegmentStatusId = PSST.A_SegmentStatusId    
 WHERE PSUT_Src.ProjectId = @SourceProjectId    
 AND PSUT_Src.CustomerId = @CustomerId;    
    
--INSERT ProjectSegmentGlobalTerm        
INSERT INTO ProjectSegmentGlobalTerm (SectionId, SegmentId, mSegmentId, UserGlobalTermId, GlobalTermCode,    
CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, IsLocked, LockedByFullName,    
UserLockedId, IsDeleted)    
 SELECT    
  PS.SectionId    
    ,PSG.SegmentId    
    ,PSGT_Src.mSegmentId    
    ,PSGT_Src.UserGlobalTermId    
    ,PSGT_Src.GlobalTermCode    
    ,PSGT_Src.CreatedDate AS CreatedDate    
    ,PSGT_Src.CreatedBy AS CreatedBy    
    ,PSGT_Src.ModifiedDate AS ModifiedDate    
    ,PSGT_Src.ModifiedBy AS ModifiedBy    
    ,@CustomerId AS CustomerId    
    ,@TargetProjectId AS ProjectId    
    ,PSGT_Src.IsLocked    
    ,PSGT_Src.LockedByFullName    
    ,PSGT_Src.UserLockedId    
    ,PSGT_Src.IsDeleted    
 FROM ProjectSegmentGlobalTerm PSGT_Src WITH (NOLOCK)    
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)    
  ON PSGT_Src.SectionId = PS.A_SectionId    
 INNER JOIN #tmp_TgtSegment PSG WITH (NOLOCK)    
  ON PSGT_Src.SegmentId = PSG.A_SegmentId    
 WHERE PSGT_Src.ProjectId = @SourceProjectId    
 AND PSGT_Src.CustomerId = @CustomerId;    
    
EXEC usp_MaintainCopyProjectHistory @TargetProjectId    
     ,@CopyTags_Description    
     ,@CopyTags_Description    
     ,1 --IsCompleted        
     ,@CopyTags_Step --Step        
     ,@RequestId    
    
EXEC usp_MaintainCopyProjectProgress @SourceProjectId    
   ,@TargetProjectId    
   ,@UserId    
   ,@CustomerId    
   ,2 --Status        
   ,@CopyTags_Percentage --Percent       
   ,0 --IsInsertRecord        
   ,@CustomerName    
   ,@UserName;    
    
--INSERT Header        
INSERT INTO Header (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, TypeId, AltHeader, FPHeader, UseSeparateFPHeader, HeaderFooterCategoryId,    
[DateFormat], TimeFormat, HeaderFooterDisplayTypeId, DefaultHeader, FirstPageHeader, OddPageHeader, EvenPageHeader, DocumentTypeId,IsShowLineAboveHeader,IsShowLineBelowHeader)    
 SELECT    
  @TargetProjectId AS ProjectId    
    ,NULL AS SectionId    
    ,@CustomerId AS CustomerId    
    ,H_Src.Description    
    ,H_Src.IsLocked    
    ,H_Src.LockedByFullName    
    ,H_Src.LockedBy    
    ,H_Src.ShowFirstPage    
    ,H_Src.CreatedBy AS CreatedBy    
    ,H_Src.CreatedDate AS CreatedDate    
    ,H_Src.ModifiedBy AS ModifiedBy    
    ,H_Src.ModifiedDate AS ModifiedDate    
    ,H_Src.TypeId    
    ,H_Src.AltHeader    
    ,H_Src.FPHeader    
    ,H_Src.UseSeparateFPHeader    
    ,H_Src.HeaderFooterCategoryId    
    ,H_Src.[DateFormat]    
    ,H_Src.TimeFormat    
    ,H_Src.HeaderFooterDisplayTypeId    
    ,H_Src.DefaultHeader    
    ,H_Src.FirstPageHeader    
    ,H_Src.OddPageHeader    
    ,H_Src.EvenPageHeader    
    ,H_Src.DocumentTypeId    
 ,H_Src.IsShowLineAboveHeader      
 ,H_Src.IsShowLineBelowHeader      
 FROM Header H_Src WITH (NOLOCK)    
 WHERE H_Src.ProjectId = @SourceProjectId    
 AND ISNULL(H_Src.SectionId, 0) = 0    
 UNION    
 SELECT    
  @TargetProjectId AS ProjectId    
    ,PS.SectionId AS SectionId    
    ,@CustomerId AS CustomerId    
    ,H_Src.Description    
    ,H_Src.IsLocked    
    ,H_Src.LockedByFullName    
    ,H_Src.LockedBy    
    ,H_Src.ShowFirstPage    
    ,H_Src.CreatedBy AS CreatedBy    
    ,H_Src.CreatedDate AS CreatedDate    
    ,H_Src.ModifiedBy AS ModifiedBy    
    ,H_Src.ModifiedDate AS ModifiedDate    
    ,H_Src.TypeId    
    ,H_Src.AltHeader    
    ,H_Src.FPHeader    
    ,H_Src.UseSeparateFPHeader    
    ,H_Src.HeaderFooterCategoryId    
    ,H_Src.[DateFormat]    
    ,H_Src.TimeFormat    
    ,H_Src.HeaderFooterDisplayTypeId    
    ,H_Src.DefaultHeader    
    ,H_Src.FirstPageHeader    
    ,H_Src.OddPageHeader    
    ,H_Src.EvenPageHeader    
    ,H_Src.DocumentTypeId    
 ,H_Src.IsShowLineAboveHeader      
 ,H_Src.IsShowLineBelowHeader      
 FROM Header H_Src WITH (NOLOCK)    
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)    
  ON H_Src.SectionId = PS.A_SectionId    
 WHERE H_Src.ProjectId = @SourceProjectId;    
    
--INSERT Footer        
INSERT INTO Footer (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, TypeId, AltFooter, FPFooter, UseSeparateFPFooter, HeaderFooterCategoryId,    
[DateFormat], TimeFormat, HeaderFooterDisplayTypeId, DefaultFooter, FirstPageFooter, OddPageFooter, EvenPageFooter, DocumentTypeId,IsShowLineAboveFooter,IsShowLineBelowFooter)    
 SELECT    
  @TargetProjectId AS ProjectId    
    ,NULL AS SectionId    
    ,@CustomerId AS CustomerId    
    ,F_Src.Description    
    ,F_Src.IsLocked    
    ,F_Src.LockedByFullName    
    ,F_Src.LockedBy    
    ,F_Src.ShowFirstPage    
    ,F_Src.CreatedBy AS CreatedBy    
    ,F_Src.CreatedDate AS CreatedDate    
    ,F_Src.ModifiedBy AS ModifiedBy    
    ,F_Src.ModifiedDate AS ModifiedDate    
    ,F_Src.TypeId    
    ,F_Src.AltFooter    
    ,F_Src.FPFooter    
    ,F_Src.UseSeparateFPFooter    
    ,F_Src.HeaderFooterCategoryId    
    ,F_Src.[DateFormat]    
    ,F_Src.TimeFormat    
    ,F_Src.HeaderFooterDisplayTypeId    
    ,F_Src.DefaultFooter    
    ,F_Src.FirstPageFooter    
    ,F_Src.OddPageFooter    
    ,F_Src.EvenPageFooter    
    ,F_Src.DocumentTypeId        
 ,F_Src.IsShowLineAboveFooter      
 ,F_Src.IsShowLineBelowFooter        
 FROM Footer F_Src WITH (NOLOCK)    
 WHERE F_Src.ProjectId = @SourceProjectId    
 AND ISNULL(F_Src.SectionId, 0) = 0    
 UNION    
 SELECT    
  @TargetProjectId AS ProjectId    
    ,PS.SectionId AS SectionId    
    ,@CustomerId AS CustomerId    
    ,F_Src.Description    
    ,F_Src.IsLocked    
    ,F_Src.LockedByFullName    
    ,F_Src.LockedBy    
    ,F_Src.ShowFirstPage    
    ,F_Src.CreatedBy AS CreatedBy    
    ,F_Src.CreatedDate AS CreatedDate    
    ,F_Src.ModifiedBy AS ModifiedBy    
    ,F_Src.ModifiedDate AS ModifiedDate    
    ,F_Src.TypeId    
    ,F_Src.AltFooter    
    ,F_Src.FPFooter    
    ,F_Src.UseSeparateFPFooter    
    ,F_Src.HeaderFooterCategoryId    
    ,F_Src.[DateFormat]    
    ,F_Src.TimeFormat    
    ,F_Src.HeaderFooterDisplayTypeId    
    ,F_Src.DefaultFooter    
    ,F_Src.FirstPageFooter    
    ,F_Src.OddPageFooter    
    ,F_Src.EvenPageFooter    
    ,F_Src.DocumentTypeId         
 ,F_Src.IsShowLineAboveFooter      
 ,F_Src.IsShowLineBelowFooter      
 FROM Footer F_Src WITH (NOLOCK)    
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)    
  ON F_Src.SectionId = PS.A_SectionId    
 WHERE F_Src.ProjectId = @SourceProjectId;    
    
--INSERT HeaderFooterGlobalTermUsage        
INSERT INTO HeaderFooterGlobalTermUsage (HeaderId, FooterId, UserGlobalTermId, CustomerId    
, ProjectId, HeaderFooterCategoryId, CreatedDate, CreatedById)    
 SELECT    
  HeaderId    
    ,FooterId    
    ,UserGlobalTermId    
    ,@CustomerId AS CustomerId    
    ,@TargetProjectId AS ProjectId    
    ,HeaderFooterCategoryId    
    ,CreatedDate    
    ,CreatedById    
 FROM HeaderFooterGlobalTermUsage WITH (NOLOCK)    
 WHERE ProjectId = @SourceProjectId;    
    
EXEC usp_MaintainCopyProjectHistory @TargetProjectId    
     ,@CopyHeaderFooter_Description    
     ,@CopyHeaderFooter_Description    
     ,1 --IsCompleted        
     ,@CopyHeaderFooter_Step --Step        
     ,@RequestId    
    
EXEC usp_MaintainCopyProjectProgress @SourceProjectId    
   ,@TargetProjectId    
   ,@UserId    
   ,@CustomerId    
   ,2 --Status        
   ,@CopyHeaderFooter_Percentage --Percent        
   ,0 --IsInsertRecord        
   ,@CustomerName    
   ,@UserName;    
    
UPDATE Psmry    
SET Psmry.SpecViewModeId = Psmry_Src.SpecViewModeId    
   ,Psmry.IsIncludeRsInSection = Psmry_Src.IsIncludeRsInSection    
   ,Psmry.IsIncludeReInSection = Psmry_Src.IsIncludeReInSection    
   ,Psmry.BudgetedCostId = Psmry_Src.BudgetedCostId    
   ,Psmry.BudgetedCost = Psmry_Src.BudgetedCost    
   ,Psmry.ActualCost = Psmry_Src.ActualCost    
   ,Psmry.EstimatedArea = Psmry_Src.EstimatedArea    
   ,Psmry.SourceTagFormat = Psmry_Src.SourceTagFormat    
   ,Psmry.IsPrintReferenceEditionDate = Psmry_Src.IsPrintReferenceEditionDate    
   ,Psmry.IsActivateRsCitation = Psmry_Src.IsActivateRsCitation    
   ,Psmry.EstimatedSizeId = Psmry_Src.EstimatedSizeId    
   ,Psmry.EstimatedSizeUoM = Psmry_Src.EstimatedSizeUoM    
   ,Psmry.UnitOfMeasureValueTypeId = Psmry_Src.UnitOfMeasureValueTypeId    
   ,Psmry.TrackChangesModeId = Psmry_Src.TrackChangesModeId    
FROM ProjectSummary Psmry WITH (NOLOCK)    
INNER JOIN ProjectSummary Psmry_Src WITH (NOLOCK)    
 ON Psmry_Src.ProjectId = @SourceProjectId    
WHERE Psmry.ProjectId = @TargetProjectId;    
    
--Insert LuProjectSectionIdSeparator        
INSERT INTO LuProjectSectionIdSeparator (ProjectId, CustomerId, UserId, separator)    
 SELECT    
  @TargetProjectId AS ProjectId    
    ,@CustomerId AS CustomerId    
    ,UserId    
    ,LPSIS_Src.separator    
 FROM LuProjectSectionIdSeparator LPSIS_Src WITH (NOLOCK)    
 WHERE ProjectId = @SourceProjectId;    
    
--Insert ProjectPageSetting        
INSERT INTO ProjectPageSetting (MarginTop, MarginBottom, MarginLeft, MarginRight, EdgeHeader, EdgeFooter, IsMirrorMargin, ProjectId, CustomerId)    
 SELECT    
  MarginTop    
    ,MarginBottom    
    ,MarginLeft    
    ,MarginRight    
    ,EdgeHeader    
    ,EdgeFooter    
    ,IsMirrorMargin    
    ,@TargetProjectId AS ProjectId    
    ,@CustomerId AS CustomerId    
 FROM ProjectPageSetting WITH (NOLOCK)    
 WHERE ProjectId = @SourceProjectId;    
    
--Insert ProjectPaperSetting        
INSERT INTO ProjectPaperSetting (PaperName, PaperWidth, PaperHeight, PaperOrientation, PaperSource, ProjectId, CustomerId)    
 SELECT    
  PaperName    
    ,PaperWidth    
    ,PaperHeight    
    ,PaperOrientation    
    ,PaperSource    
    ,@TargetProjectId AS ProjectId    
    ,@CustomerId AS CustomerId    
 FROM ProjectPaperSetting WITH (NOLOCK)    
 WHERE ProjectId = @SourceProjectId;    
    
--Insert ProjectPrintSetting      
INSERT INTO ProjectPrintSetting (ProjectId, CustomerId, CreatedBy, CreateDate, ModifiedBy,    
ModifiedDate, IsExportInMultipleFiles, IsBeginSectionOnOddPage, IsIncludeAuthorInFileName, TCPrintModeId, IsIncludePageCount, IsIncludeHyperLink      
,KeepWithNext, IsPrintMasterNote, IsPrintProjectNote, IsPrintNoteImage, IsPrintIHSLogo)    
 SELECT    
  @TargetProjectId AS ProjectId    
    ,@CustomerId AS CustomerId    
    ,CreatedBy AS CreatedBy    
    ,CreateDate AS CreateDate    
    ,ModifiedBy AS ModifiedBy    
    ,ModifiedDate AS ModifiedDate    
    ,IsExportInMultipleFiles    
    ,IsBeginSectionOnOddPage    
    ,IsIncludeAuthorInFileName    
    ,TCPrintModeId    
    ,IsIncludePageCount    
    ,IsIncludeHyperLink      
 ,KeepWithNext      
 ,IsPrintMasterNote        
 ,IsPrintProjectNote        
 ,IsPrintNoteImage        
 ,IsPrintIHSLogo         
 FROM ProjectPrintSetting WITH (NOLOCK)    
 WHERE ProjectId = @SourceProjectId    
 AND CustomerId = @CustomerId;    
    
INSERT INTO ProjectDateFormat (MasterDataTypeId, ProjectId, CustomerId, UserId,    
ClockFormat, DateFormat, CreateDate)    
 SELECT    
  @MasterDataTypeId AS MasterDataTypeId    
    ,@TargetProjectId AS ProjectId    
    ,@CustomerId AS CustomerId    
    ,UserId    
    ,ClockFormat    
    ,DateFormat    
    ,CreateDate    
 FROM ProjectDateFormat WITH (NOLOCK)    
 WHERE ProjectId = @SourceProjectId;    
    
--Make project available to user        
UPDATE P    
SET P.IsDeleted = 0    
   ,P.IsPermanentDeleted = 0    
FROM Project P WITH (NOLOCK)    
WHERE P.ProjectId = @TargetProjectId;    
    
--- INSERT ProjectHyperLink    
SELECT    
  PSS_Target.sectionId    
    ,PSS_Target.SegmentId    
    ,PSS_Target.SegmentStatusId    
    ,PSS_Target.ProjectId    
    ,PSS_Target.CustomerId    
    ,LinkTarget    
    ,LinkText    
    ,LuHyperLinkSourceTypeId    
    ,GETUTCDATE() as CreateDate    
    ,@UserId AS CreatedBy    
    ,PHL.HyperLinkId    
 ,ROW_NUMBER() OVER (ORDER BY PSS_Target.SegmentStatusId) AS SrNo    
 INTO #HL FROM ProjectHyperLink PHL WITH (NOLOCK)    
 INNER JOIN #tmp_TgtSegmentStatus PSS_Target    
  ON PHL.SegmentStatusId = PSS_Target.A_SegmentStatusId    
 WHERE PHL.ProjectId = @PSourceProjectId    
    
SET @results = 1     
SET @id_control = 0    
    
WHILE(@results>0)    
BEGIN    
 INSERT INTO ProjectHyperLink (SectionId, SegmentId, SegmentStatusId, ProjectId,    
 CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy    
 , A_HyperLinkId)    
 SELECT SectionId, SegmentId, SegmentStatusId, ProjectId,    
 CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy    
 , HyperLinkId    
 FROM #HL    
 WHERE SrNo > @id_control    
 AND SrNo <= @id_control + @ProjectHyperLink    
      
 SET @results = @@ROWCOUNT    
 -- next batch    
 SET @id_control = @id_control + @ProjectHyperLink    
END    
---UPDATE NEW HyperLinkId in SegmentDescription    
DECLARE @MultipleHyperlinkCount INT = 0;    
SELECT    
 COUNT(SegmentStatusId) AS TotalCountSegmentStatusId INTO #TotalCountSegmentStatusIdTbl    
FROM ProjectHyperLink WITH (NOLOCK)    
WHERE ProjectId = @TargetProjectId    
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
WHERE PHL.ProjectId = @TargetProjectId    
AND  PS.SegmentDescription LIKE '%{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '}%'    
AND PS.SegmentDescription LIKE '%{HL#%'    
SET @MultipleHyperlinkCount = @MultipleHyperlinkCount - 1;    
END    
    
EXEC usp_MaintainCopyProjectHistory @TargetProjectId    
     ,@CopyProjectHyperLink_Description    
     ,@CopyProjectHyperLink_Description    
     ,1 --IsCompleted        
     ,@CopyProjectHyperLink_Step  --Step        
     ,@RequestId    
    
EXEC usp_MaintainCopyProjectProgress @SourceProjectId    
   ,@TargetProjectId    
   ,@UserId    
   ,@CustomerId    
   ,3 --Status        
   ,@CopyProjectHyperLink_Percentage --Percent        
   ,0 --IsInsertRecord        
   ,@CustomerName    
   ,@UserName;    
    
    
EXEC usp_MaintainCopyProjectHistory @TargetProjectId    
     ,@CopyComplete_Description    
     ,@CopyComplete_Description    
     ,1 --IsCompleted        
     ,@CopyComplete_Step --Step        
     ,@RequestId    
    
EXEC usp_MaintainCopyProjectProgress @SourceProjectId    
   ,@TargetProjectId    
   ,@UserId    
   ,@CustomerId    
   ,3 --Status        
   ,@CopyComplete_Percentage --Percent        
   ,0 --IsInsertRecord        
   ,@CustomerName    
   ,@UserName;    
    
END TRY    
BEGIN CATCH    
    
DECLARE @ResultMessage NVARCHAR(MAX);    
SET @ResultMessage = 'Rollback Transaction. Error Number: ' + CONVERT(VARCHAR(MAX), ERROR_NUMBER()) +    
'. Error Message: ' + CONVERT(VARCHAR(MAX), ERROR_MESSAGE()) +    
'. Procedure Name: ' + CONVERT(VARCHAR(MAX), ERROR_PROCEDURE()) +    
'. Error Severity: ' + CONVERT(VARCHAR(5), ERROR_SEVERITY()) +    
'. Line Number: ' + CONVERT(VARCHAR(5), ERROR_LINE());    
    
--Make unavailable this project from user        
UPDATE P    
SET P.IsDeleted = 1    
   ,P.IsPermanentDeleted = 1    
FROM Project P WITH (NOLOCK)    
WHERE P.ProjectId = @TargetProjectId;    
    
    
EXEC usp_MaintainCopyProjectHistory @TargetProjectId    
     ,@CopyFailed_Description    
     ,@ResultMessage    
     ,1 --IsCompleted        
     ,@CopyFailed_Step --Step        
     ,@RequestId    
    
EXEC usp_MaintainCopyProjectProgress @SourceProjectId    
   ,@TargetProjectId    
   ,@UserId    
   ,@CustomerId    
   ,4 --Status        
   ,@CopyFailed_Percentage --Percent        
   ,0 --IsInsertRecord        
   ,@CustomerName    
   ,@UserName;    
    
--Insert add user into the Project Team Member list     
DECLARE @IsOfficeMaster bit=0;    
SELECT TOP 1 @IsOfficeMaster=IsOfficeMaster FROM Project WHERE ProjectId=@TargetProjectId    
EXEC usp_ApplyProjectDefaultSetting @IsOfficeMaster,@TargetProjectId,@PUserId,@CustomerId   
    
EXEC usp_SendEmailCopyProjectFailedJob    
END CATCH    
END
GO
PRINT N'Altering [dbo].[usp_CreateNewProject]...';


GO
ALTER PROCEDURE [dbo].[usp_CreateNewProject] (    
@Name NVARCHAR(500),      
@IsOfficeMaster BIT,      
@Description NVARCHAR(100),      
@MasterDataTypeId INT,      
@UserId INT,      
@CustomerId INT,      
@ModifiedByFullName NVARCHAR(500),      
@GlobalProjectID NVARCHAR(36),      
@CreatedBy    INT     
)    
AS      
BEGIN    
DECLARE @PName NVARCHAR(500) = @Name;    
DECLARE @PIsOfficeMaster BIT = @IsOfficeMaster;    
DECLARE @PDescription NVARCHAR(100) = @Description;    
DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;    
DECLARE @PUserId INT = @UserId;    
DECLARE @PCustomerId INT = @CustomerId;    
DECLARE @PModifiedByFullName NVARCHAR(500) = @ModifiedByFullName;    
DECLARE @PGlobalProjectID NVARCHAR(36) = @GlobalProjectID;    
DECLARE @PCreatedBy INT = @CreatedBy;    
    
      
    DECLARE @TemplateId INT=0;    
  -- Get Template ID as per master datatype    
 IF @PMasterDataTypeId=1    
 BEGIN    
SET @TemplateId = (SELECT TOP 1    
  TemplateId    
 FROM Template WITH (NOLOCK)    
 WHERE IsSystem = 1    
 AND MasterDataTypeId = @PMasterDataTypeId    
 AND IsDeleted = 0);    
      
  END    
  ELSE    
  BEGIN    
SET @TemplateId = (SELECT TOP 1    
  TemplateId    
 FROM Template WITH (NOLOCK)    
 WHERE IsSystem = 1    
 AND MasterDataTypeId != 1    
 AND IsDeleted = 0);    
 END    
-- make entry to project table    
INSERT INTO Project ([Name]    
, IsOfficeMaster    
, [Description]    
, TemplateId    
, MasterDataTypeId    
, UserId    
, CustomerId    
, CreateDate    
, CreatedBy    
, ModifiedBy    
, ModifiedDate    
, IsDeleted    
, IsMigrated    
, IsNamewithHeld    
, IsLocked    
, GlobalProjectID    
, IsPermanentDeleted    
, A_ProjectId    
, IsProjectMoved    
, ModifiedByFullName)    
 VALUES (@PName, @PIsOfficeMaster, @PDescription, @TemplateId, @PMasterDataTypeId, @PUserId, @PCustomerId, GETUTCDATE(), @PCreatedBy, @PCreatedBy, GETUTCDATE(), 0, NULL, 0, 0,@PGlobalProjectID, NULL, NULL, NULL, @PModifiedByFullName)    
    
DECLARE @NewProjectId INT = SCOPE_IDENTITY();    
    
-- make entry to UserFolder table    
INSERT INTO UserFolder (FolderTypeId    
, ProjectId    
, UserId    
, LastAccessed    
, CustomerId    
, LastAccessByFullName)    
 VALUES (1, @NewProjectId, @PUserId, GETUTCDATE(), @PCustomerId, @PModifiedByFullName)    
    
-- Select newly created project.    
SELECT    
 @NewProjectId AS ProjectId    
   ,@PName AS [Name]    
   ,@PIsOfficeMaster AS IsOfficeMaster    
   ,@PDescription AS [Description]    
   ,@TemplateId AS TemplateId    
   ,@PMasterDataTypeId AS MasterDataTypeId    
   ,@PUserId AS UserId    
   ,@PCustomerId AS CustomerId    
   ,GETUTCDATE() AS CreateDate    
   ,@PCreatedBy AS CreatedBy    
   ,@PCreatedBy AS ModifiedBy    
   ,GETUTCDATE() AS ModifiedDate    
   ,0 AS IsDeleted    
   ,NULL AS IsMigrated    
   ,0 AS IsNamewithHeld    
   ,0 AS IsLocked    
   ,@PGlobalProjectID AS GlobalProjectID    
   ,NULL AS IsPermanentDeleted    
   ,NULL AS A_ProjectId    
   ,NULL AS IsProjectMoved    
   ,@PModifiedByFullName AS ModifiedByFullName    
   ,@NewProjectId AS Id    
--FROM Project WITH (NOLOCK)    
--WHERE ProjectId = @NewProjectId    
      
--Insert add user into the Project Team Member list     
EXEC usp_ApplyProjectDefaultSetting @IsOfficeMaster,@NewProjectId,@PUserId,@CustomerId  
   
END
GO
PRINT N'Altering [dbo].[usp_CreateSectionFromTemplateRequest]...';


GO
ALTER PROCEDURE usp_CreateSectionFromTemplateRequest  
(  
 @ProjectId INT,  
 @CustomerId INT,  
 @UserId INT,  
 @SourceTag VARCHAR(10),  
 @Author NVARCHAR(MAX),  
 @Description NVARCHAR(MAX),  
 @UserName NVARCHAR(MAX)='',  
 @UserAccessDivisionId NVARCHAR(MAX)=''  
)  
AS  
BEGIN  
--Paramenter Sniffing  
 DECLARE @PProjectId INT = @ProjectId;    
 DECLARE @PCustomerId INT = @CustomerId;    
 DECLARE @PUserId INT = @UserId;    
 DECLARE @PSourceTag VARCHAR (10) = @SourceTag;    
 DECLARE @PAuthor NVARCHAR(MAX) = @Author;    
 DECLARE @PDescription NVARCHAR(MAX) = @Description;    
 DECLARE @PUserName NVARCHAR(MAX) = @UserName;    
 DECLARE @PUserAccessDivisionId NVARCHAR(MAX) = @UserAccessDivisionId;    
  
 DECLARE @RequestId INT = 0;                  
 DECLARE @ErrorMessage NVARCHAR(MAX) = 'Exception'; 
 DECLARe @QuedStatus INT = 1 ;   
 DECLARE @RunningStatus INT=2 ;
  
 --If came from UI as undefined then make it empty as it should empty    
 IF @PUserAccessDivisionId = 'undefined'    
 BEGIN    
  SET @PUserAccessDivisionId = ''    
 END    
  
 DECLARE @ParentSectionIdTable TABLE (ParentSectionId INT );    
    
 DECLARE @BsdMasterDataTypeId INT = 1;    
 DECLARE @CNMasterDataTypeId INT = 4;    
    
 DECLARE @MasterDataTypeId INT = (SELECT TOP 1  MasterDataTypeId FROM Project WITH (NOLOCK) WHERE ProjectId = @PProjectId);    
    
 DECLARE @UserAccessDivisionIdTbl TABLE (DivisionId INT);    
 DECLARE @FutureDivisionIdOfSectionTbl TABLE (DivisionId INT);    
   
 DECLARE @TargetSectionId INT=0  
 DECLARE @TemplateSectionId INT=0  
 DECLARE @ParentSectionId INT=0  
 DECLARE @FutureDivisionId INT  
 DECLARE @TemplateSourceTag NVARCHAR(15) = '';                  
 DECLARE @TemplateAuthor NVARCHAR(50) = '';   
 DECLARE @DefaultTemplateSourceTag NVARCHAR(15) = '';                  
  
  
 --SET DEFAULT TEMPLATE SOURCE TAG ACCORDING TO MASTER DATATYPEID  
 IF @MasterDataTypeId = @BsdMasterDataTypeId  
 BEGIN  
  SET @DefaultTemplateSourceTag = '99999';  
  SET @TemplateAuthor = 'BSD';  
 END  
 ELSE IF @MasterDataTypeId = @CNMasterDataTypeId  
 BEGIN  
  SET @DefaultTemplateSourceTag = '99999';  
  SET @TemplateAuthor = 'BSD';  
 END  
  
 DECLARE @TemplateMasterSectionId INT = (SELECT TOP 1 mSectionId FROM ProjectSection PS WITH (NOLOCK)  
        WHERE ProjectId = @PProjectId  AND CustomerId = @CustomerId    
        AND PS.IsLastLevel = 1 AND ISNULL(PS.IsDeleted,0) = 0       
        AND PS.mSectionId IS NOT NULL  AND PS.SourceTag = @DefaultTemplateSourceTag    
        AND PS.Author = @TemplateAuthor);       
      
 IF EXISTS (SELECT TOP 1 1 FROM  SLCMaster..Section MS WITH (NOLOCK) WHERE MS.SectionId = @TemplateMasterSectionId AND MS.IsDeleted = 0)  
 BEGIN  
  SET @TemplateSourceTag = @DefaultTemplateSourceTag;  
 END        
  
 --FETCH VARIABLE DETAILS       
 SELECT @TemplateSectionId = PS.SectionId       
    --,@TemplateSectionCode = PS.SectionCode       
 FROM ProjectSection PS WITH (NOLOCK)       
 WHERE PS.ProjectId = @PProjectId       
 AND PS.CustomerId = @PCustomerId       
 AND PS.IsLastLevel = 1       
 AND PS.mSectionId =@TemplateMasterSectionId       
 AND PS.SourceTag = @TemplateSourceTag       
 AND PS.Author = @TemplateAuthor       
       
 --CALCULATE ParentSectionId   
 INSERT INTO @ParentSectionIdTable (ParentSectionId)   
 EXEC usp_GetParentSectionIdForImportedSection @PProjectId   
            ,@PCustomerId,@PUserId,@PSourceTag;    
  
 SELECT TOP 1 @ParentSectionId = ParentSectionId FROM @ParentSectionIdTable;  
  
 --PUT USER DIVISION ID'S INTO TABLE   
 INSERT INTO @UserAccessDivisionIdTbl (DivisionId)   
 SELECT * FROM dbo.fn_SplitString(@PUserAccessDivisionId, ',');   
   
 --CALCULATE DIVISION ID OF USER SECTION WHICH IS GOING TO BE   
 INSERT INTO @FutureDivisionIdOfSectionTbl (DivisionId)   
 EXEC usp_CalculateDivisionIdForUserSection @PProjectId   
            ,@PCustomerId   
            ,@PSourceTag   
            ,@PUserId   
            ,@ParentSectionId   
  
 SELECT TOP 1 @FutureDivisionId = DivisionId FROM @FutureDivisionIdOfSectionTbl;   

 
   
 --PERFORM VALIDATIONS   
 IF (@TemplateSourceTag = '')   
 BEGIN   
  SET @ErrorMessage = 'No master template found.';  
 END   
 ELSE IF EXISTS (SELECT TOP 1  1   
  FROM ProjectSection WITH (NOLOCK)   
  WHERE ProjectId = @PProjectId   
  AND CustomerId = @PCustomerId   
  AND ISNULL(IsDeleted,0) = 0   
  AND SourceTag = TRIM(@PSourceTag)   
  AND LOWER(Author) = LOWER(TRIM(@PAuthor)))   
 BEGIN   
  SET @ErrorMessage = 'Section already exists.';   
 END  
 ELSE IF EXISTS(Select TOP 1  1 from ProjectSection PS WITH(NOLOCK)
 INNER JOIN ImportProjectRequest IPR WITH(NOLOCK)
 ON PS.SectionId = IPR.TargetSectionId
  WHERE PS.ProjectId = @PProjectId   
  AND PS.CustomerId = @PCustomerId   
  AND ISNULL(PS.IsDeleted,0) = 1  
  AND PS.SourceTag = TRIM(@PSourceTag)   
  AND LOWER(PS.Author) = LOWER(TRIM(@PAuthor)) 
  AND IPR.StatusId IN(@QuedStatus,@RunningStatus))
  BEGIN
   SET @ErrorMessage = 'Section already exists.'; 
  END
 ELSE IF @ParentSectionId IS NULL OR @ParentSectionId <= 0   
 BEGIN   
  SET @ErrorMessage = 'Section id is invalid.'  
 END  
 ELSE IF @PUserAccessDivisionId != '' AND @FutureDivisionId NOT IN (SELECT DivisionId FROM @UserAccessDivisionIdTbl)  
 BEGIN  
  SET @ErrorMessage = 'You don''t have access rights to import section(s) in this division';  
 END  
 ELSE  
 BEGIN  
  --INSERT INTO ProjectSection  
  INSERT INTO ProjectSection (ParentSectionId, ProjectId, CustomerId, UserId,  
  DivisionId, DivisionCode, Description, LevelId, IsLastLevel, SourceTag,  
  Author, TemplateId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted,   
  FormatTypeId, SpecViewModeId,LockedByFullName,IsTrackChanges,IsTrackChangeLock,  
  TrackChangeLockedBy)  
  SELECT @ParentSectionId AS ParentSectionId                
   ,@PProjectId AS ProjectId  
   ,@PCustomerId AS CustomerId  
   ,@PUserId AS UserId  
   ,NULL AS DivisionId  
   ,NULL AS DivisionCode  
   ,@PDescription AS Description  
   ,PS_Template.LevelId AS LevelId  
   ,1 AS IsLastLevel  
   ,@PSourceTag AS SourceTag  
   ,@PAuthor AS Author  
   ,PS_Template.TemplateId AS TemplateId  
   ,GETUTCDATE() AS CreateDate  
   ,@PUserId AS CreatedBy  
   ,GETUTCDATE() AS ModifiedDate  
   ,@PUserId AS ModifiedBy  
   ,1 AS IsDeleted  
   ,PS_Template.FormatTypeId AS FormatTypeId  
   ,PS_Template.SpecViewModeId AS SpecViewModeId  
   ,@PUserName  
   ,IsTrackChanges  
   ,IsTrackChangeLock  
   ,COALESCE(TrackChangeLockedBy, 0) AS TrackChangeLockedBy  
   FROM ProjectSection PS_Template WITH (NOLOCK)  
   WHERE PS_Template.SectionId = @TemplateSectionId  
  SET @TargetSectionId = scope_identity()    
    
  SET @ErrorMessage = '';  
  
  INSERT INTO ImportProjectRequest(  
  SourceProjectId,TargetProjectId,SourceSectionId,TargetSectionId,  
  CreatedById,CustomerId,CreatedDate,StatusId,CompletedPercentage,  
  Source,IsNotify,IsDeleted)  
  SELECT @PProjectId,@PProjectId,@TemplateSectionId,@TargetSectionId,  
  @PUserId,@PCustomerId,getutcdate(),1,0,  
  'Import from Template',0,0  
  
  SET @RequestId=scope_identity();  
 END  
 SELECT @ErrorMessage as ErrorMessage,@RequestId as RequestId  
END
GO
PRINT N'Altering [dbo].[usp_GetAllSections]...';


GO
ALTER PROCEDURE [dbo].[usp_GetAllSections]
(      
 @projectId INT NULL,       
 @customerId INT NULL,       
 @userId INT NULL=NULL,       
 @DisciplineId NVARCHAR (1024) NULL = '',       
 @CatalogueType NVARCHAR (1024) NULL = 'FS',       
 @DivisionId NVARCHAR (1024) NULL = '',      
 @UserAccessDivisionId NVARCHAR (1024) = ''          
)      
AS          
BEGIN  

	DECLARE @PProjectId INT = @projectId;  
	DECLARE @PCustomerId INT = @customerId;  
	DECLARE @PUserId INT = @userId;  
	DECLARE @PDisciplineId NVARCHAR (1024) = @DisciplineId;
	DECLARE @PCatalogueType NVARCHAR (10) = @CatalogueType;
	
	DECLARE @True BIT = CAST(1 AS BIT), @False BIT = CAST(0 AS BIT);
	DECLARE @TodayDate DATETIME2 = GETDATE();

	--IMP: Apply master updates to project for some types of actions  
	EXEC usp_ApplyMasterUpdatesToProject @PProjectId, @PCustomerId;
  
	--DECLARE Variables  
	DECLARE @SourceTagFormat VARCHAR(10) = '999999';
	SET @SourceTagFormat = (SELECT TOP 1 PS.SourceTagFormat FROM ProjectSummary PS WITH(NOLOCK) WHERE PS.ProjectId = @PProjectId);

	-- Select Project for import from project list
	SELECT PS.SectionId AS SectionId,
	   ISNULL(PS.mSectionId, 0) AS mSectionId,
	   ISNULL(PS.ParentSectionId, 0) AS ParentSectionId,
	   PS.ProjectId AS ProjectId,
	   PS.CustomerId AS CustomerId,
	   @PUserId AS UserId,
	   ISNULL(PS.TemplateId, 0) AS TemplateId,
	   ISNULL(PS.DivisionId, 0) AS DivisionId,
	   ISNULL(PS.DivisionCode, '') AS DivisionCode,
	   ISNULL(PS.Description, '') AS Description,
	   ISNULL(PS.Description, '') AS DescriptionForPrint,
	   @PCatalogueType AS CatalogueType,
	   @True AS IsDisciplineEnabled,
	   PS.LevelId AS LevelId,
	   PS.IsLastLevel AS IsLastLevel,
	   PS.SourceTag AS SourceTag,
	   ISNULL(PS.Author, '') AS Author,
	   ISNULL(PS.CreatedBy, 0) AS CreatedBy,
	   ISNULL(PS.CreateDate, @TodayDate) AS CreateDate,
	   ISNULL(PS.ModifiedBy, 0) AS ModifiedBy,
	   ISNULL(PS.ModifiedDate, @TodayDate) AS ModifiedDate,(
		  CASE
			 WHEN PSS.SegmentStatusId IS NULL
			 AND PS.mSectionId IS NOT NULL THEN 'M'
			 WHEN PSS.SegmentStatusId IS NULL
			 AND PS.mSectionId IS NULL THEN 'U'
			 WHEN PSS.SegmentStatusId IS NOT NULL
			 AND PSS.SegmentSource = 'M'
			 AND PSS.SegmentOrigin = 'M' THEN 'M'
			 WHEN PSS.SegmentStatusId IS NOT NULL
			 AND PSS.SegmentSource = 'U'
			 AND PSS.SegmentOrigin = 'U' THEN 'U'
			 WHEN PSS.SegmentStatusId IS NOT NULL
			 AND PSS.SegmentSource = 'M'
			 AND PSS.SegmentOrigin = 'U' THEN 'M*'
		  END
	   ) AS SegmentOrigin,
	   COALESCE(PSS.SegmentStatusTypeId, -1) AS SegmentStatusTypeId,
	   ISNULL(PS.SectionCode, 0) AS SectionCode,
	   ISNULL(PS.IsLocked, 0) AS IsLocked,
	   ISNULL(PS.LockedBy, 0) AS LockedBy,
	   ISNULL(PS.LockedByFullName, '') AS LockedByFullName,
	   PS.FormatTypeId AS FormatTypeId,
	   @SourceTagFormat AS SourceTagFormat,
	   0 AS OLSFCount,
	   (CASE
			 WHEN MS.SectionId IS NOT NULL AND MS.IsDeleted = 1 
			 THEN @True
			 ELSE @False
		END) AS IsMasterDeleted,
	   (CASE
			 WHEN PS.IsLastLevel = 1 AND (PS.mSectionId IS NULL OR PS.mSectionId <= 0 OR PS.Author = 'USER') 
			 THEN @True
			 ELSE @False
		END) AS IsUserSection
	FROM
	   ProjectSection PS WITH (NOLOCK)
	   LEFT JOIN SLCMaster..Section MS WITH (NOLOCK) ON PS.mSectionId = MS.SectionId  
	   LEFT JOIN ProjectSegmentStatus PSS WITH (NOLOCK) 
	   ON PSS.SectionId = PS.SectionId
	   AND PSS.ProjectId = PS.ProjectId
	   AND PSS.CustomerId = PS.CustomerId
	   AND PSS.IndentLevel = 0
	   AND PSS.ParentSegmentStatusId = 0
	   AND PSS.SequenceNumber = 0
	   AND ISNULL(PSS.IsDeleted, 0) = 0
	WHERE PS.ProjectId = @PProjectId
	AND PS.CustomerId = @PCustomerId
	AND ISNULL(PS.IsDeleted, 0)  = 0
	ORDER BY PS.SourceTag ASC, PS.Author ASC;

END
GO
PRINT N'Creating [dbo].[CopyAndUnArchiveProjectJob]...';


GO
CREATE PROCEDURE [dbo].[CopyAndUnArchiveProjectJob]  
AS  
BEGIN  
   
    --find and mark as failed copy project requests which running loner(more than 30 mins)  
    EXEC [dbo].[usp_UpdateCopyProjectStepProgress]  
  
 EXEC [dbo].[usp_SendEmailCopyProjectFailedJob]  
  
 IF(NOT EXISTS(SELECT TOP 1 1 FROM [dbo].CopyProjectRequest WITH(nolock) WHERE StatusId=2))  
 BEGIN  
  DECLARE @SourceProjectId INT;  
  DECLARE @TargetProjectId INT;  
  DECLARE @CustomerId INT;  
  DECLARE @UserId INT;  
  DECLARe @RequestId INt;  
   
  SELECT TOP 1  
   @SourceProjectId = SourceProjectId  
     ,@TargetProjectId = TargetProjectId  
     ,@CustomerId = CustomerId  
     ,@UserId = CreatedById  
     ,@RequestId = RequestId  
  FROM [dbo].[CopyProjectRequest] WITH(nolock)   
  WHERE StatusId=1 AND ISNULL(IsDeleted,0)=0  
  ORDER BY CreatedDate ASC  
  
  IF(@TargetProjectId>0)  
  BEGIN  
   EXEC [dbo].[usp_CopyProject] @SourceProjectId  
       ,@TargetProjectId  
       ,@CustomerId  
       ,@UserId  
       ,@RequestId  
  END  
 END  
  
 IF(NOT EXISTS(SELECT TOP 1 1 FROM [dbo].CopyProjectRequest WITH(nolock) WHERE StatusId=2))  
 BEGIN  
  EXECUTE [dbo].[sp_UnArchiveProject]  
 END  
  
END
GO
PRINT N'Creating [dbo].[usp_CopyProjectSection]...';


GO
CREATE  PROCEDURE usp_CopyProjectSection 
(          
 @SourceProjectId INT,          
 @SourceSectionId INT,          
 @TargetProjectId INT,          
 @CustomerId INT,          
 @UserId INT,          
 @SourceTag VARCHAR (10),          
 @Author NVARCHAR(10),          
 @Description NVARCHAR(500),          
 @UserName NVARCHAR(500) = 'N/A',        
 @UserAccessDivisionId NVARCHAR(MAX) = ''      
)          
AS          
BEGIN  
    
 DECLARE @UserAccessDivisionIdTbl TABLE (DivisionId INT);  
 DECLARE @FutureDivisionIdOfSectionTbl TABLE (DivisionId INT);  
 DECLARE @ParentSectionIdTable TABLE (ParentSectionId INT);  
    
 DECLARE @ParentSectionId INT = 0;      
 DECLARE @FutureDivisionId INT;      
 DECLARE @ErrorMessage NVARCHAR(MAX) = 'Exception';       
 DECLARE @TargetSectionId INT = 0;          
       
   --If came from UI as undefined then make it empty as it should empty          
  IF @UserAccessDivisionId = 'undefined'          
  BEGIN  
   SET @UserAccessDivisionId = ''          
  END  
          
 -- Calculate ParentSectionId                        
 INSERT INTO @ParentSectionIdTable (ParentSectionId)                        
 EXEC usp_GetParentSectionIdForImportedSection @TargetProjectId, @CustomerId, @UserId, @SourceTag;                        
         
 SELECT TOP 1 @ParentSectionId = ParentSectionId FROM @ParentSectionIdTable;      
      
   --PUT USER DIVISION ID'S INTO TABLE         
  INSERT INTO @UserAccessDivisionIdTbl (DivisionId)         
  SELECT * FROM dbo.fn_SplitString(@UserAccessDivisionId, ',');         
         
  --CALCULATE DIVISION ID OF USER SECTION WHICH IS GOING TO BE         
  INSERT INTO @FutureDivisionIdOfSectionTbl (DivisionId)         
  EXEC usp_CalculateDivisionIdForUserSection @TargetProjectId         
    ,@CustomerId         
    ,@SourceTag         
    ,@UserId         
    ,@ParentSectionId         
        
  SELECT TOP 1 @FutureDivisionId = DivisionId FROM @FutureDivisionIdOfSectionTbl;      
      
  DECLARE @SourceMSectionId INT = 0, @SourceSectionCode INT = 0;        
  SELECT @SourceMSectionId = PS.mSectionId, @SourceSectionCode = PS.SectionCode        
  FROM ProjectSection PS WITH(NOLOCK) WHERE PS.SectionId = @SourceSectionId;          
      
       IF EXISTS (SELECT TOP 1  1         
     FROM ProjectSection WITH (NOLOCK)         
     WHERE ProjectId = @TargetProjectId         
     AND CustomerId = @CustomerId         
     AND ISNULL(IsDeleted,0) = 0         
     AND SourceTag = TRIM(@SourceTag)         
     AND LOWER(Author) = LOWER(TRIM(@Author)))         
  BEGIN         
   SET @ErrorMessage = 'Section already exists.';         
  END        
  ELSE IF @ParentSectionId IS NULL OR @ParentSectionId <= 0         
  BEGIN         
   SET @ErrorMessage = 'Section id is invalid.';      
  END        
  ELSE IF @UserAccessDivisionId != '' AND @FutureDivisionId NOT IN (SELECT DivisionId FROM @UserAccessDivisionIdTbl)        
  BEGIN        
   SET @ErrorMessage = 'You don''t have access rights to import section(s) in this division';        
  END        
  ELSE        
 BEGIN      
   EXEC usp_CreateTargetSection @SourceSectionId, @TargetProjectId, @CustomerId, @UserId, @SourceTag, @Author, @Description,@ParentSectionId, @TargetSectionId OUTPUT;          
          
   IF(@TargetSectionId = 0) RETURN;        
        
   DECLARE @TargetSectionCode INT = 0;        
   SELECT @TargetSectionCode = PS.SectionCode        
   FROM ProjectSection PS WITH(NOLOCK) WHERE PS.SectionId = @TargetSectionId;          
          
   DROP TABLE IF EXISTS #SourceProjectSegmentStatus;          
   DROP TABLE IF EXISTS #SourceProjectSegment;          
   DROP TABLE IF EXISTS #TargetProjectSegmentStatus;          
   --DROP TABLE IF EXISTS #TargetProjectSegment;          
   DROP TABLE IF EXISTS #TargetSegmentStatus;          
   Drop table if exists #tmp_SrcComment           
   DROP TABLE if exists #NewOldCommentIdMapping          
          
   BEGIN -- Initialize few parameters          
           
           
    DECLARE @IsMasterSection BIT = 0;          
   IF @SourceMSectionId IS NULL           
     SET @IsMasterSection = 0;          
    ELSE          
     SET @IsMasterSection = 1;          
          
    DECLARE @IsSectionOpen BIT = 0;          
    IF EXISTS (SELECT TOP 1 1                          
     FROM ProjectSegmentStatus PSS WITH (NOLOCK)           
     WHERE PSS.ProjectId = @SourceProjectId                  
     AND PSS.SectionId = @SourceSectionId             
     AND PSS.IndentLevel = 0          
     AND ISNULL(PSS.IsDeleted, 0) = 0)                          
    BEGIN                          
     SET @IsSectionOpen = 1;                          
    END          
   END          
          
   --IF(@IsSectionOpen = 1)          
    BEGIN          
             
    SELECT PSS.*          
    INTO #SourceProjectSegmentStatus          
    FROM ProjectSegmentStatus PSS WITH(NOLOCK)          
    WHERE PSS.ProjectId = @SourceProjectId AND PSS.SectionId = @SourceSectionId          
          
    --select top 1 * from ProjectSegment          
    --Fetch Src ProjectSegment data into temp table                          
     SELECT PS.*          
     INTO #SourceProjectSegment                          
     FROM ProjectSegment PS WITH (NOLOCK)                          
     WHERE PS.ProjectId = @SourceProjectId AND PS.SectionId = @SourceSectionId;          
          
          
     -- Insert records into ProjectSegmentStatus              
     INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin,                
     IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId,                
     SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson, CreateDate, CreatedBy, ModifiedBy,                
     ModifiedDate, IsPageBreak, IsDeleted, A_SegmentStatusId)                
     ((SELECT          
     @TargetSectionId AS SectionId                
    ,SrcPSS.ParentSegmentStatusId AS ParentSegmentStatusId          
    ,SrcPSS.mSegmentStatusId AS mSegmentStatusId          
    ,(CASE                          
   WHEN @IsSectionOpen = 1          
   THEN SrcPSS.mSegmentId          
   ELSE SrcPSS.SegmentId          
   END) AS mSegmentId         
    --,SrcPSS.mSegmentId AS mSegmentId          
    ,(CASE          
     WHEN SrcPSS.SegmentOrigin = 'U'          
     THEN SrcPSS.SegmentId          
     ELSE SrcPSS.mSegmentId          
     END) AS SegmentId          
     ,'U' AS SegmentSource                
     ,'U' AS SegmentOrigin                
     ,SrcPSS.IndentLevel AS IndentLevel          
     ,SrcPSS.SequenceNumber AS SequenceNumber                
     ,SrcPSS.SpecTypeTagId AS SpecTypeTagId                
     ,SrcPSS.SegmentStatusTypeId AS SegmentStatusTypeId                
     ,SrcPSS.IsParentSegmentStatusActive AS IsParentSegmentStatusActive                
     ,@TargetProjectId AS ProjectId                
     ,@CustomerId AS CustomerId                
     ,SrcPSS.SegmentStatusCode AS SegmentStatusCode                
     ,SrcPSS.IsShowAutoNumber AS IsShowAutoNumber                
     ,SrcPSS.IsRefStdParagraph AS IsRefStdParagraph                
     ,SrcPSS.FormattingJson AS FormattingJson                
     ,SrcPSS.CreateDate AS CreateDate                
     ,SrcPSS.CreatedBy AS CreatedBy                
     ,SrcPSS.ModifiedBy AS ModifiedBy                
     ,SrcPSS.ModifiedDate AS ModifiedDate                
     ,SrcPSS.IsPageBreak AS IsPageBreak          
     ,SrcPSS.IsDeleted AS IsDeleted                
     ,SrcPSS.SegmentStatusId AS A_SegmentStatusId          
     FROM #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)          
     WHERE @IsSectionOpen = 1)          
     UNION          
     (SELECT                          
   @TargetSectionId AS SectionId                          
   ,SrcMSS.ParentSegmentStatusId AS ParentSegmentStatusId                   
   ,SrcMSS.SegmentStatusId AS mSegmentStatusId      
   ,SrcMSS.SegmentId AS mSegmentId                          
   ,SrcMSS.SegmentId AS SegmentId          
   ,'U' AS SegmentSource                          
   ,'U' AS SegmentOrigin                          
   ,SrcMSS.IndentLevel AS IndentLevel                          
   ,SrcMSS.SequenceNumber AS SequenceNumber                
   ,(CASE                          
    WHEN SrcMSS.SpecTypeTagId = 1 THEN 4                          
    WHEN SrcMSS.SpecTypeTagId = 2 THEN 3                          
    ELSE SrcMSS.SpecTypeTagId                          
    END) AS SpecTypeTagId                         ,SrcMSS.SegmentStatusTypeId AS SegmentStatusTypeId                          
   ,SrcMSS.IsParentSegmentStatusActive AS IsParentSegmentStatusActive                          
   ,@TargetProjectId AS ProjectId                          
   ,@CustomerId AS CustomerId                          
   ,SrcMSS.SegmentStatusCode AS SegmentStatusCode                          
   ,SrcMSS.IsShowAutoNumber AS IsShowAutoNumber                          
   ,SrcMSS.IsRefStdParagraph AS IsRefStdParagraph                          
   ,SrcMSS.FormattingJson AS FormattingJson                          
   ,GETUTCDATE() AS CreateDate                          
   ,@UserId AS CreatedBy                          
   ,@UserId AS ModifiedBy          
   ,GETUTCDATE() AS ModifiedDate                          
   ,0 AS IsPageBreak                          
   ,SrcMSS.IsDeleted AS IsDeleted          
   ,SrcMSS.SegmentStatusId AS A_SegmentStatusId                          
   FROM SLCMaster..SegmentStatus SrcMSS WITH (NOLOCK)                          
   INNER JOIN SLCMaster..Segment SrcMS WITH (NOLOCK)                          
   ON SrcMSS.SegmentId = SrcMS.SegmentId                      
   WHERE SrcMSS.SectionId = @SourceMSectionId                          
   AND ISNULL(SrcMSS.IsDeleted, 0) = 0          
   AND @IsSectionOpen = 0))          
          
          
     SELECT PSS.*          
     INTO #TargetProjectSegmentStatus          
     FROM ProjectSegmentStatus PSS WITH(NOLOCK)          
     WHERE PSS.ProjectId = @TargetProjectId AND PSS.SectionId = @TargetSectionId;          
          
     -- Insert records into ProjectSegment                          
     INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId,                          
     SegmentDescription, SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, A_SegmentId)                
     ((SELECT                          
    NULL AS SegmentStatusId                          
   ,@TargetSectionId AS SectionId                          
   ,@TargetProjectId AS ProjectId                          
   ,@CustomerId AS CustomerId          
   ,(CASE                          
   WHEN SrcPSS.SegmentOrigin = 'U' THEN SrcPS.SegmentDescription                          
   ELSE SrcMS.SegmentDescription          
   END) AS SegmentDescription          
   ,'U' AS SegmentSource                          
   ,(CASE                          
   WHEN SrcPS.SegmentId IS NOT NULL          
   THEN SrcPS.SegmentCode          
   ELSE SrcMS.SegmentCode          
   END) AS SegmentCode          
   --,SrcMS.SegmentCode AS SegmentCode          
   ,@UserId AS CreatedBy          
   ,GETUTCDATE() AS CreateDate          
   ,@UserId AS ModifiedBy          
   ,GETUTCDATE() AS ModifiedDate          
   ,(CASE                          
    WHEN SrcPSS.SegmentOrigin = 'U'          
   THEN SrcPS.SegmentId          
    ELSE SrcMS.SegmentId          
    END) AS A_SegmentId          
   --,SrcPS.SegmentId AS SrcPSSegmentId          
   --,SrcMS.SegmentId AS SrcMSSegmentId          
          
   FROM #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)                          
   LEFT JOIN #SourceProjectSegment SrcPS WITH (NOLOCK)                    
   ON SrcPSS.SegmentId = SrcPS.SegmentId                          
   AND SrcPSS.SegmentOrigin = 'U'                          
   LEFT JOIN SLCMaster..Segment SrcMS WITH (NOLOCK)       
   ON SrcPSS.mSegmentId = SrcMS.SegmentId                          
   AND SrcPSS.SegmentOrigin = 'M'                          
   WHERE SrcPSS.SectionId = @SourceSectionId                          
   AND ISNULL(SrcPSS.IsDeleted, 0) = 0          
   AND (SrcPS.SegmentId IS NOT NULL                          
   OR SrcMS.SegmentId IS NOT NULL)          
   AND @IsSectionOpen = 1)          
  UNION          
   (SELECT                          
    NULL AS SegmentStatusId                          
   ,@TargetSectionId AS SectionId                          
   ,@TargetProjectId AS ProjectId                          
   ,@CustomerId AS CustomerId                          
   ,SrcMS.SegmentDescription AS SegmentDescription                          
   ,'U' AS SegmentSource                          
   ,SrcMS.SegmentCode AS SegmentCode                   
   ,@UserId AS CreatedBy                          
   ,GETUTCDATE() AS CreateDate                          
   ,@UserId AS ModifiedBy                          
   ,GETUTCDATE() AS ModifiedDate          
   ,SrcMS.SegmentId AS A_SegmentId                          
   FROM SLCMaster..SegmentStatus SrcMSS WITH (NOLOCK)                          
   INNER JOIN SLCMaster..Segment SrcMS WITH (NOLOCK)                          
    ON SrcMSS.SegmentId = SrcMS.SegmentId                          
   WHERE SrcMSS.SectionId = @SourceMSectionId                          
   AND ISNULL(SrcMSS.IsDeleted, 0) = 0                          
   AND @IsSectionOpen = 0))          
          
          
     BEGIN -- Update ProjectSegmentStatus and ProjectSegment with correct mappings          
      -- Update proper ParentSegmentStatusId          
      UPDATE PSS          
      SET PSS.ParentSegmentStatusId = TPSS.SegmentStatusId          
      FROM ProjectSegmentStatus PSS WITH(NOLOCK)          
      INNER JOIN #TargetProjectSegmentStatus TPSS WITH(NOLOCK)           
    ON TPSS.A_SegmentStatusId = PSS.ParentSegmentStatusId          
    WHERE PSS.ProjectId = @TargetProjectId AND PSS.SectionId = @TargetSectionId;          
          
      -- Update proper SegmentStatusId into ProjectSegment          
      UPDATE PS          
      SET PS.SegmentStatusId = PSS.SegmentStatusId          
      FROM ProjectSegment PS WITH(NOLOCK)          
      INNER JOIN #TargetProjectSegmentStatus PSS WITH(NOLOCK)          
    ON PS.SectionId = PSS.SectionId AND PS.A_SegmentId = PSS.SegmentId          
    WHERE PS.ProjectId = @TargetProjectId AND PS.SectionId = @TargetSectionId;          
          
      -- Update proper SegmentId into ProjectSegmentStatus          
      UPDATE PSS          
      SET PSS.SegmentId = PS.SegmentId          
      FROM ProjectSegmentStatus PSS WITH(NOLOCK)          
      INNER JOIN ProjectSegment PS WITH(NOLOCK)           
    ON PS.SectionId = PSS.SectionId AND PS.SegmentStatusId = PSS.SegmentStatusId          
    WHERE PSS.ProjectId = @TargetProjectId AND PSS.SectionId = @TargetSectionId;    
     END          
          
     SELECT PSS.*          
     INTO #TargetSegmentStatus          
     FROM ProjectSegmentStatus PSS WITH(NOLOCK)          
     WHERE PSS.ProjectId = @TargetProjectId AND PSS.SectionId = @TargetSectionId;          
             
     BEGIN -- Insert choices from source to target section ProjectChoiceOption          
   INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId,                          
   CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)                          
   (SELECT                          
     @TargetSectionId AS SectionId                          
    ,TPSS.SegmentStatusId AS SegmentStatusId                          
    ,TPSS.SegmentId AS SegmentId                          
    ,SrcMSC.ChoiceTypeId AS ChoiceTypeId                          
    ,@TargetProjectId AS ProjectId                          
    ,@CustomerId AS CustomerId                          
    ,'U' AS SegmentChoiceSource            
    ,SrcMSC.SegmentChoiceCode AS SegmentChoiceCode                          
    ,@UserId AS CreatedBy                          
    ,GETUTCDATE() AS CreateDate                          
    ,@UserId AS ModifiedBy                          
    ,GETUTCDATE() AS ModifiedDate                          
    FROM #TargetSegmentStatus TPSS WITH (NOLOCK)                          
    INNER JOIN SLCMaster..SegmentChoice SrcMSC WITH (NOLOCK)                          
     ON TPSS.mSegmentId = SrcMSC.SegmentId AND SrcMSC.SectionId = @SourceMSectionId          
    WHERE TPSS.SectionId = @TargetSectionId                          
    AND @IsSectionOpen = 0)          
    UNION          
    (SELECT                          
     @TargetSectionId AS SectionId                          
    ,TPSS.SegmentStatusId AS SegmentStatusId                          
    ,TPSS.SegmentId AS SegmentId          
    ,SrcMSC.ChoiceTypeId AS ChoiceTypeId                          
    ,@TargetProjectId AS ProjectId                          
    ,@CustomerId AS CustomerId                          
    ,'U' AS SegmentChoiceSource          
    ,SrcMSC.SegmentChoiceCode AS SegmentChoiceCode                          
    ,@UserId AS CreatedBy                          
    ,GETUTCDATE() AS CreateDate                          
    ,@UserId AS ModifiedBy                          
    ,GETUTCDATE() AS ModifiedDate                          
    FROM #TargetSegmentStatus TPSS WITH (NOLOCK)                          
    INNER JOIN #SourceProjectSegmentStatus SPSS WITH (NOLOCK)                          
     ON TPSS.SegmentStatusCode = SPSS.SegmentStatusCode                          
      AND SPSS.SectionId = @SourceSectionId                          
    INNER JOIN SLCMaster..SegmentChoice SrcMSC WITH (NOLOCK)                          
     ON TPSS.mSegmentId = SrcMSC.SegmentId                          
    WHERE TPSS.SectionId = @TargetSectionId          
    AND SPSS.SegmentOrigin = 'M'                          
    AND @IsSectionOpen = 1)          
    UNION                          
    (SELECT                          
     @TargetSectionId AS SectionId                          
    ,TPSS.SegmentStatusId AS SegmentStatusId                          
    ,TPSS.SegmentId AS SegmentId                          
    ,SrcPSC.ChoiceTypeId AS ChoiceTypeId                          
    ,@TargetProjectId AS ProjectId                          
    ,@CustomerId AS CustomerId                          
    ,'U' AS SegmentChoiceSource                          
    ,SrcPSC.SegmentChoiceCode AS SegmentChoiceCode                          
    ,@UserId AS CreatedBy                          
    ,GETUTCDATE() AS CreateDate                          
    ,@UserId AS ModifiedBy                          
    ,GETUTCDATE() AS ModifiedDate                          
    FROM #TargetSegmentStatus TPSS WITH (NOLOCK)                          
    INNER JOIN #SourceProjectSegmentStatus SPSS WITH (NOLOCK)                          
     ON TPSS.SegmentStatusCode = SPSS.SegmentStatusCode                          
      AND SPSS.SectionId = @SourceSectionId                          
    INNER JOIN ProjectSegmentChoice SrcPSC WITH (NOLOCK)                          
     ON SPSS.SegmentId = SrcPSC.SegmentId                          
    WHERE TPSS.SectionId = @TargetSectionId                          
    AND SPSS.SegmentOrigin = 'U'                          
    AND @IsSectionOpen = 1)          
     END          
          
     BEGIN -- Insert options from source to target section ProjectChoiceOption          
   INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson,                          
   ProjectId, SectionId, CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)                          
    (SELECT                          
    PCH.SegmentChoiceId AS SegmentChoiceId,          
    SrcMCO.SortOrder AS SortOrder                          
    ,'U' AS ChoiceOptionSource              
    ,SrcMCO.OptionJson AS OptionJson             
    ,@TargetProjectId AS ProjectId                          
    ,@TargetSectionId AS SectionId                          
    ,@CustomerId AS CustomerId                          
    ,SrcMCO.ChoiceOptionCode AS ChoiceOptionCode                          
    ,@UserId AS CreatedBy                          
    ,GETUTCDATE() AS CreateDate          
    ,@UserId AS ModifiedBy          
    ,GETUTCDATE() AS ModifiedDate          
    FROM #TargetSegmentStatus TPSS WITH (NOLOCK)                          
    INNER JOIN SLCMaster..SegmentChoice SrcMSC WITH (NOLOCK)                          
    ON TPSS.mSegmentId = SrcMSC.SegmentId AND SrcMSC.SectionId = @SourceMSectionId                        
    INNER JOIN SLCMaster..ChoiceOption SrcMCO WITH (NOLOCK)                          
    ON SrcMSC.SegmentChoiceId = SrcMCO.SegmentChoiceId                          
    INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)                          
    ON TPSS.SegmentId = PCH.SegmentId                
    AND SrcMSC.SegmentChoiceCode = PCH.SegmentChoiceCode                          
    WHERE TPSS.SectionId = @TargetSectionId                          
    AND @IsSectionOpen = 0)                         
    UNION          
    (SELECT                          
    PCH.SegmentChoiceId AS SegmentChoiceId                          
    ,SrcMCO.SortOrder AS SortOrder                          
    ,'U' AS ChoiceOptionSource                          
    ,SrcMCO.OptionJson AS OptionJson                          
    ,@TargetProjectId AS ProjectId                          
    ,@TargetSectionId AS SectionId                          
    ,@CustomerId AS CustomerId                          
    ,SrcMCO.ChoiceOptionCode AS ChoiceOptionCode                          
    ,@UserId AS CreatedBy                          
    ,GETUTCDATE() AS CreateDate                          
    ,@UserId AS ModifiedBy                          
    ,GETUTCDATE() AS ModifiedDate                          
    FROM #TargetSegmentStatus TPSS WITH (NOLOCK)                          
    INNER JOIN #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)                          
    ON TPSS.SegmentStatusCode = SrcPSS.SegmentStatusCode                          
    AND SrcPSS.SectionId = @SourceSectionId                          
    INNER JOIN SLCMaster..SegmentChoice SrcMSC WITH (NOLOCK)                          
    ON TPSS.mSegmentId = SrcMSC.SegmentId                          
    INNER JOIN SLCMaster..ChoiceOption SrcMCO WITH (NOLOCK)                          
    ON SrcMSC.SegmentChoiceId = SrcMCO.SegmentChoiceId                          
    INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)                          
    ON TPSS.SegmentId = PCH.SegmentId                          
    AND SrcMSC.SegmentChoiceCode = PCH.SegmentChoiceCode                          
    WHERE TPSS.SectionId = @TargetSectionId                          
    AND SrcPSS.SegmentOrigin = 'M'                          
    AND @IsSectionOpen = 1)          
    UNION                          
    (SELECT                          
    PCH.SegmentChoiceId AS SegmentChoiceId                          
    ,SrcPCO.SortOrder AS SortOrder                          
    ,'U' AS ChoiceOptionSource                          
    ,SrcPCO.OptionJson AS OptionJson                          
    ,@TargetProjectId AS ProjectId                          
    ,@TargetSectionId AS SectionId                          
    ,@CustomerId AS CustomerId                          
    ,SrcPCO.ChoiceOptionCode AS ChoiceOptionCode                          
    ,@UserId AS CreatedBy                          
    ,GETUTCDATE() AS CreateDate                          
    ,@UserId AS ModifiedBy                          
    ,GETUTCDATE() AS ModifiedDate                          
    FROM #TargetSegmentStatus TPSS WITH (NOLOCK)                          
    INNER JOIN #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)                          
    ON TPSS.SegmentStatusCode = SrcPSS.SegmentStatusCode                          
    AND SrcPSS.SectionId = @SourceSectionId                          
    INNER JOIN ProjectSegmentChoice SrcPSC WITH (NOLOCK)                          
    ON SrcPSS.SegmentId = SrcPSC.SegmentId                          
    INNER JOIN ProjectChoiceOption SrcPCO WITH (NOLOCK)                          
    ON SrcPSC.SegmentChoiceId = SrcPCO.SegmentChoiceId                          
    INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)                          
    ON TPSS.SegmentId = PCH.SegmentId                          
    AND SrcPSC.SegmentChoiceCode = PCH.SegmentChoiceCode                          
    WHERE TPSS.SectionId = @TargetSectionId                          
    AND SrcPSS.SegmentOrigin = 'U'                   
    AND @IsSectionOpen = 1)          
     END          
          
     BEGIN -- Insert selected choice options from source to target          
   INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource,                          
   IsSelected, SectionId, ProjectId, CustomerId, OptionJson)                          
    (SELECT                          
     SrcMSC.SegmentChoiceCode AS SegmentChoiceCode                          
    ,SrcMCO.ChoiceOptionCode AS ChoiceOptionCode                          
    ,'U' AS ChoiceOptionSource                          
    ,SrcMSCO.IsSelected AS IsSelected                          
    ,@TargetSectionId AS SectionId                          
    ,@TargetProjectId AS ProjectId                          
    ,@CustomerId AS CustomerId                          
    ,NULL AS OptionJson                          
    FROM #TargetSegmentStatus TrgPSS WITH (NOLOCK)                          
    INNER JOIN SLCMaster..SegmentChoice SrcMSC WITH (NOLOCK)                          
     ON TrgPSS.MSegmentId = SrcMSC.SegmentId AND SrcMSC.SectionId = @SourceMSectionId                          
    INNER JOIN SLCMaster..ChoiceOption SrcMCO WITH (NOLOCK)                          
     ON SrcMSC.SegmentChoiceId = SrcMCO.SegmentChoiceId                          
    INNER JOIN SLCMaster..SelectedChoiceOption SrcMSCO WITH (NOLOCK)                          
     ON SrcMSC.SegmentChoiceCode = SrcMSCO.SegmentChoiceCode                          
      AND SrcMCO.ChoiceOptionCode = SrcMSCO.ChoiceOptionCode                          
    WHERE TrgPSS.SectionId = @TargetSectionId                          
    AND @IsSectionOpen = 0)          
    UNION                          
    (SELECT                          
     SrcMSC.SegmentChoiceCode AS SegmentChoiceCode                          
    ,SrcMCO.ChoiceOptionCode AS ChoiceOptionCode                          
    ,'U' AS ChoiceOptionSource                          
    ,SrcMSCO.IsSelected AS IsSelected                          
    ,@TargetSectionId AS SectionId                          
    ,@TargetProjectId AS ProjectId                          
    ,@CustomerId AS CustomerId                          
    ,SrcMSCO.OptionJson AS OptionJson                          
    FROM #TargetSegmentStatus PSST WITH (NOLOCK)                          
    INNER JOIN #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)                          
     ON PSST.SegmentStatusCode = SrcPSS.SegmentStatusCode                          
      AND SrcPSS.SectionId = @SourceSectionId                          
    INNER JOIN SLCMaster..SegmentChoice SrcMSC WITH (NOLOCK)                          
     ON PSST.mSegmentId = SrcMSC.SegmentId                          
    INNER JOIN SLCMaster..ChoiceOption SrcMCO WITH (NOLOCK)                          
     ON SrcMSC.SegmentChoiceId = SrcMCO.SegmentChoiceId                          
    INNER JOIN SelectedChoiceOption SrcMSCO WITH (NOLOCK)                          
     ON SrcMSC.SegmentChoiceCode = SrcMSCO.SegmentChoiceCode                          
      AND SrcMCO.ChoiceOptionCode = SrcMSCO.ChoiceOptionCode                          
      AND SrcMSCO.ChoiceOptionSource = 'M'                          
      AND SrcMSCO.SectionId = @SourceSectionId                          
    WHERE PSST.SectionId = @TargetSectionId                          
    AND SrcPSS.SegmentOrigin = 'M'                          
    AND @IsSectionOpen = 1)                       
    UNION                          
    (SELECT                          
     SrcPSC.SegmentChoiceCode AS SegmentChoiceCode                          
    ,SrcPCO.ChoiceOptionCode AS ChoiceOptionCode                          
    ,'U' AS ChoiceOptionSource                          
    ,SrcMSCO.IsSelected AS IsSelected                          
    ,@TargetSectionId AS SectionId                          
    ,@TargetProjectId AS ProjectId                          
    ,@CustomerId AS CustomerId                          
    ,SrcMSCO.OptionJson AS OptionJson                          
    FROM #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)                          
    INNER JOIN ProjectSegmentChoice SrcPSC WITH (NOLOCK)                          
     ON SrcPSS.SegmentId = SrcPSC.SegmentId                          
    INNER JOIN ProjectChoiceOption SrcPCO WITH (NOLOCK)                          
     ON SrcPSC.SegmentChoiceId = SrcPCO.SegmentChoiceId                          
    INNER JOIN SelectedChoiceOption SrcMSCO WITH (NOLOCK)                          
     ON SrcPSC.SegmentChoiceCode = SrcMSCO.SegmentChoiceCode                          
      AND SrcPCO.ChoiceOptionCode = SrcMSCO.ChoiceOptionCode                          
      AND SrcMSCO.ChoiceOptionSource = 'U'                          
      AND SrcMSCO.SectionId = @SourceSectionId                          
    WHERE SrcPSS.SectionId = @SourceSectionId                          
    AND SrcPSS.SegmentOrigin = 'U'          
    AND @IsSectionOpen = 1)          
     END          
          
     BEGIN -- Add records into ProjectSegmentLink          
     DROP TABLE IF EXISTS #ProjectSegmentLinkTemp;    
		 CREATE TABLE #ProjectSegmentLinkTemp  
		 (  
		SourceSectionCode int,  
		SourceSegmentStatusCode int,  
		SourceSegmentCode int,  
		SourceSegmentChoiceCode int,  
		SourceChoiceOptionCode int,  
		LinkSource varchar,  
		TargetSectionCode int,  
		TargetSegmentStatusCode int,  
		TargetSegmentCode int,  
		TargetSegmentChoiceCode int,  
		TargetChoiceOptionCode int,  
		LinkTarget varchar,  
		LinkStatusTypeId int,  
		IsDeleted bit,  
		CreateDate datetime2,  
		CreatedBy int,  
		ModifiedBy int,  
		ModifiedDate datetime2,  
		ProjectId int,  
		CustomerId int,  
		SegmentLinkCode int,  
		SegmentLinkSourceTypeId int,  
		 )  
   IF(@IsSectionOpen = 0)  
   BEGIN  
        INSERT INTO #ProjectSegmentLinkTemp  
     SELECT  
    (CASE WHEN MSLNK.SourceSectionCode = @SourceSectionCode THEN @TargetSectionCode  ELSE MSLNK.SourceSectionCode END) AS SourceSectionCode  
    ,MSLNK.SourceSegmentStatusCode AS SourceSegmentStatusCode  
    ,MSLNK.SourceSegmentCode AS SourceSegmentCode  
    ,MSLNK.SourceSegmentChoiceCode AS SourceSegmentChoiceCode  
    ,MSLNK.SourceChoiceOptionCode AS SourceChoiceOptionCode  
    ,(CASE  
    WHEN MSLNK.SourceSectionCode = @SourceSectionCode THEN 'U'  
    ELSE MSLNK.LinkSource  
    END) AS LinkSource  
    ,(CASE  WHEN MSLNK.TargetSectionCode = @SourceSectionCode THEN @TargetSectionCode  ELSE MSLNK.TargetSectionCode  END) AS TargetSectionCode  
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
    ,@UserId AS CreatedBy  
    ,@UserId AS ModifiedBy  
    ,GETUTCDATE() AS ModifiedDate  
    ,@TargetProjectId AS ProjectId  
    ,@CustomerId AS CustomerId  
    ,MSLNK.SegmentLinkCode as SegmentLinkCode  
    ,(CASE  
    WHEN MSLNK.SegmentLinkSourceTypeId = 1 THEN 5  
    ELSE MSLNK.SegmentLinkSourceTypeId  
    END) AS SegmentLinkSourceTypeId --INTO #ProjectSegmentLinkTemp  
    FROM SLCMaster..SegmentLink MSLNK WITH (NOLOCK)  
    WHERE (MSLNK.SourceSectionCode = @SourceSectionCode  
    OR MSLNK.TargetSectionCode = @SourceSectionCode)  
    AND MSLNK.IsDeleted = 0  
    AND MSLNK.SourceSectionCode = @SourceSectionCode AND @IsSectionOpen = 0   
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
        ,(CASE WHEN PSL.SegmentLinkSourceTypeId = 1 THEN 5 ELSE PSL.SegmentLinkSourceTypeId  
         END) AS SegmentLinkSourceTypeId                
   FROM ProjectSegmentLink PSL WITH (NOLOCK)        
   WHERE PSL.ProjectId = @SourceProjectId        
   AND (PSL.SourceSectionCode = @SourceSectionCode OR PSL.TargetSectionCode = @SourceSectionCode)        
   AND PSL.CustomerId = @CustomerId        
   AND ISNULL(PSL.IsDeleted, 0) = 0       
   AND PSL.SourceSectionCode = @SourceSectionCode AND @IsSectionOpen = 1  
   END  
                
   --INSERT ProjectSegmentLink                                
   INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,                
   TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget,                
   LinkStatusTypeId, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId,                
   SegmentLinkCode, SegmentLinkSourceTypeId)                
    SELECT        
     (CASE WHEN SrcPSL.SourceSectionCode = @SourceSectionCode THEN @TargetSectionCode ELSE SrcPSL.SourceSectionCode END) AS SourceSectionCode            
    ,SrcPSL.SourceSegmentStatusCode                
    ,SrcPSL.SourceSegmentCode                
    ,SrcPSL.SourceSegmentChoiceCode                
    ,SrcPSL.SourceChoiceOptionCode                
    ,(CASE WHEN SrcPSL.SourceSectionCode = @SourceSectionCode THEN 'U' ELSE SrcPSL.LinkSource END) AS LinkSource        
    ,(CASE WHEN SrcPSL.TargetSectionCode = @SourceSectionCode THEN @TargetSectionCode ELSE SrcPSL.TargetSectionCode END) AS TargetSectionCode        
    ,SrcPSL.TargetSegmentStatusCode        
    ,SrcPSL.TargetSegmentCode                
    ,SrcPSL.TargetSegmentChoiceCode                
    ,SrcPSL.TargetChoiceOptionCode                
    ,(CASE WHEN (SrcPSL.SourceSectionCode = @SourceSectionCode AND SrcPSL.TargetSectionCode = @SourceSectionCode AND @IsSectionOpen=1) THEN 'U' ELSE SrcPSL.LinkTarget END) AS LinkTarget                
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
       END        
          
     BEGIN -- Add record into ProjectDisciplineSection          
    INSERT INTO ProjectDisciplineSection (SectionId, Disciplineld, ProjectId, CustomerId, IsActive)     
    SELECT                          
     @TargetSectionId AS SectionId                          
    ,MDS.DisciplineId AS Disciplineld                          
    ,@TargetProjectId AS ProjectId                          
    ,@CustomerId AS CustomerId                 
    ,1 AS IsActive                          
    FROM SLCMaster..DisciplineSection MDS WITH (NOLOCK)                          
    INNER JOIN LuProjectDiscipline LPD WITH (NOLOCK)                          
    ON MDS.DisciplineId = LPD.Disciplineld                          
    WHERE MDS.SectionId = @SourceMSectionId          
     END          
          
     BEGIN -- Insert Project and Master notes          
    INSERT INTO ProjectNote (SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId,                
    CustomerId, Title, CreatedBy, ModifiedBy, CreatedUserName, ModifiedUserName, IsDeleted, NoteCode)                          
     SELECT                          
      @TargetSectionId AS SectionId          
     ,TrgPSS.SegmentStatusId AS SegmentStatusId          
     ,SrcMN.NoteText AS NoteText          
     ,GETUTCDATE() AS CreateDate                          
     ,GETUTCDATE() AS ModifiedDate                          
     ,@TargetProjectId AS ProjectId                          
     ,@CustomerId AS CustomerId                          
     ,'' AS Title                          
     ,@UserId AS CreatedBy                          
     ,@UserId AS ModifiedBy                          
     ,@UserName AS CreatedUserName                          
     ,@UserName AS ModifiedUserName                          
     ,0 AS IsDeleted                          
     ,SrcMN.NoteId AS NoteCode                          
     FROM SLCMaster..Note SrcMN WITH (NOLOCK)                          
     INNER JOIN #TargetSegmentStatus TrgPSS WITH (NOLOCK)                          
      ON SrcMN.SegmentStatusId = TrgPSS.mSegmentStatusId          
     WHERE SrcMN.SectionId = @SourceMSectionId          
     AND TrgPSS.SectionId = @TargetSectionId                          
     UNION          
     SELECT          
      @TargetSectionId AS SectionId                          
     ,TrgPSS.SegmentStatusId AS SegmentStatusId                          
     ,SrcPN.NoteText AS NoteText                          
     ,GETUTCDATE() AS CreateDate                          
     ,GETUTCDATE() AS ModifiedDate                          
     ,@TargetProjectId AS ProjectId                          
     ,@CustomerId AS CustomerId                          
     ,SrcPN.Title AS Title                          
     ,@UserId AS CreatedBy                          
     ,@UserId AS ModifiedBy                          
     ,@UserName AS CreatedUserName                          
     ,@UserName AS ModifiedUserName                          
     ,0 AS IsDeleted                          
     ,SrcPN.NoteCode AS NoteCode                          
     FROM ProjectNote SrcPN WITH (NOLOCK)                          
     INNER JOIN #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)                          
      ON SrcPN.SegmentStatusId = SrcPSS.SegmentStatusId                          
     INNER JOIN #TargetSegmentStatus TrgPSS WITH (NOLOCK)          
      ON SrcPSS.SegmentStatusCode = TrgPSS.SegmentStatusCode                          
       AND TrgPSS.SectionId = @TargetSectionId                          
     WHERE SrcPN.SectionId = @SourceSectionId           
     END          
          
     BEGIN -- Insert records into ProjectSegmentRequirementTag          
   INSERT INTO ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId,                          
   CreateDate, ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy)                          
    SELECT                          
     @TargetSectionId AS SectionId                          
    ,PSST.SegmentStatusId AS SegmentStatusId                          
    ,MSRT_Template.RequirementTagId AS RequirementTagId                          
    ,GETUTCDATE() AS CreateDate                          
    ,GETUTCDATE() AS ModifiedDate                          
    ,@TargetProjectId AS ProjectId                          
    ,@CustomerId AS CustomerId                          
    ,@UserId AS CreatedBy                          
    ,@UserId AS ModifiedBy                          
    FROM SLCMaster..SegmentRequirementTag MSRT_Template WITH (NOLOCK)                          
    INNER JOIN #TargetSegmentStatus PSST WITH (NOLOCK)                          
    ON MSRT_Template.SegmentStatusId = PSST.mSegmentStatusId                          
    WHERE MSRT_Template.SectionId = @SourceMSectionId                          
    AND PSST.SectionId = @TargetSectionId                          
    AND @IsSectionOpen = 0                         
    UNION                          
    SELECT                          
     @TargetSectionId AS SectionId                          
    ,PSST.SegmentStatusId AS SegmentStatusId                          
    ,PSRT_Template.RequirementTagId AS RequirementTagId                          
    ,GETUTCDATE() AS CreateDate                          
    ,GETUTCDATE() AS ModifiedDate                          
    ,@TargetProjectId AS ProjectId                          
    ,@CustomerId AS CustomerId                          
    ,@UserId AS CreatedBy                          
    ,@UserId AS ModifiedBy                          
    FROM ProjectSegmentRequirementTag PSRT_Template WITH (NOLOCK)                          
    INNER JOIN #SourceProjectSegmentStatus PSST_Template WITH (NOLOCK)                          
    ON PSRT_Template.SegmentStatusId = PSST_Template.SegmentStatusId                          
    INNER JOIN #TargetSegmentStatus PSST WITH (NOLOCK)                          
    ON PSST_Template.SegmentStatusCode = PSST.SegmentStatusCode                          
    AND PSST.SectionId = @TargetSectionId                          
    WHERE PSRT_Template.SectionId = @SourceSectionId                          
    AND @IsSectionOpen = 1          
     END          
          
     BEGIN -- Insert records into ProjectSegmentUserTag          
   IF(@IsSectionOpen = 1)          
   BEGIN          
    INSERT INTO ProjectSegmentUserTag (CustomerId, ProjectId, SectionId, SegmentStatusId,                          
    UserTagId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)                          
     SELECT                          
      @CustomerId AS CustomerId                          
     ,@TargetProjectId AS ProjectId                          
     ,@TargetSectionId AS SectionId                          
     ,TrgPSS.SegmentStatusId AS SegmentStatusId                          
     ,SrcPSUT.UserTagId AS UserTagId                          
     ,GETUTCDATE() AS CreateDate                          
     ,@UserId AS CreatedBy                          
     ,GETUTCDATE() AS ModifiedDate                          
     ,@UserId AS ModifiedBy                  
     FROM ProjectSegmentUserTag SrcPSUT WITH (NOLOCK)                          
     INNER JOIN #SourceProjectSegmentStatus SrcPSS WITH (NOLOCK)                          
      ON SrcPSUT.SegmentStatusId = SrcPSS.SegmentStatusId                          
     INNER JOIN #TargetSegmentStatus TrgPSS WITH (NOLOCK)                          
      ON SrcPSS.SegmentStatusCode = TrgPSS.SegmentStatusCode          
    AND TrgPSS.SectionId = @TargetSectionId                          
     WHERE SrcPSUT.SectionId = @SourceSectionId                          
    END          
     END          
          
     BEGIN -- Insert records into ProjectSegmentGlobalTerm          
     INSERT INTO ProjectSegmentGlobalTerm (CustomerId, ProjectId, SectionId, SegmentId, mSegmentId,                          
     UserGlobalTermId, GlobalTermCode, IsLocked, LockedByFullName, UserLockedId, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy)                          
   SELECT                          
    @CustomerId AS CustomerId                          
   ,@TargetProjectId AS ProjectId                          
   ,@TargetSectionId AS SectionId                          
   ,PSG.SegmentId AS SegmentId                          
   ,NULL AS mSegmentId                          
   ,SrcPSGT.UserGlobalTermId AS UserGlobalTermId                          
   ,SrcPSGT.GlobalTermCode AS GlobalTermCode                          
   ,SrcPSGT.IsLocked AS IsLocked                          
   ,SrcPSGT.LockedByFullName AS LockedByFullName                          
   ,SrcPSGT.UserLockedId AS UserLockedId                     
   ,GETUTCDATE() AS CreatedDate                          
   ,@UserId AS CreatedBy                          
   ,GETUTCDATE() AS ModifiedDate                          
   ,@UserId AS ModifiedBy                          
   FROM ProjectSegmentGlobalTerm SrcPSGT WITH (NOLOCK)                          
   INNER JOIN #SourceProjectSegment SrcPS WITH (NOLOCK)                          
    ON SrcPSGT.SegmentId = SrcPS.SegmentId                          
   INNER JOIN ProjectSegment PSG WITH (NOLOCK)          
    ON SrcPS.SegmentCode = PSG.SegmentCode                          
     AND PSG.SectionId = @TargetSectionId                          
   WHERE SrcPSGT.SectionId = @SourceSectionId                
          
     END          
          
     BEGIN --Insert  records into ProjectSegmentImage          
   INSERT INTO ProjectSegmentImage (SectionId, ImageId, ProjectId, CustomerId, SegmentId,ImageStyle)          
    SELECT          
     @TargetSectionId AS SectionId                          
    ,SrcPSI.ImageId AS ImageId                          
    ,@TargetProjectId AS ProjectId                          
    ,@CustomerId AS CustomerId                          
    ,TrgPS.SegmentId AS SegmentId              
    ,SrcPSI.ImageStyle          
    FROM ProjectSegmentImage SrcPSI WITH (NOLOCK)                          
    INNER JOIN #SourceProjectSegment SrcPS WITH (NOLOCK)                          
     ON SrcPSI.SegmentId = SrcPS.SegmentId                          
    INNER JOIN ProjectSegment TrgPS WITH (NOLOCK)                          
     ON SrcPS.SegmentCode = TrgPS.SegmentCode                          
      AND TrgPS.SectionId = @TargetSectionId                          
    WHERE SrcPSI.SectionId = @SourceSectionId                          
    UNION                          
    SELECT                          
     @TargetSectionId AS SectionId                          
    ,SrcPSI.ImageId AS ImageId                          
    ,@TargetProjectId AS ProjectId                          
    ,@CustomerId AS CustomerId                          
    ,SrcPSI.SegmentId AS SegmentId            
    ,SrcPSI.ImageStyle          
    FROM ProjectSegmentImage SrcPSI WITH (NOLOCK)                          
    WHERE SrcPSI.SectionId = @SourceSectionId                          
    AND (SrcPSI.SegmentId IS NULL          
    OR SrcPSI.SegmentId <= 0)          
     END          
          
     BEGIN -- Insert records into ProjectHyperLink          
        print('Copy Hyperlinks');          
  --- INSERT ProjectHyperLink                
  INSERT INTO ProjectHyperLink (SectionId, SegmentId, SegmentStatusId, ProjectId, CustomerId, LinkTarget, LinkText,  
  LuHyperLinkSourceTypeId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy,A_HyperLinkId)  
   SELECT  
    @TargetSectionId AS SectionId  
   ,PSST.SegmentId AS SegmentId  
   ,PSST.SegmentStatusId AS SegmentStatusId  
   ,@TargetProjectId AS ProjectId           
   ,@CustomerId as CustomerId  
   ,MHL_Template.LinkTarget AS LinkTarget  
   ,MHL_Template.LinkText AS LinkText  
   ,MHL_Template.LuHyperLinkSourceTypeId AS LuHyperLinkSourceTypeId  
   ,GETUTCDATE() AS CreateDate  
   ,@UserId AS CreatedBy  
   ,GETUTCDATE() AS ModifiedDate  
   ,@UserId AS ModifiedBy  
   ,MHL_Template.HyperLinkId AS HyperLinkId  
   FROM SLCMaster..Note MNT_Template WITH (NOLOCK)  
   INNER JOIN SLCMaster..HyperLink MHL_Template WITH (NOLOCK)  
   ON MNT_Template.SegmentStatusId = MHL_Template.SegmentStatusId  
   INNER JOIN #TargetSegmentStatus PSST WITH (NOLOCK)  
   ON MNT_Template.SegmentStatusId = PSST.SegmentStatusCode  
   AND PSST.SectionId = @TargetSectionId  
   WHERE MNT_Template.SectionId = @SourceMSectionId           
                
   -- --Fetch Src Master notes into temp table  
   --SELECT  
   -- * INTO #tmp_SrcMasterNote  
   --FROM SLCMaster..Note WITH (NOLOCK)  
   --WHERE SectionId = @SourceMSectionId;  
  
   ----Fetch tgt project notes into temp table  
   --SELECT  
   -- * INTO #tmp_TgtProjectNote  
   --FROM ProjectNote PNT WITH (NOLOCK)  
   --WHERE SectionId = @TargetSectionId;  
  
   ----UPDATE NEW HyperLinkId IN NoteText  
   --DECLARE @HyperLinkLoopCount INT = 1;  
   --DECLARE @HyperLinkTable TABLE (  
   -- RowId INT  
   --   ,HyperLinkId INT  
   --   ,MasterHyperLinkId INT  
   --);  
  
   --INSERT INTO @HyperLinkTable (RowId, HyperLinkId, MasterHyperLinkId)  
   -- SELECT  
   --  ROW_NUMBER() OVER (ORDER BY PHL.HyperLinkId ASC) AS RowId         
   -- ,PHL.HyperLinkId  
   -- ,PHL.A_HyperLinkId  
   -- FROM ProjectHyperLink PHL WITH (NOLOCK)  
   -- WHERE PHL.SectionId = @TargetSectionId;  
  
   --declare @HyperLinkTableRowCount INT=(SELECT  COUNT(*)  FROM @HyperLinkTable)  
   --WHILE (@HyperLinkLoopCount <= @HyperLinkTableRowCount)  
   --BEGIN  
   --DECLARE @HyperLinkId INT = 0;  
   --DECLARE @MasterHyperLinkId INT = 0;  
  
   --SELECT  
   -- @HyperLinkId = HyperLinkId  
   --   ,@MasterHyperLinkId = MasterHyperLinkId  
   --FROM @HyperLinkTable  
   --WHERE RowId = @HyperLinkLoopCount;  
  
   --UPDATE PNT  
   --SET PNT.NoteText =  
   --REPLACE(PNT.NoteText, '{HL#' + CAST(@MasterHyperLinkId AS NVARCHAR(MAX)) + '}',  
   --'{HL#' + CAST(@HyperLinkId AS NVARCHAR(MAX)) + '}')  
   --FROM #tmp_SrcMasterNote MNT_Template WITH (NOLOCK)  
   --INNER JOIN #TargetSegmentStatus PSST WITH (NOLOCK)  
   -- ON MNT_Template.SegmentStatusId = PSST.SegmentStatusCode       
   -- AND PSST.SectionId = @TargetSectionId  
   --INNER JOIN #tmp_TgtProjectNote PNT WITH (NOLOCK)  
   -- ON PSST.SegmentStatusId = PNT.SegmentStatusId  
   --WHERE MNT_Template.SectionId = @SourceMSectionId  
  
   --SET @HyperLinkLoopCount = @HyperLinkLoopCount + 1;  
   --END  
  
   ----Update NoteText back into original table from temp table  
   --UPDATE PNT  
   --SET PNT.NoteText = TMP.NoteText  
   --FROM ProjectNote PNT WITH (NOLOCK)  
   --INNER JOIN #tmp_TgtProjectNote TMP WITH (NOLOCK)  
   -- ON PNT.NoteId = TMP.NoteId  
   --WHERE PNT.SectionId = @TargetSectionId;  
   END          
          
     BEGIN -- Insert records into ProjectNoteImage          
   INSERT INTO ProjectNoteImage (NoteId, SectionId, ImageId, ProjectId, CustomerId)                          
    SELECT                          
     PN.NoteId AS NoteId                          
    ,@TargetSectionId AS SectionId                          
    ,SrcPNI.ImageId AS ImageId                          
    ,@TargetProjectId AS ProjectId                          
    ,@CustomerId AS CustomerId                          
    FROM ProjectNoteImage SrcPNI WITH (NOLOCK)                          
    INNER JOIN ProjectNote SrcPN WITH (NOLOCK)                          
     ON SrcPNI.NoteId = SrcPN.NoteId                          
    INNER JOIN ProjectNote PN WITH (NOLOCK)                          
     ON SrcPN.NoteCode = PN.NoteCode                          
      AND PN.SectionId = @TargetSectionId          
    WHERE SrcPNI.SectionId = @SourceSectionId          
     END          
          
     BEGIN -- Insert records into Header          
   INSERT INTO Header ([ProjectId],[SectionId],[CustomerId],[Description],[IsLocked],          
   [LockedByFullName],[LockedBy],[ShowFirstPage],[CreatedBy],[CreatedDate],[ModifiedBy],          
   [ModifiedDate],[TypeId],[AltHeader],[FPHeader],[UseSeparateFPHeader],[HeaderFooterCategoryId],          
   [DateFormat],[TimeFormat],[HeaderFooterDisplayTypeId],[DefaultHeader],[FirstPageHeader],          
   [OddPageHeader],[EvenPageHeader],[DocumentTypeId],[IsShowLineAboveHeader],[IsShowLineBelowHeader])          
    SELECT                          
     @TargetProjectId AS ProjectId                          
    ,@TargetSectionId AS SectionId                          
    ,@CustomerId AS CustomerId                          
    ,[Description]                          
    ,NULL AS IsLocked                          
    ,NULL AS LockedByFullName                          
    ,NULL AS LockedBy                          
    ,ShowFirstPage                          
    ,@UserId AS CreatedBy                          
    ,GETUTCDATE() AS CreatedDate                          
    ,@UserId AS ModifiedBy                          
    ,GETUTCDATE() AS ModifiedDate                          
    ,TypeId                          
    ,AltHeader          
    ,FPHeader          
    ,UseSeparateFPHeader                          
    ,HeaderFooterCategoryId                          
    ,[DateFormat]          
    ,TimeFormat          
    ,HeaderFooterDisplayTypeId          
    ,DefaultHeader          
    ,FirstPageHeader          
    ,OddPageHeader          
    ,EvenPageHeader          
    ,DocumentTypeId          
    ,IsShowLineAboveHeader          
    ,IsShowLineBelowHeader          
    FROM Header WITH (NOLOCK)          
    WHERE SectionId = @SourceSectionId          
     END          
          
     BEGIN -- Insert records into Footer          
   INSERT INTO Footer ([ProjectId],[SectionId],[CustomerId],[Description],[IsLocked],          
   [LockedByFullName],[LockedBy],[ShowFirstPage],[CreatedBy],[CreatedDate],[ModifiedBy],          
   [ModifiedDate],[TypeId],[AltFooter],[FPFooter],[UseSeparateFPFooter],[HeaderFooterCategoryId],          
   [DateFormat],[TimeFormat],[HeaderFooterDisplayTypeId],[DefaultFooter],[FirstPageFooter],          
   [OddPageFooter],[EvenPageFooter],[DocumentTypeId],[IsShowLineAboveFooter],[IsShowLineBelowFooter])          
    SELECT                          
     @TargetProjectId AS ProjectId                          
    ,@TargetSectionId AS SectionId                          
    ,@CustomerId AS CustomerId                          
    ,[Description]                          
    ,NULL AS IsLocked                          
    ,NULL AS LockedByFullName                          
    ,NULL AS LockedBy                          
    ,ShowFirstPage                          
    ,@UserId AS CreatedBy                          
    ,GETUTCDATE() AS CreatedDate                          
    ,@UserId AS ModifiedBy                          
    ,GETUTCDATE() AS ModifiedDate                          
    ,TypeId                          
    ,AltFooter                          
    ,FPFooter                          
    ,UseSeparateFPFooter                          
    ,HeaderFooterCategoryId                          
    ,[DateFormat]          
    ,TimeFormat          
    ,HeaderFooterDisplayTypeId          
    ,DefaultFooter          
    ,FirstPageFooter          
    ,OddPageFooter          
    ,EvenPageFooter          
    ,DocumentTypeId          
    ,IsShowLineAboveFooter          
    ,IsShowLineBelowFooter          
    FROM Footer WITH (NOLOCK)                          
    WHERE SectionId = @SourceSectionId                      
     END          
          
     BEGIN -- Insert records into ProjectSegmentReferenceStandard          
   INSERT INTO [dbo].[ProjectSegmentReferenceStandard]          
     ([SectionId],[SegmentId],[RefStandardId],[RefStandardSource],[mRefStandardId],[CreateDate],          
     [CreatedBy],[ModifiedDate],[ModifiedBy],[mSegmentId],[ProjectId],[CustomerId],[RefStdCode],[IsDeleted])          
   SELECT          
   @TargetSectionId AS SectionId          
   ,TrgPSS.[SegmentId]          
   ,PSRS.[RefStandardId]          
   ,'U' AS RefStandardSource          
   ,PSRS.[mRefStandardId]          
   ,PSRS.[CreateDate]          
   ,PSRS.[CreatedBy]          
   ,PSRS.[ModifiedDate]          
   ,PSRS.[ModifiedBy]          
   ,NULL AS [mSegmentId]          
   ,@TargetProjectId AS ProjectId          
   ,@CustomerId AS CustomerId          
   ,PSRS.[RefStdCode]          
   ,PSRS.[IsDeleted]          
   FROM ProjectSegmentReferenceStandard PSRS WITH(NOLOCK)          
   INNER JOIN #SourceProjectSegmentStatus SrcPSS WITH(NOLOCK) ON SrcPSS.SegmentId = PSRS.SegmentId          
   INNER JOIN #TargetSegmentStatus TrgPSS WITH(NOLOCK) ON TrgPSS.A_SegmentStatusId = SrcPSS.SegmentStatusId          
   WHERE PSRS.SectionId = @SourceSectionId AND ISNULL(PSRS.IsDeleted,0) = 0          
   UNION          
   SELECT          
   @TargetSectionId AS SectionId          
   ,TrgPSS.[SegmentId]          
   ,MSRS.[RefStandardId]          
   ,'U' AS RefStandardSource          
   ,0 AS mRefStandardId          
   ,GETUTCDATE() AS [CreateDate]          
   ,@UserId AS [CreatedBy]          
   ,GETUTCDATE() AS [ModifiedDate]          
   ,@UserId AS [ModifiedBy]          
   ,NULL AS [mSegmentId]          
   ,@TargetProjectId AS ProjectId          
   ,@CustomerId AS CustomerId          
   ,SMRS.RefStdCode AS RefStdCode             
   ,CAST(0 AS BIT) AS IsDeleted          
   FROM SLCMaster..SegmentReferenceStandard MSRS          
   INNER JOIN SLCMaster..ReferenceStandard SMRS WITH (NOLOCK) ON MSRS.RefStandardId = SMRS.RefStdId          
   INNER JOIN #SourceProjectSegmentStatus SrcPSS WITH(NOLOCK) ON SrcPSS.mSegmentId = MSRS.SegmentId          
   INNER JOIN #TargetSegmentStatus TrgPSS WITH(NOLOCK) ON TrgPSS.A_SegmentStatusId = SrcPSS.SegmentStatusId          
   WHERE MSRS.SectionId = @SourceMSectionId          
     END          
          
     BEGIN -- Insert records into ProjectReferenceStandard          
   INSERT INTO [dbo].[ProjectReferenceStandard]([ProjectId],[RefStandardId],[RefStdSource],[mReplaceRefStdId],          
     [RefStdEditionId],[IsObsolete],[RefStdCode],[PublicationDate],[SectionId],[CustomerId],[IsDeleted])          
   SELECT           
   @TargetProjectId AS ProjectId,          
   PRS.RefStandardId,          
   PRS.RefStdSource,          
   PRS.mReplaceRefStdId,          
   PRS.RefStdEditionId,          
   PRS.IsObsolete,          
   PRS.RefStdCode,          
   PRS.PublicationDate,          
   @TargetSectionId AS SectionId,          
   @CustomerId AS CustomerId,          
   PRS.IsDeleted          
   FROM ProjectReferenceStandard PRS  WITH(NOLOCK) WHERE PRS.SectionId = @SourceSectionId          
     END          
          
     BEGIN -- Insert records into SegmentComment          
    --Copy source Comments in temp table                            
     SELECT SC.* INTO #tmp_SrcComment          
     FROM SegmentComment SC WITH (NOLOCK)                
     WHERE SC.ProjectId = @SourceProjectId                
     AND SC.SectionId  = @SourceSectionId          
     AND ISNULL(SC.IsDeleted, 0) = 0;               
          
      --Insert SegmentComment          
      INSERT INTO SegmentComment (ProjectId,SectionId,SegmentStatusId,ParentCommentId,CommentDescription,CustomerId,CreatedBy ,CreateDate           
     ,ModifiedBy ,ModifiedDate ,CommentStatusId ,IsDeleted ,userFullName,A_SegmentCommentId)          
     Select            
    @SourceProjectId          
      ,@TargetSectionId          
      ,SC_Src.SegmentStatusId          
      ,SC_Src.ParentCommentId          
      ,SC_Src.CommentDescription          
      ,SC_Src.CustomerId          
      ,SC_Src.CreatedBy          
      ,SC_Src.CreateDate          
      ,SC_Src.ModifiedBy          
      ,SC_Src.ModifiedDate          
      ,SC_Src.CommentStatusId          
      ,SC_Src.IsDeleted          
      ,SC_Src.userFullName          
      ,SC_Src.SegmentCommentId AS A_SegmentCommentId          
      FROM  #tmp_SrcComment SC_Src WITH(Nolock)          
      where SC_Src.ProjectId = @SourceProjectId           
      AND SC_Src.SectionId = @SourceSectionId          
          
      --UPDATE SegmentStatusId in TGT Comment table           
      Update SC SET SC.SegmentStatusId = PSS.SegmentStatusId          
    FROM ProjectSegmentStatus PSS WITH(Nolock)          
    Inner join SegmentComment SC  WITH(Nolock)          
    On PSS.A_SegmentStatusId = SC.SegmentStatusId           
    WHERE SC.ProjectId = @TargetProjectId          
    AND SC.SectionId=@TargetSectionId         
    AND PSS.SectionId =@TargetSectionId      
          
      SELECT SegmentCommentId ,A_SegmentCommentId INTO #NewOldCommentIdMapping                
     FROM SegmentComment SC WITH (NOLOCK)                
     WHERE SC.ProjectId = @SourceProjectId           
     AND SC.SectionId =  @TargetSectionId            
     AND ISNULL(SC.IsDeleted, 0) = 0;              
          
      --UPDATE ParentCommentId in Target Comment table           
      UPDATE TGT_TMP                
     SET TGT_TMP.ParentCommentId = NOSM.SegmentCommentId                
     FROM SegmentComment TGT_TMP WITH (NOLOCK)                
     INNER JOIN #NewOldCommentIdMapping NOSM WITH (NOLOCK)                
      ON TGT_TMP.ParentCommentId = NOSM.A_SegmentCommentId                
     WHERE TGT_TMP.ProjectId = @TargetProjectId          
     and TGT_TMP.SectionId = @TargetSectionId          
     END          
    END          
          
    BEGIN -- Update ProjectSegmentStatus and reset mSegmentStatusId and mSegmentId          
      UPDATE PSS          
      SET PSS.mSegmentStatusId = NULL, PSS.mSegmentId = NULL  
      FROM ProjectSegmentStatus PSS WITH (NOLOCK)                          
      WHERE PSS.SectionId = @TargetSectionId;          
  
     ---- Upadate SegmentDescription at sequence Number 0  
	 UPDATE PS  SET PS.SegmentDescription = @Description  FROM ProjectSegmentStatus PSS WITH (NOLOCK)  
	 INNER JOIN ProjectSegment PS WITH (NOLOCK) ON  PS.SectionId = @TargetSectionId 
	 AND PSS.SegmentId = PS.SegmentId  WHERE PSS.SectionId = @TargetSectionId AND PSS.ProjectId = @TargetProjectId AND     PSS.CustomerId = @CustomerId AND PSS.SequenceNumber = 0 AND PSS.IndentLevel = 0;  
  
    END          
    SELECT @TargetSectionId AS TargetSectionId, @IsSectionOpen AS IsSectionOpen;         
    END      
    SELECT @ErrorMessage as ErrorMessage,@TargetSectionId as TargetSectionId;      
END
GO
PRINT N'Refreshing [dbo].[usp_GetSubmittalsLog]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSubmittalsLog]';


GO
PRINT N'Refreshing [dbo].[GetSubmittals]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[GetSubmittals]';


GO
PRINT N'Refreshing [dbo].[getProjectDetailsById]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[getProjectDetailsById]';


GO
PRINT N'Refreshing [dbo].[sp_LoadUnMappedMasterSectionsToExistingProjectUpdates]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[sp_LoadUnMappedMasterSectionsToExistingProjectUpdates]';


GO
PRINT N'Refreshing [dbo].[usp_ArchivedProjectsList]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ArchivedProjectsList]';


GO
PRINT N'Refreshing [dbo].[usp_ArchiveMigratedProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ArchiveMigratedProject]';


GO
PRINT N'Refreshing [dbo].[usp_ArchiveProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ArchiveProject]';


GO
PRINT N'Refreshing [dbo].[usp_CalculateDivisionIdForUserSection]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CalculateDivisionIdForUserSection]';


GO
PRINT N'Refreshing [dbo].[usp_CheckDivisionIsAccessForImportWord]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CheckDivisionIsAccessForImportWord]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSpecDataSections]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSpecDataSections]';


GO
PRINT N'Refreshing [dbo].[usp_DataLoadMaterialSectionMapping]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DataLoadMaterialSectionMapping]';


GO
PRINT N'Refreshing [dbo].[usp_deletedMasterSectionsFromProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_deletedMasterSectionsFromProject]';


GO
PRINT N'Refreshing [dbo].[usp_DeleteMasterSection_ApplyMasterUpdate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DeleteMasterSection_ApplyMasterUpdate]';


GO
PRINT N'Refreshing [dbo].[usp_DeleteProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DeleteProject]';


GO
PRINT N'Refreshing [dbo].[usp_deleteProjectById]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_deleteProjectById]';


GO
PRINT N'Refreshing [dbo].[usp_DeleteProjectID]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DeleteProjectID]';


GO
PRINT N'Refreshing [dbo].[usp_DeleteProjectPermanent]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DeleteProjectPermanent]';


GO
PRINT N'Refreshing [dbo].[usp_DeleteUserTemplate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DeleteUserTemplate]';


GO
PRINT N'Refreshing [dbo].[usp_GetArchievedProjects]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetArchievedProjects]';


GO
PRINT N'Refreshing [dbo].[usp_GetCopyProjectProgress]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetCopyProjectProgress]';


GO
PRINT N'Refreshing [dbo].[usp_GetCopyProjectRequest]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetCopyProjectRequest]';


GO
PRINT N'Refreshing [dbo].[usp_GetCoverSheetDetails]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetCoverSheetDetails]';


GO
PRINT N'Refreshing [dbo].[usp_getDeletedMasterSections]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getDeletedMasterSections]';


GO
PRINT N'Refreshing [dbo].[usp_getDisciplineSectionId]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getDisciplineSectionId]';


GO
PRINT N'Refreshing [dbo].[usp_GetDivisionsAndSectionsForPrint]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetDivisionsAndSectionsForPrint]';


GO
PRINT N'Refreshing [dbo].[usp_GetFilteredCopyProjectDetails]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetFilteredCopyProjectDetails]';


GO
PRINT N'Refreshing [dbo].[usp_getGTDateFormat]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getGTDateFormat]';


GO
PRINT N'Refreshing [dbo].[usp_getLastActivityDateOfUser]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getLastActivityDateOfUser]';


GO
PRINT N'Refreshing [dbo].[usp_GetOfficeMaster]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetOfficeMaster]';


GO
PRINT N'Refreshing [dbo].[usp_GetParentSectionIdForImportedSection]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetParentSectionIdForImportedSection]';


GO
PRINT N'Refreshing [dbo].[usp_GetProjectAndSectionData]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetProjectAndSectionData]';


GO
PRINT N'Refreshing [dbo].[usp_getProjectCountByCustomerId]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getProjectCountByCustomerId]';


GO
PRINT N'Refreshing [dbo].[usp_GetProjectCountDetails]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetProjectCountDetails]';


GO
PRINT N'Refreshing [dbo].[usp_getProjectNameById]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getProjectNameById]';


GO
PRINT N'Refreshing [dbo].[usp_getProjectsByID]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getProjectsByID]';


GO
PRINT N'Refreshing [dbo].[usp_GetProjectSections]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetProjectSections]';


GO
PRINT N'Refreshing [dbo].[usp_GetProjectSegmentGlobalTerms]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetProjectSegmentGlobalTerms]';


GO
PRINT N'Refreshing [dbo].[usp_GetProjectSummary]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetProjectSummary]';


GO
PRINT N'Refreshing [dbo].[usp_GetProjectTemplateStyle]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetProjectTemplateStyle]';


GO
PRINT N'Refreshing [dbo].[usp_GetRecentProjects]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetRecentProjects]';


GO
PRINT N'Refreshing [dbo].[usp_GetSections]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSections]';


GO
PRINT N'Refreshing [dbo].[usp_GetSegments_Work]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSegments_Work]';


GO
PRINT N'Refreshing [dbo].[usp_GetSourceTargetLinksOfSegmentOrChoice]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSourceTargetLinksOfSegmentOrChoice]';


GO
PRINT N'Refreshing [dbo].[usp_GetSpecDataSectionList]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSpecDataSectionList]';


GO
PRINT N'Refreshing [dbo].[usp_GetStandardProjects]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetStandardProjects]';


GO
PRINT N'Refreshing [dbo].[usp_GetTagReports]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetTagReports]';


GO
PRINT N'Refreshing [dbo].[usp_GetTagsReportDataOfHeaderFooter]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetTagsReportDataOfHeaderFooter]';


GO
PRINT N'Refreshing [dbo].[usp_getTOCReport]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getTOCReport]';


GO
PRINT N'Refreshing [dbo].[usp_InsertNewSection_ApplyMasterUpdate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_InsertNewSection_ApplyMasterUpdate]';


GO
PRINT N'Refreshing [dbo].[usp_IsProjectNameExist]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_IsProjectNameExist]';


GO
PRINT N'Refreshing [dbo].[usp_IsProjectOwner]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_IsProjectOwner]';


GO
PRINT N'Refreshing [dbo].[usp_MapSectionToProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_MapSectionToProject]';


GO
PRINT N'Refreshing [dbo].[usp_RestoreProjectID]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_RestoreProjectID]';


GO
PRINT N'Refreshing [dbo].[usp_SaveAndUpdateRvtFileDetails]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SaveAndUpdateRvtFileDetails]';


GO
PRINT N'Refreshing [dbo].[usp_SaveAppliedTemplateId]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SaveAppliedTemplateId]';


GO
PRINT N'Refreshing [dbo].[usp_SendEmailCopyProjectFailedJob]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SendEmailCopyProjectFailedJob]';


GO
PRINT N'Refreshing [dbo].[usp_SetDivisionIdForUserSection]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SetDivisionIdForUserSection]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateProjectLastModifiedDate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateProjectLastModifiedDate]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateProjectSummaryInfo]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateProjectSummaryInfo]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateSection_ApplyMasterUpdate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateSection_ApplyMasterUpdate]';


GO
PRINT N'Refreshing [dbo].[usp_updateSectionLinkStatus]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_updateSectionLinkStatus]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateSegmentStatus_ApplyMasterUpdate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateSegmentStatus_ApplyMasterUpdate]';


GO
PRINT N'Refreshing [dbo].[usp_updateTemplateId]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_updateTemplateId]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateUserTrackChangesSegment]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateUserTrackChangesSegment]';


GO
PRINT N'Refreshing [dbo].[usp_ApplyMasterUpdateToProjects]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ApplyMasterUpdateToProjects]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateProjectGlobalTerm]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateProjectGlobalTerm]';


GO
PRINT N'Refreshing [dbo].[usp_ImportSectionFromProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ImportSectionFromProject]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateSectionsIdName]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateSectionsIdName]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSectionFromMasterTemplate_Job]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSectionFromMasterTemplate_Job]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSegmentsForImportedSection]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSegmentsForImportedSection]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSegmentsForImportedSectionPOC]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSegmentsForImportedSectionPOC]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSpecDataSegments]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSpecDataSegments]';


GO
PRINT N'Refreshing [dbo].[usp_MapMasterDataToProjectForSection]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_MapMasterDataToProjectForSection]';


GO
PRINT N'Refreshing [dbo].[usp_SpecDataCreateSegments]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SpecDataCreateSegments]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSectionJob]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSectionJob]';


GO
PRINT N'Refreshing [dbo].[usp_GetSectionsdemo]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSectionsdemo]';


GO
PRINT N'Refreshing [dbo].[usp_GetSegmentLinkDetails]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSegmentLinkDetails]';


GO
PRINT N'Refreshing [dbo].[usp_GetSegmentLinkDetailsForJob]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSegmentLinkDetailsForJob]';


GO
PRINT N'Refreshing [dbo].[usp_GetSubmittalsReport]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSubmittalsReport]';


GO
PRINT N'Refreshing [dbo].[usp_GetTrackChangeDetails]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetTrackChangeDetails]';


GO
PRINT N'Refreshing [dbo].[usp_GetTrackChangesModeInfo]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetTrackChangesModeInfo]';


GO
PRINT N'Refreshing [dbo].[usp_SetProjectView]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SetProjectView]';


GO
PRINT N'Refreshing [dbo].[usp_SpecDataMapSectionToProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SpecDataMapSectionToProject]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateSegmentsGTAndRSMapping]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateSegmentsGTAndRSMapping]';


GO
PRINT N'Refreshing [dbo].[usp_ApplyMasterUpdatesToProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ApplyMasterUpdatesToProject]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSectionFromMasterTemplate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSectionFromMasterTemplate]';


GO
PRINT N'Refreshing [dbo].[usp_GetProjectDivisionAndSections]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetProjectDivisionAndSections]';


GO
PRINT N'Refreshing [dbo].[usp_GetSegments]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSegments]';


GO
PRINT N'Refreshing [dbo].[CopyProjectJob]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[CopyProjectJob]';


GO
PRINT N'Refreshing [dbo].[usp_MapSectionToProject_Work]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_MapSectionToProject_Work]';


GO
PRINT N'Refreshing [dbo].[usp_GetSegmentMappingData]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSegmentMappingData]';
