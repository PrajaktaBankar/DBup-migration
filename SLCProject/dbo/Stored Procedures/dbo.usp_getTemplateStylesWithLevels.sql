CREATE PROCEDURE [dbo].[usp_GetTemplateStylesWithLevels]      
(            
 @customerId INT,          
 @masterDataTypeId INT          
)            
AS            
BEGIN
  
 DECLARE @PcustomerId INT = @customerId;
 DECLARE @PmasterDataTypeId INT = @masterDataTypeId;
SELECT
	S.StyleId
   ,S.Alignment
   ,S.IsBold
   ,S.CharAfterNumber
   ,S.CharBeforeNumber
   ,S.FontName
   ,S.FontSize
   ,S.HangingIndent
   ,S.IncludePrevious
   ,S.IsItalic
   ,S.LeftIndent
   ,S.NumberFormat
   ,S.NumberPosition
   ,S.PrintUpperCase
   ,S.ShowNumber
   ,S.StartAt
   ,S.Strikeout
   ,S.[Name]
   ,S.TopDistance
   ,S.Underline
   ,S.SpaceBelowParagraph
   ,S.IsSystem
   ,S.IsDeleted
   ,TS.[Level]
   ,ISNULL(S.MasterDataTypeId, 0) AS MasterDataTypeId
   ,TS.TemplateId
   ,T.[Name] AS TemplateName
   ,TS.TemplateStyleId INTO #TEMPTABLE
FROM TemplateStyle TS WITH (NOLOCK)
LEFT JOIN Style S WITH (NOLOCK)
	ON S.StyleId = TS.StyleId
LEFT JOIN Template T WITH (NOLOCK)
	ON T.TemplateId = TS.TemplateId
WHERE T.IsDeleted = 0
AND (T.IsSystem = 1
OR T.CustomerId = @PcustomerId) --AND T.masterDataTypeId = @PmasterDataTypeId  
ORDER BY s.Level

SELECT
	*
FROM (SELECT
		*
	FROM #TEMPTABLE
	UNION
	SELECT
		S.StyleId
	   ,S.Alignment
	   ,S.IsBold
	   ,S.CharAfterNumber
	   ,S.CharBeforeNumber
	   ,S.FontName
	   ,S.FontSize
	   ,S.HangingIndent
	   ,S.IncludePrevious
	   ,S.IsItalic
	   ,S.LeftIndent
	   ,S.NumberFormat
	   ,S.NumberPosition
	   ,S.PrintUpperCase
	   ,S.ShowNumber
	   ,S.StartAt
	   ,S.Strikeout
	   ,S.[Name]
	   ,S.TopDistance
	   ,S.Underline
	   ,S.SpaceBelowParagraph
	   ,S.IsSystem
	   ,S.IsDeleted
	   ,S.[Level]
	   ,ISNULL(S.MasterDataTypeId, 0) AS MasterDataTypeId
	   ,0 AS TemplateId
	   ,'' AS TemplateName
	   ,0 AS TemplateStyleId
	FROM Style S WITH (NOLOCK)
	WHERE S.Level IS NOT NULL
	AND S.CustomerId = @PcustomerId
	AND s.StyleId NOT IN (SELECT
			StyleId
		FROM #TEMPTABLE)) AS X
ORDER BY X.[Level], X.[Name]

DROP TABLE #TEMPTABLE
END
GO
