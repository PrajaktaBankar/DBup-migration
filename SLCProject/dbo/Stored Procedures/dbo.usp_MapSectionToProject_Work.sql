CREATE PROCEDURE [dbo].[usp_MapSectionToProject_Work]        
@newProjectID INT NULL,       
@newCustomerID INT NULL,       
@newUserID INT NULL,       
@isCopied BIT NULL,       
@copiedProjectID INT NULL=NULL,       
@copiedCustomerID INT NULL=NULL,       
@copiedUserID INT NULL=NULL,      
@MasterDataTypeId INT NULL=NULL        
AS  
        
BEGIN
  
  
IF (@isCopied = 1)  
BEGIN
EXEC usp_CopyProject @copiedProjectID
					,@newProjectID
					,@newCustomerID
					,@newUserID;

END
ELSE
BEGIN

DECLARE @SpecViewModeId INT = (SELECT
		SpecViewModeId
	FROM ProjectSummary WITH (NOLOCK)
	WHERE ProjectId = @newProjectID
	AND CustomerId = @newCustomerID);
SET @SpecViewModeId =
CASE
	WHEN @SpecViewModeId IS NULL THEN 1
	ELSE @SpecViewModeId
END;

SELECT
	SectionId AS mSectionId
   ,0 AS ParentSectionId
   ,s.ParentSectionId AS mParentSectionId
   ,@newProjectID AS [ProjectId]
   ,@newCustomerID AS [CustomerId]
   ,@newUserID AS [UserId]
   ,DivisionId
   ,[Description]
   ,LevelId
   ,IsLastLevel
   ,SourceTag
   ,Author
   ,@newUserID AS CreatedBy
   ,GETUTCDATE() AS CreateDate
   ,@newUserID AS ModifiedBy
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
FROM [SLCMaster].[dbo].[Section] AS [S] WITH (NOLOCK)
WHERE S.MasterDataTypeId = @MasterDataTypeId;


INSERT INTO [ProjectSection] ([mSectionId], [ParentSectionId], [ProjectId], [CustomerId], [UserId], [DivisionId], [Description],
[LevelId], [IsLastLevel], [SourceTag], [Author], [CreatedBy], [CreateDate], [ModifiedBy], [ModifiedDate], [SectionCode], [IsDeleted],
[TemplateId],
[FormatTypeId], [DivisionCode], [SpecViewModeId])
	SELECT
		ps.mSectionId
	   ,ps.ParentSectionId
	   ,@newProjectID AS [ProjectId]
	   ,@newCustomerID AS [CustomerId]
	   ,@newUserID AS [UserId]
	   ,ps.DivisionId
	   ,ps.[Description]
	   ,ps.LevelId
	   ,ps.IsLastLevel
	   ,ps.SourceTag
	   ,ps.Author
	   ,@newUserID AS CreatedBy
	   ,GETUTCDATE() AS CreateDate
	   ,@newUserID AS ModifiedBy
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



UPDATE CPS
SET CPS.ParentSectionId = PPS.SectionId
FROM [ProjectSection] AS CPS WITH (NOLOCK)
INNER JOIN #ProjectSection AS CMS WITH (NOLOCK)
	ON CPS.mSectionId = CMS.mSectionId
INNER JOIN [ProjectSection] AS PPS WITH (NOLOCK)
	ON PPS.mSectionId = CMS.mParentSectionId
	AND CPS.ProjectId = PPS.ProjectId
	AND CPS.CustomerId = PPS.CustomerId
WHERE CPS.[ProjectId] = @newProjectID
AND CPS.[CustomerId] = @newCustomerID
AND PPS.[ProjectId] = @newProjectID
AND PPS.[CustomerId] = @newCustomerID;

END

END 
GO
