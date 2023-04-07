CREATE PROCEDURE usp_UpdateUserDivision                    
(                                        
@ProjectId INT,                                        
@CustomerId INT,                                        
@SectionId INT,                            
@SourceTag NVARCHAR(18),                                      
@Description NVARCHAR(1000),            
@UserId INT                                               
)                                        
AS                                        
BEGIN                            
                               
DECLARE @PCustomerId INT = @CustomerId;                                        
DECLARE @PProjectId INT = @ProjectId;                                                   
DECLARE @PSectionId INT = @SectionId;                            
DECLARE @PDescription NVARCHAR(1000)=@Description;                                     
DECLARE @PSourceTag NVARCHAR(18)=@SourceTag;                            
DECLARE @ResponseId INT = 0;                          
DECLARE @DivisionId INT, @DivisionCode NVARCHAR(18) = '' ;                               
DECLARE @MasterDataTypeId INT = (SELECT MasterDataTypeId FROM Project WITH(NOLOCK) WHERE ProjectId = @ProjectId);              
DECLARE @FormatTypeId INT = 1;             
                    
IF EXISTS(SELECT TOP 1 1 FROM ProjectSection WITH (NOLOCK)                                                               
 WHERE ProjectId=@ProjectId AND CustomerId = @CustomerId                                                                          
 AND ((@SourceTag IS NOT NULL AND UPPER(SourceTag) = UPPER(@SourceTag) AND UPPER([Description]) = UPPER(@Description)) OR           
  (@SourceTag IS NULL AND SourceTag IS NULL AND UPPER([Description]) = UPPER(@Description)))                                     
 AND ISNULL(IsDeleted,0) = 0)                                       
BEGIN                                                  
 SET @ResponseId = -1; --SET @ResponseMsg = 'Division already exists.';                                                
END;                   
            
-- Check if Global Division is duplicate on not                                  
IF (EXISTS(SELECT TOP 1 1 FROM CustomerDivision WITH(NOLOCK)                                   
 WHERE CustomerId = @CustomerId AND ((@SourceTag IS NOT NULL AND UPPER(DivisionCode) = UPPER(@SourceTag) AND UPPER(DivisionTitle) = UPPER(@Description))           
 OR (@SourceTag IS NULL AND DivisionCode IS NULL AND UPPER(DivisionTitle) = UPPER(@Description)))))                                 
BEGIN                                  
 SELECT @DivisionId = DivisionId, @DivisionCode = DivisionCode FROM CustomerDivision WITH(NOLOCK) WHERE CustomerId = @CustomerId                                   
  AND UPPER(DivisionCode) = UPPER(@SourceTag) AND UPPER(DivisionTitle) = UPPER(@Description) AND ISNULL(IsActive,0) = 1;                                  
END                                  
ELSE                              
BEGIN                                     
 INSERT INTO CustomerDivision (DivisionTitle, DivisionCode, IsActive, MasterDataTypeId, FormatTypeId, CustomerId, CreatedBy, CreatedDate)                                  
 VALUES (@Description, @SourceTag, 1, @MasterDataTypeId, @FormatTypeId, @CustomerId, @UserId, GETUTCDATE());                                  
                                  
 SET @DivisionId = SCOPE_IDENTITY();    
 SELECT @DivisionCode = DivisionCode FROM CustomerDivision WITH(NOLOCK) WHERE DivisionId = @DivisionId;                                
END;              
                          
IF(@ResponseId =0)                          
BEGIN     
   
  
 DECLARE @OldDivisionId INT = (SELECT TOP 1 DivisionId FROM ProjectSection WITH(NOLOCK) WHERE SectionId = @PSectionId AND ProjectId = @PProjectId AND CustomerId = @PCustomerId);  
 UPDATE PS SET DivisionId = @DivisionId FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId and DivisionId = @OldDivisionId;  
  
 IF(@PSourceTag IS NULL OR @PSourceTag = '' OR ((SELECT COUNT(1) FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @PCustomerId AND LevelId = 2 AND SourceTag = @SourceTag)  = 1))                 
 BEGIN                 
  UPDATE PS SET PS.[Description] = @PDescription, DivisionId = @DivisionId, ModifiedBy = @UserId, ModifiedDate = GETUTCDATE()         
  FROM ProjectSection PS WITH(NOLOCK) WHERE PS.SectionId = @PSectionId and PS.ProjectId = @ProjectId and PS.CustomerId = @CustomerId;                
 END            
 ELSE                 
 BEGIN                
  DROP TABLE IF EXISTS #divisions;                
  CREATE TABLE #divisions(                
  [RowId] INT,                          
  [SectionId] INT,                                  
  [Description] NVARCHAR(MAX),                
  [T_Description] NVARCHAR(MAX),                
  [SourceTag] VARCHAR(100) NULL,                 
  [SortOrder] INT                                  
  );                
  UPDATE PS SET PS.[Description] = @PDescription FROM ProjectSection PS WITH(NOLOCK) WHERE PS.SectionId = @PSectionId and PS.ProjectId = @ProjectId and PS.CustomerId = @PCustomerId;                
  INSERT INTO #divisions([RowId], [SectionId], [Description], SourceTag, SortOrder)                 
  (SELECT ROW_NUMBER() OVER( ORDER BY [Description]) AS RowId, SectionId, [Description],    
 (CASE WHEN (SourceTag = '020' AND (mSectionId = 3000110 OR mSectionId = 105)) THEN '02' ELSE SourceTag END) AS SourceTag    
 , SortOrder FROM ProjectSection WITH(NOLOCK) WHERE                 
  ProjectId = @PProjectId and SourceTag = @PSourceTag AND LevelId = 2 AND ISNULL(IsDeleted,0) = 0);                
                  
  UPDATE #divisions SET T_Description = dbo.udf_ExpandDigits([Description], 5, '0');                
                  
  DROP TABLE IF EXISTS #sortedDivisions;                  
  SELECT ROW_NUMBER() OVER( ORDER BY T_Description) AS RowId ,SectionId, [Description], T_Description, SourceTag, SortOrder INTO #sortedDivisions FROM #divisions ORDER BY T_Description;                
                
  DECLARE @MaxRowId INT = (SELECT MAX(RowId) FROM #sortedDivisions);                                                      
  DECLARE @NewDivRowId INT = (SELECT TOP 1 RowId FROM #sortedDivisions WHERE SectionId = @SectionId);                                           
  DECLARE @SortOrder INT = 0;                                     
  IF(@MaxRowId = @NewDivRowId)                                                      
   SET @SortOrder = (SELECT MAX(SortOrder)+1 FROM #sortedDivisions);                                                     
  ELSE                                                       
   SET @SortOrder = (SELECT SortOrder FROM #sortedDivisions WHERE RowId = (@NewDivRowId + 1));                 
                
  UPDATE PS SET SortOrder = SortOrder + 1 FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @ProjectId and SortOrder >= @SortOrder;                
  UPDATE PS SET SortOrder = @SortOrder , DivisionId = @DivisionId, ModifiedBy = @UserId, ModifiedDate = GETUTCDATE() FROM ProjectSection PS WITH(NOLOCK) WHERE SectionId = @PSectionId;                 
 END -- ELSE IF(@PSourceTag IS NULL OR @PSourceTag = ''                
 SET @ResponseId = @SectionId;                
END -- IF(@ResponseId =0)                      
SELECT @ResponseId AS SectionId;                            
END 