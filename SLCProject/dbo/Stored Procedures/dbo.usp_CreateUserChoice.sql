
CREATE PROCEDURE [dbo].[usp_CreateUserChoice]      
(      
@InpChoiceJson NVARCHAR(MAX),      
@SegmentStatusId BIGINT,      
@Segmentid BIGINT,      
@SegmentSource CHAR(1),      
@SegmentOrigin CHAR(1)      
)      
AS      
BEGIN    
	BEGIN TRY    
	DECLARE @PInpChoiceJson NVARCHAR(MAX) = @InpChoiceJson;    
	DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId;    
	DECLARE @PSegmentid BIGINT = @Segmentid;    
	DECLARE @PSegmentSource CHAR(1) = @SegmentSource    
	DECLARE @PSegmentOrigin CHAR(1) = @SegmentOrigin    
      
	DECLARE @ChoiceCount INT = 1;    
      
	create TABLE #TempInsertedChoice (SegmentChoiceId BIGINT,RowId INT,SegmentChoiceCode BIGINT)    
        
	CREATE  TABLE #TempInpChoiceTable(      
	RowId INT,      
	SegmentChoiceId BIGINT NULL,      
	SectionId INT NULL,          
	ChoiceTypeId INT NULL,         
	ProjectId INT NULL,        
	CustomerId INT NULL,        
	SegmentChoiceSource CHAR(1) NULL,        
	SegmentChoiceCode  NVARCHAR(MAX) NULL,      
	CreatedBy  INT NULL,      
	ModifiedBy  INT NULL,      
	ChoiceAction  INT NULL,      
	OptionListJson  NVARCHAR(MAX) NULL,      
	IsDeleted bit      
	);    
    
	INSERT INTO #TempInpChoiceTable    
	SELECT    
	*    
	FROM OPENJSON(@PInpChoiceJson)    
	WITH (    
	RowId INT '$.RowId',    
	SegmentChoiceId BIGINT '$.SegmentChoiceId',    
	SectionId INT '$.SectionId',    
	ChoiceTypeId INT '$.ChoiceTypeId',    
	ProjectId INT '$.ProjectId',    
	CustomerId INT '$.CustomerId',    
	SegmentChoiceSource CHAR(1) '$.SegmentChoiceSource',    
	SegmentChoiceCode NVARCHAR(MAX) '$.OriginalSegmentChoiceCode',    
	CreatedBy INT '$.CreatedBy',    
	ModifiedBy INT '$.ModifiedBy',    
	ChoiceAction INT '$.ChoiceAction',    
	OptionListJson NVARCHAR(MAX) '$.OptionListJson',    
	IsDeleted BIT '$.IsDeleted'    
	);    
    
	--Choice Action Enum    
	DECLARE @Created INT = 0;    
	DECLARE @Modified INT = 1;    
	DECLARE @Deleted INT = 2;    
	DECLARE @Edited INT = 3;    
	DECLARE @TempInpChoiceTableCount INT = 0;    
	DECLARE @NewChoiceId BIGINT = 0;    
    
	SET @TempInpChoiceTableCount = (SELECT COUNT(1) FROM #TempInpChoiceTable);    
    
	DECLARE @RowId INT;    
	DECLARE @SegmentChoiceId BIGINT;    
	DECLARE @SectionId INT;    
	DECLARE @ChoiceTypeId INT;    
	DECLARE @ProjectId INT;    
	DECLARE @CustomerId INT;    
	DECLARE @SegmentChoiceSource CHAR(1);    
	DECLARE @SegmentChoiceCode NVARCHAR(MAX);    
	DECLARE @CreatedBy INT;    
	DECLARE @ModifiedBy INT;    
	DECLARE @ChoiceAction INT;    
	DECLARE @OptionListJson NVARCHAR(MAX);    
	DECLARE @IsDeleted BIT;    
    
	WHILE (@ChoiceCount <= @TempInpChoiceTableCount)    
	BEGIN    
		set @RowId=0    
		set @SegmentChoiceId=0    
		set @SectionId=0    
		set @ChoiceTypeId=0    
		set @ProjectId=0    
		set @CustomerId=0    
		set @SegmentChoiceSource=null    
		set @SegmentChoiceCode=null    
		set @CreatedBy=0    
		set @ModifiedBy=0    
		set @ChoiceAction=0    
		set @OptionListJson=null    
		set @IsDeleted=0    
       
		SELECT    
		@RowId = RowId    
		,@SegmentChoiceId = SegmentChoiceId    
		,@SectionId = SectionId    
		,@ChoiceTypeId = ChoiceTypeId    
		,@ProjectId = ProjectId    
		,@CustomerId = CustomerId    
		,@SegmentChoiceSource = SegmentChoiceSource    
		,@SegmentChoiceCode = SegmentChoiceCode    
		,@CreatedBy = CreatedBy    
		,@ModifiedBy = ModifiedBy    
		,@ChoiceAction = ChoiceAction    
		,@OptionListJson = OptionListJson    
		,@IsDeleted = IsDeleted    
		FROM #TempInpChoiceTable    
		WHERE RowId = @ChoiceCount    
    
		--IF SEGMENT IS MODIFIED  and Choice Action to Be Created      
		IF (ISNULL(@ChoiceAction,-1) = @Created)    
		BEGIN    
			--CREATE NEW CHOICE      
			IF (ISNULL(@SegmentChoiceCode,0)> 0)    
			BEGIN    
				--handled m to m*    
				DECLARE @SegmentChoiceIDTemp BIGINT=0    
				SELECT TOP 1 @SegmentChoiceIDTemp =SegmentChoiceId FROM ProjectSegmentChoice WITH (NOLOCK)    
				WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND SectionId = @SectionId
				AND SegmentChoiceCode = @SegmentChoiceCode
				AND SegmentStatusId = @PSegmentStatusId     
				AND SegmentId = @SegmentId    
				AND SegmentChoiceSource = 'U'    
				AND ISNULL(IsDeleted, 0) = 0    
    
				IF(ISNULL(@SegmentChoiceIDTemp,0)=0)    
				BEGIN    
					INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted)    
					VALUES (@SectionId, @PSegmentStatusId, @PSegmentid, @ChoiceTypeId, @ProjectId, @CustomerId, 'U', @SegmentChoiceCode, @CreatedBy, GETUTCDATE(), @ModifiedBy, GETUTCDATE(), 0)    
    
					SET @NewChoiceId = SCOPE_IDENTITY();    
				END
				ELSE    
				BEGIN    
					SET @NewChoiceId = @SegmentChoiceIDTemp    
          
					----Comment this block later    
					--IF(@SegmentChoiceIDTemp<>@SegmentChoiceId)    
					--BEGIN    
					--	insert into BsdLogging..AutoSaveLogging    
					--	values('usp_CreateUserChoice',    
					--	getdate(),    
					--	concat('Corrected:Wrong value provided to [usp_ActionOnChoiceOptionModify] Proc.Wrong value:',@SegmentChoiceId,', Correct Value:',@SegmentChoiceIDTemp),    
					--	ERROR_NUMBER(),    
					--	ERROR_Severity(),    
					--	ERROR_LINE(),    
					--	ERROR_STATE(),    
					--	'usp_CreateUserChoice',    
					--	concat('exec usp_CreateUserChoice ''',@InpChoiceJson,''',',@SegmentStatusId,',',@Segmentid,',''',@SegmentSource,''',''',@SegmentOrigin,''''),    
					--	@InpChoiceJson    
					--	)    
					--END    
				END    
			END    
			ELSE    
			BEGIN    
				--- handled user created choices    
				INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted)    
				VALUES (@SectionId, @PSegmentStatusId, @PSegmentid, @ChoiceTypeId, @ProjectId, @CustomerId, 'U', @CreatedBy, GETUTCDATE(), @ModifiedBy, GETUTCDATE(), 0)    
				SET @NewChoiceId = SCOPE_IDENTITY();    
			END    
    
			SELECT    
			@SegmentChoiceId = SegmentChoiceId    
			,@SegmentChoiceCode = SegmentChoiceCode    
			FROM ProjectSegmentChoice WITH(NOLOCK)    
			WHERE SegmentChoiceId = @NewChoiceId    
    
			--Inserting created SegmentChoiceId into #TempInsertedChoice table      
			INSERT INTO #TempInsertedChoice (SegmentChoiceId, RowId,SegmentChoiceCode)    
			VALUES (@NewChoiceId, @RowId,@SegmentChoiceCode)    
        
			---Call To Save Option SP      
			EXEC [usp_ActionOnChoiceOptionModify] @OptionListJson    
			,@SegmentChoiceId    
			,@SegmentChoiceCode    
			,@ChoiceAction    
			,@PSegmentStatusId    
		END    
    
		ELSE IF (@ChoiceAction = @Modified OR @ChoiceAction = @Edited)    
		BEGIN    
			---Handled undo/redo right click deleted option of choice    
			IF EXISTS (SELECT TOP 1 1 FROM ProjectSegmentChoice WITH (NOLOCK)    
			WHERE --SegmentChoiceId = @SegmentChoiceId AND 
			ProjectId = @ProjectId AND CustomerId = @CustomerId AND SectionId = @SectionId    
			AND SegmentChoiceCode = @SegmentChoiceCode
			AND SegmentStatusId = @PSegmentStatusId    
			AND SegmentChoiceSource = 'U'    
			AND ISNULL(IsDeleted, 0) = 1    
			AND SegmentId = @SegmentId    
			)    
			BEGIN    
				UPDATE PSC    
				SET IsDeleted = 0    
				FROM ProjectSegmentChoice PSC WITH (NOLOCK)    
				WHERE SegmentChoiceId = @SegmentChoiceId     
				AND SegmentStatusId = @PSegmentStatusId    
				AND SectionId = @SectionId    
				AND ProjectId = @ProjectId    
				AND CustomerId = @CustomerId    
				AND SegmentChoiceCode = @SegmentChoiceCode    
				AND SegmentChoiceSource = 'U'    
				AND ISNULL(IsDeleted, 0) = 1    
				AND SegmentId = @SegmentId    
				SET @ChoiceAction = 4    
			END    
    
			--handled undo/redo ,choices edited and modified    
			DECLARE @SegmentChoiceIDTempM BIGINT=0    
			SELECT TOP 1 @SegmentChoiceIDTempM =SegmentChoiceId FROM ProjectSegmentChoice WITH (NOLOCK)    
			WHERE --SegmentChoiceId = @SegmentChoiceId  AND 
			ProjectId = @ProjectId    
			AND CustomerId = @CustomerId AND SectionId = @SectionId AND SegmentChoiceCode = @SegmentChoiceCode
			AND SegmentStatusId = @PSegmentStatusId     
			AND SegmentId = @SegmentId    
			AND SegmentChoiceSource = 'U'    
			AND ISNULL(IsDeleted, 0) = 0    
    
			IF(ISNULL(@SegmentChoiceIDTempM,0)=0)    
			BEGIN    
				INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted)    
				VALUES (@SectionId, @PSegmentStatusId, @PSegmentid, @ChoiceTypeId, @ProjectId, @CustomerId, 'U', @SegmentChoiceCode, @CreatedBy, GETUTCDATE(), @ModifiedBy, GETUTCDATE(), @IsDeleted)    
         
				SET @SegmentChoiceIDTempM = SCOPE_IDENTITY();    
				SET @ChoiceAction=3    
         
				----Comment this block later    
				--IF(@SegmentChoiceIDTempM<>@SegmentChoiceId)    
				--BEGIN    
				--	INSERT INTO BsdLogging..AutoSaveLogging    
				--	VALUES('usp_CreateUserChoice',    
				--	Getdate(),    
				--	Concat('Corrected:Wrong value provided to [usp_ActionOnChoiceOptionModify] Proc.Wrong value:',@SegmentChoiceId,', Correct Value:',@SegmentChoiceIDTempM),    
				--	ERROR_NUMBER(),    
				--	ERROR_Severity(),    
				--	ERROR_LINE(),    
				--	ERROR_STATE(),    
				--	'usp_createUserChoice',    
				--	concat('exec usp_CreateUserChoice ''',@InpChoiceJson,''',',@SegmentStatusId,',',@Segmentid,',''',@SegmentSource,''',''',@SegmentOrigin,''''),    
				--	@InpChoiceJson    
				--	)    
				--END    
			END    
    
			SELECT    
			@SegmentChoiceId = SegmentChoiceId    
			,@SegmentChoiceCode = SegmentChoiceCode    
			FROM ProjectSegmentChoice WITH (NOLOCK)    
			WHERE SegmentChoiceId=@SegmentChoiceIDTempM    
    
			--Inserting updated SegmentChoiceId into #TempInsertedChoice table      
			INSERT INTO #TempInsertedChoice (SegmentChoiceId, RowId,SegmentChoiceCode)    
			VALUES (@SegmentChoiceId, @RowId,@SegmentChoiceCode)    
    
			--Call To Update Option SP      
			EXEC [usp_ActionOnChoiceOptionModify] @OptionListJson    
			,@SegmentChoiceId    
			,@SegmentChoiceCode    
			,@ChoiceAction    
			,@PSegmentStatusId    
			--END      
		END    
  
		--removed choices from database      
		ELSE IF (@IsDeleted = 1)    
		BEGIN    
			DROP TABLE IF EXISTS #ProjectSegmentChoiceTMP    
			SELECT PSC.SegmentChoiceId,PSC.SectionId,PSC.SegmentStatusId,PSC.ProjectId    
			INTO #ProjectSegmentChoiceTMP FROM ProjectSegmentChoice PSC WITH (NOLOCK)    
			WHERE PSC.SegmentChoiceId = @SegmentChoiceId AND PSC.ProjectId=@ProjectId AND PSC.CustomerId = @CustomerId AND PSC.SectionId=@SectionId    
			AND PSC.SegmentStatusId = @PSegmentStatusId    
			AND PSC.SegmentChoiceSource = 'U'    
    
			UPDATE PSC    
			SET PSC.IsDeleted = 1    
			FROM #ProjectSegmentChoiceTMP T_PSC INNER JOIN ProjectSegmentChoice PSC WITH (NOLOCK)    
			ON PSC.SegmentChoiceId=T_PSC.SegmentChoiceId    
			AND PSC.SectionId=T_PSC.SectionId    
			AND PSC.SegmentStatusId = T_PSC.SegmentStatusId    
			AND PSC.ProjectId=T_PSC.ProjectId    
			WHere PSC.SegmentChoiceSource = 'U'    
    
			DROP TABLE IF EXISTS #ProjectChoiceOptionTMP    
			SELECT PCO.ChoiceOptionId,PCO.SegmentChoiceId,PCO.SectionId,PCO.ProjectId,PCO.ChoiceOptionCode    
			INTO #ProjectChoiceOptionTMP FROM #ProjectSegmentChoiceTMP T INNER JOIN ProjectChoiceOption AS PCO WITH (NOLOCK)    
			ON PCO.SectionId=T.SectionId    
			AND PCO.SegmentChoiceId=T.SegmentChoiceId    
			Where PCO.SectionId=@SectionId    
			AND PCO.ProjectId=@ProjectId    
			AND PCO.ChoiceOptionSource = 'U'    
    
			UPDATE PCO    
			SET PCO.IsDeleted = 1    
			FROM #ProjectChoiceOptionTMP T INNER JOIN ProjectChoiceOption AS PCO WITH (NOLOCK)    
			ON PCO.ChoiceOptionId=T.ChoiceOptionId    
			AND PCO.SegmentChoiceId = T.SegmentChoiceId    
			AND PCO.SectionId=T.SectionId      
			WHERE PCO.SectionId=@SectionId    
			AND PCO.ProjectId=@ProjectId    
			AND PCO.ChoiceOptionSource = 'U'    
    
			UPDATE SCP    
			SET SCP.IsDeleted = 1    
			--,SCP.OptionJson='2'    
			FROM #ProjectChoiceOptionTMP T INNER JOIN SelectedChoiceOption AS SCP WITH (NOLOCK)    
			ON SCP.ProjectId=T.ProjectId AND SCP.CustomerId = @CustomerId AND SCP.SectionId=T.SectionId     
			AND SCP.SegmentChoiceCode=@SegmentChoiceCode
			AND SCP.ChoiceOptionCode = T.ChoiceOptionCode    
			WHERE SCP.ProjectId=@ProjectId AND SCP.CustomerId = @CustomerId AND SCP.SectionId=@SectionId    
			AND SCP.SegmentChoiceCode=@SegmentChoiceCode    
			AND SCP.ChoiceOptionSource = 'U'    
		END    
		SET @ChoiceCount = @ChoiceCount + 1;    
	END    
    
	--GET SAVED CHOICE      
	SELECT    
		PSC.SegmentChoiceId    
		,PSC.SegmentStatusId    
		,PSC.SegmentId    
		,PSC.SegmentChoiceCode    
		,Temp.RowId    
		FROM ProjectSegmentChoice PSC WITH (NOLOCK)    
		INNER JOIN #TempInsertedChoice Temp    
		ON PSC.SegmentChoiceId = Temp.SegmentChoiceId    
		AND PSC.SectionId = @SectionId    
		AND ISNULL(PSC.IsDeleted, 0) = 0    
		AND PSC.ProjectId = @ProjectId    
		AND PSC.CustomerId = @CustomerId    
		AND PSC.SegmentChoiceSource = 'U'    
    
	SELECT DISTINCT    
		PCO.SegmentChoiceId    
		,PCO.ChoiceOptionId    
		,SCO.SegmentChoiceCode    
		,PCO.ChoiceOptionCode    
		,PCO.OptionJson    
		,SCO.IsSelected    
		,PCO.SortOrder    
		FROM #TempInsertedChoice T INNER JOIN ProjectChoiceOption PCO WITH (NOLOCK)    
		ON T.SegmentChoiceId=PCO.SegmentChoiceId    
		AND PCO.SectionId=@SectionId    
		INNER JOIN SelectedChoiceOption SCO WITH (NOLOCK)    
		ON SCO.ProjectId = PCO.ProjectId AND SCO.CustomerId = PCO.CustomerId AND SCO.SectionId = PCO.SectionId
		AND SCO.SegmentChoiceCode=T.SegmentChoiceCode
		AND PCO.ChoiceOptionCode = SCO.ChoiceOptionCode
		WHERE SCO.ProjectId = @ProjectId AND SCO.CustomerId = @CustomerId AND SCO.SectionId = @SectionId    
		AND SCO.ChoiceOptionSource = 'U'    
		AND ISNULL(SCO.IsDeleted, 0) = 0    
	--ORDER BY SegmentChoiceId, SortOrder    
    
	END TRY    
	BEGIN CATCH    
		insert into BsdLogging..AutoSaveLogging    
		values('usp_CreateUserChoice',    
		getdate(),    
		ERROR_MESSAGE(),    
		ERROR_NUMBER(),    
		ERROR_Severity(),    
		ERROR_LINE(),    
		ERROR_STATE(),    
		ERROR_PROCEDURE(),    
		concat('exec usp_CreateUserChoice ''',@InpChoiceJson,''',',@SegmentStatusId,',',@Segmentid,',''',@SegmentSource,''',''',@SegmentOrigin,''''),    
		@InpChoiceJson    
		)    
	END CATCH    
END
GO



