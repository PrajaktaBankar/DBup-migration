CREATE PROCEDURE [dbo].[usp_getTemplateStyles]      
(          
 @templateId INT,      
 @customerId INT      
)      
AS          
BEGIN
 DECLARE @PtemplateId INT = @templateId;
 DECLARE @PcustomerId INT = @customerId;

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
   ,S.MasterDataTypeId
   ,TS.TemplateId
   ,T.[Name] AS TemplateName
   ,TS.TemplateStyleId
   ,ISNULL(STPLS.DefaultSpacesId, 0) AS DefaultSpacesId
   ,ISNULL(STPLS.BeforeSpacesId, 0) AS BeforeSpacesId
   ,ISNULL(STPLS.AfterSpacesId, 0) AS AfterSpacesId
   ,ISNULL(STPLS.CustomLineSpacing, 0) AS CustomLineSpacing
FROM TemplateStyle TS WITH (NOLOCK)
LEFT JOIN Style S WITH (NOLOCK)
	ON S.StyleId = TS.StyleId
LEFT JOIN Template T WITH (NOLOCK)
	ON T.TemplateId = TS.TemplateId
LEFT JOIN [StyleParagraphLineSpace] STPLS WITH (NOLOCK)
	ON S.StyleId = STPLS.StyleId
WHERE TS.TemplateId = @PtemplateId
AND TS.CustomerId = @PcustomerId
--AND T.IsSystem = 0
ORDER BY TS.Level ASC
END


GO
