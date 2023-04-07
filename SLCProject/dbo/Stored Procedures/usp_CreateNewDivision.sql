CREATE PROCEDURE usp_CreateNewDivision                          
(                                                         
@ProjectId INT,                                                        
@CustomerId INT,                                                         
@UserId INT,                                                        
@Description NVARCHAR(1000),                                                         
@IsAddOnTop BIT,                                                   
@SourceTag NVARCHAR(18) = NULL                                                          
)                                                         
AS                                                         
BEGIN                            
DECLARE @ParentSectionId INT;                                             
DECLARE @FormatTypeId INT = 1;                            
DECLARE @SpecViewModeId INT = 1;                                                              
DECLARE @SortOrder INT;                                                               
DECLARE @SectionId INT = 0;                                                            
DECLARE @AddDivisionSettingValue NVARCHAR(50) = 'Bottom';                                                                 
DECLARE @DivisionId INT, @DivisionCode NVARCHAR(18) = '' ;                                     
DECLARE @MasterDataTypeId INT = (SELECT MasterDataTypeId FROM Project WITH(NOLOCK) WHERE ProjectId = @ProjectId);                                       
                                        
IF EXISTS(SELECT TOP 1 1 FROM ProjectSection WITH (NOLOCK)                                                                     
 WHERE ProjectId=@ProjectId AND CustomerId = @CustomerId                                                                                
 AND ((@SourceTag IS NOT NULL AND UPPER(SourceTag) = UPPER(@SourceTag) AND UPPER([Description]) = UPPER(@Description)) OR                 
  (@SourceTag IS NULL AND SourceTag IS NULL AND UPPER([Description]) = UPPER(@Description)))                                           
 AND ISNULL(IsDeleted,0) = 0)     
                                                  
BEGIN                                                                
 SET @SectionId = -1; --SET @ResponseMsg = 'Division already exists.';                                                              
END;                                                         

-- Check if Global Division is duplicate on not                                        
IF (EXISTS(SELECT TOP 1 1 FROM CustomerDivision WITH(NOLOCK)                                         
 WHERE CustomerId = @CustomerId AND ((@SourceTag IS NOT NULL AND UPPER(DivisionCode) = UPPER(@SourceTag) AND UPPER(DivisionTitle) = UPPER(@Description))                 
 OR (@SourceTag IS NULL AND DivisionCode IS NULL AND UPPER(DivisionTitle) = UPPER(@Description)))))                                        
BEGIN                                        
 SELECT  @DivisionId = DivisionId, @DivisionCode = DivisionCode  FROM CustomerDivision WITH(NOLOCK)                                         
 WHERE CustomerId = @CustomerId AND ((@SourceTag IS NOT NULL AND UPPER(DivisionCode) = UPPER(@SourceTag) AND UPPER(DivisionTitle) = UPPER(@Description)               
 OR (@SourceTag IS NULL AND DivisionCode IS NULL AND UPPER(DivisionTitle) = UPPER(@Description))))
                                 
END                                        
ELSE                                        
BEGIN                                           
 INSERT INTO CustomerDivision (DivisionTitle, DivisionCode, IsActive, MasterDataTypeId, FormatTypeId, CustomerId, CreatedBy, CreatedDate)                                        
 VALUES (@Description, @SourceTag, 1, @MasterDataTypeId, @FormatTypeId, @CustomerId, @UserId, GETUTCDATE());                                        
                                        
 SET @DivisionId = SCOPE_IDENTITY();                                        
 SELECT @DivisionCode = DivisionCode FROM CustomerDivision WITH(NOLOCK) WHERE DivisionId = @DivisionId;                                        
END;                       
                                        
