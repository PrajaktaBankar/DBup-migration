CREATE OR ALTER  FUNCTION [dbo].[fnGetSegmentDescriptionTextForChoice]
(  
 @segmentStatusId int
)  
RETURNS nvarchar(max)  
AS  
BEGIN
	
	-- Declare the return variable here  
	DECLARE @ChoiceCounter int=1,@ChoiceCount int=0
	DECLARE @OptionCounter int=1,@OptionCount int=0
	DECLARE @ItemCounter int=1,@ItemCount int=0
	DECLARE @OptionTypeName NVARCHAR(255),@SortOrder INT,@Value NVARCHAR(255),@Id INT
	DECLARE @ChoiceOptionText NVARCHAR(1024)
	DECLARE @ProjectId int,@origin nvarchar(2),@sectionId int,@segmentId int,@mSegmentId int,@mSegmentStatusId INT
	DECLARE @Description NVARCHAR(1024),@sourceTag VARCHAR(10)
	DECLARE @segmentDescription NVARCHAR(max)=''

	SELECT 
	@ProjectId=ProjectId,@origin=SegmentOrigin,@sectionId=SectionId,
	@segmentId=SegmentId,@mSegmentId=mSegmentId,@mSegmentStatusId=mSegmentStatusId
	FROM dbo.ProjectSegmentStatus with (nolock)
	WHERE SegmentStatusId=@segmentStatusId
	
  --All Choices
	DECLARE @AllChoices TABLE(srNo int,choiceCode int);

	--All Choices with Options
	DECLARE @ChoiceTable TABLE  
	(  
	srNo int,  
	choiceCode int,  
	optionJson nvarchar(max),  
	finalChoiceText nvarchar(max),
	sortOrder int
	);

	--Single Choice with Options
	DECLARE @ChoiceTableTemp TABLE  
	(  
	srNo int,  
	choiceCode int,  
	optionJson nvarchar(max),  
	optionText nvarchar(max),
	sortOrder int
	);

	--All Options in single choice
	DECLARE @ChoiceOptionTable TABLE  
	(  
	srNo int,  
	OptionTypeName varchar(200),  
	SortOrder int,  
	Value nvarchar(1024),  
	Id int  
	);

	-- Segment Description for given @SegmentId  
	DECLARE @ChoiceCode int=0
	DECLARE @OptionJson nvarchar(max)=''
	DECLARE @Saperator nvarchar(5)=''

  
   --Step 1 : Get Segment Description based on origin  
   IF(@origin='M')  
   BEGIN
		select TOP 1 @segmentDescription=SegmentDescription FROM [SLCMaster].[dbo].[Segment] WITH(NOLOCK) where SegmentId=@mSegmentId
		IF(EXISTS(select TOP 1 1 FROM [SLCMaster].[dbo].[SegmentChoice]  WITH (NOLOCK) where SegmentId=@mSegmentId))
		BEGIN
		
		-- All Choice Option for given Segment     
			INSERT INTO @ChoiceTable (srNo, ChoiceCode, optionJson, finalChoiceText,SortOrder)
				SELECT
					ROW_NUMBER() OVER (ORDER BY co.ChoiceOptionId) AS Id
				   ,sc.SegmentChoiceCode
				   ,co.OptionJson
				   ,''
				   ,co.SortOrder
				FROM [SLCMaster].[dbo].[SegmentChoice] AS sc  with (nolock)
				INNER JOIN [SLCMaster].[dbo].[ChoiceOption] AS co  with (nolock)
					ON sc.SegmentChoiceId = co.SegmentChoiceId
				INNER JOIN [SelectedChoiceOption] sco  with (nolock)
					ON  sco.SectionId=@sectionId
						AND sco.ChoiceOptionCode = co.ChoiceOptionCode
						AND sco.SegmentChoiceCode = sc.SegmentChoiceCode
				WHERE sc.SegmentStatusId=@mSegmentStatusId
				AND sco.SectionId=@sectionId
				AND sco.ProjectId=@ProjectId
				AND sco.IsSelected = 1 
				AND sco.ChoiceOptionSource='M'
				ORDER BY co.SortOrder;

				INSERT INTO @AllChoices
				SELECT distinct ROW_NUMBER() OVER (ORDER BY ChoiceCode) AS Id,* from
				(
				select distinct ChoiceCode from @ChoiceTable
				) as x

				--Get count of All Choices
				SET @ChoiceCount=(SELECT COUNT(1) FROM @AllChoices)

				WHILE(@ChoiceCounter<=@ChoiceCount)
				BEGIN
					SELECT @ChoiceCode=choiceCode FROM @AllChoices WHERE srNo=@ChoiceCounter
					SELECT TOP 1 @Saperator=IIF(ChoiceTypeId=2,' and ',IIF(ChoiceTypeId=3,' or ',''))
					 from [SLCMaster].[dbo].[SegmentChoice]  with (nolock) 
					 where SegmentStatusId=@mSegmentStatusId
					 and SegmentChoiceCode=@choiceCode
					--CLEAR @ChoiceTableTemp
					DELETE FROM @ChoiceTableTemp
					--Get all options
					INSERT INTO @ChoiceTableTemp
					SELECT  ROW_NUMBER() OVER (ORDER BY sortOrder ) AS Id,*
					FROM (
					SELECT DISTINCT ChoiceCode, optionJson, finalChoiceText,sortOrder FROM @ChoiceTable 
					WHERE choiceCode=@ChoiceCode) as x

					SET @optionCount=@@rowcount
					SET @OptionCounter=1
	
					--Iterate options
					WHILE(@OptionCounter<=@optionCount)
					BEGIN
						SELECT @OptionJson=optionJson FROM @ChoiceTableTemp WHERE srNo=@OptionCounter

						--CLEAR @ChoiceOptionTable
						DELETE FROM @ChoiceOptionTable
						--Get all items in options
						INSERT INTO @ChoiceOptionTable
						SELECT ROW_NUMBER() OVER (ORDER BY [SortOrder]) AS srNo,* FROM OPENJSON(@OptionJson)
						WITH (
							OptionTypeName NVARCHAR(200) '$.OptionTypeName',
							[SortOrder] INT '$.SortOrder',
							[Value] NVARCHAR(255) '$.Value',
							[Id] INT '$.Id'
						);

						SET @ItemCount=@@rowcount
						SET @ItemCounter=1
						SET @ChoiceOptionText=''
		
						--Iterate all items
						WHILE(@ItemCounter<=@ItemCount)
						BEGIN
							SELECT
								 @OptionTypeName = OptionTypeName
								,@SortOrder = SortOrder
								,@Value = Value
								,@Id = Id
							FROM @ChoiceOptionTable
							WHERE srNo = @ItemCounter

							IF (@OptionTypeName IN('CustomText','NoneNA','GlobalTerm', 'UnitOfMeasure'))
							BEGIN
								SET @ChoiceOptionText = CONCAT(@ChoiceOptionText,' ', @Value,' ')
							END 
							ELSE IF (@OptionTypeName IN('FillInBlank'))
							BEGIN
								IF(@Value='' OR @Value is null)
									SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, ' [_______] ')
								ELSE 
									SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value,' ')
							END 
						 
							ELSE IF(@OptionTypeName='SectionID')  
							BEGIN
								SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, (SELECT
									SourceTag
								FROM SLCMaster.dbo.Section WITH (NOLOCK)
								WHERE sectionid = @Id),' ')
							END  
							ELSE IF(@OptionTypeName='ReferenceStandard')  
							BEGIN
								SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value,' ')
  
							END  
							ELSE IF(@OptionTypeName='ReferenceEditionDate')  
							BEGIN
								SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value, '')
							END  
							ELSE IF(@OptionTypeName='SectionTitle')  
							BEGIN
								SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, (SELECT
									Description FROM SLCMaster.dbo.Section WITH (NOLOCK) WHERE sectionid = @Id),' '
								)
							END
							SET @ItemCounter=@ItemCounter+1
						END
		
						UPDATE @ChoiceTableTemp
						SET optionText=@ChoiceOptionText
						WHERE srNo=@OptionCounter and ChoiceCode=@ChoiceCode
					
						SET @OptionCounter=@OptionCounter+1
					END

					--set @ChoiceOptionText=(SELECT optionText+',' FROM @ChoiceTableTemp WHERE choiceCode=@ChoiceCode FOR XML PATH(''))
					DECLARE @count int,@i int=2

					SELECT @count=count(1) FROM @ChoiceTableTemp
					SELECT TOP 1 @ChoiceOptionText=optionText FROM @ChoiceTableTemp
					WHILE (@i<@count)
					BEGIN
						SET @ChoiceOptionText=CONCAT(@ChoiceOptionText,', ',(SELECT optionText FROM @ChoiceTableTemp WHERE srNo=@i))
						SET @i=@i+1
					END

					IF(@count>1)
					SET @ChoiceOptionText=CONCAT(@ChoiceOptionText,@Saperator,(SELECT optionText FROM @ChoiceTableTemp WHERE srNo=@i))

					SET @segmentDescription = REPLACE(@segmentDescription, CONCAT('{CH#', @choiceCode, '}'), @ChoiceOptionText)

					SET	@ChoiceCounter=@ChoiceCounter+1
				END
			END
	   END  
	   ELSE IF(@origin='U')  
	   BEGIN
			select TOP 1 @segmentDescription=SegmentDescription FROM [dbo].[ProjectSegment] WITH(NOLOCK) where SegmentStatusId=@segmentStatusId and SectionId=@SectionId 
			
			IF(EXISTS(select 1 from [ProjectSegmentChoice] with (nolock) where SectionId=@sectionId and SegmentStatusId=@segmentStatusId))
			BEGIN

			-- store all choices WITH OPTIONS
			INSERT INTO @ChoiceTable (srNo, ChoiceCode, optionJson, finalChoiceText,sortOrder)
			SELECT  
			ROW_NUMBER() OVER (ORDER BY co.ChoiceOptionId) AS Id
			,sc.SegmentChoiceCode
			,co.OptionJson
			,''   
			,co.SortOrder
			FROM [ProjectSegmentChoice] AS sc  with (nolock)
			INNER JOIN [ProjectChoiceOption] AS co with (nolock)
			ON co.SectionId = sc.SectionId
			and sc.SegmentChoiceId = co.SegmentChoiceId
			INNER JOIN [SelectedChoiceOption] sco with (nolock)
			ON sco.SectionId = sc.SectionId
			AND sco.ProjectId = sc.ProjectId
			AND sco.SegmentChoiceCode = sc.SegmentChoiceCode
			and sco.ChoiceOptionCode=co.ChoiceOptionCode
			WHERE sc.SectionId=@sectionId and  
			sc.SegmentStatusId=@segmentStatusId
			AND sco.IsSelected = 1  and sco.ChoiceOptionSource='U'
			ORDER BY co.SortOrder,sc.SegmentChoiceCode;

			--GET ALL CHOICES WITHOUT OPTIONS
			INSERT INTO @AllChoices
			SELECT distinct ROW_NUMBER() OVER (ORDER BY ChoiceCode) AS Id,* from
			(
			select distinct ChoiceCode from @ChoiceTable
			) as x

			--Get count of All Choices
			SET @ChoiceCount=(SELECT COUNT(1) FROM @AllChoices)
			--Iterate choices
			WHILE(@ChoiceCounter<=@ChoiceCount)
			BEGIN
				SELECT @ChoiceCode=choiceCode FROM @AllChoices WHERE srNo=@ChoiceCounter
				SELECT TOP 1 @Saperator=IIF(ChoiceTypeId=2,' and ',IIF(ChoiceTypeId=3,' or ','')) 
				from [dbo].[ProjectSegmentChoice] with (nolock)
				where SectionId=@sectionId and SegmentStatusId=@segmentStatusId
				AND SegmentChoiceCode=@choiceCode

				--CLEAR @ChoiceTableTemp
				DELETE FROM @ChoiceTableTemp
				--Get all options
				--INSERT INTO @ChoiceTableTemp
				--SELECT ROW_NUMBER() OVER (ORDER BY srNo) AS Id,ChoiceCode, optionJson, finalChoiceText FROM @ChoiceTable WHERE choiceCode=@ChoiceCode
				INSERT INTO @ChoiceTableTemp
				SELECT  ROW_NUMBER() OVER (ORDER BY sortOrder ) AS Id,*
				FROM (
				SELECT DISTINCT ChoiceCode, optionJson, finalChoiceText,sortOrder FROM @ChoiceTable WHERE choiceCode=@ChoiceCode) as x

				SET @optionCount=@@rowcount
				SET @OptionCounter=1
			  
				--Iterate options
				WHILE(@OptionCounter<=@optionCount)
				BEGIN
					SELECT @OptionJson=optionJson FROM @ChoiceTableTemp WHERE srNo=@OptionCounter

					--CLEAR @ChoiceOptionTable
					DELETE FROM @ChoiceOptionTable
					--Get all items in options
					INSERT INTO @ChoiceOptionTable
					SELECT ROW_NUMBER() OVER (ORDER BY [SortOrder]) AS srNo,* FROM OPENJSON(@OptionJson)
					WITH (
						OptionTypeName NVARCHAR(200) '$.OptionTypeName',
						[SortOrder] INT '$.SortOrder',
						[Value] NVARCHAR(255) '$.Value',
						[Id] INT '$.Id'
					);

					SET @ItemCount=@@rowcount
					SET @ItemCounter=1
					SET @ChoiceOptionText=''
		
					--Iterate all items
					WHILE(@ItemCounter<=@ItemCount)
					BEGIN
						SELECT
							 @OptionTypeName = OptionTypeName
							,@SortOrder = SortOrder
							,@Value = Value
							,@Id = Id
						FROM @ChoiceOptionTable
						WHERE srNo = @ItemCounter

						IF (@OptionTypeName IN('CustomText','NoneNA','GlobalTerm', 'UnitOfMeasure'))
						BEGIN
							SET @ChoiceOptionText = CONCAT(@ChoiceOptionText,' ', @Value,' ')
						END 
						ELSE IF (@OptionTypeName IN('FillInBlank'))
						BEGIN
							IF(@Value='' OR @Value is null)
								SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, ' [_______] ')
							ELSE 
								SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value,' ')
						END 
						ELSE IF(@OptionTypeName='SectionID')  
						BEGIN
							SET @ChoiceOptionText =	CONCAT(@ChoiceOptionText,@Value,' ')
							--set @sourceTag=(SELECT
							--SourceTag
							--FROM [SLCProject].[dbo].[ProjectSection]
							--WHERE sectionid = @Id and ProjectId=@ProjectId)

							--SET @ChoiceOptionText = CONCAT(@ChoiceOptionText,iif(@sourceTag is null OR LEN(@sourceTag)<=0,(SELECT
							--	SourceTag
							--FROM SLCMaster.dbo.Section
							--WHERE sectionid = @Id),@sourceTag)
							--)
  
						END  
						ELSE IF(@OptionTypeName='ReferenceStandard')  
						BEGIN
							SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value,' ')
  
						END  
						ELSE IF(@OptionTypeName='ReferenceEditionDate')  
						BEGIN
  
							SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value,'')
  
						END  
						ELSE IF(@OptionTypeName='SectionTitle')  
						BEGIN

						SET @Description=(SELECT
							Description
							FROM [ProjectSection] with (nolock)
							WHERE sectionid = @Id and ProjectId=@ProjectId)

							SET @ChoiceOptionText = CONCAT(@ChoiceOptionText,iif(@Description is null,(SELECT
								Description
							FROM SLCMaster.dbo.Section WITH (NOLOCK)
							WHERE sectionid = @Id),@Description),' '
							)
							--SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, (SELECT
							--Description
							--FROM [SLCProject].[dbo].[ProjectSection]
							--WHERE sectionid = @Id)
							--)
  
						END
					
						SET @ItemCounter=@ItemCounter+1
					END
		
					UPDATE @ChoiceTableTemp
					SET optionText=@ChoiceOptionText
					WHERE srNo=@OptionCounter and ChoiceCode=@ChoiceCode

					SET @OptionCounter=@OptionCounter+1
				END

				
				SELECT @count=count(1) FROM @ChoiceTableTemp
				SELECT TOP 1 @ChoiceOptionText=optionText FROM @ChoiceTableTemp
				WHILE (@i<@count)
				BEGIN
					SET @ChoiceOptionText=CONCAT(@ChoiceOptionText,', ',(SELECT optionText FROM @ChoiceTableTemp WHERE srNo=@i))
					SET @i=@i+1
				END

				IF(@count>1)
				SET @ChoiceOptionText=CONCAT(@ChoiceOptionText,@Saperator,(SELECT optionText FROM @ChoiceTableTemp WHERE srNo=@i))
	           
				SET @segmentDescription = REPLACE(@segmentDescription, CONCAT('{CH#', @choiceCode, '}'), @ChoiceOptionText)

				SET	@ChoiceCounter=@ChoiceCounter+1
			END
			END
	   END
  
   return @segmentDescription;
END
GO
Print '1. fnGetSegmentDescriptionTextForChoice'
go

 CREATE OR ALTER FUNCTION [dbo].[fnGetSegmentDescriptionTextForRSAndGT]    
(    
 @ProjectId int,    
 @CustomerId int,    
 @segmentDescription NVARCHAR(MAX)    
)RETURNS NVARCHAR(MAX)    
AS    
BEGIN    
SELECT    
 @segmentDescription = REPLACE(@segmentDescription,    
 CONCAT('{RS#', CONVERT(NVARCHAR(MAX), prs.RefStdCode), '}'), rs.RefStdName)    
FROM [dbo].[ProjectReferenceStandard] prs WITH(NOLOCK)  Inner JOIN ReferenceStandard rs WITH(NOLOCK)  
ON prs.RefStandardId=rs.RefStdId  
 WHERE prs.ProjectId=@ProjectId and prs.CustomerId=@CustomerId  
  
SELECT    
 @segmentDescription = REPLACE(@segmentDescription,    
 CONCAT('{RS#', CONVERT(NVARCHAR(MAX), RefStdCode), '}'), RefStdName)    
FROM [SLCMaster].[dbo].[ReferenceStandard] WITH(NOLOCK)    
    
 IF @segmentDescription LIKE '%{RSTEMP#%'    
 BEGIN    
  DECLARE @RSCode INT = 0;    
  SELECT @RSCode = LEFT(Val, PATINDEX('%[^0-9]%', Val + 'a') - 1)     
  FROM (SELECT SUBSTRING(@segmentDescription, PATINDEX('%[0-9]%', @segmentDescription), LEN(@segmentDescription)) Val) RSCode    
    
  SELECT    
   @segmentDescription = CONCAT(RSEdition.RefStdName, ' - ', RSEdition.RefStdTitle + '; ' + RSEdition.RefEdition + '.')    
  FROM (SELECT TOP 1    
    RSE.RefStdTitle    
      ,RSE.RefEdition    
      ,RS.RefStdName    
      ,RS.RefStdCode    
   FROM [SLCMaster].[dbo].[ReferenceStandard] RS WITH(NOLOCK)    
   INNER JOIN [SLCMaster].[dbo].[ReferenceStandardEdition] RSE WITH(NOLOCK)    
    ON RS.RefStdId = RSE.RefStdId    
   WHERE RS.RefStdCode = @RSCode    
   ORDER BY RSE.RefStdEditionId DESC) RSEdition    
    
  SELECT    
   @segmentDescription = CONCAT(RSEdition.RefStdName, ' - ', RSEdition.RefStdTitle + '; ' + RSEdition.RefEdition + '.')    
  FROM (SELECT TOP 1    
    RSE.RefStdTitle    
      ,RSE.RefEdition    
      ,RS.RefStdName    
      ,RS.RefStdCode    
   FROM [ReferenceStandard] RS WITH(NOLOCK)    
   INNER JOIN [ReferenceStandardEdition] RSE WITH(NOLOCK)    
    ON RS.RefStdId = RSE.RefStdId    
   WHERE RS.RefStdCode = @RSCode    
   ORDER BY RSE.RefStdEditionId DESC) RSEdition    
 END    
    
  --Commented for Bug: Location related GT are not appearing with Project Value in "Submittals Log Report  
--SELECT    
-- @segmentDescription = REPLACE(@segmentDescription,    
-- CONCAT('{GT#', CONVERT(NVARCHAR(MAX), GlobalTermCode), '}'), [Value])    
--FROM [SLCMaster].[dbo].[GlobalTerm] WITH(NOLOCK)    
    
  
    
SELECT    
 @segmentDescription = REPLACE(@segmentDescription,    
 CONCAT('{GT#', CONVERT(NVARCHAR(MAX), GlobalTermCode), '}'), [Value])    
FROM [dbo].[ProjectGlobalTerm] WITH(NOLOCK)    
WHERE ProjectId = @ProjectId    
AND CustomerId = @CustomerId    
AND ISNULL(IsDeleted,0) = 0    
    
    
RETURN @segmentDescription;    
    
END
GO
Print '2. fnGetSegmentDescriptionTextForRSAndGT'
go

 CREATE OR ALTER PROCEDURE [dbo].[usp_ActionOnChoiceOptionModify]     
(        
@OptionListJson NVARCHAR(MAX),        
@SegmentChoiceId INT,    
@SegmentChoiceCode INT,    
@ChoiceAction INT = 1 ,   
@SegmentStatusId INT=0  
)           
AS    
BEGIN  
	BEGIN TRY   
		DECLARE @POptionListJson NVARCHAR(MAX) = @OptionListJson  
		DECLARE @PSegmentChoiceId INT = @SegmentChoiceId  
		DECLARE @PSegmentChoiceCode INT = @SegmentChoiceCode  
		DECLARE @PChoiceAction INT = @ChoiceAction  
		DECLARE @PSegmentStatusId INT = @SegmentStatusId  
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
		ChoiceOptionCode INT NULL,        
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
		ChoiceOptionCode INT '$.ChoiceOptionCode',  
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
		DECLARE @ChoiceOptionCode INT = 0;  
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
			ON SCO.SectionId = PCO.SectionId  
			AND SCO.ChoiceOptionCode = PCO.ChoiceOptionCode  
			AND SCO.SegmentChoiceCode = @SegmentChoiceCode  
			WHERE PCO.SegmentChoiceId = @SegmentChoiceId  
			AND PCO.SectionId = @SectionId  
			AND PCO.ChoiceOptionSource = @ChoiceOptionSource  
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
			ON SCO.SectionId = PCO.SectionId  
			AND SCO.ChoiceOptionCode = PCO.ChoiceOptionCode  
			AND SCO.SegmentChoiceCode = @SegmentChoiceCode  
			WHERE PCO.SegmentChoiceId = @SegmentChoiceId  
			AND PCO.SectionId = @SectionId  
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
Print '3. usp_ActionOnChoiceOptionModify'
go

CREATE OR ALTER PROCEDURE [dbo].[usp_CopyProject]                  
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
DROP TABLE IF EXISTS #tmp_SrcSegmentStatus;      
DROP TABLE IF EXISTS #tmp_TgtSegmentStatus;      
DROP TABLE IF EXISTS #tmp_SrcSegment;      
DROP TABLE IF EXISTS #tmp_TgtSegment;      
DROP TABLE IF EXISTS #tmp_SrcSegmentChoice;      
DROP TABLE IF EXISTS #tmp_SrcSelectedChoiceOption;      
DROP TABLE IF EXISTS #tmp_TgtSegmentChoice;      
DROP TABLE IF EXISTS #tmp_SrcSegmentLink;      
DROP TABLE IF EXISTS #tmp_TgtProjectNote;      
DROP TABLE IF EXISTS #tmp_SrcProjectSegmentRequirementTag;      
      
      
      
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
SET P.TemplateId = P_Src.TemplateId      
--,P.ModifiedBy = P_Src.ModifiedBy                
--,P.ModifiedDate = P_Src.ModifiedDate                
--,P.ModifiedByFullName = P_Src.ModifiedByFullName                
FROM Project P WITH (NOLOCK)      
INNER JOIN Project P_Src WITH (NOLOCK)      
 ON P_Src.ProjectId = @SourceProjectId      
WHERE P.ProjectId = @TargetProjectId;      
      
--UPDATE LastAccessed and LastAccessByFullName in target project                
UPDATE UF      
SET --UF.LastAccessed = UF_Src.LastAccessed                
UF.LastAccessByFullName = UF_Src.LastAccessByFullName      
FROM UserFolder UF WITH (NOLOCK)      
INNER JOIN UserFolder UF_Src WITH (NOLOCK)      
 ON UF_Src.ProjectId = @SourceProjectId      
WHERE UF.ProjectId = @TargetProjectId;      
      
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
 PS.* INTO #tmp_SrcSection      
FROM ProjectSection PS WITH (NOLOCK)      
WHERE PS.ProjectId = @SourceProjectId      
AND PS.CustomerId = @CustomerId      
AND ISNULL(PS.IsDeleted, 0) = 0;      
      
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
      
--Copy target sections in temp table                  
SELECT      
 PS.SectionId      
   ,PS.ParentSectionId      
   ,PS.ProjectId      
   ,PS.CustomerId      
   ,PS.IsLastLevel      
   ,PS.SectionCode      
   ,PS.IsDeleted      
   ,PS.A_SectionId INTO #tmp_TgtSection      
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
 PSST.* INTO #tmp_SrcSegmentStatus      
FROM ProjectSegmentStatus PSST WITH (NOLOCK)      
WHERE PSST.ProjectId = @SourceProjectId      
AND PSST.CustomerId = @CustomerId      
AND ISNULL(PSST.IsDeleted, 0) = 0      
      
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
 FROM #tmp_SrcSegmentStatus PSST_Src WITH (NOLOCK)      
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)      
  ON PSST_Src.SectionId = PS.A_SectionId      
      
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
SELECT      
 PSG.* INTO #tmp_SrcSegment      
FROM ProjectSegment PSG WITH (NOLOCK)      
WHERE PSG.ProjectId = @SourceProjectId      
AND PSG.CustomerId = @CustomerId      
AND ISNULL(PSG.IsDeleted, 0) = 0      
      
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
 PCH.* INTO #tmp_SrcSegmentChoice      
FROM ProjectSegmentChoice PCH WITH (NOLOCK)      
WHERE PCH.ProjectId = @SourceProjectId      
AND PCH.CustomerId = @CustomerId      
AND ISNULL(PCH.IsDeleted, 0) = 0      
      
--INSERT ProjectSegmentChoice                
INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource,      
SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted, A_SegmentCHoiceId)      
 SELECT      
  PS.SectionId AS SectionId      
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
 INNER JOIN #tmp_SrcSegmentStatus SRCS      
  ON PCH_Src.SegmentId = SRCS.SegmentId      
 WHERE ISNULL(SRCS.IsDeleted, 0) = 0      
      
      
--Copy target choices in temp table                
SELECT      
 PCH.* INTO #tmp_TgtSegmentChoice      
FROM ProjectSegmentChoice PCH WITH (NOLOCK)      
WHERE PCH.ProjectId = @TargetProjectId      
AND PCH.CustomerId = @CustomerId      
AND ISNULL(PCH.IsDeleted, 0) = 0      
      
--INSERT ProjectChoiceOption                    
INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId,      
CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted, A_ChoiceOptionId)      
 SELECT      
  PCH.SegmentChoiceId AS SegmentChoiceId      
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
 AND PCHOP_Src.CustomerId = @CustomerId;      
      
--Copy source choices in temp table                
SELECT      
 SCO_Src.* INTO #tmp_SrcSelectedChoiceOption      
FROM SelectedChoiceOption SCO_Src WITH (NOLOCK)      
WHERE SCO_Src.ProjectId = @SourceProjectId      
AND SCO_Src.CustomerId = @CustomerId      
AND ISNULL(SCO_Src.IsDeleted, 0) = 0      
      
--INSERT SelectedChoiceOption                
INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected,      
SectionId, ProjectId, CustomerId, OptionJson, IsDeleted)      
 SELECT      
  PSCHOP_Src.SegmentChoiceCode AS SegmentChoiceCode      
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
 --AND PSCHOP_Src.SegmentChoiceCode = PSC.SegmentChoiceCode            
 WHERE PSCHOP_Src.ProjectId = @SourceProjectId      
 AND PSCHOP_Src.CustomerId = @CustomerId      
--AND ISNULL(PSCHOP_Src.IsDeleted,0)=0;            
      
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
      
SELECT      
 * INTO #tmp_SrcSegmentLink      
FROM ProjectSegmentLink WITH (NOLOCK)      
WHERE ProjectId = @SourceProjectId      
AND CustomerId = @CustomerId      
AND ISNULL(IsDeleted, 0) = 0      
      
--INSERT ProjectSegmentLink                      
INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,      
TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget,      
LinkStatusTypeId, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId,      
SegmentLinkCode, SegmentLinkSourceTypeId)      
 SELECT      
  PSL_Src.SourceSectionCode      
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
--WHERE ProjectId = @SourceProjectId                
--AND CustomerId = @CustomerId;                
      
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
INSERT INTO ProjectNote (SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId,      
CustomerId, Title, CreatedBy, ModifiedBy, CreatedUserName, ModifiedUserName, IsDeleted, NoteCode, A_NoteId)      
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
 FROM ProjectNote PNT_Src WITH (NOLOCK)      
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)      
  ON PNT_Src.SectionId = PS.A_SectionId      
 INNER JOIN #tmp_TgtSegmentStatus PSST WITH (NOLOCK)      
  ON PNT_Src.SegmentStatusId = PSST.A_SegmentStatusId      
 WHERE PNT_Src.ProjectId = @SourceProjectId      
 AND PNT_Src.CustomerId = @CustomerId;      
      
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
   ,PN.A_NoteId INTO #tmp_TgtProjectNote      
FROM ProjectNote PN WITH (NOLOCK)      
WHERE PN.ProjectId = @SourceProjectId      
AND PN.CustomerId = @CustomerId      
AND ISNULL(IsDeleted, 0) = 0      
      
      
--INSERT ProjectNoteImage                
INSERT INTO ProjectNoteImage (NoteId, SectionId, ImageId, ProjectId, CustomerId)      
 SELECT      
  PN.NoteId AS NoteId      
    ,PS.SectionId AS SectionId      
    ,PNTI_Src.ImageId AS ImageId      
    ,@TargetProjectId AS ProjectId      
    ,@CustomerId AS CustomerId      
 FROM ProjectNoteImage PNTI_Src WITH (NOLOCK)      
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)      
  ON PNTI_Src.SectionId = PS.A_SectionId      
 INNER JOIN #tmp_TgtProjectNote PN WITH (NOLOCK)      
  ON PN.ProjectId = @TargetProjectId      
   AND PNTI_Src.NoteId = PN.A_NoteId      
 WHERE PNTI_Src.ProjectId = @SourceProjectId      
 AND PNTI_Src.CustomerId = @CustomerId;      
      
      
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
   ,Psmry.ProjectAccessTypeId = Psmry_Src.ProjectAccessTypeId      
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
INSERT INTO ProjectHyperLink (SectionId, SegmentId, SegmentStatusId, ProjectId,      
CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy      
, A_HyperLinkId)      
 SELECT      
  PSS_Target.sectionId      
    ,PSS_Target.SegmentId      
    ,PSS_Target.SegmentStatusId      
    ,PSS_Target.ProjectId      
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
 WHERE PHL.ProjectId = @PSourceProjectId      
      
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
      
EXEC usp_SendEmailCopyProjectFailedJob      
END CATCH      
END
GO
Print '4. usp_CopyProject'
go


CREATE OR ALTER PROCEDURE [dbo].[usp_CreateGlobalTerms] 
@Name  NVARCHAR(max) NULL,
@Value NVARCHAR(max) NULL,
@CreatedBy INT NULL,
@CustomerId INT NULL,
@ProjectId INT NULL
AS      
BEGIN
DECLARE @PName NVARCHAR(max) = @Name;
DECLARE @PValue NVARCHAR(max) = @Value;
DECLARE @PCreatedBy INT = @CreatedBy;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PProjectId INT = @ProjectId;
SET NOCOUNT ON;

    --DECLARE @ProjectIdList TABLE (ProjectId INT);
	DECLARE @GlobalTermCode INT=0;
	DECLARE @UserGlobalTermId INT = NULL
	DECLARE @MaxGlobalTermCode INT = ( SELECT TOP 1
		GlobalTermCode
	FROM ProjectGlobalTerm(Nolock)
	WHERE CustomerId = @PCustomerId
	ORDER BY GlobalTermCode DESC)

--DECLARE @GlobalTermValues TABLE (
--	ProjectId INT
--   ,CustomerId INT
--   ,Name NVARCHAR(MAX)
--   ,Value NVARCHAR(MAX)
--   ,GlobalTermSource NVARCHAR(MAX)
--   ,CreatedDate DATETIME2(7)
--   ,CreatedBy INT
--   ,UserGlobalTermId INT
--   ,UniqueGlobalTermCode INT
--);

INSERT INTO [UserGlobalTerm] (Name, Value, CreatedDate, CreatedBy, CustomerId, ProjectId, IsDeleted)
	VALUES (@PName, @PValue, GETUTCDATE(), @PCreatedBy, @PCustomerId, @PProjectId, 0)
SET @UserGlobalTermId = SCOPE_IDENTITY();

--INSERT INTO @ProjectIdList (ProjectId)
--	SELECT DISTINCT
--		(ProjectId)
--	FROM [dbo].[ProjectGlobalTerm] (NoLock)
--	WHERE CustomerId = @PCustomerId;

INSERT INTO [ProjectGlobalTerm] (ProjectId, CustomerId, Name, Value, GlobalTermSource, CreatedDate, CreatedBy, UserGlobalTermId, GlobalTermCode)
	SELECT
		P.ProjectId
	   ,@PCustomerId
	   ,@PName
	   ,@PValue
	   ,'U'
	   ,GETUTCDATE()
	   ,@PCreatedBy
	   ,@UserGlobalTermId
	   --,ROW_NUMBER() OVER (ORDER BY P.ProjectId ASC) + @MaxGlobalTermCode
	   ,@MaxGlobalTermCode+1
	FROM Project P WITH(NOLOCK)
	WHERE P.CustomerId = @PCustomerId
	AND P.IsDeleted = 0;

SELECT TOP 1
	GlobalTermCode
FROM ProjectGlobalTerm WITH(NOLOCK)
WHERE ProjectId = @PProjectId
ORDER BY GlobalTermId DESC

END

GO
Print '5. usp_CreateGlobalTerms'
go

CREATE OR ALTER PROCEDURE [dbo].[usp_CreateNewProject] (
@Name NVARCHAR(MAX),  
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
DECLARE @PName NVARCHAR(MAX) = @Name;
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
	VALUES (@PName, @PIsOfficeMaster, @PDescription, @TemplateId, @PMasterDataTypeId, @PUserId, @PCustomerId, GETUTCDATE(), @PCreatedBy, @PCreatedBy, GETUTCDATE(), 0, NULL, 0, 0, @PGlobalProjectID, NULL, NULL, NULL, @PModifiedByFullName)

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
	ProjectId
   ,[Name]
   ,IsOfficeMaster
   ,[Description]
   ,TemplateId
   ,MasterDataTypeId
   ,UserId
   ,CustomerId
   ,CreateDate
   ,CreatedBy
   ,ModifiedBy
   ,ModifiedDate
   ,IsDeleted
   ,IsMigrated
   ,IsNamewithHeld
   ,IsLocked
   ,GlobalProjectID
   ,IsPermanentDeleted
   ,A_ProjectId
   ,IsProjectMoved
   ,ModifiedByFullName
   ,ProjectId as Id
FROM Project WITH (NOLOCK)
WHERE ProjectId = @NewProjectId


END
GO
Print '6. usp_CreateNewProject'
go

CREATE OR ALTER PROCEDURE [dbo].[usp_CreateOrUpdatePrintSetting]          
 (      
 @ProjectId INT,      
 @CustomerId INT,             
 @UserId INT ,             
 @IsExportInMultipleFiles BIT = 0,          
 @IsBeginSectionOnOddPage BIT = 0,          
 @IsIncludeAuthorInFileName BIT = 0,          
 @TCPrintModeId INT=1,    
 @IsIncludePageCount BIT = 0,  
 @IsIncludeHyperLink BIT = 0,  
 @KeepWithNext BIT = 0,  
 @IsPrintMasterNote BIT = 0,  
 @IsPrintProjectNote BIT = 0,  
 @IsPrintNoteImage BIT = 0,  
 @IsPrintIHSLogo BIT = 0  
)AS                
BEGIN      
          
  DECLARE @PProjectId INT = @ProjectId          
  DECLARE @PCustomerId INT = @CustomerId             
  DECLARE @PUserId INT = @UserId             
  DECLARE @PIsExportInMultipleFiles BIT = @IsExportInMultipleFiles          
  DECLARE @PIsBeginSectionOnOddPage BIT = @IsBeginSectionOnOddPage          
  DECLARE @PIsIncludeAuthorInFileName BIT = @IsIncludeAuthorInFileName          
  DECLARE @PTCPrintModeId  INT = @TCPrintModeId      
  DECLARE @PIsIncludePageCount BIT = @IsIncludePageCount         
  DECLARE @PIsIncludeHyperLink BIT = @IsIncludeHyperLink    
  DECLARE @PKeepWithNext BIT = @KeepWithNext        
  DECLARE @PIsPrintMasterNote BIT = @IsPrintMasterNote  
  DECLARE @PIsPrintProjectNote BIT = @IsPrintProjectNote  
  DECLARE @PIsPrintNoteImage BIT = @IsPrintNoteImage  
  DECLARE @PIsPrintIHSLogo BIT = @IsPrintIHSLogo   
          
  IF NOT EXISTS (SELECT TOP 1      
  1      
 FROM ProjectPrintSetting WITH (NOLOCK)      
 WHERE CustomerId = @PCustomerId      
 AND ProjectId = @PProjectId)      
BEGIN      
INSERT INTO ProjectPrintSetting (ProjectId, CustomerId, CreatedBy, CreateDate, ModifiedBy,      
ModifiedDate, IsExportInMultipleFiles, IsBeginSectionOnOddPage, IsIncludeAuthorInFileName, TCPrintModeId,IsIncludePageCount,IsIncludeHyperLink, KeepWithNext,  
   IsPrintMasterNote, IsPrintProjectNote, IsPrintNoteImage, IsPrintIHSLogo)      
 VALUES (@PProjectId, @PCustomerId, @PUserId, GETUTCDATE(), @PUserId, GETUTCDATE(), @PIsExportInMultipleFiles, @PIsBeginSectionOnOddPage, @PIsIncludeAuthorInFileName,   
 @PTCPrintModeId,@PIsIncludePageCount,@PIsIncludeHyperLink ,@PKeepWithNext, @PIsPrintMasterNote, @PIsPrintProjectNote, @PIsPrintNoteImage, @PIsPrintIHSLogo )      
END      
ELSE      
BEGIN      
UPDATE PPS      
SET PPS.IsExportInMultipleFiles = COALESCE(@PIsExportInMultipleFiles, PPS.IsExportInMultipleFiles)      
   ,PPS.IsBeginSectionOnOddPage = COALESCE(@PIsBeginSectionOnOddPage, PPS.IsBeginSectionOnOddPage)      
   ,PPS.IsIncludeAuthorInFileName = COALESCE(@IsIncludeAuthorInFileName, PPS.IsIncludeAuthorInFileName)      
   ,PPS.TCPrintModeId = COALESCE(@PTCPrintModeId, PPS.TCPrintModeId)      
   ,PPS.ModifiedBy = @PUserId      
   ,PPS.ModifiedDate = GETUTCDATE()      
   ,PPS.IsIncludePageCount=COALESCE(@PIsIncludePageCount, PPS.IsIncludePageCount)      
   ,PPS.IsIncludeHyperLink=COALESCE(@PIsIncludeHyperLink, PPS.IsIncludeHyperLink)  
   ,PPS.KeepWithNext=COALESCE(@PKeepWithNext, PPS.KeepWithNext)      
   ,PPS.IsPrintMasterNote=COALESCE(@PIsPrintMasterNote, PPS.IsPrintMasterNote)   
   ,PPS.IsPrintProjectNote=COALESCE(@PIsPrintProjectNote, PPS.IsPrintProjectNote)   
   ,PPS.IsPrintNoteImage=COALESCE(@PIsPrintNoteImage, PPS.IsPrintNoteImage)   
   ,PPS.IsPrintIHSLogo=COALESCE(@PIsPrintIHSLogo, PPS.IsPrintIHSLogo)      
FROM ProjectPrintSetting PPS WITH (NOLOCK)      
WHERE PPS.CustomerId = @PCustomerId      
AND PPS.ProjectId = @PProjectId      
END      
END
GO
Print '7. usp_CreateOrUpdatePrintSetting'
go

CREATE OR ALTER PROCEDURE [dbo].[usp_CreateSegmentsForImportedSection]      
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
DECLARE @IsAutoSelectParagraph BIT = 0;  
    
 --DECLARE INP SEGMENT TABLE     
 CREATE TABLE #InpSegmentTableVar (      
	 RowId INT NULL,
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
 RowId INT '$.rowId',  
 SectionId INT '$.sectionId',  
 ParentSegmentStatusId INT '$.parentSegmentStatusId',  
 IndentLevel TINYINT '$.indentLevel',  
 SegmentStatusTypeId INT '$.segmentStatusTypeId',  
 IsParentSegmentStatusActive BIT '$.isParentSegmentStatusActive',  
 SpecTypeTagId INT '$.SpecTypeTagId',  
 ProjectId INT '$.projectId',  
 CustomerId NVARCHAR(MAX) '$.customerId',  
 CreatedBy INT '$.createdBy',  
 IsRefStdParagraph BIT '$.isRefStdParagraph',  
 SequenceNumber DECIMAL(18, 4) '$.sequenceNumber',  
 TempSegmentStatusId BIT '$.tempSegmentStatusId',  
 SegmentStatusId INT '$.segmentStatusId'
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
  
--CHECK SETTING OF AUTOSELECT PARAGRAPH    
IF EXISTS (SELECT  
   top 1 1  
  FROM CustomerGlobalSetting with(nolock)  
  WHERE CustomerId = @CustomerId  
  AND UserId = @UserId)  
BEGIN  
SET @IsAutoSelectParagraph = (SELECT TOP 1  
  --IsAutoSelectParagraph    
  IsAutoSelectForImport  
 FROM CustomerGlobalSetting with(nolock)  
 WHERE CustomerId = @CustomerId  
 AND UserId = @UserId  
 ORDER BY CustomerGlobalSettingId DESC)  
END    
ELSE IF EXISTS (SELECT  
  top 1 1  
 FROM CustomerGlobalSetting  with(nolock)  
 WHERE CustomerId IS NULL  
 AND UserId IS NULL)  
BEGIN  
SET @IsAutoSelectParagraph = (SELECT TOP 1  
  --IsAutoSelectParagraph    
  IsAutoSelectForImport  
 FROM CustomerGlobalSetting  with(nolock)  
 WHERE CustomerId IS NULL  
 AND UserId IS NULL  
 ORDER BY CustomerGlobalSettingId DESC)  
END  
  
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
IsShowAutoNumber, CreateDate, CreatedBy, IsRefStdParagraph,mSegmentStatusId, mSegmentId)  
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
INNER JOIN ProjectSegmentStatus PSST with(nolock)  
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
FROM ProjectSegmentStatus PSST with(nolock)  
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
FROM ProjectSegmentStatus PSST with(nolock)  
INNER JOIN ProjectSegment PSG with(nolock)  
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
INNER JOIN ProjectSegmentStatus PSST with(nolock)  
 ON PSST.ProjectId = @ProjectId  
  AND PSST.CustomerId = @CustomerId  
  AND PSST.SectionId = @SectionId  
  AND PSST.SegmentStatusId = INPTBL.SegmentStatusId  
END  
GO
Print '8. usp_CreateSegmentsForImportedSection'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_CreateSpecDataSegments] (@ProjectId INT,
@CustomerId INT,
@UserId INT,
@MasterSectionIdJson NVARCHAR(MAX))
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
	DECLARE @InputDataTable TABLE (
		RowId INT
	   ,SectionId INT
	   ,RequestId INT
	);

	IF @MasterSectionIdJson != ''
	BEGIN
		INSERT INTO @InputDataTable
			SELECT
				ROW_NUMBER() OVER (ORDER BY SectionId ASC) AS RowId
			   ,SectionId
			   ,RequestId
			FROM OPENJSON(@MasterSectionIdJson)
			WITH (
			SectionId INT '$.SectionId',
			RequestId INT '$.RequestId'
			);

		DECLARE @n INT = 1
		WHILE ((SELECT
				COUNT(SectionId)
			FROM @InputDataTable)
		>= @n)
		BEGIN
		DECLARE @SectionId INT;
		DECLARE @RequestId INT;

		(SELECT TOP 1
			@SectionId = SectionId
		   ,@RequestId = RequestId
		FROM @InputDataTable
		WHERE RowId = @n)


		EXECUTE usp_MapSegmentStatusFromMasterToProject @ProjectId
													   ,@SectionId
													   ,@CustomerId
													   ,@UserId

		EXEC usp_MaintainImportProjectProgress NULL
											  ,@ProjectId
											  ,NULL
											  ,@SectionId
											  ,@UserId
											  ,@CustomerId
											  ,@StepInprogress
											  ,@ProgressPer10  
											  ,0
											  ,"SpecAPI"
											  ,@RequestId;



		EXECUTE usp_MapSegmentChoiceFromMasterToProject @ProjectId
													   ,@SectionId
													   ,@CustomerId
													   ,@UserId

		EXEC usp_MaintainImportProjectProgress NULL
											  ,@ProjectId
											  ,NULL
											  ,@SectionId
											  ,@UserId
											  ,@CustomerId
											  ,@StepInprogress
											  ,@ProgressPer10  
											  ,0
											  ,'SpecAPI'
											  ,@RequestId;

		EXECUTE usp_MapProjectRefStands @ProjectId
									   ,@SectionId
									   ,@CustomerId
									   ,@UserId


		EXEC usp_MaintainImportProjectProgress NULL
											  ,@ProjectId
											  ,NULL
											  ,@SectionId
											  ,@UserId
											  ,@CustomerId
											  ,@StepInprogress
											  ,@ProgressPer30 --Percent
											  ,0
											  ,'SpecAPI'
											  ,@RequestId;

		EXECUTE usp_MapSegmentRequirementTagFromMasterToProject @ProjectId
															   ,@SectionId
															   ,@CustomerId
															   ,@UserId
		EXEC usp_MaintainImportProjectProgress NULL
											  ,@ProjectId
											  ,NULL
											  ,@SectionId
											  ,@UserId
											  ,@CustomerId
											  ,2
											  ,@ProgressPer40 --Percent
											  ,0
											  ,'SpecAPI'
											  ,@RequestId;

		EXECUTE usp_MapSegmentLinkFromMasterToProject @ProjectId
													 ,@SectionId
													 ,@CustomerId
													 ,@UserId
		EXEC usp_MaintainImportProjectProgress NULL
											  ,@ProjectId
											  ,NULL
											  ,@SectionId
											  ,@UserId
											  ,@CustomerId
											  ,@StepInprogress
											  ,@ProgressPer50 --Percent
											  ,0
											  ,'SpecAPI'
											  ,@RequestId;
		EXECUTE usp_UpdateSegmentStatus_ApplyMasterUpdate @ProjectId
														 ,@CustomerId
														 ,@SectionId

		EXEC usp_MaintainImportProjectProgress NULL
											  ,@ProjectId
											  ,NULL
											  ,@SectionId
											  ,@UserId
											  ,@CustomerId
											  ,@StepInprogress
											  ,@ProgressPer60 --Percent
											  ,0
											  ,'SpecAPI'
											  ,@RequestId;
		EXECUTE usp_DeleteSegmentRequirementTag_ApplyMasterUpdate @ProjectId
																 ,@CustomerId
																 ,@SectionId

		EXEC usp_MaintainImportProjectProgress NULL
											  ,@ProjectId
											  ,NULL
											  ,@SectionId
											  ,@UserId
											  ,@CustomerId
											  ,@StepInprogress
											  ,@ProgressPer65 --Percent
											  ,0
											  ,'SpecAPI'
											  ,@RequestId;
		SET @n = @n + 1;

		END

	END
END
GO
Print '9. usp_CreateSpecDataSegments'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_DeleteSection]  
(  
@ProjectId INT NULL,  
@CustomerId INT NULL,  
@SectionId INT = NULL,  
@UserId INT  
)  
AS  
BEGIN  
  
DECLARE @PprojectId INT = @ProjectId;  
DECLARE @PCustomerId INT = @CustomerId;  
DECLARE @PSectionId INT = @SectionId;  
DECLARE @PUserId INT = @UserId;  
  
DECLARE @IsSuccess BIT = 1;  
DECLARE @StatusCode NVARCHAR(20) = '';  
  
DECLARE @IsLocked BIT = 0;  
DECLARE @LockedBy INT = 0;  
DECLARE @LockedByFullName NVARCHAR(100) = 'N/A';  
DECLARE @IsLockedImportSection BIT = 0;  
  
SELECT TOP 1  
@IsLocked = PS.IsLocked,  
@LockedBy = PS.LockedBy,  
@LockedByFullName = PS.LockedByFullName,  
@IsLockedImportSection = PS.IsLockedImportSection  
FROM [ProjectSection] PS WITH (NOLOCK)  
WHERE PS.IsLastLevel = 1  
AND PS.IsLocked = 1  
AND PS.SectionId = @SectionId;  
  
IF (@IsLocked = 1 OR @IsLockedImportSection = 1)  
BEGIN  
SET @IsSuccess = 0;  
SET @StatusCode = 'LockedImportSection';  
-- Is Locked Section then give priority to this  
IF(@IsLocked = 1)  
SET @StatusCode = 'SectionLockedByUser';  
--SELECT @IsSuccess AS IsSuccess, @StatusCode AS StatusCode  
END  
ELSE  
BEGIN  
UPDATE PS  
SET PS.IsDeleted = 1  
from ProjectSection PS WITH (NOLOCK)  
WHERE PS.ProjectId = @PprojectId  
AND PS.SectionId = @PSectionId  
AND PS.CustomerId = @PCustomerId;  
  
UPDATE PSL  
SET PSL.IsDeleted = 1  
FROM ProjectSegmentLink PSL WITH (NOLOCK)  
INNER JOIN ProjectSection PS WITH (NOLOCK)  
ON PS.CustomerId = PSL.CustomerId  
AND PS.ProjectId = PSL.ProjectId  
AND (PS.SectionCode = PSL.SourceSectionCode  
OR PS.SectionCode = PSL.TargetSectionCode)  
WHERE PS.ProjectId = @PprojectId  
AND PS.SectionId = @PSectionId  
AND PS.CustomerId = @PCustomerId;  
  
SET @IsSuccess = 1;  
SET @StatusCode = 'SectionDeleted';  
END  
  
SELECT @IsSuccess AS IsSuccess, @StatusCode AS StatusCode;  
END
GO
Print '10. usp_DeleteSection'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_GetChoiceRSAndGTList]    
@CustomerId INT ,
@ProjectId INT ,
@SectionId INT = 0,
@choicesIds NVARCHAR (MAX),
@RSIds NVARCHAR (MAX) NULL,
@GTIds NVARCHAR (MAX) NULL

AS
BEGIN
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PchoicesIds NVARCHAR (MAX) = @choicesIds;
DECLARE @PRSIds NVARCHAR (MAX) = @RSIds;
DECLARE @PGTIds NVARCHAR (MAX) = @GTIds;

  CREATE TABLE #ProjectSegmentChoiceTemp
(
  SegmentId INT,
  mSegmentId INT,
  ChoiceTypeId INT,
  ChoiceSource NVARCHAR(MAX),
  SegmentChoiceCode INT,
  ChoiceOptionCode INT,
  IsSelected BIT,
  ChoiceOptionSource  CHAR(1),
  OptionJson NVARCHAR(MAX),
  SortOrder INT,
  SegmentChoiceId INT,
  ChoiceOptionId BIGINT,
  SelectedChoiceOptionId INT
);
SELECT DISTINCT
	[Key] AS [Index]
   ,[Value] AS SegmentChoiceCode INTO #TempChoiceCode
FROM OPENJSON(@PchoicesIds)

INSERT INTO #ProjectSegmentChoiceTemp (SegmentId,
mSegmentId,
ChoiceTypeId,
ChoiceSource,
SegmentChoiceCode,
ChoiceOptionCode,
IsSelected,
ChoiceOptionSource,
OptionJson,
SortOrder,
SegmentChoiceId,
ChoiceOptionId,
SelectedChoiceOptionId)
	SELECT
		0 AS SegmentId
	   ,MCH.SegmentId AS mSegmentId
	   ,MCH.ChoiceTypeId
	   ,'M' AS ChoiceSource
	   ,ISNULL(MCH.SegmentChoiceCode, 0) AS SegmentChoiceCode
	   ,ISNULL(MCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode
	   ,PSCHOP.IsSelected
	   ,PSCHOP.ChoiceOptionSource
	   ,MCHOP.OptionJson
	   ,MCHOP.SortOrder
	   ,MCH.SegmentChoiceId
	   ,MCHOP.ChoiceOptionId
	   ,PSCHOP.SelectedChoiceOptionId
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK)
		ON PSST.mSegmentId = MCH.SegmentId
	INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)
		ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId
	INNER JOIN SelectedChoiceOption PSCHOP WITH (NOLOCK)
		ON MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode
			AND PSCHOP.ChoiceOptionSource = 'M'
			AND PSCHOP.ProjectId = PSST.ProjectId
			AND PSCHOP.SectionId = PSST.SectionId
	INNER JOIN #TempChoiceCode T
		ON MCH.SegmentChoiceCode = T.SegmentChoiceCode
	WHERE PSST.ProjectId = @PProjectId
	AND PSST.SectionId = @PSectionId
	AND PSST.CustomerId = @PCustomerId

	--AND MCH.SegmentChoiceCode IN (SELECT
	--		SegmentChoiceCode
	--	FROM #TempChoiceCode)

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

	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
		ON PSST.ProjectId = PCH.ProjectId
			AND PSST.SectionId = PCH.SectionId
			AND PSST.CustomerId = PCH.CustomerId
			AND PSST.SegmentId = PCH.SegmentId
	INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)
		ON PSST.ProjectId = PCH.ProjectId
			AND PSST.SectionId = PCH.SectionId
			AND PSST.CustomerId = PCH.CustomerId
			AND PCH.SegmentChoiceId = PCHOP.SegmentChoiceId
	INNER JOIN SelectedChoiceOption PSCHOP WITH (NOLOCK)
		ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode
			AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode
			AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource
			AND PSCHOP.ProjectId = PSST.ProjectId
			AND PSCHOP.SectionId = PSST.SectionId
	INNER JOIN #TempChoiceCode T
		ON PCH.SegmentChoiceCode = T.SegmentChoiceCode
	WHERE PSST.ProjectId = @PProjectId
	AND PSST.SectionId = @PSectionId
	AND PSST.CustomerId = @PCustomerId
	AND PSCHOP.ChoiceOptionSource = 'U'

--AND PCH.SegmentChoiceCode IN (SELECT
--		SegmentChoiceCode
--	FROM #TempChoiceCode)


--Select All used choices
SELECT
	*
FROM #ProjectSegmentChoiceTemp;

--Join with Reference Standard Master and insert into #ReferenceTemp table	   
WITH RSTemp
AS
(SELECT DISTINCT
		[Key] AS [Index]
	   ,[Value] AS RefStdCode
	FROM OPENJSON(@PRSIds))
SELECT
	RS.RefStdId
   ,RS.RefStdName
   ,RS.ReplaceRefStdId
   ,RS.IsObsolete
   ,RS.RefStdCode
   ,RefEdition.RefStdEditionId
   ,RefEdition.RefEdition
   ,RefEdition.RefStdTitle
   ,RefEdition.LinkTarget
FROM [SLCMaster].dbo.ReferenceStandard RS WITH (NOLOCK)
INNER JOIN RSTemp RST
	ON RST.RefStdCode = RS.RefStdCode
CROSS APPLY (SELECT TOP 1
		RSE.RefStdEditionId
	   ,RSE.RefEdition
	   ,RSE.RefStdTitle
	   ,RSE.LinkTarget
	FROM [SLCMaster].dbo.ReferenceStandardEdition RSE WITH (NOLOCK)
	WHERE RSE.RefStdId = RS.RefStdCode
	ORDER BY RSE.RefStdEditionId DESC) RefEdition
ORDER BY RS.RefStdName;

WITH GTTemp
AS
(SELECT DISTINCT
		[Key] AS [Index]
	   ,[Value] AS GlobalTermCode
	FROM OPENJSON(@PGTIds))
SELECT
	GT.GlobalTermId
   ,GT.mGlobalTermId
   ,GT.ProjectId
   ,GT.CustomerId
   ,GT.Name
   ,GT.value
   ,GT.GlobalTermSource
   ,GT.GlobalTermCode
   ,GT.CreatedDate
   ,GT.CreatedBy
   ,GT.ModifiedDate
   ,GT.ModifiedBy
   ,GT.SLE_GlobalChoiceID
   ,GT.UserGlobalTermId
   ,GT.IsDeleted
   ,GT.A_GlobalTermId
   ,GT.GlobalTermFieldTypeId
   ,GT.OldValue
FROM GTTemp
INNER JOIN [ProjectGlobalTerm] AS GT WITH (NOLOCK)
	ON GTTemp.GlobalTermCode = GT.GlobalTermCode
WHERE ProjectId = @PProjectId
AND CustomerId = @PCustomerId


END
GO
Print '11. usp_GetChoiceRSAndGTList'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_GetDeletedProjects] -- EXEC GetDeletedProject @CustomerID = 8,  @UserID = 12, @IsOfficeMaster = 0                  
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
 AND ISNULL(p.IsShowMigrationPopup, 0) = 0;  
      
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
 AND ISNULL(p.IsShowMigrationPopup, 0) = 0;      
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
Print '12. usp_GetDeletedProjects'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_GetExistingProjects]          
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
 AND P.IsShowMigrationPopup=0     
        
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
 AND P.IsShowMigrationPopup=0      
        
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
   AND P.IsShowMigrationPopup=0         
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
go
Print '13. usp_GetExistingProjects'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_GetHeaderFooterKeywordDetails]         
@ProjectId INT,        
@CustomerId INT        
AS            
BEGIN        
DECLARE @PProjectId INT = @ProjectId;        
DECLARE @PCustomerId INT = @CustomerId;        
--DECLARE @KeywordFormatStart NVARCHAR(MAX) = '{KW#';        
--DECLARE @KeywordFormatEnd NVARCHAR(MAX) = '}';        
        
DECLARE @KeywordFormatStart NVARCHAR(MAX) = '';        
DECLARE @KeywordFormatEnd NVARCHAR(MAX) = '';        
        
DECLARE @KeywordsTable TABLE (        
 KeywordDescription NVARCHAR(MAX),        
 KeywordFormat NVARCHAR(MAX),        
 KeywordTypeId int        
);        
        
INSERT INTO @KeywordsTable (KeywordDescription, KeywordFormat,KeywordTypeId)        
 VALUES ('Division ID', @KeywordFormatStart + 'DivisionID' + @KeywordFormatEnd,1),        
 ('Division Name', @KeywordFormatStart + 'DivisionName' + @KeywordFormatEnd,1),        
 ('Section ID', @KeywordFormatStart + 'SectionID' + @KeywordFormatEnd,1),        
 ('Section Name', @KeywordFormatStart + 'SectionName' + @KeywordFormatEnd,1),        
 ('Project ID', @KeywordFormatStart + 'ProjectID' + @KeywordFormatEnd,1),   
 ('Project Location', @KeywordFormatStart + 'DBInfoProjectLocation' + @KeywordFormatEnd,1),
 --('Delegated Design Engineers to be Licensed in', @KeywordFormatStart + 'DBInfoProjectLocation' + @KeywordFormatEnd),        
 --('Project Location', @KeywordFormatStart + 'ProjectLocation' + @KeywordFormatEnd),        
 ('Project Name', @KeywordFormatStart + 'ProjectName' + @KeywordFormatEnd,0),        
 ('Page Number', @KeywordFormatStart + 'PageNumber' + @KeywordFormatEnd,1),        
 ('Section Page Count', @KeywordFormatStart + 'SectionPageCount' + @KeywordFormatEnd,1),        
 ('Project Page Count', @KeywordFormatStart + 'PageCount' + @KeywordFormatEnd,1),        
 ('Date', @KeywordFormatStart + 'DateField' + @KeywordFormatEnd,1),        
 ('Time', @KeywordFormatStart + 'TimeField' + @KeywordFormatEnd,1),        
        
 ('Report Name', @KeywordFormatStart + 'ReportName' + @KeywordFormatEnd,2),        
 ('Page Number', @KeywordFormatStart + 'PageNumber' + @KeywordFormatEnd,2),        
 ('Section Page Count', @KeywordFormatStart + 'SectionPageCount' + @KeywordFormatEnd,2),        
 ('Project Page Count', @KeywordFormatStart + 'PageCount' + @KeywordFormatEnd,2),        
 ('Date', @KeywordFormatStart + 'DateField' + @KeywordFormatEnd,2),        
 ('Time', @KeywordFormatStart + 'TimeField' + @KeywordFormatEnd,2)  ,      
 --('Project Name', @KeywordFormatStart + 'ProjectName' + @KeywordFormatEnd,2)        
      
  ('Report Name', @KeywordFormatStart + 'ReportName' + @KeywordFormatEnd,3),        
 ('Page Number', @KeywordFormatStart + 'PageNumber' + @KeywordFormatEnd,3),        
 ('Date', @KeywordFormatStart + 'DateField' + @KeywordFormatEnd,3),        
 ('Time', @KeywordFormatStart + 'TimeField' + @KeywordFormatEnd,3)       
        
SELECT        
 *        
FROM @KeywordsTable         
END 
GO
Print '14. usp_GetHeaderFooterKeywordDetails'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_GetImportRequest]        
(            
 @CustomerId INT,            
 @UserId INT             
)            
AS            
BEGIN            
 DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())          
         
 SELECT           
 CPR.RequestId          
,CPR.TargetProjectId  AS ProjectId       
,CPR.TargetSectionId  AS SectionId      
,PS.[Description] AS [TaskName]      
,CPR.CreatedById  As UserId        
,CPR.CustomerId          
,CPR.CreatedDate AS RequestDateTime         
,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr
,DATEADD(DAY,30,CPR.CreatedDate) AS RequestExpiryDateTime          
,ISNULL(CPR.ModifiedDate,'') as ModifiedDate          
,CPR.StatusId          
,CPR.IsNotify          
,CPR.CompletedPercentage       
,LCS.Name as StatusDescription
,CPR.Source
 FROM ImportProjectRequest CPR WITH(NOLOCK)         
   INNER JOIN LuCopyStatus LCS  WITH(NOLOCK)        
   ON LCS.CopyStatusId=CPR.StatusId           
   INNER JOIN ProjectSection PS WITH(NOLOCK)      
   ON PS.SectionId=CPR.TargetSectionId      
 WHERE CPR.CreatedById=@UserId AND Source IN('SpecAPI','Import from Template')     
  AND isnull(CPR.IsDeleted,0)=0       
 AND CPR.CreatedDate> @DateBefore30Days           
 ORDER by CPR.CreatedDate DESC            
END
GO
Print '15. usp_GetImportRequest'
Go


CREATE OR ALTER PROCEDURE usp_GetImportSectionProgress     
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
  ,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr
   ,DATEADD(DAY, 30, CPR.CreatedDate) AS RequestExpiryDateTime        
	INTO #ImportProgress
	FROM ImportProjectRequest CPR WITH (NOLOCK)       
	INNER JOIN LuCopyStatus LCS WITH (NOLOCK)        
	 ON LCS.CopyStatusId = CPR.StatusId        
	  INNER JOIN ProjectSection PS WITH(NOLOCK)  
	   ON PS.SectionId=CPR.TargetSectionId  
	WHERE CPR.CreatedById = @UserId
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
Print '16. usp_GetImportSectionProgress'
Go


CREATE OR ALTER PROCEDURE [dbo].usp_GetProjectForImportSection(                          
 @PageSize INT =25,                          
 @PageNumber INT =1,                          
 @IsOfficeMaster BIT,                          
 @TargetProjectId INT = 0,                          
 @CustomerId INT,                          
 @SearchName NVARCHAR(MAX) =null,                          
 @UserId INT,                          
 @IsSystemManager BIT =0                        
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
                        
DECLARE @masterDataTypeId INT = 0            
            
SET @masterDataTypeId = (SELECT            
  p.MasterDataTypeId            
 FROM Project AS p WITH (NOLOCK)            
 WHERE p.ProjectId = @PTargetProjectId)            
                          
IF @PSearchName=''            
SET @PSearchName = NULL;            
            
--Fetch required sequence 0 segment status of customer into tables for next heaviour joins                          
DROP TABLE IF EXISTS #tmp_ProjectSegmentStatus;            
            
SELECT            
 PSST.SectionId            
   ,PSST.SegmentStatusId            
   ,PSST.ParentSegmentStatusId            
   ,PSST.IndentLevel            
   ,PSST.SequenceNumber INTO #tmp_ProjectSegmentStatus            
FROM ProjectSegmentStatus PSST WITH (NOLOCK)            
WHERE PSST.CustomerId = @PCustomerId            
AND PSST.ParentSegmentStatusId = 0            
AND PSST.IndentLevel = 0            
AND PSST.SequenceNumber = 0;            
            
IF (@PIsSystemManager = 0)            
BEGIN            
            
CREATE TABLE #AccessibleProjectIds (            
 Projectid INT            
   ,ProjectAccessTypeId INT            
   ,IsProjectAccessible BIT            
   ,ProjectAccessTypeName NVARCHAR(100)            
   ,IsProjectOwner BIT            
);            
            
---Get all public,private and owned projects                            
INSERT INTO #AccessibleProjectIds (Projectid, ProjectAccessTypeId, IsProjectAccessible, ProjectAccessTypeName, IsProjectOwner)            
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
WHERE u.IsActive = 1            
AND u.UserId = @PUserId            
AND t.ProjectAccessTypeId = 2            
AND u.CustomerId = @PCustomerId            
            
--Get all accessible projects                            
INSERT INTO #AccessibleProjectIds (Projectid, ProjectAccessTypeId, IsProjectAccessible, ProjectAccessTypeName, IsProjectOwner)            
 SELECT            
  ps.Projectid            
    ,ps.ProjectAccessTypeId            
    ,1            
    ,''            
    ,IIF(ps.OwnerId = @PUserId, 1, 0)            
 FROM ProjectSummary ps WITH (NOLOCK)            
 INNER JOIN UserProjectAccessMapping upam WITH (NOLOCK)            
  ON upam.ProjectId = ps.ProjectId            
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
            
SELECT            
 p.ProjectId            
   ,LTRIM(RTRIM(p.[Name])) AS [Name]            
   ,p.IsOfficeMaster            
   ,p.customerId AS CustomerId            
   ,UF.LastAccessed AS ModifiedDate            
   ,COUNT(PS.SectionId) AS OpenSectionCount           
   ,CONVERT( bit,0) AS IsMigrated         
   ,CONVERT( bit,0) AS HasMigrationError           
   INTO #ProjectForImportSection        
FROM Project AS p WITH (NOLOCK)            
INNER JOIN [ProjectSummary] psm WITH (NOLOCK)            
 ON psm.ProjectId = p.ProjectId            
INNER JOIN ProjectSection PS WITH (NOLOCK)            
 ON P.ProjectId = PS.ProjectId            
  AND PS.IsLastLevel = 1            
  AND PS.IsDeleted = 0            
INNER JOIN #tmp_ProjectSegmentStatus PSST            
 ON PS.SectionId = PSST.SectionId            
  AND PSST.ParentSegmentStatusId = 0            
  AND PSST.IndentLevel = 0            
  AND PSST.SequenceNumber = 0            
INNER JOIN #AccessibleProjectIds t            
 ON t.Projectid = p.ProjectId            
LEFT JOIN UserFolder UF WITH (NOLOCK)            
 ON UF.ProjectId = P.ProjectId            
  AND UF.customerId = p.customerId            
WHERE             
P.MasterDataTypeId = @masterDataTypeId            
AND ISNULL(P.IsDeleted,0)=0            
AND ISNULL(P.IsArchived,0)=0           
AND P.IsOfficeMaster = @PIsOfficeMaster            
AND P.ProjectId != @PTargetProjectId            
AND p.customerId = @PCustomerId     
AND P.IsShowMigrationPopup =0             
AND (@PSearchName IS NULL            
OR p.[Name] LIKE '%' + COALESCE(@PSearchName, p.[Name]) + '%')            
GROUP BY p.ProjectId            
  ,P.[Name]            
  ,p.IsOfficeMaster            
  ,p.customerId            
  ,UF.LastAccessed            
HAVING COUNT(PS.SectionId) > 0            
ORDER BY UF.LastAccessed DESC            
OFFSET @PPageSize * (@PPageNumber - 1) ROWS            
FETCH NEXT @PPageSize ROWS ONLY;          
        
UPDATE P          
SET P.IsMigrated = 1          
FROM #ProjectForImportSection P          
INNER JOIN Project PME WITH (NOLOCK)          
 ON PME.ProjectId = P.ProjectId          
WHERE ISNULL(PME.IsMigrated, 0) = 1         
        
UPDATE P          
SET P.HasMigrationError = 1          
FROM #ProjectForImportSection P          
INNER JOIN ProjectMigrationException PME WITH (NOLOCK)          
 ON PME.ProjectId = P.ProjectId          
WHERE ISNULL(P.IsMigrated, 0) = 1   AND ISNULL(IsResolved,0)=0      
        
SELECT * FROM   #ProjectForImportSection        
                      
END            
IF (@PIsSystemManager = 1)            
BEGIN            
SELECT            
 P.ProjectId            
   ,P.CustomerId            
   ,P.Name            
   ,P.IsOfficeMaster            
   ,UF.LastAccessed AS ModifiedDate            
   ,COUNT(PS.SectionId) AS OpenSectionCount            
   ,CONVERT( bit,0) AS IsMigrated         
   ,CONVERT( bit,0) AS HasMigrationError           
   INTO #ProjectForImportSectionSM        
FROM Project P WITH (NOLOCK)            
INNER JOIN UserFolder UF WITH (NOLOCK)            
 ON P.ProjectId = UF.ProjectId            
INNER JOIN ProjectSection PS WITH (NOLOCK)            
 ON P.ProjectId = PS.ProjectId            
  AND PS.IsLastLevel = 1            
  AND PS.IsDeleted = 0         
INNER JOIN #tmp_ProjectSegmentStatus PSST            
 ON PS.SectionId = PSST.SectionId            
  AND PSST.ParentSegmentStatusId = 0            
  AND PSST.IndentLevel = 0            
  AND PSST.SequenceNumber = 0            
WHERE P.CustomerId = @PCustomerId            
AND P.MasterDataTypeId = @masterDataTypeId            
AND ISNULL(P.IsDeleted,0)=0            
AND ISNULL(P.IsArchived,0)=0           
AND ISNULL(P.IsPermanentDeleted, 0) = 0     
AND P.IsOfficeMaster = @PIsOfficeMaster    
AND P.IsShowMigrationPopup =0          
AND P.ProjectId != @PTargetProjectId            
AND P.Name LIKE '%' + COALESCE(@PSearchName, P.Name) + '%'            
GROUP BY P.ProjectId            
  ,P.CustomerId            
  ,P.Name            
  ,P.IsOfficeMaster            
  ,UF.LastAccessed            
HAVING COUNT(PS.SectionId) > 0            
ORDER BY UF.LastAccessed DESC            
OFFSET @PPageSize * (@PPageNumber - 1) ROWS            
FETCH NEXT @PPageSize ROWS ONLY;            
        
        
UPDATE P          
SET P.IsMigrated = 1          
FROM #ProjectForImportSectionSM P          
INNER JOIN Project PME WITH (NOLOCK)          
 ON PME.ProjectId = P.ProjectId          
WHERE ISNULL(PME.IsMigrated, 0) = 1         
        
UPDATE P          
SET P.HasMigrationError = 1          
FROM #ProjectForImportSectionSM P          
INNER JOIN ProjectMigrationException PME WITH (NOLOCK)          
 ON PME.ProjectId = P.ProjectId          
WHERE ISNULL(P.IsMigrated, 0) = 1   AND ISNULL(IsResolved,0)=0      
        
SELECT * FROM   #ProjectForImportSectionSM        
                      
        
END            
END 
GO
Print '17. usp_GetProjectForImportSection'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_GetProjectPrintSetting]          
 (      
 @ProjectId INT,      
 @CustomerId INT,             
 @UserId INT       
)AS                
BEGIN      
          
  DECLARE @PProjectId INT = @ProjectId      
  DECLARE @PCustomerId INT = @CustomerId      
  DECLARE @PUserId INT = @UserId      
          
  IF NOT EXISTS (SELECT TOP 1      
  1      
 FROM ProjectPrintSetting WITH (NOLOCK)      
 WHERE CustomerId = @PCustomerId      
 AND ProjectId = @PProjectId)      
BEGIN      
SELECT      
 @PProjectId AS ProjectId      
   ,@PCustomerId AS CustomerId      
   ,@PUserId AS UserId      
   ,IsExportInMultipleFiles      
   ,IsBeginSectionOnOddPage      
   ,IsIncludeAuthorInFileName      
   ,TCPrintModeId    
   ,IsIncludePageCount    
   ,IsIncludeHyperLink  
   , KeepWithNext  
   ,IsPrintMasterNote  
   ,IsPrintProjectNote  
   ,IsPrintNoteImage  
   ,IsPrintIHSLogo   
FROM ProjectPrintSetting  WITH(NOLOCK)      
WHERE CustomerId IS NULL      
AND ProjectId IS NULL      
AND CreatedBy IS NULL      
END      
ELSE      
BEGIN      
SELECT      
 @PProjectId AS ProjectId      
   ,@PCustomerId AS CustomerId      
   ,@PUserId AS UserId      
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
WHERE CustomerId = @PCustomerId      
AND ProjectId = @PProjectId      
END      
END  
GO
Print '18. [usp_GetProjectPrintSetting]'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_GetProjects]                                     
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
   AND ISNULL(P.IsShowMigrationPopup,0) = 0  
   AND (@PSearchField IS NULL OR P.[Name] LIKE '%' + COALESCE(@PSearchField, P.[Name]) + '%')                              
   )                                  
  , 0);                                  
                              
                    
                        
 SET @deletedProjectCount = COALESCE((SELECT                                  
    COUNT(P.ProjectId)                                  
   FROM dbo.Project AS P WITH (NOLOCK)                                  
   WHERE ISNULL(P.IsOfficeMaster, 0) = @PIsOfficeMasterTab                                  
   AND ISNULL(P.IsDeleted, 0) = 1                                  
   AND P.customerId = @PCustomerId                                  
   AND ISNULL(P.IsPermanentDeleted, 0) = 0  
   AND ISNULL(P.IsShowMigrationPopup, 0) = 0)                                  
  , 0);  
                       
 SET @archivedProjectCount = 0;  
   -- SET @archivedProjectCount = COALESCE((SELECT                                  
   -- COUNT(P.ProjectId)                                  
   --FROM dbo.Project AS P WITH (NOLOCK)                                  
   --WHERE ISNULL(P.IsOfficeMaster, 0) = @PIsOfficeMasterTab                                  
   --AND  ISNULL(p.IsArchived,0)=1                    
   --AND ISNULL(P.IsDeleted,0)=0                               
   --AND P.customerId = @PCustomerId                                  
   --) , 0);                     
                    
                    
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
   FROM dbo.Project AS p WITH (NOLOCK)                                  
   INNER JOIN [dbo].[ProjectSummary] psm WITH (NOLOCK)                                  
    ON psm.ProjectId = p.ProjectId                                  
   LEFT JOIN UserFolder UF WITH (NOLOCK)                                  
    ON UF.ProjectId = P.ProjectId                                  
     AND UF.customerId = p.customerId                                  
   WHERE ISNULL(p.IsDeleted,0)= 0               
   AND ISNULL(p.IsArchived,0)= 0                        
   AND p.IsOfficeMaster = @PIsOfficeMasterTab  
   AND ISNULL(P.IsShowMigrationPopup,0) = 0                                  
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
   AND ISNULL(P.IsShowMigrationPopup,0)=0                                
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
   AND ISNULL(P.IsShowMigrationPopup,0) = 0  
   AND ISNULL(P.IsPermanentDeleted, 0) = 0)                                  
  , 0);                                  
         
  SET @archivedProjectCount = 0;                           
  --SET @archivedProjectCount = COALESCE((SELECT                                  
  --  COUNT(P.ProjectId)                                  
  -- FROM dbo.Project AS P WITH (NOLOCK)                                  
  -- inner JOIN #AccessibleProjectIds t                                  
  -- ON t.Projectid=p.ProjectId                                  
  -- WHERE ISNULL(P.IsOfficeMaster, 0) = @PIsOfficeMasterTab                                  
  -- AND ISNULL(P.IsArchived, 0) = 1                        
  -- and ISNULL(p.IsDeleted,0)=0                              
  -- AND P.customerId = @PCustomerId )             
  --, 0);                
                    
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
   AND ISNULL(P.IsShowMigrationPopup,0) = 0  
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
    
       
UPDATE P        
SET P.HasMigrationError = 1  
FROM #projectList P        
INNER JOIN ProjectMigrationException PME WITH (NOLOCK)        
 ON PME.ProjectId = P.ProjectId        
WHERE ISNULL(P.IsMigrated, 0) = 1 AND ISNULL(IsResolved,0)=0      
      
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
 from #projectList pl          
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
Print '19. [usp_GetProjects]'
Go


CREATE OR ALTER PROCEDURE usp_GetProjectSegemntMappingData  
(
@ProjectId int,
@CustomerId int
)
AS
BEGIN
DECLARE @SegemntChoiceTbl Table(
SegmentChoiceCode	int ,
ChoiceOptionCode	int , 
IsSelected	bit ,
SectionId int ,
ProjectId int 
)

DECLARE @SegmentStatusTbl table(
mSegmentStatusId	int null,
mSegmentId	int null,
SpecTypeTagId	int null,
SegmentStatusTypeId	int null,
IsParentSegmentStatusActive	int null ,
mSectionId	int ,
SectionId int
 )

DECLARE @SectionTbl table(
SectionId int,
mSectionId int,
ProjectId int
)
/*Get Active sections */
INSERT INTO @SectionTbl (SectionId, mSectionId, ProjectId)
	SELECT
		ps.SectionId
	   ,ps.mSectionId
	   ,ps.ProjectId
	FROM ProjectSection ps WITH (NOLOCK)
	INNER JOIN ProjectSegmentStatus pss WITH (NOLOCK)
		ON pss.SectionId = ps.SectionId
			AND ps.ProjectId = pss.ProjectId
			AND ps.CustomerId = pss.CustomerId
	WHERE ps.ProjectId = @ProjectId
	AND ps.CustomerId = @CustomerId
	AND pss.ParentSegmentStatusId = 0
	AND pss.SegmentStatusTypeId > 0

INSERT INTO @SegmentStatusTbl (mSegmentStatusId, mSegmentId, SpecTypeTagId, SegmentStatusTypeId, IsParentSegmentStatusActive, mSectionId, SectionId)
	SELECT DISTINCT
		pss.mSegmentStatusId
	   ,pss.mSegmentId
	   ,pss.SpecTypeTagId
	   ,pss.SegmentStatusTypeId
	   ,pss.IsParentSegmentStatusActive
	   ,stbl.mSectionId
	   ,pss.SectionId
	FROM ProjectSegmentStatus pss WITH (NOLOCK)
	INNER JOIN @SectionTbl stbl
		ON stbl.SectionId = pss.SectionId
			AND stbl.ProjectId = pss.ProjectId
	WHERE pss.SegmentStatusTypeId < 6

SELECT
	mSegmentStatusId
   ,mSegmentId
   ,SpecTypeTagId
   ,SegmentStatusTypeId
   ,Cast(IsParentSegmentStatusActive AS BIT)as IsParentSegmentStatusActive
   ,mSectionId
FROM @SegmentStatusTbl

SELECT DISTINCT
	sco.SegmentChoiceCode
   ,sco.ChoiceOptionCode
   ,CAST(sco.IsSelected AS BIT)AS IsSelected
   ,stbl.mSegmentStatusId
   ,stbl.mSegmentId
   ,stbl.mSectionId
FROM SelectedChoiceOption sco WITH (NOLOCK)
INNER JOIN @SegmentStatusTbl stbl
	ON sco.SectionId = stbl.SectionId
INNER JOIN SLCMaster..SegmentChoice slcmsc WITH (NOLOCK)
	ON slcmsc.SegmentStatusId = stbl.mSegmentStatusId
		AND slcmsc.SegmentId = stbl.mSegmentId
		AND sco.SegmentChoiceCode = slcmsc.SegmentChoiceCode
WHERE sco.ProjectId = @ProjectId
AND sco.CustomerId = @CustomerId
ORDER BY sco.SegmentChoiceCode ASC

END
GO
Print '20. usp_GetProjectSegemntMappingData'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_GetSegmentLinkDetailsNew] (    
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
FROM #InputDataTable;              
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
   *              
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
              
IF NOT EXISTS (SELECT TOP 1              
   PSST.SegmentStatusId              
  FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)              
  WHERE PSST.ProjectId = @ProjectId              
  AND PSST.CustomerId = @CustomerId              
  AND PSST.SectionId = @LoopedSectionId)              
BEGIN              
EXEC usp_MapSegmentStatusFromMasterToProject @ProjectId = @ProjectId              
           ,@SectionId = @LoopedSectionId              
            ,@CustomerId = @CustomerId              
            ,@UserId = @UserId;              
END              
              
IF NOT EXISTS (SELECT TOP 1              
   PSCHOP.SelectedChoiceOptionId              
  FROM SelectedChoiceOption AS PSCHOP WITH (NOLOCK)              
  WHERE PSCHOP.SectionId = @LoopedSectionId              
  AND PSCHOP.ProjectId = @ProjectId               
  AND PSCHOP.ChoiceOptionSource = 'M'               
  AND PSCHOP.CustomerId = @CustomerId)              
BEGIN              
EXEC usp_MapSegmentChoiceFromMasterToProject @ProjectId = @ProjectId              
            ,@SectionId = @LoopedSectionId              
            ,@CustomerId = @CustomerId              
            ,@UserId = @UserId;              
END              
              
IF NOT EXISTS (SELECT TOP 1              
   PSRT.SegmentRequirementTagId              
  FROM ProjectSegmentRequirementTag AS PSRT WITH (NOLOCK)              
  WHERE PSRT.ProjectId = @ProjectId              
  AND PSRT.CustomerId = @CustomerId              
  AND PSRT.SectionId = @LoopedSectionId)              
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
AND ParentSegmentStatusId = 0;              
              
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
   PSST.ProjectId = @ProjectId AND  
   PS.SectionId = PSST.SectionId              
   AND PSST.ParentSegmentStatusId = 0              
   AND PSST.IndentLevel = 0              
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
SET @LoopedSectionId = (SELECT TOP 1  
  SectionId              
 FROM #TargetSectionCodeTable WITH (NOLOCK)              
 WHERE Id = @UniqueSectionCodesLoopCnt);              
              
IF NOT EXISTS (SELECT TOP 1              
  PSST.SegmentStatusId              
 FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)              
 WHERE PSST.ProjectId = @ProjectId              
 AND PSST.CustomerId = @CustomerId              
 AND PSST.SectionId = @LoopedSectionId)              
BEGIN              
EXEC dbo.usp_MapSegmentStatusFromMasterToProject @ProjectId = @ProjectId              
            ,@SectionId = @LoopedSectionId              
            ,@CustomerId = @CustomerId              
            ,@UserId = @UserId;              
END              
              
IF NOT EXISTS (SELECT TOP 1              
   PSCHOP.SelectedChoiceOptionId              
  FROM SelectedChoiceOption AS PSCHOP WITH (NOLOCK)              
  WHERE PSCHOP.ProjectId = @ProjectId              
  AND PSCHOP.CustomerId = @CustomerId              
  AND PSCHOP.SectionId = @LoopedSectionId              
  AND PSCHOP.ChoiceOptionSource = 'M')              
BEGIN              
EXEC dbo.usp_MapSegmentChoiceFromMasterToProject @ProjectId = @ProjectId              
            ,@SectionId = @LoopedSectionId              
            ,@CustomerId = @CustomerId              
            ,@UserId = @UserId;           
END              
              
IF NOT EXISTS (SELECT TOP 1              
   PSRT.SegmentRequirementTagId              
  FROM ProjectSegmentRequirementTag AS PSRT WITH (NOLOCK)              
  WHERE PSRT.ProjectId = @ProjectId              
  AND PSRT.CustomerId = @CustomerId              
  AND PSRT.SectionId = @LoopedSectionId)              
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
    ,0 AS SegmentCode              
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
 WHERE   
 SCHOP.ProjectId = @ProjectId              
 AND SCHOP.CustomerId = @CustomerId              
 AND SCHOP.ChoiceOptionSource = 'M'  
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
 WHERE SCHOP.ProjectId = @ProjectId              
 AND SCHOP.CustomerId = @CustomerId              
 AND SCHOP.ChoiceOptionSource = 'M'              
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
 WHERE SCHOP.ProjectId = @ProjectId              
 AND SCHOP.CustomerId = @CustomerId              
 AND SCHOP.ChoiceOptionSource = 'U'              
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
 WHERE   
 SCHOP.ProjectId = @ProjectId              
 AND SCHOP.CustomerId = @CustomerId              
 AND SCHOP.ChoiceOptionSource = 'U'
END              
              
/** [BLOCK] SET IsFetchedDbLinkResult **/              
BEGIN              
UPDATE PSST              
SET PSST.IsFetchedDbLinkResult = CAST(1 AS BIT)              
FROM #SegmentStatusTable PSST WITH (NOLOCK)              
INNER JOIN #InputDataTable IDT WITH (NOLOCK)              
 ON PSST.SectionCode = IDT.SectionCode              
 AND PSST.SegmentStatusCode = IDT.SegmentStatusCode              
 AND PSST.SegmentSource = IDT.SegmentSource              
              
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
 ON PSRT.SectionId = PSST.SectionId           
  AND PSRT.ProjectId = PSST.ProjectId          
  AND PSRT.SegmentStatusId = PSST.SegmentStatusId          
WHERE PSRT.ProjectId = @ProjectId          
AND PSRT.CustomerId = @CustomerId          
AND PSRT.RequirementTagId IN (@RS_TAG, @RT_TAG, @RE_TAG, @ST_TAG)          
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
Print '21. [usp_GetSegmentLinkDetailsNew]'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_GetSegmentsForMLReportWithParagraph]                   
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
Print '22. [usp_GetSegmentsForMLReportWithParagraph]'
Go


CREATE OR ALTER PROCEDURE usp_GetSourceTargetLinksCount  
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

--REMOVE THOSE TO WHOME THERE IS DO NOT HAVE ACCESS DEPENDS UPON CATALOGUE TYPE  
IF @PCatalogueType != 'FS'
BEGIN
INSERT INTO #SpecTypeTagIdTable (SpecTypeTagId)
	SELECT
		SpecTypeTagId
	FROM LuProjectSpecTypeTag WITH (NOLOCK)
	WHERE TagType IN (SELECT
			*
		FROM dbo.fn_SplitString(@PCatalogueType, ','));

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

--Fetch SECTION LIST  
SELECT
	PS.SectionCode
   ,PS.SourceTag
   ,PS.[Description] AS Description
FROM ProjectSection PS WITH (NOLOCK)
WHERE PS.ProjectId = @PProjectId
AND PS.CustomerId = @PCustomerId
AND PS.IsLastLevel = 1
UNION
SELECT
	MS.SectionCode
   ,MS.SourceTag
   ,CAST(MS.Description AS NVARCHAR(500)) AS Description
FROM SLCMaster..Section MS WITH (NOLOCK)
LEFT JOIN ProjectSection PS WITH (NOLOCK)
	ON PS.ProjectId = @PProjectId
		AND PS.CustomerId = @PCustomerId
		AND PS.mSectionId = MS.SectionId
WHERE MS.MasterDataTypeId = @PMasterDataTypeId
AND MS.IsLastLevel = 1
AND PS.SectionId IS NULL
END
go
Print '23. usp_GetSourceTargetLinksCount'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_GetSummaryInfo]          
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
        
 --Used to get Global Term For GT with name ProjectId in Master        
 --DECLARE @ProjectIdGlobalTermCode INT = 2;         
 DECLARE @ProjectIdGlobalTermName NVARCHAR(50) = 'Project ID'       

	-- Only fetch total and active sections count if @IsSummaryInfoPage is true
	IF(@IsSummaryInfoPage = 1)
	BEGIN    
	 SET @TotalSectionsCount = (SELECT          
	   COUNT(1)          
	  FROM ProjectSection PS WITH (NOLOCK)          
	  WHERE PS.ProjectId = @PProjectId          
	  AND PS.CustomerId = @PCustomerId          
	  AND PS.IsLastLevel = 1          
	  AND PS.IsDeleted = 0)          
	 SET @ActiveSectionsCount = (SELECT          
	   COUNT(1)          
	  FROM ProjectSection PS WITH (NOLOCK)          
	  INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)          
	   ON PS.SectionId = PSST.SectionId          
	  WHERE PS.ProjectId = @PProjectId          
	  AND PS.CustomerId = @PCustomerId          
	  AND PSST.ProjectId = @PProjectId          
	  AND PSST.CustomerId = @PCustomerId          
	  AND PS.IsLastLevel = 1          
	  AND PS.IsDeleted = 0          
	  AND PSST.ParentSegmentStatusId = 0          
	  AND PSST.SegmentStatusTypeId > 0          
	  AND PSST.SegmentStatusTypeId < 6)          
	END

 SELECT          
  P.ProjectId          
    ,PGT.[value] AS GlobalTermProjectIdValue          
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
 LEFT OUTER JOIN ProjectGlobalTerm PGT WITH (NOLOCK)          
  ON PGT.ProjectId =P.ProjectId           
 WHERE P.ProjectId = @PProjectId          
 AND P.CustomerId = @PCustomerId          
 AND PGT.[Name] = @ProjectIdGlobalTermName        
END
GO
Print '24. [usp_GetSummaryInfo]'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_GetTagReports]                    
(                  
@ProjectId INT,                    
@CustomerId INT,                   
@TagType INT,                   
@TagIdList NVARCHAR(MAX) NULL                  
)                    
AS                    
BEGIN          
DROP TABLE IF EXISTS #SegmentStatusIds          
DROP TABLE IF EXISTS #SectionsContainingTaggedSegments          
          
DECLARE @PProjectId INT = @ProjectId;          
DECLARE @PCustomerId INT = @CustomerId;          
DECLARE @PTagType INT = @TagType;          
DECLARE @PTagIdList NVARCHAR(MAX) = @TagIdList;          
          
--CONVERT STRING INTO TABLE                            
CREATE TABLE #TagIdTbl (          
 TagId INT          
);          
INSERT INTO #TagIdTbl (TagId)          
 SELECT          
  *          
 FROM dbo.fn_SplitString(@PTagIdList, ',');          
          
CREATE TABLE #SegmentStatusIds (          
 SegmentStatusId INT          
   ,TagId INT          
   ,TagName NVARCHAR(MAX)          
);          
          
INSERT INTO #SegmentStatusIds (SegmentStatusId, TagId, TagName)          
 (SELECT          
  PSRT.SegmentStatusId          
    ,TIT.TagId          
    ,LPRTI.Description AS TagName          
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)          
 INNER JOIN LuProjectRequirementTag LPRTI WITH (NOLOCK)          
  ON PSRT.RequirementTagId = LPRTI.RequirementTagId          
 INNER JOIN #TagIdTbl TIT          
  ON PSRT.RequirementTagId = TIT.TagId          
 WHERE PSRT.ProjectId = @PProjectId          
 --AND PSRT.RequirementTagId = @PTagId                  
 UNION ALL          
 SELECT          
  PSUT.SegmentStatusId          
    ,TIT.TagId          
    ,PUT.Description AS TagName          
 FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)          
 INNER JOIN #TagIdTbl TIT          
  ON PSUT.UserTagId = TIT.TagId          
 INNER JOIN ProjectUserTag PUT  WITH (NOLOCK)        
  ON PUT.UserTagId = TIT.TagId          
 WHERE PSUT.ProjectId = @PProjectId          
 --AND PSUT.UserTagId = @PTagId                  
 )          
--END                  
          
--Inserts Sections Containing Tagged Segments                    
SELECT          
 PSS.SectionId          
   ,SI.TagId          
   ,SI.TagName          
   ,PSS.ProjectId          
   ,PSS.CustomerId INTO #SectionsContainingTaggedSegments          
FROM ProjectSegmentStatusView PSS WITH (NOLOCK)          
INNER JOIN #SegmentStatusIds SI          
 ON PSS.SegmentStatusId = SI.SegmentStatusId          
WHERE PSS.ProjectId = @PProjectId          
AND PSS.CustomerId = @PCustomerId          
AND PSS.IsDeleted = 0          
AND PSS.IsSegmentStatusActive <> 0          
          
--Select Sections with Tags                    
SELECT DISTINCT          
 PS.SectionId          
   ,PS.DivisionId          
   ,PS.DivisionCode          
   ,PS.[Description]          
   ,PS.SourceTag          
   ,PS.Author          
   ,PS.SectionCode          
   ,SCTS.Tagid          
   ,SCTS.TagName          
FROM ProjectSection PS WITH (NOLOCK)          
JOIN #SectionsContainingTaggedSegments SCTS          
 ON PS.ProjectId = SCTS.ProjectId          
  AND PS.SectionId = SCTS.SectionId          
  AND PS.CustomerId = SCTS.CustomerId          
WHERE PS.ProjectId = @PProjectId          
AND PS.CustomerId = @PCustomerId          
ORDER BY SCTS.Tagname, PS.SourceTag;          
          
--Select Division For Sections who has tagged segments                    
SELECT DISTINCT          
 D.DivisionId          
   ,D.DivisionCode          
   ,D.DivisionTitle          
   ,D.SortOrder          
   ,D.IsActive          
   ,D.MasterDataTypeId          
   ,D.FormatTypeId          
FROM SLCMaster..Division D WITH (NOLOCK)          
INNER JOIN ProjectSection PS WITH (NOLOCK)          
 ON PS.DivisionId = D.DivisionId          
JOIN #SectionsContainingTaggedSegments SCTS WITH (NOLOCK)          
 ON PS.ProjectId = SCTS.ProjectId          
  AND PS.SectionId = SCTS.SectionId          
  AND PS.CustomerId = SCTS.CustomerId          
WHERE PS.ProjectId = @PProjectId          
AND PS.CustomerId = @PCustomerId          
order by D.DivisionCode    
          
SELECT DISTINCT          
 TemplateId INTO #TEMPLATE          
FROM Project WITH (NOLOCK)          
WHERE ProjectId = @PProjectID          
          
-- SELECT TEMPLATE STYLE DATA                    
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
   ,TSY.Level     
   ,ISNULL(SPS.CustomLineSpacing,0) as CustomLineSpacing  
   ,ISNULL(SPS.DefaultSpacesId,0) as  DefaultSpacesId  
   ,ISNULL(SPS.BeforeSpacesId,0) as   BeforeSpacesId  
   ,ISNULL(SPS.AfterSpacesId,0) as AfterSpacesId      
FROM Style ST WITH (NOLOCK)          
INNER JOIN TemplateStyle TSY WITH (NOLOCK)          
 ON ST.StyleId = TSY.StyleId          
INNER JOIN #TEMPLATE T          
 ON TSY.TemplateId = T.TemplateId  
LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK) 
 ON SPS.StyleId=ST.StyleId;
          
-- GET SourceTagFormat                     
SELECT          
 SourceTagFormat          
FROM ProjectSummary WITH (NOLOCK)          
WHERE ProjectId = @PProjectId;          
          
END  
GO
Print '25. [usp_GetTagReports]'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_GetUpdates]                      
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
WHERE ProjectId = @PprojectId
AND CustomerId = @PcustomerId
AND SegmentSource = 'M'
AND IsRefStdParagraph = 0
AND (@PCatalogueType = 'FS'
OR SpecTypeTagId IN (1, 2))
AND SectionId = @PsectionId


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

	WHERE PrjRefStd.ProjectId = @PprojectId
	AND PrjRefStd.RefStdSource = 'M'
	AND PrjRefStd.SectionId = @PsectionId
	AND PrjRefStd.CustomerId = @PcustomerId
	AND PrjRefStd.IsDeleted = 0
	AND MEDN.RefStdEditionId > PrjRefStd.RefStdEditionId
	AND PSST.ProjectId = @PprojectId
	AND PSST.SectionId = @PsectionId
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
	WHERE PrjRefStd.ProjectId = @PprojectId
	AND PrjRefStd.RefStdSource = 'M'
	AND PrjRefStd.SectionId = @PsectionId
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
	WHERE PrjRefStd.ProjectId = @PprojectId
	AND PrjRefStd.RefStdSource = 'M'
	AND PrjRefStd.SectionId = @PsectionId
	AND PrjRefStd.CustomerId = @PcustomerId
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
	WHERE PrjRefStd.ProjectId = @PprojectId
	AND PrjRefStd.RefStdSource = 'M'
	AND PrjRefStd.SectionId = @PsectionId
	AND PrjRefStd.CustomerId = @PcustomerId
	AND PrjRefStd.IsDeleted = 0
--AND PrjRefStd.RefStandardId = X1.RefStandardId
) Tb

--DROP TABLE IF EXISTS #PRefStdNew
--SELECT
--	* INTO #PRefStdNew
--FROM (SELECT
--		MEDN.LinkTarget AS NewLinkTarget
--	   ,MEDN.RefEdition AS NewRefEdition
--	   ,MEDN.RefStdTitle AS NewRefStdTitle
--	   ,MEDN.RefStdEditionId AS NewRefStdEditionId
--	   ,PrjRefStd.RefStandardId AS PrjRefStdId
--	FROM ProjectReferenceStandard PrjRefStd WITH (NOLOCK)
--	INNER JOIN SLCMaster..ReferenceStandardEdition MEDN WITH (NOLOCK)
--		ON PrjRefStd.RefStandardId = MEDN.RefStdId
--	WHERE PrjRefStd.ProjectId = @PprojectId
--	AND PrjRefStd.RefStdSource = 'M'
--	AND PrjRefStd.SectionId = @PsectionId
--	AND PrjRefStd.CustomerId = @PcustomerId
--	--AND PrjRefStd.RefStandardId = X1.RefStandardId
--	AND PrjRefStd.IsDeleted = 0
--	AND MEDN.RefStdEditionId > PrjRefStd.RefStdEditionId
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
Print '26. [usp_GetUpdates]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_GetUpdatesNeedsReview]
@projectId INT NULL, @sectionId INT NULL, @customerId INT NULL, @userId INT NULL=0,@CatalogueType NVARCHAR (50) NULL='FS'                    
AS
  BEGIN
  
DECLARE @PprojectId INT = @projectId;
DECLARE @PsectionId INT = @sectionId;
DECLARE @PcustomerId INT = @customerId;
DECLARE @PuserId INT = @userId;
DECLARE @PCatalogueType NVARCHAR = @CatalogueType;

			DECLARE @counter int=1, @max int=0,@SegmentStatusId int=0,@sequenceNos nvarchar(max)='',@Action NVARCHAR(50)='',
			@ScenarioA bit,@ScenarioB bit,@ScenarioC bit
			DECLARE @ProjectSegmentStatus TABLE 
			(
			[SegmentStatusId] [int] NULL,
			[SectionId] [int] NULL,
			[ParentSegmentStatusId] [int] NULL,
			[isParent] bit NULL ,
			[mSegmentStatusId] [int] NULL,
			[mSegmentId] [int] NULL,
			[SegmentId] [int] NULL,
			[SegmentSource] [char](1) NULL,
			[SegmentOrigin] [char](2) NULL,
			[IndentLevel] [tinyint] NULL,
			[SequenceNumber] [decimal](18, 4) NULL,
			[Remark] NVARCHAR(max) NULL,
			[isDeleted] bit null,
			[MessageDescription] NVARCHAR(max) NULL,
			[ScenarioA] bit,
			[ScenarioB] bit,
			[ScenarioC] bit
			)

				;
WITH CTE
AS
(SELECT
	pss.SegmentStatusId
   ,pss.SectionId
   ,pss.ParentSegmentStatusId
   ,pss.mSegmentStatusId
   ,pss.mSegmentId
   ,pss.SegmentId
   ,pss.SegmentSource
   ,pss.SegmentOrigin
   ,pss.IndentLevel
   ,pss.SequenceNumber
   ,pss.SpecTypeTagId
   ,pss.SegmentStatusTypeId
   ,pss.IsParentSegmentStatusActive
   ,pss.ProjectId
   ,pss.CustomerId
   ,pss.SegmentStatusCode
   ,pss.IsShowAutoNumber
   ,pss.IsRefStdParagraph
   ,pss.FormattingJson
   ,pss.CreateDate
   ,pss.CreatedBy
   ,pss.ModifiedDate
   ,pss.ModifiedBy
   ,pss.IsPageBreak
   ,pss.SLE_DocID
   ,pss.SLE_ParentID
   ,pss.SLE_SegmentID
   ,pss.SLE_ProjectSegID
   ,pss.SLE_StatusID
   ,pss.A_SegmentStatusId
   ,pss.IsDeleted
   ,pss.TrackOriginOrder
   ,pss.MTrackDescription
	FROM ProjectSegmentStatus AS pss WITH (NOLOCK)
	INNER JOIN [SLCMaster].[dbo].[SegmentStatus] AS mss  WITH (NOLOCK)
		ON pss.mSegmentStatusId = mss.SegmentStatusId
	WHERE pss.projectId = @PprojectId
	AND pss.sectionId = @PsectionId
	AND mss.isDeleted = 1
	AND ISNULL(pss.IsDeleted, 0) = 0)
SELECT
	ROW_NUMBER() OVER (ORDER BY SegmentStatusId) AS ID
   ,*
   ,CONVERT(NVARCHAR(MAX), '') AS Remark INTO #temp
FROM cte;

--SELECT
--	*
--FROM #temp;
SET @max = (SELECT
		COUNT(*)
	FROM #temp);

		WHILE(@counter<=@max)
		BEGIN
SET @SegmentStatusId = (SELECT
		SegmentStatusId
	FROM #temp
	WHERE ID = @counter);
WITH CTE
AS
(SELECT 
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
   ,MTrackDescription
	FROM ProjectSegmentStatus AS pss  WITH (NOLOCK)
	WHERE pss.SegmentStatusId = @SegmentStatusId
	AND pss.projectID = @PprojectId
	AND pss.sectionId = @PsectionId
	UNION ALL
	SELECT
	pss.SegmentStatusId
   ,pss.SectionId
   ,pss.ParentSegmentStatusId
   ,pss.mSegmentStatusId
   ,pss.mSegmentId
   ,pss.SegmentId
   ,pss.SegmentSource
   ,pss.SegmentOrigin
   ,pss.IndentLevel
   ,pss.SequenceNumber
   ,pss.SpecTypeTagId
   ,pss.SegmentStatusTypeId
   ,pss.IsParentSegmentStatusActive
   ,pss.ProjectId
   ,pss.CustomerId
   ,pss.SegmentStatusCode
   ,pss.IsShowAutoNumber
   ,pss.IsRefStdParagraph
   ,pss.FormattingJson
   ,pss.CreateDate
   ,pss.CreatedBy
   ,pss.ModifiedDate
   ,pss.ModifiedBy
   ,pss.IsPageBreak
   ,pss.SLE_DocID
   ,pss.SLE_ParentID
   ,pss.SLE_SegmentID
   ,pss.SLE_ProjectSegID
   ,pss.SLE_StatusID
   ,pss.A_SegmentStatusId
   ,pss.IsDeleted
   ,pss.TrackOriginOrder
   ,pss.MTrackDescription
	FROM  ProjectSegmentStatus AS pss  WITH (NOLOCK)
	INNER JOIN CTE AS c
		ON pss.ParentSegmentStatusId = c.SegmentStatusId
	WHERE pss.projectID = @PprojectId
	AND pss.sectionId = @PsectionId)
SELECT
	@SegmentStatusId AS MasterSegmentStatusId
   ,* INTO #temp1
FROM cte
ORDER BY ParentSegmentStatusId, SegmentStatusId;
SET @ScenarioA = 0
SET @ScenarioB = 0
SET @ScenarioC = 0
			-- CASE 1-Deleted master paragraph has at least one master subparagraph that has not been deleted
			IF (( SELECT
		COUNT(*)
	FROM #temp1 AS t
	INNER JOIN [SLCMaster].[dbo].[SegmentStatus] AS mss  WITH (NOLOCK)
		ON mss.segmentId = t.msegmentId
	WHERE mss.IndentLevel != t.IndentLevel
	AND mss.SegmentStatusId = t.mSegmentStatusId)
>= 1)
BEGIN
--US-30907 - To get correct sequence number of edit mode using segmentStatusId
SET @sequenceNos = (SELECT
		',' + CONVERT(NVARCHAR(MAX), t.SegmentStatusId)

		--RIGHT('0000' + SUBSTRING(CONVERT(NVARCHAR(MAX), t.SequenceNumber), 1, CHARINDEX('.', CONVERT(NVARCHAR(MAX), t.SequenceNumber)) - 1), 4)
	FROM #temp1 AS t
	INNER JOIN [SLCMaster].[dbo].[SegmentStatus] AS mss WITH (NOLOCK)
		ON mss.segmentId = t.msegmentId
	WHERE mss.IndentLevel != t.IndentLevel
	AND mss.SegmentStatusId = t.mSegmentStatusId
	FOR XML PATH (''))
SET @Action = 'NEED_TO_PROMOTE'
SET @ScenarioA = 1
			END
			-- CASE 2 - Deleted master paragraph has at least one user sub-paragraph
			IF (( SELECT
		COUNT(*)
	FROM #temp1
	WHERE SegmentSource = 'U'
	AND SegmentOrigin = 'U')
>= 1)
BEGIN
SET @Action = 'NEED_TO_REVIEW'
--SET @sequenceNos=NULL
SET @ScenarioB = 1
			END
			--CASE 3 -Deleted master paragraph has user modifications -- M or M*
			IF (( SELECT
		COUNT(*)
	FROM #temp1
	WHERE SegmentSource = 'M'
	AND SegmentOrigin = 'U'
	AND segmentId IS NOT NULL)
>= 1)
BEGIN
SET @Action = 'NEED_TO_REVIEW'
--SET @sequenceNos=NULL
SET @ScenarioC = 1

			END

INSERT INTO @ProjectSegmentStatus ([SegmentStatusId], [SectionId], [ParentSegmentStatusId], [isParent],
[mSegmentStatusId], [mSegmentId], [SegmentId], [SegmentSource], [SegmentOrigin], [IndentLevel], [SequenceNumber], [Remark], [isDeleted]
, [ScenarioA], [ScenarioB], [ScenarioC])
	SELECT
		[SegmentStatusId]
	   ,[SectionId]
	   ,[ParentSegmentStatusId]
	   ,CASE
			WHEN [SegmentStatusId] = @SegmentStatusId THEN 1
			ELSE 0
		END AS [isParent]
	   ,[mSegmentStatusId]
	   ,[mSegmentId]
	   ,[SegmentId]
	   ,[SegmentSource]
	   ,[SegmentOrigin]
	   ,[IndentLevel]
	   ,[SequenceNumber]
	   ,CASE
			WHEN [SegmentStatusId] = @SegmentStatusId THEN @Action
			ELSE NULL
		END
	   ,CASE
			WHEN [SegmentStatusId] = @SegmentStatusId THEN 1
			ELSE 0
		END AS [isDeleted]
	   ,CASE
			WHEN [SegmentStatusId] = @SegmentStatusId THEN @ScenarioA
			ELSE 0
		END AS ScenarioA
	   ,CASE
			WHEN [SegmentStatusId] = @SegmentStatusId THEN @ScenarioB
			ELSE 0
		END AS ScenarioB
	   ,CASE
			WHEN [SegmentStatusId] = @SegmentStatusId THEN @ScenarioC
			ELSE 0
		END AS ScenarioC
	FROM #temp1

UPDATE @ProjectSegmentStatus
SET [MessageDescription] = @sequenceNos
WHERE [SegmentStatusId] = @SegmentStatusId

SET @sequenceNos = NULL;

DROP TABLE #temp1;
SET @counter = @counter + 1
		
		END --END OF WHILE LOOP

UPDATE @ProjectSegmentStatus
SET Remark = 'NEED_TO_PROMOTE'
WHERE [ScenarioA] = 1

--UPDATE @ProjectSegmentStatus
--SET Remark='READY_TO_DELETE' WHERE [ScenarioA]=0 AND [ScenarioB]=0 AND [ScenarioC]=0
--AND isDeleted=1

--DELETE FROM @ProjectSegmentStatus WHERE [ScenarioA]=0 AND [ScenarioB]=0 AND [ScenarioC]=0
--AND isDeleted=1


SELECT
	CONVERT(INT, (ROW_NUMBER() OVER (ORDER BY pss.SegmentStatusId))) AS RowNumber
   ,pss.SegmentStatusId AS PSegmentStatusId
   ,pss.ParentSegmentstatusId
   ,pss.mSegmentId
   ,pss.mSegmentStatusId
   ,ps.mSectionId AS MSectionId
   ,pss.SectionId AS PSectionId
   ,pss.SegmentSource
   ,pss.SegmentOrigin
   ,psv.SegmentCode AS SegmentCode
   ,psv.SegmentDescription
   ,pss.Remark AS ActionName
   ,pss.SequenceNumber
   ,pss.SegmentId AS PSegmentId
   ,pss.IsDeleted AS MasterSegmentIsDelete
   ,pss.IndentLevel
   ,SUBSTRING(pss.MessageDescription, 2, LEN(pss.MessageDescription)) AS MessageDescription
   ,[ScenarioA]
   ,[ScenarioB]
   ,[ScenarioC]
   ,CONVERT(BIT, 1) AS isParent INTO #tempTbl
FROM @ProjectSegmentStatus AS pss
INNER JOIN ProjectSegmentStatusView AS psv WITH (NOLOCK)
	ON pss.SegmentStatusId = psv.SegmentStatusId
INNER JOIN ProjectSection AS ps  WITH (NOLOCK)
	ON ps.SectionId = pss.SectionId
WHERE pss.IsDeleted = 1
ORDER BY pss.IndentLevel, pss.SegmentStatusId

UPDATE CH
SET ch.isParent = 0
FROM #tempTbl CH
INNER JOIN #tempTbl PA
	ON CH.ParentSegmentStatusId = PA.pSegmentStatusId

;
WITH cte
AS
(SELECT
		*
	FROM #tempTbl AS s
	WHERE [ScenarioA] = 0
	AND [ScenarioB] = 0
	AND [ScenarioC] = 0
	AND isParent = 1
	UNION ALL
	SELECT
		t.*
	FROM #tempTbl AS t
	INNER JOIN cte AS c
		ON t.ParentSegmentStatusId = c.PSegmentStatusId)
UPDATE t
SET isParent = 1
FROM cte
INNER JOIN #tempTbl AS t
	ON cte.PSegmentStatusId = t.PSegmentStatusId;


DELETE FROM #tempTbl
WHERE [ScenarioA] = 0
	AND [ScenarioB] = 0
	AND [ScenarioC] = 0
	AND isParent = 1



SELECT
	*
FROM #tempTbl


-- EXECUTE usp_getUpdatesNeedsReview 12922,6631715,2227,0,'FS'


--GET SEGMENT CHOICES                  
SELECT
DISTINCT
	SCH.SegmentChoiceId
   ,SCH.SegmentChoiceCode
   ,SCH.SectionId
   ,SCH.ChoiceTypeId
   ,SCH.SegmentId
FROM SLCMaster..SegmentChoice SCH  WITH (NOLOCK)
INNER JOIN @ProjectSegmentStatus TMPSG
	ON SCH.SegmentId = TMPSG.mSegmentId
WHERE TMPSG.IsDeleted = 1

--GET SEGMENT CHOICES OPTIONS                  
SELECT DISTINCT
	CHOP.SegmentChoiceId
   ,CAST(CHOP.ChoiceOptionId AS BIGINT) AS ChoiceOptionId
   ,CHOP.SortOrder
   ,SCHOP.IsSelected
   ,CHOP.ChoiceOptionCode
   ,CHOP.OptionJson
FROM SLCMaster..SegmentChoice SCH  WITH (NOLOCK)
INNER JOIN SLCMaster..ChoiceOption CHOP  WITH (NOLOCK)
	ON SCH.SegmentChoiceId = CHOP.SegmentChoiceId
INNER JOIN SLCMaster..SelectedChoiceOption SCHOP  WITH (NOLOCK)
	ON SCHOP.ChoiceOptionCode = CHOP.ChoiceOptionCode
INNER JOIN @ProjectSegmentStatus TMPSG
	ON SCH.SegmentId = TMPSG.mSegmentId

END
GO
Print '27. [usp_GetUpdatesNeedsReview]'
Go

CREATE OR ALTER PROCEDURE usp_ImportSectionFromProject
(        
@CustomerId INT,                    
@UserId INT,                    
@SourceProjectId INT,                    
@SourceSectionId INT,                    
@TargetProjectId INT,                    
@UserName NVARCHAR(500)=NULL,                 
@RequestId INT                                
)                    
AS                    
BEGIN      
              
 DECLARE @PCustomerId INT = @CustomerId;      
              
 DECLARE @PUserId INT = @UserId;      
              
 DECLARE @PSourceProjectId INT = @SourceProjectId;      
              
 DECLARE @PSourceSectionId INT = @SourceSectionId;      
              
 DECLARE @PTargetProjectId INT = @TargetProjectId;      
              
 DECLARE @PUserName NVARCHAR(500) = @UserName;              
               
DECLARE @ImportStart_Description NVARCHAR(50) = 'Import Started';                
DECLARE @ImportProjectSection_Description NVARCHAR(50) = 'Import Project Section Imported';                                    
DECLARE @ImportProjectSegment_Description NVARCHAR(50) = 'Project Segment Imported';                  
DECLARE @ImportProjectSegmentStatus_Description NVARCHAR(50) = 'Project Segment Status Imported';                          
DECLARE @ImportProjectSegmentChoice_Description NVARCHAR(50) = 'Project Segment Choice Imported';                       
DECLARE @ImportProjectChoiceOption_Description NVARCHAR(50) = 'Project Choice Option Imported';                        
DECLARE @ImportSelectedChoiceOption_USERCHOICE_Description NVARCHAR(50) = 'Selected Choice Option(USER CHOICE) Imported';                       
DECLARE @ImportSelectedChoiceOption_MASTERCHOICE_Description NVARCHAR(50) = 'Selected Choice Option(MASTER CHOICE) Imported';                            
DECLARE @ImportProjectNote_Description NVARCHAR(50) = 'Project Note Imported';                              
DECLARE @ImportProjectNoteImage_Description NVARCHAR(50) = 'Project Note Image Imported';                              
DECLARE @ImportProjectSegmentImage_Description NVARCHAR(50) = 'Project Segment Image Imported';                           
DECLARE @ImportProjectReferenceStandard_Description NVARCHAR(50) = 'Project Reference Standard Imported';                  
DECLARE @ImportProjectSegmentReferenceStandard_Description NVARCHAR(50) = 'Project Segment Reference Standard Imported';                  
DECLARE @ImportProjectSegmentRequirementTag_Description NVARCHAR(50) = 'Project Segment Requirement Tag Imported';                  
DECLARE @ImportProjectSegmentUserTag_Description NVARCHAR(50) = 'Project Segment User Tag Imported';              
DECLARE @ImportHeader_Description NVARCHAR(50) = 'Header Imported';                  
DECLARE @ImportFooter_Description NVARCHAR(50) = 'Footer Imported';                
DECLARE @ImportProjectSegmentGlobalTerm_Description NVARCHAR(50) = 'Project Segment Global Term Imported';                
DECLARE @ImportProjectGlobalTerm_Description NVARCHAR(50) = 'Project Global Term Imported';               
DECLARE @ImportProjectSegmentLink_Description NVARCHAR(50) = 'Project Segment Link Imported';                
DECLARE @ImportProjectHyperLink_Description NVARCHAR(50) = 'Project HyperLink Imported';                
DECLARE @ImportComplete_Description NVARCHAR(50) = 'Import Completed';                
DECLARE @ImportFailed_Description NVARCHAR(50) = 'IMPORT FAILED';                
              
DECLARE @ImportStart_Percentage TINYINT = 5;                 
DECLARE @ImportProjectSection_Percentage TINYINT = 10;                                  
DECLARE @ImportProjectSegment_Percentage TINYINT = 15;                  
DECLARE @ImportProjectSegmentStatus_Percentage TINYINT = 20;                         
DECLARE @ImportProjectSegmentChoice_Percentage TINYINT = 25;                      
DECLARE @ImportProjectChoiceOption_Percentage TINYINT = 30;                       
DECLARE @ImportSelectedChoiceOption_USERCHOICE_Percentage TINYINT = 35;                    
DECLARE @ImportSelectedChoiceOption_MASTERCHOICE_Percentage TINYINT = 40;                       
DECLARE @ImportProjectNote_Percentage TINYINT = 45;                         
DECLARE @ImportProjectNoteImage_Percentage TINYINT = 50;                      
DECLARE @ImportProjectSegmentImage_Percentage TINYINT = 55;               
DECLARE @ImportProjectReferenceStandard_Percentage TINYINT = 60;               
DECLARE @ImportProjectSegmentReferenceStandard_Percentage TINYINT = 65;               
DECLARE @ImportProjectSegmentRequirementTag_Percentage TINYINT = 70;               
DECLARE @ImportProjectSegmentUserTag_Percentage TINYINT = 75;               
DECLARE @ImportHeader_Percentage TINYINT = 80;               
DECLARE @ImportFooter_Percentage TINYINT = 85;               
DECLARE @ImportProjectSegmentGlobalTerm_Percentage TINYINT = 90;               
DECLARE @ImportProjectGlobalTerm_Percentage TINYINT = 92;              
DECLARE @ImportProjectSegmentLink_Percentage TINYINT = 95;               
DECLARE @ImportProjectHyperLink_Percentage TINYINT = 98;               
DECLARE @ImportComplete_Percentage TINYINT = 100;               
DECLARE @ImportFailed_Percentage TINYINT = 100;               
              
DECLARE @ImportStart_Step TINYINT = 1;                
DECLARE @ImportProjectSection_Step TINYINT = 2;                              
DECLARE @ImportProjectSegment_Step TINYINT = 3;              
DECLARE @ImportProjectSegmentStatus_Step TINYINT = 4;               
DECLARE @ImportProjectSegmentChoice_Step TINYINT = 5;              
DECLARE @ImportProjectChoiceOption_Step TINYINT = 6;              
DECLARE @ImportSelectedChoiceOption_USERCHOICE_Step TINYINT = 7;              
DECLARE @ImportSelectedChoiceOption_MASTERCHOICE_Step TINYINT = 8;                  
DECLARE @ImportProjectNote_Step TINYINT = 9;              
DECLARE @ImportProjectNoteImage_Step TINYINT = 10;              
DECLARE @ImportProjectSegmentImage_Step TINYINT = 11;              
DECLARE @ImportProjectReferenceStandard_Step TINYINT = 12;              
DECLARE @ImportProjectSegmentReferenceStandard_Step TINYINT = 13;              
DECLARE @ImportProjectSegmentRequirementTag_Step TINYINT = 14;              
DECLARE @ImportProjectSegmentUserTag_Step TINYINT = 15;              
DECLARE @ImportHeader_Step TINYINT = 16;              
DECLARE @ImportFooter_Step TINYINT = 17;              
DECLARE @ImportProjectSegmentGlobalTerm_Step TINYINT = 18;              
DECLARE @ImportProjectGlobalTerm_Step TINYINT = 19;              
DECLARE @ImportProjectSegmentLink_Step TINYINT = 20;              
DECLARE @ImportProjectHyperLink_Step TINYINT = 21;              
DECLARE @ImportComplete_Step TINYINT = 22;              
DECLARE @ImportFailed_Step TINYINT = 23;              
        
DECLARE  @ImportPending TINYINT =1;        
DECLARE  @ImportStarted TINYINT =2;        
DECLARE  @ImportCompleted TINYINT =3;        
DECLARE  @Importfailed TINYINT =4        
        
DECLARE @IsCompleted BIT =1;        
        
DECLARE @ImportSource Nvarchar(100)='Import From Project'         
                            
     
 BEGIN TRY                    
 --DECLARE VARIABLES                    
 DECLARE @ParentSectionId INT = NULL;      
              
 DECLARE @ParentSectionTbl AS TABLE (                    
  ParentSectionId INT                    
 );      
              
 DECLARE @TargetSectionId INT = NULL;      
              
 DECLARE @SectionCode INT = NULL;      
              
 DECLARE @SourceTag VARCHAR(10) = '';      
                    
 DECLARE @mSectionId INT = 0;      
                    
 DECLARE @Author NVARCHAR(MAX) = '';                  
               
    --Add Logs to ImportProjectHistory              
 EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportStart_Description                
           ,@ImportStart_Description                          
           ,@IsCompleted                     
           ,@ImportStart_Step --Step                   
     ,@RequestId              
              
 --Add Logs to ImportProjectRequest              
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId       
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                 
         ,@PCustomerId                          
        ,@ImportStarted             
         ,@ImportStart_Percentage --Percent                          
         , 0              
   ,@ImportSource            
         , @RequestId;     
      
--FETCH SECTIONS DETAILS INTO VARIABLES                    
SELECT      
 @SectionCode = SectionCode      
   ,@SourceTag = SourceTag      
   ,@mSectionId = mSectionId      
   ,@Author = Author      
FROM ProjectSection WITH (NOLOCK)      
WHERE SectionId = @PSourceSectionId;      
      
--DELETE EXISTING ONE And Also Lock IT.        
DECLARE @OldSectionId INT=(SELECT top 1 SectionId FROM ProjectSection PS WITH (NOLOCK)                    
WHERE PS.ProjectId = @PTargetProjectId                 
AND PS.IsLastLevel = 1                    
AND PS.SourceTag = @SourceTag                    
AND PS.Author = @Author                    
AND ISNULL(PS.IsDeleted,0) = 0)    
    
IF(ISNULL(@OldSectionId,0)=0)    
BEGIN    
 SET @OldSectionId =(SELECT top 1 SectionId FROM ProjectSection PS WITH (NOLOCK)                    
 WHERE PS.ProjectId = @PTargetProjectId                 
 AND PS.IsLastLevel = 1                    
 AND PS.SectionCode = @SectionCode  
 AND PS.SourceTag = @SourceTag                      
 AND PS.Author = @Author                    
 AND ISNULL(PS.IsDeleted,0)=0)    
END    
       
UPDATE PS      
SET PS.IsDeleted = 1      
FROM ProjectSection PS WITH (NOLOCK)      
WHERE PS.SectionId = @OldSectionId    
--AND PS.ProjectId = @PTargetProjectId      
--AND PS.IsLastLevel = 1      
--AND PS.SourceTag = @SourceTag      
--AND PS.Author = @Author      
--AND ISNULL(PS.IsDeleted,0) = 0;    
      
--DELETE EXISTING IF SectionCode already presents                    
--UPDATE PS      
--SET PS.IsDeleted = 1      
--FROM ProjectSection PS WITH (NOLOCK)      
--WHERE PS.ProjectId = @PTargetProjectId      
--AND PS.IsLastLevel = 1      
--AND PS.SectionCode = @SectionCode      
--AND ISNULL(PS.IsDeleted,0) = 0    
    
    
INSERT INTO @ParentSectionTbl (ParentSectionId)      
EXEC [usp_GetParentSectionIdForImportedSection] @PTargetProjectId      
              ,@PCustomerId      
              ,@PUserId      
              ,@SourceTag      
      
SELECT TOP 1      
 @ParentSectionId = ParentSectionId      
FROM @ParentSectionTbl      
      
INSERT INTO ProjectSection (ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode,      
Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, CreateDate,      
CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId, SpecViewModeId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy)      
 SELECT      
  @ParentSectionId AS ParentSectionId      
    ,mSectionId      
    ,@PTargetProjectId AS ProjectId      
    ,@PCustomerId AS CustomerId      
    ,@PUserId AS UserId      
    ,DivisionId      
    ,DivisionCode      
    ,Description      
    ,LevelId      
    ,IsLastLevel      
    ,SourceTag      
    ,Author      
    ,TemplateId      
    ,SectionCode      
    ,IsDeleted      
    ,GETUTCDATE()      
    ,@PUserId      
    ,@PUserId      
    ,GETUTCDATE()      
    ,FormatTypeId      
    ,SpecViewModeId  
	,IsTrackChanges
	,IsTrackChangeLock
	,COALESCE(TrackChangeLockedBy, 0) AS TrackChangeLockedBy
 FROM ProjectSection PS WITH (NOLOCK)      
 WHERE PS.SectionId = @PSourceSectionId
      
SET @TargetSectionId = SCOPE_IDENTITY();      
    
   --Add Logs to ImportProjectHistory              
 EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectSection_Description                          
           ,@ImportProjectSection_Description                          
        ,@IsCompleted                      
           ,@ImportProjectSection_Step --Step                   
     ,@RequestId              
              
 --Add Logs to ImportProjectRequest              
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
           ,@ImportStarted                      
         ,@ImportProjectSection_Percentage --Percent                          
         , 0              
    ,@ImportSource                
         , @RequestId;               
                    
--INSERT Src SegmentStatus into Temp tables                    
SELECT      
 PSST.* INTO #tmp_SrcSegmentStatus      
FROM ProjectSegmentStatus PSST WITH (NOLOCK)      
WHERE PSST.ProjectId = @PSourceProjectId      
AND PSST.SectionId = @PSourceSectionId      
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
 FROM #tmp_SrcSegmentStatus PSS WITH (NOLOCK);      
      
--INSERT Tgt SegmentStatus into Temp tables                    
SELECT      
 PSST.* INTO #tmp_TgtSegmentStatus      
FROM ProjectSegmentStatus PSST WITH (NOLOCK)      
WHERE PSST.ProjectId = @PTargetProjectId      
AND PSST.SectionId = @TargetSectionId      
      
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
      
----UPDATE PARENT SEGMENT STATUS ID                    
--UPDATE TPSS_Child                    
--SET TPSS_Child.ParentSegmentStatusId = TPSS_Parent.SegmentStatusId                    
--FROM #tmp_TgtSegmentStatus TPSS_Child WITH (NOLOCK)                    
--INNER JOIN #tmp_SrcSegmentStatus SPSS_Child WITH (NOLOCK)                    
-- ON TPSS_Child.SegmentStatusCode = SPSS_Child.SegmentStatusCode                    
--INNER JOIN #tmp_SrcSegmentStatus SPSS_Parent WITH (NOLOCK)                    
-- ON SPSS_Child.ParentSegmentStatusId = SPSS_Parent.SegmentStatusId                    
--INNER JOIN #tmp_TgtSegmentStatus TPSS_Parent WITH (NOLOCK)                    
-- ON SPSS_Parent.SegmentStatusCode = TPSS_Parent.SegmentStatusCode                    
      
--INSERT Src Segment into Temp tables                    
      
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
INNER JOIN #tmp_TgtSegmentStatus PSST_Src WITH (NOLOCK)      
 ON PSG.SegmentStatusId = PSST_Src.A_SegmentStatusId      
WHERE PSG.ProjectId = @PSourceProjectId      
AND PSG.SectionId = @PSourceSectionId      
 AND ISNULL(PSG.IsDeleted,0)=0    
    
--INSERT INTO PROJECTSEGMENT                    
INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription,      
SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, A_SegmentId, BaseSegmentDescription)      
 SELECT      
  *      
 FROM #tmp_SrcSegment PSG_Source (NOLOCK)      
      
 EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectSegment_Description                          
           ,@ImportProjectSegment_Description                          
           ,@IsCompleted                          
           ,@ImportProjectSegment_Step --Step                   
     ,@RequestId              
              
 --Add Logs to ImportProjectRequest              
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId             
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
          ,@ImportStarted                    
         ,@ImportProjectSegment_Percentage --Percent                          
         , 0              
    ,@ImportSource             
         , @RequestId;               
                    
    
--INSERT Tgt Segment into Temp tables                    
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
WHERE PSG.ProjectId = @PTargetProjectId      
AND PSG.SectionId = @TargetSectionId    
  AND ISNULL(PSG.IsDeleted,0)=0    
    
 --UPDATE SegmentId IN ProjectSegmentStatus Temp (Changed for CSI 37207)
UPDATE PSST_Target
SET PSST_Target.SegmentId = PSG_Target.SegmentId
FROM #tmp_TgtSegmentStatus PSST_Target WITH (NOLOCK)
INNER JOIN ProjectSegmentStatus PSST_Source WITH (NOLOCK)
	ON PSST_Target.SegmentStatusCode = PSST_Source.SegmentStatusCode
	AND PSST_Source.SectionId = @PSourceSectionId
INNER JOIN ProjectSegment PSG_Source WITH (NOLOCK)
	ON PSST_Source.SegmentId = PSG_Source.SegmentId
INNER JOIN #tmp_TgtSegment PSG_Target WITH (NOLOCK)
	ON PSG_Source.SegmentCode = PSG_Target.SegmentCode
	AND PSG_Target.SectionId = @TargetSectionId
WHERE PSST_Target.SectionId = @TargetSectionId
      
--UPDATE ParentSegmentStatusId IN ORIGINAL TABLES                    
UPDATE PSST      
SET PSST.ParentSegmentStatusId = TMP.ParentSegmentStatusId      
   ,PSST.SegmentId = TMP.SegmentId      
FROM ProjectSegmentStatus PSST WITH (NOLOCK)      
INNER JOIN #tmp_TgtSegmentStatus TMP WITH (NOLOCK)      
 ON PSST.SegmentStatusId = TMP.SegmentStatusId      
WHERE PSST.ProjectId = @PTargetProjectId      
AND PSST.SectionId = @TargetSectionId;      
      
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectSegmentStatus_Description                          
           ,@ImportProjectSegmentStatus_Description                          
          ,@IsCompleted                     
           ,@ImportProjectSegmentStatus_Step --Step                   
     ,@RequestId              
              
 --Add Logs to ImportProjectRequest              
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
         ,@ImportStarted                     
         ,@ImportProjectSegmentStatus_Percentage --Percent                          
         , 0              
    ,@ImportSource      
         , @RequestId;               
                    
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
 --INNER JOIN #tmp_SrcSegment PS_Source WITH (NOLOCK)                    
 -- ON PCH_Source.SegmentId = PS_Source.SegmentId                    
 INNER JOIN #tmp_TgtSegment PS_Target WITH (NOLOCK)      
  ON PCH_Source.SegmentId = PS_Target.A_SegmentId      
 WHERE PCH_Source.ProjectId = @PSourceProjectId      
 AND PCH_Source.SectionId = @PSourceSectionId      
 AND ISNULL(PCH_Source.IsDeleted, 0) = 0      
--AND ISNULL(PS_Target.IsDeleted, 0) = 0              
      
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectSegmentChoice_Description                          
           ,@ImportProjectSegmentChoice_Description                          
           ,@IsCompleted                   
           ,@ImportProjectSegmentChoice_Step --Step                   
     ,@RequestId              
              
 --Add Logs to ImportProjectRequest              
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
           ,@ImportStarted                  
         ,@ImportProjectSegmentChoice_Percentage --Percent                          
         , 0              
    ,@ImportSource            
         , @RequestId;               
                    
SELECT      
 ProjectId      
   ,SectionId      
   ,CustomerId      
   ,SegmentChoiceId      
   ,A_SegmentChoiceId INTO #tgtProjectSegmentChoice      
FROM ProjectSegmentChoice WITH (NOLOCK)      
WHERE ProjectId = @TargetProjectId      
AND SectionId = @TargetSectionId      
      
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
  ON PCH_Source.SegmentChoiceId = t.A_SegmentChoiceId      
 --INNER JOIN ProjectSegmentChoice PCH_Source WITH (NOLOCK)                    
 -- ON PCH_Source.ProjectId = @PSourceProjectId                    
 --  AND PCH_Source.SectionId = @PSourceSectionId                    
 --  AND PCHOP_Source.SegmentChoiceId = PCH_Source.SegmentChoiceId                    
 --INNER JOIN ProjectSegmentChoice PCH_Target WITH (NOLOCK)                    
 -- ON PCH_Target.ProjectId = @PTargetProjectId                    
 --  AND PCH_Target.SectionId = @TargetSectionId                    
 --  AND PCH_Source.SegmentChoiceCode = PCH_Target.SegmentChoiceCode                    
 --INNER JOIN #tmp_TgtSegment PS_Target ON PS_Target.SegmentId = t.SegmentId                 
 WHERE PCH_Source.ProjectId = @PSourceProjectId      
 AND PCH_Source.SectionId = @PSourceSectionId      
 AND ISNULL(PCH_Source.IsDeleted, 0) = 0      
      
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectChoiceOption_Description                          
           ,@ImportProjectChoiceOption_Description                          
          ,@IsCompleted                     
           ,@ImportProjectChoiceOption_Step --Step                   
     ,@RequestId              
              
 --Add Logs to ImportProjectRequest              
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
          ,@ImportStarted                 
         ,@ImportProjectChoiceOption_Percentage --Percent                          
         , 0              
   ,@ImportSource                
         , @RequestId;               
       
    
DROP TABLE #tgtProjectSegmentChoice      
      
--INSERT SELECTED CHOICE OPTIONS OF USER CHOICE                   
INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId)      
 SELECT DISTINCT      
  SCHOP_Source.SegmentChoiceCode      
    ,SCHOP_Source.ChoiceOptionCode      
    ,SCHOP_Source.ChoiceOptionSource      
    ,SCHOP_Source.IsSelected      
    ,@TargetSectionId AS SectionId      
    ,@PTargetProjectId AS ProjectId      
    ,@PCustomerId AS CustomerId      
 FROM SelectedChoiceOption SCHOP_Source WITH (NOLOCK)      
 INNER JOIN ProjectSegmentChoice PSC WITH (NOLOCK)      
  ON PSC.SectionId = SCHOP_Source.SectionId      
   AND PSC.ProjectId = SCHOP_Source.ProjectId      
   AND PSC.SegmentChoiceCode = SCHOP_Source.SegmentChoiceCode      
 INNER JOIN ProjectChoiceOption PCO WITH (NOLOCK)      
  ON PCO.SegmentChoiceId = PSC.SegmentChoiceId      
   AND PCO.SectionId = PCO.SectionId      
   AND PCO.ChoiceOptionCode=SCHOP_Source.ChoiceOptionCode    
   AND SCHOP_Source.SegmentChoiceCode=PSC.SegmentChoiceCode    
   AND PCO.ProjectId = SCHOP_Source.ProjectId      
 --INNER JOIN #tmp_TgtSegment PS_Target              
 -- ON PSC.SegmentId = PS_Target.SegmentId              
 WHERE SCHOP_Source.ProjectId = @PSourceProjectId      
 AND SCHOP_Source.SectionId = @PSourceSectionId      
 AND ISNULL(SCHOP_Source.IsDeleted, 0) = 0      
 --AND ISNULL(PS_Target.IsDeleted, 0) = 0              
 AND SCHOP_Source.ChoiceOptionSource = 'U'      
      
    
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportSelectedChoiceOption_USERCHOICE_Description                          
          ,@ImportSelectedChoiceOption_USERCHOICE_Description                          
           ,@IsCompleted                      
           ,@ImportSelectedChoiceOption_USERCHOICE_Step --Step                   
     ,@RequestId              
              
 --Add Logs to ImportProjectRequest              
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
         ,@ImportStarted                     
        ,@ImportSelectedChoiceOption_USERCHOICE_Percentage --Percent                          
         , 0              
   ,@ImportSource           
         , @RequestId;                 
                    
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
 WHERE SCHOP_Source.ProjectId = @PSourceProjectId      
 AND SCHOP_Source.SectionId = @PSourceSectionId      
 AND ISNULL(SCHOP_Source.IsDeleted, 0) = 0      
 AND SCHOP_Source.ChoiceOptionSource = 'M'      
      
       EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportSelectedChoiceOption_MASTERCHOICE_Description                          
          ,@ImportSelectedChoiceOption_MASTERCHOICE_Description                          
           ,@IsCompleted               
           ,@ImportSelectedChoiceOption_MASTERCHOICE_Step --Step                   
     ,@RequestId              
              
 --Add Logs to ImportProjectRequest              
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
          ,@ImportStarted                 
      ,@ImportSelectedChoiceOption_MASTERCHOICE_Percentage --Percent                          
         , 0              
   ,@ImportSource           
         , @RequestId;                    
                    
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
  ON PN.SegmentStatusId = t.A_SegmentStatusId      
 --INNER JOIN #tmp_SrcSegmentStatus PSS_Source WITH (NOLOCK)                    
 -- ON PN.SegmentStatusId = PSS_Source.SegmentStatusId                    
 --INNER JOIN #tmp_TgtSegmentStatus PSS_Target WITH (NOLOCK)                    
 -- ON PSS_Source.SegmentStatusCode = PSS_Target.SegmentStatusCode                    
 WHERE PN.ProjectId = @PSourceProjectId      
 AND PN.SectionId = @PSourceSectionId      
      
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectNote_Description                          
          ,@ImportProjectNote_Description                          
         ,@IsCompleted                
           ,@ImportProjectNote_Step --Step                   
     ,@RequestId;              
              
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
           ,@ImportStarted             
       ,@ImportProjectNote_Percentage --Percent                          
         , 0              
    ,@ImportSource             
         , @RequestId;                       
                    
SELECT      
 * INTO #note      
FROM ProjectNote WITH (NOLOCK)      
WHERE SectionId = @TargetSectionId      
AND ProjectId = @TargetProjectId      
      
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
 --INNER JOIN ProjectNote PN_Target WITH (NOLOCK)                    
 -- ON PN_Target.ProjectId = @PTargetProjectId                    
 --  AND PN_Target.SectionId = @TargetSectionId                    
 --  AND PN_Source.NoteCode = PN_Target.NoteCode                    
 WHERE PNI.ProjectId = @PSourceProjectId      
 AND PNI.SectionId = @PSourceSectionId      
      
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectNoteImage_Description                          
          ,@ImportProjectNoteImage_Description                          
          ,@IsCompleted             
           ,@ImportProjectNoteImage_Step --Step                   
     ,@RequestId;              
              
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
          ,@ImportStarted                   
       ,@ImportProjectNoteImage_Percentage --Percent                          
         , 0              
    ,@ImportSource           
         , @RequestId;                  
                    
DROP TABLE #note      
      
--INSERT ProjectSegmentImage                    
INSERT INTO ProjectSegmentImage (SectionId, ImageId, ProjectId, CustomerId, SegmentId,ImageStyle)      
 SELECT      
  @TargetSectionId AS SectionId      
    ,ImageId      
    ,@PTargetProjectId AS ProjectId      
    ,@PCustomerId AS CustomerId      
    ,0 AS SegmentId      
 ,PSI.ImageStyle     
 FROM ProjectSegmentImage PSI WITH (NOLOCK)      
 WHERE PSI.ProjectId = @PSourceProjectId      
 AND PSI.SectionId = @PSourceSectionId      
      
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectSegmentImage_Description                          
          ,@ImportProjectSegmentImage_Description                          
          ,@IsCompleted              
           ,@ImportProjectSegmentImage_Step --Step                   
     ,@RequestId;              
              
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
          ,@ImportStarted             
       ,@ImportProjectSegmentImage_Percentage --Percent                          
         , 0              
    ,@ImportSource           
         , @RequestId;                       
    
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
 WHERE ProjectId = @PSourceProjectId      
 AND SectionId = @PSourceSectionId      
 AND ISNULL(IsDeleted, 0) = 0      
      
   EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectReferenceStandard_Description                          
          ,@ImportProjectReferenceStandard_Description                          
         ,@IsCompleted    
           ,@ImportProjectReferenceStandard_Step --Step                   
     ,@RequestId;              
              
 EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                   
          ,@ImportStarted             
       ,@ImportProjectReferenceStandard_Percentage --Percent                          
         , 0              
   ,@ImportSource           
         , @RequestId;                     
                    
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
 WHERE PSRS.ProjectId = @PSourceProjectId                    
 AND PSRS.SectionId = @PSourceSectionId                 
               
EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectSegmentReferenceStandard_Description                          
          ,@ImportProjectSegmentReferenceStandard_Description                          
       ,@IsCompleted                  
           ,@ImportProjectSegmentReferenceStandard_Step --Step                   
     ,@RequestId;              
              
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
         ,@ImportStarted              
       ,@ImportProjectSegmentReferenceStandard_Percentage --Percent                         
         , 0              
   ,@ImportSource           
         , @RequestId;                        
                    
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
 --INNER JOIN #tmp_SrcSegmentStatus PSS_Source WITH (NOLOCK)                    
 -- ON PSRT.SegmentStatusId = PSS_Source.SegmentStatusId                    
 INNER JOIN #tmp_TgtSegmentStatus PSS_Target WITH (NOLOCK)      
  ON PSRT.SegmentStatusId = PSS_Target.A_SegmentStatusId      
 WHERE PSRT.ProjectId = @PSourceProjectId      
 AND PSRT.SectionId = @PSourceSectionId      
      
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectSegmentRequirementTag_Description                          
          ,@ImportProjectSegmentRequirementTag_Description                          
           ,@IsCompleted                  
           ,@ImportProjectSegmentRequirementTag_Step --Step                   
     ,@RequestId;              
              
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                        
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
           ,@ImportStarted                
       ,@ImportProjectSegmentRequirementTag_Percentage --Percent                          
         , 0              
    ,@ImportSource           
         , @RequestId;                        
                    
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
 --INNER JOIN #tmp_SrcSegmentStatus PSS_Source WITH (NOLOCK)                    
 -- ON PSUT.SegmentStatusId = PSS_Source.SegmentStatusId                    
 INNER JOIN #tmp_TgtSegmentStatus PSS_Target WITH (NOLOCK)      
  ON PSUT.SegmentStatusId = PSS_Target.A_SegmentStatusId      
 WHERE PSUT.ProjectId = @PSourceProjectId      
 AND PSUT.SectionId = @PSourceSectionId      
      
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectSegmentUserTag_Description                          
          ,@ImportProjectSegmentUserTag_Description                          
          ,@IsCompleted               
           ,@ImportProjectSegmentUserTag_Step --Step                   
     ,@RequestId;              
              
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
           ,@ImportStarted                    
       ,@ImportProjectSegmentUserTag_Percentage --Percent                          
         , 0              
   ,@ImportSource           
         , @RequestId;                     
                    
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
 WHERE ProjectId = @PSourceProjectId      
 AND SectionId = @PSourceSectionId      
      
   EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportHeader_Description                          
          ,@ImportHeader_Description                          
         ,@IsCompleted                 
           ,@ImportHeader_Step --Step                   
     ,@RequestId;              
          
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
          ,@ImportStarted                 
       ,@ImportHeader_Percentage --Percent                          
         , 0              
   ,@ImportSource           
         , @RequestId;                   
                    
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
 WHERE ProjectId = @PSourceProjectId                    
 AND SectionId = @PSourceSectionId                  
               
EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportFooter_Description                          
          ,@ImportFooter_Description                          
         ,@IsCompleted                      
           ,@ImportFooter_Step --Step                   
     ,@RequestId;              
              
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
          ,@ImportStarted             
       ,@ImportFooter_Percentage --Percent                          
         , 0              
    ,@ImportSource           
         , @RequestId;                     
                    
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
 WHERE PSGT.ProjectId = @PSourceProjectId      
 AND PSGT.SectionId = @PSourceSectionId      
      
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectSegmentGlobalTerm_Description                          
          ,@ImportProjectSegmentGlobalTerm_Description                          
          ,@IsCompleted                           
           ,@ImportProjectSegmentGlobalTerm_Step --Step                   
     ,@RequestId;              
              
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
         ,@ImportStarted             
       ,@ImportProjectSegmentGlobalTerm_Percentage --Percent                          
         , 0              
   ,@ImportSource           
         , @RequestId;                        
                    
SELECT      
 * INTO #PrjSegGblTerm      
FROM ProjectSegmentGlobalTerm WITH (NOLOCK)      
WHERE SectionId = @TargetSectionId      
AND ProjectId = @TargetProjectId      
      
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
 --  AND PGT_Source.GlobalTermCode = PSGT_Source.GlobalTermCode                    
 --LEFT JOIN ProjectGlobalTerm PGT_Target WITH (NOLOCK)                    
 -- ON PGT_Target.ProjectId = @PTargetProjectId                    
 --  AND PGT_Source.GlobalTermCode = PGT_Target.GlobalTermCode                    
 WHERE PGT_Source.ProjectId = @PSourceProjectId      
 AND PSGT_Source.SectionId = @PSourceSectionId      
 AND PSGT_Source.IsDeleted = 0      
      
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectGlobalTerm_Description                          
          ,@ImportProjectGlobalTerm_Description                    
       ,@IsCompleted                         
            ,@ImportProjectGlobalTerm_Step --Step                   
     ,@RequestId;             
              
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
          ,@ImportStarted             
        ,@ImportProjectGlobalTerm_Percentage --Percent                          
         , 0              
   ,@ImportSource           
         , @RequestId;                    
                    
SELECT      
 * INTO #tmp_SrcSegmentLink      
FROM ProjectSegmentLink PSLNK WITH (NOLOCK)      
WHERE PSLNK.ProjectId = @PSourceProjectId      
AND (PSLNK.SourceSectionCode = @SectionCode      
OR PSLNK.TargetSectionCode = @SectionCode)      
AND PSLNK.IsDeleted = 0;      
      
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
      
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectSegmentLink_Description                          
          ,@ImportProjectSegmentLink_Description                    
      ,@IsCompleted                       
            ,@ImportProjectSegmentLink_Step --Step                   
     ,@RequestId;              
              
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
          ,@ImportStarted             
        ,@ImportProjectSegmentLink_Percentage --Percent                          
         , 0              
    ,@ImportSource           
         , @RequestId;                   
                    
    
--- INSERT ProjectHyperLink              
INSERT INTO ProjectHyperLink (SectionId, SegmentId, SegmentStatusId, ProjectId,      
CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy      
, A_HyperLinkId)      
 SELECT      
  @TargetSectionId      
    ,PSS_Target.SegmentId      
    ,PSS_Target.SegmentStatusId      
    ,@TargetProjectId      
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
 WHERE PHL.ProjectId = @PSourceProjectId      
 AND PHL.SectionId = @PSourceSectionId      
      
---UPDATE NEW HyperLinkId in SegmentDescription             
      
DECLARE @MultipleHyperlinkCount INT = 0;      
SELECT      
 COUNT(SegmentStatusId) AS TotalCountSegmentStatusId INTO #TotalCountSegmentStatusIdTbl      
FROM ProjectHyperLink WITH(NOLOCK)      
WHERE ProjectId = @TargetProjectId      
AND SectionId = @TargetSectionId      
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
AND PHL.ProjectId = @TargetProjectId      
AND PS.SegmentDescription LIKE '%{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '}%'      
AND PS.SegmentDescription LIKE '%{HL#%'      
SET @MultipleHyperlinkCount =@MultipleHyperlinkCount-1;      
END      
    
  EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportProjectHyperLink_Description                          
          ,@ImportProjectHyperLink_Description                    
      ,@IsCompleted                      
            ,@ImportProjectHyperLink_Step --Step                   
     ,@RequestId;              
              
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
           ,@ImportStarted             
        ,@ImportProjectHyperLink_Percentage --Percent                          
         , 0              
    ,@ImportSource            
         , @RequestId;                   
                    
--SELECT FINAL REQUIRED RESULT                    
SELECT      
 SectionId      
   ,ParentSectionId      
   ,mSectionId      
   ,ProjectId      
   ,CustomerId      
   ,UserId      
   ,DivisionId      
   ,DivisionCode      
   ,Description      
   ,SourceTag      
   ,Author      
   ,SectionCode      
   ,@OldSectionId as A_SectionId    
FROM ProjectSection WITH (NOLOCK)      
WHERE SectionId = @TargetSectionId      
      
--UNLOCK Source And Target Section                    
--EXEC usp_unLockImportedSourceAndTargetSection @PSourceSectionId                    
--     ,@PTargetProjectId                    
--            ,@SourceTag                    
--            ,@Author                    
--            ,0                    
      EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportComplete_Description                          
          ,@ImportComplete_Description                    
         ,@IsCompleted                      
            ,@ImportComplete_Step --Step                   
     ,@RequestId;              
              
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
          ,@ImportCompleted          
        ,@ImportComplete_Percentage --Percent                          
         , 0              
    ,@ImportSource           
         , @RequestId;                    
                    
END TRY      
BEGIN CATCH      
              
DECLARE @ResultMessage NVARCHAR(MAX);                          
SET @ResultMessage = 'Rollback Transaction. Error Number: ' + CONVERT(VARCHAR(MAX), ERROR_NUMBER()) +                    
'. Error Message: ' + CONVERT(VARCHAR(MAX), ERROR_MESSAGE()) +                          
'. Procedure Name: ' + CONVERT(VARCHAR(MAX), ERROR_PROCEDURE()) +                          
'. Error Severity: ' + CONVERT(VARCHAR(5), ERROR_SEVERITY()) +                          
'. Line Number: ' + CONVERT(VARCHAR(5), ERROR_LINE());                  
              
EXEC usp_unLockImportedSourceAndTargetSection @PSourceSectionId                    
            ,@PTargetProjectId                    
            ,@SourceTag                    
            ,@Author                    
            ,1                 
                 
    EXEC usp_MaintainImportProjectHistory @PTargetProjectId                          
           ,@ImportFailed_Description                          
          ,@ResultMessage                    
         ,@IsCompleted                   
            ,@ImportFailed_Step --Step                   
     ,@RequestId;              
              
EXEC usp_MaintainImportProjectProgress @PSourceProjectId                          
         ,@PTargetProjectId                   
   ,@PSourceSectionId              
  , @TargetSectionId                     
         ,@PUserId                          
         ,@PCustomerId                          
         ,@Importfailed        
        ,@ImportFailed_Percentage --Percent                          
         , 0              
    ,@ImportSource           
         , @RequestId;                  
END CATCH      
END 
GO
Print '28. usp_ImportSectionFromProject'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_ImportToolChoicesInsert]
(
@InpChoiceJson NVARCHAR(MAX),
@InpOptionJson NVARCHAR(MAX)
)
AS
BEGIN
DECLARE @PInpChoiceJson NVARCHAR(MAX) = @InpChoiceJson;
DECLARE @PInpOptionJson NVARCHAR(MAX) = @InpOptionJson;

print @PInpChoiceJson
print @PInpOptionJson
DECLARE @ProjectId INT;  
DECLARE @SectionId INT;  
DECLARE @CustomerId INT;  
DECLARE @UserId INT;
 

 --DECLARE INP Choice TABLE   
 DECLARE @InpChoiceTable TABLE(   
         TempChoiceId INT,
		 SegmentChoiceId INT,
		 SegmentChoiceCode INT,
         SegmentId INT,
         SegmentStatusId INT,
         ChoiceTypeId INT,
         ProjectId INT,
         CustomerId INT,  
		 UserId INT,       
         SectionId INT    
 );

  --DECLARE INP Choice TABLE   
 DECLARE @InpOptionTable TABLE(  
         TempOptionId INT, 
		 ChoiceOptionId BIGINT,
		 ChoiceOptionCode INT,
		 SegmentChoiceId INT, 
         SortOrder INT,
         OptionJson NVARCHAR(MAX),  
		 IsSelected BIT   
 );
 


 IF @PInpChoiceJson != ''  
BEGIN
INSERT INTO @InpChoiceTable
	SELECT
		*
	FROM OPENJSON(@PInpChoiceJson)
	WITH (
	TempChoiceId INT '$.TempChoiceId',
	SegmentChoiceId INT '$.SegmentChoiceId',
	SegmentChoiceCode INT '$.SegmentChoiceCode',
	SegmentId INT '$.SegmentId',
	SegmentStatusId INT '$.SegmentStatusId'	,
	ChoiceTypeId INT '$.ChoiceTypeId',
	ProjectId INT '$.ProjectId',
	CustomerId INT '$.CustomerId',
	UserId INT '$.UserId', 
	SectionId INT '$.SectionId'
	);
END
 

IF @PInpOptionJson != ''
BEGIN
INSERT INTO @InpOptionTable
	SELECT
		*
	FROM OPENJSON(@PInpOptionJson)
	WITH (
	TempOptionId INT '$.TempOptionId',
	ChoiceOptionId BIGINT '$.ChoiceOptionId',
	ChoiceOptionCode INT '$.ChoiceOptionCode',
	SegmentChoiceId INT '$.SegmentChoiceId',
	SortOrder INT '$.SortOrder',
	OptionJson NVARCHAR(MAX) '$.OptionJson',
	IsSelected BIT '$.IsSelected'
	);
END
 

SELECT TOP 1
	@ProjectId = ProjectId
   ,@SectionId = SectionId
   ,@CustomerId = CustomerId
   ,@UserId = UserId
FROM @InpChoiceTable

-- Insert Choice
INSERT INTO ProjectSegmentChoice (SectionId,SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource,
CreatedBy, CreateDate, ModifiedBy, ModifiedDate, A_SegmentChoiceId, IsDeleted)
	SELECT
		@SectionId AS SectionId
	   ,CHT.SegmentStatusId AS SegmentStatusId
	   ,CHT.SegmentId AS SegmentId
	   ,CHT.ChoiceTypeId AS ChoiceTypeId
	   ,@ProjectId AS ProjectId
	   ,@CustomerId AS CustomerId
	   ,'U' AS SegmentChoiceSource
	   ,@UserId AS CreatedBy
	   ,GETUTCDATE() AS CreateDate
	   ,@UserId AS ModifiedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,CHT.TempChoiceId AS A_SegmentChoiceId
	   ,0 AS IsDeleted
	FROM @InpChoiceTable CHT

	-- Update ChoiceId And Code to TempChoice  Table
UPDATE CHT
SET CHT.SegmentChoiceId = PSC.SegmentChoiceId
   ,CHT.SegmentChoiceCode = PSC.SegmentChoiceCode
FROM @InpChoiceTable CHT
INNER JOIN ProjectSegmentChoice PSC WITH (NOLOCK)
	ON CHT.TempChoiceId = PSC.A_SegmentChoiceId
WHERE PSC.ProjectId = @ProjectId
AND PSC.SectionId = @SectionId
AND PSC.CustomerId = @CustomerId

-- Update ChoiceId to TempChoiceOption Table
UPDATE OPT
SET OPT.SegmentChoiceId = CHT.SegmentChoiceId
FROM @InpOptionTable OPT
INNER JOIN @InpChoiceTable CHT 
	ON OPT.SegmentChoiceId = CHT.TempChoiceId


--INSERT ProjectChoiceOption    
INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId,
CustomerId, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted, A_ChoiceOptionId)
	SELECT
		OPT.SegmentChoiceId AS SegmentChoiceId
	   ,OPT.SortOrder AS SortOrder
	   ,'U' AS ChoiceOptionSource
	   ,OPT.OptionJson AS OptionJson
	   ,@ProjectId AS ProjectId
	   ,@SectionId AS SectionId
	   ,@CustomerId AS CustomerId
	   ,@UserId AS CreatedBy
	   ,GETUTCDATE() AS CreateDate
	   ,@UserId AS ModifiedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,0 AS IsDeleted
	   ,OPT.TempOptionId AS A_ChoiceOptionId
	FROM @InpOptionTable OPT

	
-- Update OptionId and Code to TempChoiceOption Table
UPDATE OPT
SET OPT.ChoiceOptionId = PCO.ChoiceOptionId
,OPT.ChoiceOptionCode=PCO.ChoiceOptionCode
FROM @InpOptionTable OPT
INNER JOIN ProjectChoiceOption PCO WITH (NOLOCK)
	ON OPT.TempOptionId = PCO.A_ChoiceOptionId
WHERE PCO.ProjectId = @ProjectId
AND PCO.SectionId = @SectionId
AND PCO.CustomerId = @CustomerId

--Insert Selected Choice Option
INSERT INTO SelectedChoiceOption(SegmentChoiceCode,ChoiceOptionCode,ChoiceOptionSource,IsSelected,SectionId,ProjectId,CustomerId,IsDeleted)
SELECT
		CHT.SegmentChoiceCode AS SegmentChoiceCode
	   ,OPT.ChoiceOptionCode AS ChoiceOptionCode
	   ,'U' AS ChoiceOptionSource
	   ,OPT.IsSelected AS IsSelected 
	   ,@SectionId AS SectionId
	   ,@ProjectId AS ProjectId
	   ,@CustomerId AS CustomerId 
	   ,0 AS IsDeleted
	FROM @InpOptionTable OPT
	INNER JOIN @InpChoiceTable CHT ON 
	OPT.SegmentChoiceId=CHT.SegmentChoiceId

	 --SELECT the Choices.  
  SELECT TempChoiceId,
		 SegmentChoiceId,
		 SegmentChoiceCode,
         SegmentId,
         SegmentStatusId,
         ChoiceTypeId,
         ProjectId,
         CustomerId,  
		 UserId,       
         SectionId FROM @InpChoiceTable  

--Update Temp ChoiceId to Null
UPDATE PSC
SET  PSC.A_SegmentChoiceId = NULL
FROM @InpChoiceTable CHT
INNER JOIN ProjectSegmentChoice PSC WITH (NOLOCK)
	ON CHT.TempChoiceId = PSC.A_SegmentChoiceId
WHERE PSC.ProjectId = @ProjectId
AND PSC.SectionId = @SectionId
AND PSC.CustomerId = @CustomerId

--Update Temp ChoiceOptionId to Null
UPDATE PCO
SET PCO.A_ChoiceOptionId = NULL 
FROM @InpOptionTable OPT
INNER JOIN ProjectChoiceOption PCO WITH (NOLOCK)
	ON OPT.TempOptionId = PCO.A_ChoiceOptionId
WHERE PCO.ProjectId = @ProjectId
AND PCO.SectionId = @SectionId
AND PCO.CustomerId = @CustomerId
		 
END
GO
Print '29. [usp_ImportToolChoicesInsert]'
Go

CREATE OR ALTER PROCEDURE usp_LogImportSectionRequest                 
 (             
 @SectionListJson NVARCHAR(MAX)    
 )              
 AS                  
BEGIN              
 DECLARE @PSectionListJson NVarChar(MAX) =@SectionListJson 
              
     DECLARE   @ImportSectionRequest TABLE  ( 
	  TargetProjectId int,  
	  TargetSectionId int, 
	  CreatedById int, 
	  CustomerId int,  
	  Source NVARCHAR(200));      
            
INSERT INTO  @ImportSectionRequest      
SELECT   TargetProjectId,   TargetSectionId, CreatedById ,CustomerId , Source
  FROM OPENJSON(@PSectionListJson)                  
  WITH (       
  TargetProjectId INT '$.TargetProjectId', 
  TargetSectionId INT '$.TargetSectionId',
   CreatedById INT '$.CreatedById',                         
   CustomerId INT '$.CustomerId',         
   Source NVARCHAR(200) '$.Source'      
  );                
              
  Insert INTO ImportProjectRequest (TargetProjectId, TargetSectionId, CreatedById, CustomerId, CreatedDate, ModifiedDate, StatusId, CompletedPercentage, Source, IsNotify)              
  SELECT  TargetProjectId,  TargetSectionId, CreatedById ,CustomerId , getutcdate() as CreateDate, null as ModifiedDate,1 AS StatusId,5 AS CompletedPercentage, Source,0 AS IsNotify    
  FROM @ImportSectionRequest       
             

DECLARE @ImportSectionCount INT;              
Select @ImportSectionCount=COUNT(1)FROM @ImportSectionRequest;              
              
SELECT TOP (@ImportSectionCount) RequestId, TargetSectionId FROM ImportProjectRequest WITH (NOLOCK) order by RequestId desc               
                          
END  
GO
Print '30. usp_LogImportSectionRequest'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_MapGlobalTermToProject]        
 @ProjectID INT NULL,       
 @CustomerID INT NULL,       
 @UserID INT NULL ,    
 @ProjectName NVARCHAR(MAX) = NULL,    
 @MasterDataTypeId INT =1    
AS        
BEGIN    
---- Map All Global Term    
    
DECLARE @PProjectID INT = @ProjectID;    
DECLARE @PCustomerID INT = @CustomerID;    
DECLARE @PUserID INT = @UserID;    
DECLARE @PProjectName NVARCHAR(MAX) = @ProjectName;    
DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;    
DECLARE @StateProvinceName NVARCHAR(100)='', @City NVARCHAR(100)='';    
-- SET City as per selected project    
SET @City = (SELECT TOP 1    
  IIF(LUC.City IS NULL, PADR.CityName, LUC.City) AS City    
 FROM ProjectAddress PADR WITH (NOLOCK)    
 LEFT OUTER JOIN LuCity LUC WITH (NOLOCK)    
  ON LUC.CityId = PADR.CityId    
 WHERE PADR.ProjectId = @PProjectID    
 AND PADR.CustomerId = @PCustomerID);    
-- SET State as per selected project    
SET @StateProvinceName = (SELECT TOP 1    
  IIF(LUS.StateProvinceName IS NULL, PADR.StateProvinceName, LUS.StateProvinceName) AS StateProvinceName    
 FROM ProjectAddress PADR WITH (NOLOCK)    
 LEFT OUTER JOIN LuStateProvince LUS WITH (NOLOCK)    
  ON LUS.StateProvinceID = PADR.StateProvinceId    
 WHERE PADR.ProjectId = @PProjectID    
 AND PADR.CustomerId = @PCustomerID);    
    
 --Map master global term    
INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, [Name], [Value], GlobalTermSource, GlobalTermCode, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted, GlobalTermFieldTypeId)    
 SELECT    
  GlobalTermId    
    ,@PProjectID AS ProjectId    
    ,@PCustomerID AS CustomerId    
    ,[Name]    
  --,Value    
    ,CASE    
   WHEN Name = 'Project Name' THEN CAST(@PProjectName AS NVARCHAR(MAX))    
   WHEN Name = 'Project ID' THEN CAST(@PProjectID AS NVARCHAR(MAX))    
   WHEN Name = 'Project Location State' THEN CAST(@StateProvinceName AS NVARCHAR(MAX))    
   WHEN Name = 'Project Location City' THEN CAST(@City AS NVARCHAR(MAX))    
   WHEN Name = 'Project Location Province' THEN CAST(@StateProvinceName AS NVARCHAR(MAX))    
   ELSE [Value]    
  END AS [Value]    
    ,'M'    
    ,GlobalTermCode    
    ,GETUTCDATE()    
    ,@PUserID AS CreatedBy    
    ,GETUTCDATE()    
    ,@PUserID AS ModifiedBy    
    ,NULL    
    ,0 AS IsDeleted    
    ,GlobalTermFieldTypeId    
 FROM SLCMaster..GlobalTerm WITH(NOLOCK)    
 WHERE MasterDataTypeId =    
 CASE    
  WHEN @PMasterDataTypeId = 1 OR    
   @PMasterDataTypeId = 2 OR    
   @PMasterDataTypeId = 3 THEN 1    
  ELSE @PMasterDataTypeId    
 END;    
 -- Map user global term    
 -- declare table variable  
DECLARE @GlobalTermCode TABLE (  
  MinGlobalTermCode int,  
  UserGlobalTermId int  
);  
  
INSERT @GlobalTermCode  
 SELECT MIN(GlobalTermCode) AS MinGlobalTermCode,UserGlobalTermId      
 FROM ProjectGlobalTerm WITH (NOLOCK)    
 WHERE CustomerId =@PCustomerID AND ISNULL(IsDeleted,0)=0     
 AND GlobalTermSource='U'    
 GROUP BY UserGlobalTermId    
    
INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, Name, Value,GlobalTermCode, GlobalTermSource, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted)    
 SELECT    
  NULL AS GlobalTermId    
    ,@PProjectID AS ProjectId    
    ,@PCustomerID AS CustomerId    
    ,Name    
    ,Name    
    ,MGTC.MinGlobalTermCode    
    ,'U'    
    ,GETUTCDATE()    
    ,@PUserID AS CreatedBy    
    ,GETUTCDATE()    
    ,@PUserID AS ModifiedBy    
    ,UGT.UserGlobalTermId AS UserGlobalTermId    
    ,ISNULL(IsDeleted, 0) AS IsDeleted    
 FROM UserGlobalTerm UGT WITH(NOLOCK) INNER JOIN @GlobalTermCode MGTC   
 ON UGT.UserGlobalTermId=MGTC.UserGlobalTermId    
 WHERE CustomerId = @PCustomerID    
 AND IsDeleted = 0    
END 
GO
Print '31. [usp_MapGlobalTermToProject]'
Go

CREATE OR ALTER PROCEDURE usp_RemoveImportSectionRequest --221   
(    
 @RequestId INT    
)    
AS    
BEGIN    
 UPDATE CPR    
 SET CPR.IsDeleted=1 
 ,CPR.IsNotify=1
 ,ModifiedDate=GETUTCDATE()    
 FROM ImportProjectRequest CPR WITH(NOLOCK)    
 WHERE CPR.StatusId!=2 AND CPR.RequestId=@RequestId    
END  
GO
Print '32. usp_RemoveImportSectionRequest'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_SetProjectSegemntMappingData] (@ProjectId INT,  
@CustomerId INT,  
@segmentMappingDataJson NVARCHAR(MAX),  
@segmentChoiceMappingDataJson NVARCHAR(MAX))  
AS  
BEGIN  
 DECLARE @InCompleteStatus INT = 2;  
 DECLARE @CompleteStatus INT = 3;  
 DECLARE @CompletePer90 INT = 90; 
 DECLARE @CompletePer INT = 100;  
 DECLARE @SegmentMappingTbl TABLE (  
  mSegmentStatusId INT  
    ,mSegmentId INT  
    ,SpecTypeTagId INT  
    ,SegmentStatusTypeId INT  
    ,IsParentSegmentStatusActive BIT  
    ,mSectionId INT  
    ,SectionId INT  
 )  
  
 DECLARE @DistinctSectionTbl TABLE (SectionId INT)
 INSERT INTO @SegmentMappingTbl  
  SELECT  
   *   
  FROM OPENJSON(@segmentMappingDataJson)  
  WITH (  
  mSegmentStatusId INT '$.mSegmentStatusId',  
  mSegmentId INT '$.mSegmentId',  
  SpecTypeTagId INT '$.SpecTypeTagId',  
  SegmentStatusTypeId INT '$.SegmentStatusTypeId',  
  IsParentSegmentStatusActive BIT '$.IsParentSegmentStatusActive',  
  mSectionId INT '$.mSectionId',  
  SectionId INT '$.SectionId'  
  
  );  

  INSERT INTO @DistinctSectionTbl
  SELECT DISTINCT SectionId FROM @SegmentMappingTbl

 DECLARE @SegmentChoiceMappingTbl TABLE (  
  mSegmentStatusId INT  
    ,mSegmentId INT  
    ,mSectionId INT  
    ,SegmentChoiceCode INT  
    ,ChoiceOptionCode INT  
    ,IsSelected BIT  
    ,SectionId INT  
 )  
  
 INSERT INTO @SegmentChoiceMappingTbl  
  SELECT  
   *  
  FROM OPENJSON(@segmentChoiceMappingDataJson)  
  WITH (  
  mSegmentStatusId INT '$.mSegmentStatusId',  
  mSegmentId INT '$.mSegmentId',  
  mSectionId INT '$.mSectionId',  
  SegmentChoiceCode INT '$.SegmentChoiceCode',  
  ChoiceOptionCode INT '$.ChoiceOptionCode',  
  IsSelected BIT '$.IsSelected',  
  SectionId INT '$.SectionId'  
  );  
  
 DECLARE @SegmentRowCount INT = (SELECT  
   COUNT(mSegmentStatusId)  
  FROM @SegmentMappingTbl)  
  
 SELECT  
  *  
 FROM @SegmentMappingTbl  
  
 IF (@SegmentRowCount > 0)  
 BEGIN  
  
  UPDATE pss  
  SET pss.SpecTypeTagId = smtbl.SpecTypeTagId  
     ,pss.SegmentStatusTypeId = smtbl.SegmentStatusTypeId  
     ,pss.IsParentSegmentStatusActive = smtbl.IsParentSegmentStatusActive  
  FROM ProjectSegmentStatus pss WITH (NOLOCK)  
  INNER JOIN @SegmentMappingTbl smtbl  
   ON smtbl.SectionId = pss.SectionId  
   AND smtbl.mSegmentId = pss.mSegmentId  
   AND smtbl.mSegmentStatusId = pss.mSegmentStatusId  
  WHERE pss.ProjectId = @ProjectId  
  AND pss.CustomerId = @CustomerId  
  
  
  
 END  

  UPDATE IPR  
 SET IPR.StatusId = @InCompleteStatus  
    ,IPR.CompletedPercentage = @CompletePer90 
	,IPR.IsNotify=0
 FROM ImportProjectRequest IPR  with (nolock)
 INNER JOIN @DistinctSectionTbl SM  
  ON IPR.TargetSectionId = SM.SectionId  
  
 DECLARE @ChoiceTableRowCount INT = (SELECT  
   COUNT(mSegmentStatusId)  
  FROM @SegmentChoiceMappingTbl)  
  
 IF (@ChoiceTableRowCount > 0)  
 BEGIN  
  
  UPDATE sco  
  SET sco.IsSelected = scmtbl.IsSelected  
  FROM SelectedChoiceOption sco WITH (NOLOCK)  
  INNER JOIN @SegmentChoiceMappingTbl scmtbl  
   ON scmtbl.SegmentChoiceCode = sco.SegmentChoiceCode  
   AND scmtbl.ChoiceOptionCode = sco.ChoiceOptionCode  
   AND sco.SectionId = scmtbl.SectionId  
  WHERE sco.ProjectId = @ProjectId  
  AND sco.CustomerId = @CustomerId  
  AND sco.ChoiceOptionSource = 'M'  
 END  
  
  
 UPDATE IPR  
 SET IPR.StatusId = @CompleteStatus  
    ,IPR.CompletedPercentage = @CompletePer  
	,IPR.IsNotify=0
 FROM ImportProjectRequest IPR   with (nolock)
 INNER JOIN @DistinctSectionTbl SM  
  ON IPR.TargetSectionId = SM.SectionId  
  
END
GO
Print '33. [usp_SetProjectSegemntMappingData]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_SpecDataActivateDeactivateMappedSegment]
(
   @SegmentStatusJson NVARCHAR(max)
)
AS
BEGIN


DECLARE @TempMappingtable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,SectionId INT
   ,SegmentStatusId INT
   ,ActionTypeId INT
   ,RowId INT
)

INSERT INTO @TempMappingtable
	SELECT
		*
	   ,ROW_NUMBER() OVER (ORDER BY SegmentStatusId ASC) AS RowId
	FROM OPENJSON(@SegmentStatusJson)
	WITH (
	ProjectId INT '$.ProjectId',
	CustomerId INT '$.CustomerId',
	SectionId INT '$.SectionId',
	SegmentStatusId INT '$.SegmentStatusId',
	ActionTypeId INT '$.ActionTypeId'
	);

DECLARE @RowCount INT = (SELECT
		COUNT(SectionId)
	FROM @TempMappingtable);
DECLARE @n INT = 1;

DECLARE @SegmentTempTable TABLE (
	SegmentStatusId INT
   ,SectionId INT
   ,ParentSegmentStatusId INT
   ,mSegmentStatusId INT
   ,mSegmentId INT
   ,IndentLevel INT
   ,ProjectId INT
   ,SegmentId INT
   ,CustomerId INT
)

DECLARE @SegmentStatusId INT = 0;
DECLARE @SectionId INT = 0;
DECLARE @ProjectId INT = 0;
DECLARE @ActionTypeId INT = 0;

WHILE (@RowCount >= @n)
BEGIN

DELETE FROM @SegmentTempTable

SET @SegmentStatusId = 0;
SET @SectionId = 0;
SET @ProjectId = 0;
SET @ActionTypeId = 0;

SELECT
	@SegmentStatusId = pss.SegmentStatusId
   ,@SectionId = pss.SectionId
   ,@ProjectId = pss.ProjectId
   ,@ActionTypeId = TMTBL.ActionTypeId
FROM @TempMappingtable TMTBL
INNER JOIN ProjectSegmentStatus pss WITH (NOLOCK)
	ON pss.mSegmentStatusId = TMTBL.SegmentStatusId
		AND pss.ProjectId = TMTBL.ProjectId
		AND pss.CustomerId = TMTBL.CustomerId
WHERE RowId = @n

PRINT @ActionTypeId

IF (@ActionTypeId <> 2)

BEGIN
;
WITH cte
AS
(SELECT
		a.SegmentStatusId
	   ,a.SectionId
	   ,a.ParentSegmentStatusId
	   ,a.mSegmentStatusId
	   ,a.mSegmentId
	   ,a.IndentLevel
	   ,a.ProjectId
	   ,a.SegmentId
	   ,a.CustomerId

	FROM ProjectSegmentStatus a WITH (NOLOCK)
	WHERE a.SegmentStatusId = @SegmentStatusId
	AND ISNULL(a.IsDeleted, 0) = 0
	UNION ALL
	SELECT
		s.SegmentStatusId
	   ,s.SectionId
	   ,s.ParentSegmentStatusId
	   ,s.mSegmentStatusId
	   ,s.mSegmentId
	   ,s.IndentLevel
	   ,s.ProjectId
	   ,s.SegmentId
	   ,c.CustomerId

	FROM ProjectSegmentStatus s WITH (NOLOCK)
	JOIN cte c
		ON s.SegmentStatusId = c.ParentSegmentStatusId
		AND ISNULL(s.IsDeleted, 0) = 0
		--AND s.IndentLevel > 0
		--AND c.IndentLevel > 0
		)

INSERT INTO @SegmentTempTable (SegmentStatusId
, SectionId
, ParentSegmentStatusId
, mSegmentStatusId
, mSegmentId
, IndentLevel
, ProjectId
, SegmentId
, CustomerId)
	SELECT
		ss.SegmentStatusId
	   ,ss.SectionId
	   ,ss.ParentSegmentStatusId
	   ,ss.mSegmentStatusId
	   ,ss.mSegmentId
	   ,ss.IndentLevel
	   ,ss.ProjectId
	   ,ss.SegmentId
	   ,ss.CustomerId

	FROM ProjectSegmentStatus ss WITH (NOLOCK)
	WHERE ss.SegmentStatusId = @SegmentStatusId
	UNION
	SELECT
		C.SegmentStatusId
	   ,C.SectionId
	   ,C.ParentSegmentStatusId
	   ,C.mSegmentStatusId
	   ,C.mSegmentId
	   ,C.IndentLevel
	   ,C.ProjectId
	   ,C.SegmentId
	   ,C.CustomerId
	FROM cte C


UPDATE pss
SET pss.IsParentSegmentStatusActive = 1
   ,SegmentStatusTypeId = 2
   ,SpecTypeTagId = 2
FROM ProjectSegmentStatus pss WITH (NOLOCK)
INNER JOIN @SegmentTempTable STT
	ON STT.SegmentStatusId = pss.SegmentStatusId
	AND ISNULL(pss.IsDeleted, 0) = 0

END
ELSE
BEGIN

UPDATE pss
SET pss.IsParentSegmentStatusActive = 0
   ,SegmentStatusTypeId = 6
   ,SpecTypeTagId = NULL
FROM ProjectSegmentStatus pss WITH (NOLOCK)
WHERE pss.SegmentStatusId = @SegmentStatusId
AND ISNULL(pss.IsDeleted, 0) = 0
END

SET @n = @n + 1;
	END
	 
END
GO
Print '34. [usp_SpecDataActivateDeactivateMappedSegment]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_SpecDataCreateSegments]
(
@ProjectId int,
@CustomerId int,
@UserId Int,
@MasterSectionIdJson NVARCHAR(max)
)
as
begin

DECLARE  @InputDataTable TABLE(
RowId int,
    SectionId INT  
);

IF @MasterSectionIdJson != ''
BEGIN
INSERT INTO @InputDataTable
	SELECT
		ROW_NUMBER() OVER (ORDER BY SectionId ASC) AS RowId
	   ,SectionId
	FROM OPENJSON(@MasterSectionIdJson)
	WITH (
	SectionId INT '$.SectionId'
	);
END

DECLARE @InputDataTablerowCount INT = (SELECT
				COUNT(SectionId)
			FROM @InputDataTable)
	   ,@n INT = 1;

WHILE (@InputDataTablerowCount >= @n)
BEGIN

DECLARE @SectionId INT = (SELECT TOP 1
		ps.SectionId
	FROM ProjectSection PS WITH (NOLOCK)
	INNER JOIN @InputDataTable IDTBL
		ON IDTBL.SectionId = PS.mSectionId
		AND PS.ProjectId = @ProjectId
		AND PS.CustomerId = @CustomerId
		AND isnull(PS.IsDeleted,0)=0
	WHERE RowId = @n)

EXECUTE usp_MapSegmentStatusFromMasterToProject @ProjectId
											   ,@SectionId
											   ,@CustomerId
											   ,@UserId

EXECUTE usp_MapSegmentChoiceFromMasterToProject @ProjectId
											   ,@SectionId
											   ,@CustomerId
											   ,@UserId
EXECUTE usp_MapProjectRefStands @ProjectId
							   ,@SectionId
							   ,@CustomerId
							   ,@UserId

EXECUTE usp_MapSegmentRequirementTagFromMasterToProject @ProjectId
													   ,@SectionId
													   ,@CustomerId
													   ,@UserId

EXECUTE usp_MapSegmentLinkFromMasterToProject @ProjectId
											 ,@SectionId
											 ,@CustomerId
											 ,@UserId

EXECUTE usp_UpdateSegmentStatus_ApplyMasterUpdate @ProjectId
												 ,@CustomerId
												 ,@SectionId

EXECUTE usp_DeleteSegmentRequirementTag_ApplyMasterUpdate @ProjectId
														 ,@CustomerId
														 ,@SectionId

SET @n = @n + 1;
END
END
GO
Print '35. [usp_SpecDataCreateSegments]'
Go
 
CREATE OR ALTER PROCEDURE [dbo].[usp_SpecDataGetLinkedProjectSegmentDetails]
(
   @SegmentStatusJson NVARCHAR(max)
)
AS
BEGIN


DECLARE @TempMappingtable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,SectionId INT
   ,SegmentStatusId INT
   ,RowId INT
)

INSERT INTO @TempMappingtable
	SELECT
		*
	   ,ROW_NUMBER() OVER (ORDER BY SegmentStatusId ASC) AS RowId
	FROM OPENJSON(@SegmentStatusJson)
	WITH (
	ProjectId INT '$.ProjectId',
	CustomerId INT '$.CustomerId',
	SectionId INT '$.SectionId',
	SegmentStatusId INT '$.SegmentStatusId'
	);

DECLARE @SegmentTempTable TABLE (
	SegmentStatusId INT
   ,SectionId INT
   ,ParentSegmentStatusId INT
   ,mSegmentStatusId INT
   ,mSegmentId INT
   ,IndentLevel INT
   ,ProjectId INT
   ,SegmentId INT
   ,CustomerId INT

)
DECLARE @SegmentStatusId INT = 0;
DECLARE @SectionId INT = 0;
DECLARE @ProjectId INT = 0;

DECLARE @RowCount INT = (SELECT
		COUNT(SectionId)
	FROM @TempMappingtable);
DECLARE @n INT = 1;

WHILE (@RowCount >= @n)
BEGIN

SET @SegmentStatusId = 0;
SET @SectionId = 0;
SET @ProjectId = 0;;

SELECT
	@SegmentStatusId = pss.SegmentStatusId
   ,@SectionId = pss.SectionId
   ,@ProjectId = pss.ProjectId
FROM @TempMappingtable TMTBL
INNER JOIN ProjectSegmentStatus pss WITH (NOLOCK)
	ON pss.mSegmentStatusId = TMTBL.SegmentStatusId
		AND pss.ProjectId = TMTBL.ProjectId
		AND pss.CustomerId = TMTBL.CustomerId
WHERE RowId = @n
;
WITH cte
AS
(SELECT
		a.SegmentStatusId
	   ,a.SectionId
	   ,a.ParentSegmentStatusId
	   ,a.mSegmentStatusId
	   ,a.mSegmentId
	   ,a.IndentLevel
	   ,a.ProjectId
	   ,a.SegmentId
	   ,a.CustomerId

	FROM ProjectSegmentStatus a WITH (NOLOCK)
	WHERE a.SegmentStatusId = @SegmentStatusId
	AND ISNULL(a.IsDeleted, 0) = 0
	UNION ALL
	SELECT
		s.SegmentStatusId
	   ,s.SectionId
	   ,s.ParentSegmentStatusId
	   ,s.mSegmentStatusId
	   ,s.mSegmentId
	   ,s.IndentLevel
	   ,s.ProjectId
	   ,s.SegmentId
	   ,c.CustomerId
	FROM ProjectSegmentStatus s WITH (NOLOCK)
	JOIN cte c
		ON s.SegmentStatusId = c.ParentSegmentStatusId
		AND ISNULL(s.IsDeleted, 0) = 0
		AND s.IndentLevel > 0
		AND c.IndentLevel > 0)

INSERT INTO @SegmentTempTable (SegmentStatusId
, SectionId
, ParentSegmentStatusId
, mSegmentStatusId
, mSegmentId
, IndentLevel
, ProjectId
, SegmentId
, CustomerId)
	SELECT
		ss.SegmentStatusId
	   ,ss.SectionId
	   ,ss.ParentSegmentStatusId
	   ,ss.mSegmentStatusId
	   ,ss.mSegmentId
	   ,ss.IndentLevel
	   ,ss.ProjectId
	   ,ss.SegmentId
	   ,ss.CustomerId

	FROM ProjectSegmentStatus ss WITH (NOLOCK)
	WHERE ss.SegmentStatusId = @SegmentStatusId
	UNION
	SELECT
		C.SegmentStatusId
	   ,C.SectionId
	   ,C.ParentSegmentStatusId
	   ,C.mSegmentStatusId
	   ,C.mSegmentId
	   ,C.IndentLevel
	   ,C.ProjectId
	   ,C.SegmentId
	   ,C.CustomerId
	FROM cte C

SET @n = @n + 1;
	END

SELECT
	STBL.ProjectId
   ,STBL.CustomerId
   ,STBL.SectionId
   ,PS.SectionCode
   ,PSS.SegmentStatusCode
   ,PSS.SegmentSource
   ,STBL.SegmentStatusId
   ,PSS.IndentLevel
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
	ON PS.SectionId = PSS.SectionId
		AND PS.ProjectId = PSS.ProjectId
		AND ISNULL(PS.IsDeleted, 0) = 0
INNER JOIN @SegmentTempTable STBL
	ON PSS.SegmentStatusId = STBL.SegmentStatusId
		AND ISNULL(PSS.IsDeleted, 0) = 0

UNION
SELECT DISTINCT
	PSS.ProjectId
   ,PSS.CustomerId
   ,PS.SectionId
   ,PS.SectionCode
   ,PSS.SegmentStatusCode
   ,PSS.SegmentSource
   ,PSS.SegmentStatusId
   ,PSS.IndentLevel
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
	ON PS.SectionId = PSS.SectionId
		AND PS.ProjectId = PSS.ProjectId
		AND ISNULL(PS.IsDeleted, 0) = 0
INNER JOIN @SegmentTempTable STBL
	ON PSS.SectionId = STBL.SectionId
		AND PSS.ProjectId = STBL.ProjectId
		AND ISNULL(PSS.IsDeleted, 0) = 0
		AND PSS.IndentLevel = 0
END
GO
Print '36. [usp_SpecDataGetLinkedProjectSegmentDetails]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_SpecDataSetSegmentChoiceOption]
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
	);

DECLARE @SingleSelectionChoiceTable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,SectionId INT
   ,SegmentChoiceId INT
   ,ChoiceOptionId INT
   ,SegmentStatusId INT
)

INSERT INTO @SingleSelectionChoiceTable (ProjectId, CustomerId, SectionId, SegmentChoiceId, ChoiceOptionId, SegmentStatusId)
	SELECT DISTINCT
		TMT.ProjectId
	   ,TMT.CustomerId
	   ,TMT.SectionId
	   ,TMT.SegmentChoiceId
	   ,TMT.ChoiceOptionId
	   ,TMT.SegmentStatusId
	FROM SLCMaster..SegmentChoice slcmsc WITH (NOLOCK)
	INNER JOIN @TempMappingtable TMT
		ON TMT.SegmentChoiceId = slcmsc.SegmentChoiceCode
			AND slcmsc.ChoiceTypeId = 1
			AND slcmsc.SegmentStatusId = TMT.SegmentStatusId 

DECLARE @SingleSelectionFinalChoiceTable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,SectionId INT
   ,SegmentChoiceId INT
   ,ChoiceOptionId INT
   ,SegmentStatusId INT
)

INSERT INTO @SingleSelectionFinalChoiceTable
	SELECT
		ProjectId
	   ,CustomerId
	   ,SectionId
	   ,SegmentChoiceId
	   ,ChoiceOptionId
	   ,SegmentStatusId
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
)

INSERT INTO @MultipleSelectionChoiceTable (ProjectId, CustomerId, SectionId, SegmentChoiceId, ChoiceOptionId, SegmentStatusId)
	SELECT DISTINCT
		TMT.ProjectId
	   ,TMT.CustomerId
	   ,TMT.SectionId
	   ,TMT.SegmentChoiceId
	   ,TMT.ChoiceOptionId
	   ,TMT.SegmentStatusId
	FROM SLCMaster..SegmentChoice slcmsc WITH (NOLOCK) 
	INNER JOIN @TempMappingtable TMT
		ON TMT.SegmentChoiceId = slcmsc.SegmentChoiceCode
			AND slcmsc.ChoiceTypeId <> 1
			AND slcmsc.SegmentStatusId = TMT.SegmentStatusId 

UPDATE SCO
SET SCO.IsSelected = 0
FROM SelectedChoiceOption SCO WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
	ON SCO.SectionId = PS.SectionId
	AND PS.ProjectId = SCO.ProjectId
	AND PS.CustomerId = SCO.CustomerId
INNER JOIN @TempMappingtable TMTBL
	ON SCO.SegmentChoiceCode = TMTBL.SegmentChoiceId
	AND SCO.ProjectId = TMTBL.ProjectId
	AND SCO.CustomerId = TMTBL.CustomerId


IF ((SELECT
			COUNT(SegmentStatusId)
		FROM @SingleSelectionChoiceTable)
	> 0)
BEGIN

UPDATE SCO
SET SCO.IsSelected = 1
FROM SelectedChoiceOption SCO WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
	ON SCO.SectionId = PS.SectionId
	AND PS.ProjectId = SCO.ProjectId
	AND PS.CustomerId = SCO.CustomerId
INNER JOIN @SingleSelectionFinalChoiceTable TMTBL
	ON SCO.SegmentChoiceCode = TMTBL.SegmentChoiceId
	AND SCO.ChoiceOptionCode = TMTBL.ChoiceOptionId
	AND SCO.ProjectId = TMTBL.ProjectId
    AND SCO.CustomerId = TMTBL.CustomerId
 

END

IF ((SELECT
			COUNT(SegmentStatusId)
		FROM @MultipleSelectionChoiceTable)
	> 0)
BEGIN
UPDATE SCO
SET SCO.IsSelected = 1
FROM SelectedChoiceOption SCO WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
	ON SCO.SectionId = PS.SectionId
	AND PS.ProjectId = SCO.ProjectId
	AND PS.CustomerId = SCO.CustomerId
INNER JOIN @MultipleSelectionChoiceTable TMTBL
	ON SCO.SegmentChoiceCode = TMTBL.SegmentChoiceId
	AND SCO.ChoiceOptionCode = TMTBL.ChoiceOptionId
	AND SCO.ProjectId = TMTBL.ProjectId
	AND SCO.CustomerId = TMTBL.CustomerId
 
END

END
GO
Print '37. [usp_SpecDataSetSegmentChoiceOption]'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_UpdateProjectSummaryInfo]       
(       
@SummaryInfoType INT,       
@SummaryInfoDetail NVARCHAR(MAX)       
)       
AS       
BEGIN       
      
DECLARE @PSummaryInfoType INT = @SummaryInfoType       
DECLARE @PSummaryInfoDetail NVARCHAR(MAX) = @SummaryInfoDetail       
      
CREATE TABLE #SummaryInfoTbl(       
CustomerId INT,       
ProjectId INT,       
ProjectName NVARCHAR(MAX),       
ActiveSectionsCount INT,       
TotalSectionsCount INT,       
SpecViewModeId INT,       
TrackChangesModeId TINYINT,
IsMigratedProject BIT,       
CountryId INT,       
StateProvinceId INT,       
StateProvinceName nvarchar(50),       
CityId INT,       
CityName nvarchar(50),       
ProjectTypeId INT,       
FacilityTypeId INT,       
ProjectSize INT,       
ProjectCost INT,       
ProjectSizeUOM INT,       
IsPrintReferenceEditionDate BIT,       
IsIncludeRsInSection BIT,       
IsIncludeReInSection BIT,       
IsActivateRsCitation BIT,       
SourceTagFormat NVARCHAR(MAX),       
UnitOfMeasureValueTypeId INT,       
IsNamewithHeld BIT,       
IsProjectNameExist BIT,       
IsProjectNameModified BIT,      
ProjectGlobalTermId NVARCHAR(MAX),       
IsProjectGTIdModified BIT,    
ProjectAccessTypeId INT,    
OwnerId INT    
);       
      
    
INSERT INTO #SummaryInfoTbl       
SELECT TOP 1       
*       
FROM OPENJSON(@PSummaryInfoDetail)       
WITH (       
CustomerId INT '$.CustomerId',       
ProjectId INT '$.ProjectId',       
      
ProjectName NVARCHAR(MAX) '$.ProjectName',       
ActiveSectionsCount INT '$.ActiveSectionsCount',       
TotalSectionsCount INT '$.TotalSectionsCount',       
SpecViewModeId INT '$.SpecViewModeId',   
TrackChangesModeId TINYINT '$.TrackChangesModeId',
IsMigratedProject BIT '$.IsMigratedProject',       
      
CountryId INT '$.CountryId',       
StateProvinceId INT '$.StateProvinceId',       
StateProvinceName NVARCHAR(50) '$.StateProvinceName',       
CityId INT '$.CityId',       
CityName NVARCHAR(50) '$.CityName',       
ProjectTypeId INT '$.ProjectTypeId',       
FacilityTypeId INT '$.FacilityTypeId',       
ProjectSize INT '$.ProjectSize',       
ProjectCost INT '$.ProjectCost',       
ProjectSizeUOM INT '$.ProjectSizeUOM',       
      
IsPrintReferenceEditionDate BIT '$.IsPrintReferenceEditionDate',       
IsIncludeRsInSection BIT '$.IsIncludeRsInSection',       
IsIncludeReInSection BIT '$.IsIncludeReInSection',       
IsActivateRsCitation BIT '$.IsActivateRsCitation',       
      
SourceTagFormat NVARCHAR(MAX) '$.SourceTagFormat',       
UnitOfMeasureValueTypeId INT '$.UnitOfMeasureValueTypeId',       
IsNamewithHeld BIT '$.IsNamewithHeld',       
IsProjectNameExist BIT '$.IsProjectNameExist',       
IsProjectNameModified BIT '$.IsProjectNameModified',       
ProjectGlobalTermId NVARCHAR(MAX) '$.GlobalTermProjectIdValue',      
IsProjectGTIdModified BIT '$.IsGTProjectIdValueModified'   ,    
ProjectAccessTypeId INT '$.ProjectAccessTypeId',    
OwnerId INT '$.OwnerId'    
);       
      
    
-- @PSummaryInfoType IS FOLLOWING       
DECLARE @ProjectInfo INT = 1;       
DECLARE @ProjectDetails INT = 2;       
DECLARE @ProjectHistory INT = 3;       
DECLARE @References INT = 4;       
DECLARE @SectionID INT = 5;       
DECLARE @UnitOfMeasure INT = 6;       
DECLARE @Permissions INT = 7;       
DECLARE @ProjectAccessTypeAndOwner INT=9;    
      
--DECLARE @IsNameAlreadyExist BIT = 0;       
      
IF @PSummaryInfoType = @ProjectInfo       
BEGIN      
UPDATE PS       
SET PS.SpecViewModeId = PST.SpecViewModeId, 
	PS.TrackChangesModeId = PST.TrackChangesModeId 
FROM ProjectSummary PS WITH (NOLOCK)
INNER JOIN #SummaryInfoTbl PST
ON PS.ProjectId = PST.ProjectId
      
DECLARE @ProjectCount INT = 0;       
DECLARE @CustomerId INT = 0;       
DECLARE @ProjectId INT = 0;       
DECLARE @ProjectName NVARCHAR(MAX) = '';       
      
DECLARE @IsModified BIT = 0;       
DECLARE @IsProjectGTIdModified BIT=0;      
DECLARE @ProjectGtId NVARCHAR(MAX) ='';       
      
SELECT       
@CustomerId = SIT.CustomerId       
,@ProjectName = SIT.ProjectName       
,@ProjectId = SIT.ProjectId       
,@IsModified = SIT.IsProjectNameModified       
,@IsProjectGTIdModified =SIT.IsProjectGTIdModified      
,@ProjectGtId =SIT.ProjectGlobalTermId      
FROM #SummaryInfoTbl SIT       
      
IF @IsModified = 1 -- Update only if modifed       
BEGIN       
SELECT       
@ProjectCount = COUNT([Name])       
FROM Project  WITH (NOLOCK)  
WHERE (CustomerId = @CustomerId       
AND ProjectId != @ProjectId       
AND [Name] = @ProjectName)       
AND ISNULL(IsPermanentDeleted,0)=0       
      
IF @ProjectCount > 0 -- Project Name Already Exist       
BEGIN       
UPDATE #SummaryInfoTbl       
SET IsProjectNameExist = 1;       
END       
ELSE -- Update new name for project       
BEGIN       
UPDATE P       
SET P.[Name] = @ProjectName       
,P.[Description] = @ProjectName    
FROM Project P WITH (NOLOCK)  
WHERE P.ProjectId = @ProjectId       
      
UPDATE PGT       
SET PGT.[Value] = @ProjectName   
FROM ProjectGlobalTerm PGT WITH (NOLOCK)  
WHERE PGT.ProjectId = @ProjectId       
AND PGT.[Name] = 'Project Name';       
      
UPDATE #SummaryInfoTbl       
SET IsProjectNameExist = 0       
,IsProjectNameModified = 0;       
END       
END       
IF @IsProjectGTIdModified =1      
BEGIN       
UPDATE PGT       
SET [Value] = @ProjectGtId   
FROM ProjectGlobalTerm PGT WITH (NOLOCK)  
WHERE PGT.ProjectId = @ProjectId       
AND PGT.CustomerId=@CustomerId      
AND PGT.[Name] = 'Project ID';       
END       
      
END      
      
IF @PSummaryInfoType = @ProjectDetails       
BEGIN       
UPDATE PS       
SET PS.ProjectTypeId = PST.ProjectTypeId       
,PS.FacilityTypeId = PST.FacilityTypeId       
,PS.ActualSizeId = PST.ProjectSize       
,PS.SizeUOM = PST.ProjectSizeUOM       
,PS.ActualCostId = PST.ProjectCost       
FROM ProjectSummary PS WITH (NOLOCK)       
INNER JOIN #SummaryInfoTbl PST       
ON PS.ProjectId = PST.ProjectId       
      
UPDATE PA       
SET PA.CountryId = PST.CountryId       
,PA.StateProvinceId =       
CASE       
WHEN PST.StateProvinceId = 0 THEN NULL       
ELSE PST.StateProvinceId       
END       
,PA.CityId =       
CASE       
WHEN PST.CityId = 0 THEN NULL       
ELSE PST.CityId       
END       
,PA.StateProvinceName =       
CASE       
WHEN COALESCE(PST.StateProvinceName, '') = '' OR       
PST.StateProvinceId != 0 THEN NULL       
ELSE PST.StateProvinceName       
END       
,PA.CityName =       
CASE       
WHEN COALESCE(PST.CityName, '') = '' OR       
PST.CityId != 0 THEN NULL       
ELSE PST.CityName       
END       
FROM ProjectAddress PA WITH (NOLOCK)       
INNER JOIN #SummaryInfoTbl PST       
ON PA.ProjectId = PST.ProjectId       
      
END       
      
--IF @PSummaryInfoType=@ProjectHistory       
--BEGIN       
-- SELECT * FROM #SummaryInfoTbl       
--END       
      
IF @PSummaryInfoType = @References       
BEGIN       
UPDATE PS       
SET PS.IsIncludeRsInSection = PST.IsIncludeRsInSection       
,PS.IsIncludeReInSection = PST.IsIncludeReInSection       
,PS.IsPrintReferenceEditionDate = PST.IsPrintReferenceEditionDate       
,PS.IsActivateRsCitation = PST.IsActivateRsCitation       
FROM ProjectSummary PS WITH (NOLOCK)       
INNER JOIN #SummaryInfoTbl PST       
ON PS.ProjectId = PST.ProjectId       
END       
      
IF @PSummaryInfoType = @SectionID       
BEGIN       
UPDATE PS       
SET PS.SourceTagFormat = PST.SourceTagFormat       
FROM ProjectSummary PS WITH (NOLOCK)       
INNER JOIN #SummaryInfoTbl PST       
ON PS.ProjectId = PST.ProjectId       
END       
      
IF @PSummaryInfoType = @UnitOfMeasure       
BEGIN       
UPDATE PS       
SET PS.UnitOfMeasureValueTypeId = PST.UnitOfMeasureValueTypeId       
FROM ProjectSummary PS WITH (NOLOCK)       
INNER JOIN #SummaryInfoTbl PST       
ON PS.ProjectId = PST.ProjectId       
END       
      
IF @PSummaryInfoType = @Permissions       
BEGIN       
UPDATE P       
SET P.IsNameWithHeld = PST.IsNameWithHeld       
FROM Project P WITH (NOLOCK)       
INNER JOIN #SummaryInfoTbl PST       
ON P.ProjectId = PST.ProjectId       
END       
      
DECLARE @SummaryInfoGTValueTbl TABLE (       
CustomerId INT       
,ProjectId INT       
,CityName NVARCHAR(MAX)       
,StateProvinceName NVARCHAR(MAX)       
)       
      
INSERT INTO @SummaryInfoGTValueTbl     
SELECT TOP 1       
*       
FROM OPENJSON(@PSummaryInfoDetail)       
WITH (       
CustomerId INT '$.CustomerId',       
ProjectId INT '$.ProjectId',       
CityName NVARCHAR(MAX) '$.CityName',       
StateProvinceName NVARCHAR(MAX) '$.StateProvinceName'       
)       
      
UPDATE PGT       
SET value = GTTBL.StateProvinceName       
FROM ProjectGlobalTerm PGT WITH (NOLOCK)       
INNER JOIN @SummaryInfoGTValueTbl GTTBL       
ON PGT.ProjectId = GTTBL.ProjectId       
AND PGT.CustomerId = GTTBL.CustomerId       
WHERE PGT.Name = 'Project Location State'       
AND PGT.GlobalTermFieldTypeId = 3       
      
UPDATE PGT       
SET value = GTTBL.CityName       
FROM ProjectGlobalTerm PGT WITH (NOLOCK)       
INNER JOIN @SummaryInfoGTValueTbl GTTBL       
ON PGT.ProjectId = GTTBL.ProjectId       
AND PGT.CustomerId = GTTBL.CustomerId       
WHERE PGT.Name = 'Project Location City'       
AND PGT.GlobalTermFieldTypeId = 3       
      
UPDATE PGT       
SET value = GTTBL.StateProvinceName       
FROM ProjectGlobalTerm PGT WITH (NOLOCK)       
INNER JOIN @SummaryInfoGTValueTbl GTTBL       
ON PGT.ProjectId = GTTBL.ProjectId       
AND PGT.CustomerId = GTTBL.CustomerId       
WHERE PGT.Name = 'Project Location Province'       
AND PGT.GlobalTermFieldTypeId = 3       
      
     
IF @PSummaryInfoType = @ProjectAccessTypeAndOwner       
 BEGIN      
 UPDATE PS       
 SET PS.ProjectAccessTypeId = PST.ProjectAccessTypeId,    
 PS.OwnerId=PST.OwnerId       
 FROM ProjectSummary PS WITH (NOLOCK)       
 INNER JOIN #SummaryInfoTbl PST       
 ON PS.ProjectId = PST.ProjectId     
END     
    
SELECT       
*       
FROM #SummaryInfoTbl       
      
END  
GO
Print '38. [usp_UpdateProjectSummaryInfo]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_ValidateSection]       
(        
@CustomerId INT,        
@SourceProjectId INT,        
@SourceTagString NVARCHAR(MAX)=NULL,        
@TargetProjectId INT,        
@mSectionIdString  NVARCHAR(MAX)=NULL,        
@SectionIdString  NVARCHAR(MAX)=NULL,        
@IncludeReferencedSections BIT = 1        
)        
AS        
BEGIN
    
DECLARE @PCustomerId INT = @CustomerId;
    
DECLARE @PSourceProjectId INT = @SourceProjectId;
    
DECLARE @PSourceTagString NVARCHAR(MAX) = @SourceTagString;
    
DECLARE @PTargetProjectId INT = @TargetProjectId;
    
DECLARE @PmSectionIdString  NVARCHAR(MAX) = @mSectionIdString;
    
DECLARE @PSectionIdString  NVARCHAR(MAX) = @SectionIdString;
    
DECLARE @PIncludeReferencedSections BIT = @IncludeReferencedSections;
    
        
DECLARE @SectionIdTbl TABLE(Id INT);
    
DECLARE @mSectionIdTbl TABLE(Id INT);
    
DECLARE @SourceTagTbl TABLE(Id nvarchar(MAX));
    
DECLARE @InpSectionId INT = NULL;

DROP TABLE IF EXISTS #tmp_SrcProjectSegmentStatus;
DROP TABLE IF EXISTS #tmp_SrcProjectChoiceOption;
DROP TABLE IF EXISTS #tmp_SrcProjectSection;

INSERT INTO @SectionIdTbl
	SELECT
		id
	FROM dbo.udf_GetSplittedIds(@PSectionIdString, ',')

INSERT INTO @mSectionIdTbl
	SELECT
		id
	FROM dbo.udf_GetSplittedIds(@PmSectionIdString, ',')

INSERT INTO @SourceTagTbl (id)
	SELECT
		*
	FROM dbo.fn_SplitString(@PSourceTagString, ',')

SELECT
	PS.SectionId
   ,PS.ParentSectionId
   ,PS.mSectionId
   ,PS.ProjectId
   ,PS.DivisionId
   ,PS.DivisionCode
   ,PS.[Description]
   ,PS.LevelId
   ,PS.IsLastLevel
   ,PS.SourceTag
   ,PS.Author
   ,PS.SectionCode
   ,PS.IsDeleted
FROM ProjectSection PS WITH (NOLOCK)
INNER JOIN @mSectionIdTbl SI
	ON PS.mSectionId = SI.id
INNER JOIN @SourceTagTbl ST
	ON PS.SourceTag = ST.id
WHERE PS.ProjectId = @PTargetProjectId
AND PS.CustomerId = @PCustomerId
AND PS.IsDeleted = 0
AND PS.IsLastLevel = 1

DECLARE @ReferencedSection TABLE (
	mSectionId INT
   ,SectionId INT
   ,ParentSectionId INT
   ,ProjectId INT
   ,DivisionId INT
   ,DivisionCode NVARCHAR(MAX)
   ,[Description] NVARCHAR(MAX)
   ,LevelId INT
   ,IsLastLevel BIT
   ,SourceTag NVARCHAR(MAX)
   ,Author NVARCHAR(MAX)
   ,SectionCode INT
   ,IsDeleted BIT
   ,MainSectionId INT
   ,IsProcessed BIT
)

--Fetch Source Segment Status Data of sequence 0 and user segments    
SELECT
	PSST.SegmentStatusId
   ,PSST.SectionId
   ,PSST.ParentSegmentStatusId
   ,PSST.mSegmentStatusId
   ,PSST.mSegmentId
   ,PSST.SegmentId
   ,PSST.SegmentSource
   ,PSST.SegmentOrigin
   ,PSST.IndentLevel
   ,PSST.SequenceNumber
   ,PSST.SpecTypeTagId
   ,PSST.SegmentStatusTypeId
   ,PSST.IsParentSegmentStatusActive
   ,PSST.ProjectId
   ,PSST.CustomerId
   ,PSST.SegmentStatusCode
   ,PSST.IsShowAutoNumber
   ,PSST.IsRefStdParagraph
   ,PSST.FormattingJson
   ,PSST.CreateDate
   ,PSST.CreatedBy
   ,PSST.ModifiedDate
   ,PSST.ModifiedBy
   ,PSST.IsPageBreak
   ,PSST.IsDeleted
   ,PSST.TrackOriginOrder
   ,PSST.MTrackDescription INTO #tmp_SrcProjectSegmentStatus
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
WHERE PSST.ProjectId = @PSourceProjectId
AND PSST.CustomerId = @PCustomerId
AND PSST.ParentSegmentStatusId = 0
AND PSST.SequenceNumber = 0
AND PSST.IndentLevel = 0
AND PSST.SegmentOrigin = 'U'
AND ISNULL(PSST.IsDeleted, 0) = 0;

--Fetch Source user choice options    
SELECT
	PCHOP.ChoiceOptionId
   ,PCHOP.SegmentChoiceId
   ,PCHOP.SortOrder
   ,PCHOP.ChoiceOptionSource
   ,PCHOP.OptionJson
   ,PCHOP.ProjectId
   ,PCHOP.SectionId
   ,PCHOP.CustomerId
   ,PCHOP.ChoiceOptionCode
   ,PCHOP.CreatedBy
   ,PCHOP.CreateDate
   ,PCHOP.ModifiedBy
   ,PCHOP.ModifiedDate
   ,PCHOP.IsDeleted INTO #tmp_SrcProjectChoiceOption
FROM ProjectChoiceOption PCHOP WITH (NOLOCK)
INNER JOIN ProjectSegmentChoice PSC WITH (NOLOCK)
	ON PSC.SegmentChoiceId = PCHOP.SegmentChoiceId
WHERE ISNULL(PSC.IsDeleted, 0) = 0
AND PCHOP.ProjectId = @PSourceProjectId
AND PCHOP.CustomerId = @PCustomerId
AND ISNULL(PCHOP.IsDeleted, 0) = 0
AND PCHOP.OptionJson != '[]';

--Fetch Source user sections    
SELECT
	PS.* INTO #tmp_SrcProjectSection
FROM ProjectSection PS WITH (NOLOCK)
WHERE PS.ProjectId = @PSourceProjectId
AND PS.CustomerId = @PCustomerId
AND PS.IsLastLevel = 1
AND PS.IsDeleted = 0
AND PS.mSectionId IS NULL;

INSERT INTO @ReferencedSection
	SELECT
		PS.mSectionId
	   ,PS.SectionId
	   ,PS.ParentSectionId
	   ,PS.ProjectId
	   ,PS.DivisionId
	   ,PS.DivisionCode
	   ,PS.[Description]
	   ,PS.LevelId
	   ,PS.IsLastLevel
	   ,PS.SourceTag
	   ,PS.Author
	   ,PS.SectionCode
	   ,PS.IsDeleted
	   ,X.MainSectionId AS MainSectionId
	   ,0 AS IsProcessed
	FROM (SELECT
			PST.id AS MainSectionId
		   ,JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.Id') AS ReferSectionId
		   ,JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.Value') AS SectionName
		FROM #tmp_SrcProjectChoiceOption CH WITH (NOLOCK)
		INNER JOIN @SectionIdTbl PST
			ON CH.SectionId = PST.id
		WHERE CH.ProjectId = @PSourceProjectId
		AND CH.CustomerId = @PCustomerId
		AND JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.OptionTypeName') = 'SectionID'
		AND JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.Id') > 0) AS X
	INNER JOIN #tmp_SrcProjectSection PS WITH (NOLOCK)
		ON X.ReferSectionId = PS.SectionCode
	INNER JOIN #tmp_SrcProjectSegmentStatus PSS WITH (NOLOCK)
		ON PS.SectionId = PSS.SectionId
	WHERE PS.ProjectId = @PSourceProjectId
	AND PS.CustomerId = @PCustomerId
--OPTION (RECOMPILE)    

SET @InpSectionId = ISNULL((SELECT TOP 1
		SectionId
	FROM @ReferencedSection
	WHERE IsProcessed IS NULL
	OR IsProcessed = 0)
, 0);
    
        
WHILE(@InpSectionId > 0)        
BEGIN
UPDATE @ReferencedSection
SET IsProcessed = 1
WHERE SectionId = @InpSectionId;

INSERT INTO @ReferencedSection
	SELECT
		PS.mSectionId
	   ,PS.SectionId
	   ,PS.ParentSectionId
	   ,PS.ProjectId
	   ,PS.DivisionId
	   ,PS.DivisionCode
	   ,PS.[Description]
	   ,PS.LevelId
	   ,PS.IsLastLevel
	   ,PS.SourceTag
	   ,PS.Author
	   ,PS.SectionCode
	   ,PS.IsDeleted
	   ,X.MainSectionId AS MainSectionId
	   ,0 AS IsProcessed
	FROM (SELECT
			@InpSectionId AS MainSectionId
		   ,JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.Id') AS ReferSectionId
		   ,JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.Value') AS SectionName
		FROM #tmp_SrcProjectChoiceOption CH WITH (NOLOCK)
		WHERE CH.ProjectId = @PSourceProjectId
		AND CH.CustomerId = @PCustomerId
		AND CH.SectionId = @InpSectionId
		AND JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.OptionTypeName') = 'SectionID'
		AND JSON_VALUE(LEFT(RIGHT(CH.OptionJson, LEN(CH.OptionJson) - 1), LEN(CH.OptionJson) - 2), '$.Id') > 0) AS X
	INNER JOIN #tmp_SrcProjectSection PS WITH (NOLOCK)
		ON X.ReferSectionId = PS.SectionCode
	INNER JOIN #tmp_SrcProjectSegmentStatus PSS WITH (NOLOCK)
		ON PS.SectionId = PSS.SectionId
	LEFT JOIN @ReferencedSection RSINPTBL
		ON PS.SectionId = RSINPTBL.SectionId
	WHERE PS.ProjectId = @PSourceProjectId
	AND PS.CustomerId = @PCustomerId
	AND RSINPTBL.SectionId IS NULL
--OPTION (RECOMPILE)    

SET @InpSectionId = ISNULL((SELECT TOP 1
		SectionId
	FROM @ReferencedSection
	WHERE IsProcessed IS NULL
	OR IsProcessed = 0)
, 0);
    
END

SELECT
	DISTINCT 
	RS.mSectionId 
   ,RS.SectionId
   ,RS.ParentSectionId
   ,RS.ProjectId
   ,RS.DivisionId 
   ,RS.DivisionCode
   ,RS.[Description]
   ,RS.LevelId
   ,RS.IsLastLevel
   ,RS.SourceTag
   ,RS.Author
   ,RS.SectionCode
   ,RS.IsDeleted
   ,0 AS MainSectionId
   ,RS.IsProcessed
FROM @ReferencedSection RS
LEFT JOIN ProjectSection PS WITH (NOLOCK)
	ON RS.SourceTag = PS.SourceTag
		AND PS.ProjectId = @PTargetProjectId
AND PS.SectionId IS NULL;
END
GO
Print '39. [usp_ValidateSection]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_ActiveMigratedProject]     
(  
 @CustomerId INT,    
 @ProjectId INT,  
 @UserId INT,  
 @ModifiedByFullName NVARCHAR(100)  
)  
AS          
BEGIN  
    
Update P Set IsShowMigrationPopup=0    
from Project P WITH (NOLOCK)  
Where P.ProjectId = @ProjectId    
AND P.CustomerId=@CustomerId    
  
Update UF  
SET UF.LastAccessByFullName =  @ModifiedByFullName,  
 UF.UserId = @UserId,  
 UF.LastAccessed = GETUTCDATE()  
FROM UserFolder UF WITH (NOLOCK)  
Where UF.ProjectId = @ProjectId  
  
END
GO
Print '40. [usp_ActiveMigratedProject]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_ArchivedProjectsList]
(          
 @CustomerId INT,
 @UserId INT=0,
 @IsSystemManager BIT=0,          
 @IsOfficeMaster INT=0,          
 @PageNumber INT=1,          
 @PageSize INT=20,          
 @SearchText NVARCHAR(1024)=''          
)          
AS          
BEGIN     
	DECLARE @TRUE BIT=1,@FALSE BIT=0
	SELECT       
	 CONVERT(BIGINT, P.ProjectId) AS ArchiveProjectId,      
	 P.[Name] AS ProjectName,      
	 0 AS SLC_ArchiveProjectId,      
	 P.ProjectId AS SLC_ProdProjectId,      
	 ISNULL(UF.UserId,0) AS SLC_UserId,      
	 P.CustomerId AS SlcCustomerId,      
	 ISNULL(UF.LastAccessed,'') AS ArchivedDate,      
	 ISNULL(UF.LastAccessByFullName,'') AS ModifiedByFullName,      
	 
	 ISNULL(PS.ProjectAccessTypeId,1) AS ProjectAccessTypeId,
	 @FALSE AS IsProjectAccessible,
	 CONVERT(NVARCHAR(100),'') AS ProjectAccessTypeName,
	 IIF(PS.OwnerId=@UserId,@TRUE,@FALSE) as IsProjectOwner 
	  
	 INTO #T FROM Project P WITH(NOLOCK)      
	 LEFT JOIN UserFolder UF WITH(NOLOCK) ON UF.ProjectId = P.ProjectId      
	 LEFT JOIN ProjectSummary PS WITH(NOLOCK) ON PS.ProjectId = P.ProjectId      
	 WHERE P.CustomerId = @CustomerId      
	 AND ISNULL(P.IsDeleted,0) = 0      
	 AND ISNULL(P.IsArchived,0) = 1      
	 AND ISNULL(P.IsPermanentDeleted,0) = 0      
	 AND ISNULL(p.IsOfficeMaster,0)=@IsOfficeMaster    
	 
 IF(@IsSystemManager=@TRUE)   
 BEGIN 
	      
	UPDATE t   
	set t.ProjectAccessTypeName=pt.Name,
		t.IsProjectAccessible=@TRUE  
	from #T t inner join LuProjectAccessType pt  WITH (NOLOCK)              
	on t.ProjectAccessTypeId=pt.ProjectAccessTypeId  
    
	SELECT * FROM #T ORDER by ArchivedDate desc  
 END
 ELSE
 BEGIN
	CREATE TABLE #AccessibleProjectIds(     
	   Projectid INT,     
	   ProjectAccessTypeId INT,     
	   IsProjectAccessible bit,     
	   --ProjectAccessTypeName NVARCHAR(100)  ,   
	   IsProjectOwner BIT   
	);
	
	---Get all public,private and owned projects   
	INSERT INTO #AccessibleProjectIds(Projectid  ,ProjectAccessTypeId,  IsProjectAccessible,IsProjectOwner)                            
	SELECT ps.Projectid,ps.ProjectAccessTypeId,0,iif(ps.OwnerId=@UserId,1,0) 
	FROM #t t inner join ProjectSummary ps WITH(NOLOCK)    
	ON t.ArchiveProjectId=ps.ProjectId      
	where  (ps.ProjectAccessTypeId in(1,2) or ps.OwnerId=@UserId)   
	AND ps.CustomerId=@CustomerId  
	
	--Update all public Projects as accessible   
	UPDATE t   
	set t.IsProjectAccessible=1   
	from #AccessibleProjectIds t    
	where t.ProjectAccessTypeId=1        
	    
	--Update all private Projects if they are accessible   
	UPDATE t set t.IsProjectAccessible=1   
	from #AccessibleProjectIds t    
	inner join UserProjectAccessMapping u WITH(NOLOCK)   
	ON t.Projectid=u.ProjectId         
	where u.IsActive=1    
	and u.UserId=@UserId and t.ProjectAccessTypeId=2   
	AND u.CustomerId=@CustomerId     
	
	--Get all accessible projects   
	INSERT INTO #AccessibleProjectIds  (Projectid  ,ProjectAccessTypeId,  IsProjectAccessible,IsProjectOwner)                            
	SELECT ps.Projectid,ps.ProjectAccessTypeId,1,iif(ps.OwnerId=@UserId,1,0) 
	FROM #t res inner join ProjectSummary ps WITH(NOLOCK)  
	ON res.ArchiveProjectId=ps.ProjectId
	INNER JOIN UserProjectAccessMapping upam WITH(NOLOCK)   
	ON upam.ProjectId=ps.ProjectId 
	LEFT outer JOIN #AccessibleProjectIds t   
	ON t.Projectid=ps.ProjectId   
	where ps.ProjectAccessTypeId=3 AND upam.UserId=@UserId and t.Projectid is null AND ps.CustomerId=@CustomerId   
	AND(upam.IsActive=1 OR ps.OwnerId=@UserId)      
 
	UPDATE t   
	set t.IsProjectAccessible=t.IsProjectOwner   
	from #AccessibleProjectIds t    
	where t.IsProjectOwner=1         
	
	UPDATE t   
	set t.ProjectAccessTypeName=pt.Name
	from #T t inner join LuProjectAccessType pt  WITH (NOLOCK)              
	on t.ProjectAccessTypeId=pt.ProjectAccessTypeId

	UPDATE res   
	set res.IsProjectAccessible=t.IsProjectAccessible	
	from #T res INNER JOIN #AccessibleProjectIds t    
	ON res.ArchiveProjectId=t.ProjectId

	SELECT res.* from #T res 
	INNER JOIN #AccessibleProjectIds t    
	ON res.ArchiveProjectId=t.ProjectId
	ORDER by res.ArchivedDate desc      
	 
 END
END 
GO
Print '41. [usp_ArchivedProjectsList]'
Go

CREATE OR ALTER PROCEDURE usp_ArchiveMigratedProject  
(  
 @CustomerId INT,  
 @IsOfficeMaster BIT=0,  
 @ArchiveProjectId INT,  
 @UserId INT,  
 @ModifiedByFullName NVARCHAR(50)=''  
)  
AS  
BEGIN  
  
 UPDATE P  
 SET P.IsArchived=1  
 FROM Project P WITH(NOLOCK)  
 WHERE P.ProjectId=@ArchiveProjectId  
  
 UPDATE UF  
 SET UF.UserId=@UserId,  
  UF.LastAccessed=GETUTCDATE(),  
  LastAccessByFullName=@ModifiedByFullName  
 FROM UserFolder UF WITH(NOLOCK)  
 WHERE UF.ProjectId=@ArchiveProjectId  
END
GO
Print '42. usp_ArchiveMigratedProject'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_ArchiveProject]             
@UserId INT,            
@ProjectId INT,            
@CustomerId INT,            
@UserName nvarchar(500),          
@IsArchived BIT          
AS            
BEGIN      
            
DECLARE @PUserId INT = @UserId      
DECLARE @PProjectId INT = @ProjectId      
DECLARE @PCustomerId INT = @CustomerId      
DECLARE @PUserName nvarchar(500) =  @UserName      
DECLARE @PIsArchived BIT = @IsArchived      
DECLARE @IsSuccess BIT = 1    
DECLARE @ErrorMessageÇode  INT;    
      
 IF EXISTS (SELECT TOP 1    
  1    
 FROM [ProjectSection] WITH (NOLOCK)    
 WHERE ProjectId = @PProjectId    
 AND IsLastLevel = 1    
 AND IsLocked = 1    
 AND LockedBy != @UserId    
 AND CustomerId = @CustomerId)    
BEGIN    
SET @IsSuccess = 0    
SET @ErrorMessageÇode = 1    
SELECT    
 @IsSuccess AS IsSuccess    
   ,@ErrorMessageÇode AS ErrorCode    
END    
ELSE    
BEGIN    
    
UPDATE P      
SET P.IsArchived = @PIsArchived      
   ,P.ModifiedBy = @PUserId      
   ,P.ModifiedByFullName = @PUserName      
   ,P.ModifiedDate = GETUTCDATE()      
FROM Project P WITH (NOLOCK)      
WHERE P.ProjectId = @PProjectId      
AND P.CustomerId = @PCustomerId      
      
UPDATE UF      
SET UF.LastAccessed = GETUTCDATE()      
   ,UF.LastAccessByFullName = @PUserName      
FROM UserFolder UF WITH (NOLOCK)      
WHERE UF.ProjectId = @PProjectId      
AND UF.CustomerId = @PCustomerId      
    
SET @IsSuccess = 1    
SET @ErrorMessageÇode = 0    
SELECT    
 @IsSuccess AS IsSuccess    
   ,@ErrorMessageÇode AS ErrorCode      
END    
END  
GO
Print '43. [usp_ArchiveProject]'
Go

CREATE OR ALTER PROCEDURE [usp_CreateSectionFromMasterTemplate_Job] 
 @RequestId INT              
AS  
BEGIN
	DECLARE @PProjectId INT;
	DECLARE @PCustomerId INT;
	DECLARE @PUserId INT;
	DECLARE @PUserName NVARCHAR(MAX);

	--DECLARE VARIABLES
	DECLARE @TemplateMasterSectionId INT = 0;
	DECLARE @TemplateSectionCode INT = 0;
	DECLARE @TargetSectionCode INT = 0;

	DECLARE @TemplateSectionId INT = 0;
	DECLARE @TargetSectionId INT = 0;
               
	DECLARE @IsTemplateMasterSectionOpened BIT = 0;
        
	DECLARE @IsCompleted BIT =1;        
	DECLARE @ImportStart_Description NVARCHAR(100) = 'Import Started';  
	DECLARE @ImportNoMasterTemplateFound_Description NVARCHAR(100)='No Master Template Found';              
	DECLARE @ImportSectionAlreadyExists_Description NVARCHAR(100)='Section Already Exists';              
	DECLARE @ImportSectionIdInvalid_Description NVARCHAR(100)='SectionId is Invalid';              
	DECLARE @NoAccessRights_Description NVARCHAR(100)='You dont have access rights to import section';              
	DECLARE @ImportProjectSection_Description NVARCHAR(100) = 'Import Project Section Imported';               
	DECLARE @ImportProjectSegment_Description NVARCHAR(100) = 'Project Segment Imported';
	DECLARE @ImportProjectSegmentStatus_Description NVARCHAR(100) = 'Project Segment Status Imported';  
	DECLARE @ImportProjectSegmentChoice_Description NVARCHAR(100)='Project Segment Choice Imported';              
	DECLARE @ImportProjectChoiceOption_Description NVARCHAR(100) = 'Project Choice Option Imported';          
	DECLARE @ImportSelectedChoiceOption_Description NVARCHAR(100) = 'Selected Choice Option Imported';               
	DECLARE @ImportProjectDisciplineSection_Description NVARCHAR(100) = 'Project Discipline Section Imported';               
	DECLARE @ImportProjectNote_Description NVARCHAR(100) = 'Project Note Imported';            
	DECLARE @ImportProjectSegmentLink_Description NVARCHAR(100) = 'Project Segment Link Imported';               
	DECLARE @ImportProjectSegmentRequirementTag_Description NVARCHAR(100) = 'Project SegmentRequirement Tag';              
	DECLARE @ImportProjectSegmentUserTag_Description NVARCHAR(100) = 'Project Segment User Tag Imported';
	DECLARE @ImportProjectSegmentGlobalTerm_Description NVARCHAR(100) = 'Project Segment Global Term Imported';  
	DECLARE @ImportProjectSegmentImage_Description NVARCHAR(100) = 'Project Segment Image Imported';
	DECLARE @ImportProjectHyperLink_Description NVARCHAR(100) = 'Project HyperLink Imported';
	DECLARE @ImportProjectNoteImage_Description NVARCHAR(100) = 'Project Note Image Imported';              
	DECLARE @ImportProjectSegmentReferenceStandard_Description NVARCHAR(100) = 'Project Segment Reference Standard Imported';               
	DECLARE @ImportHeader_Description NVARCHAR(100) = 'Header Imported';    
	DECLARE @ImportFooter_Description NVARCHAR(100) = 'Footer Imported';        
	DECLARE @ImportProjectReferenceStandard_Description NVARCHAR(100) = 'Project Reference Standard Imported';               
	DECLARE @ImportComplete_Description NVARCHAR(100) = 'Import Completed';  
	DECLARE @ImportFailed_Description NVARCHAR(100) = 'IMPORT FAILED'; 
              

	DECLARE @ImportStart_Percentage TINYINT = 5; 
	DECLARE @ImportProjectSection_Percentage TINYINT = 10;               
	DECLARE @ImportProjectSegment_Percentage TINYINT = 15;
	DECLARE @ImportProjectSegmentStatus_Percentage TINYINT = 20;
	DECLARE @ImportProjectSegmentChoice_Percentage TINYINT = 25;              
	DECLARE @ImportProjectChoiceOption_Percentage TINYINT = 30;         
	DECLARE @ImportSelectedChoiceOption_Percentage TINYINT = 35;               
	DECLARE @ImportProjectDisciplineSection_Percentage TINYINT = 40;               
	DECLARE @ImportProjectNote_Percentage TINYINT = 45;              
	DECLARE @ImportProjectSegmentLink_Percentage TINYINT = 50;              
	DECLARE @ImportProjectSegmentRequirementTag_Percentage TINYINT = 55;              
	DECLARE @ImportProjectSegmentUserTag_Percentage TINYINT = 60;              
	DECLARE @ImportProjectSegmentGlobalTerm_Percentage TINYINT = 65;  
	DECLARE @ImportProjectSegmentImage_Percentage TINYINT = 70;
	DECLARE @ImportProjectHyperLink_Percentage TINYINT = 75;              
	DECLARE @ImportProjectNoteImage_Percentage TINYINT = 80;              
	DECLARE @ImportProjectSegmentReferenceStandard_Percentage TINYINT = 85;               
	DECLARE @ImportHeader_Percentage TINYINT = 90;
	DECLARE @ImportFooter_Percentage TINYINT = 95;               
	DECLARE @ImportProjectReferenceStandard_Percentage TINYINT = 97;              
	DECLARE @ImportNoMasterTemplateFound_Percentage TINYINT = 100;  
	DECLARE @ImportSectionAlreadyExists_Percentage TINYINT = 100;  
	DECLARE @ImportSectionidInvalid_Percentage TINYINT = 100;              
	DECLARE @NoAccessRights_Percentage TINYINT = 100;
	DECLARE @ImportComplete_Percentage TINYINT = 100;  
	DECLARE @ImportFailed_Percentage TINYINT = 100;
    
	DECLARE @ImportStart_Step TINYINT = 1;  
	DECLARE @ImportNoMasterTemplateFound_Step TINYINT = 2; 
	DECLARE @ImportSectionAlreadyExists_Step TINYINT = 3;
	DECLARE @ImportSectionIdInvalid_Step TINYINT = 4;
	DECLARE @NoAccessRights_Step TINYINT = 5;              
	DECLARE @ImportProjectSection_Step TINYINT = 6;              
	DECLARE @ImportProjectSegment_Step TINYINT = 7;  
	DECLARE @ImportProjectSegmentChoice_Step TINYINT = 8;
	DECLARE @ImportProjectChoiceOption_Step TINYINT = 9;
	DECLARE @ImportSelectedChoiceOption_Step TINYINT = 10;
	DECLARE @ImportProjectDisciplineSection_Step TINYINT = 11;               
	DECLARE @ImportProjectNote_Step TINYINT = 12;              
	DECLARE @ImportProjectSegmentLink_Step TINYINT = 13;              
	DECLARE @ImportProjectSegmentRequirementTag_Step TINYINT = 14;              
	DECLARE @ImportProjectSegmentUserTag_Step TINYINT = 15;              
	DECLARE @ImportProjectSegmentGlobalTerm_Step TINYINT = 16;               
	DECLARE @ImportProjectSegmentImage_Step TINYINT = 17;              
	DECLARE @ImportProjectHyperLink_Step TINYINT = 18;              
	DECLARE @ImportProjectNoteImage_Step TINYINT = 19;              
	DECLARE @ImportProjectSegmentReferenceStandard_Step TINYINT = 20;              
	DECLARE @ImportHeader_Step TINYINT = 21;              
	DECLARE @ImportFooter_Step TINYINT = 22;              
	DECLARE @ImportProjectReferenceStandard_Step TINYINT = 23;             
	DECLARE @ImportProjectSegmentStatus_Step TINYINT = 24;               
	DECLARE @ImportComplete_Step TINYINT = 25; 
	DECLARE @ImportFailed_Step TINYINT = 25;             
        
	DECLARE @ImportPending TINYINT =1;        
	DECLARE @ImportStarted TINYINT =2;        
	DECLARE @ImportCompleted TINYINT =3;        
	DECLARE @Importfailed TINYINT =4    
	DECLARE @ImportSource nvarchar(1)=''     
	--TEMP TABLES
	DROP TABLE IF EXISTS #tmp_SrcProjectSegmentStatus;
	DROP TABLE IF EXISTS #tmp_TgtProjectSegmentStatus;
	DROP TABLE IF EXISTS #tmp_SrcMasterNote;
	DROP TABLE IF EXISTS #tmp_TgtProjectNote;
	DROP TABLE IF EXISTS #tmp_SrcProjectSegment;

BEGIN TRY
--BEGIN TRANSACTION               
	
	SELECT top 1 
	@TemplateSectionId=SourceSectionId,
	@TargetSectionId=TargetSectionId,
	@PProjectId=SourceProjectId,
	@PCustomerId=CustomerId,
	@PUserId=CreatedById
	from ImportProjectRequest with(NOLOCK)
	where RequestId=@RequestId

	SELECT top 1
	@TargetSectionCode=SectionCode
	from ProjectSection WITH(NOLOCK)
	where SectionId=@TargetSectionId
	and ProjectId=@PProjectId

	SELECT top 1
	@TemplateSectionCode=SectionCode,
	@TemplateMasterSectionId=mSectionId
	from ProjectSection WITH(NOLOCK)
	where SectionId=@TemplateSectionId
	and ProjectId=@PProjectId

--CHECK WHETHER MASTER TEMPLATE SECTION IS OPENED OR NOT
IF EXISTS (SELECT TOP 1
  1
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN ProjectSection PS WITH (NOLOCK)
  ON PSST.SectionId = PS.SectionId        
  AND PSST.ProjectId = PS.ProjectId          
 WHERE PSST.ProjectId = @PProjectId
 AND PS.mSectionId = @TemplateMasterSectionId
 --AND PS.CustomerId = @CustomerId  
 AND PSST.SequenceNumber = 0
 AND PSST.IndentLevel = 0)
BEGIN
SET @IsTemplateMasterSectionOpened = 1;
END


--CALCULATE DIVISION ID AND CODE
EXEC usp_SetDivisionIdForUserSection @PProjectId
         ,@TargetSectionId
         ,@PCustomerId;

--Fetch Src ProjectSegmentStatus data into temp table
SELECT
 * INTO #tmp_SrcProjectSegmentStatus
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
WHERE PSST.ProjectId = @PProjectId
AND PSST.SectionId = @TemplateSectionId

--Fetch Src ProjectSegment data into temp table
SELECT
 * INTO #tmp_SrcProjectSegment
FROM ProjectSegment PSG WITH (NOLOCK)
WHERE PSG.ProjectId = @PProjectId
AND PSG.SectionId = @TemplateSectionId

--INSERT INTO ProjectSegment
INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId,
SegmentDescription, SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)
 SELECT
  NULL AS SegmentStatusId
    ,@TargetSectionId AS SectionId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,MSG_Template.SegmentDescription AS SegmentDescription
    ,'U' AS SegmentSource
    ,MSG_Template.SegmentCode AS SegmentCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM SLCMaster..SegmentStatus MSST_Template WITH (NOLOCK)
 INNER JOIN SLCMaster..Segment MSG_Template WITH (NOLOCK)
  ON MSST_Template.SegmentId = MSG_Template.SegmentId
 WHERE MSST_Template.SectionId = @TemplateMasterSectionId
 AND ISNULL(MSST_Template.IsDeleted, 0) = 0
 AND @IsTemplateMasterSectionOpened = 0
 UNION
 SELECT
  NULL AS SegmentStatusId
    ,@TargetSectionId AS SectionId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,(CASE
   WHEN PSST_Template_PSG.SegmentId IS NOT NULL THEN PSST_Template_PSG.SegmentDescription
   ELSE PSST_Template_MSG.SegmentDescription
  END) AS SegmentDescription
    ,'U' AS SegmentSource
    ,(CASE
   WHEN PSST_Template_PSG.SegmentId IS NOT NULL THEN PSST_Template_PSG.SegmentCode
   ELSE PSST_Template_MSG.SegmentCode
  END) AS SegmentCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
 LEFT JOIN #tmp_SrcProjectSegment PSST_Template_PSG WITH (NOLOCK)          
  ON PSST_Template.SegmentId = PSST_Template_PSG.SegmentId
   AND PSST_Template.SegmentOrigin = 'U'
 LEFT JOIN SLCMaster..Segment PSST_Template_MSG WITH (NOLOCK)
  ON PSST_Template.mSegmentId = PSST_Template_MSG.SegmentId
   AND PSST_Template.SegmentOrigin = 'M'
 WHERE PSST_Template.SectionId = @TemplateSectionId
 AND ISNULL(PSST_Template.IsDeleted, 0) = 0
 AND (PSST_Template_PSG.SegmentId IS NOT NULL
 OR PSST_Template_MSG.SegmentId IS NOT NULL)
 AND @IsTemplateMasterSectionOpened = 1
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
        ,@ImportProjectSegment_Description            
           ,@ImportProjectSegment_Description            
           ,@IsCompleted            
           ,@ImportProjectSegment_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted        
         ,@ImportProjectSegment_Percentage --Percent            
         , 0
    ,@ImportSource             
         , @RequestId;               

--INSERT INTO ProjectSegmentStatus
INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource,
SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId,
IsParentSegmentStatusActive, ProjectId, CustomerId, SegmentStatusCode, IsShowAutoNumber,
IsRefStdParagraph, FormattingJson, CreateDate, CreatedBy, ModifiedDate, ModifiedBy,
IsPageBreak, IsDeleted)
 SELECT
  @TargetSectionId AS SectionId
    ,0 AS ParentSegmentStatusId
    ,MSST_Template.SegmentStatusId AS mSegmentStatusId
    ,MSST_Template.SegmentId AS mSegmentId
    ,PSG.SegmentId AS SegmentId
    ,'U' AS SegmentSource
    ,'U' AS SegmentOrigin
    ,MSST_Template.IndentLevel AS IndentLevel
    ,MSST_Template.SequenceNumber AS SequenceNumber
    ,(CASE
   WHEN MSST_Template.SpecTypeTagId = 1 THEN 4
   WHEN MSST_Template.SpecTypeTagId = 2 THEN 3
   ELSE MSST_Template.SpecTypeTagId
  END) AS SpecTypeTagId
    ,MSST_Template.SegmentStatusTypeId AS SegmentStatusTypeId
    ,MSST_Template.IsParentSegmentStatusActive AS IsParentSegmentStatusActive
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,MSST_Template.SegmentStatusCode AS SegmentStatusCode
    ,MSST_Template.IsShowAutoNumber AS IsShowAutoNumber
    ,MSST_Template.IsRefStdParagraph AS IsRefStdParagraph
    ,MSST_Template.FormattingJson AS FormattingJson
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS ModifiedDate
    ,@PUserId AS ModifiedBy
    ,0 AS IsPageBreak
    ,MSST_Template.IsDeleted AS IsDeleted
 FROM SLCMaster..SegmentStatus MSST_Template WITH (NOLOCK)
 INNER JOIN SLCMaster..Segment MSG_Template WITH (NOLOCK)
  ON MSST_Template.SegmentId = MSG_Template.SegmentId
 INNER JOIN ProjectSegment PSG WITH (NOLOCK)
  ON MSG_Template.SegmentCode = PSG.SegmentCode
   AND PSG.SectionId = @TargetSectionId
 WHERE MSST_Template.SectionId = @TemplateMasterSectionId
 AND ISNULL(MSST_Template.IsDeleted, 0) = 0
 AND @IsTemplateMasterSectionOpened = 0
 UNION
 SELECT
  @TargetSectionId AS SectionId
    ,0 AS ParentSegmentStatusId
    ,PSST_Template.mSegmentStatusId AS mSegmentStatusId
    ,PSST_Template.mSegmentId AS mSegmentId
    ,PSG.SegmentId AS SegmentId
    ,'U' AS SegmentSource
    ,'U' AS SegmentOrigin
    ,PSST_Template.IndentLevel AS IndentLevel
    ,PSST_Template.SequenceNumber AS SequenceNumber
    ,(CASE
   WHEN PSST_Template.SpecTypeTagId = 1 THEN 4
   WHEN PSST_Template.SpecTypeTagId = 2 THEN 3
   ELSE PSST_Template.SpecTypeTagId
  END) AS SpecTypeTagId
    ,PSST_Template.SegmentStatusTypeId AS SegmentStatusTypeId
    ,PSST_Template.IsParentSegmentStatusActive AS IsParentSegmentStatusActive
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,PSST_Template.SegmentStatusCode AS SegmentStatusCode
    ,PSST_Template.IsShowAutoNumber AS IsShowAutoNumber
    ,PSST_Template.IsRefStdParagraph AS IsRefStdParagraph
    ,PSST_Template.FormattingJson AS FormattingJson
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS ModifiedDate
    ,@PUserId AS ModifiedBy
    ,0 AS IsPageBreak
    ,PSST_Template.IsDeleted AS IsDeleted
 FROM #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
 LEFT JOIN #tmp_SrcProjectSegment PSST_Template_PSG WITH (NOLOCK)
  ON PSST_Template.SegmentId = PSST_Template_PSG.SegmentId
   AND PSST_Template.SegmentOrigin = 'U'
 LEFT JOIN SLCMaster..Segment PSST_Template_MSG WITH (NOLOCK)
  ON PSST_Template.mSegmentId = PSST_Template_MSG.SegmentId
   AND PSST_Template.SegmentOrigin = 'M'
 INNER JOIN ProjectSegment PSG WITH (NOLOCK)
  ON (CASE
    WHEN PSST_Template_PSG.SegmentId IS NOT NULL THEN PSST_Template_PSG.SegmentCode
    ELSE PSST_Template_MSG.SegmentCode
   END) = PSG.SegmentCode
   AND PSG.SectionId = @TargetSectionId
 WHERE PSST_Template.SectionId = @TemplateSectionId
 AND ISNULL(PSST_Template.IsDeleted, 0) = 0
 AND (PSST_Template_PSG.SegmentId IS NOT NULL
 OR PSST_Template_MSG.SegmentId IS NOT NULL)
 AND @IsTemplateMasterSectionOpened = 1
              
              

--Insert target segment status into temp table of new section
SELECT
 * INTO #tmp_TgtProjectSegmentStatus
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
WHERE PSST.SectionId = @TargetSectionId

--UPDATE TEMP TABLE ProjectSegmentStatus
UPDATE PSST_Child
SET PSST_Child.ParentSegmentStatusId = PSST_Parent.SegmentStatusId
FROM #tmp_TgtProjectSegmentStatus PSST_Child WITH (NOLOCK)
INNER JOIN SLCMaster..SegmentStatus MSST_Template_Child WITH (NOLOCK)
 ON PSST_Child.SegmentStatusCode = MSST_Template_Child.SegmentStatusCode
INNER JOIN SLCMaster..SegmentStatus MSST_Template_Parent WITH (NOLOCK)
 ON MSST_Template_Child.ParentSegmentStatusId = MSST_Template_Parent.SegmentStatusId
INNER JOIN #tmp_TgtProjectSegmentStatus PSST_Parent WITH (NOLOCK)
 ON MSST_Template_Parent.SegmentStatusCode = PSST_Parent.SegmentStatusCode
WHERE PSST_Child.SectionId = @TargetSectionId
AND PSST_Parent.SectionId = @TargetSectionId
AND MSST_Template_Child.SectionId = @TemplateMasterSectionId
AND @IsTemplateMasterSectionOpened = 0

UPDATE PSST_Child
SET PSST_Child.ParentSegmentStatusId = PSST_Parent.SegmentStatusId
FROM #tmp_TgtProjectSegmentStatus PSST_Child WITH (NOLOCK)
INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template_Child WITH (NOLOCK)
 ON PSST_Child.SegmentStatusCode = PSST_Template_Child.SegmentStatusCode
 AND PSST_Template_Child.SectionId = @TemplateSectionId
INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template_Parent WITH (NOLOCK)
 ON PSST_Template_Child.ParentSegmentStatusId = PSST_Template_Parent.SegmentStatusId
 AND PSST_Template_Parent.SectionId = @TemplateSectionId
INNER JOIN #tmp_TgtProjectSegmentStatus PSST_Parent WITH (NOLOCK)
 ON PSST_Template_Parent.SegmentStatusCode = PSST_Parent.SegmentStatusCode
WHERE PSST_Child.SectionId = @TargetSectionId
AND PSST_Parent.SectionId = @TargetSectionId
AND @IsTemplateMasterSectionOpened = 1

--UPDATE IN ORIGINAL TABLE
UPDATE PSST
SET PSST.ParentSegmentStatusId = TMP.ParentSegmentStatusId
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN #tmp_TgtProjectSegmentStatus TMP WITH (NOLOCK)
 ON PSST.SegmentStatusId = TMP.SegmentStatusId
WHERE PSST.SectionId = @TargetSectionId

--UPDATE ProjectSegment
UPDATE PSG
SET PSG.SegmentStatusId = PSST.SegmentStatusId       
FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN ProjectSegment PSG WITH (NOLOCK)
 ON PSST.SegmentId = PSG.SegmentId
WHERE PSST.SectionId = @TargetSectionId

UPDATE PSG
SET PSG.SegmentDescription = PS.Description
FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN ProjectSegment PSG WITH (NOLOCK)
 ON PSST.SegmentId = PSG.SegmentId
INNER JOIN ProjectSection PS WITH (NOLOCK)
 ON PSST.SectionId = PS.SectionId
WHERE PSST.SectionId = @TargetSectionId
AND PSST.SequenceNumber = 0
AND PSST.IndentLevel = 0

--INSERT INTO ProjectSegmentChoice
INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId,
CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,PSST.SegmentId AS SegmentId
    ,MCH_Template.ChoiceTypeId AS ChoiceTypeId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,'U' AS SegmentChoiceSource
    ,MCH_Template.SegmentChoiceCode AS SegmentChoiceCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)
  ON PSST.mSegmentId = MCH_Template.SegmentId
 WHERE PSST.SectionId = @TargetSectionId
 AND @IsTemplateMasterSectionOpened = 0
 UNION
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,PSST.SegmentId AS SegmentId
    ,MCH_Template.ChoiceTypeId AS ChoiceTypeId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,'U' AS SegmentChoiceSource
    ,MCH_Template.SegmentChoiceCode AS SegmentChoiceCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PSST.SegmentStatusCode = PSST_Template.SegmentStatusCode
   AND PSST_Template.SectionId = @TemplateSectionId
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)
  ON PSST.mSegmentId = MCH_Template.SegmentId
 WHERE PSST.SectionId = @TargetSectionId
 AND PSST_Template.SegmentOrigin = 'M'
 AND @IsTemplateMasterSectionOpened = 1
 UNION
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,PSST.SegmentId AS SegmentId
    ,PCH_Template.ChoiceTypeId AS ChoiceTypeId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,'U' AS SegmentChoiceSource
    ,PCH_Template.SegmentChoiceCode AS SegmentChoiceCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PSST.SegmentStatusCode = PSST_Template.SegmentStatusCode
   AND PSST_Template.SectionId = @TemplateSectionId
 INNER JOIN ProjectSegmentChoice PCH_Template WITH (NOLOCK)
  ON PSST_Template.SegmentId = PCH_Template.SegmentId
 WHERE PSST.SectionId = @TargetSectionId
 AND PSST_Template.SegmentOrigin = 'U'
 AND @IsTemplateMasterSectionOpened = 1
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentChoice_Description            
           ,@ImportProjectSegmentChoice_Description            
           ,@IsCompleted            
           ,@ImportProjectSegmentChoice_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted         
         ,@ImportProjectSegmentChoice_Percentage --Percent            
         , 0
    ,@ImportSource           
         , @RequestId;               

--INSERT INTO ProjectChoiceOption
INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson,
ProjectId, SectionId, CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)
 SELECT
  PCH.SegmentChoiceId AS SegmentChoiceId      ,MCHOP_Template.SortOrder AS SortOrder
    ,'U' AS ChoiceOptionSource
    ,MCHOP_Template.OptionJson AS OptionJson
    ,@PProjectId AS ProjectId
    ,@TargetSectionId AS SectionId
    ,@PCustomerId AS CustomerId
    ,MCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)
  ON PSST.mSegmentId = MCH_Template.SegmentId
 INNER JOIN SLCMaster..ChoiceOption MCHOP_Template WITH (NOLOCK)
  ON MCH_Template.SegmentChoiceId = MCHOP_Template.SegmentChoiceId
 INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
  ON PSST.SegmentId = PCH.SegmentId
   AND MCH_Template.SegmentChoiceCode = PCH.SegmentChoiceCode
 WHERE PSST.SectionId = @TargetSectionId
 AND @IsTemplateMasterSectionOpened = 0
 UNION
 SELECT
  PCH.SegmentChoiceId AS SegmentChoiceId
    ,MCHOP_Template.SortOrder AS SortOrder
    ,'U' AS ChoiceOptionSource
    ,MCHOP_Template.OptionJson AS OptionJson
    ,@PProjectId AS ProjectId
    ,@TargetSectionId AS SectionId
    ,@PCustomerId AS CustomerId
    ,MCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PSST.SegmentStatusCode = PSST_Template.SegmentStatusCode
   AND PSST_Template.SectionId = @TemplateSectionId
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)
  ON PSST.mSegmentId = MCH_Template.SegmentId
 INNER JOIN SLCMaster..ChoiceOption MCHOP_Template WITH (NOLOCK)
  ON MCH_Template.SegmentChoiceId = MCHOP_Template.SegmentChoiceId
 INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
  ON PSST.SegmentId = PCH.SegmentId
   AND MCH_Template.SegmentChoiceCode = PCH.SegmentChoiceCode
 WHERE PSST.SectionId = @TargetSectionId
 AND PSST_Template.SegmentOrigin = 'M'
 AND @IsTemplateMasterSectionOpened = 1
 UNION
 SELECT
  PCH.SegmentChoiceId AS SegmentChoiceId
    ,PCHOP_Template.SortOrder AS SortOrder
    ,'U' AS ChoiceOptionSource
    ,PCHOP_Template.OptionJson AS OptionJson
    ,@PProjectId AS ProjectId
    ,@TargetSectionId AS SectionId
    ,@PCustomerId AS CustomerId
    ,PCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PSST.SegmentStatusCode = PSST_Template.SegmentStatusCode
   AND PSST_Template.SectionId = @TemplateSectionId
 INNER JOIN ProjectSegmentChoice PCH_Template WITH (NOLOCK)
  ON PSST_Template.SegmentId = PCH_Template.SegmentId
 INNER JOIN ProjectChoiceOption PCHOP_Template WITH (NOLOCK)
  ON PCH_Template.SegmentChoiceId = PCHOP_Template.SegmentChoiceId
 INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
  ON PSST.SegmentId = PCH.SegmentId
   AND PCH_Template.SegmentChoiceCode = PCH.SegmentChoiceCode
 WHERE PSST.SectionId = @TargetSectionId
 AND PSST_Template.SegmentOrigin = 'U'
 AND @IsTemplateMasterSectionOpened = 1
              
 EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectChoiceOption_Description            
           ,@ImportProjectChoiceOption_Description            
           ,@IsCompleted          
           ,@ImportProjectChoiceOption_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted       
         ,@ImportProjectChoiceOption_Percentage --Percent            
         , 0
    ,@ImportSource          
         , @RequestId;               

--INSERT INTO SelectedChoiceOption
INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource,
IsSelected, SectionId, ProjectId, CustomerId, OptionJson)
 SELECT
  MCH_Template.SegmentChoiceCode AS SegmentChoiceCode
    ,MCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode
    ,'U' AS ChoiceOptionSource
    ,SCHOP_Template.IsSelected AS IsSelected
    ,@TargetSectionId AS SectionId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,NULL AS OptionJson
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)
  ON PSST.mSegmentId = MCH_Template.SegmentId
 INNER JOIN SLCMaster..ChoiceOption MCHOP_Template WITH (NOLOCK)
  ON MCH_Template.SegmentChoiceId = MCHOP_Template.SegmentChoiceId
 INNER JOIN SLCMaster..SelectedChoiceOption SCHOP_Template WITH (NOLOCK)
  ON MCH_Template.SegmentChoiceCode = SCHOP_Template.SegmentChoiceCode
   AND MCHOP_Template.ChoiceOptionCode = SCHOP_Template.ChoiceOptionCode
 WHERE PSST.SectionId = @TargetSectionId
 AND @IsTemplateMasterSectionOpened = 0
 UNION
 SELECT
  MCH_Template.SegmentChoiceCode AS SegmentChoiceCode
    ,MCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode
    ,'U' AS ChoiceOptionSource
    ,SCHOP_Template.IsSelected AS IsSelected
    ,@TargetSectionId AS SectionId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,SCHOP_Template.OptionJson AS OptionJson
 FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PSST.SegmentStatusCode = PSST_Template.SegmentStatusCode
   AND PSST_Template.SectionId = @TemplateSectionId
 INNER JOIN SLCMaster..SegmentChoice MCH_Template WITH (NOLOCK)
  ON PSST.mSegmentId = MCH_Template.SegmentId
 INNER JOIN SLCMaster..ChoiceOption MCHOP_Template WITH (NOLOCK)
  ON MCH_Template.SegmentChoiceId = MCHOP_Template.SegmentChoiceId
 INNER JOIN SelectedChoiceOption SCHOP_Template WITH (NOLOCK)
  ON MCH_Template.SegmentChoiceCode = SCHOP_Template.SegmentChoiceCode
   AND MCHOP_Template.ChoiceOptionCode = SCHOP_Template.ChoiceOptionCode
   AND SCHOP_Template.ChoiceOptionSource = 'M'
   AND SCHOP_Template.SectionId = @TemplateSectionId
 WHERE PSST.SectionId = @TargetSectionId
 AND PSST_Template.SegmentOrigin = 'M'
 AND @IsTemplateMasterSectionOpened = 1
 UNION
 SELECT
  PCH_Template.SegmentChoiceCode AS SegmentChoiceCode
    ,PCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode
    ,'U' AS ChoiceOptionSource
    ,SCHOP_Template.IsSelected AS IsSelected
    ,@TargetSectionId AS SectionId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,SCHOP_Template.OptionJson AS OptionJson
 FROM #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
 INNER JOIN ProjectSegmentChoice PCH_Template WITH (NOLOCK)
  ON PSST_Template.SegmentId = PCH_Template.SegmentId
 INNER JOIN ProjectChoiceOption PCHOP_Template WITH (NOLOCK)
  ON PCH_Template.SegmentChoiceId = PCHOP_Template.SegmentChoiceId
 INNER JOIN SelectedChoiceOption SCHOP_Template WITH (NOLOCK)
  ON PCH_Template.SegmentChoiceCode = SCHOP_Template.SegmentChoiceCode
   AND PCHOP_Template.ChoiceOptionCode = SCHOP_Template.ChoiceOptionCode
   AND SCHOP_Template.ChoiceOptionSource = 'U'
   AND SCHOP_Template.SectionId = @TemplateSectionId
 WHERE PSST_Template.SectionId = @TemplateSectionId
 AND PSST_Template.SegmentOrigin = 'U'
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportSelectedChoiceOption_Description            
           ,@ImportSelectedChoiceOption_Description            
           ,@IsCompleted          
           ,@ImportSelectedChoiceOption_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null               
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted   
        ,@ImportSelectedChoiceOption_Percentage --Percent            
         , 0
    ,@ImportSource           
         , @RequestId;               

--INSERT INTO ProjectDisciplineSection
INSERT INTO ProjectDisciplineSection (SectionId, Disciplineld, ProjectId, CustomerId, IsActive)
 SELECT
  @TargetSectionId AS SectionId
    ,MDS.DisciplineId AS Disciplineld
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,1 AS IsActive
 FROM SLCMaster..DisciplineSection MDS WITH (NOLOCK)
 INNER JOIN LuProjectDiscipline LPD WITH (NOLOCK)
  ON MDS.DisciplineId = LPD.Disciplineld
 WHERE MDS.SectionId = @TemplateMasterSectionId
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectDisciplineSection_Description            
           ,@ImportProjectDisciplineSection_Description            
           ,@IsCompleted        
           ,@ImportProjectDisciplineSection_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted               
         ,@ImportProjectDisciplineSection_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               

--INSERT INTO ProjectNote
INSERT INTO ProjectNote (SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId,      
CustomerId, Title, CreatedBy, ModifiedBy, CreatedUserName, ModifiedUserName, IsDeleted, NoteCode)
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,MNT_Template.NoteText AS NoteText
    ,GETUTCDATE() AS CreateDate
    ,GETUTCDATE() AS ModifiedDate
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,'' AS Title
    ,@PUserId AS CreatedBy
    ,@PUserId AS ModifiedBy
  ,@PUserName AS CreatedUserName
    ,@PUserName AS ModifiedUserName
    ,0 AS IsDeleted
    ,MNT_Template.NoteId AS NoteCode
 FROM SLCMaster..Note MNT_Template WITH (NOLOCK)
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
  ON MNT_Template.SegmentStatusId = PSST.mSegmentStatusId
 WHERE MNT_Template.SectionId = @TemplateMasterSectionId
 AND PSST.SectionId = @TargetSectionId
 UNION
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,PNT_Template.NoteText AS NoteText
    ,GETUTCDATE() AS CreateDate
    ,GETUTCDATE() AS ModifiedDate
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,PNT_Template.Title AS Title
    ,@PUserId AS CreatedBy
    ,@PUserId AS ModifiedBy
    ,@PUserName AS CreatedUserName
    ,@PUserName AS ModifiedUserName
    ,0 AS IsDeleted
    ,PNT_Template.NoteCode AS NoteCode
 FROM ProjectNote PNT_Template WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PNT_Template.SegmentStatusId = PSST_Template.SegmentStatusId
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
  ON PSST_Template.SegmentStatusCode = PSST.SegmentStatusCode
   AND PSST.SectionId = @TargetSectionId
 WHERE PNT_Template.SectionId = @TemplateSectionId
 AND ISNULL(PNT_Template.IsDeleted, 0) = 0
 EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectNote_Description            
           ,@ImportProjectNote_Description            
           ,@IsCompleted           
           ,@ImportProjectNote_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted   
         ,@ImportProjectNote_Percentage --Percent            
         , 0
    ,@ImportSource         
         , @RequestId;               

              
--INSERT INTO ProjectSegmentLink
INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode,
SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource, TargetSectionCode,
TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode,
LinkTarget, LinkStatusTypeId, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate,
ProjectId, CustomerId, SegmentLinkSourceTypeId)
 SELECT
  (CASE
   WHEN MSLNK.SourceSectionCode = @TemplateSectionCode THEN @TargetSectionCode
   ELSE MSLNK.SourceSectionCode
  END) AS SourceSectionCode
    ,MSLNK.SourceSegmentStatusCode AS SourceSegmentStatusCode
    ,MSLNK.SourceSegmentCode AS SourceSegmentCode
    ,MSLNK.SourceSegmentChoiceCode AS SourceSegmentChoiceCode
    ,MSLNK.SourceChoiceOptionCode AS SourceChoiceOptionCode
    ,(CASE
   WHEN MSLNK.SourceSectionCode = @TemplateSectionCode THEN 'U'
   ELSE MSLNK.LinkSource
  END) AS LinkSource
    ,(CASE
   WHEN MSLNK.TargetSectionCode = @TemplateSectionCode THEN @TargetSectionCode
   ELSE MSLNK.TargetSectionCode
  END) AS TargetSectionCode
    ,MSLNK.TargetSegmentStatusCode AS TargetSegmentStatusCode
    ,MSLNK.TargetSegmentCode AS TargetSegmentCode
    ,MSLNK.TargetSegmentChoiceCode AS TargetSegmentChoiceCode
    ,MSLNK.TargetChoiceOptionCode AS TargetChoiceOptionCode
    ,(CASE
   WHEN MSLNK.TargetSectionCode = @TemplateSectionCode THEN 'U'
   ELSE MSLNK.LinkTarget
  END) AS LinkTarget
    ,MSLNK.LinkStatusTypeId AS LinkStatusTypeId
    ,MSLNK.IsDeleted AS IsDeleted
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS CreatedBy
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,(CASE
   WHEN MSLNK.SegmentLinkSourceTypeId = 1 THEN 5
   ELSE MSLNK.SegmentLinkSourceTypeId
  END) AS SegmentLinkSourceTypeId
 FROM SLCMaster..SegmentLink MSLNK WITH (NOLOCK)
 WHERE (MSLNK.SourceSectionCode = @TemplateSectionCode
 OR MSLNK.TargetSectionCode = @TemplateSectionCode)
 AND MSLNK.IsDeleted = 0
 AND @IsTemplateMasterSectionOpened = 0
               

SELECT
   (CASE
    WHEN PSLNK.SourceSectionCode = @TemplateSectionCode THEN @TargetSectionCode
    ELSE PSLNK.SourceSectionCode
   END) AS SourceSectionCode
     ,PSLNK.SourceSegmentStatusCode AS SourceSegmentStatusCode
     ,PSLNK.SourceSegmentCode AS SourceSegmentCode
     ,PSLNK.SourceSegmentChoiceCode AS SourceSegmentChoiceCode
     ,PSLNK.SourceChoiceOptionCode AS SourceChoiceOptionCode
     ,(CASE
    WHEN PSLNK.SourceSectionCode = @TemplateSectionCode THEN 'U'
    ELSE PSLNK.LinkSource
   END) AS LinkSource
     ,(CASE
    WHEN PSLNK.TargetSectionCode = @TemplateSectionCode THEN @TargetSectionCode
    ELSE PSLNK.TargetSectionCode
   END) AS TargetSectionCode
     ,PSLNK.TargetSegmentStatusCode AS TargetSegmentStatusCode
     ,PSLNK.TargetSegmentCode AS TargetSegmentCode
     ,PSLNK.TargetSegmentChoiceCode AS TargetSegmentChoiceCode
     ,PSLNK.TargetChoiceOptionCode AS TargetChoiceOptionCode
     ,(CASE
    WHEN PSLNK.TargetSectionCode = @TemplateSectionCode THEN 'U'
    ELSE PSLNK.LinkTarget
   END) AS LinkTarget
     ,PSLNK.LinkStatusTypeId AS LinkStatusTypeId
     ,PSLNK.IsDeleted AS IsDeleted
     ,GETUTCDATE() AS CreateDate
     ,@PUserId AS CreatedBy
     ,@PUserId AS ModifiedBy
     ,GETUTCDATE() AS ModifiedDate
     ,@PProjectId AS ProjectId
     ,@PCustomerId AS CustomerId
     ,(CASE
    WHEN PSLNK.SegmentLinkSourceTypeId = 1 THEN 5
    ELSE PSLNK.SegmentLinkSourceTypeId
   END) AS SegmentLinkSourceTypeId
  INTO #X FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
  WHERE PSLNK.ProjectId = @PProjectId
  AND PSLNK.CustomerId = @PCustomerId
  AND (PSLNK.SourceSectionCode = @TemplateSectionCode
  OR PSLNK.TargetSectionCode = @TemplateSectionCode)
  AND PSLNK.IsDeleted = 0
  AND @IsTemplateMasterSectionOpened = 1

INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode,
SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource, TargetSectionCode,
TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode,
LinkTarget, LinkStatusTypeId, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate,
ProjectId, CustomerId, SegmentLinkSourceTypeId)
 SELECT
  X.*
 FROM #x AS X
 LEFT JOIN ProjectSegmentLink PSLNK WITH (NOLOCK)
  ON X.SourceSectionCode = PSLNK.SourceSectionCode
   AND X.SourceSegmentStatusCode = PSLNK.SourceSegmentStatusCode
   AND X.SourceSegmentCode = PSLNK.SourceSegmentCode
   AND X.SourceSegmentChoiceCode = PSLNK.SourceSegmentChoiceCode
   AND X.SourceChoiceOptionCode = PSLNK.SourceChoiceOptionCode
   AND X.LinkSource = PSLNK.LinkSource
   AND X.TargetSectionCode = PSLNK.TargetSectionCode
   AND X.TargetSegmentStatusCode = PSLNK.TargetSegmentStatusCode
   AND X.TargetSegmentCode = PSLNK.TargetSegmentCode
   AND X.TargetSegmentChoiceCode = PSLNK.TargetSegmentChoiceCode
   AND X.TargetChoiceOptionCode = PSLNK.TargetChoiceOptionCode
   AND X.LinkTarget = PSLNK.LinkTarget
   AND X.LinkStatusTypeId = PSLNK.LinkStatusTypeId
   AND X.IsDeleted = PSLNK.IsDeleted
   AND X.ProjectId = PSLNK.ProjectId
   AND X.CustomerId = PSLNK.CustomerId
   AND X.SegmentLinkSourceTypeId = PSLNK.SegmentLinkSourceTypeId
 WHERE PSLNK.SegmentLinkId IS NULL
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentLink_Description            
           ,@ImportProjectSegmentLink_Description            
           ,@IsCompleted           
           ,@ImportProjectSegmentLink_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null  
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted               
         ,@ImportProjectSegmentLink_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               

--INSERT INTO ProjectSegmentRequirementTag
INSERT INTO ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId,
CreateDate, ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy)
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,MSRT_Template.RequirementTagId AS RequirementTagId
    ,GETUTCDATE() AS CreateDate
    ,GETUTCDATE() AS ModifiedDate
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,@PUserId AS CreatedBy
    ,@PUserId AS ModifiedBy
 FROM SLCMaster..SegmentRequirementTag MSRT_Template WITH (NOLOCK)
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
  ON MSRT_Template.SegmentStatusId = PSST.mSegmentStatusId
 WHERE MSRT_Template.SectionId = @TemplateMasterSectionId
 AND PSST.SectionId = @TargetSectionId
 AND @IsTemplateMasterSectionOpened = 0
 UNION
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,PSRT_Template.RequirementTagId AS RequirementTagId
    ,GETUTCDATE() AS CreateDate
    ,GETUTCDATE() AS ModifiedDate
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,@PUserId AS CreatedBy
    ,@PUserId AS ModifiedBy
 FROM ProjectSegmentRequirementTag PSRT_Template WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PSRT_Template.SegmentStatusId = PSST_Template.SegmentStatusId
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
  ON PSST_Template.SegmentStatusCode = PSST.SegmentStatusCode
   AND PSST.SectionId = @TargetSectionId
 WHERE PSRT_Template.SectionId = @TemplateSectionId
 AND @IsTemplateMasterSectionOpened = 1
              
 EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentRequirementTag_Description            
           ,@ImportProjectSegmentRequirementTag_Description            
           ,@IsCompleted         
           ,@ImportProjectSegmentRequirementTag_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted        
         ,@ImportProjectSegmentRequirementTag_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               

--INSERT INTO ProjectSegmentUserTag
INSERT INTO ProjectSegmentUserTag (CustomerId, ProjectId, SectionId, SegmentStatusId,
UserTagId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)
 SELECT
  @PCustomerId AS CustomerId
    ,@PProjectId AS ProjectId
    ,@TargetSectionId AS SectionId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,PSUT_Template.UserTagId AS UserTagId
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS ModifiedDate
    ,@PUserId AS ModifiedBy
 FROM ProjectSegmentUserTag PSUT_Template WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegmentStatus PSST_Template WITH (NOLOCK)
  ON PSUT_Template.SegmentStatusId = PSST_Template.SegmentStatusId
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
  ON PSST_Template.SegmentStatusCode = PSST.SegmentStatusCode
   AND PSST.SectionId = @TargetSectionId
 WHERE PSUT_Template.SectionId = @TemplateSectionId
 AND @IsTemplateMasterSectionOpened = 1

EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentUserTag_Description            
           ,@ImportProjectSegmentUserTag_Description            
           ,@IsCompleted           
           ,@ImportProjectSegmentUserTag_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted     
         ,@ImportProjectSegmentUserTag_Percentage --Percent            
         , 0
    ,@ImportSource          
         , @RequestId;               

--INSERT INTO ProjectSegmentGlobalTerm
INSERT INTO ProjectSegmentGlobalTerm (CustomerId, ProjectId, SectionId, SegmentId, mSegmentId,
UserGlobalTermId, GlobalTermCode, IsLocked, LockedByFullName, UserLockedId, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy)
 SELECT
  @PCustomerId AS CustomerId
    ,@PProjectId AS ProjectId
    ,@TargetSectionId AS SectionId
    ,PSG.SegmentId AS SegmentId
    ,NULL AS mSegmentId
    ,PSGT_Template.UserGlobalTermId AS UserGlobalTermId
    ,PSGT_Template.GlobalTermCode AS GlobalTermCode
    ,PSGT_Template.IsLocked AS IsLocked
    ,PSGT_Template.LockedByFullName AS LockedByFullName
    ,PSGT_Template.UserLockedId AS UserLockedId
    ,GETUTCDATE() AS CreatedDate
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS ModifiedDate
    ,@PUserId AS ModifiedBy
 FROM ProjectSegmentGlobalTerm PSGT_Template WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegment PSG_Template WITH (NOLOCK)
  ON PSGT_Template.SegmentId = PSG_Template.SegmentId
 INNER JOIN ProjectSegment PSG WITH (NOLOCK)
  ON PSG_Template.SegmentCode = PSG.SegmentCode
   AND PSG.SectionId = @TargetSectionId
 WHERE PSGT_Template.SectionId = @TemplateSectionId
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentGlobalTerm_Description         
           ,@ImportProjectSegmentGlobalTerm_Description            
           ,@IsCompleted           
           ,@ImportProjectSegmentGlobalTerm_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted 
         ,@ImportProjectSegmentGlobalTerm_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               

--INSERT INTO ProjectSegmentImage
INSERT INTO ProjectSegmentImage (SectionId, ImageId, ProjectId, CustomerId, SegmentId,ImageStyle)
 SELECT
  @TargetSectionId AS SectionId
    ,PSI_Template.ImageId AS ImageId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,PSG.SegmentId AS SegmentId
	,PSI_Template.ImageStyle
 FROM ProjectSegmentImage PSI_Template WITH (NOLOCK)
 INNER JOIN #tmp_SrcProjectSegment PSG_Template WITH (NOLOCK)
  ON PSI_Template.SegmentId = PSG_Template.SegmentId
 INNER JOIN ProjectSegment PSG WITH (NOLOCK)
  ON PSG_Template.SegmentCode = PSG.SegmentCode
   AND PSG.SectionId = @TargetSectionId
 WHERE PSI_Template.SectionId = @TemplateSectionId
 UNION
 SELECT
  @TargetSectionId AS SectionId
    ,PSI_Template.ImageId AS ImageId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
    ,PSI_Template.SegmentId AS SegmentId
	,PSI_Template.ImageStyle
 FROM ProjectSegmentImage PSI_Template WITH (NOLOCK)
 WHERE PSI_Template.SectionId = @TemplateSectionId
 AND (PSI_Template.SegmentId IS NULL
 OR PSI_Template.SegmentId <= 0)
              
  EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentImage_Description            
           ,@ImportProjectSegmentImage_Description            
           ,@IsCompleted           
           ,@ImportProjectSegmentImage_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null      
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted  
         ,@ImportProjectSegmentImage_Percentage --Percent            
         , 0
    ,@ImportSource          
         , @RequestId;               
        --INSERT INTO ProjectHyperLink
--NOTE IMP:For updating proper HyperLinkId in final table, CustomerId used for temp purpose
--TODO:Need to correct ProjectHyperLink table's ModifiedBy Column
INSERT INTO ProjectHyperLink (SectionId, SegmentId, SegmentStatusId, ProjectId, CustomerId, LinkTarget, LinkText,
LuHyperLinkSourceTypeId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)
 SELECT
  @TargetSectionId AS SectionId
    ,PSST.SegmentId AS SegmentId
    ,PSST.SegmentStatusId AS SegmentStatusId
    ,@PProjectId AS ProjectId         
    ,MHL_Template.HyperLinkId AS MasterHyperLinkId
    ,MHL_Template.LinkTarget AS LinkTarget
    ,MHL_Template.LinkText AS LinkText
    ,MHL_Template.LuHyperLinkSourceTypeId AS LuHyperLinkSourceTypeId
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS ModifiedDate
    ,GETUTCDATE() AS ModifiedBy
 FROM SLCMaster..Note MNT_Template WITH (NOLOCK)
 INNER JOIN SLCMaster..HyperLink MHL_Template WITH (NOLOCK)
  ON MNT_Template.SegmentStatusId = MHL_Template.SegmentStatusId
 INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
  ON MNT_Template.SegmentStatusId = PSST.mSegmentStatusId
   AND PSST.SectionId = @TargetSectionId
 WHERE MNT_Template.SectionId = @TemplateMasterSectionId
               
--Fetch Src Master notes into temp table
SELECT
 * INTO #tmp_SrcMasterNote
FROM SLCMaster..Note WITH (NOLOCK)
WHERE SectionId = @TemplateMasterSectionId;

--Fetch tgt project notes into temp table
SELECT
 * INTO #tmp_TgtProjectNote
FROM ProjectNote PNT WITH (NOLOCK)
WHERE SectionId = @TargetSectionId;

--UPDATE NEW HyperLinkId IN NoteText
DECLARE @HyperLinkLoopCount INT = 1;
DECLARE @HyperLinkTable TABLE (
 RowId INT
   ,HyperLinkId INT
   ,MasterHyperLinkId INT
);

INSERT INTO @HyperLinkTable (RowId, HyperLinkId, MasterHyperLinkId)
 SELECT
  ROW_NUMBER() OVER (ORDER BY PHL.HyperLinkId ASC) AS RowId       
    ,PHL.HyperLinkId
    ,PHL.CustomerId
 FROM ProjectHyperLink PHL WITH (NOLOCK)
 WHERE PHL.SectionId = @TargetSectionId;

declare @HyperLinkTableRowCount INT=(SELECT  COUNT(*)  FROM @HyperLinkTable)
WHILE (@HyperLinkLoopCount <= @HyperLinkTableRowCount)
BEGIN
DECLARE @HyperLinkId INT = 0;
DECLARE @MasterHyperLinkId INT = 0;

SELECT
 @HyperLinkId = HyperLinkId
   ,@MasterHyperLinkId = MasterHyperLinkId
FROM @HyperLinkTable
WHERE RowId = @HyperLinkLoopCount;

UPDATE PNT
SET PNT.NoteText =
REPLACE(PNT.NoteText, '{HL#' + CAST(@MasterHyperLinkId AS NVARCHAR(MAX)) + '}',
'{HL#' + CAST(@HyperLinkId AS NVARCHAR(MAX)) + '}')
FROM #tmp_SrcMasterNote MNT_Template WITH (NOLOCK)
INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
 ON MNT_Template.SegmentStatusId = PSST.mSegmentStatusId     
 AND PSST.SectionId = @TargetSectionId
INNER JOIN #tmp_TgtProjectNote PNT WITH (NOLOCK)
 ON PSST.SegmentStatusId = PNT.SegmentStatusId
WHERE MNT_Template.SectionId = @TemplateMasterSectionId

SET @HyperLinkLoopCount = @HyperLinkLoopCount + 1;
END

--Update NoteText back into original table from temp table
UPDATE PNT
SET PNT.NoteText = TMP.NoteText
FROM ProjectNote PNT WITH (NOLOCK)
INNER JOIN #tmp_TgtProjectNote TMP WITH (NOLOCK)
 ON PNT.NoteId = TMP.NoteId
WHERE PNT.SectionId = @TargetSectionId;

--UPDATE PROPER CustomerId IN ProjectHyperLink
UPDATE PHL
SET PHL.CustomerId = @PCustomerId
FROM ProjectHyperLink PHL WITH (NOLOCK)
WHERE PHL.SectionId = @TargetSectionId
              
   EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectHyperLink_Description            
           ,@ImportProjectHyperLink_Description            
           ,@IsCompleted           
           ,@ImportProjectHyperLink_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted    
         ,@ImportProjectHyperLink_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               

--INSERT INTO ProjectNoteImage
INSERT INTO ProjectNoteImage (NoteId, SectionId, ImageId, ProjectId, CustomerId)
 SELECT
  PN.NoteId AS NoteId
    ,@TargetSectionId AS SectionId
    ,PNI_Template.ImageId AS ImageId
    ,@PProjectId AS ProjectId
    ,@PCustomerId AS CustomerId
 FROM ProjectNoteImage PNI_Template WITH (NOLOCK)
 INNER JOIN ProjectNote PN_Template WITH (NOLOCK)
  ON PNI_Template.NoteId = PN_Template.NoteId
 INNER JOIN ProjectNote PN WITH (NOLOCK)
  ON PN_Template.NoteCode = PN.NoteCode
   AND PN.SectionId = @TargetSectionId
 WHERE PNI_Template.SectionId = @TemplateSectionId     
 
    EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectNoteImage_Description            
           ,@ImportProjectNoteImage_Description            
           ,@IsCompleted          
           ,@ImportProjectNoteImage_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId             
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted               
         ,@ImportProjectNoteImage_Percentage --Percent            
         , 0
   ,@ImportSource        
         , @RequestId;               

--INSERT INTO ProjectSegmentReferenceStandard
INSERT INTO ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource,
mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, mSegmentId, RefStdCode, IsDeleted)
 SELECT
 DISTINCT
  @TargetSectionId AS SectionId
    ,X.SegmentId
    ,X.RefStandardId
    ,X.RefStandardSource
    ,X.mRefStandardId
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS ModifiedDate
    ,@PUserId AS ModifiedBy
    ,@PCustomerId AS CustomerId
    ,@PProjectId AS ProjectId
    ,X.mSegmentId
    ,X.RefStdCode
    ,X.IsDeleted
 FROM (SELECT
   PSST.SegmentId AS SegmentId
     ,NULL AS RefStandardId
    ,'M' AS RefStandardSource
     ,MRS_Template.RefStdId AS mRefStandardId
     ,NULL AS mSegmentId
     ,MRS_Template.RefStdCode AS RefStdCode
     ,CAST(0 AS BIT) AS IsDeleted
  FROM SLCMaster..SegmentReferenceStandard MSRS_Template WITH (NOLOCK)
  INNER JOIN SLCMaster..ReferenceStandard MRS_Template WITH (NOLOCK)
 ON MSRS_Template.RefStandardId = MRS_Template.RefStdId
  INNER JOIN #tmp_TgtProjectSegmentStatus PSST
   ON MSRS_Template.SegmentId = PSST.mSegmentId
   AND PSST.SectionId = @TargetSectionId
  WHERE MSRS_Template.SectionId = @TemplateMasterSectionId
  UNION
  SELECT
   PSST.SegmentId AS SegmentId
     ,PSRS_Template.RefStandardId AS RefStandardId
     ,PSRS_Template.RefStandardSource AS RefStandardSource
     ,PSRS_Template.mRefStandardId AS mRefStandardId
     ,NULL AS mSegmentId
     ,PSRS_Template.RefStdCode AS RefStdCode
     ,PSRS_Template.IsDeleted
  FROM ProjectSegmentReferenceStandard PSRS_Template WITH (NOLOCK)
  INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
   ON PSRS_Template.mSegmentId = PSST.mSegmentId
   AND PSST.SectionId = @TargetSectionId
  WHERE PSRS_Template.SectionId = @TemplateSectionId
  AND PSRS_Template.mSegmentId IS NOT NULL
  AND PSRS_Template.SegmentId IS NULL
  UNION
  SELECT
   PSG.SegmentId AS SegmentId
     ,PSRS_Template.RefStandardId AS RefStandardId
     ,PSRS_Template.RefStandardSource AS RefStandardSource
     ,PSRS_Template.mRefStandardId AS mRefStandardId
     ,NULL AS mSegmentId
     ,PSRS_Template.RefStdCode AS RefStdCode
     ,PSRS_Template.IsDeleted
  FROM ProjectSegmentReferenceStandard PSRS_Template WITH (NOLOCK)
  INNER JOIN #tmp_SrcProjectSegment PSG_Template WITH (NOLOCK)         
   ON PSRS_Template.SegmentId = PSG_Template.SegmentId
  INNER JOIN ProjectSegment PSG WITH (NOLOCK)
   ON PSG_Template.SegmentCode = PSG.SegmentCode
   AND PSG.SectionId = @TargetSectionId
  WHERE PSRS_Template.SectionId = @TemplateSectionId
  AND PSRS_Template.mSegmentId IS NULL
  AND PSRS_Template.SegmentId IS NOT NULL) AS X
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentReferenceStandard_Description            
           ,@ImportProjectSegmentReferenceStandard_Description            
           ,@IsCompleted          
           ,@ImportProjectSegmentReferenceStandard_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted 
         ,@ImportProjectSegmentReferenceStandard_Percentage --Percent            
         , 0
   ,@ImportSource        
         , @RequestId;               

--INSERT INTO Header
INSERT INTO Header (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy,
ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, TypeId, AltHeader, FPHeader,
UseSeparateFPHeader, HeaderFooterCategoryId, DateFormat, TimeFormat)
 SELECT
  @PProjectId AS ProjectId
    ,@TargetSectionId AS SectionId
    ,@PCustomerId AS CustomerId
    ,Description
    ,NULL AS IsLocked
    ,NULL AS LockedByFullName
    ,NULL AS LockedBy
    ,ShowFirstPage
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreatedDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
    ,TypeId
    ,AltHeader
    ,FPHeader
    ,UseSeparateFPHeader
    ,HeaderFooterCategoryId
    ,DateFormat
    ,TimeFormat
 FROM Header WITH (NOLOCK)
 WHERE SectionId = @TemplateSectionId
              
EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportHeader_Description            
           ,@ImportHeader_Description            
           ,@IsCompleted     
           ,@ImportHeader_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted  
         ,@ImportHeader_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               

--INSERT INTO Footer
INSERT INTO Footer (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy,
ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, TypeId, AltFooter, FPFooter,
UseSeparateFPFooter, HeaderFooterCategoryId, DateFormat, TimeFormat)
 SELECT
  @PProjectId AS ProjectId
    ,@TargetSectionId AS SectionId
    ,@PCustomerId AS CustomerId
    ,Description
    ,NULL AS IsLocked
    ,NULL AS LockedByFullName
    ,NULL AS LockedBy
    ,ShowFirstPage
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS CreatedDate
    ,@PUserId AS ModifiedBy
    ,GETUTCDATE() AS ModifiedDate
    ,TypeId
    ,AltFooter
    ,FPFooter
    ,UseSeparateFPFooter
    ,HeaderFooterCategoryId
    ,DateFormat
    ,TimeFormat
 FROM Footer WITH (NOLOCK)
 WHERE SectionId = @TemplateSectionId
              
 EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportFooter_Description            
           ,@ImportFooter_Description            
           ,@IsCompleted      
           ,@ImportFooter_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted      
         ,@ImportFooter_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               

--INSERT INTO ProjectReferenceStandard
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,
RefStdEditionId, IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId)
 SELECT
 DISTINCT
  @PProjectId AS ProjectId
    ,X.RefStandardId
    ,X.RefStdSource
    ,X.mReplaceRefStdId
    ,X.RefStdEditionId
    ,X.IsObsolete
    ,X.RefStdCode
    ,GETUTCDATE() AS PublicationDate             
    ,@TargetSectionId AS SectionId
    ,@PCustomerId AS CustomerId
 FROM (SELECT
   MRS.RefStdId AS RefStandardId
     ,'M' AS RefStdSource
     ,MRS.ReplaceRefStdId AS mReplaceRefStdId
     ,MAX(MRSE.RefStdEditionId) AS RefStdEditionId
     ,MRS.IsObsolete AS IsObsolete
     ,MRS.RefStdCode AS RefStdCode
  FROM SLCMaster..SegmentReferenceStandard MSRS WITH (NOLOCK)
  INNER JOIN SLCMaster..ReferenceStandard MRS WITH (NOLOCK)
   ON MSRS.RefStandardId = MRS.RefStdId
  INNER JOIN SLCMaster..ReferenceStandardEdition MRSE WITH (NOLOCK)
   ON MRS.RefStdId = MRSE.RefStdId
  INNER JOIN #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)
   ON MSRS.SegmentId = PSST.mSegmentId
   AND PSST.SectionId = @TargetSectionId
  WHERE MSRS.SectionId = @TemplateMasterSectionId
  GROUP BY MRS.RefStdId
    ,MRS.ReplaceRefStdId
    ,MRS.IsObsolete
    ,MRS.RefStdCode
  UNION
  SELECT
   PRS.RefStandardId AS RefStandardId
     ,PRS.RefStdSource AS RefStdSource
     ,PRS.mReplaceRefStdId AS mReplaceRefStdId
     ,PRS.RefStdEditionId AS RefStdEditionId
     ,PRS.IsObsolete AS IsObsolete
     ,PRS.RefStdCode AS RefStdCode
  FROM ProjectReferenceStandard PRS WITH (NOLOCK)
  WHERE PRS.ProjectId = @PProjectId
  AND PRS.CustomerId = @PCustomerId
  AND PRS.SectionId = @TargetSectionId
  AND PRS.IsDeleted = 0) AS X
 LEFT JOIN ProjectReferenceStandard PRS WITH (NOLOCK)
  ON PRS.ProjectId = @PProjectId
   AND PRS.RefStandardId = X.RefStandardId
   AND PRS.RefStdSource = X.RefStdSource
   AND ISNULL(PRS.mReplaceRefStdId, 0) = ISNULL(X.mReplaceRefStdId, 0)
   AND PRS.RefStdEditionId = X.RefStdEditionId
   AND PRS.IsObsolete = X.IsObsolete
   AND PRS.SectionId = @TargetSectionId
   AND PRS.CustomerId = @PCustomerId
 WHERE PRS.ProjRefStdId IS NULL
              
 EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectReferenceStandard_Description            
           ,@ImportProjectReferenceStandard_Description            
           ,@IsCompleted      
           ,@ImportProjectReferenceStandard_Step --Step     
     ,@RequestId;              
  
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
        ,@PCustomerId            
         ,@ImportStarted      
         ,@ImportProjectReferenceStandard_Percentage --Percent            
         , 0
   ,@ImportSource        
         , @RequestId;         

--UPDATE ProjectSegmentStatus at last
UPDATE PSST
SET PSST.mSegmentStatusId = NULL
   ,PSST.mSegmentId = NULL
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
WHERE PSST.SectionId = @TargetSectionId
              
	update ps
	set ps.IsLocked=0,
		ps.IsDeleted=0,
		ps.LockedBy=0,
		ps.LockedByFullName=''
	from ProjectSection ps WITH(NOLOCK)
	WHERE ps.SectionId=@TargetSectionId

 EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportProjectSegmentStatus_Description            
           ,@ImportProjectSegmentStatus_Description            
           ,@IsCompleted   
           ,@ImportProjectSegmentStatus_Step --Step     
     ,@RequestId;              
             
EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportStarted    
         ,@ImportProjectSegmentStatus_Percentage --Percent            
         , 0
   ,@ImportSource          
         , @RequestId;               

SELECT
 *
FROM ProjectSection WITH (NOLOCK)
WHERE SectionId = @TargetSectionId              
  
    EXEC usp_MaintainImportProjectHistory @PProjectId           
           ,@ImportComplete_Description            
           ,@ImportComplete_Description            
           ,@IsCompleted    
           ,@ImportComplete_Step --Step     
     ,@RequestId;              

 --Add Logs to ImportProjectRequest
 EXEC usp_MaintainImportProjectProgress null            
         ,@PProjectId     
   ,null
  , @TargetSectionId              
         ,@PUserId            
         ,@PCustomerId            
         ,@ImportCompleted        
         ,@ImportComplete_Percentage --Percent            
         , 0
    ,@ImportSource        
         , @RequestId;               
              
               
END TRY

BEGIN CATCH
	
	update ps
	set ps.IsLocked=0,
		ps.LockedBy=0,
		ps.LockedByFullName=''
	from ProjectSection ps WITH(NOLOCK)
	WHERE ps.SectionId=@TargetSectionId
	
	DECLARE @ResultMessage NVARCHAR(MAX);            
	SET @ResultMessage = concat('Rollback Transaction. Error Number: ' , CONVERT(VARCHAR(MAX), ERROR_NUMBER()) ,      
	'. Error Message: ' , CONVERT(VARCHAR(MAX), ERROR_MESSAGE()) ,            
	'. Procedure Name: ' , CONVERT(VARCHAR(MAX), ERROR_PROCEDURE()) ,            
	'. Error Severity: ' , CONVERT(VARCHAR(5), ERROR_SEVERITY()) ,            
	'. Line Number: ' , CONVERT(VARCHAR(5), ERROR_LINE()))    
              
			  --insert into temp values(@ResultMessage,GETUTCDATE())

	 EXEC usp_MaintainImportProjectHistory @PProjectId            
			   ,@ImportFailed_Description            
			  ,@ResultMessage      
			   ,@IsCompleted  
				,@ImportFailed_Step --Step     
		 ,@RequestId;

	EXEC usp_MaintainImportProjectProgress null            
			 ,@PProjectId     
	   ,null
	  , @TargetSectionId       
			 ,@PUserId            
			 ,@PCustomerId         
		,@Importfailed        
			,@ImportFailed_Percentage --Percent            
			 , 0
		   ,@ImportSource          
			 , @RequestId;
              
END CATCH  
END 
GO
Print '44. [usp_CreateSectionFromMasterTemplate_Job]'
Go

CREATE OR ALTER PROCEDURE usp_CreateSectionFromTemplateRequest
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
Print '45. usp_CreateSectionFromTemplateRequest'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_CreateSectionJob]   
AS  
BEGIN  
 --Check for Expiry  
 update r
 set r.StatusId=5
 FROM ImportProjectRequest r WITH(nolock) 
 WHERE r.StatusId=2 and 
 r.Source='Import from Template' 
 and isnull(r.IsDeleted,0)=0
 and DATEADD(Minute,-5,GETUTCDATE())>r.ModifiedDate

 IF(NOT EXISTS(SELECT TOP 1 1 FROM ImportProjectRequest WITH(nolock) WHERE StatusId=2 and Source='Import from Template' and isnull(IsDeleted,0)=0))  
 BEGIN  
  DECLARE @RequestId INT      
   
  SELECT TOP 1  
   @RequestId=RequestId  
  FROM ImportProjectRequest WITH(nolock)   
  WHERE StatusId=1 AND ISNULL(IsDeleted,0)=0  
  AND Source='Import from Template' 
  ORDER BY CreatedDate ASC  
  
  IF(@RequestId>0)  
  BEGIN  
   EXEC usp_CreateSectionFromMasterTemplate_Job @RequestId  
  END  
 END  
END
GO
Print '46. [usp_CreateSectionJob]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_CreateSpecDataSections]  
(  
@ProjectId int,  
@CustomerId int,  
@UserId Int,  
@MasterSectionIdJson NVARCHAR(max)   
)  
as  
begin  
  
DECLARE  @ReturnInputDataTable TABLE(   
    SectionId INT  ,  
 mSectionId INT   
);  
  
DECLARE  @InputDataTable TABLE(  
RowId int,  
    SectionId INT    
);  
DECLARE @SectionId int=0;  
DECLARE @Canada_Section_CutOffDate DATETIME2(7) = '20190420';  
IF @MasterSectionIdJson != ''  
BEGIN  
INSERT INTO @InputDataTable  
 SELECT  
  ROW_NUMBER() OVER (ORDER BY SectionId ASC) AS RowId  
    ,SectionId  
 FROM OPENJSON(@MasterSectionIdJson)  
 WITH (  
 SectionId INT '$.SectionId'  
 );  
END  
  
DECLARE @RowCount INT = (SELECT  
  COUNT(SectionId)  
 FROM @InputDataTable)  
  
DECLARE @n INT = 1;  
WHILE (@RowCount >= @n)  
BEGIN  
  
SET @SectionId = (SELECT TOP 1  
  ps.SectionId  
 FROM @InputDataTable stb  
 INNER JOIN ProjectSection ps  with (nolock)
  ON ps.mSectionId = stb.SectionId  
  AND ps.ProjectId = @ProjectId  
  AND ps.CustomerId = @CustomerId  
 WHERE RowId = @n)  
  
DECLARE @IsPresent INT = 0;  
SELECT  
 @IsPresent = COUNT(SegmentStatusId)  
FROM ProjectSegmentStatus  with (nolock)
WHERE SectionId = @SectionId  
AND ProjectId = @ProjectId  
AND CustomerId = @CustomerId  
  
PRINT @IsPresent  
PRINT @n  
  
IF (@IsPresent > 0)  
BEGIN  
  
DECLARE @PMasterDataTypeId INT = (SELECT  
  MasterDataTypeId  
 FROM Project  with (nolock)
 WHERE ProjectId = @ProjectId  
 AND CustomerId = @CustomerId);  
  
DECLARE @SpecViewModeId INT = (SELECT  
  SpecViewModeId  
 FROM ProjectSummary WITH (NOLOCK)  
 WHERE ProjectId = @ProjectId  
 AND CustomerId = @CustomerId);  
SET @SpecViewModeId =  
CASE  
 WHEN @SpecViewModeId IS NULL THEN 1  
 ELSE @SpecViewModeId  
END;  
  
DROP TABLE IF EXISTS #ProjectSection  
  
SELECT  
 S.SectionId AS mSectionId  
   ,0 AS ParentSectionId  
   ,s.ParentSectionId AS mParentSectionId  
   ,@ProjectId AS [ProjectId]  
   ,@CustomerId AS [CustomerId]  
   ,@UserId AS [UserId]  
   ,DivisionId  
   ,[Description]  
   ,LevelId  
   ,IsLastLevel  
   ,SourceTag + '.1' AS SourceTag  
   ,Author  
   ,@UserId AS CreatedBy  
   ,GETUTCDATE() AS CreateDate  
   ,@UserId AS ModifiedBy  
   ,GETUTCDATE() AS ModifiedDate  
   ,[SectionCode]  
   ,[IsDeleted]  
   ,CASE  
  WHEN ParentSectionId = 0 OR  
   ParentSectionId IS NULL THEN 0  
  ELSE NULL  
 END AS TemplateId  
   ,[FormatTypeId]  
   ,[S].[DivisionCode]  
   ,@SpecViewModeId AS SpecViewModeId INTO #ProjectSection  
FROM [SLCMaster].[dbo].[Section] S WITH (NOLOCK)  
INNER JOIN @InputDataTable stbl  
 ON S.SectionId = stbl.SectionId  
  AND stbl.RowId = @n  
WHERE S.MasterDataTypeId = @PMasterDataTypeId  
AND S.IsDeleted = 0  
AND (S.PublicationDate >=  
CASE  
 WHEN @PMasterDataTypeId = 4 THEN (  
  CASE  
   WHEN S.IsLastLevel = 1 THEN @Canada_Section_CutOffDate  
   ELSE S.PublicationDate  
  END  
  )  
 ELSE S.PublicationDate  
END)  
  
INSERT INTO [ProjectSection] ([mSectionId], [ParentSectionId], [ProjectId], [CustomerId], [UserId], [DivisionId], [Description],  
[LevelId], [IsLastLevel], [SourceTag], [Author], [CreatedBy], [CreateDate], [ModifiedBy], [ModifiedDate], [SectionCode], [IsDeleted],  
[TemplateId],  
[FormatTypeId], [DivisionCode], [SpecViewModeId])  
 SELECT  
  ps.mSectionId  
    ,ps.ParentSectionId  
    ,@ProjectId AS [ProjectId]  
    ,@CustomerId AS [CustomerId]  
    ,@UserId AS [UserId]  
    ,ps.DivisionId  
    ,ps.[Description]  
    ,ps.LevelId  
    ,ps.IsLastLevel  
    ,ps.SourceTag  
    ,ps.Author  
    ,@UserId AS CreatedBy  
    ,GETUTCDATE() AS CreateDate  
    ,@UserId AS ModifiedBy  
    ,GETUTCDATE() AS ModifiedDate  
    ,ps.[SectionCode]  
    ,ps.[IsDeleted]  
    ,CASE  
   WHEN ParentSectionId = 0 OR  
    ParentSectionId IS NULL THEN 0  
   ELSE NULL  
  END AS TemplateId  
    ,ps.[FormatTypeId]  
    ,ps.[DivisionCode]  
    ,@SpecViewModeId AS SpecViewModeId  
 FROM #ProjectSection AS ps;  
  
DROP TABLE IF EXISTS #PSections  
  
SET @SectionId = SCOPE_IDENTITY();  
  
SELECT  
 PPS.ParentSectionId  
   ,PPS.mSectionId INTO #PSections  
FROM [ProjectSection] AS PPS WITH (NOLOCK)  
INNER JOIN @InputDataTable stbl  
 ON PPS.mSectionId = stbl.SectionId  
WHERE PPS.[ProjectId] = @ProjectId  
AND PPS.[CustomerId] = @CustomerId  
AND stbl.RowId = @n  
GROUP BY PPS.ParentSectionId  
  ,PPS.mSectionId  
  
  
UPDATE CPS  
SET CPS.ParentSectionId = PPS.ParentSectionId  
FROM [ProjectSection] AS CPS WITH (NOLOCK)  
INNER JOIN #PSections AS PPS WITH (NOLOCK)  
 ON PPS.mSectionId = CPS.mSectionId  
WHERE CPS.[ProjectId] = @ProjectId  
AND CPS.[CustomerId] = @CustomerId  
AND CPS.SectionId = @SectionId  
AND PPS.ParentSectionId <> 0  
  
END  
  
IF (@IsPresent <= 0)  
BEGIN  
  
SET @SectionId = (SELECT TOP 1  
  ps.SectionId  
 FROM ProjectSection PS WITH (NOLOCK)  
 INNER JOIN @InputDataTable IDTBL  
  ON IDTBL.SectionId = PS.mSectionId  
  AND PS.ProjectId = @ProjectId  
  AND PS.CustomerId = @CustomerId  
 WHERE RowId = @n)  
  
END  
  
  
SET @n = @n + 1;  
declare @mSectionId int=0  
SELECT  
 @mSectionId = mSectionId  
FROM ProjectSection  with (nolock)
WHERE SectionId = @SectionId  
INSERT INTO @ReturnInputDataTable (SectionId, mSectionId)  
 SELECT  
  @SectionId  
    ,@mSectionId  
  
END  
  
  
SELECT  
 *  
FROM @ReturnInputDataTable  
END  
GO
Print '47. [usp_CreateSpecDataSections]'
Go

CREATE OR ALTER PROCEDURE usp_DeleteMigratedProject  
(  
 @CustomerId INT,  
 @ArchiveProjectId INT,  
 @UserId INT,  
 @ModifiedByFullName NVARCHAR(50)=''  
)  
AS  
BEGIN  
  
 UPDATE P  
 SET P.IsDeleted=1  
 FROM Project P WITH(NOLOCK)  
 WHERE P.ProjectId=@ArchiveProjectId  
 AND P.IsShowMigrationPopup=1  
  
 UPDATE UF  
 SET UF.UserId=@UserId,  
  UF.LastAccessed=GETUTCDATE(),  
  LastAccessByFullName=@ModifiedByFullName  
 FROM UserFolder UF WITH(NOLOCK)  
 WHERE UF.ProjectId=@ArchiveProjectId  
END  
GO
Print '48. usp_DeleteMigratedProject'
Go

CREATE OR ALTER PROCEDURE usp_DeleteMigratedProjectPermanent  
(  
 @CustomerId INT,  
 @ArchiveProjectId INT,  
 @UserId INT,  
 @ModifiedByFullName NVARCHAR(50)=''  
)  
AS  
BEGIN  
  
 UPDATE P
 SET P.IsPermanentDeleted=1  
 FROM Project P WITH(NOLOCK)  
 WHERE P.ProjectId=@ArchiveProjectId  
 AND P.IsShowMigrationPopup=1  
 AND ISNULL(P.IsDeleted,0)=1  
  
 UPDATE UF  
 SET UF.UserId=@UserId,  
  UF.LastAccessed=GETUTCDATE(),  
  LastAccessByFullName=@ModifiedByFullName  
 FROM UserFolder UF WITH(NOLOCK)  
 WHERE UF.ProjectId=@ArchiveProjectId  
END
GO
Print '49. usp_DeleteMigratedProjectPermanent'
Go

CREATE OR ALTER PROCEDURE  [dbo].[usp_EnableDisableTrackChanges]
(  
 @ProjectId  int,
 @SectionId int,
 @CustomerId int,
 @UserId int,
 @IsTrackChanges bit
)
AS  
BEGIN  
	DECLARE @IsLocked BIT;
	SET @IsLocked = (SELECT
		COUNT(1) AS TrackChangeLockedBy
	FROM [ProjectSection] PS WITH (NOLOCK)
	WHERE PS.SectionId = @SectionId
	AND PS.IsTrackChangeLock = 1)

	IF(@IsLocked=1 and @IsTrackChanges=1)
	BEGIN
		UPDATE PS SET PS.IsTrackChanges = @IsTrackChanges
		FROM ProjectSection PS WITH(NOLOCK) WHERE PS.SectionId = @SectionId
	END

	IF(@IsLocked=0)
	BEGIN
		UPDATE PS  SET PS.IsTrackChanges =@IsTrackChanges
		FROM ProjectSection PS WITH(NOLOCK) WHERE PS.SectionId=@SectionId
	END

	SELECT IsTrackChanges,PS.IsTrackChangeLock ,COALESCE(PS.TrackChangeLockedBy,0)AS TrackChangeLockedBy
	FROM ProjectSection PS WITH(NOLOCK) WHERE PS.SectionId=@SectionId

END
GO
Print '50. [usp_EnableDisableTrackChanges]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_GetCopyProjectProgress]    
@UserId INT        
AS        
BEGIN    
--find and mark as failed copy project requests which running loner(more than 30 mins)        
    
UPDATE cpr
	SET cpr.StatusId=5
		,cpr.IsNotify=0
		,cpr.IsEmailSent=0
		,ModifiedDate=GETUTCDATE()
	FROM CopyProjectRequest cpr WITH(nolock) INNER JOIN CopyProjectHistory cph WITH(NOLOCK)
	ON cpr.RequestId=cph.RequestId
	WHERE cpr.StatusId = 2 and cph.CreatedDate < DATEADD(MINUTE,-30,GETUTCDATE())
	and cph.Step=2     
    
SELECT    
 CPR.RequestId    
   ,CPR.SourceProjectId    
   ,CPR.TargetProjectId    
   ,CPR.CreatedById    
   ,CPR.CustomerId    
   ,P.Name    
   ,P.IsOfficeMaster    
   ,CPR.CompletedPercentage    
   ,CPR.StatusId    
   ,CPR.CreatedDate    
	,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr
   ,LCS.StatusDescription    
   ,CPR.IsNotify    
   ,CPR.ModifiedDate    
   ,DATEADD(DAY, 30, CPR.CreatedDate) AS RequestExpiryDateTime    
INTO #t    
FROM CopyProjectRequest CPR WITH (NOLOCK)    
INNER JOIN Project P WITH (NOLOCK)    
 ON P.ProjectId = CPR.TargetProjectId    
INNER JOIN LuCopyStatus LCS WITH (NOLOCK)    
 ON LCS.CopyStatusId = CPR.StatusId    
WHERE 
(CPR.IsNotify = 0    
OR DATEADD(SECOND, 7, CPR.ModifiedDate) > GETUTCDATE())    
AND CPR.CreatedById = @UserId    
AND ISNULL(CPR.IsDeleted, 0) = 0    
    
UPDATE CPR    
SET CPR.IsNotify = 1    
   ,ModifiedDate = GETUTCDATE()    
FROM CopyProjectRequest CPR WITH (NOLOCK)    
INNER JOIN #t t    
 ON CPR.RequestId = t.RequestId    
WHERE CPR.IsNotify = 0    
    
SELECT    
 *    
FROM #t    
    
    
END 
GO
Print '51. [usp_GetCopyProjectProgress]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_GetCopyProjectRequest]    
(    
 @CustomerId INT,    
 @UserId INT,    
 @IsSystemManager BIT=0    
)    
AS    
BEGIN    
 DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())    
 SELECT   
 CPR.RequestId  
,CPR.SourceProjectId  
,CPR.TargetProjectId  
,CPR.CreatedById  
,CPR.CustomerId  
,CPR.CreatedDate  
,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr
,DATEADD(DAY,30,CPR.CreatedDate) AS RequestExpiryDateTime  
,ISNULL(CPR.ModifiedDate,'') as ModifiedDate  
,CPR.StatusId  
,CPR.IsNotify  
,CPR.CompletedPercentage  
,CPR.IsDeleted  
,P.[Name]  
,LCS.Name as StatusDescription  
 FROM CopyProjectRequest CPR WITH(NOLOCK)    
  INNER JOIN Project P WITH(NOLOCK)    
   ON P.ProjectId = CPR.TargetProjectId   
   INNER JOIN LuCopyStatus LCS  WITH(NOLOCK)
   ON LCS.CopyStatusId=CPR.StatusId   
 WHERE CPR.CreatedById=@UserId  
 AND isnull(CPR.IsDeleted,0)=0    
 AND CPR.CreatedDate> @DateBefore30Days   
 ORDER by CPR.CreatedDate DESC    
END    
GO
Print '52. [usp_GetCopyProjectRequest]'
Go

CREATE OR ALTER PROCEDURE  [dbo].[usp_GetCustomerDataForPDFExport] 
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
Print '53. [usp_GetCustomerDataForPDFExport]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_GetLimitAccessProjectList]          
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
  AND P.IsShowMigrationPopup=0     
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
   AND P.IsShowMigrationPopup=0            
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
Print '54. [usp_GetLimitAccessProjectList]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_GetMigratedDeletedProjects] --51,0               
  @CustomerId INT NULL                
 ,@IsOfficeMaster BIT NULL = NULL                
                 
AS                
BEGIN        
              
  DECLARE @PCustomerId INT = @CustomerId;        
  DECLARE @PIsOfficeMaster BIT = @IsOfficeMaster;        
              
              
 SELECT        
    CONVERT(BIGINT, P.ProjectId) AS ArchiveProjectId,  
    p.ProjectId AS SLC_ProdProjectId       
    ,LTRIM(RTRIM(p.[Name])) AS ProjectName        
    ,UF.LastAccessed as DeletedOn       
    ,ISNULL(UF.LastAccessByFullName,'') AS ModifiedByFullName       
    --,ISNULL(psm.projectAccessTypeId,0)  AS projectAccessTypeId    
 ,ISNUll(P.UserId,0) as SLC_UserId  
 ,ISNUll(P.CustomerId,0) as SlcCustomerId            
 FROM Project AS p WITH (NOLOCK)        
 Left Join UserFolder UF
 ON P.ProjectId = UF.ProjectId
 WHERE ISNULL(p.IsDeleted,0) = 1        
 AND P.IsShowMigrationPopup=1    
 AND ISNULL(P.IsPermanentDeleted, 0) = 0        
 AND p.IsOfficeMaster = @PIsOfficeMaster        
 AND p.customerId = @PCustomerId;        
END        
GO
Print '55. [usp_GetMigratedDeletedProjects]'
Go

CREATE OR ALTER PROCEDURE usp_GetMigratedProjectCount
(    
 @CustomerId INT,    
 @UserId INT=0,
 @IsOfficeMaster BIT=0,    
 @IsSystemManager BIT=0    
)    
AS    
BEGIN    
 DECLARE @MigratedProjectCount INT=0    
 DECLARE @ArchivedProjectCount INT=0    
 DECLARE @DeletedProjectCount INT=0    
    
 select @MigratedProjectCount=COUNT(1) from Project P WITH(NOLOCK)    
 where CustomerId=@CustomerId AND Isnull(p.isDeleted,0)=0 and IsShowMigrationPopup=1    
 and ISNULL(p.IsArchived,0)=0  AND ISNULL(p.IsOfficeMaster,0)=@IsOfficeMaster  
 
 IF(@IsSystemManager=1)
 BEGIN   
	 select @ArchivedProjectCount=COUNT(1) from Project P WITH(NOLOCK)    
	 where CustomerId=@CustomerId AND Isnull(p.isDeleted,0)=0 --and IsShowMigrationPopup=1    
	 and ISNULL(p.IsArchived,0)=1 and ISNULL(p.IsPermanentDeleted,0)=0 AND ISNULL(p.IsOfficeMaster,0)=@IsOfficeMaster  
 END
 ELSE
 BEGIN
	
	select P.ProjectId into #t from Project P WITH(NOLOCK)    
	where CustomerId=@CustomerId AND Isnull(p.isDeleted,0)=0 --and IsShowMigrationPopup=1    
	and ISNULL(p.IsArchived,0)=1 and ISNULL(p.IsPermanentDeleted,0)=0 AND ISNULL(p.IsOfficeMaster,0)=@IsOfficeMaster 

	CREATE TABLE #AccessibleProjectIds(     
	   Projectid INT,     
	   ProjectAccessTypeId INT,     
	   IsProjectAccessible bit,     
	   --ProjectAccessTypeName NVARCHAR(100)  ,   
	   IsProjectOwner BIT   
	);
	---Get all public,private and owned projects   
	INSERT INTO #AccessibleProjectIds(Projectid  ,ProjectAccessTypeId,  IsProjectAccessible,IsProjectOwner)                            
	SELECT ps.Projectid,ps.ProjectAccessTypeId,0,iif(ps.OwnerId=@UserId,1,0) 
	FROM #t t inner join ProjectSummary ps WITH(NOLOCK)    
	ON t.ProjectId=ps.ProjectId   
	where  (ps.ProjectAccessTypeId in(1,2) or ps.OwnerId=@UserId)   
	AND ps.CustomerId=@CustomerId  
	
	--Update all public Projects as accessible   
	UPDATE t   
	set t.IsProjectAccessible=1   
	from #AccessibleProjectIds t    
	where t.ProjectAccessTypeId=1        
	    
	--Update all private Projects if they are accessible   
	UPDATE t set t.IsProjectAccessible=1   
	from #AccessibleProjectIds t    
	inner join UserProjectAccessMapping u WITH(NOLOCK)   
	ON t.Projectid=u.ProjectId         
	where u.IsActive=1    
	and u.UserId=@UserId and t.ProjectAccessTypeId=2   
	AND u.CustomerId=@CustomerId     
	
	--Get all accessible projects   
	INSERT INTO #AccessibleProjectIds  (Projectid  ,ProjectAccessTypeId,  IsProjectAccessible,IsProjectOwner)                            
	SELECT ps.Projectid,ps.ProjectAccessTypeId,1,iif(ps.OwnerId=@UserId,1,0) 
	FROM #t res inner join ProjectSummary ps WITH(NOLOCK)  
	ON res.ProjectId=ps.ProjectId
	INNER JOIN UserProjectAccessMapping upam WITH(NOLOCK)   
	ON upam.ProjectId=ps.ProjectId 
	LEFT outer JOIN #AccessibleProjectIds t   
	ON t.Projectid=ps.ProjectId   
	where ps.ProjectAccessTypeId=3 AND upam.UserId=@UserId and t.Projectid is null AND ps.CustomerId=@CustomerId   
	AND(upam.IsActive=1 OR ps.OwnerId=@UserId)      
 
	UPDATE t   
	set t.IsProjectAccessible=t.IsProjectOwner   
	from #AccessibleProjectIds t    
	where t.IsProjectOwner=1   

	select @ArchivedProjectCount=COUNT(1) from #AccessibleProjectIds WITH(NOLOCK)    
	--where IsProjectAccessible=1

 END   
 select @DeletedProjectCount=COUNT(1) from Project P WITH(NOLOCK)    
 where CustomerId=@CustomerId AND Isnull(p.isDeleted,0)=1 and IsShowMigrationPopup=1    
 and ISNULL(p.IsPermanentDeleted,0)=0  AND ISNULL(p.IsOfficeMaster,0)=@IsOfficeMaster  
    
 SELECT @MigratedProjectCount AS MigratedProjectCount,@ArchivedProjectCount AS ArchivedProjectCount,@DeletedProjectCount AS DeletedProjectCount   
  
END
GO
Print '56. usp_GetMigratedProjectCount'
Go

CREATE OR ALTER PROCEDURE usp_GetMigratedProjectErrorsList
(@ProjectId INT, @CustomerId INT)    
AS     
BEGIN    
DECLARE @PProjectId INT = @ProjectId;    
DECLARE @PCustomerId INT = @CustomerId;     

select     
PME.MigrationExceptionId,    
--CONCAT(PS.SourceTag, ':' ,PS.Author) AS Section,    
--COALESCE(PS.[Description],'') AS SectionName,  
CAST('' AS NVARCHAR(15)) AS Section,    
CAST('' AS NVARCHAR(500)) AS SectionName,    
CAST(0 AS INT) AS SequenceNumber,    
PME.SegmentDescription as SegmentDescription1,       
PME.SegmentStatusId,
PME.SectionId, 
COALESCE(PME.BrokenPlaceHolderType,'NA') AS MissingEntities,    
'' AS ProjectName,    
ISNULL(PME.IsResolved,0) AS IsResolved,      
CAST(0 AS BIT) AS HasCorruptSequenceNumbers,
0 AS SegmentId,
0 as mSegmentStatusId,
0 AS mSegmentId,
'' AS SegmentOrigin,
PME.ProjectId
into #errorList  
from ProjectMigrationException PME WITH(NOLOCK) 
WHERE PME.ProjectId = @PProjectId     
AND PME.CustomerId = @PCustomerId     
AND ISNULL(PME.IsResolved,0) = 0;    
     
UPDATE e
set e.Section=CONCAT(PS.SourceTag, ':' ,PS.Author),
	e.SectionName=COALESCE(PS.[Description],'')
	from #errorList e INNER JOIN ProjectSection PS WITH(NOLOCK) 
	ON e.SectionId = PS.SectionId 
	AND e.ProjectId = PS.ProjectId 
	WHERE PS.ProjectId = @PProjectId     
AND PS.CustomerId = @PCustomerId 

-- set Sequence Number      
update e 
set e.SequenceNumber = CAST(PSS.SequenceNumber AS INT)    ,
	e.mSegmentId=pss.mSegmentId,
	e.mSegmentStatusId=pss.mSegmentStatusId,
	e.SegmentId=pss.SegmentId,
	e.SegmentOrigin=pss.SegmentOrigin
from #errorList as e join ProjectSegmentStatus as PSS WITH(NOLOCK) ON
e.SectionId = PSS.SectionId and e.SegmentStatusId = PSS.SegmentStatusId
WHERE PSS.ProjectId = @PProjectId --AND e.SegmentStatusId IS NOT NULL;

-- set hasCorruptSequenceNumbers Flag
select DISTINCT SectionId, CAST(0 as BIT) AS HasCorruptSequenceNumbers into #seqNumIssue from #errorList;    
    
update s 
set HasCorruptSequenceNumbers = 1     
from #seqNumIssue as s join ProjectSegmentStatus as pss WITH(NOLOCK) ON    
s.SectionId = pss.SectionId and PSS.ProjectId = @ProjectId    
WHERE PSS.ProjectId = @ProjectId and pss.SegmentId is null and SegmentSource= 'U';    
    
update e 
set e.HasCorruptSequenceNumbers = s.HasCorruptSequenceNumbers
from #errorList as e join #seqNumIssue as s WITH(NOLOCK) ON     
e.SectionId = s.SectionId;    
      
UPDATE t
SET t.segmentDescription1 = dbo.[fnGetSegmentDescriptionTextForChoice](t.SegmentStatusId)
FROM #errorList t

UPDATE t
SET t.segmentDescription1 = REPLACE(dbo.[fnGetSegmentDescriptionTextForRSAndGT](@ProjectId, @CustomerId, segmentDescription1),'{\rs\#', '{rs#')
FROM #errorList t


SELECT *,segmentDescription1 AS segmentDescription 
from #errorList order by sectionId
   
END; 
GO
Print '57. usp_GetMigratedProjectErrorsList'
Go

CREATE OR ALTER PROCEDURE usp_GetMigratedProjectsList  
(    
 @CustomerId INT,    
 @IsOfficeMaster BIT=0,    
 @IsSystemManaget BIT=1,    
 @PageNumber  INT=1,    
 @PageSize  INT=25,    
 @SearchText  NVARCHAR(50)=''    
)    
AS    
BEGIN    
 DECLARE @TRUE BIT=1,@FALSE BIT=0    
 select CONVERT(BIGINT,P.ProjectId) as ArchiveProjectId,P.ProjectId as SLC_ProdProjectId,     
 ISNULL(p.CreateDate,'') as MigratedDate,
 ISNULL(ModifiedDate,'') AS LastModifiedDate,    
 [NAME] AS ProjectName,
 ISNULL(CreatedBy,0) as SLC_UserId,
 ISNULL(p.CustomerId,0) as SlcCustomerId,    
 @FALSE AS HasErrors,
 0 AS PDFGenerationStatusId,
 NULL AS PDFFileNameAndPath,   
 ISNULL(PS.ProjectAccessTypeId,1) AS  ProjectAccessTypeId
 INTO #TEMP from Project P WITH(NOLOCK)    
 Left Join ProjectSummary PS
 ON P.ProjectId = PS.ProjectId
 where P.CustomerId=@CustomerId AND Isnull(p.isDeleted,0)=0 and P.IsShowMigrationPopup=1    
 and ISNULL(p.IsArchived,0)=0  AND ISNULL(p.IsOfficeMaster,0)=@IsOfficeMaster  

    
 SELECT distinct e.ProjectId into #errorList     
 from ProjectMigrationException e WITH(NOLOCK)    
 INNER JOIN #TEMP t     
 ON t.SLC_ProdProjectId=e.ProjectId    
 WHERE ISNULL(e.IsResolved,0)=0
    
 UPDATE t    
 set t.HasErrors=@TRUE    
 FROM #TEMP t inner join #errorList e    
 ON t.SLC_ProdProjectId=e.ProjectId    
 SELECT * FROM #TEMP    
END
GO
Print '58. usp_GetMigratedProjectsList'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_GetProjectAndSectionData]       
  ( 
  @ProjectId INT ,                               
  @SectionId INT 
  )                                                       
AS                                
BEGIN

  SELECT   
 PS.SectionId  As SectionId 
 ,PS.mSectionId  As mSectionId 
 ,PS.ParentSectionId  As ParentSectionId 
 ,PS.ProjectId  AS ProjectId 
 ,PS.CustomerId  AS CustomerId ,
 PS.TemplateId  As TemplateId
 ,PS.DivisionId  As DivisionId
 ,PS.DivisionCode  AS DivisionCode
 ,PS.Description  AS Description
 ,PS.LevelId  As LeveId
 ,PS.IsLastLevel  As IsLastLevel
 ,PS.SourceTag  As SourceTagFormat
 ,PS.Author  AS Author
 ,PS.CreatedBy As CreatedBy 
 ,PS.CreateDate  As CreateDate
 ,PS.ModifiedBy  AS ModifiedBy
 ,PS.ModifiedDate  As ModifiedDate
 ,PS.SectionCode  As SectionCode
 ,PS.IsLocked  AS IsLocked
 ,PS.LockedBy  AS LockedBy 
 ,PS.FormatTypeId AS FormatTypeId    
 INTO #ProjectSections  
 FROM ProjectSection PS WITH (NOLOCK)  
 WHERE PS.ProjectId = @ProjectId   
 ANd PS.SectionId = @SectionId 
 AND ISNULL(PS.IsDeleted,0) = 0  

 SELECT
  p.ProjectId As ProjectId,
  p.ProjectId As Id,
  P.Name As Name ,
  --P.Name As description ,
  P.Description As Description
 ,P.IsOfficeMaster As IsOfficeMaster ,
 P.TemplateId As ProjectTemplateId ,
 P.MasterDataTypeId As MasterDataTypeId ,
 P.CreateDate As ProjectCreateDate ,
 P.CreatedBy AS ProjectCreatedBy ,
 P.ModifiedBy As ProjectModifiedBy ,
 P.ModifiedDate As ProjectModifiedDate ,
 P.UserId AS UserId,
  P.CustomerId As CustomeRId 

  INTO #ProjectData
  from #ProjectSections PSS WITH (NOLOCK) 
 INNER JOIN Project P  WITH (NOLOCK) ON 
 p.ProjectId = PSS.ProjectId and 
 p.CustomerId = PSS.CustomerId 
where P.ProjectId = @ProjectId  and PSS.SectionId =  @SectionId
 
SELECT * from #ProjectSections WITH (NOLOCK)
SELECT * from #ProjectData WITH (NOLOCK)

END
GO
Print '59. [usp_GetProjectAndSectionData]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_GetProjectCountDetails]        
  @CustomerId INT NULL                                
 ,@UserId INT NULL = NULL                                                          
 ,@IsOfficeMasterTab BIT NULL = false                                                                
AS                                
BEGIN 

 DECLARE @allProjectCount AS INT = 0; 
 DECLARE @PCustomerId AS INT = 0; 
 DECLARE @PIsOfficeMasterTab BIT = @IsOfficeMasterTab;                              
  DECLARE @officeMasterCount AS INT = 0; 


 SET @allProjectCount = (Select Count(*) from  Project  WITH (NOLOCK) where CustomerId =@CustomerId and IsOfficeMaster = 0 and ISNULL(IsDeleted,0) = 0 and IsArchived = 0)                              
SET @officeMasterCount = (Select Count(*) from Project  WITH (NOLOCK)  where CustomerId =@CustomerId and IsOfficeMaster = 1  and ISNULL(IsDeleted,0) = 0 and IsArchived = 0)                        
                          
 
select @allProjectCount As TotalProjectCount ,
   @officeMasterCount As OfficeMasterCount

  END 
  GO
  Print '60. [usp_GetProjectCountDetails]'
Go

 CREATE OR ALTER PROCEDURE [dbo].[usp_GetProjectExportList]            
(                  
 @CustomerId INT,  
 @UserId INT = 0         
)                  
AS                  
BEGIN          
  
DECLARE @PCustomerId INT=@CustomerId,  
     @PUserId INT =@UserId  
  
SELECT  
 PE.ProjectExportId  
   ,PE.FileName  
   ,PE.ProjectId  
   ,PE.FilePath  
   ,PE.FileFormatType  
   ,LPET.ProjectExportTypeId   
   ,PE.ExprityDate  
   ,PE.IsDeleted  
   ,PE.CreatedDate  
   ,PE.CreatedBy  
   ,PE.CreatedByFullName  
   ,PE.ModifiedDate  
   ,PE.ModifiedBy  
   ,PE.ModifiedByFullName  
   ,LFET.FileExportTypeId  
   ,LPET.Name AS ProjectExportType  
   ,LFET.Name AS FileExportType  
   ,PE.CustomerId  
   ,PE.ProjectName  
   ,PE.FileStatus  
  
FROM ProjectExport PE WITH (NOLOCK)  
INNER JOIN LuProjectExportType LPET WITH (NOLOCK)  
 ON PE.ProjectExportTypeId = LPET.ProjectExportTypeId  
INNER JOIN LuFileExportType LFET WITH (NOLOCK)  
 ON PE.FileExportTypeId = LFET.FileExportTypeId  
WHERE CustomerId = @PCustomerId  
AND IsDeleted = 0 AND PE.CreatedBy = @PUserId  
ORDER BY CreatedDate DESC         
          
END
GO
Print '61. [usp_GetProjectExportList]'
Go

CREATE OR ALTER PROCEDURE usp_GetProjectGlobalTerm    
(  
 @ProjectId INT,    
 @CustomerId INT  
)    
AS    
BEGIN    
 SELECT    
    GlobalTermId,    
    COALESCE(mGlobalTermId, 0) AS mGlobalTermId,    
    [Name],    
    ISNULL([Value], '') AS [Value],    
    ISNULL(OldValue, '') AS OldValue,    
    CreatedDate,  
    CreatedBy,    
    COALESCE(ModifiedDate, NULL) AS ModifiedDate,    
    COALESCE(ModifiedBy, 0) AS ModifiedBy,    
    GlobalTermSource,    
    GlobalTermCode,    
    COALESCE(UserGlobalTermId, 0) AS UserGlobalTermId,    
    ISNULL(GlobalTermFieldTypeId, 1) AS GlobalTermFieldTypeId    
 FROM    
    ProjectGlobalTerm WITH (NOLOCK)    
 WHERE    
    ProjectId = @ProjectId    
    AND CustomerId = @CustomerId    
    AND isnull(IsDeleted,0) = 0     
 ORDER BY [Name]  
    
END
GO
Print '62. usp_GetProjectGlobalTerm'
Go

CREATE OR ALTER PROCEDURE usp_GetProjectSectionHyperLinks
(  
	@ProjectId INT,    
	@SectionId INT    
)
AS    
BEGIN    
	SET NOCOUNT ON;  

	--FETCH HYPERLINKS FROM PROJECT DB    
	SELECT    
	   HLNK.HyperLinkId,    
	   HLNK.LinkTarget,    
	   HLNK.LinkText,    
	   'U' AS Source    
	FROM ProjectHyperLink HLNK WITH (NOLOCK)    
	WHERE HLNK.ProjectId = @ProjectId AND HLNK.SectionId = @SectionId;

END
GO
Print '63. usp_GetProjectSectionHyperLinks'
Go

CREATE OR ALTER PROCEDURE usp_GetProjectSections  
 @ProjectId INT,  
 @SectionId INT,  
 @CustomerId INT  
AS  
BEGIN  
  
 SET NOCOUNT ON;  
  
 DECLARE @PProjectId INT = @ProjectId;                    
 DECLARE @PSectionId INT = @SectionId;                    
 DECLARE @PCustomerId INT = @CustomerId;                    
  
 DECLARE @MasterDataTypeId INT;                    
 SELECT @MasterDataTypeId = P.MasterDataTypeId FROM Project P WITH (NOLOCK) WHERE P.ProjectId = @PProjectId;  
  
 DECLARE @SourceTagFormat NVARCHAR(500);  
 SELECT @SourceTagFormat = SourceTagFormat FROM ProjectSummary PS WITH (NOLOCK) WHERE PS.ProjectId = @PProjectId;  
  
 DROP TABLE IF EXISTS #Sections  
  
 CREATE TABLE #Sections  
 (  
  [Description] NVARCHAR(500) NULL,  
  Author NVARCHAR(500) NULL,  
  SectionCode INT NULL,     
  SourceTag  NVARCHAR(10) NULL,                              
  mSectionId  INT NULL,                      
  SectionId  INT NULL,                    
  IsDeleted  BIT NULL  
 )  
                 
 --Insert ProjectSection records  
 INSERT INTO #Sections  
 ([Description], Author, SectionCode,SourceTag,mSectionId,SectionId, IsDeleted)  
 SELECT                    
  S.[Description]                    
    ,S.Author                    
    ,S.SectionCode                    
    ,S.SourceTag                            
    ,S.mSectionId                    
    ,S.SectionId                    
    ,S.IsDeleted  
 FROM ProjectSection AS S WITH (NOLOCK)                    
 WHERE S.ProjectId = @PProjectId                    
 AND S.CustomerId = @PCustomerId                 
           
 --Insert MasterSections records missing in ProjectSection  
 INSERT INTO #Sections    
 ([Description], Author, SectionCode,SourceTag,mSectionId,SectionId, IsDeleted)  
  SELECT                    
   MS.[Description]                    
  ,MS.Author                    
  ,MS.SectionCode                    
  ,MS.SourceTag                  
  ,MS.SectionId AS mSectionId                    
  ,0 AS SectionId                    
  ,MS.IsDeleted                    
  FROM SLCMaster..Section MS WITH (NOLOCK)               
  LEFT JOIN #Sections TMP WITH (NOLOCK)                    
   ON MS.SectionCode = TMP.SectionCode                    
  WHERE MS.MasterDataTypeId = @MasterDataTypeId                    
  AND MS.IsLastLevel = 1                    
  AND TMP.SectionId IS NULL;  
  
 -- Fetch All Project Sections  
 SELECT  
  S.[Description]                    
    ,S.Author                    
    ,S.SectionCode                    
    ,S.SourceTag  
    ,@SourceTagFormat AS SourceTagFormat                            
    ,S.mSectionId                    
    ,S.SectionId                    
    ,S.IsDeleted  
 FROM #Sections S;  
  
 DROP TABLE #Sections;  
  
  
END
GO
Print '64. usp_GetProjectSections'
Go

CREATE OR ALTER PROCEDURE usp_GetProjectSectionUserTag
(  
@ProjectId INT = 0,    
@CustomerId INT = 0,    
@SectionId  INT = 0   
)    
AS BEGIN    
  
SET NOCOUNT ON;  
   --FETCH SEGMENT USER TAGS LIST    
SELECT    
   PSUT.SegmentUserTagId,    
   PSUT.SegmentStatusId,    
   PSUT.UserTagId,    
   PUT.TagType,    
   PUT.Description AS TagName    
FROM    
   ProjectSegmentUserTag PSUT WITH (NOLOCK)    
   INNER JOIN ProjectUserTag PUT WITH (NOLOCK) ON PSUT.UserTagId = PUT.UserTagId    
WHERE    
   PSUT.ProjectId = @ProjectId    
   AND PSUT.CustomerId = @CustomerId    
   AND PSUT.SectionId = @SectionId    
END
GO
Print '65. usp_GetProjectSectionUserTag'
Go

CREATE OR ALTER PROCEDURE usp_GetProjectSegmentImage    
(  
	@SectionId INT  
)  
As    
BEGIN    
  
SET NOCOUNT ON;  
--FETCH REQUIRED IMAGES FROM DB    
SELECT    
   PSI.SegmentImageId,    
   IMG.ImageId,    
   IMG.ImagePath,    
   ISNULL(PSI.ImageStyle, '') AS ImageStyle    
FROM    
   ProjectSegmentImage PSI WITH (NOLOCK)    
   INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PSI.ImageId = IMG.ImageId    
WHERE    
   PSI.SectionId = @SectionId    
   AND IMG.LuImageSourceTypeId = 1    
    
END
GO
Print '66. usp_GetProjectSegmentImage'
Go

CREATE OR ALTER PROCEDURE usp_GetProjectSummary
(  
 @ProjectId INT  
)  
AS  
BEGIN  
SET NOCOUNT ON    
   SELECT   
   PS.ProjectId,    
   PS.IsIncludeRsInSection,    
   PS.IsIncludeReInSection,    
   ISNULL(PS.IsPrintReferenceEditionDate, 0) AS IsPrintReferenceEditionDate    
   FROM ProjectSummary PS WITH (NOLOCK)    
   WHERE PS.ProjectId = @ProjectId    
END
GO
Print '67. usp_GetProjectSummary'
Go

CREATE OR ALTER PROCEDURE usp_GetProjectTemplateStyle  
@ProjectId INT,  
@SectionId INT,  
@CustomerId INT  
AS  
BEGIN  
SET NOCOUNT ON;  
  
--FIND TEMPLATE ID FROM                       
DECLARE @ProjectTemplateId AS INT = (SELECT TOP 1 ISNULL(TemplateId, 1) FROM Project WITH (NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId);                    
DECLARE @SectionTemplateId AS INT = ( SELECT TOP 1 TemplateId FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @SectionId);  
DECLARE @DocumentTemplateId INT = 0;  
                    
IF (@SectionTemplateId IS NOT NULL AND @SectionTemplateId > 0)                    
 BEGIN                    
  SET @DocumentTemplateId = @SectionTemplateId;  
 END                      
ELSE                      
 BEGIN                    
  SET @DocumentTemplateId = @ProjectTemplateId;                    
 END       
----GET TEMPLATE  
SELECT                   
 TemplateId                    
   ,Name                    
   ,TitleFormatId                    
   ,SequenceNumbering                    
   ,IsSystem                    
   ,IsDeleted                    
   ,ISNULL(@ProjectTemplateId, 0) AS ProjectTemplateId                    
   ,ISNULL(@SectionTemplateId, 0) AS SectionTemplateId       
   ,ApplyTitleStyleToEOS              
FROM Template WITH (NOLOCK)                    
WHERE TemplateId = @DocumentTemplateId;  
  
----GET TEMPLATE STYLE  
SELECT                    
 TemplateStyleId                    
   ,TemplateId                    
   ,StyleId                    
   ,Level                    
FROM TemplateStyle WITH (NOLOCK)                    
WHERE TemplateId = @DocumentTemplateId;     
  
----GET  STYLE  
SELECT  
   ST.StyleId,  
   ST.Alignment,  
   ST.IsBold,  
   ST.CharAfterNumber,  
   ST.CharBeforeNumber,  
   ST.FontName,  
   ST.FontSize,  
   ST.HangingIndent,  
   ST.IncludePrevious,  
   ST.IsItalic,  
   ST.LeftIndent,  
   ST.NumberFormat,  
   ST.NumberPosition,  
   ST.PrintUpperCase,  
   ST.ShowNumber,  
   ST.StartAt,  
   ST.Strikeout,  
   ST.Name,  
   ST.TopDistance,  
   ST.Underline,  
   ST.SpaceBelowParagraph,  
   ST.IsSystem,  
   ST.IsDeleted,  
   CAST(TST.Level AS INT) AS Level  
FROM  
   Style AS ST WITH (NOLOCK)  
   INNER JOIN TemplateStyle AS TST WITH (NOLOCK)   
   ON ST.StyleId = TST.StyleId  
WHERE TST.TemplateId = @DocumentTemplateId;  
  
END  
GO
Print '68. usp_GetProjectTemplateStyle'
Go

CREATE OR ALTER PROCEDURE usp_GetSegmentMappingData
(  
 @ProjectId INT,  
 @SectionId INT,   
 @CustomerId INT  
)  
AS  
BEGIN  
  
 EXEC usp_GetProjectSections @ProjectId, @SectionId, @CustomerId  
 EXEC usp_GetProjectSectionUserTag @ProjectId, @CustomerId, @SectionId  
 EXEC usp_GetProjectSectionHyperLinks @ProjectId, @SectionId  
 EXEC usp_GetProjectSegmentImage @SectionId  
 EXEC usp_GetProjectTemplateStyle @ProjectId, @SectionId, @CustomerId  
 EXEC usp_GetProjectGlobalTerm @ProjectId, @CustomerId  
 EXEC usp_GetProjectSummary @ProjectId
  
END
GO
Print '69. usp_GetSegmentMappingData'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_GetSegmentsForPrintPDF] (                  
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
 FROM SLCMaster..Note MN  WITH (NOLOCK)  
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK)  
ON MN.SegmentStatusId = PSS.mSegmentStatusId   
/*End - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/    
END
GO
Print '70. [usp_GetSegmentsForPrintPDF]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_GetSegmentsForSection]
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
	DECLARE @MasterSectionId AS INT;    
	DECLARE @SectionTemplateId AS INT;    
	--SET @MasterSectionId = (SELECT TOP 1 mSectionId FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSectionId);        
                            
	DECLARE @MasterDataTypeId INT;    
	DECLARE @ProjectTemplateId AS INT;                        
	--SET @MasterDataTypeId = (SELECT TOP 1 MasterDataTypeId FROM Project WITH (NOLOCK) WHERE ProjectId = @PProjectId);         
	SELECT TOP 1 @MasterDataTypeId = MasterDataTypeId, @ProjectTemplateId = ISNULL(TemplateId, 1) FROM Project WITH (NOLOCK) WHERE ProjectId = @PProjectId    
        
	--FIND TEMPLATE ID FROM                             
	--DECLARE @ProjectTemplateId AS INT = (SELECT TOP 1 ISNULL(TemplateId, 1) FROM Project WITH (NOLOCK) WHERE ProjectId = @PProjectId);                          
	--DECLARE @SectionTemplateId AS INT = ( SELECT TOP 1 TemplateId FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSectionId);        
	SELECT TOP 1  @MasterSectionId = mSectionId, @SectionTemplateId = TemplateId FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSectionId;        
	DECLARE @DocumentTemplateId INT = 0;        
                          
	IF (@SectionTemplateId IS NOT NULL AND @SectionTemplateId > 0)                          
	 BEGIN                          
	  SET @DocumentTemplateId = @SectionTemplateId;        
	 END                            
	ELSE                            
	 BEGIN                          
	  SET @DocumentTemplateId = @ProjectTemplateId;                          
	 END                      
                          
	--CatalogueTypeTbl table                          
	DECLARE @CatalogueTypeTbl TABLE (TagType NVARCHAR(MAX));        
                          
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
             
	BEGIN -- Data Mapping SP's              
	 EXECUTE usp_MapSegmentStatusFromMasterToProject @ProjectId = @PProjectId                          
		  ,@SectionId = @PSectionId                          
		  ,@CustomerId = @PCustomerId                          
		  ,@UserId = @PUserId;                          
	 EXECUTE usp_MapSegmentChoiceFromMasterToProject @ProjectId = @PProjectId                          
		  ,@SectionId = @PSectionId                          
		  ,@CustomerId = @PCustomerId                          
		  ,@UserId = @PUserId;                          
	 EXECUTE usp_MapProjectRefStands @ProjectId = @PProjectId                          
		 ,@SectionId = @PSectionId                          
		 ,@CustomerId = @PCustomerId                          
		 ,@UserId = @PUserId;                          
	 EXECUTE usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @PProjectId                          
		 ,@SectionId = @PSectionId                          
		 ,@CustomerId = @PCustomerId                          
		 ,@UserId = @PUserId;       
	 EXECUTE usp_MapSegmentLinkFromMasterToProject @ProjectId = @PProjectId                        
		,@SectionId = @PSectionId                          
		,@CustomerId = @PCustomerId                          
		,@UserId = @PUserId;                          
	 EXECUTE usp_UpdateSegmentStatus_ApplyMasterUpdate @ProjectId = @PProjectId                          
		 ,@CustomerId = @PCustomerId                          
		 ,@SectionId = @PSectionId                          
	 EXECUTE usp_DeleteSegmentRequirementTag_ApplyMasterUpdate @ProjectId = @PProjectId                          
		   ,@CustomerId = @PCustomerId                          
		   ,@SectionId = @PSectionId                
	END    
    
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
	   ,CONVERT(nvarchar(2),trim(PSS.SegmentOrigin)) as SegmentOrigin              
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
                      
	SELECT    
	 SegmentStatusId    
	,ParentSegmentStatusId    
	,mSegmentStatusId    
	,mSegmentId    
	,SegmentId    
	,SegmentSource    
	,SegmentOrigin    
	,IndentLevel    
	,MasterIndentLevel    
	,SequenceNumber    
	,SegmentStatusTypeId    
	,SegmentStatusCode    
	,IsParentSegmentStatusActive    
	,IsShowAutoNumber    
	,FormattingJson    
	,TagType    
	,SpecTypeTagId    
	,IsRefStdParagraph    ,IsPageBreak    
	,IsDeleted    
	,MasterSpecTypeTagId    
	,MasterParentSegmentStatusId    
	,IsMasterSpecTypeTag    
	,TrackOriginOrder    
	,MTrackDescription    
	FROM #ProjectSegmentStatus ORDER BY SequenceNumber;    
                      
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
	 --WHERE PSST.ProjectId = @PProjectId                      
	 --AND PSST.CustomerId = @PCustomerId                      
	 --AND PSST.SectionId = @PSectionId                      
	 --AND ISNULL(PSST.IsDeleted, 0) = 0                      
	 UNION ALL                      
	 SELECT                      
	  MSG.SegmentId                      
		,PST.SegmentStatusId                      
		,PST.SectionId                      
		,CASE WHEN PST.ParentSegmentStatusId = 0 AND PST.SequenceNumber = 0 THEN PS.Description ELSE ISNULL(MSG.SegmentDescription, '') END AS SegmentDescription                      
		,MSG.SegmentSource                      
		,MSG.SegmentCode                      
	 FROM #ProjectSegmentStatus AS PST WITH (NOLOCK)                      
	 INNER JOIN ProjectSection AS PS WITH (NOLOCK)                      
	  ON PST.SectionId = PS.SectionId                      
	 INNER JOIN SLCMaster.dbo.Segment AS MSG WITH (NOLOCK)                      
	  ON PST.mSegmentId = MSG.SegmentId                      
	 --WHERE PST.ProjectId = @PProjectId                      
	 --AND PST.CustomerId = @PCustomerId                      
	 --AND PST.SectionId = @PSectionId                      
	 --AND ISNULL(PST.IsDeleted, 0) = 0    
	 ) AS X    
                          
	--NOTE -- Need to fetch distinct SelectedChoiceOption records                            
	DROP TABLE IF EXISTS #SelectedChoiceOptionTemp                          
	SELECT DISTINCT                          
	 SCHOP.SegmentChoiceCode                          
	   ,SCHOP.ChoiceOptionCode                          
	   ,SCHOP.ChoiceOptionSource                          
	   ,SCHOP.IsSelected                          
	   ,SCHOP.ProjectId                          
	   ,SCHOP.SectionId                          
	   ,SCHOP.CustomerId                          
	   ,0 AS SelectedChoiceOptionId                          
	   ,SCHOP.OptionJson     
	INTO #SelectedChoiceOptionTemp                          
	FROM SelectedChoiceOption SCHOP WITH (NOLOCK)                          
	WHERE SCHOP.SectionId = @PSectionId                   
	AND SCHOP.ProjectId = @PProjectId                                             
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
	FROM #ProjectSegmentStatus PSST WITH (NOLOCK)            
	INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK)            
	 ON PSST.mSegmentId = MCH.SegmentId            
	INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)            
	 ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId            
	INNER JOIN #SelectedChoiceOptionTemp PSCHOP WITH (NOLOCK)            
	 ON MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode            
	  AND PSCHOP.ChoiceOptionSource = 'M'            
	  AND PSCHOP.ProjectId = @PProjectId            
	  AND PSCHOP.SectionId = @PSectionId            
	WHERE     
	MCH.SectionId = @MasterSectionId    
	AND PSST.ProjectId = @PProjectId            
	AND PSST.SectionId = @PSectionId            
	AND PSST.CustomerId = @PCustomerId            
	AND ISNULL(PSST.IsDeleted, 0) = 0            
	UNION ALL            
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
	FROM #ProjectSegmentStatus PSST WITH (NOLOCK)            
	INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)            
	 ON PCH.SectionId = PSST.SectionId AND PSST.SegmentId = PCH.SegmentId            
	  AND ISNULL(PCH.IsDeleted, 0) = 0            
	INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)            
	 ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId AND PCHOP.SectionId = PCH.SectionId
	  AND ISNULL(PCHOP.IsDeleted, 0) = 0            
	INNER JOIN #SelectedChoiceOptionTemp PSCHOP WITH (NOLOCK)            
	 ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode            
	  AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode            
	  AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource            
	  AND PSCHOP.ProjectId = @PProjectId            
	  AND PSCHOP.SectionId = @PSectionId            
	  AND PSCHOP.ChoiceOptionSource = 'U'            
	WHERE PCH.SectionId = @PSectionId
	AND PSST.ProjectId = @PProjectId            
	AND PSST.SectionId = @PSectionId            
	AND PSST.CustomerId = @PCustomerId            
	AND ISNULL(PSST.IsDeleted, 0) = 0                          
                         
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
	 PSRT.CustomerId = @PCustomerId    
	AND PSRT.ProjectId = @PProjectId    
	AND PSRT.SectionId = @PSectionId    
	AND ISNULL(PSRT.IsDeleted,0)=0
END   
GO
Print '71. [usp_GetSegmentsForSection]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_GetSegmentsNotesMapping]    
(
 @ProjectId INT, 
 @SectionId INT, 
 @MSectionId INT
)  
AS    
BEGIN  
	DECLARE @PProjectId INT = @ProjectId;  
	DECLARE @PSectionId INT = @SectionId;  
	DECLARE @PMSectionId INT = @MSectionId;  
	DECLARE @IsMasterSection BIT;  
  
	--SELECT @IsMasterSection = CASE WHEN mSectionId IS NULL THEN 0 ELSE 1 END FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSectionId;
	SELECT @IsMasterSection = CASE WHEN @PMSectionId IS NULL THEN 0 ELSE 1 END;

	SELECT PSS.ProjectId, PSS.SegmentStatusId, PSS.mSegmentStatusId 
	INTO #ProjectSegmentStatus
	FROM ProjectSegmentStatus PSS WITH (NOLOCK)
	WHERE PSS.ProjectId = @PProjectId AND PSS.SectionId = @PSectionId  
	AND ISNULL(PSS.IsDeleted, 0) = 0;

	SELECT MN.SegmentStatusId
	INTO #MasterNotes
	FROM SLCMaster..Note MN WITH (NOLOCK)
	WHERE MN.SectionId = @PMSectionId

	SELECT PN.SegmentStatusId
	INTO #ProjectNotes
	FROM ProjectNote PN WITH (NOLOCK)
	WHERE PN.ProjectId = @PProjectId AND PN.SectionId = @PSectionId

 
	SELECT DISTINCT
	 PSS.SegmentStatusId  
	,CASE WHEN (MN.SegmentStatusId IS NOT NULL AND @IsMasterSection = 1) THEN 1 ELSE 0 END AS HasMasterNote  
	,CASE WHEN (PN.SegmentStatusId IS NOT NULL) THEN 1 ELSE 0 END AS HasProjectNote
	FROM #ProjectSegmentStatus PSS WITH (NOLOCK)  
	LEFT JOIN #MasterNotes MN WITH (NOLOCK)  
	 ON MN.SegmentStatusId = PSS.mSegmentStatusId  
	LEFT JOIN #ProjectNotes PN WITH (NOLOCK)
	 ON PN.SegmentStatusId = PSS.SegmentStatusId

END
GO
Print '72. [usp_GetSegmentsNotesMapping]'
Go


CREATE OR ALTER PROCEDURE [dbo].[usp_GetSpecDataSectionListPDF]     
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
Print '73. [usp_GetSpecDataSectionListPDF]'
Go

CREATE OR ALTER PROCEDURE usp_getTOCReport
(                  
@ProjectId INT,                        
@CustomerId INT,            
@CatalogueType NVARCHAR(MAX)         
)
AS
BEGIN              
            
DECLARE @PProjectId INT = @ProjectId;            
DECLARE @PCustomerId INT = @CustomerId;            
DECLARE @OldKeywordFormat NVARCHAR(MAX) = '{\kw\';              
DECLARE @NewKeywordFormat NVARCHAR(MAX) = '{KW#';              
DECLARE @PCatalogueType NVARCHAR(MAX) =@CatalogueType;          
DECLARE @PCatalogueTypelIST NVARCHAR(MAX) ;   
 DECLARE @ImagSegment int =1  
 DECLARE @ImageHeaderFooter int =3  
  
DECLARE @CatalogueTypeTbl TABLE (                
 TagType NVARCHAR(MAX)                
);            
            
  SELECT @PCatalogueTypelIST=          
(CASE          
    WHEN @PCatalogueType ='OL' THEN '2'          
 WHEN @PCatalogueType ='SF' THEN '1,2'          
    ELSE '1,2,3'           
END);          
          
--CONVERT CATALOGUE TYPE INTO TABLE                
IF @PCatalogueType IS NOT NULL                
 AND @PCatalogueType != 'FS'                
BEGIN                  
INSERT INTO @CatalogueTypeTbl (TagType)                
 SELECT                
  *                
 FROM dbo.fn_SplitString(@PCatalogueTypelIST, ',');             
 END          
  
--SELECT SEGMENT MASTER TAGS DATA                     
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
   ,PSST.SectionId INTO #MasterTagList            
FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)            
INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)            
 ON PSRT.RequirementTagId = LPRT.RequirementTagId            
INNER JOIN ProjectSegmentStatus AS PSST WITH (NOLOCK)            
 ON PSRT.SegmentStatusId = PSST.SegmentStatusId            
WHERE PSRT.ProjectId = @PProjectId            
AND PSRT.CustomerId = @PCustomerId            
AND PSST.ParentSegmentStatusId=0             
AND LPRT.RequirementTagId IN (2,3)--NS,NP            
            
			
--SELECT Active Section DATA                     
SELECT * INTO #ActiveSectionList            
 FROM(            
SELECT            
PSST.SegmentStatusId            
,PS.SourceTag            
,PS.Author            
,PS.SectionId            
,PS.mSectionId            
,PS.DivisionId            
,PS.Description            
,PSST.SpecTypeTagId   
,PS.ParentSectionId       
FROM ProjectSection PS WITH(NOLOCK)            
INNER JOIN ProjectSegmentStatus PSST WITH(NOLOCK)            
ON PS.SectionId = PSST.SectionId            
WHERE PS.ProjectId = @PProjectId            
AND PS.CustomerId = @PCustomerId            
AND PS.IsDeleted = 0            
AND PSST.SequenceNumber = 0            
AND PSST.IndentLevel = 0            
AND PSST.ParentSegmentStatusId = 0            
AND (PSST.IsParentSegmentStatusActive = 1 AND PSST.SegmentStatusTypeId<6)            
AND (@PCatalogueType = 'FS'                
OR PSST.SpecTypeTagId IN (SELECT * FROM @CatalogueTypeTbl))          
) AS T            
    
	  
--TOC List            
SELECT T.SegmentStatusId,T.SourceTag,T.Author,T.SectionId,ISNULL(T.mSectionId,0) as mSectionId ,DivisionId,Description,SpecTypeTagId,T.ParentSectionId INTO #TOCSectionList FROM #MasterTagList M WITH(NOLOCK)            
FULL OUTER JOIN  #ActiveSectionList T WITH(NOLOCK)            
ON T.SegmentStatusId=M.SegmentStatusId            
WHERE M.SegmentStatusId IS NULL            
ORDER BY T.SegmentStatusId            
            
----Added for to delete parent delete section CSI ticket 35671
DELETE P FROM #TOCSectionList P WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
ON PS.SectionId = P.ParentSectionId
where ISNULL(PS.IsDeleted,0)=1


SELECT * FROM #TOCSectionList WITH(NOLOCK)   ORDER BY sourcetag     

       
--Select Division For Sections who has tagged segments                        
SELECT DISTINCT              
 D.DivisionId                 ,D.DivisionCode              
   ,D.DivisionTitle              
   ,D.SortOrder              
   ,D.IsActive              
   ,D.MasterDataTypeId              
   ,D.FormatTypeId              
FROM SLCMaster..Division D WITH (NOLOCK)              
INNER JOIN ProjectSection PS WITH (NOLOCK)              
 ON PS.DivisionId = D.DivisionId              
JOIN #TOCSectionList SCTS WITH (NOLOCK)              
  ON PS.SectionId = SCTS.SectionId              
WHERE PS.ProjectId = @PProjectId              
AND PS.CustomerId = @PCustomerId              
ORDER BY D.DivisionCode            
SELECT DISTINCT              
 TemplateId INTO #TEMPLATE              
FROM Project WITH (NOLOCK)              
WHERE ProjectId = @PProjectID              
              
-- SELECT TEMPLATE STYLE DATA                        
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
   --,TSY.Level            
   ,CAST(TSY.Level as INT) as Level       
   ,ISNULL(SPS.CustomLineSpacing,0) as CustomLineSpacing  
   ,ISNULL(SPS.DefaultSpacesId,0) as  DefaultSpacesId
   ,ISNULL(SPS.BeforeSpacesId,0) as   BeforeSpacesId
   ,ISNULL(SPS.AfterSpacesId,0) as AfterSpacesId
FROM Style ST WITH (NOLOCK)            
INNER JOIN TemplateStyle TSY WITH (NOLOCK)              
 ON ST.StyleId = TSY.StyleId              
INNER JOIN #TEMPLATE T              
 ON TSY.TemplateId = COALESCE(T.TemplateId, 1)        
LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK) ON SPS.StyleId=ST.StyleId       
  
-- GET SourceTagFormat                         
SELECT              
 SourceTagFormat              
FROM ProjectSummary WITH (NOLOCK)              
WHERE ProjectId = @PProjectId;              
              
--SELECT Header/Footer information                              
IF EXISTS (SELECT              
   TOP 1 1            
  FROM Header WITH (NOLOCK)            
  WHERE ProjectId = @PProjectId              
  AND CustomerId = @PCustomerId              
  AND DocumentTypeId = 3)              
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
   ,H.IsShowLineBelowHeader AS   IsShowLineBelowHeader         
FROM Header H  WITH (NOLOCK)            
WHERE H.ProjectId = @PProjectId              
AND H.CustomerId = @PCustomerId              
AND H.DocumentTypeId = 3             
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
   ,H.IsShowLineBelowHeader AS   IsShowLineBelowHeader   
FROM Header H  WITH (NOLOCK)            
WHERE H.ProjectId IS NULL              
AND H.CustomerId IS NULL              
AND H.SectionId IS NULL              
AND H.DocumentTypeId = 3              
END              
IF EXISTS (SELECT              
   TOP 1 1              
  FROM Footer WITH (NOLOCK)             
  WHERE ProjectId = @PProjectId              
  AND CustomerId = @PCustomerId              
  AND DocumentTypeId = 3)              
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
   ,F.IsShowLineBelowFooter AS   IsShowLineBelowFooter         
              
FROM Footer F WITH (NOLOCK)              
WHERE F.ProjectId = @PProjectId              
AND F.CustomerId = @PCustomerId              
AND F.DocumentTypeId = 3              
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
   ,F.IsShowLineBelowFooter AS   IsShowLineBelowFooter         
                      
FROM Footer F  WITH (NOLOCK)            
WHERE F.ProjectId IS NULL              
AND F.CustomerId IS NULL              
AND F.SectionId IS NULL              
AND F.DocumentTypeId = 3              
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
  
--SELECT IMAGES DATA       
 SELECT         
  PIMG.SegmentImageId        
 ,IMG.ImageId        
 ,IMG.ImagePath        
 ,PIMG.ImageStyle        
 ,PIMG.SectionId         
 ,IMG.LuImageSourceTypeId         
 FROM ProjectSegmentImage PIMG WITH (NOLOCK)              
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PIMG.ImageId = IMG.ImageId                        
 WHERE PIMG.ProjectId = @PProjectId              
  AND PIMG.CustomerId = @PCustomerId              
  AND IMG.LuImageSourceTypeId IN(@ImagSegment,@ImageHeaderFooter)     
END  
GO
Print '74. usp_getTOCReport'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_GetTrackChangeDetails]  
(    
 @ProjectId  int,  
 @SectionId int,  
 @CustomerId int,  
 @UserId int = null
)    
AS    
BEGIN

	DECLARE @TcModeBySection TINYINT = 3;
	SELECT ISNULL(TrackChangesModeId, @TcModeBySection) AS TrackChangesModeId 
	FROM ProjectSummary WITH(NOLOCK) WHERE ProjectId = @ProjectId;

	SELECT  
	 IsTrackChanges  
	,IsTrackChangeLock  
	,COALESCE(TrackChangeLockedBy, 0) AS TrackChangeLockedBy
	FROM ProjectSection WITH(NOLOCK)  
	WHERE ProjectId = @ProjectId  
	AND SectionId = @SectionId  
	AND CustomerId = @CustomerId

END
GO
Print '75. [usp_GetTrackChangeDetails]'
Go

CREATE OR ALTER PROCEDURE [dbo].[usp_LockUnlockTrackChanges]  
( 
 @SectionId int,
 @IsTrackChanges bit,  
 @IsTrackChangeLock bit,    
 @UserId int = 0
)
AS    
BEGIN
    
	UPDATE PS  
	SET PS.IsTrackChanges = @IsTrackChanges,
		PS.IsTrackChangeLock = @IsTrackChangeLock,
	    PS.TrackChangeLockedBy = @UserId
	FROM ProjectSection PS WITH (NOLOCK)  
	WHERE PS.SectionId = @SectionId
  
	SELECT IsTrackChanges  
		   ,IsTrackChangeLock  
		   ,COALESCE(TrackChangeLockedBy, 0) AS TrackChangeLockedBy  
	FROM ProjectSection WITH (NOLOCK)  
	WHERE SectionId = @SectionId 
  
END
GO
Print '76. [usp_LockUnlockTrackChanges]'
Go

       
CREATE OR ALTER PROCEDURE usp_MarkProjectMigrationErrorAsResolved            
(            
 @MigrationExceptionId INT,           
 @UserId INT            
)            
AS            
BEGIN 

DECLARE @PMigrationExceptionId INT = @MigrationExceptionId;      
DECLARE @PUserId INT =@UserId;

 UPDATE p            
 set p.IsResolved=1,          
     p.ModifiedBy = @PUserId,        
 p.ModifiedDate = GETUTCDATE()          
 from ProjectMigrationException p WITH(NOLOCK)            
 where p.MigrationExceptionId=@PMigrationExceptionId;           
END
GO
Print '77. usp_MarkProjectMigrationErrorAsResolved'
Go

CREATE OR ALTER PROCEDURE usp_RestoreMigratedProjectFromDelete  
(  
 @CustomerId INT,  
 @ArchiveProjectId INT,  
 @UserId INT,  
 @ModifiedByFullName NVARCHAR(50)=''  
)  
AS  
BEGIN  
  
 UPDATE P  
 SET P.IsArchived=0,
	 P.IsShowMigrationPopup=0,
	 P.IsDeleted=0
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
Print '78. usp_RestoreMigratedProjectFromDelete'
Go

CREATE OR ALTER PROCEDURE usp_UnArchiveProject  
(  
 @CustomerId INT,  
 @ArchiveProjectId INT,  
 @UserId INT,  
 @ModifiedByFullName NVARCHAR(50)=''  
)  
AS  
BEGIN  
  
 UPDATE P  
 SET P.IsArchived=0,
	 P.IsShowMigrationPopup=0
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
Print '79. usp_UnArchiveProject'
Go

CREATE TYPE [dbo].[Spec360ProductOptionRequestData] AS TABLE (
    [ProductCode] VARCHAR (32)  NULL,
    [OptionName]  VARCHAR (128) NULL,
    [OptionValue] VARCHAR (128) NULL);
	GO
Print '80. type Spec360ProductOptionRequestData'
GO

-- Below sp having Error
Create OR ALTER Procedure usp_GetProductMappingDataFromProductService 
 (
 @CusetomerId int,
 @ProductOptionJson NVARCHAR(max)
 )
 as
 begin
DECLARE @ProductJsonTab Table(
ProductCode NVARCHAR(max) ,
	Options NVARCHAR(max)  ,
	RowId INT
	)
	DECLARE @Spec360ProductOptionRequestData [dbo].[Spec360ProductOptionRequestData]
INSERT INTO @ProductJsonTab
	SELECT
		*
	   ,ROW_NUMBER() OVER (ORDER BY ProductCode) AS RowId
	FROM OPENJSON(@ProductOptionJson)
	WITH (
	ProductCode NVARCHAR(MAX) '$.ProductCode',
	Options NVARCHAR(MAX) '$.Options' AS JSON
	);

DECLARE @n INT = 1;
WHILE ((SELECT
		COUNT(*)
	FROM @ProductJsonTab)
>= @n)

BEGIN
DECLARE @ProductOptionsjson NVARCHAR(MAX) = '';
DECLARE @ProductCode NVARCHAR(MAX) = '';
SELECT
	@ProductCode = ProductCode
   ,@ProductOptionsjson = Options
FROM @ProductJsonTab
WHERE RowId = @n
AND Options IS NOT NULL

IF (@ProductOptionsjson != '')
BEGIN
INSERT INTO @Spec360ProductOptionRequestData
	SELECT
		@ProductCode AS ProductCode
	   ,OptionName
	   ,OptionValue
	FROM OPENJSON(@ProductOptionsjson)
	WITH (
	Options NVARCHAR(MAX) AS JSON,
	OptionName NVARCHAR(MAX) '$.OptionName',
	OptionValue NVARCHAR(MAX) '$.OptionValue'
	);
END
SET @n = @n + 1;

 END

INSERT INTO @Spec360ProductOptionRequestData
	SELECT
		ProductCode
	   ,NULL AS OptionName
	   ,NULL AS OptionValue
	FROM @ProductJsonTab
	WHERE Options IS NULL

EXECUTE [dbo].[uspGetProductSegmentMappingData] @CusetomerId
											   ,@Spec360ProductOptionRequestData

END