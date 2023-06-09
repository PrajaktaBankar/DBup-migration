CREATE PROCEDURE [dbo].[usp_GetProjectPageSettings]      
 @ProjectId INT NULL,        
 @CustomerId INT NULL,    
 @SectionId INT NULL    
AS          
BEGIN    
        
DECLARE @PProjectId INT = @ProjectId;    
DECLARE @PCustomerId INT = @CustomerId;    
DECLARE @PSectionId INT = @SectionId;    
    
DECLARE @HasProjectPageSetting AS BIT = 0;    
DECLARE @HasSectionPageSetting AS BIT = 0;    
    
SET @HasProjectPageSetting = COALESCE((SELECT 1 FROM ProjectPageSetting WITH (NOLOCK) WHERE ProjectId = @PProjectId AND     
        CustomerId = @PCustomerId AND SectionId IS NULL),0)    
SET @HasSectionPageSetting = COALESCE((SELECT 1 FROM ProjectPageSetting WITH (NOLOCK) WHERE ProjectId = @PProjectId AND     
        CustomerId = @PCustomerId AND SectionId = @PSectionId),0)    
    
    
IF(@PSectionId IS NOT NULL AND @PSectionId > 0     
 AND EXISTS (SELECT 1 FROM ProjectPageSetting WITH (NOLOCK) WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId    
  AND SectionId = @PSectionId))    
 BEGIN    
  SELECT    
   PP.ProjectId    
     ,PP.CustomerId    
     ,PP.MarginTop    
     ,PP.MarginBottom    
     ,PP.MarginLeft    
     ,PP.MarginRight    
     ,PP.EdgeHeader    
     ,PP.EdgeFooter    
     ,PP.IsMirrorMargin    
     ,PS.PaperName    
     ,PS.PaperWidth    
     ,PS.PaperHeight    
     ,PS.PaperOrientation    
     ,PS.PaperSource    
     ,@HasProjectPageSetting AS HasProjectPageSetting     
     ,@HasSectionPageSetting AS HasSectionPageSetting     
  FROM ProjectPageSetting PP WITH (NOLOCK)    
  INNER JOIN ProjectPaperSetting PS WITH (NOLOCK)    
   ON PP.ProjectId = PS.ProjectId    
   AND PP.SectionId = PS.SectionId    
  WHERE PP.ProjectId = @PProjectId    
  AND PP.CustomerId = @PCustomerId    
  AND PP.SectionId = @PSectionId    
 END    
 ELSE    
 BEGIN    
  SELECT    
   PP.ProjectId    
     ,PP.CustomerId    
     ,PP.MarginTop    
     ,PP.MarginBottom    
     ,PP.MarginLeft    
     ,PP.MarginRight    
     ,PP.EdgeHeader    
     ,PP.EdgeFooter    
     ,PP.IsMirrorMargin    
     ,PS.PaperName    
     ,PS.PaperWidth    
     ,PS.PaperHeight    
     ,PS.PaperOrientation    
     ,PS.PaperSource    
     ,@HasProjectPageSetting AS HasProjectPageSetting     
     ,@HasSectionPageSetting AS HasSectionPageSetting     
  FROM ProjectPageSetting PP WITH (NOLOCK)    
  INNER JOIN ProjectPaperSetting PS WITH (NOLOCK)    
   ON PP.ProjectId = PS.ProjectId    
  WHERE PP.ProjectId = @PProjectId    
  AND PP.CustomerId = @PCustomerId   
  AND PP.SectionId IS NULL  
   AND PS.SectionId IS NULL   
 END    
END 