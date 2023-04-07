CREATE PROC [dbo].[usp_ImportToolChoicesInsert]
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
         TempChoiceId BIGINT,
		 SegmentChoiceId BIGINT,
		 SegmentChoiceCode BIGINT,
         SegmentId BIGINT,
         SegmentStatusId BIGINT,
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
		 ChoiceOptionCode BIGINT,
		 SegmentChoiceId BIGINT, 
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
	TempChoiceId BIGINT '$.TempChoiceId',
	SegmentChoiceId BIGINT '$.SegmentChoiceId',
	SegmentChoiceCode BIGINT '$.SegmentChoiceCode',
	SegmentId BIGINT '$.SegmentId',
	SegmentStatusId BIGINT '$.SegmentStatusId'	,
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
	TempOptionId BIGINT '$.TempOptionId',
	ChoiceOptionId BIGINT '$.ChoiceOptionId',
	ChoiceOptionCode BIGINT '$.ChoiceOptionCode',
	SegmentChoiceId BIGINT '$.SegmentChoiceId',
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


