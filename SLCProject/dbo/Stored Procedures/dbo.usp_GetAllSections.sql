CREATE PROCEDURE [dbo].[usp_GetAllSections]                
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
 DECLARE @AlternateDocument INT = 8 ;              
 DECLARE @DocumentPath NVARCHAR(200) ='' ;   
                   
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
    ISNULL(PS.SourceTag,'')AS SourceTag,                  
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
  END) AS IsUserSection,                 
  ISNULL(PS.IsHidden,0) as IsHidden,                    
  ISNULL(PS.SortOrder,0) AS SortOrder,        
  IsTrackChanges,      
  ISNULL(SectionSource,1)  as SectionSource,  
  @DocumentPath As DocumentPath  
 INTO #tempProjectSection  
 FROM                
    ProjectSection PS WITH (NOLOCK)                  
    LEFT JOIN SLCMaster..Section MS WITH (NOLOCK)   
  ON PS.mSectionId = MS.SectionId                    
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
 ORDER BY PS.SortOrder ASC, PS.Author ASC;                  
  
 --Update Document Path which is AlterNate Document  
  UPDATE t SET t.DocumentPath = SD.DocumentPath  
   FROM #tempProjectSection t  
   INNER JOIN SectionDocument SD WITH(NOLOCK)  
   ON SD.SectionId = t.SectionId  
   Where t.SectionSource = @AlternateDocument  
  
   Select * From #tempProjectSection PS  
   ORDER BY PS.SortOrder ASC, PS.Author ASC;    
                  
END 