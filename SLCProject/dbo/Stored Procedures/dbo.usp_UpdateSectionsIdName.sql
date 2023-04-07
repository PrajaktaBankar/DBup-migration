
CREATE PROCEDURE [dbo].[usp_UpdateSectionsIdName]                       
@ProjectId INT,                          
@CustomerId INT,                           
@UserId INT,                           
@SectionId INT,                          
@ParentSectionId INT,                          
@SourceTag VARCHAR (18) ,                          
@Description NVARCHAR (MAX),                          
@Author NVARCHAR(50)                          
AS                              
BEGIN                            
DECLARE @PProjectId INT = @ProjectId;                            
DECLARE @PCustomerId INT = @CustomerId;                            
DECLARE @PUserId INT = @UserId;                            
DECLARE @PSectionId INT = @SectionId;                            
DECLARE @PParentSectionId INT = @ParentSectionId;                          
DECLARE @PSourceTag VARCHAR (18) = @SourceTag;                            
DECLARE @PDescription NVARCHAR (MAX) = @Description;                            
DECLARE @PAuthor NVARCHAR(50) = @Author;               
DECLARE @BSDMasterAdminDivId int=38  
DECLARE @CanadaMasterAdminDivId int=3000037                            
--DECLARE VARIABLES                            
--DECLARE @ParentSectionId INT = 0;                            
DECLARE @IsSectionOpened BIT = 0;                            
DECLARE @IsUserVersionCreated BIT = 0;                            
DECLARE @IsSuccess BIT = 1;                            
DECLARE @ErrorMessage NVARCHAR(50) = '';                            
                            
--CHECK SECTION OPENED OR NOT                            
IF EXISTS (SELECT TOP 1                            
   PSST.SegmentStatusId                            
  FROM ProjectSegmentStatus PSST WITH (NOLOCK)                            
  WHERE PSST.SectionId = @PSectionId  
  AND PSST.ProjectId = @PProjectId  
  AND PSST.CustomerId = @PCustomerId                            
  AND PSST.SequenceNumber = 0                            
  AND PSST.IndentLevel = 0)                            
BEGIN                            
SET @IsSectionOpened = 1;                            
END                            
                            
--CHECK USER VERSION CREATED                            
IF EXISTS (SELECT TOP 1                            
  PSG.SegmentId                            
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)                            
 INNER JOIN ProjectSegment PSG WITH (NOLOCK)                            
  ON PSST.SegmentId = PSG.SegmentId                            
 WHERE PSST.ProjectId = @PProjectId AND PSST.SectionId = @PSectionId                            
 AND PSST.SequenceNumber = 0                            
 AND PSST.IndentLevel = 0)                            
BEGIN                            
SET @IsUserVersionCreated = 1;                            
END                            
                            
--PERFORM VALIDATIONS                            
IF EXISTS (SELECT                            
  TOP 1 1                            
 FROM ProjectSection WITH (NOLOCK)                            
 WHERE ProjectId = @PProjectId                            
 AND CustomerId = @PCustomerId                            
 AND (SourceTag = TRIM(@PSourceTag)                            
 AND Description = TRIM(@PDescription))                            
 AND Author = TRIM(@PAuthor)                            
 AND SectionId != @PSectionId                            
 AND IsLastLevel = 1                            
 AND IsDeleted != 1)                            
BEGIN                            
SET @IsSuccess = 0;                            
SET @ErrorMessage = 'Section already exists';                            
END                            
                            
ELSE IF @ParentSectionId IS NULL OR @ParentSectionId <= 0                            
BEGIN                            
SET @IsSuccess = 0;                            
SET @ErrorMessage = 'Section id is invalid.';                            
END                            
                            
ELSE                            
BEGIN                            
IF EXISTS (SELECT                            
  TOP 1 1                            
 FROM ProjectSection WITH (NOLOCK)                            
 WHERE ProjectId = @PProjectId                            
 AND SectionId = @PSectionId                            
 AND IsLocked = 1                            
 AND LockedBy != @PUserId)                            
BEGIN                            
SET @IsSuccess = 0;                            
SET @ErrorMessage = 'Another user is working on this section.';                            
END                            
          
ELSE                            
BEGIN               
-- UPDATE SORTORDER        
    DECLARE @OldSourceTag NVARCHAR(18) , @OldParentSectionId INT;        
    SELECT @OldSourceTag = SourceTag , @OldParentSectionId = ParentSectionId FROM ProjectSection WITH(NOLOCK) WHERE SectionId = @PSectionId AND ProjectId = @PProjectId;        
