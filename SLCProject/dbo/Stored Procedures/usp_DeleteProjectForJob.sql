
CREATE PROCEDURE [dbo].[usp_DeleteProjectForJob]  
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