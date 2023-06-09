 

CREATE  PROCEDURE [dbo].[usp_SpecDataMapSectionToProject] 
(  
@newProjectID INT NULL,             
@newCustomerID INT NULL,             
@newUserID INT NULL,             
@isCopied BIT NULL,             
@copiedProjectID INT NULL=NULL,             
@copiedCustomerID INT NULL=NULL,             
@copiedUserID INT NULL=NULL,            
@MasterDataTypeId INT NULL=NULL,      
@customerName VARCHAR(200)='',      
@userName VARCHAR(200)='' 
)            
AS              
BEGIN
          
          
DECLARE @Canada_Section_CutOffDate DATETIME2(7) = '20190420';
          
          
DECLARE @PnewProjectID INT = @newProjectID;
          
DECLARE @PnewCustomerID INT = @newCustomerID;
          
DECLARE @PnewUserID INT = @newUserID;
          
DECLARE @PisCopied BIT = @isCopied;
          
DECLARE @PcopiedProjectID INT = @copiedProjectID;
          
DECLARE @PcopiedCustomerID INT = @copiedCustomerID;
          
DECLARE @PcopiedUserID INT = @copiedUserID;
          
DECLARE @PMasterDataTypeId  INT = @MasterDataTypeId;
          
DECLARE @RequestId INT = 0;
        
DECLARE @PCustomerName  NVARCHAR(200)=@CustomerName;
      
DECLARE @PUserName NVARCHAR(200)=@userName;
      
DECLARE @ProjectSection Table(
     mSectionId INT
   , ParentSectionId INT
   , mParentSectionId INT
   ,ProjectId   INT
   ,CustomerId INT
   , UserId INT
   ,DivisionId INT
   ,Description NVARCHAR(MAX)
   ,LevelId INT
   ,IsLastLevel BIT
   ,SourceTag NVARCHAR(100)
   ,Author NVARCHAR(50)
   , CreatedBy INT
   ,CreateDate datetime2
   ,ModifiedBy INT
   ,ModifiedDate datetime2
   ,SectionCode INT
   ,IsDeleted bit
   ,TemplateId INT
   ,FormatTypeId INT
   ,DivisionCode  NVARCHAR(MAX)
   ,SpecViewModeId INT
   );

   DECLARE @PSections Table(
     mSectionId INT
   , SectionId INT)

 
DECLARE @SpecViewModeId INT = ( SELECT
		SpecViewModeId
	FROM ProjectSummary WITH (NOLOCK)
	WHERE ProjectId = @PnewProjectID
	AND CustomerId = @PnewCustomerID);
SET @SpecViewModeId =
CASE
	WHEN @SpecViewModeId IS NULL THEN 1
	ELSE @SpecViewModeId
END;

INSERT INTO @ProjectSection (mSectionId
, ParentSectionId
, mParentSectionId
, ProjectId
, CustomerId
, UserId
, DivisionId
, Description
, LevelId
, IsLastLevel
, SourceTag
, Author
, CreatedBy
, CreateDate
, ModifiedBy
, ModifiedDate
, SectionCode
, IsDeleted
, TemplateId
, FormatTypeId
, DivisionCode
, SpecViewModeId)

	SELECT
		SectionId AS mSectionId
	   ,0 AS ParentSectionId
	   ,s.ParentSectionId AS mParentSectionId
	   ,@PnewProjectID AS [ProjectId]
	   ,@PnewCustomerID AS [CustomerId]
	   ,@PnewUserID AS [UserId]
	   ,DivisionId
	   ,[Description]
	   ,LevelId
	   ,IsLastLevel
	   ,SourceTag
	   ,Author
	   ,@PnewUserID AS CreatedBy
	   ,GETUTCDATE() AS CreateDate
	   ,@PnewUserID AS ModifiedBy
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
	   ,@SpecViewModeId AS SpecViewModeId
	FROM [SLCMaster].[dbo].[Section] AS [S] WITH (NOLOCK)
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

INSERT INTO [dbo].[ProjectSection] ([mSectionId], [ParentSectionId], [ProjectId], [CustomerId], [UserId], [DivisionId], [Description],
[LevelId], [IsLastLevel], [SourceTag], [Author], [CreatedBy], [CreateDate], [ModifiedBy], [ModifiedDate], [SectionCode], [IsDeleted],
[TemplateId],
[FormatTypeId], [DivisionCode], [SpecViewModeId])
	SELECT
		ps.mSectionId
	   ,ps.ParentSectionId
	   ,@PnewProjectID AS [ProjectId]
	   ,@PnewCustomerID AS [CustomerId]
	   ,@PnewUserID AS [UserId]
	   ,ps.DivisionId
	   ,ps.[Description]
	   ,ps.LevelId
	   ,ps.IsLastLevel
	   ,ps.SourceTag
	   ,ps.Author
	   ,@PnewUserID AS CreatedBy
	   ,GETUTCDATE() AS CreateDate
	   ,@PnewUserID AS ModifiedBy
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
	FROM @ProjectSection AS ps;
	 

	 insert into @PSections(SectionId,mSectionId)
	SELECT 
	 PPS.SectionId
	, PPS.mSectionId
	FROM [dbo].[ProjectSection] AS PPS WITH (NOLOCK)
	WHERE PPS.[ProjectId] = @PnewProjectID
	AND PPS.[CustomerId] = @PnewCustomerID;

UPDATE CPS
SET CPS.ParentSectionId = PPS.SectionId
FROM [dbo].[ProjectSection] AS CPS WITH (NOLOCK)
INNER JOIN @ProjectSection AS CMS
	ON CPS.mSectionId = CMS.mSectionId
	AND CPS.ProjectId = CMS.ProjectId
	AND CPS.CustomerId = CMS.CustomerId
INNER JOIN @PSections PPS on 
CMS.mParentSectionId=PPS.mSectionId
WHERE CPS.[ProjectId] = @PnewProjectID
AND CPS.[CustomerId] = @PnewCustomerID


END
GO