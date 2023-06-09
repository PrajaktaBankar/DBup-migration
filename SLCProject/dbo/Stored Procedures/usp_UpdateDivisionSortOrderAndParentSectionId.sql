  
CREATE PROCEDURE usp_UpdateDivisionSortOrderAndParentSectionId      
(      
@ProjectId INT,      
@CustomerId INT,      
@SectionId INT      
)      
AS       
BEGIN      
DECLARE @SourceTag NVARCHAR(18), @Description NVARCHAR(1000), @MasterDataTypeId INT;      
DECLARE @SortOrder INT = 0, @ParentSectionId INT =0;      
      
SELECT @SourceTag = SourceTag , @Description = [Description] FROM ProjectSection WITH(NOLOCK) WHERE SectionId = @SectionId AND ProjectId = @ProjectId AND CustomerId = @CustomerId;      
SELECT @MasterDataTypeId = MasterDataTypeId FROM Project  WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId;      
      
IF(@SourceTag IS NOT NULL OR @SourceTag <> '')      
BEGIN      
 DROP TABLE IF EXISTS #divisions;                                                                    
                                                
 CREATE TABLE #divisions(                                                  
 [Description] NVARCHAR(MAX),                                 
 [T_Description] NVARCHAR(MAX) NULL,                                                               
 [SourceTag] NVARCHAR(18) NULL,                                  
 [T_SourceTag] NVARCHAR(400) NULL,                                  
 [SortOrder] INT);       
      
    -- CASE Statement is for Converting 020 tag to 02               
 INSERT INTO #divisions([Description],[T_Description], [SourceTag], [T_SourceTag], [SortOrder])                                                                   
  (select [Description], '',               
   (CASE WHEN (SourceTag = '020' AND (mSectionId = 3000110 OR mSectionId = 105)) THEN '02' ELSE SourceTag END) AS SourceTag , '', SortOrder from ProjectSection WITH(NOLOCK)                                                   
   WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND ISNULL(IsDeleted,0) =0 AND DivisionCode is NULL AND LevelId = 2 AND (SourceTag IS NOT NULL AND SourceTag NOT IN ('9','DC')));                                                          
      
 UPDATE dt SET dt.T_SourceTag = UPPER(dbo.udf_ExpandDigits(dt.SourceTag, 18, '0')) , dt.T_Description = UPPER(dbo.udf_ExpandDigits(dt.Description, 20, '0')) FROM #divisions dt;                                  
                                  
 DROP TABLE IF EXISTS #sortedDivisions;                                                                    
                                                 
 SELECT ROW_NUMBER() OVER( ORDER BY T_SourceTag,T_Description) AS RowId , [Description],T_Description, SourceTag, T_SourceTag, SortOrder INTO #sortedDivisions from #divisions order by T_SourceTag,T_Description;                  
         
 DECLARE @MaxRowId INT = (SELECT MAX(RowId) FROM #sortedDivisions);                                                                    
 DECLARE @NewDivRowId INT = (SELECT TOP 1 RowId FROM #sortedDivisions WHERE [Description] = @Description AND [SourceTag] = @SourceTag);                                                         
                                                   
 IF(@MaxRowId = @NewDivRowId)                                                                    
  SET @SortOrder = (SELECT MAX(SortOrder)+1 FROM #sortedDivisions);                                                                   
 ELSE                                            
  SET @SortOrder = (SELECT SortOrder FROM #sortedDivisions WHERE RowId = (@NewDivRowId + 1));      
       
      
 UPDATE PS SET SortOrder = SortOrder + 1 FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND LevelId = 2 AND SortOrder >= @SortOrder;      
 UPDATE PS SET SortOrder = @SortOrder FROM ProjectSection PS WITH(NOLOCK) WHERE SectionId = @SectionId AND ProjectId = @ProjectId AND CustomerId = @CustomerId;  
 -- SET ParentSectionId       
 IF(@MasterDataTypeId = 1 OR @MasterDataTypeId = 4)                                             
  SET @ParentSectionId = dbo.fn_getDivisionParentSectionId(@ProjectId, @CustomerId, @SortOrder, @SourceTag);                                             
 ELSE                                             
  SET @ParentSectionId = 0;                                
 UPDATE PS SET ParentSectionId = @ParentSectionId FROM ProjectSection PS WITH(NOLOCK) WHERE SectionId = @SectionId AND ProjectId = @ProjectId AND CustomerId = @CustomerId;      
END      
ELSE      
BEGIN      
 DECLARE @AddDivisionSettingValue NVARCHAR(10) = NULL;      
 SET @AddDivisionSettingValue = (SELECT TOP 1 [Value] FROM ProjectSetting WITH(NOLOCK) WHERE ProjectId = @ProjectId  AND CustomerId = @CustomerId AND [Name] = 'AddDivision');      
 SET @AddDivisionSettingValue = ISNULL(@AddDivisionSettingValue, 'Bottom');      
 IF(@AddDivisionSettingValue = 'Top')      
 BEGIN      
  SET @SortOrder = (SELECT MIN(SortOrder)-1 FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId  AND CustomerId = @CustomerId AND LevelId = 2 AND ISNULL(IsDeleted,0) =0);      
  IF(@MasterDataTypeId = 1 OR @MasterDataTypeId = 4)                                            
   SET @ParentSectionId = (SELECT TOP 1 SectionId FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND ParentSectionId = 0 AND (mSectionId = 5 OR mSectionId = 3000001)); -- Front End Group                        
  
  ELSE                                         
   SET @ParentSectionId = 0;       
 END      
 ELSE      
 BEGIN      
  SET @SortOrder = (SELECT MAX(SortOrder)+1 FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId  AND CustomerId = @CustomerId AND LevelId = 2 AND ISNULL(IsDeleted,0) =0);      
  IF(@MasterDataTypeId = 1 OR @MasterDataTypeId = 4)                                                                   
   SET @ParentSectionId = (SELECT TOP 1 SectionId FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND ParentSectionId = 0 AND (mSectionId = 4 OR mSectionId = 3001044)); -- Process Equipment Subgroup - Divisions 40 through 48                                                 
  ELSE                                            
   SET @ParentSectionid = 0;                                            
 END;      
 UPDATE PS SET SortOrder = @SortOrder, ParentSectionId = @ParentSectionId FROM ProjectSection PS WITH(NOLOCK) WHERE SectionId = @SectionId AND ProjectId = @ProjectId AND CustomerId = @CustomerId;      
END      
END;

GO