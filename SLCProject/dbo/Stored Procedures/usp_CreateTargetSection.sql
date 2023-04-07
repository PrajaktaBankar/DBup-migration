CREATE PROCEDURE usp_CreateTargetSection          
 @SourceSectionId INT ,          
 @ProjectId INT,          
 @CustomerId INT,          
 @UserId INT,          
 @SourceTag VARCHAR(18),          
 @Author NVARCHAR(10),          
 @Description NVARCHAR(500),          
 @ParentSectionId INT,          
 @TargetSectionId INT OUTPUT           
AS          
BEGIN          
 --DECLARE @TargetSectionId INT = 0;          
 SET @TargetSectionId = 0;           
          
 BEGIN -- Create New/Target Section          
          
  --DECLARE @ParentSectionId INT = 0;          
  --DECLARE @ParentSectionIdTable TABLE (ParentSectionId INT);              
              
  ---- Calculate ParentSectionId                            
  --INSERT INTO @ParentSectionIdTable (ParentSectionId)                            
  --EXEC usp_GetParentSectionIdForImportedSection @ProjectId, @CustomerId, @UserId, @SourceTag;                            
             
  --SELECT TOP 1 @ParentSectionId = ParentSectionId FROM @ParentSectionIdTable;          
       
      
DECLARE @SortOrder INT = dbo.udf_getSectionSortOrder(@ProjectId, @CustomerId, @ParentSectionId, @SourceTag, @Author);        
        
UPDATE PS SET SortOrder = SortOrder + 1 FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId  AND ParentSectionId = @ParentSectionId AND SortOrder >= @SortOrder;        
  -- Insert Target Section          
  INSERT INTO ProjectSection (ParentSectionId, ProjectId, CustomerId, UserId,                            
  DivisionId, DivisionCode, Description, LevelId, IsLastLevel, SourceTag,                            
  Author, TemplateId,CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted, FormatTypeId, SpecViewModeId,             
  IsLockedImportSection,IsTrackChanges,IsTrackChangeLock,TrackChangeLockedBy,SortOrder)          
  SELECT          
   @ParentSectionId AS ParentSectionId          
  ,@ProjectId AS ProjectId          
  ,@CustomerId AS CustomerId          
  ,@UserId AS UserId          
  ,NULL AS DivisionId          
  ,NULL AS DivisionCode          
  ,@Description AS [Description]          
  ,PS.LevelId AS LevelId                            
  ,1 AS IsLastLevel                            
  ,@SourceTag AS SourceTag                            
  ,@Author AS Author                            
  ,PS.TemplateId AS TemplateId                            
  ,GETUTCDATE() AS CreateDate                            
  ,@UserId AS CreatedBy                            
  ,GETUTCDATE() AS ModifiedDate                            
  ,@UserId AS ModifiedBy                            
  ,0 AS IsDeleted              
  ,PS.FormatTypeId AS FormatTypeId                            
  ,PS.SpecViewModeId AS SpecViewModeId            
  ,PS.IsLockedImportSection AS IsLockedImportSection          
  ,PS.IsTrackChanges AS IsTrackChanges           
  ,PS.IsTrackChangeLock AS IsTrackChangeLock           
  ,PS.TrackChangeLockedBy As TrackChangeLockedBy      
  ,@SortOrder as SortOrder          
  FROM ProjectSection PS WITH (NOLOCK)          
  WHERE PS.SectionId = @SourceSectionId;          
              
  SET @TargetSectionId = SCOPE_IDENTITY();          
          
  EXEC usp_SetDivisionIdForUserSection @ProjectId                          
         ,@TargetSectionId                          
         ,@CustomerId;           
          
  SELECT @TargetSectionId AS TargetSectionId;          
          
 END          
          
END 