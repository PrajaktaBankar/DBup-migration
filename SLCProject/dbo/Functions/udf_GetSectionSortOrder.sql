CREATE FUNCTION [dbo].[udf_GetSectionSortOrder](@ProjectId INT, @CustomerId INT, @ParentSectionId INT, @SourceTag NVARCHAR(18), @Author NVARCHAR(MAX))                
RETURNS INT                
AS                
BEGIN                
           
DECLARE @SortOrder INT = 0;          
          
DECLARE @SectionSortOrder TABLE(SourceTag NVARCHAR(18),T_SourceTag NVARCHAR(400), Author NVARCHAR(MAX), SortOrder INT);          
          
INSERT INTO @SectionSortOrder(SourceTag, T_SourceTag, Author, SortOrder) VALUES (@SourceTag, '', @Author, -1);          
          
INSERT INTO @SectionSortOrder(SourceTag, T_SourceTag, Author, SortOrder)          
(SELECT SourceTag, '', Author, SortOrder FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND ParentSectionId = @ParentSectionId AND ISNULL(IsDeleted,0)=0);          
          
UPDATE sso SET sso.T_SourceTag = dbo.udf_ExpandDigits(sso.SourceTag, 18, '0') FROM @SectionSortOrder sso;          
          
DECLARE @SortedSectionOrders TABLE(RowId INT, SourceTag NVARCHAR(18),T_SourceTag NVARCHAR(400), Author NVARCHAR(MAX), SortOrder INT );               
      
-- Get Only distinct records      
DECLARE @Dist_SectionSortOrder TABLE(SourceTag NVARCHAR(18),T_SourceTag NVARCHAR(400), Author NVARCHAR(MAX), SortOrder INT);          
    
INSERT INTO @Dist_SectionSortOrder(SourceTag, T_SourceTag, Author, SortOrder) SELECT distinct * FROM @SectionSortOrder;      
          
INSERT INTO @SortedSectionOrders(RowId, SourceTag, T_SourceTag, Author, SortOrder)          
(SELECT ROW_NUMBER() OVER( ORDER BY T_SourceTag, Author) AS RowId, SourceTag, T_SourceTag, Author, SortOrder FROM @Dist_SectionSortOrder);                
                  
DECLARE @MaxRowId INT = (SELECT MAX(RowId) FROM @SortedSectionOrders);                              
DECLARE @NewSubDivRowId INT = (SELECT TOP 1 RowId FROM @SortedSectionOrders WHERE SourceTag = @SourceTag AND Author = @Author);          
IF(@MaxRowId = 1)                
   SET @SortOrder = 1;                
ELSE IF(@MaxRowId = @NewSubDivRowId)                              
   SET @SortOrder = (SELECT MAX(SortOrder)+1 FROM @SortedSectionOrders);                              
ELSE                               
   SET @SortOrder = (SELECT SortOrder FROM @SortedSectionOrders WHERE RowId = (@NewSubDivRowId + 1));           
          
 RETURN @SortOrder;                
END 