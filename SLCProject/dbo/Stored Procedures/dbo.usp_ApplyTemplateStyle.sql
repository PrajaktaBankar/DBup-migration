CREATE PROCEDURE [dbo].[usp_ApplyTemplateStyle]        
@CustomerId INT,      
@TitleFormatId INT,       
@TemplateStyleDtoListJson nvarchar(MAX),      
@templateId INT NULL      
AS    
        
BEGIN    
DECLARE @PCustomerId INT = @CustomerId;    
DECLARE @PTitleFormatId INT = @TitleFormatId;    
DECLARE @PTemplateStyleDtoListJson nvarchar(MAX) = @TemplateStyleDtoListJson;    
DECLARE @PtemplateId INT = @templateId;    
      
DECLARE @oldStyleId INT = NULL;    
      
DECLARE @newStyleId INT = NULL;    
      
DECLARE @counter INT = 1;    
    
--Set Nocount On      
SET NOCOUNT ON;    
      
      
--DECLARE TABLES      
 DECLARE @TemplateStyletbl TABLE(      
 RowId INT,      
 TemplateStyleId INT NULL,          
 TemplateId INT NULL,       
 StyleId   INT NULL,      
 Level INT NULL      
 );    
      
      
 --CONVERT STRING JSONS INTO TABLES      
IF @PTemplateStyleDtoListJson != ''        
BEGIN    
INSERT INTO @TemplateStyletbl (RowId, TemplateStyleId, TemplateId, StyleId, Level)    
 SELECT    
  ROW_NUMBER() OVER (ORDER BY Level ASC) AS RowId    
    ,TemplateStyleId    
    ,TemplateId    
    ,StyleId    
    ,Level    
 FROM OPENJSON(@PTemplateStyleDtoListJson)    
 WITH (    
 TemplateStyleId INT '$.TemplateStyleId',    
 TemplateId INT '$.TemplateId',    
 StyleId INT '$.StyleId',    
 Level INT '$.Level'    
 );    
END    
    
    
UPDATE t    
SET t.TitleFormatId = @PTitleFormatId    
FROM Template t WITH (NOLOCK)    
WHERE t.TemplateId = @PtemplateId;    
    
    
DECLARE @TemplateStyletblRowCount INT = (SELECT    
  COUNT(1)    
 FROM @TemplateStyletbl)    
    
WHILE @counter <= @TemplateStyletblRowCount    
BEGIN    
    
(SELECT    
 @newStyleId = tt.StyleId    
   ,@oldStyleId = T.StyleId    
FROM TemplateStyle T WITH (NOLOCK)    
INNER JOIN @TemplateStyletbl tt    
 ON T.Level = tt.Level    
WHERE T.TemplateId = @PtemplateId    
AND CustomerId = @PCustomerId    
AND T.Level = tt.Level    
AND TT.RowId = @counter    
);    
    
IF (@oldStyleId != @newStyleId    
 AND @oldStyleId IS NOT NULL)    
BEGIN    
DECLARE @isNewStyleAllocated AS INT = (SELECT    
  COUNT(1)    
 FROM TemplateStyle WITH (NOLOCK)    
 WHERE StyleId = @newStyleId);    
IF (@isNewStyleAllocated > 0)    
BEGIN    
    
    
--ALTER TABLE #TEMP DROP COLUMN StyleId;    
    
INSERT INTO Style    
 SELECT    
  Alignment    
    ,IsBold    
    ,CharAfterNumber    
    ,CharBeforeNumber    
    ,FontName    
    ,FontSize    
    ,HangingIndent    
    ,IncludePrevious    
    ,IsItalic    
    ,LeftIndent    
    ,NumberFormat    
    ,NumberPosition    
    ,PrintUpperCase    
    ,ShowNumber    
    ,StartAt    
    ,Strikeout    
    ,Name    
    ,TopDistance    
    ,Underline    
    ,SpaceBelowParagraph    
    ,IsSystem    
    ,CustomerId    
    ,IsDeleted    
    ,CreatedBy    
    ,CreateDate    
    ,ModifiedBy    
    ,ModifiedDate    
    ,Level    
    ,MasterDataTypeId    
    ,A_StyleId    
 ,IsTransferred  
 FROM Style WITH (NOLOCK)    
 WHERE StyleId = @newStyleId;    
    
SET @newStyleId = @@identity;    
        
 END    
    
UPDATE ts    
SET ts.StyleId = @newStyleId    
FROM TemplateStyle ts WITH (NOLOCK)    
WHERE ts.TemplateId = @PtemplateId    
AND ts.StyleId = @oldStyleId;    
    
UPDATE s    
SET s.Level = (SELECT    
  Level    
 FROM TemplateStyle WITH (NOLOCK)    
 WHERE StyleId = @newStyleId)    
FROM Style s WITH (NOLOCK)    
WHERE StyleId = @oldStyleId    
    
UPDATE S    
SET S.IsSystem = 0    
FROM Style S WITH (NOLOCK)    
INNER JOIN TemplateStyle TS WITH (NOLOCK)    
 ON TS.StyleId = S.StyleId    
INNER JOIN Template T WITH (NOLOCK)    
 ON T.TemplateId = TS.TemplateId    
WHERE TS.StyleId = @newStyleId    
AND T.IsSystem = 0    
    
END;    
    
SET @counter = @counter + 1;    
      
END;    
    
    
--call sp to get applied styles      
EXEC usp_GetAppliedStyles @PtemplateId    
    
END 