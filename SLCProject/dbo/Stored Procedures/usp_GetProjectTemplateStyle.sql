CREATE PROCEDURE usp_GetProjectTemplateStyle    
@ProjectId INT,    
@SectionId INT,    
@CustomerId INT    
AS    
BEGIN    
SET NOCOUNT ON;    
    
--FIND TEMPLATE ID FROM                         
DECLARE @ProjectTemplateId AS INT = (SELECT TOP 1 ISNULL(TemplateId, 1) FROM Project WITH (NOLOCK) WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId);                      
DECLARE @SectionTemplateId AS INT = ( SELECT TOP 1 TemplateId FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @SectionId);    
DECLARE @DocumentTemplateId INT = 0;    
                      
IF (@SectionTemplateId IS NOT NULL AND @SectionTemplateId > 0)                      
 BEGIN                      
  SET @DocumentTemplateId = @SectionTemplateId;    
 END                        
ELSE                        
 BEGIN                      
  SET @DocumentTemplateId = @ProjectTemplateId;                      
 END         
----GET TEMPLATE    
SELECT                     
 TemplateId                      
   ,Name                      
   ,TitleFormatId                      
   ,SequenceNumbering                      
   ,IsSystem                      
   ,IsDeleted                      
   ,ISNULL(@ProjectTemplateId, 0) AS ProjectTemplateId                      
   ,ISNULL(@SectionTemplateId, 0) AS SectionTemplateId         
   ,ApplyTitleStyleToEOS                
FROM Template WITH (NOLOCK)                      
WHERE TemplateId = @DocumentTemplateId;    
    
----GET TEMPLATE STYLE    
SELECT                      
    ts.TemplateStyleId                      
   ,ts.TemplateId                      
   ,ts.StyleId                      
   ,ts.Level
   ,ISNULL(t.ApplyTitleStyleToEOS,0) As  ApplyTitleStyleToEOS                     
FROM TemplateStyle ts WITH (NOLOCK)  
INNER JOIN Template t WITH(NOLOCK)
ON ts.TemplateId = t.TemplateId                    
WHERE ts.TemplateId = @DocumentTemplateId;       
    
----GET  STYLE    
SELECT    
   ST.StyleId,    
   ST.Alignment,    
   ST.IsBold,    
   ST.CharAfterNumber,    
   ST.CharBeforeNumber,    
   ST.FontName,    
   ST.FontSize,    
   ST.HangingIndent,    
   ST.IncludePrevious,    
   ST.IsItalic,    
   ST.LeftIndent,    
   ST.NumberFormat,    
   ST.NumberPosition,    
   ST.PrintUpperCase,    
   ST.ShowNumber,    
   ST.StartAt,    
   ST.Strikeout,    
   ST.Name,    
   ST.TopDistance,    
   ST.Underline,    
   ST.SpaceBelowParagraph,    
   ST.IsSystem,    
   ST.IsDeleted,    
   CAST(TST.Level AS INT) AS Level    
FROM    
   Style AS ST WITH (NOLOCK)    
   INNER JOIN TemplateStyle AS TST WITH (NOLOCK)     
   ON ST.StyleId = TST.StyleId    
WHERE TST.TemplateId = @DocumentTemplateId;    
    
END  