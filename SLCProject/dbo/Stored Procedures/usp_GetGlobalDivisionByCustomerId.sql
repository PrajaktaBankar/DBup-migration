CREATE PROC usp_GetGlobalDivisionByCustomerId          
(@CustomerID INT)          
AS          
BEGIN          
      
DROP TABLE IF EXISTS #customerDivisions;      
 SELECT DivisionId AS SectionId, DivisionCode AS SourceTag, DivisionTitle AS [Description] , CAST('' AS NVARCHAR(100)) AS T_SourceTag, CAST('' AS NVARCHAR(MAX)) AS T_Description      
 INTO #customerDivisions FROM CustomerDivision WITH(NOLOCK)      
  WHERE CustomerId = @CustomerID AND ISNULL(IsDeleted,0) = 0 ORDER BY DivisionCode, DivisionTitle;      
      
 UPDATE #customerDivisions SET T_SourceTag = dbo.udf_ExpandDigits(SourceTag, 5, '0'), T_Description = dbo.udf_ExpandDigits([Description], 16, '0');      
      
 SELECT SectionId, SourceTag, [Description] FROM #customerDivisions ORDER BY T_SourceTag, T_Description;      
END;