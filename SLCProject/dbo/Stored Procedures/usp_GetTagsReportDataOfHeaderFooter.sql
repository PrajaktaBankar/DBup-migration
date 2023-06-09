CREATE PROCEDURE [dbo].[usp_GetTagsReportDataOfHeaderFooter]           
(          
@ProjectId INT,          
@CustomerId INT,          
@CatalogueType NVARCHAR(MAX)='FS',          
@TCPrintModeId INT = 1  
)              
AS              
BEGIN  
    
    
DECLARE @PProjectId INT = @ProjectId;  
    
DECLARE @PCustomerId INT = @CustomerId;  
    
DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;  
    
    
DECLARE @OldKeywordFormat NVARCHAR(MAX) = '{\kw\';  
    
DECLARE @NewKeywordFormat NVARCHAR(MAX) = '{KW#';  

 DECLARE @ImagSegment int =1
 DECLARE @ImageHeaderFooter int =3
    
    
DECLARE @MasterDataTypeId INT = ( SELECT  
  P.MasterDataTypeId  
 FROM Project P with(NOLOCK)  
 WHERE P.ProjectId = @PProjectId  
 AND P.CustomerId = @PCustomerId);  
  
  
--SELECT GLOBAL TERM DATA               
SELECT
@PProjectId AS ProjectId 
,@PCustomerId as CustomerId 
 ,PGT.GlobalTermId  
   ,COALESCE(PGT.mGlobalTermId, 0) AS mGlobalTermId  
   ,PGT.Name  
   ,ISNULL(PGT.value, '') AS value  
   ,PGT.CreatedDate  
   ,PGT.CreatedBy  
   ,PGT.ModifiedDate  
   ,PGT.ModifiedBy  
   ,PGT.GlobalTermSource  
   ,PGT.GlobalTermCode  
   ,COALESCE(PGT.UserGlobalTermId, 0) AS UserGlobalTermId  
   ,GlobalTermFieldTypeId as GTFieldType  
FROM ProjectGlobalTerm PGT WITH (NOLOCK)  
WHERE PGT.ProjectId = @PProjectId  
AND PGT.CustomerId = @PCustomerId;  

--SELECT Image DATA
SELECT     
  PIMG.SegmentImageId    
 ,IMG.ImageId    
 ,IMG.ImagePath    
 ,COALESCE(PIMG.ImageStyle,'') as ImageStyle   
 ,PIMG.SectionId     
 ,ISNULL(IMG.LuImageSourceTypeId ,0) AS LuImageSourceTypeId   
 FROM ProjectSegmentImage PIMG WITH (NOLOCK)          
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PIMG.ImageId = IMG.ImageId          
 WHERE PIMG.ProjectId = @PProjectId          
  AND PIMG.CustomerId = @PCustomerId          
  AND IMG.LuImageSourceTypeId IN(@ImagSegment,@ImageHeaderFooter) 
  
  
--SELECT Project Summary information          
SELECT  
 P.ProjectId AS ProjectId  
   ,P.Name AS ProjectName  
   ,'' AS ProjectLocation  
   ,PS.IsPrintReferenceEditionDate AS IsPrintReferenceEditionDate  
   ,PS.SourceTagFormat AS SourceTagFormat  
   ,CONCAT(LState.StateProvinceAbbreviation, ', ', LCity.City) AS DbInfoProjectLocationKeyword  
   ,ISNULL(PGT.value, '') AS ProjectLocationKeyword  
   ,PS.UnitOfMeasureValueTypeId  
FROM Project P with(NOLOCK)  
INNER JOIN ProjectSummary PS WITH (NOLOCK)  
 ON P.ProjectId = PS.ProjectId  
INNER JOIN ProjectAddress PA WITH (NOLOCK)  
 ON P.ProjectId = PA.ProjectId  
INNER JOIN LuCountry LCountry WITH (NOLOCK)  
 ON PA.CountryId = LCountry.CountryId  
INNER JOIN LuStateProvince LState WITH (NOLOCK)  
 ON PA.StateProvinceId = LState.StateProvinceID  
  AND PA.CountryId = LState.CountryId  
INNER JOIN LuCity LCity WITH (NOLOCK)  
 ON PA.CityId = LCity.CityId  
  AND PA.StateProvinceId = LCity.StateProvinceID  
LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK)  
 ON P.ProjectId = PGT.ProjectId  
  AND PGT.mGlobalTermId = 11  
WHERE P.ProjectId = @PProjectId  
AND P.CustomerId = @PCustomerId  
  
--SELECT Header/Footer information                    
IF EXISTS (SELECT  
  TOP 1  
   1  
  FROM Header with(NOLOCK)  
  WHERE ProjectId = @PProjectId  
  AND CustomerId = @PCustomerId  
  AND DocumentTypeId = 2)  
