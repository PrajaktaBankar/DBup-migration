CREATE PROCEDURE [dbo].[usp_ActionOnChoiceOptionModify]     
(        
@OptionListJson NVARCHAR(MAX),        
@SegmentChoiceId BIGINT,    
@SegmentChoiceCode BIGINT,    
@ChoiceAction INT = 1 ,   
@SegmentStatusId BIGINT=0  
)           
AS    
BEGIN  
	BEGIN TRY   
		DECLARE @POptionListJson NVARCHAR(MAX) = @OptionListJson  
		DECLARE @PSegmentChoiceId BIGINT = @SegmentChoiceId  
		DECLARE @PSegmentChoiceCode BIGINT = @SegmentChoiceCode  
		DECLARE @PChoiceAction INT = @ChoiceAction  
		DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId  
		DECLARE @ChoiceCreated INT = 0;--New choice created or master choice modified    
		DECLARE @ChoiceUpdated INT = 1;--Existing user choice modified    
		DECLARE @ChoiceDeleted INT = 2;--Existing user choice deleted    
		DECLARE @ChoiceEdited INT = 3;--Existing Master/User choice edited from choice panel    
		DECLARE @UndoDeletedChoice INT = 4;  
		DECLARE @ChoiceOptionSource CHAR(1) = 'U';  
		DECLARE @ChoiceOptionCount INT = 1;  
		DECLARE @ProjectId INT;  
		DECLARE @SectionId INT;  
		DECLARE @CustomerId INT;  
		--DECLARE @UserId int;        
        
		CREATE TABLE #ChoiceOptionTable(  
		RowId INT,        
		ChoiceOptionId BIGINT NULL,    
		SortOrder INT NULL,        
		ChoiceOptionSource CHAR(1) NULL,        
		OptionJson  NVARCHAR(MAX) NULL,        
		ProjectId INT NULL,        
		SectionId INT NULL,        
		CustomerId INT NULL,        
		ChoiceOptionCode BIGINT NULL,        
		CreatedBy INT NULL,        
		ModifiedBy INT NULL,      
		IsSelected BIT NULL,    
		IsDeleted BIT NULL   
		);  
  
		INSERT INTO #ChoiceOptionTable (RowId, ChoiceOptionId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId, CustomerId, ChoiceOptionCode  
		, CreatedBy, ModifiedBy, IsSelected)  
		SELECT  
		*  
		FROM OPENJSON(@POptionListJson)  
		WITH (  
		RowId INT '$.RowId',  
		ChoiceOptionId BIGINT '$.OriginalChoiceOptionId',  
		SortOrder INT '$.SortOrder',  
		ChoiceOptionSource CHAR(1) '$.ChoiceOptionSource',  
		OptionJson NVARCHAR(MAX) '$.OptionJson',  
		ProjectId INT '$.ProjectId',  
		SectionId INT '$.SectionId',  
		CustomerId INT '$.CustomerId',  
		ChoiceOptionCode BIGINT '$.ChoiceOptionCode',  
		CreatedBy INT '$.CreatedBy',  
		ModifiedBy INT '$.ModifiedBy',  
		IsSelected BIT '$.IsSelected'  
		);  
  
		SELECT TOP 1  
		@ProjectId = ProjectId  
		,@CustomerId = CustomerId  
		,@SectionId = SectionId  
		FROM #ChoiceOptionTable  
  
		DECLARE @CurrentRowId INT = 1;  
		DECLARE @ChoiceOptionCode BIGINT = 0;  
		DECLARE @InsertedChoiceOptionId BIGINT = 0;  
		DECLARE @ChoiceOptionId BIGINT = 0;  
		DECLARE @ChoiceOptionTableCount INT = 0;  
		IF (@PChoiceAction = @ChoiceCreated)  
		BEGIN  
			--SET @CurrentRowId = 1;  
			--SET @ChoiceOptionCode = 0;  
  
			declare @ChoiceOptionTableRowCount INT=(SELECT COUNT(1) FROM #ChoiceOptionTable)  
			WHILE (@CurrentRowId <= @ChoiceOptionTableRowCount)  
			BEGIN  
				SELECT  @ChoiceOptionId = CO.ChoiceOptionId , 
				@ChoiceOptionCode = ChoiceOptionCode  
				FROM #ChoiceOptionTable CO  
				WHERE CO.RowId = @CurrentRowId;  
				
				SET @ChoiceOptionId = ISNULL(@ChoiceOptionId,0)  
				--handled option removed or added  
				IF EXISTS (SELECT TOP 1 1 FROM ProjectChoiceOption PCO WITH (NOLOCK)  
				WHERE PCO.ChoiceOptionId = @ChoiceOptionId  
				AND PCO.SectionId = @SectionId  
				AND PCO.CustomerId = @CustomerId  
				AND PCO.ProjectId = @ProjectId  
				AND PCO.SegmentChoiceId = @SegmentChoiceId   
				AND PCO.ChoiceOptionSource = @ChoiceOptionSource   
				AND ISNULL(PCO.IsDeleted,0) = 0)  
				BEGIN  
					UPDATE PCO  
					SET PCO.OptionJson = CO.OptionJson  
					,PCO.ModifiedBy = CO.ModifiedBy  
					,PCO.ModifiedDate = GETUTCDATE()  
					,PCO.SortOrder = CO.SortOrder  
					FROM #ChoiceOptionTable CO  
					INNER JOIN ProjectChoiceOption PCO WITH (NOLOCK)  
					ON PCO.ChoiceOptionId = CO.ChoiceOptionId  
					AND CO.ProjectId = PCO.ProjectId  
					AND CO.SectionId = PCO.SectionId  
					AND CO.CustomerId = PCO.CustomerId  
					WHERE CO.ChoiceOptionId = @ChoiceOptionId   
					AND PCO.SectionId = @SectionId  
					AND PCO.CustomerId = @CustomerId  
					AND PCO.ProjectId = @ProjectId  
					AND PCO.SegmentChoiceId = @PSegmentChoiceId  
					AND ISNULL(PCO.IsDeleted,0) = 0  
					AND PCO.ChoiceOptionSource = @ChoiceOptionSource      
				END  
				ELSE  
				BEGIN 
					IF (ISNULL(@ChoiceOptionCode,0) > 0)  
					BEGIN  
						INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId, CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)  
						SELECT  
						@PSegmentChoiceId AS SegmentChoiceId  
						,SortOrder  
						,@ChoiceOptionSource AS ChoiceOptionSource  
						,OptionJson  
						,ProjectId  
						,SectionId  
						,CustomerId  
						,ChoiceOptionCode  
						,CreatedBy  
						,GETUTCDATE() AS CreateDate  
						,ModifiedBy  
						,GETUTCDATE() AS ModifiedDate  
						FROM #ChoiceOptionTable CO  
						WHERE CO.RowId = @CurrentRowId;  
  
						--SET @InsertedChoiceOptionId = SCOPE_IDENTITY();  
					END  
					ELSE  
					BEGIN  
						INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId, CustomerId, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)  
						SELECT  
						@PSegmentChoiceId AS SegmentChoiceId  
						,SortOrder  
						,@ChoiceOptionSource AS ChoiceOptionSource  
						,OptionJson  
						,ProjectId  
						,SectionId  
						,CustomerId  
						,CreatedBy  
						,GETUTCDATE() AS CreateDate  
						,ModifiedBy  
						,GETUTCDATE() AS ModifiedDate  
						FROM #ChoiceOptionTable CO  
						WHERE CO.RowId = @CurrentRowId;  
  
						SET @InsertedChoiceOptionId = SCOPE_IDENTITY();  
  
						SELECT @ChoiceOptionCode = ChoiceOptionCode  
						FROM ProjectChoiceOption WITH (NOLOCK)  
						WHERE ChoiceOptionId = @InsertedChoiceOptionId  
					END  
  
					----MAKE ENTRY IN SelectedChoiceOption TABLE    
					INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId)  
					SELECT  
					@PSegmentChoiceCode AS SegmentChoiceCode  
					,@ChoiceOptionCode AS ChoiceOptionCode  
					,@ChoiceOptionSource AS ChoiceOptionSource  
					,CO.IsSelected  
					,@SectionId AS SectionId  
					,@ProjectId AS ProjectId  
					,@CustomerId AS CustomerId  
					FROM #ChoiceOptionTable CO  
					WHERE CO.RowId = @CurrentRowId;  
				END
				SET @CurrentRowId = @CurrentRowId + 1;   

			END  
		END  
    
		--handled Edited choice  
		IF(@PChoiceAction =@ChoiceEdited)    
		BEGIN  
			declare @TotalOptionCount int=0;  
			SET @CurrentRowId = 1;  
			SET @ChoiceOptionCode = 0;  
			SET @ChoiceOptionId = 0;  
			SET @ChoiceOptionTableCount = (SELECT COUNT(1) FROM #ChoiceOptionTable)  
			WHILE(@CurrentRowId <= @ChoiceOptionTableCount)  
			BEGIN  
				SELECT @ChoiceOptionId = CO.ChoiceOptionId , 
				@ChoiceOptionCode = ChoiceOptionCode  
				FROM #ChoiceOptionTable CO  
				WHERE CO.RowId = @CurrentRowId;  
  
				SET @ChoiceOptionId = ISNULL(@ChoiceOptionId,0)  
				--handled option removed or added  
				IF EXISTS (SELECT TOP 1 1 FROM ProjectChoiceOption PCO WITH (NOLOCK)  
				WHERE PCO.ChoiceOptionId = @ChoiceOptionId  
				AND PCO.SectionId = @SectionId  
				AND PCO.CustomerId = @CustomerId  
				AND PCO.ProjectId = @ProjectId  
				AND PCO.SegmentChoiceId = @SegmentChoiceId   
				AND PCO.ChoiceOptionSource = @ChoiceOptionSource   
				AND ISNULL(PCO.IsDeleted,0) = 0)  
				BEGIN  
					UPDATE PCO  
					SET PCO.OptionJson = CO.OptionJson  
					,PCO.ModifiedBy = CO.ModifiedBy  
					,PCO.ModifiedDate = GETUTCDATE()  
					,PCO.SortOrder = CO.SortOrder  
					FROM #ChoiceOptionTable CO  
					INNER JOIN ProjectChoiceOption PCO WITH (NOLOCK)  
					ON PCO.ChoiceOptionId = CO.ChoiceOptionId  
					AND CO.ProjectId = PCO.ProjectId  
					AND CO.SectionId = PCO.SectionId  
					AND CO.CustomerId = PCO.CustomerId  
					WHERE CO.ChoiceOptionId = @ChoiceOptionId   
					AND PCO.SectionId = @SectionId  
					AND PCO.CustomerId = @CustomerId  
					AND PCO.ProjectId = @ProjectId  
					AND PCO.SegmentChoiceId = @PSegmentChoiceId  
					AND ISNULL(PCO.IsDeleted,0) = 0  
					AND PCO.ChoiceOptionSource = @ChoiceOptionSource      
				END  
				ELSE  
				BEGIN  
					SELECT  
					@ChoiceOptionCode = ChoiceOptionCode  
					FROM #ChoiceOptionTable CO  
					WHERE CO.RowId = @CurrentRowId;  
					IF (ISNULL(@ChoiceOptionCode,0)>0)  
					BEGIN  
						INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId, CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate,IsDeleted)  
						SELECT  
						@PSegmentChoiceId AS SegmentChoiceId  
						,SortOrder  
						,@ChoiceOptionSource AS ChoiceOptionSource  
						,OptionJson  
						,ProjectId  
						,SectionId  
						,CustomerId  
						,ChoiceOptionCode  
						,CreatedBy  
						,GETUTCDATE() AS CreateDate  
						,ModifiedBy  
						,GETUTCDATE() AS ModifiedDate  
						,0  
						FROM #ChoiceOptionTable CO  
						WHERE CO.RowId = @CurrentRowId;  
						SET @InsertedChoiceOptionId = SCOPE_IDENTITY();  
						UPDATE CO  
						SET CO.ChoiceOptionId = @InsertedChoiceOptionId  
						FROM #ChoiceOptionTable CO  
						WHERE CO.RowId = @CurrentRowId;  
					END  
					ELSE  
					BEGIN  
						INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId, CustomerId, CreatedBy, CreateDate, ModifiedBy, ModifiedDate,IsDeleted)  
						SELECT  
						@PSegmentChoiceId AS SegmentChoiceId  
						,SortOrder  
						,@ChoiceOptionSource AS ChoiceOptionSource  
						,OptionJson  
						,ProjectId  
						,SectionId  
						,CustomerId  
						,CreatedBy  
						,GETUTCDATE() AS CreateDate  
						,ModifiedBy  
						,GETUTCDATE() AS ModifiedDate  
						,0  
						FROM #ChoiceOptionTable CO  
						WHERE CO.RowId = @CurrentRowId;  
						SET @InsertedChoiceOptionId = SCOPE_IDENTITY();  
						SELECT  
						@ChoiceOptionCode = ChoiceOptionCode  
						FROM ProjectChoiceOption WITH (NOLOCK)  
						WHERE ChoiceOptionId = @InsertedChoiceOptionId  
					----MAKE ENTRY IN SelectedChoiceOption TABLE    
					END  
  
					UPDATE CO  
					SET CO.ChoiceOptionId = @InsertedChoiceOptionId  
					,CO.ChoiceOptionCode=@ChoiceOptionCode  
					FROM #ChoiceOptionTable CO  
					WHERE CO.RowId = @CurrentRowId;  
  
					INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId)  
					SELECT  
					@PSegmentChoiceCode AS SegmentChoiceCode  
					,@ChoiceOptionCode AS ChoiceOptionCode  
					,@ChoiceOptionSource AS ChoiceOptionSource  
					,CO.IsSelected  
					,@SectionId AS SectionId  
					,@ProjectId AS ProjectId  
					,@CustomerId AS CustomerId  
					FROM #ChoiceOptionTable CO  
					WHERE CO.RowId = @CurrentRowId;  
				END  
  
				SET @CurrentRowId = @CurrentRowId + 1;  
			END  
  
			UPDATE PCO  
			SET PCO.IsDeleted = 1  
			FROM ProjectChoiceOption PCO WITH (NOLOCK)   
			LEFT OUTER JOIN #ChoiceOptionTable CO  
			ON CO.ChoiceOptionId = PCO.ChoiceOptionId  
			AND PCO.SectionId = CO.SectionId  
			AND PCO.ChoiceOptionCode = CO.ChoiceOptionCode  
			AND PCO.ProjectId = CO.ProjectId  
			AND PCO.CustomerId = CO.CustomerId  
			WHERE PCO.SectionId = @SectionId   
			AND PCO.SegmentChoiceId = @SegmentChoiceId  
			AND PCO.ProjectId = @ProjectId  
			AND CO.ChoiceOptionId IS NULL  
			--AND PSC.SegmentStatusId = @PSegmentStatusId  
			AND PCO.CustomerId = @CustomerId  
			AND PCO.ChoiceOptionSource = @ChoiceOptionSource  
			AND ISNULL(PCO.IsDeleted, 0) = 0  
       
			--Is this really needed.   
			UPDATE SCO  
			SET SCO.IsDeleted = 1  
			--SCO.OptionJson='1'  
			FROM ProjectChoiceOption PCO WITH (NOLOCK)    
			INNER JOIN SelectedChoiceOption SCO WITH (NOLOCK)  
			ON PCO.SectionId = SCO.SectionId  
			AND SCO.ChoiceOptionCode = PCO.ChoiceOptionCode  
			AND SCO.SegmentChoiceCode=@PSegmentChoiceCode  
			AND PCO.ProjectId = SCO.ProjectId  
			AND PCO.CustomerId = SCO.CustomerId  
			LEFT OUTER JOIN #ChoiceOptionTable CO  
			ON CO.ChoiceOptionId = PCO.ChoiceOptionId  
			AND CO.SectionId = PCO.SectionId  
			AND CO.ChoiceOptionCode = PCO.ChoiceOptionCode  
			AND CO.ProjectId = PCO.ProjectId  
			AND CO.CustomerId = PCO.CustomerId  
			WHERE PCO.SectionId = @SectionId  
			AND CO.ChoiceOptionId IS NULL  
			AND SCO.ProjectId = @ProjectId  
			AND SCO.ChoiceOptionSource = @ChoiceOptionSource  
			AND SCO.CustomerId = @CustomerId  
			AND PCO.SegmentChoiceId = @SegmentChoiceId  
			--AND PSC.SegmentStatusId = @PSegmentStatusId  
			AND ISNULL(SCO.IsDeleted, 0) = 0  
		END  
    
		--Handled Update choice  
		IF(@PChoiceAction = @ChoiceUpdated)  
		BEGIN  
  
			UPDATE PCO  
			SET PCO.OptionJson = CO.OptionJson  
			,PCO.ModifiedBy = CO.ModifiedBy  
			,PCO.ModifiedDate = GETUTCDATE()  
			,PCO.SortOrder = CO.SortOrder  
			FROM #ChoiceOptionTable CO  
			INNER JOIN ProjectChoiceOption PCO WITH (NOLOCK)  
			ON PCO.ChoiceOptionId = CO.ChoiceOptionId  
			AND PCO.SectionId = CO.SectionId  
			AND PCO.SegmentChoiceId = @SegmentChoiceId  
			WHERE PCO.SectionId = @SectionId  
			AND PCO.ProjectId = @ProjectId  
			AND PCO.CustomerId = @CustomerId  
			AND PCO.ChoiceOptionSource = @ChoiceOptionSource  
			--AND PCO.SegmentStatusId = @PSegmentStatusId  
			AND ISNULL(PCO.IsDeleted, 0) = 0  
  
			UPDATE SCO  
			SET SCO.IsSelected = CO.IsSelected  
			FROM #ChoiceOptionTable CO WITH (NOLOCK)  
			INNER JOIN ProjectChoiceOption PCO WITH (NOLOCK)  
			ON CO.ChoiceOptionId = PCO.ChoiceOptionId  
			AND CO.SectionId = PCO.SectionId  
			INNER JOIN SelectedChoiceOption SCO WITH (NOLOCK)
			ON PCO.ProjectId = SCO.ProjectId AND PCO.CustomerId = SCO.CustomerId AND SCO.SectionId = PCO.SectionId
			AND SCO.SegmentChoiceCode = @SegmentChoiceCode
			AND SCO.ChoiceOptionCode = PCO.ChoiceOptionCode
			WHERE PCO.SegmentChoiceId = @SegmentChoiceId
			AND PCO.SectionId = @SectionId
			AND PCO.ChoiceOptionSource = @ChoiceOptionSource
			AND SCO.ProjectId = @ProjectId AND SCO.CustomerId = @CustomerId AND SCO.SectionId = @SectionId
			AND SCO.ChoiceOptionSource = @ChoiceOptionSource

		END  
		---Handled undo/redo right click deleted option of choice  
		IF (@PChoiceAction = @UndoDeletedChoice)  
		BEGIN  
			UPDATE PCO  
			SET PCO.IsDeleted = 0  
			FROM ProjectChoiceOption PCO WITH (NOLOCK)  
			INNER JOIN #ChoiceOptionTable CO  
			ON PCO.ChoiceOptionId = CO.ChoiceOptionId  
			AND PCO.SectionId = CO.SectionId  
			AND PCO.ProjectId = CO.ProjectId  
			AND PCO.CustomerId = CO.CustomerId  
			AND PCO.ChoiceOptionSource = @ChoiceOptionSource  
			WHERE PCO.SectionId = @SectionId  
			AND PCO.SegmentChoiceId = @PSegmentChoiceId  
  
			UPDATE SCO  
			SET SCO.IsDeleted = 0  
			--,OptionJson='FAILED:SelectedChoiceOption..IsDeleted=0'  
			FROM #ChoiceOptionTable CO WITH (NOLOCK)  
			INNER JOIN ProjectChoiceOption PCO WITH (NOLOCK)  
			ON CO.ChoiceOptionId = PCO.ChoiceOptionId  
			AND CO.SectionId = PCO.SectionId  
			INNER JOIN SelectedChoiceOption SCO WITH (NOLOCK)  
			ON PCO.ProjectId = SCO.ProjectId AND PCO.CustomerId = SCO.CustomerId AND SCO.SectionId = PCO.SectionId  
			AND SCO.SegmentChoiceCode = @SegmentChoiceCode
			AND SCO.ChoiceOptionCode = PCO.ChoiceOptionCode			
			WHERE PCO.SegmentChoiceId = @SegmentChoiceId  
			AND PCO.SectionId = @SectionId
			AND SCO.ProjectId = @ProjectId AND SCO.CustomerId = @CustomerId AND SCO.SectionId = @SectionId
			AND SCO.ChoiceOptionSource=@ChoiceOptionSource  
  
			IF(@@rowcount=0)  
			BEGIN  
			INSERT INTO BsdLogging..AutoSaveLogging  
			VALUES ('usp_ActionOnChoiceOptionModify',   
			GETDATE(),   
			'FAILED:SelectedChoiceOption..IsDeleted=0',   
			ERROR_NUMBER(),   
			ERROR_SEVERITY(),   
			ERROR_LINE(),   
			ERROR_STATE(),   
			ERROR_PROCEDURE(),   
			CONCAT('EXEC usp_ActionOnChoiceOptionModify ''', @OptionListJson, ''',', @SegmentChoiceId, ',', @SegmentChoiceCode, ',', @ChoiceAction, ',', @SegmentStatusId),   
			(SELECT * from #ChoiceOptionTable for json path))  
			END  
		END  
  
		IF (@PChoiceAction = @ChoiceDeleted)  
		BEGIN  
			PRINT ('NOT IMPLEMENTED');  
		END  
	END TRY  
	BEGIN CATCH  
		INSERT INTO BsdLogging..AutoSaveLogging  
		VALUES ('usp_ActionOnChoiceOptionModify', GETDATE(), ERROR_MESSAGE(), ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_STATE(), ERROR_PROCEDURE(), CONCAT('EXEC usp_ActionOnChoiceOptionModify ''', @OptionListJson, ''',', @SegmentChoiceId, ',', @SegmentChoiceCode, ',', @ChoiceAction, ',', @SegmentStatusId), @OptionListJson)  
	END CATCH  
END
GO


