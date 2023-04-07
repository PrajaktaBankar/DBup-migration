Use SLCProject
GO

PRINT N'Altering [dbo].[fnGetSegmentDescriptionTextForChoice]...';
GO
ALTER FUNCTION [dbo].[fnGetSegmentDescriptionTextForChoice]
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
		IF(@segmentDescription like '%{CH#%')
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
			select TOP 1 @segmentDescription=SegmentDescription FROM [dbo].[ProjectSegment] WITH(NOLOCK) where SegmentId=@segmentId and SectionId=@SectionId 
			
			IF(@segmentDescription like '%{CH#%')
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
PRINT N'Altering [dbo].[fnGetSegmentDescriptionTextForRSAndGT]...';


GO
ALTER FUNCTION [dbo].[fnGetSegmentDescriptionTextForRSAndGT]    
(    
 @ProjectId int,    
 @CustomerId int,    
 @segmentDescription NVARCHAR(MAX)    
)RETURNS NVARCHAR(MAX)    
AS    
BEGIN    
	IF(@segmentDescription like '%{RS#%')
	BEGIN
		SELECT @segmentDescription = REPLACE(@segmentDescription,    
		CONCAT('{RS#', CONVERT(NVARCHAR(MAX), prs.RefStdCode), '}'), rs.RefStdName)    
		FROM [dbo].[ProjectReferenceStandard] prs WITH(NOLOCK)  Inner JOIN ReferenceStandard rs WITH(NOLOCK)  
		ON prs.RefStandardId=rs.RefStdId  
		WHERE prs.ProjectId=@ProjectId and prs.CustomerId=@CustomerId  
  
		SELECT @segmentDescription = REPLACE(@segmentDescription,    
		CONCAT('{RS#', CONVERT(NVARCHAR(MAX), RefStdCode), '}'), RefStdName)    
		FROM [SLCMaster].[dbo].[ReferenceStandard] WITH(NOLOCK)    
    END 
	IF @segmentDescription LIKE '%{RSTEMP#%'    
	BEGIN    
		  DECLARE @RSCode INT = 0;    
		  SELECT @RSCode = LEFT(Val, PATINDEX('%[^0-9]%', Val + 'a') - 1)     
		  FROM (SELECT SUBSTRING(@segmentDescription, PATINDEX('%[0-9]%', @segmentDescription), LEN(@segmentDescription)) Val) RSCode    
    
		  SELECT @segmentDescription = CONCAT(RSEdition.RefStdName, ' - ', RSEdition.RefStdTitle + '; ' + RSEdition.RefEdition + '.')    
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
    
		  SELECT @segmentDescription = CONCAT(RSEdition.RefStdName, ' - ', RSEdition.RefStdTitle + '; ' + RSEdition.RefEdition + '.')    
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
  
    IF(@segmentDescription like '%{GT#%')
	BEGIN
		SELECT @segmentDescription = REPLACE(@segmentDescription,    
		CONCAT('{GT#', CONVERT(NVARCHAR(MAX), GlobalTermCode), '}'), [Value])    
		FROM [dbo].[ProjectGlobalTerm] WITH(NOLOCK)    
		WHERE ProjectId = @ProjectId    
		AND CustomerId = @CustomerId    
		AND ISNULL(IsDeleted,0) = 0    
    END
	RETURN @segmentDescription;    
END
GO
PRINT N'Altering [dbo].[udf_GetRSUsedInChoice]...';


GO
--Usage : SELECT * FROM dbo.[udf_GetRSUsedInChoice]('{RS#3228}&nbsp;{CH#10010219}&nbsp;', 12275, 5710121)
ALTER FUNCTION [dbo].[udf_GetRSUsedInChoice](
	@SegmentDescription NVARCHAR(MAX),
	@ProjectId INT,
	@SectionId INT	 
)
RETURNS  @SegmentRSTbl TABLE(RSCode INT NULL)
AS
BEGIN
	
	DECLARE @SegmentCH TABLE(ChoiceCode INT NULL);
	DECLARE @OptionJsonList TABLE(RowId INT NULL, OptionJson NVARCHAR(MAX) NULL);
	DECLARE @RSUsedInChoice TABLE(Id INT NULL, OptionTypeName NVARCHAR(50) NULL, [Value] NVARCHAR(MAX) NULL);

	INSERT INTO @SegmentCH
	SELECT DISTINCT [value] AS ChoiceCode FROM STRING_SPLIT(dbo.[udf_GetCodeFromFormat](@SegmentDescription,'{CH#'), ',')

	--INSERT INTO @OptionJsonList
	--SELECT ROW_NUMBER() OVER(ORDER BY PSC.SegmentChoiceId DESC) AS RowId, PCO.OptionJson FROM @SegmentCH SC
	--LEFT JOIN ProjectSegmentChoice PSC WITH(NOLOCK) ON SC.ChoiceCode = PSC.SegmentChoiceCode
	--INNER JOIN ProjectChoiceOption PCO WITH(NOLOCK) ON PCO.SegmentChoiceId = PSC.SegmentChoiceId
	--WHERE PCO.ProjectId = @ProjectId AND PCO.SectionId = @SectionId

	INSERT INTO @OptionJsonList
	SELECT ROW_NUMBER() OVER(ORDER BY PSC.SegmentChoiceId DESC) AS RowId, PCO.OptionJson 
	FROM ProjectSegmentChoice PSC WITH(NOLOCK) INNER JOIN ProjectChoiceOption PCO WITH(NOLOCK) 
	ON PCO.SegmentChoiceId = PSC.SegmentChoiceId 
	AND PCO.SectionId=PSC.SectionId
	inner join @SegmentCH SC
	ON PSC.SectionId=@SectionId 
	AND SC.ChoiceCode = PSC.SegmentChoiceCode
	WHERE PCO.SectionId = @SectionId AND PCO.ProjectId = @ProjectId 

	DECLARE @COUNTER INT = (SELECT MAX(RowId) FROM @OptionJsonList);
	DECLARE @OptionJson NVARCHAR(MAX) = '';
	WHILE (@COUNTER != 0)
	BEGIN
 
	 SELECT @OptionJson = OJL.OptionJson
	 FROM @OptionJsonList OJL
		WHERE OJL.RowId = @COUNTER

	 INSERT INTO @RSUsedInChoice
	 SELECT * FROM OPENJSON(@OptionJson)
	  WITH (
	  Id INT '$.Id',
	  OptionTypeName NVARCHAR(50) '$.OptionTypeName',
	  [Value] NVARCHAR(MAX) '$.Value'
	 )
	 WHERE OptionTypeName = 'ReferenceStandard'
	
	 SET @COUNTER = @COUNTER -1
	END

	INSERT INTO @SegmentRSTbl
	SELECT Id AS RSCode FROM @RSUsedInChoice

	RETURN;

END
GO
PRINT N'Altering [dbo].[usp_CreateSegmentsForImportedSection]...';


GO
ALTER PROCEDURE [dbo].[usp_CreateSegmentsForImportedSection]      
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
ELSE 
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
PRINT N'Altering [dbo].[usp_SetProjectSegemntMappingData]...';


GO
ALTER PROCEDURE [dbo].[usp_SetProjectSegemntMappingData] (@ProjectId INT,    
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
	,OptionJson nvarchar(MAX)    
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
  ,OptionJson NVARCHAR(MAX)  '$.OptionJson' 
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
 FROM ImportProjectRequest IPR  WITH (NOLOCK)   
 INNER JOIN @DistinctSectionTbl SM    
  ON IPR.TargetSectionId = SM.SectionId    
    
 DECLARE @ChoiceTableRowCount INT = (SELECT    
   COUNT(mSegmentStatusId)    
  FROM @SegmentChoiceMappingTbl)    
    
 IF (@ChoiceTableRowCount > 0)    
 BEGIN    
    
  UPDATE sco    
  SET sco.IsSelected = scmtbl.IsSelected  
  ,sco.OptionJson=CASE WHEN scmtbl.OptionJson='' THEN NULL ELSE scmtbl.OptionJson END
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
 FROM ImportProjectRequest IPR   WITH (NOLOCK) 
 INNER JOIN @DistinctSectionTbl SM    
  ON IPR.TargetSectionId = SM.SectionId    
    
END
GO
PRINT N'Altering [dbo].[usp_CreateSectionFromMasterTemplate]...';


GO
ALTER PROCEDURE [usp_CreateSectionFromMasterTemplate]                 
 @ProjectId INT, @CustomerId INT, @UserId INT, @SourceTag VARCHAR (10),                 
 @Author NVARCHAR(500), @Description NVARCHAR(500), @UserName NVARCHAR(500) = '',                
 @UserAccessDivisionId NVARCHAR(MAX) = '', @RequestId INT              
AS                  
BEGIN                
 DECLARE @PProjectId INT = @ProjectId;                
 DECLARE @PCustomerId INT = @CustomerId;                
 DECLARE @PUserId INT = @UserId;                
 DECLARE @PSourceTag VARCHAR (10) = @SourceTag;                
 DECLARE @PAuthor NVARCHAR(500) = @Author;                
 DECLARE @PDescription NVARCHAR(500) = @Description;                
 DECLARE @PUserName NVARCHAR(500) = @UserName;                
 DECLARE @PUserAccessDivisionId NVARCHAR(MAX) = @UserAccessDivisionId;                
                
--If came from UI as undefined then make it empty as it should empty                
IF @PUserAccessDivisionId = 'undefined'                
BEGIN                
SET @PUserAccessDivisionId = ''                
END                
                
--DECLARE VARIABLES                
DECLARE @DefaultTemplateSourceTag NVARCHAR(10) = '';                
--DECLARE @AlternateTemplateSourceTag NVARCHAR(MAX) = '';                
                
DECLARE @DefaultTemplateMasterSectionId INT = 0;                
DECLARE @AlternateTemplateMasterSectionId INT = 0;                
                
DECLARE @TemplateSourceTag NVARCHAR(10) = '';                
DECLARE @TemplateAuthor NVARCHAR(50) = '';                
DECLARE @TemplateMasterSectionId INT = 0;                
DECLARE @TemplateSectionId INT = 0;                
DECLARE @TemplateSectionCode INT = 0;                
                
DECLARE @SectionId INT = 0;                
DECLARE @SectionCode INT = 0;                
DECLARE @DivisionCode NVARCHAR(500) = NULL;                
DECLARE @DivisionId INT = NULL;                
DECLARE @ParentSectionId INT = 0;                
                
DECLARE @IsSuccess BIT = 1;                
DECLARE @ErrorMessage NVARCHAR(80) = '';                
DECLARE @ParentSectionIdTable TABLE (                
 ParentSectionId INT                
);                
DECLARE @IsTemplateMasterSectionOpened BIT = 0;                
                
DECLARE @BsdMasterDataTypeId INT = 1;                
DECLARE @CNMasterDataTypeId INT = 4;                
                
DECLARE @MasterDataTypeId INT = ( SELECT TOP 1                
  MasterDataTypeId                
 FROM Project WITH (NOLOCK)                
 WHERE ProjectId = @PProjectId);                
                
DECLARE @UserAccessDivisionIdTbl TABLE (                
 DivisionId INT                
);                
                
DECLARE @FutureDivisionIdOfSectionTbl TABLE (                
 DivisionId INT                
);                
                
DECLARE @FutureDivisionId INT = NULL;                
              
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
        
DECLARE  @ImportPending TINYINT =1;        
DECLARE  @ImportStarted TINYINT =2;        
DECLARE  @ImportCompleted TINYINT =3;        
DECLARE  @Importfailed TINYINT =4        
        
DECLARE @IsCompleted BIT =1;        
        
DECLARE @ImportSource Nvarchar(100)='Import From Template'        
              
                
--TEMP TABLES                
DROP TABLE IF EXISTS #tmp_SrcProjectSegmentStatus;                
DROP TABLE IF EXISTS #tmp_TgtProjectSegmentStatus;                
DROP TABLE IF EXISTS #tmp_SrcMasterNote;                
DROP TABLE IF EXISTS #tmp_TgtProjectNote;                
DROP TABLE IF EXISTS #tmp_SrcProjectSegment;                
                
BEGIN TRY                
--BEGIN TRANSACTION                
              
 --Add Logs to ImportProjectHistory                
 EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportStart_Description                            
           ,@ImportStart_Description                            
           ,@IsCompleted                            
           ,@ImportStart_Step --Step                     
     ,@RequestId;              
                
 --Add Logs to ImportProjectRequest                
 EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , null              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                         
         ,@ImportStart_Percentage --Percent                            
         , 0                
         ,@ImportSource               
         , @RequestId;               
              
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
                
--NOTE:Below condition is due to deleted master template on DEV                
--NOTE:SET Appropriate Master Template Section to be copy    
     
DECLARE @mSectionId INT = ( SELECT TOP 1                
  mSectionId                
 FROM ProjectSection PS WITH (NOLOCK)                
 WHERE ProjectId = @PProjectId  
      AND CustomerId = @CustomerId  
   AND PS.IsLastLevel = 1                
      AND ISNULL(PS.IsDeleted,0) = 0     
   AND PS.mSectionId IS NOT NULL  
   AND PS.SourceTag = @DefaultTemplateSourceTag  
   AND PS.Author = @TemplateAuthor);     
    
           
IF EXISTS (SELECT                
 TOP 1                
  1                
 FROM  SLCMaster..Section MS WITH (NOLOCK)                
 WHERE MS.SectionId = @mSectionId                           
 AND MS.IsDeleted = 0)                
BEGIN                
SET @TemplateSourceTag = @DefaultTemplateSourceTag;                
END                
     
--FETCH VARIABLE DETAILS                
SELECT                
 @TemplateSectionId = PS.SectionId                
   ,@TemplateMasterSectionId = PS.mSectionId                
   ,@TemplateSectionCode = PS.SectionCode                
--FROM Project P WITH (NOLOCK)                
FROM ProjectSection PS WITH (NOLOCK)                
 --ON P.ProjectId = PS.ProjectId                
--INNER JOIN SLCMaster..Section MS WITH (NOLOCK)                
-- ON PS.mSectionId = MS.SectionId                
-- and isnull(PS.IsDeleted,0) = isnull(MS.IsDeleted,0)                
WHERE PS.ProjectId = @PProjectId                
AND PS.CustomerId = @PCustomerId                
AND PS.IsLastLevel = 1                
--AND isnull(MS.IsDeleted,0)= 0                
AND PS.mSectionId =@mSectionId                
AND PS.SourceTag = @TemplateSourceTag                
AND PS.Author = @TemplateAuthor                
                
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
                
--CALCULATE ParentSectionId                
INSERT INTO @ParentSectionIdTable (ParentSectionId)                
EXEC usp_GetParentSectionIdForImportedSection @PProjectId                
            ,@PCustomerId                
            ,@PUserId                
            ,@PSourceTag;                
                
SELECT TOP 1                
 @ParentSectionId = ParentSectionId                
FROM @ParentSectionIdTable;                
                
--PUT USER DIVISION ID'S INTO TABLE                
INSERT INTO @UserAccessDivisionIdTbl (DivisionId)                
 SELECT                
  *                
 FROM dbo.fn_SplitString(@PUserAccessDivisionId, ',');                
                
--CALCULATE DIVISION ID OF USER SECTION WHICH IS GOING TO BE                
INSERT INTO @FutureDivisionIdOfSectionTbl (DivisionId)                
EXEC usp_CalculateDivisionIdForUserSection @PProjectId                
            ,@PCustomerId                
            ,@PSourceTag                
            ,@PUserId                
            ,@ParentSectionId                
SELECT TOP 1                
 @FutureDivisionId = DivisionId                
FROM @FutureDivisionIdOfSectionTbl;                
                
                
--PERFORM VALIDATIONS                
IF (@TemplateSourceTag = '')                
BEGIN                
SET @IsSuccess = 0;                
SET @ErrorMessage = 'No master template found.';                
              
 EXEC usp_MaintainImportProjectHistory @PProjectId                            
           ,@ImportNomastertemplatefound_Description                            
            ,@ImportNomastertemplatefound_Description                             
           ,@IsCompleted                            
           ,@ImportNomastertemplatefound_Step --Step                     
     ,@RequestId;              
 EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                    
   ,null                
  , null              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@Importfailed                         
         ,@ImportNomastertemplatefound_Percentage --Percent                            
         , 0                
    ,@ImportSource               
         , @RequestId;               
              
END                
                
ELSE IF EXISTS (SELECT TOP 1                 
  1                
 FROM ProjectSection WITH (NOLOCK)                
 WHERE ProjectId = @PProjectId                
 AND CustomerId = @PCustomerId                
 AND ISNULL(IsDeleted,0) = 0                
 AND SourceTag = TRIM(@PSourceTag)                
 AND LOWER(Author) = LOWER(TRIM(@PAuthor)))                
BEGIN                
SET @IsSuccess = 0;                
SET @ErrorMessage = 'Section already exists.';                
 EXEC usp_MaintainImportProjectHistory @PProjectId                            
           ,@ImportSectionalreadyexists_Description                            
          ,@ImportSectionalreadyexists_Description                             
           ,@IsCompleted                            
            ,@ImportSectionalreadyexists_Step --Step                     
     ,@RequestId;              
 EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
  ,null                
  , null              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@Importfailed                         
         ,@ImportSectionalreadyexists_Percentage --Percent                            
         , 0                
    ,@ImportSource                
         , @RequestId;               
END                
                
ELSE IF @ParentSectionId IS NULL OR @ParentSectionId <= 0                
BEGIN                
SET @IsSuccess = 0;                
SET @ErrorMessage = 'Section id is invalid.';                
 EXEC usp_MaintainImportProjectHistory @PProjectId                            
           ,@ImportSectionidinvalid_Description                            
           ,@ImportSectionidinvalid_Description                            
           ,@IsCompleted                            
            ,@ImportSectionidinvalid_step --Step         
     ,@RequestId;              
 EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , null              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@Importfailed                           
         ,@ImportSectionidinvalid_Percentage --Percent                            
         , 0                
    ,@ImportSource              
         , @RequestId;               
END                
                
ELSE IF  @PUserAccessDivisionId != ''                
 AND @FutureDivisionId NOT IN (SELECT                
  DivisionId                
 FROM @UserAccessDivisionIdTbl)                
BEGIN                
SET @IsSuccess = 0;                
SET @ErrorMessage = 'You don''t have access rights to import section(s) in this division';                
 EXEC usp_MaintainImportProjectHistory @PProjectId                            
           ,@NoAccessRights_Description                  
            ,@NoAccessRights_Description                                
           ,@IsCompleted                           
            ,@NoAccessRights_step --Step                     
     ,@RequestId;              
 EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , null              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@Importfailed                            
         ,@NoAccessRights_Percentage --Percent                            
         , 0                
   ,@ImportSource                
         , @RequestId;               
END                
                
ELSE                
BEGIN                
                
--INSERT INTO ProjectSection                
INSERT INTO ProjectSection (ParentSectionId, ProjectId, CustomerId, UserId,                
DivisionId, DivisionCode, Description, LevelId, IsLastLevel, SourceTag,                
Author, TemplateId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted, FormatTypeId, SpecViewModeId)                
 SELECT                
  @ParentSectionId AS ParentSectionId              
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
    ,0 AS IsDeleted                
    ,PS_Template.FormatTypeId AS FormatTypeId                
    ,PS_Template.SpecViewModeId AS SpecViewModeId                
 FROM ProjectSection PS_Template WITH (NOLOCK)                
 WHERE PS_Template.SectionId = @TemplateSectionId                
                
SET @SectionId = scope_identity()                
              
 EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectSection_Description                            
           ,@ImportProjectSection_Description                            
           ,@IsCompleted                          
           ,@ImportProjectSection_Step --Step                     
     ,@RequestId;              
                
 --Add Logs to ImportProjectRequest                
 EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                          
         ,@ImportProjectSection_Percentage --Percent                            
         , 0                
    ,@ImportSource              
         , @RequestId;               
               
--GET NEW SECTION ID                
SELECT TOP 1                
 --@SectionId = SectionId,                
   @SectionCode = SectionCode                
FROM ProjectSection WITH (NOLOCK)                
WHERE SectionId = @SectionId                 
AND ProjectId = @PProjectId                
AND CustomerId = @PCustomerId                
--AND mSectionId IS NULL                
--AND SourceTag = @PSourceTag                
--AND Author = @PAuthor                
--AND IsDeleted = 0                
                
--CALCULATE DIVISION ID AND CODE                
EXEC usp_SetDivisionIdForUserSection @PProjectId                
         ,@SectionId                
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
    ,@SectionId AS SectionId                
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
    ,@SectionId AS SectionId                
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
  , @SectionId              
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
  @SectionId AS SectionId                
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
   AND PSG.SectionId = @SectionId                
 WHERE MSST_Template.SectionId = @TemplateMasterSectionId                
 AND ISNULL(MSST_Template.IsDeleted, 0) = 0                
 AND @IsTemplateMasterSectionOpened = 0                
 UNION                
 SELECT                
  @SectionId AS SectionId                
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
   AND PSG.SectionId = @SectionId                
 WHERE PSST_Template.SectionId = @TemplateSectionId                
 AND ISNULL(PSST_Template.IsDeleted, 0) = 0                
 AND (PSST_Template_PSG.SegmentId IS NOT NULL                
 OR PSST_Template_MSG.SegmentId IS NOT NULL)                
 AND @IsTemplateMasterSectionOpened = 1                
              
              
                
--Insert target segment status into temp table of new section                
SELECT                
 * INTO #tmp_TgtProjectSegmentStatus                
FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
WHERE PSST.SectionId = @SectionId                
                
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
WHERE PSST_Child.SectionId = @SectionId                
AND PSST_Parent.SectionId = @SectionId                
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
WHERE PSST_Child.SectionId = @SectionId                
AND PSST_Parent.SectionId = @SectionId                
AND @IsTemplateMasterSectionOpened = 1                
                
--UPDATE IN ORIGINAL TABLE                
UPDATE PSST                
SET PSST.ParentSegmentStatusId = TMP.ParentSegmentStatusId                
FROM ProjectSegmentStatus PSST WITH (NOLOCK)                
INNER JOIN #tmp_TgtProjectSegmentStatus TMP WITH (NOLOCK)                
 ON PSST.SegmentStatusId = TMP.SegmentStatusId                
WHERE PSST.SectionId = @SectionId                
                
--UPDATE ProjectSegment                
UPDATE PSG                
SET PSG.SegmentStatusId = PSST.SegmentStatusId       
FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
INNER JOIN ProjectSegment PSG WITH (NOLOCK)                
 ON PSST.SegmentId = PSG.SegmentId                
WHERE PSST.SectionId = @SectionId                
                
UPDATE PSG                
SET PSG.SegmentDescription = PS.Description                
FROM #tmp_TgtProjectSegmentStatus PSST WITH (NOLOCK)                
INNER JOIN ProjectSegment PSG WITH (NOLOCK)                
 ON PSST.SegmentId = PSG.SegmentId                
INNER JOIN ProjectSection PS WITH (NOLOCK)                
 ON PSST.SectionId = PS.SectionId                
WHERE PSST.SectionId = @SectionId                
AND PSST.SequenceNumber = 0                
AND PSST.IndentLevel = 0                
                
--INSERT INTO ProjectSegmentChoice                
INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId,                
CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)                
 SELECT                
  @SectionId AS SectionId                
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
 WHERE PSST.SectionId = @SectionId                
 AND @IsTemplateMasterSectionOpened = 0                
 UNION                
 SELECT                
  @SectionId AS SectionId                
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
 WHERE PSST.SectionId = @SectionId                
 AND PSST_Template.SegmentOrigin = 'M'                
 AND @IsTemplateMasterSectionOpened = 1                
 UNION                
 SELECT                
  @SectionId AS SectionId                
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
 WHERE PSST.SectionId = @SectionId                
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
  , @SectionId              
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
    ,@SectionId AS SectionId                
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
 WHERE PSST.SectionId = @SectionId                
 AND @IsTemplateMasterSectionOpened = 0                
 UNION                
 SELECT                
  PCH.SegmentChoiceId AS SegmentChoiceId                
    ,MCHOP_Template.SortOrder AS SortOrder                
    ,'U' AS ChoiceOptionSource                
    ,MCHOP_Template.OptionJson AS OptionJson                
    ,@PProjectId AS ProjectId                
    ,@SectionId AS SectionId                
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
 WHERE PSST.SectionId = @SectionId                
 AND PSST_Template.SegmentOrigin = 'M'                
 AND @IsTemplateMasterSectionOpened = 1                
 UNION                
 SELECT                
  PCH.SegmentChoiceId AS SegmentChoiceId                
    ,PCHOP_Template.SortOrder AS SortOrder                
    ,'U' AS ChoiceOptionSource                
    ,PCHOP_Template.OptionJson AS OptionJson                
    ,@PProjectId AS ProjectId                
    ,@SectionId AS SectionId                
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
 WHERE PSST.SectionId = @SectionId                
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
  , @SectionId              
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
    ,@SectionId AS SectionId                
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
 WHERE PSST.SectionId = @SectionId                
 AND @IsTemplateMasterSectionOpened = 0                
 UNION                
 SELECT                
  MCH_Template.SegmentChoiceCode AS SegmentChoiceCode                
    ,MCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode                
    ,'U' AS ChoiceOptionSource                
    ,SCHOP_Template.IsSelected AS IsSelected                
    ,@SectionId AS SectionId                
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
 WHERE PSST.SectionId = @SectionId                
 AND PSST_Template.SegmentOrigin = 'M'                
 AND @IsTemplateMasterSectionOpened = 1                
 UNION                
 SELECT                
  PCH_Template.SegmentChoiceCode AS SegmentChoiceCode                
    ,PCHOP_Template.ChoiceOptionCode AS ChoiceOptionCode                
    ,'U' AS ChoiceOptionSource                
    ,SCHOP_Template.IsSelected AS IsSelected                
    ,@SectionId AS SectionId                
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
  , @SectionId              
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
  @SectionId AS SectionId                
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
  , @SectionId              
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
  @SectionId AS SectionId                
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
 AND PSST.SectionId = @SectionId                
 UNION                
 SELECT                
  @SectionId AS SectionId                
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
   AND PSST.SectionId = @SectionId                
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
  , @SectionId              
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
   WHEN MSLNK.SourceSectionCode = @TemplateSectionCode THEN @SectionCode                
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
   WHEN MSLNK.TargetSectionCode = @TemplateSectionCode THEN @SectionCode                
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
    WHEN PSLNK.SourceSectionCode = @TemplateSectionCode THEN @SectionCode                
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
    WHEN PSLNK.TargetSectionCode = @TemplateSectionCode THEN @SectionCode                
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
  , @SectionId              
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
  @SectionId AS SectionId                
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
 AND PSST.SectionId = @SectionId                
 AND @IsTemplateMasterSectionOpened = 0                
 UNION                
 SELECT                
  @SectionId AS SectionId                
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
   AND PSST.SectionId = @SectionId                
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
  , @SectionId              
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
    ,@SectionId AS SectionId                
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
   AND PSST.SectionId = @SectionId                
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
  , @SectionId              
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
    ,@SectionId AS SectionId                
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
   AND PSG.SectionId = @SectionId                
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
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                 
         ,@ImportProjectSegmentGlobalTerm_Percentage --Percent                            
         , 0                
    ,@ImportSource        
         , @RequestId;               
                
--INSERT INTO ProjectSegmentImage                
INSERT INTO ProjectSegmentImage (SectionId, ImageId, ProjectId, CustomerId, SegmentId)                
 SELECT                
  @SectionId AS SectionId                
    ,PSI_Template.ImageId AS ImageId                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,PSG.SegmentId AS SegmentId                
 FROM ProjectSegmentImage PSI_Template WITH (NOLOCK)                
 INNER JOIN #tmp_SrcProjectSegment PSG_Template WITH (NOLOCK)                
  ON PSI_Template.SegmentId = PSG_Template.SegmentId                
 INNER JOIN ProjectSegment PSG WITH (NOLOCK)                
  ON PSG_Template.SegmentCode = PSG.SegmentCode                
   AND PSG.SectionId = @SectionId                
 WHERE PSI_Template.SectionId = @TemplateSectionId                
 UNION                
 SELECT                
  @SectionId AS SectionId                
    ,PSI_Template.ImageId AS ImageId                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
    ,PSI_Template.SegmentId AS SegmentId                
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
  , @SectionId              
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
  @SectionId AS SectionId                
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
   AND PSST.SectionId = @SectionId                
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
WHERE SectionId = @SectionId;                
                
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
 WHERE PHL.SectionId = @SectionId;                
                
declare @HyperLinkTableRowCount INT=(SELECT                
  COUNT(*)                
 FROM @HyperLinkTable)                
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
 AND PSST.SectionId = @SectionId                
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
WHERE PNT.SectionId = @SectionId;                
                
--UPDATE PROPER CustomerId IN ProjectHyperLink                
UPDATE PHL                
SET PHL.CustomerId = @PCustomerId                
FROM ProjectHyperLink PHL WITH (NOLOCK)                
WHERE PHL.SectionId = @SectionId                
              
   EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectHyperLink_Description                            
           ,@ImportProjectHyperLink_Description                            
           ,@IsCompleted                           
           ,@ImportProjectHyperLink_Step --Step                     
     ,@RequestId;              
                  
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
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
    ,@SectionId AS SectionId                
    ,PNI_Template.ImageId AS ImageId                
    ,@PProjectId AS ProjectId                
    ,@PCustomerId AS CustomerId                
 FROM ProjectNoteImage PNI_Template WITH (NOLOCK)                
 INNER JOIN ProjectNote PN_Template WITH (NOLOCK)                
  ON PNI_Template.NoteId = PN_Template.NoteId                
 INNER JOIN ProjectNote PN WITH (NOLOCK)                
  ON PN.SectionId = @SectionId    
   AND PN_Template.NoteCode = PN.NoteCode                            
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
  , @SectionId              
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
  @SectionId AS SectionId                
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
   AND PSST.SectionId = @SectionId                
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
   AND PSST.SectionId = @SectionId                
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
   AND PSG.SectionId = @SectionId                
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
  , @SectionId              
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
    ,@SectionId AS SectionId                
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
  , @SectionId              
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
    ,@SectionId AS SectionId                
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
  , @SectionId              
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
    ,@SectionId AS SectionId                
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
   AND PSST.SectionId = @SectionId                
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
  AND PRS.SectionId = @SectionId                
  AND PRS.IsDeleted = 0) AS X                
 LEFT JOIN ProjectReferenceStandard PRS WITH (NOLOCK)                
  ON PRS.ProjectId = @PProjectId                
   AND PRS.RefStandardId = X.RefStandardId                
   AND PRS.RefStdSource = X.RefStdSource                
   AND ISNULL(PRS.mReplaceRefStdId, 0) = ISNULL(X.mReplaceRefStdId, 0)                
   AND PRS.RefStdEditionId = X.RefStdEditionId                
   AND PRS.IsObsolete = X.IsObsolete                
   AND PRS.SectionId = @SectionId                
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
  , @SectionId              
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
WHERE PSST.SectionId = @SectionId                
              
 EXEC usp_MaintainImportProjectHistory @PProjectId                           
           ,@ImportProjectSegmentStatus_Description                            
           ,@ImportProjectSegmentStatus_Description                            
           ,@IsCompleted                   
           ,@ImportProjectSegmentStatus_Step --Step                     
     ,@RequestId;              
             
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId              
         ,@PUserId                            
         ,@PCustomerId                            
         ,@ImportStarted                    
         ,@ImportProjectSegmentStatus_Percentage --Percent                            
         , 0                
   ,@ImportSource          
         , @RequestId;               
                
END                
                
              
                
SELECT                
 @IsSuccess AS IsSuccess                
   ,@ErrorMessage AS ErrorMessage                
                