BEGIN  
SELECT  
 H.HeaderId  
   ,ISNULL(H.ProjectId, @PProjectId) AS ProjectId  
   ,ISNULL(H.SectionId, 0) AS SectionId  
   ,ISNULL(H.CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL(H.TypeId, 1) AS TypeId  
   ,H.DateFormat  
   ,H.TimeFormat  
   ,ISNULL(H.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId  
   ,REPLACE(ISNULL(H.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader  
   ,REPLACE(ISNULL(H.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader  
   ,REPLACE(ISNULL(H.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader  
   ,REPLACE(ISNULL(H.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader  
   ,H.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId 
   ,H.IsShowLineAboveHeader AS IsShowLineAboveHeader
   ,H.IsShowLineBelowHeader AS IsShowLineBelowHeader
FROM Header H with(NOLOCK)  
WHERE H.ProjectId = @PProjectId  
AND H.CustomerId = @PCustomerId  
AND H.DocumentTypeId = 2  
END  
ELSE  
BEGIN  
SELECT  
 H.HeaderId  
   ,ISNULL(H.ProjectId, @PProjectId) AS ProjectId  
   ,ISNULL(H.SectionId, 0) AS SectionId  
   ,ISNULL(H.CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL(H.TypeId, 1) AS TypeId  
   ,H.DateFormat  
   ,H.TimeFormat  
   ,ISNULL(H.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId  
   ,REPLACE(ISNULL(H.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader  
   ,REPLACE(ISNULL(H.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader  
   ,REPLACE(ISNULL(H.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader  
   ,REPLACE(ISNULL(H.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader  
   ,H.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId  
   ,H.IsShowLineAboveHeader AS IsShowLineAboveHeader
   ,H.IsShowLineBelowHeader AS IsShowLineBelowHeader
FROM Header H with(NOLOCK)  
WHERE H.ProjectId IS NULL  
AND H.CustomerId IS NULL  
AND H.SectionId IS NULL  
AND H.DocumentTypeId = 2  
END  
IF EXISTS (SELECT  
  TOP 1  
   1  
  FROM Footer with(NOLOCK)  
  WHERE ProjectId = @PProjectId  
  AND CustomerId = @PCustomerId  
  AND DocumentTypeId = 2)  
BEGIN  
SELECT  
 F.FooterId  
   ,ISNULL(F.ProjectId, @PProjectId) AS ProjectId  
   ,ISNULL(F.SectionId, 0) AS SectionId  
   ,ISNULL(F.CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL(F.TypeId, 1) AS TypeId  
   ,F.DateFormat  
   ,F.TimeFormat  
   ,ISNULL(F.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId  
   ,REPLACE(ISNULL(F.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter  
   ,REPLACE(ISNULL(F.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter  
   ,REPLACE(ISNULL(F.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter  
   ,REPLACE(ISNULL(F.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter  
   ,F.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId  
   ,F.IsShowLineAboveFooter AS IsShowLineAboveFooter
   ,F.IsShowLineBelowFooter AS IsShowLineBelowFooter
  
FROM Footer F WITH (NOLOCK)  
WHERE F.ProjectId = @PProjectId  
AND F.CustomerId = @PCustomerId  
AND F.DocumentTypeId = 2  
END  
ELSE  
BEGIN  
SELECT  
 F.FooterId  
   ,ISNULL(F.ProjectId, @PProjectId) AS ProjectId  
   ,ISNULL(F.SectionId, 0) AS SectionId  
   ,ISNULL(F.CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL(F.TypeId, 1) AS TypeId  
   ,F.DateFormat  
   ,F.TimeFormat  
   ,ISNULL(F.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId  
   ,REPLACE(ISNULL(F.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter  
   ,REPLACE(ISNULL(F.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter  
   ,REPLACE(ISNULL(F.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter  
   ,REPLACE(ISNULL(F.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter  
   ,F.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId  
   ,F.IsShowLineAboveFooter AS IsShowLineAboveFooter
   ,F.IsShowLineBelowFooter AS IsShowLineBelowFooter
FROM Footer F WITH(NOLOCK)  
WHERE F.ProjectId IS NULL  
AND F.CustomerId IS NULL  
AND F.SectionId IS NULL  
AND F.DocumentTypeId = 2  
END  

 --SELECT PageSetup INFORMATION                                                                                                
 SELECT PageSetting.ProjectPageSettingId AS ProjectPageSettingId                                                            
  ,PaperSetting.ProjectPaperSettingId AS ProjectPaperSettingId                                                                            
  ,ISNULL(PageSetting.MarginTop, 1.00) AS MarginTop                                                                            
  ,ISNULL(PageSetting.MarginBottom, 1.00) AS MarginBottom                                                     
  ,ISNULL(PageSetting.MarginLeft, 1.00) AS MarginLeft                                                                            
  ,ISNULL(PageSetting.MarginRight, 1.00) AS MarginRight                                                                           
  ,ISNULL(PageSetting.EdgeHeader, 0.05) AS EdgeHeader                                    
  ,ISNULL(PageSetting.EdgeFooter, 0.05) AS EdgeFooter                                                                            
  ,PageSetting.IsMirrorMargin AS IsMirrorMargin                                                            
  ,PageSetting.ProjectId AS ProjectId                                                                            
  ,PageSetting.CustomerId AS CustomerId                                                                            
  ,COALESCE(PaperSetting.PaperName,'A4') AS PaperName                                                                            
  ,ISNULL(PaperSetting.PaperWidth, 0.00) AS PaperWidth                                                                            
  ,ISNULL(PaperSetting.PaperHeight, 0.00) AS PaperHeight                                                                            
  ,COALESCE(PaperSetting.PaperOrientation,'') AS PaperOrientation                 
  ,COALESCE(PaperSetting.PaperSource,'') AS PaperSource     
  ,ISNULL(PageSetting.SectionId,0) As SectionId
  ,ISNULL(PageSetting.TypeId,1) As  TypeId                                                                     
 FROM ProjectPageSetting PageSetting WITH (NOLOCK)                                                               
 INNER JOIN ProjectPaperSetting PaperSetting WITH (NOLOCK) 
 ON PageSetting.ProjectId = PaperSetting.ProjectId    
 AND ISNULL(PageSetting.SectionId,0) =  ISNULL(PaperSetting.SectionId,0)                                                                        
 WHERE PageSetting.ProjectId = @PProjectId  
END