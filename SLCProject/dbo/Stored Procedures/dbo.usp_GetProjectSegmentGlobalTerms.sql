

CREATE PROCEDURE [dbo].[usp_GetProjectSegmentGlobalTerms]
@UserGlobalTermId INT NULL,  
@CustomerId INT NULL,  
@ProjectId INT NULL=NULL  
AS         
BEGIN  
    
DECLARE @PUserGlobalTermId INT = @UserGlobalTermId;  
DECLARE @PCustomerId INT = @CustomerId;  
DECLARE @PProjectId INT = @ProjectId;  
  
SET NOCOUNT ON;  
  
--FIND INSTANCES USED IN SEGMENTS    
SELECT  
DISTINCT  
 PSSTV.CustomerId  
   ,PSGT.UserGlobalTermId  
   ,0 AS GlobalTermCode --NOTE: No need of this value in final result    
   ,PSSTV.SegmentId  
   ,0 AS HeaderId  
   ,0 AS FooterId  
   ,'Segment' AS GlobalTermUsedIn  
   ,PSGT.ProjectId INTO #UsedGTTbl  
FROM ProjectSegmentGlobalTerm PSGT WITH (NOLOCK)  
INNER JOIN ProjectSegment PSSTV WITH (NOLOCK)  
 ON PSGT.SegmentId = PSSTV.SegmentId  
INNER JOIN PROJECTSECTION PS WITH (NOLOCK)  
 ON PS.SECTIONID=PSGT.SECTIONID  
WHERE PSSTV.CustomerId = @PCustomerId  
AND ISNULL(PSSTV.IsDeleted,0) = 0  
AND PSGT.UserGlobalTermId = @PUserGlobalTermId  
AND ISNULL(PSGT.IsDeleted,0) = 0  
AND ISNULL(PS.ISDELETED,0)=0  
UNION  
--FIND INSTANCES USED IN HEADER/FOOTER    
SELECT DISTINCT  
 HFGTU.CustomerId  
   ,HFGTU.UserGlobalTermId  
   ,0 AS GlobalTermCode --NOTE: No need of this value in final result    
   ,0 AS SegmentId  
   ,ISNULL(HFGTU.HeaderId, 0) AS HeaderId  
   ,ISNULL(HFGTU.FooterId, 0) AS FooterId  
   ,(CASE  
  WHEN HFGTU.HeaderId IS NOT NULL AND  
   HFGTU.HeaderId > 0 THEN 'Header'  
  WHEN HFGTU.FooterId IS NOT NULL AND  
   HFGTU.FooterId > 0 THEN 'Footer'  
  ELSE ''  
 END) AS GlobalTermUsedIn  
   ,HFGTU.ProjectId  
FROM HeaderFooterGlobalTermUsage HFGTU WITH (NOLOCK)  
WHERE HFGTU.CustomerId = @PCustomerId  
AND HFGTU.UserGlobalTermId = @PUserGlobalTermId  
  
--SELECT * from #UsedGTTbl  
--Added this change to filter used GT from Permanently Deleted Projects  
SELECT  
 UGT.*  
FROM #UsedGTTbl UGT  
INNER JOIN Project P with (nolock)  
 ON P.ProjectId = UGT.ProjectId  
WHERE ISNULL( P.IsPermanentDeleted,0) = 0  
OR ISNULL( P.IsDeleted ,0)= 0  
  
END  

GO



