USE [SlcProject]

-- Need to execute on all servers 

GO
--- CREATE FUNCTION TO UPDATE INDIVIDUAL SECTION SORTORDER
CREATE FUNCTION [dbo].[udf_GetSectionSortOrderTemp](@ProjectId INT, @CustomerId INT, @ParentSectionId INT, @SourceTag NVARCHAR(18))              
RETURNS INT              
AS              
BEGIN              
         
DECLARE @SortOrder INT = 0;        
        
DECLARE @SectionSortOrder TABLE(SourceTag NVARCHAR(18),T_SourceTag NVARCHAR(400),SortOrder INT );        
        
INSERT INTO @SectionSortOrder(SourceTag, T_SourceTag, SortOrder) VALUES (@SourceTag, '', -1);        
        
INSERT INTO @SectionSortOrder(SourceTag, T_SourceTag, SortOrder)        
(SELECT SourceTag, '', SortOrder FROM ProjectSection PS WITH(NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND ParentSectionId = @ParentSectionId AND ISNULL(IsDeleted,0)=0 AND SortOrder IS NOT NULL);        
        
UPDATE sso SET sso.T_SourceTag = dbo.udf_ExpandDigits(sso.SourceTag, 18, '0') FROM @SectionSortOrder sso;        
        
DECLARE @SortedSectionOrders TABLE(RowId INT, SourceTag NVARCHAR(18),T_SourceTag NVARCHAR(400),SortOrder INT );             
        
INSERT INTO @SortedSectionOrders(RowId, SourceTag, T_SourceTag, SortOrder)        
(SELECT ROW_NUMBER() OVER( ORDER BY T_SourceTag) AS RowId, SourceTag, T_SourceTag, SortOrder FROM @SectionSortOrder);              
                
DECLARE @MaxRowId INT = (SELECT MAX(RowId) FROM @SortedSectionOrders);                            
DECLARE @NewSubDivRowId INT = (SELECT TOP 1 RowId FROM @SortedSectionOrders WHERE SourceTag = @SourceTag);        
IF(@MaxRowId = 1)              
   SET @SortOrder = 1;              
ELSE IF(@MaxRowId = @NewSubDivRowId)                            
   SET @SortOrder = (SELECT MAX(SortOrder)+1 FROM @SortedSectionOrders);                            
ELSE                             
   SET @SortOrder = (SELECT SortOrder FROM @SortedSectionOrders WHERE RowId = (@NewSubDivRowId + 1));         
        
 RETURN @SortOrder;              
END 
--------------------------------------------------------------------------------------------------------
GO
--------------------------------------------------------------------------------------------------------


DROP TABLE IF EXISTS #ProjectToBeUpdated;
SELECT COUNT(1) AS NullSortOrderSectionCount, ProjectId into #ProjectToBeUpdated FROM ProjectSection where SortOrder IS NULL GROUP BY ProjectId;
DELETE P FROM #ProjectToBeUpdated P INNER JOIN Project PRJ ON P.ProjectId = PRJ.ProjectId WHERE ISNULL(IsPermanentDeleted,0) = 1;

select * from #ProjectToBeUpdated

DROP TABLE IF EXISTS #tSortedSections;

SELECT SectionId ,PS.ProjectId, SourceTag, (ROW_NUMBER() OVER (PARTITION BY PS.ProjectId ORDER BY PS.ProjectId, SourceTag,Author)-1) AS SortOrderId  into #tSortedSections
FROM ProjectSection PS INNER JOIN #ProjectToBeUpdated  t ON PS.ProjectId = t.ProjectId WHERE ISNULL(PS.IsDeleted,0) = 0 AND mSectionId IS NOT NULL
ORDER BY PS.ProjectId , SourceTag, Author;

UPDATE PS SET PS.SortOrder = t.SortOrderId FROM ProjectSection PS WITH(NOLOCK) INNER JOIN  #tSortedSections t 
ON PS.SectionId = t.SectionId;

-- Update sort order of User Sections
DROP TABLE IF EXISTS #sortUserSections;

SELECT SectionId ,PS.ProjectId, PS.CustomerId, PS.parentSectionId, SourceTag, (ROW_NUMBER() OVER (ORDER BY SectionId)) AS RowNumber INTO #sortUserSections
FROM ProjectSection PS INNER JOIN #ProjectToBeUpdated  t ON PS.ProjectId = t.ProjectId WHERE ISNULL(PS.IsDeleted,0) = 0 AND mSectionId IS NULL AND SortOrder IS NULL
ORDER BY PS.ProjectId , SourceTag, Author;

DECLARE @Cnt INT = (SELECT COUNT(1) FROM #sortUserSections), @Cntr INT = 1;
DECLARE @ProjectId INT, @CustomerId INT, @ParentSectionId INT, @SourceTag NVARCHAR(18),@SectionId INT, @SortOrder INT;
WHILE(@Cntr <= @Cnt)
BEGIN

	SELECT @SectionId = SectionId , @ParentSectionId = ParentSectionId, @ProjectId = ProjectId, @CustomerId = CustomerId, @SourceTag =SourceTag 
	FROM #sortUserSections WHERE RowNumber = @Cntr;
	SET @SortOrder = dbo.udf_GetSectionSortOrderTemp(@ProjectId, @CustomerId, @ParentSectionId, @SourceTag);
	UPDATE ProjectSection SET SortOrder = @SortOrder WHERE SectionId = @SectionId;
	SET @Cntr = @Cntr +1;
	
END;

--------------------------------------------------------------------------------------------------------
GO
--------------------------------------------------------------------------------------------------------

DROP FUNCTION [dbo].[udf_GetSectionSortOrderTemp];
