CREATE PROCEDURE usp_CreateNewSubDivision                                            
(                                
@ProjectId INT,                                
@CustomerId INT,                                
@UserId INT,                                
@Description NVARCHAR(1000),                                            
@ParentSectionId INT,                                
@IsAddOnTop INT,                                
@SourceTag NVARCHAR(18) = NULL                                             
)                                
AS                                
BEGIN                                 
                                            
DECLARE @FormatTypeId INT = 1;                                            
DECLARE @SpecViewModeId INT = 1;                                            
DECLARE @SortOrder INT;                                            
DECLARE @SectionId INT = 0;                                         
DECLARE @AddSubDivisionSettingValue NVARCHAR(50) = NULL;                                           
                                    
IF (@SourceTag IS NOT NULL AND @SourceTag <> '')    
BEGIN    
 IF(EXISTS(SELECT TOP 1 1 FROM ProjectSection WITH (NOLOCK) WHERE ParentSectionId = @ParentSectionId AND ProjectId = @ProjectId AND CustomerId = @CustomerId        
                AND ISNULL(IsDeleted,0) = 0 AND TRIM(UPPER(SourceTag)) = TRIM(UPPER(@SourceTag))))          
    SET @SectionId = -1;        
END        
ELSE IF EXISTS(SELECT TOP 1 1 FROM ProjectSection WITH (NOLOCK) WHERE ParentSectionId = @ParentSectionId AND ProjectId = @ProjectId AND CustomerId = @CustomerId        
        AND ISNULL(IsDeleted,0) = 0 AND TRIM(UPPER([Description])) = TRIM(UPPER(@Description)) AND (SourceTag IS NULL OR SourceTag = ''))        
BEGIN        
    SET @SectionId = -2;        
END        
        
IF(@SectionId = 0)                                            
BEGIN                            
 IF(@IsAddOnTop = 1)                            
 BEGIN                            
  SET @SortOrder = (SELECT ISNULL(MIN(SortOrder)-1,1) FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND ParentSectionId = @ParentSectionId AND ISNULL(IsDeleted,0) = 0);                            
  SET @AddSubDivisionSettingValue = 'Top';                            
 END                            
 ELSE IF(@IsAddOnTop = 0)                            
 BEGIN                            
  SET @SortOrder = (SELECT ISNULL(MAX(SortOrder)+1,1) FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND ParentSectionId = @ParentSectionId AND ISNULL(IsDeleted,0) = 0);                            
  SET @AddSubDivisionSettingValue = 'Bottom';                            
 END                            
 ELSE IF(@IsAddOnTop = -1)                            
 BEGIN                            
  DROP TABLE IF EXISTS #subDivisions;                                          
  CREATE TABLE #subDivisions(                                        
   [Description] NVARCHAR(MAX),                                        
   [T_Description] NVARCHAR(MAX),                                        
   [SourceTag] VARCHAR(18) NULL,                                        
   [T_SourceTag] VARCHAR(400) NULL,                                        
   [SortOrder] INT                                        
  );                                  
  IF(@SourceTag IS NULL OR @SourceTag = '')                            
   INSERT INTO #subDivisions([Description], [T_Description], SourceTag, [T_SourceTag], SortOrder) VALUES (@Description, '', @Description, '', -1);                            
  ELSE                            
   INSERT INTO #subDivisions([Description], [T_Description], SourceTag, [T_SourceTag], SortOrder) VALUES (@Description, '', @SourceTag, '', -1);                            
                          
  INSERT INTO #subDivisions([Description], [T_Description], SourceTag, [T_SourceTag], SortOrder)                      
(SELECT [Description], '', SourceTag, '', SortOrder FROM ProjectSection WITH(NOLOCK)                        
   WHERE ProjectId = @ProjectId AND ParentSectionId = @ParentSectionId AND ISNULL(IsDeleted,0) = 0 AND SourceTag IS NOT NULL AND LEN(SourceTag) > 0);                            
                          
  UPDATE SD SET T_SourceTag = UPPER(dbo.udf_ExpandDigits(SD.SourceTag, 18, '0')) FROM #subDivisions SD;                        
                          
  DROP TABLE IF EXISTS #sortedSubDivisions;                                          
  SELECT ROW_NUMBER() OVER( ORDER BY T_SourceTag) AS RowId, [Description], [T_Description], SourceTag, [T_SourceTag], SortOrder INTO #sortedSubDivisions from #subDivisions order by T_SourceTag;                            
                              
  DECLARE @MaxRowId INT = (SELECT MAX(RowId) FROM #sortedSubDivisions);                                          
  DECLARE @NewSubDivRowId INT = (SELECT TOP 1 RowId FROM #sortedSubDivisions WHERE [Description] = @Description AND [SourceTag] = @SourceTag);                            
                              
  IF(@MaxRowId = 1)                            
   SET @SortOrder = 1;                            
  ELSE IF(@MaxRowId = @NewSubDivRowId)                                          
   SET @SortOrder = (SELECT MAX(SortOrder)+1 FROM #sortedSubDivisions);                                          
  ELSE                                           
   SET @SortOrder = (SELECT SortOrder FROM #sortedSubDivisions WHERE RowId = (@NewSubDivRowId + 1)); -- Update the Sort order of other SubDiv                                              
 END -- END IF(@IsAddOnTop = -1)                            
                             
 IF(@AddSubDivisionSettingValue IS NOT NULL)                            
 BEGIN                            
  DECLARE @Id INT = (SELECT TOP 1 Id FROM ProjectSetting WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND [Name] = 'AddSubDivision');                            
  IF(@Id IS NULL)                            
   INSERT INTO ProjectSetting(ProjectId, CustomerId, [Name], [Value], CreatedDate, CreatedBy)                             
   VALUES(@ProjectId, @CustomerId, 'AddSubDivision' , @AddSubDivisionSettingValue, GETUTCDATE(), @UserId);                             
  ELSE                             
   UPDATE PS SET [Value] = @AddSubDivisionSettingValue, [ModifiedDate] = GETUTCDATE(), [ModifiedBy] = @UserId FROM ProjectSetting PS WITH(NOLOCK)                             
   WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND [Name] = 'AddSubDivision';                             
 END                                  
                             
 UPDATE PS SET SortOrder = SortOrder + 1 FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @ProjectId AND ParentSectionId = @ParentSectionId AND ISNULL(ISDeleted,0) = 0 AND SortOrder >= @SortOrder;                                 
                            
 INSERT INTO ProjectSection(ParentSectionId, ProjectId, CustomerId, UserId, [Description], LevelId, IsLastLevel, SourceTag, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId, SpecViewModeId, SortOrder)                               
  
             
 VALUES (@ParentSectionId, @ProjectId, @CustomerId, @UserId, @Description, 3, 0, @SourceTag, 0, GETUTCDATE(), @UserId, NULL, NULL, @FormatTypeId, @SpecViewModeId, @SortOrder);                                            
                                            
 SET @SectionId = SCOPE_IDENTITY(); --SET @ResponseMsg = 'Sub Division created successfully.';                                   
END -- END IF(@SectionId = 0)                            
                            
SELECT @SectionId as SectionId;                                            
                                            
END