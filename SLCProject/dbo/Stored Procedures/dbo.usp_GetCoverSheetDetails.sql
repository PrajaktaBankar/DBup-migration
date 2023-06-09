CREATE PROCEDURE [dbo].[usp_GetCoverSheetDetails]         
 @ProjectId INT,            
 @CustomerID INT          
AS            
BEGIN      
        
 DECLARE @PProjectId INT = @ProjectId;      
        
 DECLARE @PCustomerID INT = @CustomerID;      
         

 DECLARE @ActiveSectionCount INT=0;      
        
 DECLARE @Temp NVARCHAR(50)      
      
--Set @ActiveSectionCount        
SET @ActiveSectionCount = (SELECT      
  COUNT(PS.SectionId) AS OpenSectionCount      
 FROM ProjectSection PS WITH (NOLOCK)      
 INNER JOIN ProjectSegmentStatus PSS WITH (NOLOCK)      
  ON PS.SectionId = PSS.SectionId     
  AND PS.ProjectId=PSS.ProjectId 
 WHERE  PS.ProjectId = @PProjectId  
 --AND PS.CustomerId = @CustomerID
 AND ISNULL(PSS.ParentSegmentStatusId,0)=0
 AND PSS.IndentLevel = 0      
 AND PS.IsLastLevel = 1      
 AND PSS.SequenceNumber = 0      
 AND ISNULL(PS.IsDeleted,0) = 0      
 AND PSS.SegmentStatusTypeId < 6      
 GROUP BY PS.ProjectId);      
--Selects Project Deatils            
SELECT     
 P.[Name] as ProjectName     
   ,P.ProjectId as ProjectNumber     
   ,CASE      
  WHEN LC.city = 'Undefined' THEN PA.CityName   
  ELSE LC.city      
 END AS city      
   ,CASE      
  WHEN LSP.StateProvinceName = 'Undefined' THEN PA.StateProvinceName     
  ELSE LSP.StateProvinceName      
 END AS State      
   ,LCO.CountryName  as Country    
   ,LF.[Description] AS WorkType      
   ,LP.[Description] AS ProjectType      
   ,LPS.SizeDescription AS Size      
   ,LPC.CostDescription AS Cost      
   ,P.CreateDate    as CreatedDate  
   ,ISNULL(@ActiveSectionCount,0) AS ActiveSectionCount      
   ,CASE      
  WHEN LPU.ProjectUoMId = 1 THEN 'm²'      
  WHEN LPU.ProjectUoMId = 2 THEN 'sq.ft.'      
 END AS SizeAbbreviation      
   ,LPU.ProjectUoMId      
   ,PS.SourceTagFormat      
   ,LCO.CurrencyAbbreviation    
FROM PROJECT P WITH (NOLOCK)      
INNER JOIN [ProjectSummary] PS WITH (NOLOCK)      
 ON PS.ProjectId = P.projectId      
INNER JOIN [ProjectAddress] PA WITH (NOLOCK)      
 ON PA.PROJECTID = P.PROJECTID      
INNER JOIN LuCountry LCO WITH (NOLOCK)      
 ON LCO.CountryId = PA.CountryId      
INNER JOIN Lucity LC WITH (NOLOCK)      
 ON LC.cityId = (CASE  
    WHEN PA.cityId IS NULL THEN '99999999'  
    ELSE PA.cityId   
 END)  
INNER JOIN LuStateProvince LSP WITH (NOLOCK)      
 ON LSP.StateProvinceID =  (CASE  
    WHEN PA.StateProvinceId IS NULL THEN '99999999'  
    ELSE PA.StateProvinceId   
 END)  
  
INNER JOIN LuFacilityType LF WITH (NOLOCK)      
 ON LF.FacilityTypeId = PS.FacilityTypeId      
INNER JOIN LuProjectType LP WITH (NOLOCK)      
 ON LP.ProjectTypeId = PS.ProjectTypeId      
INNER JOIN LuProjectSize LPS WITH (NOLOCK)      
 ON LPS.SizeId = PS.ActualSizeId      
INNER JOIN LuProjectCost LPC WITH (NOLOCK)      
 ON LPC.CostId = PS.ActualCostId      
INNER JOIN LuProjectUoM LPU WITH (NOLOCK)      
 ON LPU.ProjectUoMId = PS.SizeUoM      
--INNER JOIN ProjectSummary PSM ON PSM.ProjectId = P.ProjectId            
WHERE P.ProjectId = @PProjectId      
AND P.CustomerId = @PCustomerId      
END