IF(@SectionId = 0)                                             
BEGIN -- Get the Sort Order for the newly added Division                                                               
  IF(@SourceTag IS NULL OR @SourceTag = '' )                                              
  BEGIN                                             
     IF(@IsAddOnTop = 1)                                                            
 BEGIN                                              
 SET @SortOrder = (SELECT (MIN(SortOrder)-1) FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @ProjectId);                                           
  SET @AddDivisionSettingValue = 'Top';                                    
  IF(@MasterDataTypeId = 1 OR @MasterDataTypeId = 4)                                    
   SET @ParentSectionId = (SELECT TOP 1 SectionId FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND ParentSectionId = 0 AND (mSectionId = 5 OR mSectionId = 3000001)); -- Front End Group                         
 
           
  ELSE                                 
   SET @ParentSectionId = 0;                                    
 END --END IF(@IsAddOnTop = 1)                                 
 ELSE                                                          
 BEGIN                                               
  SET @SortOrder = (SELECT (MAX(SortOrder)+1) FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @ProjectId);                                          
  SET @AddDivisionSettingValue = 'Bottom';                                    
  IF(@MasterDataTypeId = 1 OR @MasterDataTypeId = 4)                                                           
   SET @ParentSectionId = (SELECT TOP 1 SectionId FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND ParentSectionId = 0                                 
   AND (mSectionId = 4 OR mSectionId = 3001044)); -- Process Equipment Subgroup - Divisions 40 through 48                                         
  ELSE                                    
   SET @ParentSectionid = 0;                                    
  END                                              
 END --END ELSE IF(@IsAddOnTop = 1)                                               
 ELSE                                                 
 BEGIN                                                              
   DROP TABLE IF EXISTS #divisions;                                                            
                                        
   CREATE TABLE #divisions(                                          
   [Description] NVARCHAR(MAX),                         
   [T_Description] NVARCHAR(MAX) NULL,                                                       
   [SourceTag] NVARCHAR(18) NULL,                          
   [T_SourceTag] NVARCHAR(400) NULL,                          
   [SortOrder] INT  );                                                          
                                           
   INSERT INTO #divisions([Description],[T_Description], SourceTag,[T_SourceTag], SortOrder) VALUES (@Description,@Description ,@SourceTag ,@SourceTag, -1);                                          
                                           
   -- CASE Statement is for Converting 020 tag to 02       
   INSERT INTO #divisions([Description],[T_Description], [SourceTag], [T_SourceTag], [SortOrder])                                                           
   (select [Description], '',       
  (CASE WHEN (SourceTag = '020' AND (mSectionId = 3000110 OR mSectionId = 105)) THEN '02' ELSE SourceTag END) AS SourceTag , '', SortOrder from ProjectSection WITH(NOLOCK)                                           
   WHERE ProjectId = @ProjectId and ISNULL(IsDeleted,0) =0 and DivisionCode is NULL and LevelId = 2 AND (SourceTag IS NOT NULL AND SourceTag NOT IN ('9','DC')));                                                  
                                        
   UPDATE dt SET dt.T_SourceTag = UPPER(dbo.udf_ExpandDigits(dt.SourceTag, 18, '0')) , dt.T_Description = UPPER(dbo.udf_ExpandDigits(dt.Description, 20, '0')) FROM #divisions dt;                          
                          
   DROP TABLE IF EXISTS #sortedDivisions;                                                            
                                         
   SELECT ROW_NUMBER() OVER( ORDER BY T_SourceTag,T_Description) AS RowId , [Description],T_Description, SourceTag, T_SourceTag, SortOrder INTO #sortedDivisions from #divisions order by T_SourceTag,T_Description;          
                                         
 DECLARE @MaxRowId INT = (SELECT MAX(RowId) FROM #sortedDivisions);                                                            
                                         
DECLARE @NewDivRowId INT = (SELECT TOP 1 RowId FROM #sortedDivisions WHERE [Description] = @Description AND [SourceTag] = @SourceTag);                                                 
                                           
 IF(@MaxRowId = @NewDivRowId)                                                            
  SET @SortOrder = (SELECT MAX(SortOrder)+1 FROM #sortedDivisions);                                                           
 ELSE                                    
  SET @SortOrder = (SELECT SortOrder FROM #sortedDivisions WHERE RowId = (@NewDivRowId + 1));                                          
                                          
 UPDATE PS SET SortOrder = SortOrder + 1 FROM ProjectSection PS WITH(NOLOCK) where ProjectId = @ProjectId AND SortOrder >= @SortOrder; -- Calculate Parent Section Id                                                  
                                     
 IF(@MasterDataTypeId = 1 OR @MasterDataTypeId = 4)                                     
 SET @ParentSectionId = dbo.fn_getDivisionParentSectionId(@ProjectId, @CustomerId, @SortOrder, @SourceTag);                                                     
 ELSE                                     
 SET @ParentSectionId = 0;                                    
  END -- END ELSE Part of (IF(@SourceTag IS NULL OR @SourceTag = '' ))                                                                           
                     
   -- Add/ Update AddDivision setting in ProjectSetting Table                                                            
 IF EXISTS(SELECT Id FROM ProjectSetting WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND [Name] = 'AddDivision')                         
 UPDATE PS SET [Value] = @AddDivisionSettingValue,                                                             
    [ModifiedDate] = GETUTCDATE(),                                                              
    [ModifiedBy] = @UserId    FROM ProjectSetting PS WITH(NOLOCK)                                                              
    WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND                                           
    [Name] = 'AddDivision';                                                             
  ELSE                                                              
 INSERT INTO ProjectSetting(ProjectId, CustomerId, [Name], [Value], CreatedDate, CreatedBy)                                                            
  VALUES(@ProjectId, @CustomerId, 'AddDivision' , @AddDivisionSettingValue, GETUTCDATE(), @UserId);                                                                               
                                         
                                           
 INSERT INTO ProjectSection(ParentSectionId, ProjectId, CustomerId, UserId,  [Description], LevelId, IsLastLevel, SourceTag, DivisionId, IsDeleted, CreateDate,                                             
    CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId, SpecViewModeId, SortOrder)                                             
    VALUES (@ParentSectionId, @ProjectId, @CustomerId, @UserId,  @Description, 2, 0, @SourceTag,@DivisionId, 0, GETUTCDATE(), @UserId, NULL, NULL, @FormatTypeId, @SpecViewModeId, @SortOrder);                                                               
   
    
 SET @SectionId = SCOPE_IDENTITY(); --SET @ResponseMsg = 'Division created successfully.';                                                               
END;                                                               
SELECT @SectionId as SectionId;                                                                            
END 