SELECT                
 *                
FROM ProjectSection WITH (NOLOCK)                
WHERE SectionId = @SectionId              
                  
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
  , @SectionId              
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
              
 EXEC usp_MaintainImportProjectHistory @PProjectId                            
           ,@ImportFailed_Description                            
          ,@ResultMessage                      
           ,@IsCompleted                  
            ,@ImportFailed_Step --Step                     
     ,@RequestId;                
                
EXEC usp_MaintainImportProjectProgress null                            
         ,@PProjectId                     
   ,null                
  , @SectionId                       
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
PRINT N'Altering [dbo].[usp_ImportSectionFromProject]...';


GO
ALTER PROCEDURE usp_ImportSectionFromProject
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
 DECLARE @TargetSectionCode INT = NULL;      
              
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
    
--IF(ISNULL(@OldSectionId,0)=0)    
--BEGIN    
-- SET @OldSectionId =(SELECT top 1 SectionId FROM ProjectSection PS WITH (NOLOCK)                    
-- WHERE PS.ProjectId = @PTargetProjectId                 
-- AND PS.IsLastLevel = 1                    
-- AND PS.SectionCode = @SectionCode  
-- AND PS.SourceTag = @SourceTag                      
-- AND PS.Author = @Author                    
-- AND ISNULL(PS.IsDeleted,0)=0)    
--END    
       
UPDATE PS      
SET PS.IsDeleted = 1,
	PS.IsLocked=1,
	PS.LockedBy=@UserId,
	PS.LockedByFullName=@UserName
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
CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId, SpecViewModeId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy,
IsLocked,LockedByFullName)      
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
	,1
	,@UserName
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
 FROM #SrcSegmentStatusTMP PSS WITH (NOLOCK);      
      
--INSERT Tgt SegmentStatus into Temp tables                    
SELECT      
 PSST.* INTO #tmp_TgtSegmentStatus      
FROM ProjectSegmentStatus PSST WITH (NOLOCK)      
WHERE PSST.SectionId = @TargetSectionId   
AND    PSST.ProjectId = @PTargetProjectId      
      
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
--INNER JOIN #SrcSegmentStatusTMP SPSS_Child WITH (NOLOCK)                    
-- ON TPSS_Child.SegmentStatusCode = SPSS_Child.SegmentStatusCode                    
--INNER JOIN #SrcSegmentStatusTMP SPSS_Parent WITH (NOLOCK)                    
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
 ON PSG.SectionId = @PSourceSectionId 
 AND PSG.SegmentStatusId = PSST_Src.A_SegmentStatusId      
WHERE PSG.SectionId = @PSourceSectionId           
AND PSG.ProjectId = @PSourceProjectId 
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
WHERE PSG.SectionId = @TargetSectionId 
AND    PSG.ProjectId = @PTargetProjectId      
  AND ISNULL(PSG.IsDeleted,0)=0    
    
 --UPDATE SegmentId IN ProjectSegmentStatus Temp (Changed for CSI 37207)
UPDATE PSST_Target
SET PSST_Target.SegmentId = PSG_Target.SegmentId
FROM #tmp_TgtSegmentStatus PSST_Target WITH (NOLOCK)
INNER JOIN ProjectSegmentStatus PSST_Source WITH (NOLOCK)
	ON PSST_Source.SectionId = @PSourceSectionId
	AND PSST_Target.SegmentStatusCode = PSST_Source.SegmentStatusCode
INNER JOIN ProjectSegment PSG_Source WITH (NOLOCK)
	ON PSST_Source.SectionId=PSG_Source.SectionId 
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
  ON PCH_Source.SectionId=@SourceSectionId 
  AND PCH_Source.SegmentId = PS_Target.A_SegmentId      
 WHERE PCH_Source.SectionId = @PSourceSectionId      
 AND PCH_Source.ProjectId = @PSourceProjectId      
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
WHERE SectionId = @TargetSectionId   
AND ProjectId = @TargetProjectId         
      
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
  ON PCH_Source.SectionId=@SourceSectionId
  AND PCH_Source.SegmentChoiceId = t.A_SegmentChoiceId      
 --INNER JOIN ProjectSegmentChoice PCH_Source WITH (NOLOCK)                    
 -- ON PCH_Source.ProjectId = @PSourceProjectId                    
 --  AND PCH_Source.SectionId = @PSourceSectionId                    
 --  AND PCHOP_Source.SegmentChoiceId = PCH_Source.SegmentChoiceId                    
 --INNER JOIN ProjectSegmentChoice PCH_Target WITH (NOLOCK)                    
 -- ON PCH_Target.ProjectId = @PTargetProjectId                    
 --  AND PCH_Target.SectionId = @TargetSectionId                    
 --  AND PCH_Source.SegmentChoiceCode = PCH_Target.SegmentChoiceCode                    
 --INNER JOIN #tmp_TgtSegment PS_Target ON PS_Target.SegmentId = t.SegmentId                 
 WHERE PCH_Source.SectionId = @PSourceSectionId       
 AND PCH_Source.ProjectId = @PSourceProjectId     
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
      
----INSERT SELECTED CHOICE OPTIONS OF USER CHOICE                   
--INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId)      
-- SELECT DISTINCT      
--  SCHOP_Source.SegmentChoiceCode      
--    ,SCHOP_Source.ChoiceOptionCode      
--    ,SCHOP_Source.ChoiceOptionSource      
--    ,SCHOP_Source.IsSelected      
--    ,@TargetSectionId AS SectionId      
--    ,@PTargetProjectId AS ProjectId      
--    ,@PCustomerId AS CustomerId      
-- FROM SelectedChoiceOption SCHOP_Source WITH (NOLOCK)      
-- --INNER JOIN ProjectSegmentChoice PSC WITH (NOLOCK)      
-- -- ON PSC.SectionId = SCHOP_Source.SectionId      
-- --  AND PSC.ProjectId = SCHOP_Source.ProjectId      
-- --  AND PSC.SegmentChoiceCode = SCHOP_Source.SegmentChoiceCode      
-- --INNER JOIN ProjectChoiceOption PCO WITH (NOLOCK)      
-- -- ON PCO.SegmentChoiceId = PSC.SegmentChoiceId      
-- --  AND PCO.SectionId = PCO.SectionId      
-- --  AND PCO.ChoiceOptionCode=SCHOP_Source.ChoiceOptionCode    
-- --  AND SCHOP_Source.SegmentChoiceCode=PSC.SegmentChoiceCode    
-- --  AND PCO.ProjectId = SCHOP_Source.ProjectId      
-- --INNER JOIN #tmp_TgtSegment PS_Target              
-- -- ON PSC.SegmentId = PS_Target.SegmentId              
-- WHERE SCHOP_Source.SectionId = @PSourceSectionId    
-- AND SCHOP_Source.ProjectId = @PSourceProjectId        
-- AND ISNULL(SCHOP_Source.IsDeleted, 0) = 0      
-- --AND ISNULL(PS_Target.IsDeleted, 0) = 0              
-- AND SCHOP_Source.ChoiceOptionSource = 'U'      
         
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
 WHERE SCHOP_Source.SectionId = @PSourceSectionId 
 AND  SCHOP_Source.ProjectId = @PSourceProjectId     
 AND ISNULL(SCHOP_Source.IsDeleted, 0) = 0      
 --AND SCHOP_Source.ChoiceOptionSource = 'M'      
      
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
  ON PN.SectionId=@SourceSectionId
	AND PN.SegmentStatusId = t.A_SegmentStatusId      
 --INNER JOIN #SrcSegmentStatusTMP PSS_Source WITH (NOLOCK)                    
 -- ON PN.SegmentStatusId = PSS_Source.SegmentStatusId                    
 --INNER JOIN #tmp_TgtSegmentStatus PSS_Target WITH (NOLOCK)                    
 -- ON PSS_Source.SegmentStatusCode = PSS_Target.SegmentStatusCode                    
 WHERE PN.SectionId = @PSourceSectionId      
 AND PN.ProjectId = @PSourceProjectId      
      
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
 WHERE PNI.SectionId = @PSourceSectionId      
 AND PNI.ProjectId = @PSourceProjectId      
      
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
 WHERE PSI.SectionId = @PSourceSectionId           
 AND PSI.ProjectId = @PSourceProjectId 
      
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
 WHERE SectionId = @PSourceSectionId      
 AND   ProjectId = @PSourceProjectId    
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
 WHERE PSRS.SectionId = @PSourceSectionId             
 AND     PSRS.ProjectId = @PSourceProjectId                    
               
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
 --INNER JOIN #SrcSegmentStatusTMP PSS_Source WITH (NOLOCK)                    
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
 --INNER JOIN #SrcSegmentStatusTMP PSS_Source WITH (NOLOCK)                    
 -- ON PSUT.SegmentStatusId = PSS_Source.SegmentStatusId                    
 INNER JOIN #tmp_TgtSegmentStatus PSS_Target WITH (NOLOCK)      
  ON PSUT.SegmentStatusId = PSS_Target.A_SegmentStatusId      
 WHERE PSUT.SectionId = @PSourceSectionId      
 AND PSUT.ProjectId = @PSourceProjectId      
      
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
 WHERE SectionId = @PSourceSectionId          
 AND ProjectId = @PSourceProjectId  
      
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
 WHERE SectionId = @PSourceSectionId                    
 AND  ProjectId = @PSourceProjectId                 
               
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
 WHERE PSGT.SectionId = @PSourceSectionId        
 AND  PSGT.ProjectId = @PSourceProjectId   
      
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
 WHERE PSGT_Source.SectionId = @PSourceSectionId      
 AND PGT_Source.ProjectId = @PSourceProjectId      
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
 WHERE PHL.SectionId = @PSourceSectionId   
 AND PHL.ProjectId = @PSourceProjectId         
      
---UPDATE NEW HyperLinkId in SegmentDescription             
      
DECLARE @MultipleHyperlinkCount INT = 0;      
SELECT      
 COUNT(SegmentStatusId) AS TotalCountSegmentStatusId INTO #TotalCountSegmentStatusIdTbl      
FROM ProjectHyperLink WITH(NOLOCK)      
WHERE SectionId = @TargetSectionId       
AND  ProjectId = @TargetProjectId    
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
                    
	UPDATE ps
	SET ps.IsLocked=0,
		ps.LockedByFullName=''
	FROM ProjectSection ps WITH(NOLOCK)
	WHERE ps.SectionId=@TargetSectionId

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
PRINT N'Altering [dbo].[usp_ActionOnChoiceOptionModify]...';


GO
ALTER PROCEDURE [dbo].[usp_ActionOnChoiceOptionModify]     
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
 PSST.* INTO #SrcSegmentStatusCPTMP      
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
 FROM #SrcSegmentStatusCPTMP PSST_Src WITH (NOLOCK)      
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
 INNER JOIN #SrcSegmentStatusCPTMP SRCS      
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
  ON PN.SectionId=PS.SectionId
  AND PN.ProjectId = @TargetProjectId      
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
PRINT N'Altering [dbo].[usp_GetChoiceRSAndGTList]...';


GO
ALTER PROCEDURE [dbo].[usp_GetChoiceRSAndGTList]    
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
PRINT N'Altering [dbo].[usp_GetSegmentLinksBasedOnEditorLinkActionType]...';


GO
ALTER PROCEDURE [dbo].[usp_GetSegmentLinksBasedOnEditorLinkActionType]
	@EditorLinkActionType INT NULL,    
	@ProjectId INT NULL,     
	@CustomerId INT NULL,     
	@SectionId INT NULL,     
	@SectionCode INT NULL,    
	@SegmentStatusCode INT NULL,     
	@SegmentChoiceCode INT NULL,    
	@SegmentLinkId INT NULL,    
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
	DECLARE @PSegmentStatusCode INT = @SegmentStatusCode;  
	DECLARE @PSegmentChoiceCode INT = @SegmentChoiceCode;  
	DECLARE @PSegmentLinkId INT = @SegmentLinkId;  
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
	DECLARE @MinUserSegmentLinkCode INT = 10000001;  
  
	--TABLES  
	--1.  
	DROP TABLE IF EXISTS #SegmentLinksTable  
	CREATE TABLE #SegmentLinksTable (  
		 SegmentLinkId INT NULL  
		,SourceSectionCode INT NULL  
		,SourceSegmentStatusCode INT NULL  
		,SourceSegmentCode INT NULL  
		,SourceSegmentChoiceCode INT NULL  
		,SourceChoiceOptionCode INT NULL  
		,LinkSource NVARCHAR(1) NULL  
		,TargetSectionCode INT NULL  
		,TargetSegmentStatusCode INT NULL  
		,TargetSegmentCode INT NULL  
		,TargetSegmentChoiceCode INT NULL  
		,TargetChoiceOptionCode INT NULL  
		,LinkTarget NVARCHAR(1) NULL  
		,LinkStatusTypeId INT NULL  
		,SegmentLinkCode INT NULL  
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
		 SegmentStatusId INT NULL  
		,SegmentStatusCode INT NULL  
		,SegmentSource CHAR(1) NULL  
		,SectionId INT NULL  
		,SectionCode INT NULL  
		,SegmentCode INT NULL  
	);  
  
	--3.  
	DROP TABLE IF EXISTS #PresentChoiceOptionsTbl  
	CREATE TABLE #PresentChoiceOptionsTbl (  
		ChoiceOptionCode INT NULL  
	);  
  
	--4.  
	DROP TABLE IF EXISTS #InputSegmentStatusTable  
	CREATE TABLE #InputSegmentStatusTable (  
		SegmentStatusId INT NULL  
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
		SegmentStatusId INT '$.SegmentStatusId'  
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
PRINT N'Altering [dbo].[usp_ImportToolChoicesInsert]...';


GO
ALTER PROC [dbo].[usp_ImportToolChoicesInsert]
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
PRINT N'Altering [dbo].[usp_MapSegmentChoiceFromMasterToProject]...';


GO
ALTER PROCEDURE [dbo].[usp_MapSegmentChoiceFromMasterToProject]
	@ProjectId INT NULL
	,@SectionId INT NULL
	,@CustomerId INT NULL
	,@UserId INT NULL
	,@MasterSectionId INT = NULL
AS
BEGIN
	DECLARE @PProjectId INT = @ProjectId;
	DECLARE @PSectionId INT = @SectionId;
	DECLARE @PCustomerId INT = @CustomerId;
	DECLARE @PSectionModifiedDate datetime2=null
	DECLARE @PUserId INT = @UserId;
	--DECLARE @SProjectId NVARCHAR(20) = convert(NVARCHAR, @ProjectId);
	--DECLARE @SSectionId NVARCHAR(20) = convert(NVARCHAR, @SectionId);
	--DECLARE @SCustomerId NVARCHAR(20) = convert(NVARCHAR, @CustomerId);
	--DECLARE @SUserId NVARCHAR(20) = convert(NVARCHAR, @UserId);

	DECLARE @PMasterSectionId AS INT = @MasterSectionId;

 --NOTE:VIMP: DO NOT UNCOMMENT BELOW IF CONDITION OTHERWISE UNCOIPED CHOICES WILL NOT WORK            
 --NOTE:Called from             
 --1.usp_GetSegmentLinkDetails            
 --2.usp_GetSegments            
 --3.usp_ApplyNewParagraphsUpdates            
 --IF NOT EXISTS (SELECT TOP 1            
 --  SCHOP.SelectedChoiceOptionId            
 -- FROM [dbo].[SelectedChoiceOption] AS SCHOP WITH (NOLOCK)            
 -- WHERE SCHOP.SectionId = @PSectionId            
 -- AND SCHOP.[ProjectId] = @PProjectId            
 -- AND SCHOP.CustomerId = @PCustomerId            
 -- AND SCHOP.ChoiceOptionSource = 'M')            
 --BEGIN  

	SELECT TOP 1
	@PMasterSectionId = mSectionId
	,@PSectionModifiedDate=DataMapDateTimeStamp
	FROM dbo.ProjectSection WITH (NOLOCK)
	WHERE SectionId = @PSectionId
	OPTION (FAST 1);


		SELECT SegmentChoiceCode
		,ChoiceOptionCode
		--,SelectedChoiceOptionId
		,SectionId
		INTO #tempSelectedChoiceOption
		FROM SelectedChoiceOption PSCHOP WITH (NOLOCK)
		WHERE PSCHOP.SectionId = @PSectionId
		AND PSCHOP.ProjectId = @PProjectId
		AND PSCHOP.ChoiceOptionSource = 'M'
		AND PSCHOP.CustomerId = @PCustomerId;

		INSERT INTO SelectedChoiceOption (
		SegmentChoiceCode
		,ChoiceOptionCode
		,ChoiceOptionSource
		,IsSelected
		,ProjectId
		,CustomerId
		,SectionId
		)
		SELECT MCH.SegmentChoiceCode
		,MCHOP.ChoiceOptionCode
		,MSCHOP.ChoiceOptionSource
		,MSCHOP.IsSelected
		,@PProjectId
		,@PCustomerId
		,@PSectionId
		
		FROM SLCMaster..SegmentStatus MST WITH (NOLOCK)
		INNER JOIN SLCMaster..SegmentChoice AS MCH WITH (NOLOCK) ON MCH.SectionId=MST.SectionId and MCH.SegmentStatusId = MST.SegmentStatusId
		INNER JOIN SLCMaster..ChoiceOption AS MCHOP WITH (NOLOCK) ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId
		INNER JOIN SLCMaster..SelectedChoiceOption AS MSCHOP WITH (NOLOCK) ON MCH.SectionId = MSCHOP.SectionId
		AND MSCHOP.SegmentChoiceCode=MCH.SegmentChoiceCode
		AND MCHOP.ChoiceOptionCode = MSCHOP.ChoiceOptionCode
		LEFT JOIN #tempSelectedChoiceOption PSCHOP
		ON PSCHOP.SectionId = @PSectionId
		AND PSCHOP.SegmentChoiceCode = MCH.SegmentChoiceCode
		AND PSCHOP.ChoiceOptionCode = MCHOP.ChoiceOptionCode
		WHERE MST.SectionId = @PMasterSectionId
		AND PSCHOP.SegmentChoiceCode IS NULL


	IF((dateadd(HOUR,-6,GETUTCDATE())>=@PSectionModifiedDate or @PSectionModifiedDate is null))
	BEGIN
		DROP TABLE IF EXISTS #tempSelectedChoiceOption1

		SELECT SegmentChoiceCode
		,ChoiceOptionCode
		,SectionId
		,ProjectId
		,ChoiceOptionSource
		INTO #tempSelectedChoiceOption1
		FROM SelectedChoiceOption PSCHOP WITH (NOLOCK)
		WHERE PSCHOP.SectionId = @PSectionId
		AND PSCHOP.ProjectId = @PProjectId
		--AND PSCHOP.ChoiceOptionSource = 'M'
		AND PSCHOP.CustomerId = @PCustomerId;

		-- Insert missing entry
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
		INNER JOIN ProjectChoiceOption pco WITH (NOLOCK) ON pco.SegmentChoiceId = psc.SegmentChoiceId
		AND pco.SectionId = psc.SectionId
		AND pco.ProjectId = psc.ProjectId
		AND pco.CustomerId = psc.CustomerId
		LEFT OUTER JOIN #tempSelectedChoiceOption1 sco WITH (NOLOCK)
		ON pco.SectionId = sco.SectionId
		AND pco.ProjectId = sco.ProjectId
		AND sco.SegmentChoiceCode=psc.SegmentChoiceCode
		AND pco.ChoiceOptionCode = sco.ChoiceOptionCode
		--AND pco.CustomerId = sco.CustomerId
		AND sco.ChoiceOptionSource = pco.ChoiceOptionSource
		INNER JOIN SLCMaster.dbo.SelectedChoiceOption slcmsco WITH (NOLOCK)
		ON slcmsco.SectionId=@PMasterSectionId
		and slcmsco.SegmentChoiceCode = psc.SegmentChoiceCode
		and slcmsco.ChoiceOptionCode = pco.ChoiceOptionCode
		WHERE psc.SectionId = @PSectionId
		AND pco.ProjectId = @PProjectId
		AND pco.CustomerId = @PCustomerId
		AND sco.SegmentChoiceCode IS NULL
		AND ISNULL(pco.IsDeleted, 0) = 0
		AND ISNULL(psc.IsDeleted, 0) = 0

		IF(@@ROWCOUNT>0)
		BEGIN
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
			'usp_MapSegmentChoiceFromMasterToProject'
			,@@SERVERNAME
			,convert(NVARCHAR, CONNECTIONPROPERTY('local_net_address'))
			,Getdate()
			,'Information'
			,concat('ProjectId: ' , @ProjectId , ' SectionId: ' , @SectionId , ' CustomerId: ' , @CustomerId , ' UserId:' , @UserId)
			,'Insert'
			,('Scenario 1: SelectedChoiceOption Rows Inserted - ' + convert(NVARCHAR, @@ROWCOUNT))
			)
		END
		-- Mark isdeleted =0 for SelectedChoiceOption
		UPDATE sco
		SET sco.isdeleted = 0
		FROM ProjectSegmentChoice psc WITH (NOLOCK)
		INNER JOIN ProjectChoiceOption pco WITH (NOLOCK) ON pco.SegmentChoiceId = psc.SegmentChoiceId
		AND pco.SectionId = psc.SectionId
		AND pco.ProjectId = psc.ProjectId
		AND pco.CustomerId = psc.CustomerId
		LEFT OUTER JOIN SelectedChoiceOption sco WITH (NOLOCK)
		ON pco.SectionId = sco.SectionId
		AND pco.ProjectId = sco.ProjectId
		AND sco.SegmentChoiceCode = psc.SegmentChoiceCode
		AND pco.ChoiceOptionCode = sco.ChoiceOptionCode
		--AND pco.CustomerId = sco.CustomerId
		AND sco.ChoiceOptionSource = pco.ChoiceOptionSource
		WHERE psc.SectionId = @PSectionId
		AND pco.CustomerId = @PCustomerId
		AND pco.ProjectId = @PProjectId
		AND ISNULL(sco.IsDeleted, 0) = 1
		AND ISNULL(pco.IsDeleted, 0) = 0
		AND ISNULL(psc.IsDeleted, 0) = 0
		AND psc.SegmentChoiceSource = 'U'

		-- Mark isdeleted =0 for SelectedChoiceOption
		IF(@@ROWCOUNT>0)
		BEGIN
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
			'usp_MapSegmentChoiceFromMasterToProject'
			,@@SERVERNAME
			,convert(NVARCHAR, CONNECTIONPROPERTY('local_net_address'))
			,Getdate()
			,'Information'
			,concat('ProjectId: ' , @ProjectId , ' SectionId: ' , @SectionId , ' CustomerId: ' , @CustomerId , ' UserId:' , @UserId)
			,'Update'
			,('Scenario 2: SelectedChoiceOption Rows Updated - ' + convert(NVARCHAR, @@ROWCOUNT))
			)
		END
	END
END
GO
PRINT N'Altering [dbo].[usp_ValidateSection]...';


GO
ALTER PROCEDURE [dbo].[usp_ValidateSection]       
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
   PSST.SectionId
   INTO #tmp_SrcProjectSegmentStatus
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
	   ,PS.CustomerId INTO #tmp_SrcProjectSection
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
	OR IsProcessed = 0
	)
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
		mRefStandardId	INT NULL,
		CreatedDate DATETIME NULL,
		CreatedBy INT NULL, 
		ModifiedDate DATETIME NULL,
		ModifiedBy INT NULL
	);

	IF @PIsDeleted = 1 AND @PSegmentStatusId > 0 -- Only proceed if SegmentStatusId is not zero
	BEGIN
SET @PSegmentDescription = '';
--SELECT
--	@PProjectId = ProjectId
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
	WHERE RS.CustomerId = @PCustomerId
	AND RS.RefStdSource = 'U'
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

SELECT DISTINCT	MAX(RefStdEditionId) AS RefStdEditionId,
	RefStdId INTO #TM FROM SLCMaster.dbo.ReferenceStandardEdition WITH (NOLOCK)
	GROUP BY RefStdId

	SELECT DISTINCT	MAX(RefStdEditionId) AS RefStdEditionId,
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
		--	TOP 1
		--		RSE.RefStdEditionId
		--	FROM SLCMaster..ReferenceStandardEdition RSE WITH (NOLOCK)
		--	WHERE RSE.RefStdId = PSRS.mRefStandardId
		--	ORDER BY RSE.RefStdEditionId DESC) AS MREFEDN

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
UPDATE PRS
SET PRS.IsDeleted = 1
	FROM ProjectReferenceStandard PRS  WITH (NOLOCK)
	LEFT JOIN ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)
		ON PSRS.SectionId = PRS.SectionId
		AND PSRS.ProjectId = PRS.ProjectId
		AND PSRS.RefStdCode = PRS.RefStdCode
WHERE PRS.SectionId = @PSectionId
	AND PRS.CustomerId = @PCustomerId
	AND PRS.ProjectId = @PProjectId
	AND PSRS.RefStdCode IS NULL
END
END
GO
PRINT N'Altering [dbo].[usp_AutoSaveModifiedDetails]...';