IF(@PSourceTag != @OldSourceTag OR @OldParentSectionId != @PParentSectionId)                
BEGIN                 
  DECLARE @SortOrder INT = dbo.udf_getSectionSortOrder(@PProjectId, @PCustomerId, @ParentSectionId, @PSourceTag,@PAuthor);                
  UPDATE PS SET SortOrder = SortOrder + 1 FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId  AND ParentSectionId = @PParentSectionId AND SortOrder >= @SortOrder AND SectionId != @PSectionId;                  
  UPDATE PS SET SortOrder = @SortOrder FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId  AND SectionId = @PSectionId;                   
END                             
--UPDATE ProjectSection                            
UPDATE PS                            
SET PS.SourceTag = @PSourceTag                            
   ,PS.Description = @PDescription                            
   ,PS.ParentSectionId = @PParentsectionId                            
   ,PS.Author = @PAuthor                            
   ,PS.ModifiedBy = @PUserId                            
   ,PS.ModifiedDate = GETUTCDATE()                            
   FROM ProjectSection PS WITH (NOLOCK)                            
WHERE PS.ProjectId = @PProjectId                            
AND PS.CustomerId = @PCustomerId                            
AND PS.SectionId = @PSectionId                     
                  
--IF SECTION IS NOT OPENED THEN OPEN IT                            
IF @IsSectionOpened = 0                            
BEGIN                            
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
END                            
                            
--UPDATE ProjectSegmentStatus                            
UPDATE PSS                            
SET PSS.SegmentOrigin = 'U'                            
FROM ProjectSegmentStatus PSS WITH (NOLOCK)                            
WHERE PSS.ProjectId = @PProjectId AND PSS.SectionId = @PSectionId                            
AND SequenceNumber = 0                            
AND IndentLevel = 0                            
                            
--UPDATE ProjectSegment if user version is created                            
IF @IsUserVersionCreated = 1                            
BEGIN                 
UPDATE PSG                            
SET PSG.SegmentDescription = @PDescription                            
   ,PSG.ModifiedBy = @PUserId                            
   ,PSG.ModifiedDate = GETUTCDATE()                            
FROM ProjectSegmentStatus PSST WITH (NOLOCK)                            
INNER JOIN ProjectSegment PSG WITH (NOLOCK)                            
 ON PSST.SegmentId = PSG.SegmentId                            
WHERE PSST.ProjectId = @PProjectId AND PSST.SectionId = @PSectionId                            
AND PSST.SequenceNumber = 0                            
AND PSST.IndentLevel = 0                            
END                            
ELSE                            
BEGIN                            
INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription,                            
SegmentSource, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)                            
 SELECT                            
  PSST.SegmentStatusId                            
    ,PSST.SectionId                            
    ,PSST.ProjectId                            
    ,PSST.CustomerId                            
    ,@PDescription AS SegmentDescription                            
    ,'U' AS SegmentSource                            
    ,@PUserId AS CreatedBy                          
    ,GETUTCDATE() AS CreateDate                            
    ,@PUserId AS ModifiedBy                            
    ,GETUTCDATE() AS ModifiedDate                            
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)            
 WHERE PSST.ProjectId = @PProjectId AND PSST.SectionId = @PSectionId                            
 AND PSST.SequenceNumber = 0                            
 AND PSST.IndentLevel = 0                            
END                            

--UPDATE ProjectSegmentStatus WITH LATEST SegmentId                            
UPDATE PSST                            
SET PSST.SegmentId = PSG.SegmentId                            
FROM ProjectSegmentStatus PSST WITH (NOLOCK)                          
INNER JOIN ProjectSegment PSG WITH (NOLOCK)                          
 ON PSST.ProjectId = PSG.ProjectId AND PSST.SectionId = PSG.SectionId AND PSST.SegmentStatusId = PSG.SegmentStatusId                          
WHERE PSST.ProjectId=  @PProjectId AND PSST.SectionId = @PSectionId                     
AND PSST.SequenceNumber = 0                          
AND PSST.IndentLevel = 0                          
                            
--COPY MASTER LINKS AS USER LINKS                            
DECLARE @SegmentStatusId BIGINT = (SELECT TOP 1                            
  PSST.SegmentStatusId                            
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)                            
 WHERE PSST.ProjectId = @PProjectId AND PSST.SectionId = @PSectionId                            
 AND PSST.SequenceNumber = 0                            
 AND PSST.IndentLevel = 0);                            
