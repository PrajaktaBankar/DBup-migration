CREATE PROCEDURE usp_MoveSubFolderInParentFolder            
(             
@ProjectId INT,            
@CustomerId INT,                   
@UserId INT  ,          
@SubFolderSectionId INT,                                              
@ParentSectionId INT,            
@Description NVARCHAR(1000),           
@IsAddOnTop INT,                                            
@SourceTag NVARCHAR(18) = NULL ,      
@IsNonNumberedParent   BIT       
)            
AS                                              
BEGIN                 
              
DECLARE @SortOrder INT;                                                            
DECLARE @ResponseId INT = 0;                                                         
--DECLARE @AddSubDivisionSettingValue NVARCHAR(50) = NULL;                
DECLARE @DivisionId INT = NULL ;              
DECLARE @DivisionCode NVARCHAR(500) = NULL;         
DECLARE @MasterDataTypeId INT = (SELECT TOP 1 MasterDataTypeId FROM Project WITH(NOLOCK) WHERE ProjectId = @ProjectId);           
              
IF (@SourceTag IS NOT NULL AND @SourceTag <> '')                    
BEGIN                    
 IF(EXISTS(SELECT TOP 1 1 FROM ProjectSection WITH (NOLOCK) WHERE ParentSectionId = @ParentSectionId AND ProjectId = @ProjectId AND CustomerId = @CustomerId                        
                AND ISNULL(IsDeleted,0) = 0 AND TRIM(UPPER(SourceTag)) = TRIM(UPPER(@SourceTag))))                          
    SET @ResponseId = -1;                        
END                        
ELSE IF EXISTS(SELECT TOP 1 1 FROM ProjectSection WITH (NOLOCK) WHERE ParentSectionId = @ParentSectionId AND ProjectId = @ProjectId AND CustomerId = @CustomerId                        
        AND ISNULL(IsDeleted,0) = 0 AND TRIM(UPPER([Description])) = TRIM(UPPER(@Description)) AND (SourceTag IS NULL OR SourceTag = ''))                        
BEGIN                        
    SET @ResponseId = -2;                        
END               
              
IF(@ResponseId = 0)                                                            
BEGIN                                            
 IF(@IsAddOnTop = 1)                                            
 BEGIN                                            
  SET @SortOrder = (SELECT ISNULL(MIN(SortOrder)-1,1) FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId               
                    AND CustomerId = @CustomerId AND ParentSectionId = @ParentSectionId AND ISNULL(IsDeleted,0) = 0);                                            
  --SET @AddSubDivisionSettingValue = 'Top';                                            
 END                                            
 ELSE IF(@IsAddOnTop = 0)                                            
 BEGIN                                            
  SET @SortOrder = (SELECT ISNULL(MAX(SortOrder)+1,1) FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId               
                    AND CustomerId = @CustomerId AND ParentSectionId = @ParentSectionId AND ISNULL(IsDeleted,0) = 0);                                            
  --SET @AddSubDivisionSettingValue = 'Bottom';                                            
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
   INSERT INTO #subDivisions([Description], [T_Description], SourceTag, [T_SourceTag], SortOrder) VALUES (@Description, '', @SourceTag, '', -1);                       
  ELSE                                            
   INSERT INTO #subDivisions([Description], [T_Description], SourceTag, [T_SourceTag], SortOrder) VALUES (@Description, '', @SourceTag, '', -1);                                                                                
  INSERT INTO #subDivisions([Description], [T_Description], SourceTag, [T_SourceTag], SortOrder)                                      
(SELECT [Description], '', SourceTag, '', SortOrder FROM ProjectSection WITH(NOLOCK)                               
   WHERE ProjectId = @ProjectId               
   AND ParentSectionId = @ParentSectionId               
   AND ISNULL(IsDeleted,0) = 0      AND SourceTag IS NOT NULL AND LEN(SourceTag) > 0);                 
                 
  UPDATE SD SET T_SourceTag = UPPER(dbo.udf_ExpandDigits(SD.SourceTag, 18, '0'))              
              --,T_Description = UPPER(dbo.udf_ExpandDigits(SD.Description, 20, '0'))              
   FROM #subDivisions SD;                
                                        
                                          
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
                 
    UPDATE PS SET SortOrder = SortOrder + 1               
 FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @ProjectId               
 AND ParentSectionId = @ParentSectionId               
 AND ISNULL(ISDeleted,0) = 0               
 AND SortOrder >= @SortOrder;                                                             
 END -- END IF(@IsAddOnTop = -1)                      
          
   IF EXISTS(SELECT TOP 1 SectionCode FROM ProjectSection WITH(NOLOCK) WHERE SectionId = @ParentSectionId AND ProjectId = @ProjectId AND ISNULL(mSectionId,0) >0)           
   BEGIN                                            
 SELECT @DivisionId = MD.DivisionId,@DivisionCode = MD.DivisionCode FROM SLCMaster..Division MD WITH (NOLOCK) INNER JOIN ProjectSection PS WITH (NOLOCK)       
 ON MD.DivisionCode = PS.SourceTag Where PS.SectionId = @ParentSectionId AND PS.ProjectId = @ProjectId AND MD.MasterDataTypeId = @MasterDataTypeId;              
   END      
   ELSE      
 SELECT @DivisionId = CD.DivisionId,@DivisionCode = CD.DivisionCode FROM CustomerDivision CD WITH (NOLOCK) INNER JOIN ProjectSection PS WITH (NOLOCK)       
 ON CD.DivisionId = PS.DivisionId Where PS.SectionId = @ParentSectionId AND PS.ProjectId = @ProjectId;           
              
 IF(@IsNonNumberedParent!=1)          
   BEGIN          
     UPDATE PS SET PS.SortOrder = @SortOrder,               
          PS.ParentSectionId = @ParentSectionId,              
          PS.DivisionId = @DivisionId,              
          PS.DivisionCode = @DivisionCode              
        FROM ProjectSection PS WITH(NOLOCK)               
        WHERE PS.SectionId = @SubFolderSectionId AND PS.ProjectId = @ProjectId AND PS.CustomerId = @CustomerId            
   END          
    ELSE          
   BEGIN          
    UPDATE PS SET PS.SortOrder = @SortOrder,               
          PS.ParentSectionId = @ParentSectionId,             
    PS.SourceTag=NULL,           
          PS.DivisionId = @DivisionId,              
          PS.DivisionCode = @DivisionCode              
        FROM ProjectSection PS WITH(NOLOCK)               
        WHERE PS.SectionId = @SubFolderSectionId AND PS.ProjectId = @ProjectId AND PS.CustomerId = @CustomerId            
               
   END           
          
  -- Added for Bug 64342: Moved folder is not displaying as per tree order for Reporting and TOC output        
  UPDATE PS        
  SET PS.DivisionId = @DivisionId        
  ,PS.DivisionCode = @DivisionCode        
  FROM ProjectSection PS WITH (NOLOCK)        
  WHERE PS.ParentSectionId = @SubFolderSectionId        
  AND PS.ProjectId = @ProjectId        
  AND PS.CustomerId = @CustomerId          
              
              
END -- END IF(@SectionId = 0)               
SELECT @ResponseId as ResponseId;                
END  