GO
ALTER PROCEDURE [dbo].[usp_AutoSaveModifiedDetails]  
(@InpSegmentEditedJson NVARCHAR(MAX))      
AS             
BEGIN
DECLARE @PInpSegmentEditedJson NVARCHAR(MAX) = @InpSegmentEditedJson;
BEGIN TRY
DECLARE @LoopCount INT = 1;
SELECT
	@PInpSegmentEditedJson = REPLACE(@PInpSegmentEditedJson, '`', '''');
	CREATE TABLE #TempInpSegmentEditedJson (
		RowId INT NULL
	   ,ProjectId INT NULL
	   ,SectionId INT NULL
	   ,CustomerId INT NULL
	   ,SegmentStatusId INT NULL
	   ,UserId INT NULL
	   ,SegmentDescription NVARCHAR(MAX) NULL
	   ,BaseSegmentDescription NVARCHAR(MAX) NULL
	   ,SegmentAction NVARCHAR(10) NULL
	   ,SegmentId INT NULL
	   ,SegmentSource CHAR(1) NULL
	   ,SegmentOrigin CHAR(1) NULL
	   ,ParentSegmentStatusId INT NULL
	   ,IndentLevel INT NULL
	   ,IsShowAutoNumber BIT NULL
	   ,FormattingJson NVARCHAR(MAX) NULL
	   ,IsPageBreak BIT NULL
	   ,ChoiceListJson NVARCHAR(MAX) NULL
	   ,SpecTypeTagId INT NULL
	   --,ToggleOrigin NVARCHAR(10) NULL
	);

INSERT INTO #TempInpSegmentEditedJson
	SELECT
		*
	FROM OPENJSON(@PInpSegmentEditedJson)
	WITH (
	RowId INT '$.RowId',
	ProjectId INT '$.ProjectId',
	SectionId INT '$.SectionId',
	CustomerId INT '$.CustomerId',
	SegmentStatusId INT '$.SegmentStatusId',
	UserId INT '$.UserId',
	SegmentDescription NVARCHAR(MAX) '$.SegmentDescription',
	BaseSegmentDescription NVARCHAR(MAX) '$.BaseSegmentDescription',
	SegmentAction NVARCHAR(10) '$.SegmentAction',
	SegmentId INT '$.SegmentId',
	SegmentSource CHAR(1) '$.SegmentSource',
	SegmentOrigin CHAR(1) '$.SegmentOrigin',
	ParentSegmentStatusId INT '$.ParentSegmentStatusId',
	IndentLevel INT '$.IndentLevel',
	IsShowAutoNumber BIT '$.IsShowAutoNumber',
	FormattingJson NVARCHAR(MAX) '$.FormattingJson',
	IsPageBreak BIT '$.IsPageBreak',
	ChoiceListJson NVARCHAR(MAX) '$.ChoiceListJson',
	SpecTypeTagId INT '$.SpecTypeTagId'
	--,ToggleOrigin NVARCHAR(10) '$.ToggleOrigin'
	);

	DECLARE @TempInpSegmentEditedJsonCounter INT=(SELECT COUNT(1)	FROM #TempInpSegmentEditedJson)

DECLARE @ProjectId INT;
DECLARE @SectionId INT;
DECLARE @CustomerId INT;
DECLARE @SegmentStatusId INT;
DECLARE @UserId INT;
DECLARE @SegmentDescription NVARCHAR(MAX);
DECLARE @BaseSegmentDescription NVARCHAR(MAX);
DECLARE @SegmentAction NVARCHAR(10);
DECLARE @SegmentId INT;
DECLARE @SegmentSource CHAR(1);
DECLARE @SegmentOrigin CHAR(1);
DECLARE @ParentSegmentStatusId INT;
DECLARE @IndentLevel INT;
DECLARE @IsShowAutoNumber BIT;
DECLARE @FormattingJson NVARCHAR(MAX);
DECLARE @IsPageBreak BIT;
DECLARE @ChoiceListJson NVARCHAR(MAX);
DECLARE @SpecTypeTagId INT;
--DECLARE @ToggleOrigin NVARCHAR(10);

WHILE (@LoopCount <= @TempInpSegmentEditedJsonCounter)
BEGIN

set @ProjectId =0;
set @SectionId =0;
set @CustomerId =0;
set @SegmentStatusId =0;
set @UserId =0;
set @SegmentDescription =null;
set @BaseSegmentDescription =null;
set @SegmentAction =null;
set @SegmentId =0;
set @SegmentSource =null;
set @SegmentOrigin =null;
set @ParentSegmentStatusId =0;
set @IndentLevel =0;
set @IsShowAutoNumber =0;
set @FormattingJson =null;
set @IsPageBreak =0;
set @ChoiceListJson =null;
set @SpecTypeTagId =0;
--set @ToggleOrigin =null;

SELECT
	@ProjectId = ProjectId
   ,@SectionId = SectionId
   ,@CustomerId = CustomerId
   ,@SegmentStatusId = SegmentStatusId
   ,@UserId = UserId
   ,@SegmentDescription = SegmentDescription
   ,@BaseSegmentDescription = BaseSegmentDescription
   ,@SegmentAction = SegmentAction
   ,@SegmentId = SegmentId
   ,@SegmentSource = SegmentSource
   ,@SegmentOrigin = SegmentOrigin
   ,@ParentSegmentStatusId = ParentSegmentStatusId
   ,@IndentLevel = IndentLevel
   ,@IsShowAutoNumber = IsShowAutoNumber
   ,@FormattingJson = FormattingJson
   ,@IsPageBreak = IsPageBreak
   ,@ChoiceListJson = ChoiceListJson
   ,@SpecTypeTagId = SpecTypeTagId
   --,@ToggleOrigin=ToggleOrigin
FROM #TempInpSegmentEditedJson
WHERE RowId = @LoopCount

--IF SEGMENT IS MODIFIED      
IF ISNULL(@SegmentAction,'')= 'Modified'
BEGIN

EXEC usp_ActionOnMasterSegmentModify @ProjectId
									,@SectionId
									,@CustomerId
									,@UserId
									,@SegmentStatusId
									,@SegmentDescription
									,@BaseSegmentDescription
									,@SegmentId
									,@SegmentSource
									,@SegmentOrigin
									,@ParentSegmentStatusId
									,@IndentLevel
									,@IsShowAutoNumber
									,@FormattingJson
									,@IsPageBreak
									,@SpecTypeTagId
--PRINT 'Autosave call'    

IF @SegmentOrigin = 'U'
BEGIN
IF ISNULL(@ChoiceListJson,'[]')!= '[]'
--PRINT 'Autosave call'    
BEGIN
SELECT
	@segmentid = SegmentId
FROM ProjectSegment WITH (NOLOCK)
WHERE SegmentStatusId = @SegmentStatusId

--SELECT @ChoiceListJson   
	--IF(@ToggleOrigin NOT IN('M','M*'))
	--BEGIN
		EXEC [usp_CreateUserChoice] @ChoiceListJson
									 ,@SegmentStatusId
									 ,@segmentid
									 ,@SegmentSource
									 ,@SegmentOrigin
	--END
END
END

SELECT
	PSST.SegmentStatusId
   ,PSST.SegmentStatusCode
   ,PSST.SegmentId
   ,PSG.SegmentCode
   ,PSST.SegmentOrigin
   ,PSST.ParentSegmentStatusId
   ,PSST.IndentLevel
   ,PSST.IsShowAutoNumber
   ,PSST.FormattingJson
   ,PSST.IsPageBreak
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN ProjectSegment PSG WITH (NOLOCK)
	ON PSST.SegmentId = PSG.SegmentId
		AND isnull(PSG.IsDeleted ,0)= 0
WHERE PSST.SegmentStatusId = @SegmentStatusId

END

SET @LoopCount = @LoopCount + 1;
  
END

END TRY
BEGIN CATCH
	insert into BsdLogging..AutoSaveLogging
		values('usp_AutoSaveModifiedDetails',
		getdate(),
		ERROR_MESSAGE(),
		ERROR_NUMBER(),
		ERROR_Severity(),
		ERROR_LINE(),
		ERROR_STATE(),
		ERROR_PROCEDURE(),
		concat('exec usp_AutoSaveModifiedDetails ''',@InpSegmentEditedJson,''''),
		@InpSegmentEditedJson
	)

END CATCH

END
GO
PRINT N'Altering [dbo].[usp_CheckDeletedGT]...';


GO
ALTER PROCEDURE [dbo].[usp_CheckDeletedGT]
(
@projectId INT, 
@customerId INT,
@globalTermCode INT
)
AS
BEGIN
DECLARE @PprojectId INT = @projectId;
DECLARE @PcustomerId INT = @customerId;
DECLARE @PglobalTermCode INT = @globalTermCode;
SELECT
	ISNULL(IsDeleted, 0) AS IsDeleted
FROM ProjectGlobalTerm WITH (NOLOCK)
WHERE 
 ProjectId = @PprojectId
AND CustomerId = @PcustomerId
AND GlobalTermCode = @PglobalTermCode

END
GO
PRINT N'Altering [dbo].[usp_CreateGlobalTerms]...';


GO
ALTER PROCEDURE [dbo].[usp_CreateGlobalTerms] 
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

	DECLARE @MinGlobalTermCode INT=10000000;
	IF(@MaxGlobalTermCode < @MinGlobalTermCode)
	SET @MaxGlobalTermCode = @MinGlobalTermCode;

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
PRINT N'Altering [dbo].[usp_FooterGlobalTermUsage]...';


GO
ALTER PROCEDURE [dbo].[usp_FooterGlobalTermUsage]  
 @ProjectId int=0,  
 @FooterId int=0,  
 @SectionId int=0,  
 @CustomerId int=0,  
 @Description nvarchar(MAX)='',  
 @CreatedById int=0  
AS  
BEGIN
  
 DECLARE @PProjectId int = @ProjectId;
 DECLARE @PFooterId int = @FooterId;
 DECLARE @PSectionId int =  @SectionId;
 DECLARE @PCustomerId int = @CustomerId;
 DECLARE @PDescription nvarchar(MAX) = @Description;
 DECLARE @PCreatedById int = @CreatedById;

 IF(@PFooterId=0)
SET @PFooterId = (SELECT
		FooterId
	FROM Footer WITH (NOLOCK)
	WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId)
  
   
  DECLARE @GTList nvarchar(MAX)=''

SET @GTList = (SELECT
		LEFT(REPLACE(splitdata, 'GT#', ''), CHARINDEX('}', REPLACE(splitdata, 'GT#', '')) - 1) + ','
	FROM dbo.fn_SplitString(@PDescription, '{')
	WHERE splitdata LIKE 'GT#%'
	FOR XML PATH (''))

UPDATE f
SET f.Description = @PDescription
   ,f.ModifiedDate = GETUTCDATE()
   ,f.ModifiedBy = @PCreatedById
   from Footer f WITH(NOLOCK)
WHERE f.ProjectId = @PProjectId
AND f.CustomerId = @PCustomerId
AND f.FooterId = @PFooterId

SET @GTList = IIF(@GTList IS NOT NULL, @GTList, '0')
  
  
 if(@PDescription='' OR @GTList='0')  
 BEGIN
DELETE hfgt
FROM HeaderFooterGlobalTermUsage hfgt WITH(NOLOCK)
WHERE hfgt.ProjectId = @PProjectId
	AND hfgt.CustomerId = @PCustomerId
	AND hfgt.FooterId = @PFooterId
END

IF (@GTList != '0')
BEGIN

SELECT
			HFU.UserGlobalTermId
		into #gtId FROM HeaderFooterGlobalTermUsage HFU WITH (NOLOCK)
		LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK)
			ON PGT.UserGlobalTermId = HFU.UserGlobalTermId
		WHERE PGT.GlobalTermCode NOT IN (SELECT
				*
			FROM dbo.fn_SplitString(@GTList, ','))
		AND PGT.ProjectId = @PProjectId
		AND HFU.FooterId = @PFooterId
		AND PGT.CustomerId = @PCustomerId

DELETE hfgt
FROM HeaderFooterGlobalTermUsage hfgt with(nolock) inner join #gtId t
ON hfgt.UserGlobalTermId =t.UserGlobalTermId
WHERE hfgt.ProjectId = @PProjectId
	AND hfgt.CustomerId = @PCustomerId
	AND hfgt.FooterId = @PFooterId



INSERT INTO HeaderFooterGlobalTermUsage (HeaderId, FooterId, UserGlobalTermId, CustomerId, ProjectId, HeaderFooterCategoryId, CreatedDate, CreatedById)
	SELECT
		NULL
	   ,@PFooterId
	   ,UserGlobalTermId
	   ,@PCustomerId
	   ,@PProjectId
	   ,1
	   ,GETUTCDATE()
	   ,@PCreatedById
	FROM ProjectGlobalTerm WITH (NOLOCK)
	WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND GlobalTermSource = 'U'
	AND GlobalTermCode IN (SELECT
			*
		FROM dbo.fn_SplitString(@GTList, ',')
		WHERE UserGlobalTermId NOT IN (SELECT
				UserGlobalTermId
			FROM HeaderFooterGlobalTermUsage WITH (NOLOCK)
			WHERE ProjectId = @PProjectId
			AND CustomerId = @PCustomerId
			AND FooterId = @PFooterId))
END

SELECT
	GETUTCDATE() AS ModifiedDate

END
GO
PRINT N'Altering [dbo].[usp_getTOCReport]...';


GO
ALTER Procedure usp_getTOCReport
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
PRINT N'Altering [dbo].[usp_UpdateProjectSummaryInfo]...';


GO
ALTER PROCEDURE [dbo].[usp_UpdateProjectSummaryInfo]       
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
PRINT N'Altering [dbo].[usp_GetHeaderFooterImages]...';


GO
ALTER PROCEDURE [dbo].[usp_GetHeaderFooterImages]      
(      
 @CustomerId INT,      
 @ProjectId INT      
)      
AS      
BEGIN      
 DECLARE @PCustomerId INT = @CustomerId;      
 DECLARE @PProjectId INT = @ProjectId;     
 DECLARE @PImageSourceTypeId INT = 3;  
      
 SELECT      
  PSI.SegmentImageId    
 ,PIM.ImageId    
 ,PIM.ImagePath AS [Name]    
 ,PSI.ImageStyle    
 FROM ProjectImage PIM WITH (NOLOCK)      
 INNER JOIN ProjectSegmentImage PSI WITH (NOLOCK)      
 ON PIM.ImageId = PSI.ImageId      
 WHERE PSI.CustomerId = @PCustomerId      
 AND PSI.ProjectId = @PProjectId      
 AND PIM.LuImageSourceTypeId=@PImageSourceTypeId  
      
END
GO
PRINT N'Altering [dbo].[GetSubmittals]...';


GO
ALTER PROCEDURE [dbo].[GetSubmittals]  
 @ProjectId INT ,      
 @CustomerID INT,      
 @IsIncludeUntagged BIT      
AS      
BEGIN      
 DECLARE @PProjectId INT = @ProjectId;  
 DECLARE @PCustomerID INT = @CustomerID;  
 DECLARE @PIsIncludeUntagged BIT = @IsIncludeUntagged;  
-- SET NOCOUNT ON added to prevent extra result sets from      
-- interfering with SELECT statements.      
SET NOCOUNT ON;      
      
-- Insert statements for procedure here      
DECLARE @SubmittalsWord NVARCHAR(MAX) = 'submittals';      
DECLARE @ProjectName NVARCHAR(500)='';      
DECLARE @ProjectSourceTagFormate NVARCHAR(MAX)='';      
DECLARE @RequirementsTagTbl TABLE (      
TagType NVARCHAR(MAX),      
RequirementTagId INT      
);      
DROP TABLE IF EXISTS #SegmentsTable;      
CREATE TABLE #SegmentsTable (      
 SourceTag NVARCHAR(10)      
   ,SectionId INT      
   ,Author NVARCHAR(500)      
   ,Description NVARCHAR(MAX)      
   ,SegmentStatusId INT      
   ,mSegmentStatusId INT      
   ,SegmentId INT      
   ,mSegmentId INT      
   ,SegmentSource CHAR(1)      
   ,SegmentOrigin CHAR(1)      
   ,SegmentDescription NVARCHAR(MAX)      
   ,RequirementTagId INT      
   ,TagType NVARCHAR(5)      
   ,SortOrder INT      
   ,SequenceNumber DECIMAL(18, 4)      
   ,IsSegmentStatusActive INT      
   ,ProjectName NVARCHAR(500)      
   ,ParentSegmentStatusId INT      
   ,IndentLevel INT      
   ,IsDeleted BIT NULL      
   ,SourceTagFormat NVARCHAR(MAX)      
   ,UnitOfMeasureValueTypeId INT     
);      
CREATE TABLE #SectionListTable (      
 SourceTag NVARCHAR(MAX)      
   ,Description NVARCHAR(MAX)      
   ,SectionId INT      
);      
CREATE TABLE #ProjectInfo    
(    
ProjectId INT ,    
SourceTagFormat NVARCHAR(MAX),    
UnitOfMeasureValueTypeId INT    
)    
--SET VARIABLES TO DEFAULT VALUE      
INSERT INTO @RequirementsTagTbl (RequirementTagId, TagType)      
 SELECT      
  RequirementTagId      
    ,TagType      
 FROM LuProjectRequirementTag WITH (NOLOCK)   
 WHERE TagType IN ('CT', 'DC', 'FR', 'II', 'IQ', 'LR', 'XM', 'MQ', 'MO', 'OM', 'PD', 'PE', 'PR', 'QS',      
 'SA', 'SD', 'TR', 'WE', 'WT', 'WS', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'NS', 'NP');      
SET @ProjectName = (SELECT      
  [Name]      
 FROM Project      
 WHERE ProjectId = @PProjectId);      
INSERT INTO #ProjectInfo     
SELECT      
ProjectId,    
  SourceTagFormat  ,    
  UnitOfMeasureValueTypeId    
      
 FROM ProjectSummary  WITH (NOLOCK)
 WHERE ProjectId = @PProjectId;      
 --SELECT * FROM #ProjectInfo;    
--1. FIND PARAGRAPHS WHICH ARE TAGGED BY GIVEN REQUIREMENTS TAGS      
WITH TaggedSegmentsCte      
AS      
(SELECT      
  PSSTV.SegmentStatusId      
    ,PSSTV.ParentSegmentStatusId      
 FROM ProjectSegmentStatusView PSSTV    with (nolock)  
 INNER JOIN ProjectSegmentRequirementTag PSRT    with (nolock)   
  ON PSSTV.SegmentStatusId = PSRT.SegmentStatusId      
 INNER JOIN @RequirementsTagTbl TagTbl      
  ON PSRT.RequirementTagId = TagTbl.RequirementTagId      
 WHERE PSSTV.ProjectId = @PProjectId      
 AND PSSTV.IsSegmentStatusActive = 1      
 UNION ALL      
 SELECT      
  CPSSTV.SegmentStatusId      
    ,CPSSTV.ParentSegmentStatusId      
 FROM ProjectSegmentStatusView CPSSTV   with (nolock)    
 INNER JOIN TaggedSegmentsCte TSC     
  ON CPSSTV.ParentSegmentStatusId = TSC.SegmentStatusId      
 WHERE CPSSTV.IsSegmentStatusActive = 1)      
      
      
      
INSERT INTO #SegmentsTable (SourceTag, SectionId, Author, [Description], SegmentStatusId, mSegmentStatusId, SegmentId, mSegmentId      
, SegmentSource, SegmentOrigin, SegmentDescription, RequirementTagId, TagType, SortOrder, SequenceNumber, IsSegmentStatusActive, ProjectName      
, ParentSegmentStatusId, IndentLevel, IsDeleted, SourceTagFormat,UnitOfMeasureValueTypeId)      
 SELECT DISTINCT      
  PS.SourceTag      
    ,PS.SectionId      
    ,PS.Author      
    ,PS.[Description]      
    ,PSSTV.SegmentStatusId      
    ,PSSTV.mSegmentStatusId      
    ,PSSTV.SegmentId      
    ,PSSTV.mSegmentId      
    ,PSSTV.SegmentSource      
    ,PSSTV.SegmentOrigin      
    ,PSSTV.SegmentDescription      
    ,ISNULL(PSRT.RequirementTagId, 0) AS RequirementTagId      
    ,ISNULL(LPRT.TagType, '') AS TagType      
    ,ISNULL(LPRT.SortOrder, 0) AS SortOrder      
    ,PSSTV.SequenceNumber      
    ,PSSTV.IsSegmentStatusActive      
    ,@ProjectName      
    ,PSSTV.ParentSegmentStatusId      
    ,PSSTV.IndentLevel      
    ,CASE      
   WHEN ISNULL(LPRT.TagType, '') = 'NS' OR      
    ISNULL(LPRT.TagType, '') = 'NP' THEN 1      
   ELSE 0      
  END AS IsDeleted      
    ,(Select SourceTagFormat from #ProjectInfo) AS SourceTagFormat    
 ,(Select UnitOfMeasureValueTypeId from #ProjectInfo)  AS UnitOfMeasureValueTypeId    
      
 FROM ProjectSegmentStatusView PSSTV     with (nolock)  
 INNER JOIN TaggedSegmentsCte TSC     with (nolock)  
  ON PSSTV.SegmentStatusId = TSC.SegmentStatusId      
 INNER JOIN ProjectSection PS    with (nolock)   
  ON PSSTV.SectionId = PS.SectionId      
 LEFT JOIN ProjectSegmentRequirementTag PSRT       WITH (NOLOCK)
  ON PSSTV.SegmentStatusId = PSRT.SegmentStatusId      
 LEFT JOIN LuProjectRequirementTag LPRT    with (nolock)   
  ON PSRT.RequirementTagId = LPRT.RequirementTagId;    
--2. FIND SUBMITTALS ARTICLE PARAGRAPHS      
WITH SubmittlesChildCte      
AS      
(SELECT      
  CPSSTV.SegmentStatusId      
    ,CPSSTV.ParentSegmentStatusId      
 FROM ProjectSegmentStatusView PSSTV     with (nolock)  
 INNER JOIN ProjectSegmentStatusView CPSSTV     with (nolock)  
  ON PSSTV.SegmentStatusId = CPSSTV.ParentSegmentStatusId      
 WHERE PSSTV.ProjectId = @PProjectId      
 AND PSSTV.CustomerId = @PCustomerID      
 AND PSSTV.SegmentDescription LIKE '%' + @SubmittalsWord      
 AND PSSTV.IndentLevel = 2      
 AND CPSSTV.IsSegmentStatusActive = 1      
 UNION ALL      
 SELECT      
  CPSSTV.SegmentStatusId      
    ,CPSSTV.ParentSegmentStatusId      
 FROM ProjectSegmentStatusView CPSSTV   with (nolock)  
 INNER JOIN SubmittlesChildCte SCC 
  ON CPSSTV.ParentSegmentStatusId = SCC.SegmentStatusId      
 WHERE CPSSTV.IsSegmentStatusActive = 1)      
      
INSERT INTO #SegmentsTable (SourceTag, Author, [Description], SegmentStatusId, mSegmentStatusId, SegmentId, mSegmentId      
, SegmentSource, SegmentOrigin, SegmentDescription, RequirementTagId, TagType, SortOrder, SequenceNumber, IsSegmentStatusActive, ParentSegmentStatusId, IndentLevel, IsDeleted, SourceTagFormat,UnitOfMeasureValueTypeId)      
 SELECT DISTINCT      
  PS.SourceTag      
    ,PS.Author      
    ,PS.[Description]      
    ,PSSTV.SegmentStatusId      
    ,PSSTV.mSegmentStatusId      
    ,PSSTV.SegmentId      
    ,PSSTV.mSegmentId      
    ,PSSTV.SegmentSource      
    ,PSSTV.SegmentOrigin      
    ,PSSTV.SegmentDescription      
    ,ISNULL(PSRT.RequirementTagId, 0) AS RequirementTagId      
    ,ISNULL(LPRT.TagType, '') AS TagType      
    ,ISNULL(LPRT.SortOrder, 0) AS SortOrder      
    ,PSSTV.SequenceNumber      
    ,PSSTV.IsSegmentStatusActive      
    ,PSSTV.ParentSegmentStatusId      
    ,PSSTV.IndentLevel      
    ,CASE      
   WHEN ISNULL(LPRT.TagType, '') = 'NS' OR      
    ISNULL(LPRT.TagType, '') = 'NP' THEN 1      
   ELSE 0      
  END AS IsDeleted      
    ,(Select SourceTagFormat from #ProjectInfo) AS SourceTagFormat    
 ,(Select UnitOfMeasureValueTypeId from #ProjectInfo)  AS UnitOfMeasureValueTypeId    
 FROM ProjectSegmentStatusView PSSTV  WITH (NOLOCK)    
 INNER JOIN SubmittlesChildCte SCC WITH (NOLOCK)     
  ON PSSTV.SegmentStatusId = SCC.SegmentStatusId      
 INNER JOIN ProjectSection PS     with (nolock)  
  ON PSSTV.SectionId = PS.SectionId      
 LEFT JOIN ProjectSegmentRequirementTag PSRT     with (nolock)  
  ON PSSTV.SegmentStatusId = PSRT.SegmentStatusId      
 LEFT JOIN LuProjectRequirementTag LPRT     with (nolock)  
  ON PSRT.RequirementTagId = LPRT.RequirementTagId      
      
      
;      
WITH cte      
AS      
(SELECT      
  s.SegmentStatusId      
    ,s.ParentSegmentStatusId      
    ,s.isDeleted      
 FROM #SegmentsTable AS s      
 WHERE s.isDeleted = 1      
 UNION ALL      
 SELECT      
  s.SegmentStatusId      
    ,s.ParentSegmentStatusId      
    ,CONVERT(BIT, 1) AS isDeleted      
 FROM #SegmentsTable AS s      
 INNER JOIN cte AS c      
  ON s.ParentSegmentStatusId = c.SegmentStatusId)      
DELETE s      
 FROM cte      
 INNER JOIN #SegmentsTable AS s      
  ON cte.SegmentStatusId = s.SegmentStatusId;      
      
      
      
DELETE FROM #SegmentsTable      
WHERE TagType IN('RS','RT','RE','ST','PI','ML','MT','PL')    
      
DELETE FROM #SegmentsTable      
WHERE @PIsIncludeUntagged = 0      
 AND TagType = '';      
      
--SELECT FINAL DATA      
if (not exists (select 1 from #SegmentsTable))      
BEGIN      
INSERT INTO #SegmentsTable(ProjectName)      
VALUES(@ProjectName)      
END      
--ELSE      
--BEGIN      
SELECT      
  dbo.[fnGetSegmentDescriptionTextForRSAndGT](@PProjectId,@PCustomerID, STbl.SegmentDescription) AS SegmentDescriptionNew      
   ,*      
FROM #SegmentsTable STbl      
WHERE STbl.ProjectName IS NOT NULL      
ORDER BY STbl.SourceTag ASC, STbl.SequenceNumber ASC, STbl.SortOrder ASC;      
--END      
      
SELECT      
 SCView.*      
FROM (SELECT DISTINCT      
  SegmentStatusId      
 FROM #SegmentsTable) AS PSST      
INNER JOIN SegmentChoiceView SCView WITH (NOLOCK)     
 ON PSST.SegmentStatusId = SCView.SegmentStatusId      
WHERE SCView.IsSelected = 1      
      
      
      
SELECT DISTINCT      
 (PS.SectionId)      
   ,PS.SourceTag      
   ,PS.Description      
   ,PS.SectionCode      
FROM ProjectSection PS   with (nolock)    
 WHERE PS.ProjectId=@PProjectId AND PS.CustomerId=@PCustomerID      
END
GO
PRINT N'Altering [dbo].[usp_GetSubmittalsLog]...';


GO
ALTER PROCEDURE [dbo].[usp_GetSubmittalsLog]    
 -- exec [dbo].[usp_GetSubmittalsLog]  6067,2227,1    
 @ProjectId INT ,   
 @CustomerID INT,   
 @IsIncludeUntagged BIT   
AS   
  
BEGIN  
 DECLARE @PProjectId INT = @ProjectId;  
 DECLARE @PCustomerID INT = @CustomerID;  
 DECLARE @PIsIncludeUntagged BIT = @IsIncludeUntagged;  
  
-- SET NOCOUNT ON added to prevent extra result sets from   
  
-- interfering with SELECT statements.   
SET NOCOUNT ON;  
 -- Insert statements for procedure here   
DECLARE @SubmittalsWord NVARCHAR(1024) = 'submittals';  
DECLARE @ProjectName NVARCHAR(500)='';  
--DECLARE @ProjectSourceTagFormate NVARCHAR(MAX)='';  
Declare @SourceTagFormat  VARCHAR(10);  
Declare @UnitOfMeasureValueTypeId int;  
DECLARE @RequirementsTagTbl TABLE (   
TagType NVARCHAR(5),   
RequirementTagId INT   
);  
  
DROP TABLE IF EXISTS #SegmentsTable;  
CREATE TABLE #SegmentsTable (  
 SourceTag VARCHAR(10)  
   ,SectionId INT  
   ,Author NVARCHAR(500)  
   ,Description NVARCHAR(MAX)  
   ,SegmentStatusId INT  
   ,mSegmentStatusId INT  
   ,SegmentId INT  
   ,mSegmentId INT  
   ,SegmentSource CHAR(1)  
   ,SegmentOrigin CHAR(1)  
   ,SegmentDescription NVARCHAR(MAX)  
   ,RequirementTagId INT  
   ,TagType NVARCHAR(5)  
   ,SortOrder INT  
   ,SequenceNumber DECIMAL(18, 4)  
   ,IsSegmentStatusActive INT  
   ,ProjectName NVARCHAR(500)  
   ,ParentSegmentStatusId INT  
   ,IndentLevel INT  
   ,IsDeleted BIT NULL  
   ,SourceTagFormat VARCHAR(10)  
   ,UnitOfMeasureValueTypeId INT  
   ,mSegmentRequirementTagId INT  
);  
  
--CREATE TABLE #ProjectInfo (  
-- ProjectId INT  
--   ,SourceTagFormat NVARCHAR(MAX)  
--   ,UnitOfMeasureValueTypeId INT  
--)  
  
--SET VARIABLES TO DEFAULT VALUE   
  
DROP TABLE IF EXISTS #Tags;  
CREATE TABLE #Tags (  
 TagType NVARCHAR(2)  
)  
  
INSERT INTO #Tags  
 SELECT  
  *  
 FROM STRING_SPLIT('CT,DC,FR,II,IQ,LR,XM,MQ,MO,OM,PD,PE,PR,QS,SA,SD,TR,WE,WT,WS,S1,S2,S3,S4,S5,S6,S7,NS,NP', ',')  
  
INSERT INTO @RequirementsTagTbl (RequirementTagId, TagType)  
 SELECT  
  RequirementTagId  
    ,rt.TagType  
 FROM [dbo].[LuProjectRequirementTag] AS rt WITH (NOLOCK)  
 INNER JOIN #Tags AS t  
  ON t.TagType = rt.TagType  
  
--WHERE TagType IN ('CT', 'DC', 'FR', 'II', 'IQ', 'LR', 'XM', 'MQ', 'MO', 'OM', 'PD', 'PE', 'PR', 'QS',  
--'SA', 'SD', 'TR', 'WE', 'WT', 'WS', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'NS', 'NP');  
--SET @ProjectName = (SELECT  
--  [Name]  
-- FROM Project WITH (NOLOCK)  
-- WHERE ProjectId = @PProjectId);  
  
--INSERT INTO #ProjectInfo  
SELECT  
 @ProjectName = pt.Name  
   ,@SourceTagFormat = SourceTagFormat  
   ,@UnitOfMeasureValueTypeId = UnitOfMeasureValueTypeId  
FROM ProjectSummary ps WITH (NOLOCK)  
INNER JOIN Project pt WITH (NOLOCK)  
 ON ps.ProjectId = pt.ProjectId  
WHERE ps.ProjectId = @PProjectId;  
  
DROP TABLE IF EXISTS #tmp_ProjectSegmentStatusView;  
SELECT  
 * INTO #tmp_ProjectSegmentStatusView  
FROM ProjectSegmentStatusView PSSTV  WITH (NOLOCK)  
WHERE PSSTV.ProjectId = @PProjectId  
AND PSSTV.CustomerId = @PCustomerID  
AND PSSTV.IsSegmentStatusActive = 1;  
  
DROP TABLE IF EXISTS #tmp_ProjectSegmentRequirementTag;  
SELECT  
 PSRT.* INTO #tmp_ProjectSegmentRequirementTag  
FROM ProjectSegmentRequirementTag PSRT  WITH (NOLOCK)  
WHERE PSRT.ProjectId = @PProjectId  
AND PSRT.CustomerId = @PCustomerID;  
  
--1. FIND PARAGRAPHS WHICH ARE TAGGED BY GIVEN REQUIREMENTS TAGS  
WITH TaggedSegmentsCte  
AS  
(SELECT  
  PSSTV.SegmentStatusId  
    ,PSSTV.ParentSegmentStatusId  
 FROM #tmp_ProjectSegmentStatusView PSSTV WITH (NOLOCK)  
 INNER JOIN #tmp_ProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
  ON PSSTV.SegmentStatusId = PSRT.SegmentStatusId  
 INNER JOIN @RequirementsTagTbl TagTbl  
  ON PSRT.RequirementTagId = TagTbl.RequirementTagId  
 WHERE PSSTV.ProjectId = @PProjectId  
 AND PSSTV.IsParentSegmentStatusActive = 1  
 AND PSSTV.SegmentStatusTypeId < 6  
 UNION ALL  
 SELECT  
  CPSSTV.SegmentStatusId  
    ,CPSSTV.ParentSegmentStatusId  
 FROM #tmp_ProjectSegmentStatusView CPSSTV WITH (NOLOCK)  
 INNER JOIN TaggedSegmentsCte TSC  
  ON CPSSTV.ParentSegmentStatusId = TSC.SegmentStatusId  
 WHERE CPSSTV.IsParentSegmentStatusActive = 1  
 AND CPSSTV.SegmentStatusTypeId < 6)  
  
INSERT INTO #SegmentsTable (SourceTag, SectionId, Author, [Description], SegmentStatusId, mSegmentStatusId, SegmentId, mSegmentId  
, SegmentSource, SegmentOrigin, SegmentDescription, RequirementTagId, TagType, SortOrder, SequenceNumber, IsSegmentStatusActive, ProjectName  
, ParentSegmentStatusId, IndentLevel, IsDeleted, SourceTagFormat, UnitOfMeasureValueTypeId, mSegmentRequirementTagId)  
 SELECT DISTINCT  
  PS.SourceTag  
    ,PS.SectionId  
    ,PS.Author  
    ,PS.[Description]  
    ,PSSTV.SegmentStatusId  
    ,PSSTV.mSegmentStatusId  
    ,PSSTV.SegmentId  
    ,PSSTV.mSegmentId  
    ,PSSTV.SegmentSource  
    ,PSSTV.SegmentOrigin  
    ,PSSTV.SegmentDescription  
    ,ISNULL(PSRT.RequirementTagId, 0) AS RequirementTagId  
    ,ISNULL(LPRT.TagType, '') AS TagType  
    ,ISNULL(LPRT.SortOrder, 0) AS SortOrder  
    ,PSSTV.SequenceNumber  
    ,PSSTV.IsSegmentStatusActive  
    ,@ProjectName  
    ,PSSTV.ParentSegmentStatusId  
    ,PSSTV.IndentLevel  
    ,CASE  
   WHEN ISNULL(LPRT.TagType, '') = 'NS' OR  
    ISNULL(LPRT.TagType, '') = 'NP' THEN 1  
   ELSE 0  
  END AS IsDeleted  
    ,@SourceTagFormat  
  AS SourceTagFormat  
    ,@UnitOfMeasureValueTypeId  
  AS UnitOfMeasureValueTypeId  
    ,PSRT.mSegmentRequirementTagId  
 FROM #tmp_ProjectSegmentStatusView PSSTV WITH (NOLOCK)  
 INNER JOIN TaggedSegmentsCte TSC  
  ON PSSTV.SegmentStatusId = TSC.SegmentStatusId  
 INNER JOIN ProjectSection PS WITH (NOLOCK)  
  ON PSSTV.SectionId = PS.SectionId  
 LEFT JOIN #tmp_ProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
  ON PSSTV.SegmentStatusId = PSRT.SegmentStatusId  
 LEFT JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)  
  ON PSRT.RequirementTagId = LPRT.RequirementTagId;  
  
--2. FIND SUBMITTALS ARTICLE PARAGRAPHS   
WITH SubmittlesChildCte  
AS  
(SELECT  
  CPSSTV.SegmentStatusId  
    ,CPSSTV.ParentSegmentStatusId  
 FROM #tmp_ProjectSegmentStatusView PSSTV  
 INNER JOIN #tmp_ProjectSegmentStatusView CPSSTV WITH (NOLOCK)  
  ON PSSTV.SegmentStatusId = CPSSTV.ParentSegmentStatusId  
 WHERE PSSTV.ProjectId = @PProjectId  
 AND PSSTV.CustomerId = @PCustomerID  
 AND PSSTV.SegmentDescription LIKE '%' + @SubmittalsWord  
 AND PSSTV.IndentLevel = 2  
 AND CPSSTV.IsSegmentStatusActive = 1  
 UNION ALL  
 SELECT  
  CPSSTV.SegmentStatusId  
    ,CPSSTV.ParentSegmentStatusId  
 FROM #tmp_ProjectSegmentStatusView CPSSTV WITH (NOLOCK)  
 INNER JOIN SubmittlesChildCte SCC  
  ON CPSSTV.ParentSegmentStatusId = SCC.SegmentStatusId  
 WHERE CPSSTV.IsParentSegmentStatusActive = 1  
 AND CPSSTV.SegmentStatusTypeId < 6)  
  
INSERT INTO #SegmentsTable (SourceTag, Author, [Description], SegmentStatusId, mSegmentStatusId, SegmentId, mSegmentId  
, SegmentSource, SegmentOrigin, SegmentDescription, RequirementTagId, TagType, SortOrder, SequenceNumber, IsSegmentStatusActive, 
ParentSegmentStatusId, IndentLevel, IsDeleted, SourceTagFormat, UnitOfMeasureValueTypeId, mSegmentRequirementTagId)  
 SELECT DISTINCT  
  PS.SourceTag  
    ,PS.Author  
    ,PS.[Description]  
    ,PSSTV.SegmentStatusId  
    ,PSSTV.mSegmentStatusId  
    ,PSSTV.SegmentId  
    ,PSSTV.mSegmentId  
    ,PSSTV.SegmentSource  
    ,PSSTV.SegmentOrigin  
    ,PSSTV.SegmentDescription  
    ,ISNULL(PSRT.RequirementTagId, 0) AS RequirementTagId  
    ,ISNULL(LPRT.TagType, '') AS TagType  
    ,ISNULL(LPRT.SortOrder, 0) AS SortOrder  
    ,PSSTV.SequenceNumber  
    ,PSSTV.IsSegmentStatusActive  
    ,PSSTV.ParentSegmentStatusId  
    ,PSSTV.IndentLevel  
    ,CASE  
   WHEN ISNULL(LPRT.TagType, '') = 'NS' OR  
    ISNULL(LPRT.TagType, '') = 'NP' THEN 1  
   ELSE 0  
  END AS IsDeleted  
    ,@SourceTagFormat  
  AS SourceTagFormat  
    ,@UnitOfMeasureValueTypeId  
  AS UnitOfMeasureValueTypeId  
    ,PSRT.mSegmentRequirementTagId  
 FROM #tmp_ProjectSegmentStatusView PSSTV WITH (NOLOCK)  
 INNER JOIN SubmittlesChildCte SCC WITH (NOLOCK)  
  ON PSSTV.SegmentStatusId = SCC.SegmentStatusId  
 INNER JOIN ProjectSection PS WITH (NOLOCK)  
  ON PSSTV.SectionId = PS.SectionId  
 LEFT JOIN #tmp_ProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
  ON PSSTV.SegmentStatusId = PSRT.SegmentStatusId  
 LEFT JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)  
  ON PSRT.RequirementTagId = LPRT.RequirementTagId  
  
;  
WITH cte  
AS  
(SELECT  
  s.SegmentStatusId  
    ,s.ParentSegmentStatusId  
    ,s.isDeleted  
 FROM #SegmentsTable AS s  
 WHERE s.isDeleted = 1  
 UNION ALL  
 SELECT  
  s.SegmentStatusId  
    ,s.ParentSegmentStatusId  
    ,CONVERT(BIT, 1) AS isDeleted  
 FROM #SegmentsTable AS s  
 INNER JOIN cte AS c  
  ON s.ParentSegmentStatusId = c.SegmentStatusId)  
  
DELETE s  
 FROM cte  
 INNER JOIN #SegmentsTable AS s  
  ON cte.SegmentStatusId = s.SegmentStatusId;  
  
--DELETE FROM #SegmentsTable  
--WHERE TagType IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP')  
  
--new changes--  
--Start change--  
DELETE FROM #SegmentsTable  
WHERE ParentSegmentStatusId NOT IN (SELECT  
   SegmentStatusId  
  FROM #SegmentsTable)  
 AND TagType IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP')  
  
DELETE FROM #SegmentsTable  
WHERE SequenceNumber IN (SELECT  
   SequenceNumber  
  FROM #SegmentsTable  
  GROUP BY SequenceNumber  
  HAVING COUNT(1) > 1)  
 AND TagType IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP')  
 AND mSegmentRequirementTagId IS NOT NULL  
  
DELETE FROM #SegmentsTable  
WHERE SegmentStatusId IN (SELECT  
   SegmentStatusId  
  FROM #SegmentsTable  
  WHERE TagType NOT IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP'))  
 AND TagType IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP');  
  
UPDATE #SegmentsTable  
SET TagType = ''  
WHERE TagType IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP')  
--End Change--  
  
DELETE FROM #SegmentsTable  
WHERE @PIsIncludeUntagged = 0  
 AND TagType = '';  
  
--SELECT FINAL DATA  
IF (NOT EXISTS (SELECT  
  1  
 FROM #SegmentsTable)  
)  
BEGIN  
INSERT INTO #SegmentsTable (ProjectName)  
 VALUES (@ProjectName)  
END  
  
--ELSE   
  
--BEGIN   
  
SELECT  
dbo.[fnGetSegmentDescriptionTextForRSAndGT](@PProjectId, @PCustomerID, STbl.SegmentDescription) AS SegmentDescriptionNew  
   ,STbl.Description, STbl.SegmentStatusId,STbl.SequenceNumber, STbl.SourceTag
   ,STbl.TagType,STbl.ProjectName,STbl.Author,STbl.SourceTagFormat,STbl.UnitOfMeasureValueTypeId
FROM #SegmentsTable STbl  
WHERE STbl.ProjectName IS NOT NULL  
ORDER BY STbl.SourceTag ASC, STbl.SequenceNumber ASC, STbl.SortOrder ASC;  
  
--END   
  
SELECT  
 SCView.SegmentStatusId, SCView.SegmentChoiceCode, SCView.SectionId,SCView.ChoiceTypeId
 ,SCView.SegmentChoiceCode,SCView.ChoiceOptionCode, SCView.SortOrder, SCView.ChoiceOptionSource
 ,SCView.OptionJson
FROM (SELECT DISTINCT  
  SegmentStatusId  
 FROM #SegmentsTable) AS PSST  
INNER JOIN SegmentChoiceView SCView WITH (NOLOCK)  
 ON PSST.SegmentStatusId = SCView.SegmentStatusId  
WHERE SCView.IsSelected = 1  
  
SELECT DISTINCT  
 (PS.SectionId)  
   ,PS.SourceTag  
   ,PS.Description  
   ,PS.SectionCode  
FROM ProjectSection PS WITH (NOLOCK)  
WHERE PS.ProjectId = @PProjectId  
AND PS.CustomerId = @PCustomerID  
  
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
PRINT N'Altering [dbo].[usp_GetProjectForImportSection]...';


GO
ALTER Procedure [dbo].usp_GetProjectForImportSection(                          
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
PRINT N'Altering [dbo].[usp_GetTagReports]...';


GO
ALTER PROCEDURE [dbo].[usp_GetTagReports]                    
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
PRINT N'Altering [dbo].[getProjectDetailsById]...';


GO
ALTER PROC [dbo].[getProjectDetailsById]  
(  
 @projectId int,  
 @customerID int  
)  
AS  
BEGIN
  
 DECLARE @PprojectId int = @projectId;
 --DECLARE @PcustomerID int =  @customerID;

SELECT
	P.Name
   ,P.Description
FROM Project p WITH (NOLOCK)
WHERE p.ProjectId = @PprojectId
AND ISNULL(IsDeleted,0) = 0
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
		And ISNULL(P.IsArchived,0)=0 and ISNULL(p.IsShowMigrationPopup,0)=0
END
GO
PRINT N'Altering [dbo].[usp_ApplyMasterUpdatesToProject]...';


GO
ALTER PROCEDURE [dbo].[usp_ApplyMasterUpdatesToProject]    
 @ProjectId INT, @CustomerId INT AS    
BEGIN    
DECLARE @PProjectId INT = @ProjectId;    
DECLARE @PCustomerId INT = @CustomerId;    
    
DECLARE @InsertAction NVARCHAR(10) = 'INSERT';    
DECLARE @UpdateAction NVARCHAR(10) = 'UPDATE';    
DECLARE @DeleteAction NVARCHAR(10) = 'DELETE';    
DECLARE @DeleteRevertAction NVARCHAR(20) = 'DELETE_REVERT';    
    
DECLARE @LastMasterApplyDate DATETIME2(7) = NULL;    
DECLARE @IsProjectIdEntryExists BIT = 0;    
DECLARE @MasterDataTypeId INT = NULL;    
    
DECLARE @LastMasterUpdatedByActionType DATETIME2(7) = NULL;    
DECLARE @TableName NVARCHAR(50) = NULL;    
DECLARE @CommandType NVARCHAR(50) = NULL;    
DECLARE @IsProcess BIT = 0;    
    
DECLARE @LoopCounter INT = 1;    
DECLARE @ApplyMasterUpdateTypes TABLE (    
 Id INT IDENTITY(1,1) NOT NULL,    
 TableName NVARCHAR(50) NULL,    
 CommandType NVARCHAR(50) NULL    
);    
    
--INSERT VALUES INSIDE ApplyMasterUpdateTypes TABLE    
INSERT INTO @ApplyMasterUpdateTypes (TableName, CommandType)    
 VALUES ('Section', @InsertAction),    
 ('Section', @UpdateAction),    
 ('Section', @DeleteAction),    
 ('SegmentStatus', @UpdateAction),    
 ('SegmentRequirementTag', @DeleteAction)    
    
--GET MasterDataTypeId OF PROJECT    
SET @MasterDataTypeId = (SELECT TOP 1    
  P.MasterDataTypeId    
 FROM Project P WITH (NOLOCK)    
 WHERE P.ProjectId = @PProjectId);    
    
--CHECK ProjectId ENTRY EXISTS OR NOT AND GET LastUpdateDate OF IT'S    
IF EXISTS (SELECT TOP 1    
  1    
 FROM ApplyMasterUpdateLog AML WITH (NOLOCK)    
 WHERE AML.ProjectId = @PProjectId)    
BEGIN    
SET @IsProjectIdEntryExists = 1;    
SET @LastMasterApplyDate = (SELECT TOP 1    
  AML.LastUpdateDate    
 FROM ApplyMasterUpdateLog AML WITH (NOLOCK)    
 WHERE AML.ProjectId = @PProjectId    
 ORDER BY AML.ID DESC);    
END    
    
--LOOP TYPES TO CHECK WHICH TO BE PROCESS AND WHICH TO BE NOT    
declare @ApplyMasterUpdateTypesRowCount INT=( SELECT COUNT(*) FROM @ApplyMasterUpdateTypes)    
WHILE (@LoopCounter <= @ApplyMasterUpdateTypesRowCount)    
BEGIN    
SELECT    
 @TableName = AMT.TableName    
   ,@CommandType = AMT.CommandType    
FROM @ApplyMasterUpdateTypes AMT    
WHERE AMT.Id = @LoopCounter;    
    
SET @LastMasterUpdatedByActionType = (SELECT TOP 1    
  MUL.CreatedDate    
 FROM SLCMaster..MasterUpdateLog MUL WITH (NOLOCK)    
 WHERE ISNULL(MUL.RecordsCount, 0) > 0    
 AND MUL.TableName = @TableName    
 AND MUL.CommandType = @CommandType    
 AND MUL.MasterDataTypeId = @MasterDataTypeId    
 ORDER BY MUL.id DESC);    
    
IF @IsProjectIdEntryExists = 0    
BEGIN    
SET @IsProcess = 1;    
END    
ELSE IF @LastMasterUpdatedByActionType IS NOT NULL AND @LastMasterApplyDate < @LastMasterUpdatedByActionType    
BEGIN    
SET @IsProcess = 1;    
END    
    
--PROCESS ACCORDING TO THAT    
IF @TableName = 'Section'     
 AND @CommandType = @InsertAction     
 AND @IsProcess = 1    
BEGIN    
EXEC usp_InsertNewSection_ApplyMasterUpdate @PProjectId    
             ,@PCustomerId;    
END    
ELSE    
IF @TableName = 'Section'    
 AND @CommandType = @UpdateAction    
 AND @IsProcess = 1    
BEGIN    
EXEC usp_UpdateSection_ApplyMasterUpdate @PProjectId    
          ,@PCustomerId;    
EXEC usp_InsertNewSection_ApplyMasterUpdate @PProjectId    
             ,@PCustomerId;    
END    
ELSE    
IF @TableName = 'Section'    
 AND @CommandType = @DeleteAction    
 AND @IsProcess = 1    
BEGIN    
EXEC usp_DeleteMasterSection_ApplyMasterUpdate @PProjectId    
             ,@PCustomerId;    
SET @LoopCounter = @LoopCounter;    
END    
ELSE IF @TableName = 'SegmentStatus' AND @CommandType = @UpdateAction    
BEGIN    
--NOTE:Moved [EXEC usp_UpdateSegmentStatus_ApplyMasterUpdate] under [usp_GetSegments]    
SET @LoopCounter = @LoopCounter;    
END    
ELSE    
IF @TableName = 'SegmentRequirementTag'    
 AND @CommandType = @DeleteAction    
 AND @IsProcess = 1    
BEGIN    
--NOTE:Moved [EXEC usp_DeleteSegmentRequirementTag_ApplyMasterUpdate] under [usp_GetSegments]    
SET @LoopCounter = @LoopCounter;    
END    
    
SET @LoopCounter = @LoopCounter + 1;    
END    
    
--INSERT/UPDATE ENTRY OF ProjectId IN ApplyMasterUpdateLog    
IF @IsProjectIdEntryExists = 0    
BEGIN    
INSERT INTO ApplyMasterUpdateLog (ProjectId, LastUpdateDate)    
 VALUES (@PProjectId, GETUTCDATE());    
END    
ELSE    
BEGIN    
UPDATE AML    
SET AML.LastUpdateDate = GETUTCDATE()    
FROM ApplyMasterUpdateLog AML WITH (NOLOCK)    
WHERE AML.ProjectId = @PProjectId    
END    
END
GO
PRINT N'Altering [dbo].[usp_CheckDivisionIsAccessForImportWord]...';


GO
ALTER PROCEDURE [dbo].[usp_CheckDivisionIsAccessForImportWord]
(
 @ProjectId INT,
 @CustomerId INT,
 @SourceTag VARCHAR(10),
 @UserId INT,
 @ParentSectionId INT,
 @UserAccessDivisionId NVARCHAR(MAX) = ''
)
AS
BEGIN

 DECLARE @PProjectId INT = @ProjectId;
 DECLARE @PCustomerId INT = @CustomerId;
 DECLARE @PSourceTag VARCHAR(10) = @SourceTag;
 DECLARE @PUserId INT = @UserId;
 DECLARE @PParentSectionId INT = @ParentSectionId;
 DECLARE @PUserAccessDivisionId NVARCHAR(MAX) = @UserAccessDivisionId;

--DECLARE VARIABLES
DECLARE @UserAccessDivisionIdTbl TABLE (
	DivisionId INT
);
DECLARE @FutureDivisionIdOfSectionTbl TABLE (
	DivisionId INT
);
DECLARE @FutureDivisionId INT = NULL;

DECLARE @BsdMasterDataTypeId INT = 1;
DECLARE @MasterDataTypeId INT = ( SELECT TOP 1
		MasterDataTypeId
	FROM Project WITH(NOLOCK)
	WHERE ProjectId = @PProjectId);

DECLARE @IsSuccess BIT = 1;
DECLARE @ErrorMessage NVARCHAR(MAX) = '';

--PUT USER DIVISION ID'S INTO TABLE
INSERT INTO @UserAccessDivisionIdTbl (DivisionId)
	SELECT
		*
	FROM dbo.fn_SplitString(@PUserAccessDivisionId, ',');

--CALCULATE DIVISION ID OF USER SECTION WHICH IS GOING TO BE
INSERT INTO @FutureDivisionIdOfSectionTbl (DivisionId)
EXEC usp_CalculateDivisionIdForUserSection @PProjectId
										  ,@PCustomerId
										  ,@PSourceTag
										  ,@PUserId
										  ,@PParentSectionId
SELECT TOP 1
	@FutureDivisionId = DivisionId
FROM @FutureDivisionIdOfSectionTbl;

--PERFORM VALIDATIONS
IF @PUserAccessDivisionId != ''
	AND @FutureDivisionId NOT IN (SELECT
			DivisionId
		FROM @UserAccessDivisionIdTbl)
BEGIN
SET @IsSuccess = 0;
SET @ErrorMessage = 'You don''t have access rights to import section(s) in this division';
END

--If Division id is null and parent section is Unassigned Sections then return the division id from SLCMaster..Division
IF(COALESCE(@FutureDivisionId, 0) =0)
BEGIN
SELECT @FutureDivisionId =DV.DivisionId 
FROM SLCMaster..Division DV WITH(NOLOCK)
INNER JOIN ProjectSection PS  WITH(NOLOCK)
ON TRIM(PS.Description)=TRIM(DV.DivisionTitle) 
AND DV.FormatTypeId=PS.FormatTypeId 
INNER JOIN Project P WITH(NOLOCK) ON p.ProjectId=PS.ProjectId
AND DV.MasterDataTypeId=P.MasterDataTypeId AND P.CustomerId=PS.CustomerId
WHERE PS.SectionId=@PParentSectionId 
AND PS.CustomerId=@PCustomerId
AND TRIM(PS.Description) = TRIM('Unassigned Sections')
END

--RETURN DATA
SELECT
	@IsSuccess AS IsSuccess
   ,@ErrorMessage AS ErrorMessage
   ,COALESCE(@FutureDivisionId, 0) AS DivisionId

END
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

IF (@IsLocked != 1)
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
PRINT N'Altering [dbo].[usp_checkSectionHasOLSF]...';


GO
ALTER PROCEDURE [dbo].[usp_checkSectionHasOLSF]  
  @ProjectId int   
 ,@CustomerId int  
 ,@SectionId int  
AS  
BEGIN
  
  DECLARE @PProjectId int = @ProjectId;
  DECLARE @PCustomerId int = @CustomerId;
  DECLARE @PSectionId int  = @SectionId;

	SELECT s.SegmentStatusId,SpecTypeTagId,IsDeleted INTO #Temp_PSS
		FROM ProjectSegmentStatus AS s WITH (NOLOCK)
		WHERE s.ProjectId = @PprojectId
		AND s.CustomerId = @PcustomerId
		AND s.SectionId = @PSectionId

--TODO:Check if Section is opened or not  
IF ((SELECT TOP 1
			COUNT(s.SegmentStatusId)
		from #Temp_PSS S with (nolock))
	> 0)
BEGIN
IF (EXISTS (SELECT top 1 
			1 AS StatusCount
		FROM #Temp_PSS PSST WITH (NOLOCK)
		WHERE PSST.SpecTypeTagId IN (1, 2, 3, 4)
		AND (PSST.IsDeleted IS NULL
		OR PSST.IsDeleted = 0))
	)
SELECT
	1 AS HasOLSFSegment;
ELSE
SELECT
	0 AS HasOLSFSegment;

END
ELSE
BEGIN

IF (EXISTS (SELECT top 1 1 FROM SLCMaster..SegmentStatus SST WITH (NOLOCK)
		INNER JOIN  ProjectSection AS ps WITH (NOLOCK)
		ON SST.SectionId = Ps.mSectionId
		and SST.SpecTypeTagId IN (1, 2)
		AND (SST.IsDeleted IS NULL
		OR SST.IsDeleted = 0)
		WHERE ps.ProjectId = @PprojectId
		AND ps.SectionId = @PSectionId
		AND ps.CustomerId = @PcustomerId
		)
	)
SELECT
	1 AS HasOLSFSegment;
ELSE
SELECT
	0 AS HasOLSFSegment;
END
END
GO
PRINT N'Altering [dbo].[usp_CheckSectionIsLocked]...';


GO
ALTER PROCEDURE [dbo].[usp_CheckSectionIsLocked]
 @SectionId INT 
  AS  
BEGIN
  
  DECLARE @PSectionId int  = @SectionId;
SELECT
	SectionId
   ,ParentSectionId
   ,mSectionId
   ,ProjectId
   ,CustomerId
   ,UserId
   ,DivisionId
   ,ISNULL(DivisionCode, 0) AS DivisionCode
   ,ISNULL([Description], '') AS [Description]
   ,LevelId
   ,IsLastLevel
   ,ISNULL(SourceTag, '') AS SourceTag
   ,Author
   ,TemplateId
   ,SectionCode
   ,ISNULL(IsDeleted, 0) AS IsDeleted
   ,ISNULL(IsLocked, 0) AS IsLocked
   ,LockedBy
   ,ISNULL(LockedByFullName, '') AS LockedByFullName
   ,CreateDate
   ,CreatedBy
   ,ModifiedBy
   ,ModifiedDate
   ,FormatTypeId
   ,SpecViewModeId
   ,IsLockedImportSection
FROM ProjectSection WITH (NOLOCK)
WHERE SectionId = @PSectionId

END
GO
PRINT N'Altering [dbo].[usp_CheckSectionIsLockedForVim]...';


GO
ALTER PROCEDURE [dbo].[usp_CheckSectionIsLockedForVim]      
 @SectionId INT,  
 @ProjectId INT,    
 @CustomerId INT  
  AS  
BEGIN
  
  DECLARE @PProjectId int = @ProjectId;
  DECLARE @PCustomerId int = @CustomerId;
  DECLARE @PSectionId int  = @SectionId;
SELECT
	SectionId
   ,ParentSectionId
   ,mSectionId
   ,ProjectId
   ,CustomerId
   ,UserId
   ,DivisionId
   ,ISNULL(DivisionCode, 0) AS DivisionCode
   ,ISNULL([Description], '') AS [Description]
   ,LevelId
   ,IsLastLevel
   ,ISNULL(SourceTag, '') AS SourceTag
   ,Author
   ,TemplateId
   ,SectionCode
   ,ISNULL(IsDeleted, 0) AS IsDeleted
   ,ISNULL(IsLocked, 0) AS IsLocked
   ,LockedBy
   ,ISNULL(LockedByFullName, '') AS LockedByFullName
   ,CreateDate
   ,CreatedBy
   ,ModifiedBy
   ,ModifiedDate
   ,FormatTypeId
   ,SpecViewModeId
   ,IsLockedImportSection
FROM ProjectSection WITH (NOLOCK)
WHERE  SectionId = @PSectionId

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


END
GO
PRINT N'Altering [dbo].[usp_CreateOrUpdatePrintSetting]...';


GO
ALTER PROCEDURE [dbo].[usp_CreateOrUpdatePrintSetting]          
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
 WHERE ProjectId = @PProjectId  
 AND CustomerId = @PCustomerId  )         
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
WHERE PPS.ProjectId = @PProjectId          
AND  PPS.CustomerId = @PCustomerId 
END      
END
GO
PRINT N'Altering [dbo].[usp_CreateProjectPageSettings]...';


GO
ALTER PROCEDURE [dbo].[usp_CreateProjectPageSettings]  
   @ProjectId INT,    
   @CustomerId INT,  
   @PaperName varchar(500),  
   @IsMirrorMargin bit,  
   @EdgeFooter decimal(18, 2),  
   @EdgeHeader decimal(18, 2),  
   @MarginBottom decimal(18, 2),  
   @MarginLeft decimal(18, 2),  
   @MarginRight decimal(18, 2),  
   @MarginTop decimal(18, 2),  
   @PaperHeight decimal(18, 2),  
   @PaperWidth decimal(18, 2)  
AS  
BEGIN
  
   DECLARE @PProjectId INT = @ProjectId;
   DECLARE @PCustomerId INT = @CustomerId;
   DECLARE @PPaperName varchar(500) = @PaperName;
   DECLARE @PIsMirrorMargin bit = @IsMirrorMargin;
   DECLARE @PEdgeFooter decimal(18, 2) = @EdgeFooter;
   DECLARE @PEdgeHeader decimal(18, 2) = @EdgeHeader;
   DECLARE @PMarginBottom decimal(18, 2) = @MarginBottom;
   DECLARE @PMarginLeft decimal(18, 2) = @MarginLeft;
   DECLARE @PMarginRight decimal(18, 2) = @MarginRight;
   DECLARE @PMarginTop decimal(18, 2) = @MarginTop;
   DECLARE @PPaperHeight decimal(18, 2) = @PaperHeight;
   DECLARE @PPaperWidth decimal(18, 2) =  @PaperWidth;
--SELECT @ProjectId, @CustomerId, @MarginTop, @PMarginBottom, @PMarginLeft, @MarginRight, @PIsMirrorMargin, @PEdgeHeader, @PEdgeFooter  
IF EXISTS (SELECT TOP 1
		1
	FROM ProjectPageSetting WITH (NOLOCK)
	WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId)
BEGIN
UPDATE PPS
SET PPS.MarginTop = @PMarginTop
   ,PPS.MarginBottom = @PMarginBottom
   ,PPS.MarginLeft = @PMarginLeft
   ,PPS.MarginRight = @PMarginRight
   ,PPS.EdgeHeader = @PEdgeHeader
   ,PPS.EdgeFooter = @PEdgeFooter
   ,PPS.IsMirrorMargin = @PIsMirrorMargin
   FROM ProjectPageSetting PPS WITH (NOLOCK)
WHERE PPS.ProjectId = @PProjectId
AND PPS.CustomerId = @PCustomerId

UPDATE PPS
SET PPS.PaperName = @PPaperName
   ,PPS.PaperWidth = @PPaperWidth
   ,PPS.PaperHeight = @PPaperHeight
FROM ProjectPaperSetting PPS WITH (NOLOCK)
WHERE PPS.ProjectId = @PProjectId
AND PPS.CustomerId = @PCustomerId
END
ELSE
BEGIN
INSERT INTO ProjectPageSetting (MarginTop, MarginBottom, MarginLeft, MarginRight, EdgeHeader, EdgeFooter, IsMirrorMargin, ProjectId, CustomerId)
	VALUES (@PMarginTop, @PMarginBottom, @PMarginLeft, @PMarginRight, @PEdgeHeader, @PEdgeFooter, @PIsMirrorMargin, @ProjectId, @PCustomerId);

INSERT INTO ProjectPaperSetting (PaperName, PaperWidth, PaperHeight, ProjectId, CustomerId)
	VALUES (@PPaperName, @PPaperWidth, @PPaperHeight, @PProjectId, @PCustomerId);
END
END
GO
PRINT N'Altering [dbo].[usp_CreateProjectSegmentGlobalTerm]...';


GO
ALTER PROCEDURE [dbo].[usp_CreateProjectSegmentGlobalTerm]    
@CustomerId INT NULL,  
@ProjectId INT NULL,   
@SectionId INT NULL,  
@SegmentId INT NULL,  
@mSegmentId INT NULL,  
@UserGlobalTermId INT NULL,   
@GlobalTermCode INT NULL,  
@CreatedBy INT NULL  
--@IsLocked BIT NULL,    
--@LockedByFullName NVARCHAR NULL,   
--@UserLockedId INT NULL,   
  
AS        
  
BEGIN
  
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PSegmentId INT = @SegmentId;
DECLARE @PmSegmentId INT = @mSegmentId;
DECLARE @PUserGlobalTermId INT = @UserGlobalTermId;
DECLARE @PGlobalTermCode INT = @GlobalTermCode;
DECLARE @PCreatedBy INT = @CreatedBy;
SET NOCOUNT ON;
  
  
    DECLARE @ProjSegmentGlobalTermCount INT = NULL

SET @ProjSegmentGlobalTermCount = (SELECT DISTINCT
		UserGlobalTermId
	FROM ProjectSegmentGlobalTerm WITH (NOLOCK)
	WHERE SectionId = @PSectionId
	AND UserGlobalTermId = @PUserGlobalTermId
	AND (SegmentId = @PSegmentId
	OR mSegmentId = @PmSegmentId)
	AND CustomerId = @PCustomerId
	AND IsDeleted = 0)
  
  
    IF @PSegmentId = 0  
        BEGIN
SET @PSegmentId = NULL;
    
        END
  
    IF @PmSegmentId = 0  
        BEGIN
SET @PmSegmentId = NULL;
    
        END
    
  
 IF(@ProjSegmentGlobalTermCount IS NULL)  
   BEGIN
INSERT INTO ProjectSegmentGlobalTerm (CustomerId, ProjectId, SectionId, SegmentId, mSegmentId, UserGlobalTermId, GlobalTermCode, CreatedDate, CreatedBy)
	VALUES (@PCustomerId, @PProjectId, @PSectionId, @PSegmentId, @PmSegmentId, @PUserGlobalTermId, @PGlobalTermCode, GETUTCDATE(), @PCreatedBy)
END
ELSE
BEGIN
PRINT 'CAN NOT INSERT GT'
END

END
GO
PRINT N'Altering [dbo].[usp_CreateProjectSegmentReferenceStandard]...';


GO
ALTER PROCEDURE [dbo].[usp_CreateProjectSegmentReferenceStandard]  
@ProjectId INT NULL, 
@RefStandardId INT NULL,
@RefStdSource CHAR NULL,
@RefStdCode INT NULL, 
@RefStdEditionId INT NULL,
@mReplaceRefStdId INT NULL,
@IsObsolete BIT NULL, 
@SectionId INT NULL, 
@CustomerId INT NULL,
@SegmentId INT NULL,
@RefStandardSource CHAR  NULL,
@CreatedBy INT NULL,
@mRefStandardId INT NULL,
@mSegmentId INT NULL
AS      

BEGIN
DECLARE @PProjectId INT = @ProjectId
DECLARE @PRefStandardId INT = @RefStandardId;
DECLARE @PRefStdSource CHAR = @RefStdSource;
DECLARE @PRefStdCode INT = @RefStdCode;
DECLARE @PRefStdEditionId INT = @RefStdEditionId;
DECLARE @PmReplaceRefStdId INT = @mReplaceRefStdId;
DECLARE @PIsObsolete BIT = @IsObsolete;
DECLARE @PSectionId INT = @SectionId
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PSegmentId INT = @SegmentId;
DECLARE @PRefStandardSource CHAR = @RefStandardSource;
DECLARE @PCreatedBy INT = @CreatedBy;
DECLARE @PmRefStandardId INT = @mRefStandardId;
DECLARE @PmSegmentId INT = @mSegmentId;
--Set Nocount On
SET NOCOUNT ON;

    DECLARE @ProjSegmentRefStdCount INT = NULL
	DECLARE @ProjRefStdCount INT = NULL
	DECLARE @ProjRefStdEditionId INT = NULL

SET @ProjSegmentRefStdCount = (SELECT
		COUNT(1)
	FROM ProjectSegmentReferenceStandard WITH (NOLOCK)
	WHERE SectionId = @PSectionId
	AND RefStdCode = @PRefStdCode
	AND RefStandardId = @PRefStandardId
	AND (SegmentId = @PSegmentId
	OR mSegmentId = @PmSegmentId)
	AND CustomerId = @PCustomerId
	AND IsDeleted = 0)

	SELECT
		SectionId,RefStdEditionId,RefStdSource INTO #TempProjectReferenceStandard
	FROM ProjectReferenceStandard WITH (NOLOCK)
	WHERE 
	RefStandardId = @PRefStandardId
	AND ProjectId = @PProjectId
	AND RefStdCode = @PRefStdCode
	AND CustomerId = @PCustomerId
	AND IsDeleted = 0

SET @ProjRefStdCount = (SELECT
		COUNT(1)
	FROM #TempProjectReferenceStandard WITH (NOLOCK)
	WHERE SectionId = @PSectionId
	)

    IF @PSegmentId = 0
        BEGIN
SET @PSegmentId = NULL;
  
        END
    IF @PmSegmentId = 0
        BEGIN
SET @PmSegmentId = NULL;
  
        END
  
    IF(ISNULL(@ProjRefStdCount,0)>0)
      BEGIN
 SELECT TOP 1
		@ProjRefStdEditionId = RefStdEditionId
	FROM #TempProjectReferenceStandard
	WHERE RefStdSource = 'U'
	OPTION (FAST 1)
	

	  IF ISNULL(@ProjRefStdEditionId,0) > 0
BEGIN
SET @PRefStdEditionId = @ProjRefStdEditionId
					END

INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, RefStdCode, RefStdEditionId,
mReplaceRefStdId, IsObsolete, SectionId, CustomerId, PublicationDate)
	VALUES (@PProjectId, @PRefStandardId, @RefStdSource, @PRefStdCode, @PRefStdEditionId, @PmReplaceRefStdId, @PIsObsolete, @PSectionId, @PCustomerId, NULL)
END


IF (ISNULL(@ProjSegmentRefStdCount, 0) > 0)
BEGIN
INSERT INTO ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource, mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, mSegmentId, RefStdCode)
	VALUES (@PSectionId, @PSegmentId, @PRefStandardId, @PRefStandardSource, @PmRefStandardId, GETUTCDATE(), @PCreatedBy, GETUTCDATE(), NULL, @PCustomerId, @PProjectId, @PmSegmentId, @PRefStdCode)
END


END
GO
PRINT N'Altering [dbo].[usp_CreateReferenceStandard]...';


GO
ALTER procedure [dbo].[usp_CreateReferenceStandard]
(
	@inpRefStdDto nvarchar(max)
)
AS
BEGIN
DECLARE @PinpRefStdDto nvarchar(max) = @inpRefStdDto;
	CREATE Table #ReferenceStandard (
		RefStdName nvarchar(500),
		[RefStdSource] char(1),
		[ReplaceRefStdId] int,
		[ReplaceRefStdSource] char(1),
		[mReplaceRefStdId] int,
		[IsObsolete] bit,
		[RefStdCode] int,
		[CreatedBy] int,
		[CustomerId] int
	);

	CREATE Table #ReferenceStandardEdition (
	[RefEdition] nvarchar(255),
	[RefStdTitle] nvarchar(1024),
	[LinkTarget] nvarchar(1024),
	[CreatedBy] int,
	[RefStdId] int,
	[CustomerId] int
	);

	CREATE Table #inpRefStdTbl (
	  ReferenceStandard nvarchar(max),
	  ReferenceStandardEdition nvarchar(max)
	);

INSERT INTO #inpRefStdTbl (ReferenceStandard, ReferenceStandardEdition)
	SELECT
		*
	FROM OPENJSON(@PinpRefStdDto)
	WITH (
	ReferenceStandard NVARCHAR(MAX) AS JSON,
	ReferenceStandardEdition NVARCHAR(MAX) AS JSON
	);

DECLARE @refStndJson NVARCHAR(MAX);
DECLARE @refStndEdtnJson NVARCHAR(MAX);

SELECT
	@refStndJson = ReferenceStandard
   ,@refStndEdtnJson = ReferenceStandardEdition
FROM #inpRefStdTbl;

INSERT INTO #ReferenceStandard (RefStdName, [RefStdSource], [ReplaceRefStdId], [ReplaceRefStdSource],
[mReplaceRefStdId], [IsObsolete], [RefStdCode], [CreatedBy], [CustomerId])
	SELECT
		*
	FROM OPENJSON(@refStndJson)
	WITH (
	RefStdName NVARCHAR(500) '$.RefStdName',
	[RefStdSource] CHAR(1) '$.RefStdSource',
	[ReplaceRefStdId] INT '$.ReplaceRefStdId',
	[ReplaceRefStdSource] CHAR(1) '$.ReplaceRefStdSource',
	[mReplaceRefStdId] INT '$.MReplaceRefStdId',
	[IsObsolete] BIT '$.IsObsolute',
	[RefStdCode] INT '$.RefStdCode',
	[CreatedBy] INT '$.CreatedBy',
	[CustomerId] INT '$.CustomerId'
	);

--select * from @ReferenceStandard;

INSERT INTO #ReferenceStandardEdition ([RefEdition], [RefStdTitle], [LinkTarget], [CreatedBy],
[RefStdId], [CustomerId])
	SELECT
		*
	FROM OPENJSON(@refStndEdtnJson)
	WITH (
	RefEdition NVARCHAR(255) '$.RefEdition',
	RefStdTitle NVARCHAR(1024) '$.RefStdTitle',
	LinkTarget NVARCHAR(1024) '$.LinkTarget',
	CreatedBy INT '$.CreatedBy',
	RefStdId INT '$.RefStdId',
	CustomerId INT '$.CustomerId'
	);

--select * from @ReferenceStandardEdition;

--insert values in table
INSERT INTO [ReferenceStandard] ([RefStdName], [RefStdSource], [ReplaceRefStdId], [ReplaceRefStdSource], [mReplaceRefStdId]
, [IsObsolete], [CreateDate], [CreatedBy], [CustomerId], [IsDeleted])
	SELECT
		RefStdName
	   ,[RefStdSource]
	   ,[ReplaceRefStdId]
	   ,[ReplaceRefStdSource]
	   ,[mReplaceRefStdId]
	   ,[IsObsolete]
		--,[RefStdCode]
	   ,GETUTCDATE()
	   ,[CreatedBy]
	   ,[CustomerId]
	   ,0
	FROM #ReferenceStandard

DECLARE @refStdId INT;
SET @refStdId = SCOPE_IDENTITY();

--insert values in table
INSERT INTO  [ReferenceStandardEdition] ([RefEdition], [RefStdTitle], [LinkTarget], [CreateDate], [CreatedBy]
, [RefStdId], [CustomerId])
	SELECT
		[RefEdition]
	   ,[RefStdTitle]
	   ,[LinkTarget]
	   ,GETUTCDATE()
	   ,[CreatedBy]
	   ,@refStdId
	   ,[CustomerId]
	FROM #ReferenceStandardEdition

DECLARE @refStdEditionId INT;
SET @refStdEditionId = SCOPE_IDENTITY();

--select values to return
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
WHERE RefStdId = @refStdId

SELECT
	RefStdEditionId
   ,RefEdition
   ,RefStdTitle
   ,LinkTarget
   ,CreateDate
   ,CreatedBy
   ,RefStdId
   ,CustomerId
   ,ModifiedDate
   ,ModifiedBy
FROM ReferenceStandardEdition WITH (NOLOCK)
WHERE RefStdEditionId = @refStdEditionId
END;
GO
PRINT N'Altering [dbo].[usp_CreateSegmentLink]...';


GO
ALTER PROCEDURE [dbo].[usp_CreateSegmentLink]    
@SourceSectionCode INT, @SourceSegmentStatusCode INT, @SourceSegmentCode INT, @SourceSegmentChoiceCode INT NULL, @SourceChoiceOptionCode INT NULL, @LinkSource NVARCHAR(500),
@TargetSectionCode INT, @TargetSegmentStatusCode INT, @TargetSegmentCode INT, @TargetSegmentChoiceCode INT NULL, @TargetChoiceOptionCode INT NULL, @LinkTarget NVARCHAR(500),
@LinkStatusTypeId INT, @UserId INT, @ProjectId INT, @CustomerId INT, @SegmentLinkSourceTypeId INT
AS      
BEGIN
DECLARE @PSourceSectionCode INT = @SourceSectionCode
DECLARE @PSourceSegmentStatusCode INT = @SourceSegmentStatusCode
DECLARE @PSourceSegmentCode INT = @SourceSegmentCode
DECLARE @PSourceSegmentChoiceCode INT = @SourceSegmentChoiceCode;
DECLARE @PSourceChoiceOptionCode INT = @SourceChoiceOptionCode;
DECLARE @PLinkSource NVARCHAR(500) = @LinkSource;
DECLARE @PTargetSectionCode INT = @TargetSectionCode;
DECLARE @PTargetSegmentStatusCode INT = @TargetSegmentStatusCode;
DECLARE @PTargetSegmentCode INT = @TargetSegmentCode;
DECLARE @PTargetSegmentChoiceCode INT = @TargetSegmentChoiceCode;
DECLARE @PTargetChoiceOptionCode INT = @TargetChoiceOptionCode;
DECLARE @PLinkTarget NVARCHAR(500) = @LinkTarget;
DECLARE @PLinkStatusTypeId INT = @LinkStatusTypeId;
DECLARE @PUserId INT = @UserId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PSegmentLinkSourceTypeId INT = @SegmentLinkSourceTypeId;
--Set Nocount On
SET NOCOUNT ON;

INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,
TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget,
LinkStatusTypeId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, ProjectId, CustomerId, SegmentLinkSourceTypeId)
	SELECT
		@PSourceSectionCode AS SourceSectionCode
	   ,@PSourceSegmentStatusCode AS SourceSegmentStatusCode
	   ,@PSourceSegmentCode AS SourceSegmentCode
	   ,@PSourceSegmentChoiceCode AS SourceSegmentChoiceCode
	   ,@PSourceChoiceOptionCode AS SourceChoiceOptionCode
	   ,@PLinkSource AS LinkSource
	   ,@PTargetSectionCode AS TargetSectionCode
	   ,@PTargetSegmentStatusCode AS TargetSegmentStatusCode
	   ,@PTargetSegmentCode AS TargetSegmentCode
	   ,@PTargetSegmentChoiceCode AS TargetSegmentChoiceCode
	   ,@PTargetChoiceOptionCode AS TargetChoiceOptionCode
	   ,@PLinkTarget AS LinkTarget
	   ,@PLinkStatusTypeId AS LinkStatusTypeId
	   ,GETUTCDATE() AS CreateDate
	   ,@PUserId AS CreatedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,@PUserId AS ModifiedBy
	   ,@PProjectId AS ProjectId
	   ,@PCustomerId AS CustomerId
	   ,@PSegmentLinkSourceTypeId AS SegmentLinkSourceTypeId
END
GO
PRINT N'Altering [dbo].[usp_CreateSpecialLinkForRsReTaggedSegment]...';


GO
ALTER PROCEDURE [dbo].[usp_CreateSpecialLinkForRsReTaggedSegment]    
@CustomerId INT, @ProjectId INT, @SectionId INT, @SegmentStatusId INT, @UserId INT    
AS
BEGIN
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PSegmentStatusId INT = @SegmentStatusId
DECLARE @PUserId INT = @UserId;
--Set Nocount On
SET NOCOUNT ON;

DECLARE @SourceSectionCode INT;
DECLARE @SourceSegmentStatusCode INT;
DECLARE @SourceSegmentCode INT;
DECLARE @LinkSource NVARCHAR(1);
DECLARE @TargetSectionCode INT;
DECLARE @TargetSegmentStatusCode INT;
DECLARE @TargetSegmentCode INT;
DECLARE @LinkTarget NVARCHAR(1);
DECLARE @LinkStatusTypeId INT = 3;
DECLARE @SegmentLinkSourceTypeId INT = 2;

DECLARE @ParentSegmentStatusId INT;
DECLARE @ParentSegmentId INT;
DECLARE @SegmentId INT;
DECLARE @mParentSegmentId INT;
DECLARE @mSegmentId INT;

SELECT @SourceSectionCode=SectionCode,
	@TargetSectionCode=SectionCode 
	FROM ProjectSection CPS WITH(NOLOCK)
WHERE SectionId=@PSectionId

SELECT @SourceSegmentStatusCode = CPSST.SegmentStatusCode
	  ,@LinkSource = CPSST.SegmentSource
	  ,@ParentSegmentStatusId=ParentSegmentStatusId
	  ,@mSegmentId=mSegmentId
	  ,@SegmentId=SegmentId
FROM ProjectSegmentStatus CPSST WITH(NOLOCK)
WHERE CPSST.SegmentStatusId = @PSegmentStatusId

SELECT @TargetSegmentStatusCode = PPSST.SegmentStatusCode
	  ,@LinkTarget = PPSST.SegmentSource
	  ,@mParentSegmentId=mSegmentId
	  ,@ParentSegmentId=SegmentId
FROM ProjectSegmentStatus PPSST WITH(NOLOCK)
WHERE PPSST.SegmentStatusId = @ParentSegmentStatusId

IF(ISNULL(@mSegmentId,0)=0)
BEGIN
	SELECT @SourceSegmentCode=SegmentCode
	FROM ProjectSegment PSG WITH(NOLOCK)
	WHERE SegmentId=@SegmentId
END
ELSE
BEGIN
	SELECT @SourceSegmentCode=SegmentCode
	FROM SLCMaster..Segment MSG WITH(NOLOCK)
	WHERE SegmentId=@mSegmentId
END

IF(ISNULL(@mParentSegmentId,0)=0)
BEGIN
	SELECT @TargetSegmentCode=SegmentCode
	FROM ProjectSegment PSG WITH(NOLOCK)
	WHERE SegmentId=@ParentSegmentId
END
ELSE
BEGIN
	SELECT @TargetSegmentCode=SegmentCode
	FROM SLCMaster..Segment MSG WITH(NOLOCK)
	WHERE SegmentId=@mParentSegmentId
END

EXEC usp_CreateSegmentLink @SourceSectionCode
						  ,@SourceSegmentStatusCode
						  ,@SourceSegmentCode
						  ,NULL
						  ,NULL
						  ,@LinkSource
						  ,@TargetSectionCode
						  ,@TargetSegmentStatusCode
						  ,@TargetSegmentCode
						  ,NULL
						  ,NULL
						  ,@LinkTarget
						  ,@LinkStatusTypeId
						  ,@PUserId
						  ,@PProjectId
						  ,@PCustomerId
						  ,@SegmentLinkSourceTypeId

END
GO
PRINT N'Altering [dbo].[usp_CreateSegmentRequirementTag]...';


GO
ALTER PROCEDURE [dbo].[usp_CreateSegmentRequirementTag]    
@CustomerId INT, @ProjectId INT, @SectionId INT, @SegmentStatusId INT, @TagType NVARCHAR(255) NULL, @UserId INT    
AS      
BEGIN
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PSegmentStatusId INT = @SegmentStatusId;
DECLARE @PTagType NVARCHAR(255) = @TagType;
DECLARE @PUserId INT = @UserId;

--Set Nocount On
SET NOCOUNT ON;

	IF EXISTS (SELECT TOP 1 1 FROM LuProjectRequirementTag WITH(NoLock) WHERE TagType = @PTagType)
	BEGIN
		SELECT DISTINCT RequirementTagId 
		INTO #RequirementTagIds
		FROM ProjectSegmentRequirementTag PSRT with(nolock) 
		WHERE PSRT.SegmentStatusId = @PSegmentStatusId
		AND PSRT.SectionId=@PSectionId AND PSRT.ProjectId=@PProjectId

		INSERT INTO ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId, CreateDate, ModifiedDate, ProjectId, CustomerId,
		CreatedBy, ModifiedBy)
			SELECT
				@PSectionId
			   ,@PSegmentStatusId
			   ,PRTG.RequirementTagId
			   ,GETUTCDATE()
			   ,GETUTCDATE()
			   ,@PProjectId
			   ,@PCustomerId
			   ,@PUserId
			   ,@PUserId
			FROM LuProjectRequirementTag PRTG WITH(NoLock) 
			LEFT OUTER JOIN #RequirementTagIds RTI
			ON PRTG.RequirementTagId=RTI.RequirementTagId
			WHERE PRTG.TagType = @PTagType AND RTI.RequirementTagId IS NULL
	END
END
GO
PRINT N'Altering [dbo].[usp_DeleteSection]...';


GO
ALTER PROCEDURE [dbo].[usp_DeleteSection]  
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
PRINT N'Altering [dbo].[usp_EnableDisableTrackChanges]...';


GO
ALTER PROCEDURE  [dbo].[usp_EnableDisableTrackChanges]
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
PRINT N'Altering [dbo].[usp_GetAllComments]...';


GO
ALTER PROC [dbo].[usp_GetAllComments]   --[dbo].[usp_GetAllComments]  11083, 4730165, 2227,2513,0,''  
(      
 @ProjectId INT,      
 @SectionId INT,      
 --@SegmentStatusId INT,      
 @CustomerId INT,      
 @UserId INT,      
 @CommentStatusId INT,      
 @CommentUserList NVARCHAR(1024)=''      
)      
AS      
BEGIN
  
      
 DECLARE @PProjectId INT = @ProjectId;
 DECLARE @PSectionId INT = @SectionId;
 DECLARE @PCustomerId INT = @CustomerId;
 DECLARE @PUserId INT = @UserId;
 DECLARE @PCommentStatusId INT = @CommentStatusId;
 DECLARE @PCommentUserList NVARCHAR(1024) = @CommentUserList;

 DECLARE @COMMENT_USER_TBL AS TABLE(USERID INT)
  
      
      
 --SELECT *,CAST('' AS NVARCHAR(100)) AS CommentStatusDescription INTO #T FROM SegmentComment WHERE 1=0      
      
 create TABLE #T(SegmentCommentId INT,      
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
INSERT INTO @COMMENT_USER_TBL
	SELECT
		*
	FROM dbo.fn_SplitString('', ',')
--PRINT @@ROWCOUNT      
IF (@@ROWCOUNT = 0)
BEGIN
INSERT INTO #T
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
	FROM SegmentComment WITH (NOLOCK)
	WHERE SectionId = @PSectionId
	AND ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND ParentCommentId = 0
	AND IsDeleted = 0
--AND CommentStatusId =@CommentStatusId      

END
ELSE
BEGIN
INSERT INTO @COMMENT_USER_TBL
	VALUES (@PUserId)

INSERT INTO #T
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
	   ,'' AS CommentStatusDescription
	FROM SegmentComment SC WITH (NOLOCK)
	INNER JOIN @COMMENT_USER_TBL UT
		ON UT.USERID = SC.CreatedBy
	WHERE SectionId = @PSectionId
	AND ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND ParentCommentId = 0
	AND IsDeleted = 0
--AND CommentStatusId =@CommentStatusId      
END

UPDATE T
SET T.CommentStatusDescription = CS.[Description]
   ,T.ModifiedBy = COALESCE(t.ModifiedBy, 0)
FROM #T T
INNER JOIN LuCommentStatus CS WITH (NOLOCK)
	ON T.CommentStatusId = CS.CommentStatusId

--Only Comments      
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
FROM #T
ORDER BY CreateDate DESC

--Only Reply's      
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
FROM #T T
INNER JOIN SegmentComment SC WITH (NOLOCK)
	ON SC.ParentCommentId = T.SegmentCommentId
WHERE SC.SectionId = @PSectionId
AND SC.ProjectId = @PProjectId
AND SC.CustomerId = @PCustomerId
AND SC.IsDeleted = 0
ORDER BY CreateDate DESC
END
GO
PRINT N'Altering [dbo].[usp_GetCopyProjectProgress]...';


GO
ALTER PROCEDURE [dbo].[usp_GetCopyProjectProgress]    
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
PRINT N'Altering [dbo].[usp_GetCopyProjectRequest]...';


GO
ALTER PROC [dbo].[usp_GetCopyProjectRequest]    
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
PRINT N'Altering [dbo].[usp_GetHeaderFooterKeywordDetails]...';


GO
ALTER PROCEDURE [dbo].[usp_GetHeaderFooterKeywordDetails]         
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
PRINT N'Altering [dbo].[usp_GetLookupReportTags]...';


GO
ALTER PROCEDURE [dbo].[usp_GetLookupReportTags]                    
@CustomerId INT   
AS    
BEGIN
  
DECLARE @PCustomerId INT = @CustomerId;

--DECLARE @ReportTagTbl TABLE(  
-- TagType NVARCHAR(MAX),  
-- TagName NVARCHAR(MAX),  
-- SegmentStatusCount INT,  
-- IsUserTag BIT,  
-- RequirementTagId INT,  
-- UserTagId INT,  
-- IsSystemTag BIT  
--);

--NOTE-Show IsSystem NP/NS/PL tags in lookup list only for migrated one  
--Creating temp table to get to know whether user tag of IsSystem   
SELECT
	PUT.UserTagId INTO #UsedIsSystemReportTagsTbl
FROM [dbo].ProjectUserTag PUT WITH (NOLOCK)
INNER JOIN [dbo].ProjectSegmentUserTag PSUT WITH (NOLOCK)
	ON PSUT.UserTagId = PUT.UserTagId
		--AND PSUT.CustomerId = PUT.CustomerId
WHERE PUT.CustomerId = @PCustomerId
AND PUT.IsSystemTag = 1
GROUP BY PUT.UserTagId

--INSERT VALUES IN ReportTag TABLE  
--INSERT INTO @ReportTagTbl (TagType, TagName, SegmentStatusCount, IsUserTag, RequirementTagId, UserTagId, IsSystemTag)
	SELECT
		LPRT.TagType
	   ,LPRT.Description as TagName
	   ,0 AS SegmentStatusCount
	   ,CAST(0 AS BIT) AS IsUserTag
	   ,LPRT.RequirementTagId
	   ,0 AS UserTagId
	   ,CAST(1 AS BIT) AS IsSystemTag
	FROM LuProjectRequirementTag LPRT WITH (NOLOCK)
	WHERE LPRT.IsActive = 1
	UNION ALL
	SELECT
		PUT.TagType
	   ,PUT.Description as TagName
	   ,0 AS SegmentStatusCount
	   ,CAST(1 AS BIT) AS IsUserTag
	   ,0 AS RequirementTagId
	   ,PUT.UserTagId
	   ,PUT.IsSystemTag
	FROM ProjectUserTag PUT WITH (NOLOCK)
	WHERE PUT.CustomerId = @PCustomerId
	AND PUT.IsSystemTag = 0
	UNION ALL
	SELECT
		PUT.TagType
	   ,PUT.Description as TagName
	   ,0 AS SegmentStatusCount
	   ,CAST(1 AS BIT) AS IsUserTag
	   ,0 AS RequirementTagId
	   ,PUT.UserTagId
	   ,PUT.IsSystemTag
	FROM [dbo].ProjectUserTag PUT WITH (NOLOCK)
	INNER JOIN #UsedIsSystemReportTagsTbl URTTBL
		ON PUT.UserTagId = URTTBL.UserTagId
	WHERE PUT.CustomerId = @PCustomerId
	AND PUT.IsSystemTag = 1

--SELECT
--	*
--FROM @ReportTagTbl
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
   ,ISNULL(p.IsPermanentDeleted, 0) AS IsPermanentDeleted
   ,ISNULL(p.ModifiedByFullName,'') As ModifiedByFullName
FROM Project p WITH(NOLOCK) inner join ProjectSummary ps with(nolock)
ON p.ProjectId=ps.ProjectId
WHERE p.ProjectId = @ProjectId
END
GO
PRINT N'Altering [dbo].[usp_GetProjectExportList]...';


GO
ALTER PROC [dbo].[usp_GetProjectExportList]            
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
PRINT N'Altering [dbo].[usp_GetProjectPrintSetting]...';


GO
ALTER PROCEDURE [dbo].[usp_GetProjectPrintSetting]          
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
PRINT N'Altering [dbo].[usp_GetProjectSegemntMappingData]...';


GO
ALTER  Procedure [dbo].[usp_GetProjectSegemntMappingData]  
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
   ,sco.OptionJson
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



SELECT DISTINCT 
ps.mSectionId,
pn.NoteText,
pn.Title,
pss.mSegmentId,
pss.mSegmentStatusId

FROM ProjectNote pn WITH (NOLOCK)

INNER JOIN   ProjectSegmentStatus pss WITH (NOLOCK)
ON pn.SegmentStatusId=pss.SegmentStatusId and pn.SectionId=pss.SectionId

and pn.CustomerId=pss.CustomerId and pn.ProjectId=pss.ProjectId
INNER JOIN ProjectSection PS  WITH (NOLOCK)
ON PS.SectionId=pn.SectionId and ps.ProjectId=pn.ProjectId and pn.CustomerId=ps.CustomerId

WHERE pn.ProjectId=@ProjectId and pn.CustomerId=@CustomerId

END
GO
PRINT N'Altering [dbo].[usp_GetReferenceStandards]...';


GO
ALTER PROCEDURE [dbo].[usp_GetReferenceStandards]   
(            
  @ProjectId INT= NULL,     
  --@SectionId INT =NULL,  
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
AND IsDeleted = 0

--CREATE TABLE OF REF STD'S OF MASTER ONLY    

SELECT MAX(RSE.RefStdEditionId) as RefStdEditionId,RSE.RefStdId
INTo #RefStdTbl	FROM [SLCMaster].dbo.ReferenceStandardEdition RSE WITH(NOLOCK) GROUP BY RSE.RefStdId

SELECT MAX(RSE.RefStdEditionId) as RefStdEditionId,RSE.RefStdId
INTo #RefStdProj FROM [dbo].ReferenceStandardEdition RSE WITH(NOLOCK) GROUP BY RSE.RefStdId

--SELECT
--	RS.RefStdId
--   ,RefEdition.RefStdEditionId INTO #RefStdTbl
--FROM [SLCMaster].dbo.ReferenceStandard RS (NOLOCK)
--CROSS APPLY (SELECT TOP 1
--		RSE.RefStdEditionId
--	FROM [SLCMaster].dbo.ReferenceStandardEdition RSE (NOLOCK)
--	WHERE RSE.RefStdId = RS.RefStdCode
--	ORDER BY RSE.RefStdEditionId DESC) RefEdition

----UPDATE EDITION ID ACCORDING TO APPLY UPDATE FUNCTIONALITY    
UPDATE RefStd
SET RefStd.RefStdEditionId = MREF.RefStdEditionId
FROM #RefStdTbl RefStd WITH(NOLOCK)
INNER JOIN #MappedRefStds MREF WITH(NOLOCK)
	ON RefStd.RefStdId = MREF.RefStandardId
INNER JOIN [SLCMaster].dbo.ReferenceStandard RS WITH(NOLOCK)
    ON  MREF.RefStdCode=RS.RefStdCode  


DECLARE @MasterReferenceStandard TABLE
(RefStdId	int
--,MasterDataTypeId	int
,RefStdName	varchar(100)
,ReplaceRefStdId	int
,IsObsolete	bit
,RefStdCode	int
--,CreateDate	datetime2
--,ModifiedDate	datetime2
--,PublicationDate	datetime2
,RefStdEditionId INT
)

DECLARE @MasterReferenceStandardEdition TABLE
(RefStdEditionId	int
,RefStdId	int
,RefEdition	varchar(150)
,RefStdTitle	varchar(500)
,LinkTarget	varchar(300)
--,CreateDate	datetime2
--,ModifiedDate	datetime2
--,PublicationDate	datetime2
--,MasterDataTypeId	int
)

DECLARE @ReferenceStandard TABLE
(RefStdId	int
,RefStdName	varchar(100)
,RefStdSource	char(1)
,ReplaceRefStdId	int
,ReplaceRefStdSource	char(1)
,mReplaceRefStdId	int
,IsObsolete	bit
,RefStdCode	int
,CreateDate	datetime2
,CreatedBy	int
,ModifiedDate	datetime2
,ModifiedBy	int
,CustomerId	int
,IsDeleted	bit
,IsLocked	bit
,IsLockedByFullName	nvarchar(100)
,IsLockedById	int
,A_RefStdId	int
,RefStdEditionId INT
)

DECLARE @ReferenceStandardEdition TABLE
(RefStdEditionId	int
,RefEdition	varchar(150)
,RefStdTitle varchar(300)
,LinkTarget	varchar(500)
--,CreateDate	datetime2
--,CreatedBy	int
--,RefStdId	int
--,CustomerId	int
--,ModifiedDate	datetime2
--,ModifiedBy	int
--,A_RefStdEditionId	int
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
select PRS.*, RSP.RefStdEditionId from [dbo].ReferenceStandard PRS WITH (NOLOCK)
inner join #RefStdProj RSP  WITH (NOLOCK)
on PRS.RefStdId = RSP.RefStdId 
WHERE ISNULL(PRS.IsDeleted,0) = 0

insert into @ReferenceStandardEdition
select PRSE.RefStdEditionId, PRSE.RefEdition,PRSE.RefStdTitle,PRSE.LinkTarget
from [dbo].ReferenceStandardEdition PRSE WITH (NOLOCK)
WHERE PRSE.CustomerId= @PCustomerId

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
--	ON RS.RefStdId = RefStd.RefStdId
--		AND RS.MasterDataTypeId = @PMasterDataTypeId
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
FROM @ReferenceStandard PRS
--inner join #RefStdProj RSP 
--on PRS.RefStdId = RSP.RefStdId 
inner join @ReferenceStandardEdition PRSE
on PRSE.RefStdEditionId = PRS.RefStdEditionId
--where PRS.CustomerId = @PCustomerId AND PRS.IsDeleted = 0
--CROSS APPLY (SELECT TOP 1
--		PRSE.RefStdEditionId
--	   ,PRSE.RefEdition
--	   ,PRSE.RefStdTitle
--	   ,PRSE.LinkTarget
--	FROM ReferenceStandardEdition PRSE (NOLOCK)
--	WHERE PRSE.RefStdId = PRS.RefStdId
--	AND PRS.CustomerId = @PCustomerId
--	AND PRS.IsDeleted = 0
--	ORDER BY PRSE.RefStdEditionId DESC) PRefEdition

ORDER BY RS.RefStdName;

END
GO
PRINT N'Altering [dbo].[usp_GetTrackChangeDetails]...';


GO
ALTER PROCEDURE [dbo].[usp_GetTrackChangeDetails] -- [Obsolete]
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
PRINT N'Altering [dbo].[usp_GetTrackedSegmentDetails]...';


GO
ALTER PROCEDURE [dbo].[usp_GetTrackedSegmentDetails] -- [Obsolete]
(
@ProjectId  int,
@SectionId  int,
@CustomerId	int
)
AS
BEGIN
--  SELECT
--	TPS1.SegmentId
--   ,TPS1.AfterEdit
--FROM TrackProjectSegment TPS1 WITH(NOLOCK)
--LEFT OUTER JOIN TrackProjectSegment TPS2 WITH(NOLOCK)
--	ON TPS2.SegmentId = TPS1.SegmentId
--		AND TPS2.ChangedDate > TPS1.ChangedDate
--WHERE TPS2.ChangedDate IS NULL
--AND TPS1.ProjectId = @ProjectId
--AND TPS1.SectionId = @SectionId
--AND TPS1.CustomerId = @CustomerId
--AND TPS1.IsDeleted <> 1

SELECT
	ps.SegmentId
   ,'' AS AfterEdit
FROM ProjectSegment ps WITH(NOLOCK)
INNER JOIN ProjectSegmentStatus pss WITH(NOLOCK)
	ON ps.SectionId = pss.SectionId
		AND ps.SegmentStatusId = pss.SegmentStatusId
		AND ps.SegmentId = pss.SegmentId
		AND ps.ProjectId = pss.ProjectId
		AND ps.CustomerId = pss.CustomerId
WHERE ps.SectionId = @SectionId
AND  ps.ProjectId = @ProjectId
AND ps.CustomerId = @CustomerId
AND ISNULL(ps.IsDeleted, 0) = 0
AND ISNULL(pss.IsDeleted, 0) = 0
AND PATINDEX('%ct="%', ps.SegmentDescription) > 0

END
GO
PRINT N'Altering [dbo].[usp_GetUpdatesNeedsReview]...';


GO
ALTER PROCEDURE [dbo].[usp_GetUpdatesNeedsReview]
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
PRINT N'Altering [dbo].[usp_lockImportingSourceAndTargetSections]...';


GO
ALTER PROCEDURE [dbo].[usp_lockImportingSourceAndTargetSections]  
 @SectionListJson NVARCHAR(MAX),  
 @TargetProjectId INT  
AS  
BEGIN  
 DECLARE @PSectionListJson NVARCHAR(MAX) = @SectionListJson;
 DECLARE @PTargetProjectId INT = @TargetProjectId;

  SELECT SectionId, ProjectId, SourceTag, Author, CustomerId  
  INTO #LockSectionsTbl  
  FROM OPENJSON(@PSectionListJson)  
  WITH (  
   CustomerId NVARCHAR(MAX) '$.CustomerId',  
   SectionId INT '$.SectionId',    
   ProjectId INT '$.ProjectId',    
   SourceTag VARCHAR(10) '$.SourceTag',  
   Author NVARCHAR(MAX) '$.Author'  
  );  
  
  --Lock Source Sections in Source Project  
  UPDATE PS   
  SET PS.IsLockedImportSection = 1  
  FROM #LockSectionsTbl LST  
  INNER JOIN ProjectSection PS   with (nolock)
  ON PS.SectionId = LST.SectionId  
  
  --TODO Move this query to ImportSectionFromProject
  ----Lock Target Sections in Target Project  
  --UPDATE PS   
  --SET PS.IsLockedImportSection = 1  
  --FROM #LockSectionsTbl LST  
  --INNER JOIN ProjectSection PS  with (nolock)
  --ON PS.SourceTag = LST.SourceTag AND PS.Author = LST.Author  
  --WHERE PS.ProjectId = @PTargetProjectId AND PS.IsLastLevel = 1  

  
END
GO
PRINT N'Altering [dbo].[usp_LockUnlockTrackChanges]...';


GO
ALTER PROCEDURE [dbo].[usp_LockUnlockTrackChanges]  
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
  
DECLARE @IsLocked bit =0
  
DECLARE @IsLockedImportSection bit =0
-- check if target section is already locked  
SELECT @IsLocked=iif(LockedBy <> @PUserId AND IsLocked = 1,1,0),@IsLockedImportSection=IsLockedImportSection FROM [projectSection] WITH (NOLOCK)
	WHERE SectionId = @PSectionId
	--AND ProjectId = @PProjectId
	--AND CustomerId = @PCustomerId
	--AND LockedBy <> @PUserId
	--AND IsLocked = 1 
	option (fast 1 )
	 
	 	 
IF(@IsLocked=0)    
  BEGIN
-- Release lock if any section is locked earlier  
UPDATE PS
SET IsLocked = 0
   ,LockedBy = 0
   ,LockedByFullName = ''
   FROM ProjectSection PS WITH (NOLOCK)
WHERE ProjectId = @PProjectId
and IsLastLevel=1
AND CustomerId = @PCustomerId
AND LockedBy = @PUserId
AND IsLocked = 1;

UPDATE PS
SET IsLocked = 1
   ,LockedBy = @PUserId
   ,LockedByFullName = @PUserName
   ,ModifiedBy=@PUserId
   ,ModifiedDate=GETUTCDATE()
    FROM ProjectSection PS WITH (NOLOCK)
WHERE ProjectId = @PProjectId
AND CustomerId = @PCustomerId
AND SectionId = @PSectionId;
END
ELSE
BEGIN
SET @IsLocked = 1
  END

--SELECT
--	@IsLocked AS IsLocked
--   ,IsLockedImportSection
--FROM [projectSection] WITH (NOLOCK)
--WHERE SectionId = @PSectionId
--AND ProjectId = @PProjectId
--AND CustomerId = @PCustomerId

SELECT @IsLocked AS IsLocked,@IsLockedImportSection AS IsLockedImportSection 

END
GO
PRINT N'Altering [dbo].[usp_MapProjectRefStands]...';


GO
ALTER PROCEDURE [dbo].[usp_MapProjectRefStands]  @ProjectId INT NULL, @SectionId INT NULL, @CustomerId INT NULL, @UserId INT NULL, @MasterSectionId INT NULL = NULL         
         
AS              
BEGIN  
DECLARE @PProjectId INT = @ProjectId;  
DECLARE @PSectionId INT = @SectionId;  
DECLARE @PCustomerId INT = @CustomerId;  
DECLARE @PUserId INT = @UserId;  
--ALTER DATABASE [SLCProject] SET READ_COMMITTED_SNAPSHOT ON;
  
SET NOCOUNT ON;  
        
            
 DECLARE @PMasterSectionId AS INT = @MasterSectionId;
 
 IF ISNULL(@PMasterSectionId,0) = 0
Begin 
SET @PMasterSectionId = (SELECT TOP 1  
  mSectionId  
 FROM ProjectSection WITH (NOLOCK)  
 WHERE ProjectId = @PProjectId  
 AND CustomerId = @PCustomerId  
 AND SectionId = @PSectionId);  
End;

SELECT  
 rs.RefStdId  
   ,rs.MasterDataTypeId  
   ,rs.RefStdName  
   ,rs.ReplaceRefStdId  
   ,rs.IsObsolete  
   ,rs.RefStdCode  
   ,rs.CreateDate  
   ,rs.ModifiedDate  
   ,rs.PublicationDate  
   ,MAX(rse.RefStdEditionId) AS RefStdEditionId INTO #t  
FROM [SLCMaster].[dbo].ReferenceStandard AS rs WITH (NOLOCK)  
INNER JOIN [SLCMaster].[dbo].ReferenceStandardEdition AS rse WITH (NOLOCK)  
 ON rs.RefStdId = rse.RefStdId  
INNER JOIN [SLCMaster].[dbo].SegmentReferenceStandard SRS WITH (NOLOCK)  
 ON SRS.RefStandardId = rs.RefStdId  
WHERE SRS.SectionId = @PMasterSectionId  
GROUP BY rs.RefStdId  
  ,rs.MasterDataTypeId  
  ,rs.RefStdName  
  ,rs.ReplaceRefStdId  
  ,rs.IsObsolete  
  ,rs.RefStdCode  
  ,rs.CreateDate  
  ,rs.ModifiedDate  
  ,rs.PublicationDate;  
  
INSERT INTO [dbo].[ProjectReferenceStandard] (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId, IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId)  
 SELECT  
  @PProjectId  
    ,tempTable.RefStdId  
    ,'M' AS RefStdSource  
    ,tempTable.ReplaceRefStdId AS mReplaceRefStdId  
    ,tempTable.RefStdEditionId  
    ,tempTable.IsObsolete  
    ,tempTable.RefStdCode  
    ,tempTable.PublicationDate  
    ,@PSectionId  
    ,@PCustomerId  
 -- , x.CustomerId            
 FROM #t AS tempTable  
 LEFT JOIN [dbo].ProjectReferenceStandard AS PRS WITH (NOLOCK)  
  ON tempTable.RefStdId = PRS.RefStandardId  
   AND PRS.ProjectId = @PProjectId  
   AND PRS.SectionId = @PSectionId  
   AND PRS.IsDeleted = 0  
 WHERE (PRS.RefStandardId IS NULL  
 OR PRS.SectionId IS NULL  
 OR PRS.CustomerId IS NULL)  

DROP TABLE IF EXISTS #TempProjectSegmentRefStd;
-- Insert into #TempProjectSegmentRefStd
SELECT PSRS.ProjectId, PSRS.mRefStandardId
INTO #TempProjectSegmentRefStd
FROM ProjectSegmentReferenceStandard PSRS WITH (NOLOCK) 
WHERE PSRS.SectionId = @PSectionId AND PSRS.RefStandardSource = 'M'
  
INSERT INTO [dbo].ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource,  
mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy,  
CustomerId, ProjectId, mSegmentId, RefStdCode)  
 SELECT  
  @PSectionId AS SectionId  
    ,NULL AS SegmentId  
    ,NULL AS RefStandardId  
    ,'M' AS RefStandardSource  
    ,MRS.RefStdId AS mRefStandardId  
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS ModifiedDate
    ,@PUserId AS ModifiedBy  
    ,@PCustomerId AS CustomerId  
    ,@PProjectId AS ProjectId  
    ,MSRS.SegmentId AS mSegmentId  
    ,MRS.RefStdCode AS RefStdCode  
 FROM [SLCMaster].[dbo].SegmentReferenceStandard MSRS WITH (NOLOCK)  
 INNER JOIN [SLCMaster].[dbo].ReferenceStandard MRS WITH (NOLOCK)  
  ON MSRS.RefStandardId = MRS.RefStdId
 LEFT JOIN #TempProjectSegmentRefStd PSRS WITH (NOLOCK)
 ON PSRS.ProjectId = @PProjectId AND PSRS.mRefStandardId = MRS.RefStdId
 WHERE MSRS.SectionId = @PMasterSectionId AND PSRS.mRefStandardId IS NULL;

END
GO
PRINT N'Altering [dbo].[usp_MapSegmentLinkFromMasterToProject]...';


GO
ALTER PROCEDURE [dbo].[usp_MapSegmentLinkFromMasterToProject] 
(
	@ProjectId INT NULL, 
	@SectionId INT NULL, 
	@CustomerId INT NULL, 
	@UserId INT NULL
)
AS
BEGIN
SET NOCOUNT ON;
  
DECLARE @pProjectId INT = @ProjectId
DECLARE @pSectionId INT = @SectionId
DECLARE @pCustomerId INT = @CustomerId
DECLARE @pUserId INT = @UserId
DECLARE @PSectionModifiedDate datetime2=null
DECLARE @IsMasterSection BIT=0
DECLARE @SectionCode INT;
--SET @SectionCode = (SELECT TOP 1 SectionCode FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @pSectionId AND mSectionId IS NOT NULL);

SELECT TOP 1
	@SectionCode = SectionCode
	,@PSectionModifiedDate=DataMapDateTimeStamp
	,@IsMasterSection=iif(mSectionId IS NOT NULL,1,0)
	FROM dbo.ProjectSection WITH (NOLOCK)
	WHERE SectionId = @PSectionId
	OPTION (FAST 1);

	IF(@IsMasterSection=1 AND (dateadd(HOUR,-6,GETUTCDATE())>=@PSectionModifiedDate OR @PSectionModifiedDate IS NULL))
	BEGIN
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
		   INTO #ProjectSegmentLinkTemp
		FROM ProjectSegmentLink PSLNK WITH (NOLOCK)
		WHERE PSLNK.ProjectId = @PProjectId
		AND PSLNK.CustomerId = @PCustomerId
		AND (PSLNK.SourceSectionCode = @SectionCode
		OR PSLNK.TargetSectionCode = @SectionCode)
		
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
		   ,@pUserId AS CreatedBy
		   ,GETUTCDATE() AS ModifiedDate
		   ,@pUserId AS ModifiedBy
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
		WHERE MSLNK.IsDeleted = 0
		AND (MSLNK.SourceSectionCode = @SectionCode
		OR MSLNK.TargetSectionCode = @SectionCode)
		AND PSLNK.SegmentLinkId IS NULL
	END
END
GO
PRINT N'Altering [dbo].[usp_MapSegmentRequirementTagFromMasterToProject]...';


GO
ALTER PROCEDURE [dbo].[usp_MapSegmentRequirementTagFromMasterToProject]  
 @ProjectId INT NULL, @SectionId INT NULL, @CustomerId INT NULL, @UserId INT NULL, @MasterSectionId INT = NULL      
AS      
BEGIN  
SET NOCOUNT ON;  
DECLARE @PProjectId INT = @ProjectId;  
DECLARE @PSectionId INT = @SectionId;  
DECLARE @PCustomerId INT = @CustomerId;  
DECLARE @PUserId INT = @UserId;  
  
DECLARE @PMasterSectionId AS INT = @MasterSectionId ;
DECLARE @PSectionModifiedDate datetime2=null
DECLARE @IsMasterSection BIT=0
      
--NOTE:VIMP: DO NOT UNCOMMENT BELOW IF CONDITION OTHERWISE NEW TAGS UPDATES TO EXISTING PROJECTS WON'T WORK  
--NOTE:Called from   
--1.usp_GetSegmentLinkDetails  
--2.usp_GetSegments  
--3.usp_ApplyNewParagraphsUpdates  
  
 --IF NOT EXISTS (SELECT TOP 1  
 -- PSRT.SegmentRequirementTagId  
 --FROM [dbo].[ProjectSegmentRequirementTag] AS PSRT WITH (NOLOCK)  
 --WHERE PSRT.ProjectId = @PProjectId  
 --AND PSRT.CustomerId = @PCustomerId  
 --AND PSRT.SectionId = @PSectionId)  
	BEGIN
		--IF ISNULL(@PMasterSectionId,0) = 0
		--Begin
		--	SET @PMasterSectionId = (SELECT TOP 1 PS.mSectionId FROM [dbo].ProjectSection PS WITH (NOLOCK) WHERE PS.SectionId = @PSectionId);  
		--End;
		SELECT TOP 1
			@PSectionModifiedDate=DataMapDateTimeStamp
		,@PMasterSectionId=mSectionId
		,@IsMasterSection=iif(mSectionId IS NOT NULL,1,0)
		FROM dbo.ProjectSection WITH (NOLOCK)
		WHERE SectionId = @PSectionId
		OPTION (FAST 1);

		IF(@IsMasterSection=1 AND (dateadd(HOUR,-6,GETUTCDATE())>=@PSectionModifiedDate OR @PSectionModifiedDate IS NULL))
		BEGIN
			DROP TABLE IF EXISTS #TempProjectSegmentStatus;  
			SELECT  
				 PSS.SegmentStatusId
				,PSS.mSegmentStatusId
				,PSS.SectionId
				,PSS.ProjectId
				,PSS.CustomerId
			INTO #TempProjectSegmentStatus  
			FROM [dbo].ProjectSegmentStatus PSS WITH (NOLOCK)  
			WHERE PSS.SectionId = @PSectionId
			AND PSS.ProjectId = @PProjectId  
			AND PSS.CustomerId = @PCustomerId;

			DROP TABLE IF EXISTS #TempProjectSegmentRequirementTag;  
			SELECT  
				 PSRT.SectionId
				,PSRT.ProjectId
				,PSRT.CustomerId
				,PSRT.mSegmentRequirementTagId
				,PSRT.SegmentRequirementTagId
			INTO #TempProjectSegmentRequirementTag
			FROM [dbo].ProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
			WHERE PSRT.SectionId = @PSectionId
			AND PSRT.ProjectId = @PProjectId  
			AND PSRT.CustomerId = @PCustomerId;
  
			INSERT INTO [dbo].ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId, CreateDate, ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy, mSegmentRequirementTagId)  
		SELECT
			 PSST.SectionId  
			,PSST.SegmentStatusId  
			,MSRT.RequirementTagId  
			,GETUTCDATE() AS CreateDate  
			,GETUTCDATE() AS ModifiedDate  
			,@PProjectId AS ModifiedDate  
			,@PCustomerId AS CustomerId  
			,@PUserId AS CreatedBy  
			,@PUserId AS ModifiedBy  
			,MSRT.SegmentRequirementTagId AS mSegmentRequirementTagId  
		 FROM [SLCMaster].[dbo].SegmentRequirementTag MSRT WITH (NOLOCK)  
		 INNER JOIN [dbo].LuProjectRequirementTag LuPRT WITH (NOLOCK)  
		  ON MSRT.RequirementTagId = LuPRT.RequirementTagId  
		 INNER JOIN #TempProjectSegmentStatus PSST WITH (NOLOCK)  
		  ON MSRT.SegmentStatusId = PSST.mSegmentStatusId  
		 LEFT JOIN #TempProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
		  ON PSRT.SectionId = @PSectionId
		   AND PSRT.ProjectId = @PProjectId
		   AND PSRT.CustomerId = @PCustomerId
		   AND PSRT.mSegmentRequirementTagId IS NOT NULL  
		   AND PSRT.mSegmentRequirementTagId = MSRT.SegmentRequirementTagId
		 WHERE PSST.SectionId = @PSectionId
		 AND PSST.ProjectId = @PProjectId  
		 AND PSST.CustomerId = @PCustomerId
		 AND MSRT.SectionId = @PMasterSectionId
		 AND PSRT.SegmentRequirementTagId IS NULL
		END
	END
END
GO
PRINT N'Altering [dbo].[usp_MapSegmentStatusFromMasterToProject]...';


GO
ALTER PROCEDURE [dbo].[usp_MapSegmentStatusFromMasterToProject] @ProjectId INT NULL, @SectionId INT NULL, @CustomerId INT NULL, @UserId INT NULL , @MasterSectionId INT = NULL   
AS        
BEGIN    
SET NOCOUNT ON;    
        
 DECLARE @pMasterSectionId AS INT = @MasterSectionId;    
 DECLARE @pProjectId AS INT = @ProjectId;    
 DECLARE @pSectionId AS INT = @SectionId;    
 DECLARE @pCustomerId AS INT = @CustomerId;    
 DECLARE @pUserId AS INT = @UserId;    
 
 Declare @HasSegmentStatus as INT = 0;
 SELECT  
 @HasSegmentStatus = COUNT (1)    
 FROM [dbo].[ProjectSegmentStatus] AS PST WITH (NOLOCK)    
 WHERE PST.SectionId = @pSectionId   
 AND PST.[ProjectId] = @pProjectId    
 AND PST.CustomerId = @pCustomerId
 OPTION (FAST 1);
 
       
 IF @HasSegmentStatus = 0
BEGIN    

IF ISNULL(@pMasterSectionId,0) = 0
BEGIN
 SET @pMasterSectionId = (SELECT TOP 1    
  mSectionId    
 FROM dbo.ProjectSection WITH (NOLOCK)    
 WHERE SectionId = @pSectionId   
 AND ProjectId = @pProjectId    
 AND CustomerId = @pCustomerId    
 );  
End;  
    
INSERT INTO [dbo].ProjectSegmentStatus (SectionId, ParentSegmentStatusId,    
mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin,    
IndentLevel, SequenceNumber, SegmentStatusTypeId, IsParentSegmentStatusActive,    
ProjectId, CustomerId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy,    
SegmentStatusCode, SpecTypeTagId, IsShowAutoNumber, FormattingJson, IsRefStdParagraph,A_SegmentStatusId)    
 SELECT    
  @pSectionId    
    ,0    
    ,MST.SegmentStatusId    
    ,MST.SegmentId    
    ,NULL    
    ,MST.SegmentSource    
    ,MST.SegmentSource    
    ,MST.IndentLevel    
    ,MST.SequenceNumber    
    ,MST.SegmentStatusTypeId    
    ,IsParentSegmentStatusActive    
    ,@pProjectId    
    ,@pCustomerId    
    ,GETUTCDATE()    
    ,@pUserId    
    ,GETUTCDATE()    
    ,NULL    
    ,SegmentStatusCode    
    ,SpecTypeTagId    
    ,IsShowAutoNumber    
    ,FormattingJson    
    ,IsRefStdParagraph    
 ,MST.ParentSegmentStatusId as mParentSegmentStatusId  
 FROM SLCMaster.dbo.SegmentStatus AS MST WITH (NOLOCK)    
 WHERE MST.SectionId = @pMasterSectionId    
 AND ISNULL(MST.IsDeleted,0)=0   
 --ORDER BY MST.SequenceNumber;    
    
SELECT SegmentStatusId,mSegmentStatusId,A_SegmentStatusId as mParentSegmentStatusId INTO #TMP_PSST    
FROM [dbo].ProjectSegmentStatus PSST WITH (NOLOCK)    
WHERE PSST.SectionId = @pSectionId   
AND  PSST.ProjectId = @pProjectId    
AND PSST.CustomerId = @pCustomerId    
    
UPDATE PSST    
SET PSST.ParentSegmentStatusId = t.SegmentStatusId    
FROM [dbo].ProjectSegmentStatus PSST WITH (NOLOCK) INNER JOIN #TMP_PSST t  
ON t.mSegmentStatusId=PSST.A_SegmentStatusId  
WHERE PSST.SectionId = @pSectionId     
AND PSST.ProjectId = @pProjectId     
AND PSST.CustomerId = @pCustomerId  
  
--UPDATE CPSST    
--SET CPSST.ParentSegmentStatusId = PSST.SegmentStatusId    
--FROM dbo.ProjectSegmentStatus AS CPSST WITH (NOLOCK)    
----INNER JOIN SLCMaster.dbo.SegmentStatus AS CMSST WITH (NOLOCK)    
---- ON CMSST.SegmentStatusId = CPSST.mSegmentStatusId    
--INNER JOIN #TMP_PSST AS PSST WITH (NOLOCK)    
-- ON PSST.mSegmentStatusId = CPSST.mParentSegmentStatusId    
--WHERE CPSST.SectionId = @pSectionId     
--AND CPSST.ProjectId = @pProjectId     
--AND CPSST.CustomerId = @pCustomerId  
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
	, OptionJson nvarchar(MAX) '$.OptionJson'
	);

DECLARE @SingleSelectionChoiceTable TABLE (
	ProjectId INT
   ,CustomerId INT
   ,SectionId INT
   ,SegmentChoiceId INT
   ,ChoiceOptionId INT
   ,SegmentStatusId INT 
   ,OptionJson NVARCHAR(MAX)
)

INSERT INTO @SingleSelectionChoiceTable (ProjectId, CustomerId, SectionId, SegmentChoiceId, ChoiceOptionId, SegmentStatusId,OptionJson)
	SELECT DISTINCT
		TMT.ProjectId
	   ,TMT.CustomerId
	   ,TMT.SectionId
	   ,TMT.SegmentChoiceId
	   ,TMT.ChoiceOptionId
	   ,TMT.SegmentStatusId
	   ,TMT.OptionJson
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
   ,SegmentStatusId INT,
   OptionJson NVARCHAR(MAX)
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
   ,SegmentStatusId INT,
   OptionJson NVARCHAR(MAX)
)

INSERT INTO @MultipleSelectionChoiceTable (ProjectId, CustomerId, SectionId, SegmentChoiceId, ChoiceOptionId, SegmentStatusId,OptionJson)
	SELECT DISTINCT
		TMT.ProjectId
	   ,TMT.CustomerId
	   ,TMT.SectionId
	   ,TMT.SegmentChoiceId
	   ,TMT.ChoiceOptionId
	   ,TMT.SegmentStatusId
	   ,TMT.OptionJson
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
SET SCO.IsSelected = 1,
SCO.OptionJson=CASE WHEN TMTBL.OptionJson='' THEN NULL ELSE TMTBL.OptionJson END
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
,SCO.OptionJson=CASE WHEN TMTBL.OptionJson='' THEN NULL ELSE TMTBL.OptionJson END
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
PRINT N'Altering [dbo].[usp_UnlockLockedSection]...';


GO
ALTER PROCEDURE [dbo].[usp_UnlockLockedSection](@ProjectId INT, @SectionId INT, @CustomerId INT, @UserId INT) AS  
BEGIN
  
  DECLARE @PProjectId INT = @ProjectId;
  DECLARE @PSectionId INT = @SectionId;
  DECLARE @PCustomerId INT = @CustomerId;
  DECLARE @PUserId INT = @UserId;
UPDATE PS
SET PS.IsLocked = 0
   ,PS.LockedBy = 0
   ,PS.LockedByFullName = ''
   ,PS.ModifiedBy = @PUserId
   ,PS.ModifiedDate = GETUTCDATE()
FROM ProjectSection PS WITH (NOLOCK)
WHERE PS.SectionId = @PSectionId
AND PS.ProjectId = @PProjectId
AND PS.CustomerId = @PCustomerId

END
GO
PRINT N'Creating [dbo].[usp_ActiveMigratedProject]...';


GO
CREATE PROCEDURE [dbo].[usp_ActiveMigratedProject]     
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
PRINT N'Creating [dbo].[usp_ArchivedProjectsList]...';


GO
CREATE PROCEDURE [dbo].[usp_ArchivedProjectsList]
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
PRINT N'Creating [dbo].[usp_ArchiveMigratedProject]...';


GO
CREATE PROCEDURE usp_ArchiveMigratedProject  
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
PRINT N'Creating [dbo].[usp_CreateSectionFromMasterTemplate_Job]...';


GO
CREATE PROCEDURE [usp_CreateSectionFromMasterTemplate_Job] 
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
  ON PN.SectionId = @TargetSectionId
   AND PN_Template.NoteCode = PN.NoteCode
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
PRINT N'Creating [dbo].[usp_CreateSectionFromTemplateRequest]...';


GO
CREATE PROCEDURE usp_CreateSectionFromTemplateRequest
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
PRINT N'Creating [dbo].[usp_CreateSectionJob]...';


GO
CREATE PROCEDURE [dbo].[usp_CreateSectionJob]   
AS  
BEGIN  
 --Check for Expiry  
 update r
 set r.StatusId=5,
	r.IsNotify=0
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
PRINT N'Creating [dbo].[usp_DeleteMigratedProject]...';


GO
CREATE PROC usp_DeleteMigratedProject  
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
PRINT N'Creating [dbo].[usp_DeleteMigratedProjectPermanent]...';


GO
CREATE PROCEDURE usp_DeleteMigratedProjectPermanent  
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
PRINT N'Creating [dbo].[usp_GetAllNotifications]...';


GO
CREATE PROCEDURE [dbo].[usp_GetAllNotifications]
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
							TaskName nvarchar(500),StatusDescription nvarchar(50))
	
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
	FROM CopyProjectRequest CPR WITH(NOLOCK)    
	--INNER JOIN Project P WITH(NOLOCK)    
	  -- ON P.ProjectId = CPR.TargetProjectId   
	  -- INNER JOIN LuCopyStatus LCS  WITH(NOLOCK)
	  -- ON LCS.CopyStatusId=CPR.StatusId   
	WHERE CPR.CreatedById=@UserId  
	AND ISNULL(CPR.IsDeleted,0)=0    
	AND CPR.CreatedDate> @DateBefore30Days 
	--ORDER by CPR.CreatedDate DESC    
 
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
	 FROM ImportProjectRequest CPR WITH(NOLOCK)         
	 WHERE CPR.CreatedById=@UserId AND [Source] IN('SpecAPI','Import from Template')     
	 AND ISNULL(CPR.IsDeleted,0)=0       
	 AND CPR.CreatedDate> @DateBefore30Days           
	 --ORDER by CPR.CreatedDate DESC  

	 UPDATE t
	 SET t.StatusDescription=LCS.StatusDescription
	 FROM @RES t INNER JOIN LuCopyStatus LCS WITH(NOLOCK)     
	 ON t.StatusId=LCS.CopyStatusId

	 UPDATE t
	 SET t.TaskName=P.Name
	 FROM @RES t INNER JOIN Project P WITH(NOLOCK)     
	 ON t.TargetProjectId=P.ProjectId
	 WHERE P.CustomerId=@CustomerId
	 AND t.[Source]='CopyProject'

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

	 SELECT * FROM @RES
	 ORDER BY RequestDateTimeStr DESC
	 --Check type sorting performance

END
GO
PRINT N'Creating [dbo].[usp_GetMigratedDeletedProjects]...';


GO
CREATE PROCEDURE [dbo].[usp_GetMigratedDeletedProjects] --51,0               
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
PRINT N'Creating [dbo].[usp_GetMigratedProjectCount]...';


GO
CREATE PROC usp_GetMigratedProjectCount
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
PRINT N'Creating [dbo].[usp_GetMigratedProjectErrorsList]...';


GO
CREATE PROCEDURE usp_GetMigratedProjectErrorsList
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
PME.ProjectId,
(CASE WHEN PATINDEX('%{RS#%', SegmentDescription) > 0 THEN 1
WHEN PATINDEX('%{RSTEMP#%', SegmentDescription) > 0 THEN 1
WHEN PATINDEX('%{GT#%', SegmentDescription) > 0 THEN 1
ELSE 0
END) as HasRSAndGTCodes,
(CASE WHEN PATINDEX('%{CH#%', SegmentDescription) > 0 THEN 1 ELSE 0 END) as HasCHCodes
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
set e.SequenceNumber = CAST(PSS.SequenceNumber AS INT) ,
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
where HasCHCodes = 1

UPDATE t
SET t.segmentDescription1 = dbo.[fnGetSegmentDescriptionTextForRSAndGT](@ProjectId, @CustomerId, segmentDescription1)
FROM #errorList t
where HasRSAndGTCodes = 1


SELECT *,REPLACE(segmentDescription1,'{\rs\#', '{rs#') AS segmentDescription
from #errorList order by sectionId

END;
GO
PRINT N'Creating [dbo].[usp_GetMigratedProjectsList]...';


GO
CREATE PROCEDURE usp_GetMigratedProjectsList  
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
PRINT N'Creating [dbo].[usp_GetNotificationCount]...';


GO
CREATE PROCEDURE [dbo].[usp_GetNotificationCount]
	@UserId int,
	@CustomerId int
AS
BEGIN
	DECLARE @RES AS Table(CopyProject INT,SpecApiSection INT,CreateSectionFromTemplate INT)
	DECLARE @COUNT INT=0
	INSERT INTO @RES(CopyProject)
	SELECT COUNT(1) FROM CopyProjectRequest cp WITH(NOLOCK)
	WHERE cp.CreatedById=@UserId AND ISNULL(cp.IsDeleted,0)=0
	AND cp.StatusId IN(1,2)

	SELECT @COUNT=COUNT(1) FROM ImportProjectRequest cp WITH(NOLOCK)
	WHERE cp.CreatedById=@UserId AND ISNULL(cp.IsDeleted,0)=0
	AND cp.StatusId IN(1,2) and Source='SpecAPI' --verify

	UPDATE @RES
	SET SpecApiSection=@COUNT

	SET @COUNT=0
	SELECT @COUNT=COUNT(1) FROM ImportProjectRequest cp WITH(NOLOCK)
	WHERE cp.CreatedById=@UserId AND ISNULL(cp.IsDeleted,0)=0
	AND cp.StatusId IN(1,2) and Source='Import from Template'

	UPDATE @RES
	SET CreateSectionFromTemplate=@COUNT

	SELECT * FROM @RES
END
GO
PRINT N'Creating [dbo].[usp_GetNotificationProgress]...';


GO
CREATE PROCEDURE [dbo].[usp_GetNotificationProgress]
 @UserId int,  
 @RequestIdList nvarchar(100)='',  
 @CustomerId int,  
 @CopyProject BIT=0,  
 @ImportSection BIT=0
AS  
BEGIN  
 --find and mark as failed copy project requests which running loner(more than 30 mins)  
 --EXEC usp_UpdateLongRunningRequestsASFailed  
 DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())  
 DECLARE @RES AS TABLE(RequestId INT,SourceProjectId INT,TargetProjectId INT,TargetSectionId INT,  
       RequestDateTime DATETIME,RequestDateTimeStr NVARCHAR(20),RequestExpiryDateTime DATETIME,  
       StatusId INT,IsNotify BIT,CompletedPercentage INT,[Source] NVARCHAR(200),  
       TaskName nvarchar(500),StatusDescription nvarchar(50))  
  
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
  FROM CopyProjectRequest CPR WITH (NOLOCK)  
  WHERE CPR.CreatedById = @UserId AND CPR.IsNotify = 0  
  AND ISNULL(CPR.IsDeleted, 0) = 0    
  AND CPR.CreatedDate> @DateBefore30Days    
    
  UPDATE t  
  SET t.TaskName=P.Name  
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

PRINT N'Creating [dbo].[usp_GetProjectDivisionAndSections]...';
GO
CREATE PROCEDURE [dbo].[usp_GetProjectDivisionAndSections]
(          
 @ProjectId INT NULL,           
 @CustomerId INT NULL,           
 @UserId INT NULL=NULL,           
 @DisciplineId NVARCHAR (1024) NULL='',           
 @CatalogueType NVARCHAR (1024) NULL='FS',           
 @DivisionId NVARCHAR (1024) NULL='',          
 @UserAccessDivisionId NVARCHAR (1024) = ''              
)          
AS              
BEGIN      
  DECLARE @PprojectId INT = @ProjectId;      
  DECLARE @PcustomerId INT = @CustomerId;      
  DECLARE @PuserId INT = @UserId;      
  DECLARE @PDisciplineId NVARCHAR (1024) = @DisciplineId;      
  DECLARE @PCatalogueType NVARCHAR (1024) = @CatalogueType;     
  DECLARE @PDivisionId NVARCHAR (1024) = @DivisionId;      
  DECLARE @PUserAccessDivisionId NVARCHAR (1024) = @UserAccessDivisionId;  
      
 --IMP: Apply master updates to project for some types of actions      
 EXEC usp_ApplyMasterUpdatesToProject @PprojectId, @PcustomerId;  
  
 --DECLARE Variables      
 DECLARE @MasterDataTypeId INT = 0;  
 DECLARE @SourceTagFormat VARCHAR(10);  
  
 --Set data into variables          
 SELECT top 1 @MasterDataTypeId=MasterDataTypeId FROM Project WITH(NOLOCK) WHERE ProjectId = @PprojectId option(fast 1) --fast N

SELECT TOP 1 @SourceTagFormat=PS.SourceTagFormat FROM ProjectSummary PS WITH(NOLOCK) WHERE PS.ProjectId = @PprojectId option(fast 1) --fast N
 
 -- Fetch level 0 segments for status    
 DROP TABLE IF EXISTS #LevelZeroSegments    
 SELECT DISTINCT PSS.SectionId, PSS.SegmentStatusId, PSS.SegmentSource, PSS.SegmentOrigin, PSS.SegmentStatusTypeId  
  INTO #LevelZeroSegments        
  FROM ProjectSegmentStatus PSS WITH (NOLOCK)        
  WHERE PSS.CustomerId = @PCustomerId  
  AND PSS.ProjectId = @PProjectId   
  AND PSS.SequenceNumber = 0  
  AND PSS.IndentLevel = 0  
  AND PSS.ParentSegmentStatusId = 0  
  AND ISNULL(PSS.IsDeleted,0) = 0;

  -- Insert Project Sections into Temp table
  SELECT  
	  PS.SectionId
	 ,PS.mSectionId
	 ,PS.ParentSectionId
	 ,PS.ProjectId
	 ,PS.CustomerId
	 ,PS.TemplateId
	 ,PS.DivisionId
	 ,PS.DivisionCode
	 ,PS.[Description]
	 ,PS.LevelId
	 ,PS.IsLastLevel
	 ,PS.SourceTag
	 ,PS.Author
	 ,PS.CreatedBy
	 ,PS.CreateDate
	 ,PS.ModifiedBy
	 ,PS.ModifiedDate
	 ,PS.SectionCode
	 ,PS.IsLocked
	 ,PS.LockedBy
	 ,PS.LockedByFullName
	 ,PS.FormatTypeId
  INTO #ProjectSectionTemp
  FROM ProjectSection PS WITH(NOLOCK)
  WHERE PS.ProjectId = @projectId AND PS.CustomerId = @PcustomerId AND ISNULL(PS.IsDeleted,0) = 0

  -- Insert Deleted Master Sections into Temp table
  SELECT MS.SectionId, MS.IsDeleted
  INTO #DeletedMasterSectionTemp
  FROM SLCMaster..Section MS WITH(NOLOCK) WHERE ISNULL(MS.IsDeleted, 0) = 1
     
 ;WITH SectionTableCTE as (SELECT DISTINCT      
   PS.SectionId AS SectionId      
  ,ISNULL(PS.mSectionId, 0) AS mSectionId      
  ,ISNULL(PS.ParentSectionId, 0) AS ParentSectionId      
  ,PS.ProjectId AS ProjectId      
  ,PS.CustomerId AS CustomerId      
  ,@PuserId AS UserId      
  ,ISNULL(PS.TemplateId, 0) AS TemplateId      
  ,ISNULL(PS.DivisionId, 0) AS DivisionId      
  ,ISNULL(PS.DivisionCode, '') AS DivisionCode      
  ,ISNULL(PS.Description, '') AS [Description]
  ,CAST(1 as bit) AS IsDisciplineEnabled      
  ,PS.LevelId AS LevelId      
  ,PS.IsLastLevel AS IsLastLevel      
  ,PS.SourceTag AS SourceTag      
  ,ISNULL(PS.Author, '') AS Author      
  ,ISNULL(PS.CreatedBy, 0) AS CreatedBy      
  ,ISNULL(PS.CreateDate, GETDATE()) AS CreateDate      
  ,ISNULL(PS.ModifiedBy, 0) AS ModifiedBy      
  ,ISNULL(PS.ModifiedDate, GETDATE()) AS ModifiedDate      
  ,(CASE      
    WHEN PSS.SegmentStatusId IS NULL AND      
  PS.mSectionId IS NOT NULL THEN 'M'      
    WHEN PSS.SegmentStatusId IS NULL AND      
  PS.mSectionId IS NULL THEN 'U'      
    WHEN PSS.SegmentStatusId IS NOT NULL AND      
  PSS.SegmentSource = 'M' AND      
  PSS.SegmentOrigin = 'M' THEN 'M'      
    WHEN PSS.SegmentStatusId IS NOT NULL AND      
  PSS.SegmentSource = 'U' AND      
  PSS.SegmentOrigin = 'U' THEN 'U'      
    WHEN PSS.SegmentStatusId IS NOT NULL AND      
  PSS.SegmentSource = 'M' AND      
  PSS.SegmentOrigin = 'U' THEN 'M*'      
   END) AS SegmentOrigin      
  ,COALESCE(PSS.SegmentStatusTypeId, -1) AS SegmentStatusTypeId      
  ,ISNULL(PS.SectionCode, 0) AS SectionCode      
  ,ISNULL(PS.IsLocked, 0) AS IsLocked      
  ,ISNULL(PS.LockedBy, 0) AS LockedBy      
  ,ISNULL(PS.LockedByFullName, '') AS LockedByFullName      
  ,PS.FormatTypeId AS FormatTypeId      
  ,@SourceTagFormat AS SourceTagFormat          
  ,(CASE WHEN (MS.SectionId IS NOT NULL AND MS.IsDeleted = 1) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END) AS IsMasterDeleted  
  ,(CASE      
    WHEN PS.IsLastLevel = 1 AND      
  (PS.mSectionId IS NULL OR      
  PS.mSectionId = 0) THEN 1      
    ELSE 0      
   END) AS IsUserSection      
  FROM #ProjectSectionTemp PS WITH (NOLOCK)      
  LEFT JOIN #DeletedMasterSectionTemp MS WITH (NOLOCK)      
   ON PS.mSectionId = MS.SectionId      
  LEFT OUTER JOIN #LevelZeroSegments AS PSS WITH (NOLOCK) ON PS.SectionId = PSS.SectionId
 )  
     
 SELECT * FROM SectionTableCTE ORDER BY SourceTag ASC, Author ASC  
  
END
GO
PRINT N'Creating [dbo].[usp_GetProjectGlobalTerm]...';


GO
CREATE PROCEDURE usp_GetProjectGlobalTerm    
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
PRINT N'Creating [dbo].[usp_GetProjectSectionHyperLinks]...';


GO
CREATE PROCEDURE usp_GetProjectSectionHyperLinks
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
	   'U' AS [Source]
	FROM ProjectHyperLink HLNK WITH (NOLOCK)    
	WHERE HLNK.SectionId = @SectionId AND HLNK.ProjectId = @ProjectId;

END
GO
PRINT N'Creating [dbo].[usp_GetProjectSections]...';


GO
CREATE PROCEDURE usp_GetProjectSections  
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
 AND S.IsLastLevel = 1
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
PRINT N'Creating [dbo].[usp_GetProjectSectionUserTag]...';


GO
CREATE PROC usp_GetProjectSectionUserTag
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
PRINT N'Creating [dbo].[usp_GetProjectSegmentImage]...';


GO
CREATE PROCEDURE usp_GetProjectSegmentImage    
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
PRINT N'Creating [dbo].[usp_GetProjectSummary]...';


GO
CREATE PROCEDURE usp_GetProjectSummary
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
   WHERE PS.ProjectId = @ProjectId;

	DECLARE @DateFormat NVARCHAR(50) = NULL,@TimeFormat NVARCHAR(50) = NULL;
	DECLARE @MasterDataTypeId INT = (SELECT TOP 1 MasterDataTypeId FROM Project WITH(NOLOCK) WHERE ProjectId = @ProjectId);

	SELECT @DateFormat = [DateFormat], @TimeFormat = [ClockFormat]
	FROM ProjectDateFormat WITH(NOLOCK)
	WHERE ProjectId = @ProjectId;

	IF (@DateFormat IS NULL)
	BEGIN
		SELECT TOP 1 @DateFormat = [DateFormat], @TimeFormat = [ClockFormat] 
		FROM ProjectDateFormat WITH(NOLOCK) 
		WHERE MasterDataTypeId = @MasterDataTypeId AND ProjectId IS NULL AND CustomerId IS NULL AND UserId IS NULL;
	END

	SELECT @DateFormat AS [DateFormat], @TimeFormat AS ClockFormat;

END
GO
PRINT N'Creating [dbo].[usp_GetProjectTemplateStyle]...';


GO
CREATE PROCEDURE usp_GetProjectTemplateStyle  
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
PRINT N'Creating [dbo].[usp_GetSectionChoices]...';


GO
CREATE PROCEDURE [dbo].[usp_GetSectionChoices]
(  
 @ProjectId INT   
 ,@SectionId INT   
 ,@CustomerId INT 
 ,@MasterSectionId INT
)  
AS  
BEGIN  
  
  SET NOCOUNT ON;
 DECLARE @IsMasterSection INT = CASE WHEN ISNULL(@MasterSectionId,0) =0 THEN 0 ELSE 1 END;  
 DECLARE @finalOutput TABLE
 (
   SegmentId INT
   ,mSegmentId INT
   ,ChoiceTypeId INT
   ,ChoiceSource CHAR(1)
   ,SegmentChoiceCode     INT
   ,ChoiceOptionCode   INT 
   ,IsSelected    BIT
   ,ChoiceOptionSource   CHAR(1) 
   ,OptionJson NVARCHAR(MAX)   
   ,SortOrder    TINYINT
   ,SegmentChoiceId    INT
   ,ChoiceOptionId   BIGINT 
   ,SelectedChoiceOptionId  INT
 )
  
 SELECT SegmentId, mSegmentId  
 INTO #ProjectSegmentStatus  
 FROM ProjectSegmentStatus PSS  
 WHERE PSS.SectionId = @SectionId  
 AND PSS.ProjectId = @ProjectId  
 AND PSS.CustomerId = @CustomerId;   
  
 -- GET Project Choice only if ProjectSegmentChoice has entry  
 IF EXISTS(SELECT TOP 1 1 FROM ProjectSegmentChoice PSC WHERE PSC.SectionId = @SectionId AND PSC.ProjectId = @ProjectId)  
 BEGIN  
  --NOTE -- Need to fetch distinct SelectedChoiceOption records     
  DROP TABLE IF EXISTS #SelectedChoiceOptionTempProject  
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
  INTO #SelectedChoiceOptionTempProject   
  FROM SelectedChoiceOption SCHOP WITH (NOLOCK)   
  WHERE SCHOP.SectionId = @SectionId      
  AND SCHOP.ProjectId = @ProjectId  
  AND SCHOP.CustomerId = @CustomerId   
  AND ISNULL(SCHOP.IsDeleted, 0) = 0  
  AND SCHOP.ChoiceOptionSource = 'U';  
  
  DROP TABLE IF EXISTS #ProjectSegmentChoiceTemp;  
  SELECT  
   PSC.SegmentId  
  ,PSC.ChoiceTypeId  
  ,PSC.SegmentChoiceSource  
  ,PSC.SegmentChoiceCode  
  ,PSC.SegmentChoiceId  
  ,PSC.SectionId  
  INTO #ProjectSegmentChoiceTemp  
  FROM ProjectSegmentChoice PSC  
  WHERE PSC.SectionId = @SectionId AND PSC.ProjectId = @ProjectId AND ISNULL(PSC.IsDeleted, 0) = 0;  
  
  DROP TABLE IF EXISTS #ProjectChoiceOptionTemp;  
  SELECT  
   PCO.ChoiceOptionCode  
  ,PCO.OptionJson  
  ,PCO.SortOrder  
  ,PCO.ChoiceOptionId  
  ,PCO.SegmentChoiceId  
  ,PCO.SectionId  
  INTO #ProjectChoiceOptionTemp  
  FROM ProjectChoiceOption PCO  
  WHERE PCO.SectionId = @SectionId AND PCO.ProjectId = @ProjectId AND ISNULL(PCO.IsDeleted, 0) = 0;  
  
  INSERT INTO @finalOutput
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
  FROM  #ProjectSegmentStatus PSST WITH (NOLOCK)  
  INNER JOIN #ProjectSegmentChoiceTemp PCH WITH (NOLOCK)  
  ON PSST.SegmentId = PCH.SegmentId  
  INNER JOIN #ProjectChoiceOptionTemp PCHOP WITH (NOLOCK)    
   ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId  
  INNER JOIN #SelectedChoiceOptionTempProject PSCHOP WITH (NOLOCK)    
   ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode    
    AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode;  
 END  
  
 -- GE  
 IF(@IsMasterSection = 1)  
 BEGIN  
  
  DROP TABLE IF EXISTS #SelectedChoiceOptionTempMaster   
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
  INTO #SelectedChoiceOptionTempMaster   
  FROM SelectedChoiceOption SCHOP WITH (NOLOCK)   
  WHERE SCHOP.SectionId = @SectionId      
  AND SCHOP.ProjectId = @ProjectId  
  AND SCHOP.CustomerId = @CustomerId   
  AND ISNULL(SCHOP.IsDeleted, 0) = 0  
  AND SCHOP.ChoiceOptionSource = 'M';  
  
  
  DROP TABLE IF EXISTS #MasterSegmentChoiceTemp;  
  SELECT  
   MSC.SegmentId  
  ,MSC.ChoiceTypeId  
  ,MSC.SegmentChoiceSource  
  ,MSC.SegmentChoiceCode  
  ,MSC.SegmentChoiceId  
  ,MSC.SectionId  
  INTO #MasterSegmentChoiceTemp  
  FROM SLCMaster..SegmentChoice MSC  
  WHERE MSC.SectionId = @MasterSectionId  
   
 INSERT INTO @finalOutput
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
  INNER JOIN #MasterSegmentChoiceTemp MCH WITH (NOLOCK)  
  ON PSST.mSegmentId = MCH.SegmentId  
  INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)    
   ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId  
  INNER JOIN #SelectedChoiceOptionTempMaster PSCHOP WITH (NOLOCK)  
    ON MCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode  
    AND MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode;     
    
 END  

 SELECT * FROM @finalOutput
END
GO
PRINT N'Creating [dbo].[usp_GetSegmentsForSection]...';


GO
CREATE PROCEDURE [dbo].[usp_GetSegmentsForSection]  
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
       
IF @IsMasterSection = 1  
 BEGIN -- Data Mapping SP's                  
   EXECUTE usp_MapSegmentStatusFromMasterToProject @ProjectId = @PProjectId                              
  ,@SectionId = @PSectionId                              
  ,@CustomerId = @PCustomerId                              
  ,@UserId = @PUserId  
  ,@MasterSectionId =@MasterSectionId;                              
   EXECUTE usp_MapSegmentChoiceFromMasterToProject @ProjectId = @PProjectId                    
  ,@SectionId = @PSectionId                              
  ,@CustomerId = @PCustomerId                              
  ,@UserId = @PUserId  
  ,@MasterSectionId =@MasterSectionId;                              
   EXECUTE usp_MapProjectRefStands @ProjectId = @PProjectId                   
    ,@SectionId = @PSectionId                              
    ,@CustomerId = @PCustomerId                              
    ,@UserId = @PUserId  
    ,@MasterSectionId=@MasterSectionId;                              
   EXECUTE usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @PProjectId                              
    ,@SectionId = @PSectionId                              
    ,@CustomerId = @PCustomerId                              
    ,@UserId = @PUserId  
     ,@MasterSectionId=@MasterSectionId;            
   EXECUTE usp_MapSegmentLinkFromMasterToProject @ProjectId = @PProjectId                            
   ,@SectionId = @PSectionId                              
   ,@CustomerId = @PCustomerId                              
   ,@UserId = @PUserId;                              
   EXECUTE usp_UpdateSegmentStatus_ApplyMasterUpdate @ProjectId = @PProjectId                              
    ,@CustomerId = @PCustomerId                              
    ,@SectionId = @PSectionId       
    -- NOT IN USE hence commented                         
   --EXECUTE usp_DeleteSegmentRequirementTag_ApplyMasterUpdate @ProjectId = @PProjectId                              
   --,@CustomerId = @PCustomerId                              
   --,@SectionId = @PSectionId                    
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
  SELECT MN.SegmentStatusId    
  INTO #MasterNotes    
  FROM SLCMaster..Note MN WITH (NOLOCK)    
  WHERE MN.SectionId = @MasterSectionId;    
    
  SELECT PN.SegmentStatusId    
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
PRINT N'Creating [dbo].[usp_GetSegmentsNotesMapping]...';


GO
CREATE PROCEDURE [dbo].[usp_GetSegmentsNotesMapping] -- [Obsolute]
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
PRINT N'Creating [dbo].[usp_GetTrackChangesModeInfo]...';


GO
CREATE PROCEDURE usp_GetTrackChangesModeInfo
(    
 @ProjectId INT,  
 @SectionId INT
)    
AS    
BEGIN

	DECLARE @TcModeBySection TINYINT = 3;
	SELECT TOP 1 @TcModeBySection = ISNULL(TrackChangesModeId, @TcModeBySection)
	FROM ProjectSummary WITH(NOLOCK) WHERE ProjectId = @ProjectId
	OPTION (FAST 1);

	SELECT 
	 @TcModeBySection AS TrackChangesModeId
	,IsTrackChanges
	,IsTrackChangeLock  
	,COALESCE(TrackChangeLockedBy, 0) AS TrackChangeLockedBy
	FROM ProjectSection WITH(NOLOCK)  
	WHERE SectionId = @SectionId;

END
GO
PRINT N'Creating [dbo].[usp_MapMasterDataToProjectForSection]...';


GO
CREATE PROCEDURE [dbo].[usp_MapMasterDataToProjectForSection]
(
	@ProjectId INT,      
	@SectionId INT,       
	@CustomerId INT,       
	@UserId INT ,
	@MSectionId INT=null
)
AS
BEGIN
	 DECLARE @PProjectId INT = @ProjectId;                             
	 DECLARE @PSectionId INT = @SectionId;                              
	 DECLARE @PCustomerId INT = @CustomerId;                              
	 DECLARE @PUserId INT = @UserId;  
	 DECLARE @PMasterSectionId INT = @MSectionId;  

	IF ISNULL(@PMasterSectionId,0) >0
	BEGIN -- Data Mapping SP's                  
	   EXECUTE usp_MapSegmentStatusFromMasterToProject @ProjectId = @PProjectId                              
	  ,@SectionId = @PSectionId                              
	  ,@CustomerId = @PCustomerId                              
	  ,@UserId = @PUserId  
	  ,@MasterSectionId =@PMasterSectionId;   

	   EXECUTE usp_MapSegmentChoiceFromMasterToProject @ProjectId = @PProjectId                    
	  ,@SectionId = @PSectionId                              
	  ,@CustomerId = @PCustomerId                              
	  ,@UserId = @PUserId  
	  ,@MasterSectionId =@PMasterSectionId;   
	  
	   EXECUTE usp_MapProjectRefStands @ProjectId = @PProjectId                   
		,@SectionId = @PSectionId                              
		,@CustomerId = @PCustomerId                              
		,@UserId = @PUserId  
		,@MasterSectionId=@PMasterSectionId;  
		
	   EXECUTE usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @PProjectId                              
		,@SectionId = @PSectionId                              
		,@CustomerId = @PCustomerId                              
		,@UserId = @PUserId  
		 ,@MasterSectionId=@PMasterSectionId;   
		 
	   EXECUTE usp_MapSegmentLinkFromMasterToProject @ProjectId = @PProjectId                            
	   ,@SectionId = @PSectionId                              
	   ,@CustomerId = @PCustomerId                              
	   ,@UserId = @PUserId;         
	   
	   EXECUTE usp_UpdateSegmentStatus_ApplyMasterUpdate @ProjectId = @PProjectId                              
		,@CustomerId = @PCustomerId                              
		,@SectionId = @PSectionId       
		-- NOT IN USE hence commented                         
	   --EXECUTE usp_DeleteSegmentRequirementTag_ApplyMasterUpdate @ProjectId = @PProjectId                              
	   --,@CustomerId = @PCustomerId                              
	   --,@SectionId = @PSectionId     
	   
	   UPDATE PS
		SET PS.DataMapDateTimeStamp=GETUTCDATE()
		FROM ProjectSection PS WITH(NOLOCK)
		WHERE SectionId = @PSectionId

	END  
END
GO
PRINT N'Creating [dbo].[usp_MarkProjectMigrationErrorAsResolved]...';


GO
       
CREATE PROCEDURE usp_MarkProjectMigrationErrorAsResolved            
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
PRINT N'Creating [dbo].[usp_RemoveNotification]...';


GO
CREATE PROC usp_RemoveNotification
(  
 @RequestId INT,
 @Source NVARCHAR(50)
)  
AS  
BEGIN  
 UPDATE CPR  
 SET CPR.IsDeleted=1,  
 ModifiedDate=GETUTCDATE()  
 FROM CopyProjectRequest CPR WITH(NOLOCK)  
 WHERE CPR.StatusId NOT IN(2) AND CPR.RequestId=@RequestId  
END
GO
PRINT N'Creating [dbo].[usp_RestoreMigratedProjectFromDelete]...';


GO
CREATE PROC usp_RestoreMigratedProjectFromDelete  
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
PRINT N'Creating [dbo].[usp_SaveSpecDataProjectNote]...';


GO
CREATE PROC [dbo].[usp_SaveSpecDataProjectNote] 
(@NoteDataString NVARCHAR(MAX) ='' )     
AS     
Begin     
CREATE TABLE #InpNoteTableVar (            
 SectionId INT NULL,        
 SegmentStatusId INT NULL,        
 --MSectionId INT NULL,        
 --MSegmentStatusId INT NULL,      
 NoteText NVARCHAR(MAX) NULL,          
 Title  NVARCHAR(500) NULL,        
 ProjectId INT NULL,     
 CustomerId INT NULL
   
 );      
    
 IF @NoteDataString != ''          
BEGIN      
INSERT INTO #InpNoteTableVar      
 SELECT      
  *      
 FROM OPENJSON(@NoteDataString)      
 WITH (   
 SectionId INT '$.SectionId',      
 SegmentStatusId INT '$.SegmentStatusId',      
 --MSectionId INT '$.MSectionId',      
 --MSegmentStatusId INT '$.MSegmentStatusId',      
 NoteText NVARCHAR(MAX) '$.NoteText',      
 Title NVARCHAR(500) '$.Title',      
 ProjectId INT '$.ProjectId',      
 CustomerId INT '$.CustomerId'    
 );      
END      
    
UPDATE NTV SET NTV.SegmentStatusId= PSS.SegmentStatusId,NTV.SectionId=PSS.SectionId    
From ProjectSegmentStatus PSS with (nolock) Inner Join  #InpNoteTableVar NTV    
ON PSS.MSegmentStatusId=NTV.SegmentStatusId    
WHERE PSS.ProjectId=NTV.ProjectId    
AND PSS.CustomerId=NTV.CustomerId
    
      
INSERT INTO ProjectNote (SectionId      
, SegmentStatusId      
, NoteText      
, CreateDate      
, ModifiedDate      
, ProjectId      
, CustomerId      
, Title      
, CreatedBy       
, IsDeleted      
, A_NoteId)      
      
 SELECT      
     SectionId      
    ,SegmentStatusId      
    ,NoteText      
    ,GETUTCDATE()      
    ,GETUTCDATE()      
    ,ProjectId      
    ,CustomerId      
    ,Title      
    ,CustomerId       
    ,0      
    ,0      
 FROM #InpNoteTableVar      


END
GO
PRINT N'Creating [dbo].[usp_UnArchiveProject]...';


GO
CREATE PROC usp_UnArchiveProject  
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
PRINT N'Creating [dbo].[usp_UpdateCopyProjectStepProgress]...';


GO
CREATE PROCEDURE [dbo].[usp_UpdateCopyProjectStepProgress]
AS
BEGIN

   	--find and mark as failed copy project requests which running loner(more than 30 mins)
	UPDATE cpr
	SET cpr.StatusId=5
		,cpr.IsNotify=0
		,cpr.IsEmailSent=0
		,ModifiedDate=GETUTCDATE()
	FROM dbo.CopyProjectRequest cpr WITH(nolock) 
	INNER JOIN dbo.CopyProjectHistory cph WITH(NOLOCK)
	ON cpr.RequestId=cph.RequestId
	WHERE cpr.StatusId = 2 
	and cph.CreatedDate < DATEADD(MINUTE,-30,GETUTCDATE())
	and cph.Step=2

END;
GO
PRINT N'Creating [dbo].[usp_UpdateLongRunningRequestsASFailed]...';


GO
CREATE PROCEDURE [dbo].[usp_UpdateLongRunningRequestsASFailed]
AS
BEGIN
	UPDATE cpr
	SET cpr.StatusId=5
		,cpr.IsNotify=0
		,cpr.IsEmailSent=0
		,ModifiedDate=GETUTCDATE()
	FROM CopyProjectRequest cpr WITH(nolock) INNER JOIN CopyProjectHistory cph WITH(NOLOCK)
	ON cpr.RequestId=cph.RequestId
	WHERE cpr.StatusId = 2 and cph.CreatedDate < DATEADD(MINUTE,-30,GETUTCDATE())
	and cph.Step=2


END
GO
PRINT N'Altering [dbo].[usp_GetSegmentLinkDetails]...';


GO
ALTER PROCEDURE [dbo].[usp_GetSegmentLinkDetails] (@InpSegmentLinkJson NVARCHAR(MAX))    
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

/** [BLOCK] MAP CLICKED SECTION DATA IF NOT OPENED **/
BEGIN
--LOOP INP SEGMENT LINK TABLE TO MAP SEGMENT STATUS AND CHOICES IF SECTION STATUS IS CLICKED      
DECLARE @InputDataTableRowCount INT = (SELECT
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

DECLARE @HasProjectSegmentStatus INT =0;
SELECT @HasProjectSegmentStatus = COUNT(1)
		FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)
		WHERE PSST.SectionId = @LoopedSectionId AND PSST.ProjectId = @ProjectId
		AND PSST.CustomerId = @CustomerId
OPTION (FAST 1);

IF ( @HasProjectSegmentStatus =0)
BEGIN
EXEC usp_MapSegmentStatusFromMasterToProject @ProjectId = @ProjectId
												,@SectionId = @LoopedSectionId
												,@CustomerId = @CustomerId
												,@UserId = @UserId;
END

DECLARE @HasSelectedChoiceOption INT =0;
SELECT @HasSelectedChoiceOption =COUNT(1)
		FROM SelectedChoiceOption AS PSCHOP WITH (NOLOCK)
		WHERE PSCHOP.SectionId = @LoopedSectionId
		AND PSCHOP.ProjectId = @ProjectId
		AND PSCHOP.ChoiceOptionSource = 'M'
		AND PSCHOP.CustomerId = @CustomerId
		OPTION (FAST 1);

IF ( @HasSelectedChoiceOption =0 )
BEGIN
EXEC usp_MapSegmentChoiceFromMasterToProject @ProjectId = @ProjectId
												,@SectionId = @LoopedSectionId
												,@CustomerId = @CustomerId
												,@UserId = @UserId;
END

DECLARE @HasProjectSegmentRequirementTag INT =0;
SELECT @HasProjectSegmentRequirementTag = COUNT(1)
		FROM ProjectSegmentRequirementTag AS PSRT WITH (NOLOCK)
		WHERE PSRT.ProjectId = @ProjectId
		AND PSRT.CustomerId = @CustomerId
		AND PSRT.SectionId = @LoopedSectionId
		OPTION (FAST 1);
IF ( @HasProjectSegmentRequirementTag = 0)
BEGIN
EXEC dbo.usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @ProjectId
														,@SectionId = @LoopedSectionId
														,@CustomerId = @CustomerId
														,@UserId = @UserId;
END

--EXEC dbo.usp_MapSegmentLinkFromMasterToProject @ProjectId = @ProjectId    
--             ,@SectionId = @LoopedSectionId    
--             ,@CustomerId = @CustomerId    
--             ,@UserId = @UserId;    

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
	INNER JOIN ProjectSegmentLink PSLNK WITH (NOLOCK)
		ON TMP.ProjectId = PSLNK.ProjectId
			AND TMP.SectionCode = PSLNK.TargetSectionCode
			AND TMP.SegmentStatusCode = PSLNK.TargetSegmentStatusCode
			AND TMP.SegmentSource = PSLNK.LinkTarget
	WHERE PSLNK.ProjectId = @ProjectId
	AND PSLNK.CustomerId = @CustomerId
--AND PSLNK.IsDeleted = 0    

--Print '--2. FETCH TGT LINKS FROM SLCProject..ProjectSegmentLink'
--2. FETCH TGT LINKS FROM SLCProject..ProjectSegmentLink    
;
WITH ProjectLinksCTE
AS
(SELECT
		PSLNK.*
	   ,1 AS Iteration
	FROM #InputDataTable TMP WITH (NOLOCK)
	INNER JOIN ProjectSegmentLink PSLNK WITH (NOLOCK)
		ON TMP.ProjectId = PSLNK.ProjectId
		AND TMP.SectionCode = PSLNK.SourceSectionCode
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
	INNER JOIN ProjectSegmentLink PSLNK WITH (NOLOCK)
		ON CTE.ProjectId = PSLNK.ProjectId
		AND CTE.TargetSectionCode = PSLNK.SourceSectionCode
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
	INNER JOIN ProjectSegmentLink SLNK WITH (NOLOCK)
		--TODO : Sushil; add projectid into #SegmentLinkTable  
		ON SLT.ProjectId = SLNK.ProjectId
			AND -- Added by Bhushan  
			SLT.TargetSectionCode = SLNK.TargetSectionCode
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
INSERT INTO #TargetSectionCodeTable
	SELECT DISTINCT
		ROW_NUMBER() OVER (ORDER BY X.SectionCode) AS Id
	   ,X.SectionCode
	   ,PS.SectionId
	FROM (SELECT DISTINCT
			TargetSectionCode AS SectionCode
		FROM #SegmentLinkTable) AS X
	INNER JOIN ProjectSection PS WITH (NOLOCK)
		ON PS.SectionCode = X.SectionCode
	LEFT JOIN ProjectSegmentStatus PSST WITH (NOLOCK)
		ON PS.SectionId = PSST.SectionId
			AND PSST.ParentSegmentStatusId = 0
			AND PSST.IndentLevel = 0
	WHERE PS.ProjectId = @ProjectId
	AND PS.CustomerId = @CustomerId
	AND PS.IsLastLevel = 1
	AND PS.mSectionId IS NOT NULL
	AND PS.IsDeleted = 0
	AND PSST.SegmentStatusId IS NULL
END

/** [BLOCK] LOOP TO MAP TARGET SECTIONS DATA **/
BEGIN
DECLARE @TargetSectionCodeTableRowCount INT = (SELECT
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
    
DECLARE @HasLoopedProjectSegmentStatus INT = 0;
SELECT @HasLoopedProjectSegmentStatus= COUNT(1)
	FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	AND PSST.SectionId = @LoopedSectionId  
	OPTION (FAST 1);
IF (@HasLoopedProjectSegmentStatus = 0)
BEGIN
EXEC dbo.usp_MapSegmentStatusFromMasterToProject @ProjectId = @ProjectId
												,@SectionId = @LoopedSectionId
												,@CustomerId = @CustomerId
												,@UserId = @UserId;
END

DECLARE @HasLoopedSelectedChoiceOption INT =0;
SELECT @HasLoopedSelectedChoiceOption = COUNT(1)
		FROM SelectedChoiceOption AS PSCHOP WITH (NOLOCK)
		WHERE PSCHOP.ProjectId = @ProjectId
		AND PSCHOP.CustomerId = @CustomerId
		AND PSCHOP.SectionId = @LoopedSectionId
		AND PSCHOP.ChoiceOptionSource = 'M'
		OPTION (FAST 1);
IF (@HasLoopedSelectedChoiceOption = 0)
BEGIN
EXEC dbo.usp_MapSegmentChoiceFromMasterToProject @ProjectId = @ProjectId
												,@SectionId = @LoopedSectionId
												,@CustomerId = @CustomerId
												,@UserId = @UserId;
END

DECLARE @HasLoopedProjectSegmentRequirementTag INT =0;
SELECT @HasLoopedProjectSegmentRequirementTag =COUNT(1)
		FROM ProjectSegmentRequirementTag AS PSRT WITH (NOLOCK)
		WHERE PSRT.ProjectId = @ProjectId
		AND PSRT.CustomerId = @CustomerId
		AND PSRT.SectionId = @LoopedSectionId
		OPTION (FAST 1);
IF (@HasLoopedProjectSegmentRequirementTag = 0)
BEGIN
EXEC dbo.usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @ProjectId
														,@SectionId = @LoopedSectionId
														,@CustomerId = @CustomerId
														,@UserId = @UserId;
END

--EXEC dbo.usp_MapSegmentLinkFromMasterToProject @ProjectId = @ProjectId    
--             ,@SectionId = @LoopedSectionId    
--             ,@CustomerId = @CustomerId    
--             ,@UserId = @UserId;    

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
	INNER JOIN ProjectSection PS WITH (NOLOCK)
		ON PSST.SectionId = PS.SectionId
	INNER JOIN #InputDataTable IDT WITH (NOLOCK)
		ON PS.SectionCode = IDT.SectionCode
			AND PSST.SegmentStatusCode = IDT.SegmentStatusCode
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	AND PS.IsDeleted = 0
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
	INNER JOIN ProjectSection PS WITH (NOLOCK)
		ON PSST.SectionId = PS.SectionId
	INNER JOIN #SegmentLinkTable SRC_SLT WITH (NOLOCK)
		ON PS.SectionCode = SRC_SLT.SourceSectionCode
			AND PSST.SegmentStatusCode = SRC_SLT.SourceSegmentStatusCode
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	AND PS.IsDeleted = 0
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
	INNER JOIN ProjectSection PS WITH (NOLOCK)
		ON PSST.SectionId = PS.SectionId
	INNER JOIN #SegmentLinkTable TGT_SLT WITH (NOLOCK)
		ON PS.SectionCode = TGT_SLT.TargetSectionCode
			AND PSST.SegmentStatusCode = TGT_SLT.TargetSegmentStatusCode
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	AND PS.IsDeleted = 0
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
	INNER JOIN ProjectSection PS WITH (NOLOCK)
		ON PSST.SectionId = PS.SectionId
	INNER JOIN ProjectSegmentStatus CPSST WITH (NOLOCK)
		ON PSST.SegmentStatusId = CPSST.ParentSegmentStatusId
	INNER JOIN #InputDataTable IDT WITH (NOLOCK)
		ON PS.SectionCode = IDT.SectionCode
			AND PSST.SegmentStatusCode = IDT.SegmentStatusCode
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	AND PS.IsDeleted = 0
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
	INNER JOIN ProjectSection PS WITH (NOLOCK)
		ON PSST.SectionId = PS.SectionId
	INNER JOIN ProjectSegmentStatus CPSST WITH (NOLOCK)
		ON PSST.SegmentStatusId = CPSST.ParentSegmentStatusId
	INNER JOIN #SegmentLinkTable TGT_SLT WITH (NOLOCK)
		ON PS.SectionCode = TGT_SLT.TargetSectionCode
			AND PSST.SegmentStatusCode = TGT_SLT.TargetSegmentStatusCode
			AND TGT_SLT.Iteration <= @MaxIteration
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	AND PS.IsDeleted = 0
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
	INNER JOIN ProjectSection PS WITH (NOLOCK)
		ON PSST.SectionId = PS.SectionId
	INNER JOIN ProjectSegmentStatus PPSST WITH (NOLOCK)
		ON PSST.ParentSegmentStatusId = PPSST.SegmentStatusId
	INNER JOIN #InputDataTable IDT WITH (NOLOCK)
		ON PS.SectionCode = IDT.SectionCode
			AND PSST.SegmentStatusCode = IDT.SegmentStatusCode
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	AND PS.IsDeleted = 0
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
	INNER JOIN ProjectSection PS WITH (NOLOCK)
		ON PSST.SectionId = PS.SectionId
	INNER JOIN ProjectSegmentStatus PPSST WITH (NOLOCK)
		ON PSST.ParentSegmentStatusId = PPSST.SegmentStatusId
	INNER JOIN #SegmentLinkTable TGT_SLT WITH (NOLOCK)
		ON PS.SectionCode = TGT_SLT.TargetSectionCode
			AND PSST.SegmentStatusCode = TGT_SLT.TargetSegmentStatusCode
			AND TGT_SLT.Iteration <= @MaxIteration
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.CustomerId = @CustomerId
	AND PS.IsDeleted = 0
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
	AND PS.IsDeleted = 0
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
	INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)
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
	INNER JOIN ProjectSegmentLink SLNK WITH (NOLOCK)
		ON TMPSST.ProjectId = SLNK.ProjectId
		AND TMPSST.SectionCode = SLNK.SourceSectionCode
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
		ON PSST.SectionId = SCHOP.SectionId
			AND CH.SegmentChoiceCode = SCHOP.SegmentChoiceCode
			AND CHOP.ChoiceOptionCode = SCHOP.ChoiceOptionCode
	INNER JOIN #SegmentLinkTable SRC_SLT WITH (NOLOCK)
		ON SCHOP.SegmentChoiceCode = SRC_SLT.SourceSegmentChoiceCode
			AND SCHOP.ChoiceOptionSource = SRC_SLT.LinkSource
	WHERE SCHOP.ProjectId = @ProjectId
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
		ON PSST.SectionId = SCHOP.SectionId
			AND CH.SegmentChoiceCode = SCHOP.SegmentChoiceCode
			AND CHOP.ChoiceOptionCode = SCHOP.ChoiceOptionCode
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
		ON CH.SectionId = PSST.SectionId
			AND PSST.SegmentId = CH.SegmentId
	INNER JOIN ProjectChoiceOption CHOP WITH (NOLOCK)
		ON CHOP.SectionId = PSST.SectionId
			AND CH.SegmentChoiceId = CHOP.SegmentChoiceId
	INNER JOIN SelectedChoiceOption SCHOP WITH (NOLOCK)
		ON PSST.SectionId = SCHOP.SectionId
			AND CH.SegmentChoiceCode = SCHOP.SegmentChoiceCode
			AND CHOP.ChoiceOptionCode = SCHOP.ChoiceOptionCode
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
		ON CH.SectionId = PSST.SectionId
			AND PSST.SegmentId = CH.SegmentId
	INNER JOIN ProjectChoiceOption CHOP WITH (NOLOCK)
		ON CHOP.SectionId = PSST.SectionId
			AND CH.SegmentChoiceId = CHOP.SegmentChoiceId
	INNER JOIN SelectedChoiceOption SCHOP WITH (NOLOCK)
		ON PSST.SectionId = SCHOP.SectionId
			AND CH.SegmentChoiceCode = SCHOP.SegmentChoiceCode
			AND CHOP.ChoiceOptionCode = SCHOP.ChoiceOptionCode
	INNER JOIN #SegmentLinkTable TGT_SLT WITH (NOLOCK)
		ON SCHOP.SegmentChoiceCode = TGT_SLT.TargetSegmentChoiceCode
			AND SCHOP.ChoiceOptionSource = TGT_SLT.LinkTarget
	WHERE SCHOP.ProjectId = @ProjectId
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
        
SELECT               
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

SELECT @HasSelectedChoiceOption = COUNT(1)              
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
 SELECT @HasProjectSegmentRequirementTag = COUNT(1)             
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
SELECT @LoopedHasProjectSegmentStatus = COUNT(1)
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
SELECT @LoopedHasSelectedChoiceOption = COUNT(1)
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
PRINT N'Altering [dbo].[usp_GetSegments]...';


GO
ALTER PROCEDURE [dbo].[usp_GetSegments]                  
@ProjectId INT NULL, @SectionId INT NULL, @CustomerId INT NULL, @UserId INT NULL, @CatalogueType NVARCHAR (50) NULL='FS'                            
AS                            
BEGIN                  
DECLARE @PProjectId INT = @ProjectId;                  
DECLARE @PSectionId INT = @SectionId;                  
DECLARE @PCustomerId INT = @CustomerId;                  
DECLARE @PUserId INT = @UserId;                  
DECLARE @PCatalogueType NVARCHAR (50) = @CatalogueType;                  
                  
SET NOCOUNT ON;                  
                   
--CatalogueTypeTbl table                  
DECLARE @CatalogueTypeTbl TABLE (                  
 TagType NVARCHAR(MAX)                  
);                  
                  
IF @PCatalogueType IS NOT NULL AND @PCatalogueType != 'FS'                  
BEGIN                  
INSERT INTO @CatalogueTypeTbl (TagType)                  
 SELECT                  
  *                  
 FROM dbo.fn_SplitString(@PCatalogueType, ',');                  
                  
IF EXISTS (SELECT                  
   *                  
  FROM @CatalogueTypeTbl                  
  WHERE TagType = 'OL')                  
BEGIN                  
INSERT INTO @CatalogueTypeTbl                  
 VALUES ('UO')                  
END                  
IF EXISTS (SELECT                  
   *                  
  FROM @CatalogueTypeTbl                  
  WHERE TagType = 'SF')                  
BEGIN                  
INSERT INTO @CatalogueTypeTbl                  
 VALUES ('US')                  
END                  
END                  
                  
--Set mSectionId                    
DECLARE @MasterSectionId AS INT;                  
SET @MasterSectionId = (SELECT TOP 1                  
  mSectionId                  
 FROM ProjectSection WITH (NOLOCK)                  
 WHERE SectionId = @PSectionId                  
 AND ProjectId = @PProjectId                  
 AND CustomerId = @PCustomerId);                  
                           
--FIND TEMPLATE ID FROM                     
DECLARE @ProjectTemplateId AS INT = ( SELECT TOP 1                  
  ISNULL(TemplateId, 1)                  
 FROM Project WITH (NOLOCK)                  
 WHERE ProjectId = @PProjectId                  
 AND CustomerId = @PCustomerId);                  
                  
DECLARE @SectionTemplateId AS INT = ( SELECT TOP 1                  
  TemplateId                  
 FROM ProjectSection WITH (NOLOCK)                  
 WHERE SectionId = @PSectionId);                  
                  
DECLARE @DocumentTemplateId INT = 0;                  
                  
IF (@SectionTemplateId IS NOT NULL                  
 AND @SectionTemplateId > 0)                  
BEGIN                  
SET @DocumentTemplateId = @SectionTemplateId;                  
END                    
ELSE                    
BEGIN                  
SET @DocumentTemplateId = @ProjectTemplateId;                  
END                  
                    
DECLARE @MasterDataTypeId INT;                  
SET @MasterDataTypeId = (SELECT TOP 1                  
  MasterDataTypeId                  
 FROM Project WITH (NOLOCK)                  
 WHERE ProjectId = @PProjectId                  
 AND CustomerId = @PCustomerId);                  
                  
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
                  
DROP TABLE IF EXISTS #tmp_ProjectSegmentStatus;                  
SELECT                  
 PSS.ProjectId                  
   ,PSS.CustomerId                  
   ,PSS.SegmentStatusId                  
   ,PSS.SectionId                  
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
   INTO #tmp_ProjectSegmentStatus                  
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
OR STT.TagType IN (SELECT                  
  *                  
 FROM @CatalogueTypeTbl)                  
)                  
                  
SELECT                  
 *                  
FROM #tmp_ProjectSegmentStatus                  
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
 FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                  
 INNER JOIN ProjectSegment AS PSG WITH (NOLOCK)                  
  ON PSST.SegmentId = PSG.SegmentId                  
  AND PSST.SectionId = PSG.SectionId                  
  AND PSST.ProjectId = PSG.ProjectId                  
  AND PSST.CustomerId = PSG.CustomerId                  
 WHERE PSST.ProjectId = @PProjectId                  
 AND PSST.CustomerId = @PCustomerId                  
 AND PSST.SectionId = @PSectionId                  
 AND ISNULL(PSST.IsDeleted, 0) = 0                  
 UNION ALL                  
 SELECT                  
  MSG.SegmentId                  
    ,PST.SegmentStatusId                  
    ,PST.SectionId                  
    ,CASE                  
   WHEN PST.ParentSegmentStatusId = 0 AND                  
    PST.SequenceNumber = 0 THEN PS.Description                  
   ELSE ISNULL(MSG.SegmentDescription, '')                  
  END AS SegmentDescription                  
    ,MSG.SegmentSource                  
    ,MSG.SegmentCode                  
 FROM #tmp_ProjectSegmentStatus AS PST WITH (NOLOCK)                  
 INNER JOIN ProjectSection AS PS WITH (NOLOCK)                  
  ON PST.SectionId = PS.SectionId                  
 INNER JOIN SLCMaster.dbo.Segment AS MSG WITH (NOLOCK)                  
  ON PST.mSegmentId = MSG.SegmentId                  
 WHERE PST.ProjectId = @PProjectId                  
 AND PST.CustomerId = @PCustomerId                  
 AND PST.SectionId = @PSectionId                  
 AND ISNULL(PST.IsDeleted, 0) = 0) AS X                  
                  
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
                  
SELECT                  
 TemplateStyleId                  
   ,TemplateId                  
   ,StyleId                  
   ,Level                  
FROM TemplateStyle WITH (NOLOCK)                  
WHERE TemplateId = @DocumentTemplateId;                  
                  
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
   ,CAST(TST.Level AS INT) AS Level                  
FROM Style AS ST WITH (NOLOCK)                  
INNER JOIN TemplateStyle AS TST WITH (NOLOCK)                  
 ON ST.StyleId = TST.StyleId                  
WHERE TST.TemplateId = @DocumentTemplateId;                  
                  
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
   ,SCHOP.OptionJson INTO #SelectedChoiceOptionTemp                  
FROM SelectedChoiceOption SCHOP WITH (NOLOCK)                  
WHERE SCHOP.SectionId = @PSectionId           
AND SCHOP.ProjectId = @PProjectId                      
AND ISNULL(SCHOP.IsDeleted, 0) = 0            
AND SCHOP.CustomerId = @PCustomerId                  
                
-- Start - Workaround for Bug 34851: Regression: Choices: Duplicate choice options are being displayed in the choice option
	DECLARE @DUPLICATE TABLE
	(
		SegmentChoiceCode INT, 
		ChoiceOptionCode INT, 
		CNT INT
	)
	INSERT INTO @DUPLICATE
	Select SegmentChoiceCode,ChoiceOptionCode,COUNT(1) as CNT from #SelectedChoiceOptionTemp  
	WHERE  ChoiceOptionSource='U'
	GROUP BY SegmentChoiceCode,ChoiceOptionCode
	HAVING COUNT(1)>1

	DELETE t
	from #SelectedChoiceOptionTemp t INNER JOIN @DUPLICATE d
	ON t.SegmentChoiceCode=d.SegmentChoiceCode AND t.ChoiceOptionCode=d.ChoiceOptionCode
	WHERE t.IsSelected=0 and t.ChoiceOptionSource='U'
-- End - Workaround for Bug 34851: Regression: Choices: Duplicate choice options are being displayed in the choice option
                  
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
FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)                  
INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK)                  
 ON PSST.mSegmentId = MCH.SegmentId                  
INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)                  
 ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId                  
INNER JOIN #SelectedChoiceOptionTemp PSCHOP WITH (NOLOCK)                  
 ON MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode            
 AND MCH.SegmentChoiceCode= PSCHOP.SegmentChoiceCode               
  AND PSCHOP.ChoiceOptionSource = 'M'                  
  AND PSCHOP.ProjectId = @PProjectId                  
  AND PSCHOP.SectionId = @PSectionId                  
WHERE PSST.ProjectId = @PProjectId                  
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
FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)                  
INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)                  
 ON PSST.SegmentId = PCH.SegmentId                  
  AND ISNULL(PCH.IsDeleted, 0) = 0                  
INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)                  
 ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId                  
  AND ISNULL(PCHOP.IsDeleted, 0) = 0                  
INNER JOIN #SelectedChoiceOptionTemp PSCHOP WITH (NOLOCK)                  
 ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode                  
  AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode                  
  AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource                  
  AND PSCHOP.ProjectId = @PProjectId                  
  AND PSCHOP.SectionId = @PSectionId                  
  AND PSCHOP.ChoiceOptionSource = 'U'                  
WHERE PSST.ProjectId = @PProjectId                  
AND PSST.SectionId = @PSectionId                  
AND PSST.CustomerId = @PCustomerId                  
AND ISNULL(PSST.IsDeleted, 0) = 0                  
                  
SELECT                  
 GlobalTermId                     ,COALESCE(mGlobalTermId, 0) AS mGlobalTermId                  
 --  ProjectId,                            
 -- CustomerId,                           
   ,[Name]                    
   ,ISNULL([Value], '') AS [Value]                  
   ,ISNULL(OldValue, '') AS OldValue                
   ,CreatedDate                  
   ,CreatedBy                  
   ,COALESCE(ModifiedDate,NULL)AS ModifiedDate              
   ,COALESCE(ModifiedBy, 0) AS ModifiedBy                  
   ,GlobalTermSource                  
   ,GlobalTermCode                  
   ,COALESCE(UserGlobalTermId, 0) AS UserGlobalTermId                  
   ,ISNULL(GlobalTermFieldTypeId, 1) AS GlobalTermFieldTypeId                  
FROM ProjectGlobalTerm WITH (NOLOCK)                  
WHERE ProjectId = @PProjectId                  
AND CustomerId = @PCustomerId                  
AND (IsDeleted = 0                  
OR IsDeleted IS NULL)                  
ORDER BY Name                  
                  
DROP TABLE IF EXISTS #Sections;                  
                  
--ADD UnDeleted from ProjectSection                    
SELECT                  
 S.Description                  
   ,S.Author                  
   ,S.SectionCode                  
   ,S.SourceTag                  
   ,PS.SourceTagFormat                  
   ,S.mSectionId                  
   ,S.SectionId                  
   ,S.IsDeleted INTO #Sections                  
FROM ProjectSection AS S WITH (NOLOCK)                  
INNER JOIN ProjectSummary PS WITH (NOLOCK)                  
 ON S.ProjectId = PS.ProjectId                  
  AND S.CustomerId = PS.CustomerId                  
WHERE S.ProjectId = @PProjectId                  
AND S.CustomerId = @PCustomerId                  
AND S.IsDeleted = 0                  
                  
--ADD Deleted from ProjectSection WIH UnInserted                    
INSERT INTO #Sections                  
 SELECT                  
  S.Description                  
    ,S.Author                  
    ,S.SectionCode                  
    ,S.SourceTag                  
    ,PS.SourceTagFormat                  
    ,S.mSectionId                  
    ,S.SectionId                  
    ,S.IsDeleted                  
 FROM ProjectSection AS S WITH (NOLOCK)                  
 INNER JOIN ProjectSummary PS WITH (NOLOCK)                  
  ON S.ProjectId = PS.ProjectId                  
   AND S.CustomerId = PS.CustomerId              
 LEFT JOIN #Sections TMP WITH (NOLOCK)                  
  ON S.SectionCode = TMP.SectionCode                  
 WHERE S.ProjectId = @PProjectId                  
 AND S.CustomerId = @PCustomerId                  
 AND S.IsDeleted = 1                  
 AND TMP.SectionId IS NULL                  
                  
--ADD EXTRA from SLCMaster..Section WIH UnInserted                    
INSERT INTO #Sections                  
 SELECT                  
  MS.Description                  
    ,MS.Author                  
    ,MS.SectionCode                  
    ,MS.SourceTag                  
    ,P.SourceTagFormat                  
    ,MS.SectionId AS mSectionId                  
    ,0 AS SectionId                  
    ,MS.IsDeleted                  
 FROM SLCMaster..Section MS WITH (NOLOCK)                  
 INNER JOIN ProjectSummary P WITH (NOLOCK)                  
  ON P.ProjectId = @PProjectId                  
   AND P.CustomerId = @PCustomerId                  
 LEFT JOIN #Sections TMP WITH (NOLOCK)                  
  ON MS.SectionCode = TMP.SectionCode                  
 WHERE MS.MasterDataTypeId = @MasterDataTypeId                  
 AND MS.IsLastLevel = 1                  
 AND TMP.SectionId IS NULL;                  
                  
SELECT                  
 *                  
FROM #Sections;                  
                  
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
INNER JOIN #tmp_ProjectSegmentStatus Temp WITH (NOLOCK)                  
 ON PSRT.SegmentStatusId = Temp.SegmentStatusId                  
WHERE PSRT.ProjectId = @PProjectId                  
AND PSRT.SectionId = @PSectionId                  
AND PSRT.CustomerId = @PCustomerId                
AND ISNULL(PSRT.IsDeleted,0)=0            
                  
--FETCH REQUIRED IMAGES FROM DB                      
SELECT                  
  PSI.SegmentImageId  
 ,IMG.ImageId  
 ,IMG.ImagePath  
 ,ISNULL(PSI.ImageStyle, '') AS ImageStyle
FROM ProjectSegmentImage PSI WITH (NOLOCK)  
INNER JOIN ProjectImage IMG WITH (NOLOCK)  
 ON PSI.ImageId = IMG.ImageId  
WHERE PSI.SectionId = @PSectionId  
AND IMG.LuImageSourceTypeId = 1  
                  
--FETCH HYPERLINKS FROM PROJECT DB                    
SELECT                  
 HLNK.HyperLinkId                  
   ,HLNK.LinkTarget                  
   ,HLNK.LinkText                  
   ,'U' AS [Source]                  
FROM ProjectHyperLink HLNK WITH (NOLOCK)                  
WHERE HLNK.SectionId = @PSectionId
AND HLNK.ProjectId = @PProjectId
                  
--FETCH SEGMENT USER TAGS LIST                    
SELECT                  
 PSUT.SegmentUserTagId                  
   ,PSUT.SegmentStatusId                  
   ,PSUT.UserTagId                  
   ,PUT.TagType                  
   ,PUT.Description AS TagName                  
FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)                  
INNER JOIN ProjectUserTag PUT WITH (NOLOCK)                  
 ON PSUT.UserTagId = PUT.UserTagId                  
WHERE PSUT.ProjectId = @PProjectId                  
AND PSUT.CustomerId = @PCustomerId                  
AND PSUT.SectionId = @PSectionId                  
                  
SELECT    
ProjectId                
,IsIncludeRsInSection    
,IsIncludeReInSection    
,ISNULL(IsPrintReferenceEditionDate, 0) AS IsPrintReferenceEditionDate                   
FROM ProjectSummary WITH (NOLOCK)              
WHERE ProjectId = @PProjectId                  
END
GO
PRINT N'Altering [dbo].[CopyProjectJob]...';


GO
ALTER PROCEDURE [dbo].[CopyProjectJob]
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
	END


END
GO
PRINT N'Creating [dbo].[usp_GetSegmentMappingData]...';


GO
CREATE PROCEDURE usp_GetSegmentMappingData
(  
 @ProjectId INT,  
 @SectionId INT,   
 @CustomerId INT  
)  
AS  
BEGIN  
  
 EXEC usp_GetProjectSections @ProjectId, @SectionId, @CustomerId;
 EXEC usp_GetProjectSectionUserTag @ProjectId, @CustomerId, @SectionId;
 EXEC usp_GetProjectSectionHyperLinks @ProjectId, @SectionId;
 --EXEC usp_GetProjectSegmentImage @SectionId;
 EXEC usp_GetProjectTemplateStyle @ProjectId, @SectionId, @CustomerId;
 EXEC usp_GetProjectGlobalTerm @ProjectId, @CustomerId;
 EXEC usp_GetProjectSummary @ProjectId;
 EXEC usp_GetTrackChangesModeInfo @ProjectId, @SectionId;
  
END
GO
PRINT N'Refreshing [dbo].[udf_GetGTUsedInChoice]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[udf_GetGTUsedInChoice]';


GO
PRINT N'Refreshing [dbo].[usp_CheckCustomerGlobalSetting]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CheckCustomerGlobalSetting]';


GO
PRINT N'Refreshing [dbo].[usp_CreateCustomerGlobalSetting]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateCustomerGlobalSetting]';


GO
PRINT N'Refreshing [dbo].[usp_CreateOrUpdateCustomerGlobalSetting]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateOrUpdateCustomerGlobalSetting]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSegmentsForImportedSectionPOC]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSegmentsForImportedSectionPOC]';


GO
PRINT N'Refreshing [dbo].[usp_getCustomerGlobalSetting]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getCustomerGlobalSetting]';


GO
PRINT N'Refreshing [dbo].[usp_getUserIncludeGlobalSetting]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getUserIncludeGlobalSetting]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateCustomerGlobalSetting]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateCustomerGlobalSetting]';


GO
PRINT N'Refreshing [dbo].[usp_CreateImportProjectRequest]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateImportProjectRequest]';


GO
PRINT N'Refreshing [dbo].[usp_GetImportRequest]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetImportRequest]';


GO
PRINT N'Refreshing [dbo].[usp_LogImportSectionRequest]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_LogImportSectionRequest]';


GO
PRINT N'Refreshing [dbo].[usp_MaintainImportProjectProgress]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_MaintainImportProjectProgress]';


GO
PRINT N'Refreshing [dbo].[usp_RemoveImportSectionRequest]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_RemoveImportSectionRequest]';


GO
PRINT N'Refreshing [dbo].[usp_GetCoverSheetDetails]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetCoverSheetDetails]';


GO
PRINT N'Refreshing [dbo].[usp_GetLookups]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetLookups]';


GO
PRINT N'Refreshing [dbo].[usp_GetTagsReportDataOfHeaderFooter]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetTagsReportDataOfHeaderFooter]';


GO
PRINT N'Refreshing [dbo].[usp_CheckChoiceOptionSource]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CheckChoiceOptionSource]';


GO
PRINT N'Refreshing [dbo].[usp_CreateUserChoice]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateUserChoice]';


GO
PRINT N'Refreshing [dbo].[usp_deletedMasterSectionsFromProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_deletedMasterSectionsFromProject]';


GO
PRINT N'Refreshing [dbo].[usp_DeleteProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DeleteProject]';


GO
PRINT N'Refreshing [dbo].[usp_deleteUserModifications]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_deleteUserModifications]';


GO
PRINT N'Refreshing [dbo].[usp_deleteUserSegment]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_deleteUserSegment]';


GO
PRINT N'Refreshing [dbo].[usp_deleteUserSegment_SoftDelete]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_deleteUserSegment_SoftDelete]';


GO
PRINT N'Refreshing [dbo].[usp_getDeletedMasterSections]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getDeletedMasterSections]';


GO
PRINT N'Refreshing [dbo].[usp_GetSectionIdChoiceReferences]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSectionIdChoiceReferences]';


GO
PRINT N'Refreshing [dbo].[usp_GetSectionReferencesCount]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSectionReferencesCount]';


GO
PRINT N'Refreshing [dbo].[usp_GetSourceTargetLinksOfSegmentOrChoice]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSourceTargetLinksOfSegmentOrChoice]';


GO
PRINT N'Refreshing [dbo].[usp_RemoveIsDeletedRecords]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_RemoveIsDeletedRecords]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateSegmentsGTMapping]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateSegmentsGTMapping]';


GO
PRINT N'Refreshing [dbo].[usp_MapSectionToProject_Work]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_MapSectionToProject_Work]';


GO
PRINT N'Refreshing [dbo].[usp_ApplyMasterUpdateToProjects]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ApplyMasterUpdateToProjects]';


GO
PRINT N'Refreshing [dbo].[usp_GetSections]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSections]';


GO
PRINT N'Refreshing [dbo].[usp_deleteUserSegments]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_deleteUserSegments]';


GO
PRINT N'Refreshing [dbo].[usp_deleteUserSegments_SoftDelete]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_deleteUserSegments_SoftDelete]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateSegmentsGTAndRSMapping]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateSegmentsGTAndRSMapping]';


GO
PRINT N'Refreshing [dbo].[usp_GlobalTermAutoSaveDetails]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GlobalTermAutoSaveDetails]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateHeaderFooterGlobalTermUsage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateHeaderFooterGlobalTermUsage]';


GO
PRINT N'Refreshing [dbo].[spb_GetGlobalTerms]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[spb_GetGlobalTerms]';


GO
PRINT N'Refreshing [dbo].[usp_DeleteProjectGlobalTerms]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DeleteProjectGlobalTerms]';


GO
PRINT N'Refreshing [dbo].[usp_GetGlobalTerms]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetGlobalTerms]';


GO
PRINT N'Refreshing [dbo].[usp_GetGlobalTermsCount]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetGlobalTermsCount]';


GO
PRINT N'Refreshing [dbo].[usp_HeaderGlobalTermUsage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_HeaderGlobalTermUsage]';


GO
PRINT N'Refreshing [dbo].[usp_MapGlobalTermToProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_MapGlobalTermToProject]';


GO
PRINT N'Refreshing [dbo].[usp_ModifyGlobalTermAsChoice]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ModifyGlobalTermAsChoice]';


GO
PRINT N'Refreshing [dbo].[usp_SaveHeaderFooterDetails]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SaveHeaderFooterDetails]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateProjectGlobalTerm]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateProjectGlobalTerm]';


GO
PRINT N'Refreshing [dbo].[usp_GetNotesDetails]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetNotesDetails]';


GO
PRINT N'Refreshing [dbo].[usp_GetSegmentImages]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSegmentImages]';


GO
PRINT N'Refreshing [dbo].[usp_InsertImportSectionSegmentImages]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_InsertImportSectionSegmentImages]';


GO
PRINT N'Refreshing [dbo].[usp_SaveImage]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SaveImage]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSpecDataSections]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSpecDataSections]';


GO
PRINT N'Refreshing [dbo].[usp_GetArchievedProjects]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetArchievedProjects]';


GO
PRINT N'Refreshing [dbo].[usp_GetDivisionsAndSectionsForPrint]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetDivisionsAndSectionsForPrint]';


GO
PRINT N'Refreshing [dbo].[usp_getProjectsByID]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getProjectsByID]';


GO
PRINT N'Refreshing [dbo].[usp_GetSectionsdemo]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSectionsdemo]';


GO
PRINT N'Refreshing [dbo].[usp_GetSpecViewMode]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSpecViewMode]';


GO
PRINT N'Refreshing [dbo].[usp_GetSubmittalsReport]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSubmittalsReport]';


GO
PRINT N'Refreshing [dbo].[usp_InsertNewProjectSummary]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_InsertNewProjectSummary]';


GO
PRINT N'Refreshing [dbo].[usp_IsProjectOwner]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_IsProjectOwner]';


GO
PRINT N'Refreshing [dbo].[usp_MapSectionToProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_MapSectionToProject]';


GO
PRINT N'Refreshing [dbo].[usp_SetProjectView]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SetProjectView]';


GO
PRINT N'Refreshing [dbo].[usp_SpecDataMapSectionToProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SpecDataMapSectionToProject]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSpecDataSegments]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSpecDataSegments]';


GO
PRINT N'Refreshing [dbo].[usp_GetSegmentLinkDetailsForJob]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSegmentLinkDetailsForJob]';


GO
PRINT N'Refreshing [dbo].[usp_GetSegments_Work]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSegments_Work]';


GO
PRINT N'Refreshing [dbo].[usp_getRelatedRequirement]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getRelatedRequirement]';


GO
PRINT N'Refreshing [dbo].[usp_getSectionIncludes]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getSectionIncludes]';


GO
PRINT N'Refreshing [dbo].[usp_ApplyNewParagraphsUpdates]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ApplyNewParagraphsUpdates]';


GO
PRINT N'Refreshing [dbo].[usp_SpecDataCreateSegments]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SpecDataCreateSegments]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateSectionsIdName]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateSectionsIdName]';


GO
PRINT N'Refreshing [dbo].[usp_GetAllSections]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetAllSections]';