EXEC usp_CopyMasterLinksAsUserLinks @PProjectId                            
           ,@PCustomerId                            
         ,@SegmentStatusId                            
           ,@PUserId,                            
            @PSectionId;                            
                            
            
DECLARE @DivSectionId INT = 0, @DivisionCode NVARCHAR(500), @DivisionId INT, @IsMasterSectionId BIT=0;            
            
SELECT TOP 1            
@DivSectionId = ParentSectionId             
FROM ProjectSection  WITH (NOLOCK)            
WHERE SectionId = @PParentSectionId            
AND ProjectId = @PProjectId            
AND CustomerId = @PCustomerId            
            
SELECT             
@IsMasterSectionId = CASE WHEN ISNULL(PS.mSectionId,0) = 0 THEN 0 ELSE 1 END            
, @DivisionCode = LEFT(PS.SourceTag,2)            
FROM ProjectSection PS WITH (NOLOCK)            
WHERE PS.SectionId = @DivSectionId AND PS.ProjectId =@PProjectId AND PS.CustomerId = @PCustomerId            
   
DECLARE @MasterDataTypeId INT=(SELECT TOP 1 MasterDataTypeId FROM Project P WITH (NOLOCK)  WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId)     
   
IF @IsMasterSectionId = 1            
BEGIN            
     
 SELECT             
 @DivisionCode = D.DivisionCode,            
 @DivisionId = D.DivisionId            
  FROM SLCMaster..Division D WITH (NOLOCK)            
 WHERE D.MasterDataTypeId = @MasterDataTypeId           
 AND D.DivisionCode = @DivisionCode;    
   
         
    IF(@DivisionId IS NULL AND @DivisionCode = '9')          
    BEGIN         
     -- This is set to 99 because there is no division for code 9, and to adjust the print logic for Administation Folder      
        set @DivisionId=iif(@MasterDataTypeId=1,@BSDMasterAdminDivId,iif(@MasterDataTypeId=4,@CanadaMasterAdminDivId,@DivisionId))          
    END      
  
 UPDATE PS            
 SET          
 PS.DivisionId = @DivisionId,            
 PS.DivisionCode = @DivisionCode            
 FROM ProjectSection PS WITH (NOLOCK)            
 WHERE PS.SectionId = @PSectionId AND PS.ProjectId = @PProjectId AND PS.CustomerId = @PCustomerId            
END            
ELSE            
BEGIN            
            
--SELECT @DivisionCode = PS.SourceTag             
-- FROM ProjectSection PS WITH (NOLOCK)            
--WHERE PS.SectionId = @DivSectionId AND PS.ProjectId =@PProjectId AND PS.CustomerId = @PCustomerId            
            
  SELECT @DivisionCode = PS.SourceTag             
, @DivisionId = PS.DivisionId              
 FROM ProjectSection PS WITH (NOLOCK)              
WHERE PS.SectionId = @DivSectionId AND PS.ProjectId =@PProjectId AND PS.CustomerId = @PCustomerId              
          
          
    IF(@DivisionId IS NULL AND @DivisionCode = '9')          
    BEGIN         
     -- This is set to 99 because there is no division for code 9, and to adjust the print logic for Administation Folder      
        set @DivisionId=iif(@MasterDataTypeId=1,@BSDMasterAdminDivId,iif(@MasterDataTypeId=4,@CanadaMasterAdminDivId,@DivisionId))          
    END    
  
   UPDATE PS              
   SET               
   PS.DivisionId = @DivisionId              
   ,PS.DivisionCode = @DivisionCode              
   FROM ProjectSection PS WITH (NOLOCK)              
   --INNER JOIN CustomerDivision CD WITH (NOLOCK)              
   --ON  CD.DivisionCode = @DivisionCode              
   --AND PS.CustomerId = CD.CustomerId              
   WHERE PS.SectionId = @PSectionId AND PS.ProjectId = @PProjectId AND PS.CustomerId = @PCustomerId             
            
END;            
                      
SET @IsSuccess = 1;              
SET @ErrorMessage = 'SourceTag or Description Changed Successfully';                            
                                
 END                            
                             
END                            
--SELECT FINAL RESULT                       
SELECT                            
 @IsSuccess AS IsSuccess                            
   ,@ErrorMessage AS ErrorMessage                            
END  
GO


