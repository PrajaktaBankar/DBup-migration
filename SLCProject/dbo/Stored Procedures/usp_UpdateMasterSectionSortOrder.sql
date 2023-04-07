CREATE PROCEDURE [dbo].[usp_UpdateMasterSectionSortOrder](@SectionId INT, @ProjectId INT, @CustomerId INT)                              
AS                  
BEGIN        
 DECLARE @USAMasterDataTypeId INT = 1, @CAMasterDataTypeId INT = 4;      
 DECLARE @ProjectMasterDataTypeId INT  = (SELECT MasterDataTypeId FROM Project WITH(NOLOCK) WHERE ProjectId = @ProjectId);      
 DECLARE @ParentSectionId INT, @SourceTag NVARCHAR(18) , @Description NVARCHAR(MAX), @SortOrder INT = -1, @LevelId INT;      
 DECLARE @MaxRowId INT, @NewDivRowId INT, @Author NVARCHAR(500);      
      
SELECT @ParentSectionId = ParentSectionId, @SourceTag = SourceTag , @Description = [Description] , @LevelId = LevelId , @Author = Author FROM ProjectSection WITH(NOLOCK) WHERE SectionId = @SectionId AND ProjectId = @ProjectId;      
    
DROP TABLE IF EXISTS #tDivisions;    
CREATE TABLE #tDivisions        
(        
  Description NVARCHAR(MAX),      
  T_Description NVARCHAR(MAX),      
  SourceTag NVARCHAR(20),     
  T_SourceTag NVARCHAR(400),      
  SortOrder INT,
  Author NVARCHAR(50)
);      
      
DROP TABLE IF EXISTS #SortedDivisions;    
CREATE TABLE #SortedDivisions        
(        
  RowId INT,      
  Description NVARCHAR(MAX),      
  T_Description NVARCHAR(MAX),      
  SourceTag NVARCHAR(20),    
  T_SourceTag NVARCHAR(400),      
  SortOrder INT,
  Author NVARCHAR(50)
  );       
    
INSERT INTO #tDivisions([Description],[T_Description], [SourceTag], [T_SourceTag], [SortOrder], [Author]) VALUES (@Description, '', @SourceTag, '', -1, @Author);      
      
 IF(@ProjectMasterDataTypeId = @USAMasterDataTypeId OR @ProjectMasterDataTypeId = @CAMasterDataTypeId)      
 BEGIN       
 IF(@LevelId = 2) -- Update the Sort Order of Division      
 BEGIN       
        
      
  INSERT INTO #tDivisions([Description],[T_Description], [SourceTag], [T_SourceTag], [SortOrder], [Author])                                                                 
  (select [Description], '',             
   (CASE WHEN (SourceTag = '020' AND (mSectionId = 3000110 OR mSectionId = 105)) THEN '02' ELSE SourceTag END) AS SourceTag , '', SortOrder, Author from ProjectSection WITH(NOLOCK)                                           
    WHERE ProjectId = @ProjectId and ISNULL(IsDeleted,0) =0 and DivisionCode is NULL and LevelId = 2 AND SortOrder iS NOT NULL AND (SourceTag IS NOT NULL AND SourceTag NOT IN ('9','DC')));                                                        
        
  UPDATE dt SET dt.T_SourceTag = UPPER(dbo.udf_ExpandDigits(dt.SourceTag, 18, '0')) , dt.T_Description = UPPER(dbo.udf_ExpandDigits(dt.Description, 20, '0')) FROM #tDivisions dt;                                
                                                                 
  INSERT INTO #SortedDivisions(RowId, [Description],[T_Description], [SourceTag], [T_SourceTag], [SortOrder], [Author])     
  SELECT ROW_NUMBER() OVER(ORDER BY T_SourceTag,Author, T_Description) AS RowId ,[Description], T_Description, SourceTag, T_SourceTag, SortOrder , Author FROM #tDivisions order by T_SourceTag,T_Description;                
                                               
  SET @MaxRowId = (SELECT MAX(RowId) FROM #SortedDivisions);                                                                  
  SET @NewDivRowId = (SELECT TOP 1 RowId FROM #SortedDivisions WHERE [Description] = @Description AND [SourceTag] = @SourceTag AND [Author] = @Author);                                                       
                                                 
  IF(@MaxRowId = @NewDivRowId)    
   SET @SortOrder = (SELECT MAX(SortOrder)+1 FROM #SortedDivisions);                                                                 
  ELSE                                          
   SET @SortOrder = (SELECT SortOrder FROM #SortedDivisions WHERE RowId = (@NewDivRowId + 1));          
        
  UPDATE PS SET SortOrder = SortOrder+1 FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @ProjectId AND LevelId = 2 AND SortOrder >= @SortOrder;      
  UPDATE PS SET SortOrder = @SortOrder FROM ProjectSection PS WITH(NOLOCK) WHERE SectionId = @SectionId AND ProjectId = @ProjectId;      
      
 END      
 ELSE      
 BEGIN      
    
  INSERT INTO #tDivisions([Description],[T_Description], [SourceTag], [T_SourceTag], [SortOrder], [Author])                                                                 
  (select [Description], '', SourceTag , '', SortOrder, Author from ProjectSection WITH(NOLOCK)              
    WHERE ParentSectionId = @ParentSectionId AND ProjectId = @ProjectId AND ISNULL(IsDeleted,0) = 0 and SortOrder IS NOT NULL);                                                        
      
  UPDATE dt SET dt.T_SourceTag = UPPER(dbo.udf_ExpandDigits(dt.SourceTag, 18, '0')) FROM #tDivisions dt;      
      
  INSERT INTO #SortedDivisions(RowId, [Description],[T_Description], [SourceTag], [T_SourceTag], [SortOrder], [Author])                            
  SELECT ROW_NUMBER() OVER(ORDER BY T_SourceTag, Author) AS RowId ,[Description], T_Description, SourceTag, T_SourceTag, SortOrder, Author from #tDivisions order by T_SourceTag;       
    
  SET @MaxRowId = (SELECT MAX(RowId) FROM #SortedDivisions);                                                                  
  SET @NewDivRowId = (SELECT TOP 1 RowId FROM #SortedDivisions WHERE [Description] = @Description AND [SourceTag] = @SourceTag AND [Author] = @Author);                                                       
                                                 
  IF(@MaxRowId = @NewDivRowId)                                                                  
   SET @SortOrder = (SELECT MAX(SortOrder)+1 FROM #SortedDivisions);                                                                 
  ELSE                                          
   SET @SortOrder = (SELECT SortOrder FROM #SortedDivisions WHERE RowId = (@NewDivRowId + 1));          
        
  UPDATE PS SET SortOrder = SortOrder+1 FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @ProjectId AND ParentSectionId = @ParentSectionId AND SortOrder >= @SortOrder;      
  UPDATE PS SET SortOrder = @SortOrder FROM ProjectSection PS WITH(NOLOCK) WHERE SectionId = @SectionId AND ProjectId = @ProjectId;      
              
 END      
 END      
 --ELSE       
 -- Logic for updating the Sort order of NMS project Divisions and SubDivisons will go here when we will implement updates for NMS      
 -- For now we dont have update for NMS projects      
 --BEGIN      
 --END      
 END      