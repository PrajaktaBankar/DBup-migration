CREATE PROCEDURE [dbo].[usp_GetViewReportTagsPanelInfo] (@ProjectId INT, @SectionId INT, @CustomerId INT)      
AS      
BEGIN  
    
  DECLARE @PProjectId INT = @ProjectId;  
  DECLARE @PSectionId INT = @SectionId;  
  DECLARE @PCustomerId INT = @CustomerId;  
  
DECLARE @SF_SpecTypeTagId INT = 1;  
    
DECLARE @OL_SpecTypeTagId INT = 2;  
    
DECLARE @UO_SpecTypeTagId INT = 3;  
    
DECLARE @US_SpecTypeTagId INT = 4;  
    
    
DECLARE @ViewTagTbl TABLE (    
 TagType NVARCHAR(MAX),    
 TagName NVARCHAR(MAX),    
 SegmentStatusCount INT,    
 SpecTypeTagId INT    
);  
    
    
DECLARE @ReportTagTbl TABLE(    
 TagType NVARCHAR(MAX),    
 TagName NVARCHAR(MAX),    
 SegmentStatusCount INT,    
 IsUserTag BIT,    
 RequirementTagId INT,    
 UserTagId INT,    
 IsSystemTag BIT,    
 CreateDate DATETIME2(7) NULL    
);  
  
--INSERT VALUES IN ViewTag TABLE    
INSERT INTO @ViewTagTbl (TagType, TagName, SegmentStatusCount, SpecTypeTagId)  
 VALUES ('Short Form', 'Short Form', 0, @SF_SpecTypeTagId), ('Outline', 'Outline Form', 0, @OL_SpecTypeTagId);  
  
--INSERT VALUES IN ReportTag TABLE    
INSERT INTO @ReportTagTbl (TagType, TagName, SegmentStatusCount, IsUserTag, RequirementTagId, UserTagId, IsSystemTag, CreateDate)  
 SELECT  
  LPRT.TagType  
    ,LPRT.Description  
    ,0 AS SegmentStatusCount  
    ,0 AS IsUserTag  
    ,LPRT.RequirementTagId  
    ,0 AS UserTagId  
    ,1 AS IsSystemTag  
    ,NULL AS CreateDate  
 FROM LuProjectRequirementTag LPRT WITH (NOLOCK)  
 WHERE LPRT.IsActive = 1  
 UNION  
 SELECT  
  PUT.TagType  
    ,PUT.Description  
    ,0 AS SegmentStatusCount  
    ,1 AS IsUserTag  
    ,0 AS RequirementTagId  
    ,PUT.UserTagId  
    ,PUT.IsSystemTag  
    ,PUT.CreateDate  
 FROM ProjectUserTag PUT WITH (NOLOCK)  
 WHERE PUT.CustomerId = @PCustomerId  
 AND PUT.IsDeleted=0
  
--UPDATE COUNT OF VIEW TAGS IN TABLE    
UPDATE VTBL  
SET VTBL.SegmentStatusCount = X.SegmentStatusCount  
FROM @ViewTagTbl VTBL  
INNER JOIN (SELECT  
  PSST.SpecTypeTagId  
    ,COUNT(*) AS SegmentStatusCount  
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)  
 WHERE PSST.ProjectId = @PProjectId  
 AND PSST.SectionId = @PSectionId  
 AND PSST.CustomerId = @PCustomerId  
 AND ISNULL(PSST.IsDeleted,0)=0    
 AND PSST.SpecTypeTagId IS NOT NULL  
 AND PSST.SpecTypeTagId IN (@OL_SpecTypeTagId, @SF_SpecTypeTagId)  
 GROUP BY PSST.SpecTypeTagId) AS X  
 ON VTBL.SpecTypeTagId = X.SpecTypeTagId  
  
--NOTE: UPDATE COUNT OF UO IN OL && US IN SF    
UPDATE VTBL  
SET VTBL.SegmentStatusCount = VTBL.SegmentStatusCount + X.SegmentStatusCount  
FROM @ViewTagTbl VTBL  
INNER JOIN (SELECT  
  PSST.SpecTypeTagId  
    ,COUNT(*) AS SegmentStatusCount  
 FROM ProjectSegmentStatus PSST WITH (NOLOCK)  
 WHERE PSST.ProjectId = @PProjectId  
 AND PSST.SectionId = @PSectionId  
 AND PSST.CustomerId = @PCustomerId  
 AND ISNULL(PSST.IsDeleted,0)=0    
 AND PSST.SpecTypeTagId IS NOT NULL  
 AND PSST.SpecTypeTagId IN (@UO_SpecTypeTagId, @US_SpecTypeTagId)  
 GROUP BY PSST.SpecTypeTagId) AS X  
 ON VTBL.SpecTypeTagId = (CASE  
  WHEN X.SpecTypeTagId = @UO_SpecTypeTagId THEN @OL_SpecTypeTagId  
  ELSE @SF_SpecTypeTagId  
 END)  
  
--UPDATE COUNT OF REQUIREMENT TAGS IN REPORT TAG TABLE    
UPDATE RTBL  
SET RTBL.SegmentStatusCount = X.SegmentStatusCount  
FROM @ReportTagTbl RTBL  
INNER JOIN (SELECT  
  PSRT.RequirementTagId  
    ,COUNT(*) AS SegmentStatusCount  
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
 INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)  
  ON PSRT.SegmentStatusId = PSST.SegmentStatusId  
  AND PSRT.ProjectId = PSST.ProjectId  
  AND PSRT.CustomerId = PSST.CustomerId  
 INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)  
  ON PSRT.RequirementTagId = LPRT.RequirementTagId  
 WHERE PSRT.ProjectId = @PProjectId  
 AND PSRT.SectionId = @PSectionId  
 AND PSRT.CustomerId = @PCustomerId  
 AND ISNULL(PSST.IsDeleted,0)=0    
 AND ISNULL(PSRT.IsDeleted,0)=0  
 GROUP BY PSRT.RequirementTagId) AS X  
 ON RTBL.RequirementTagId = X.RequirementTagId  
  
--UPDATE COUNT OF USER TAGS IN REPORT TAG TABLE    
UPDATE RTBL  
SET RTBL.SegmentStatusCount = X.SegmentStatusCount  
FROM @ReportTagTbl RTBL  
INNER JOIN (SELECT  
  PSUT.UserTagId  
    ,COUNT(*) AS SegmentStatusCount  
 FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)  
 INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)  
  ON PSUT.SegmentStatusId = PSST.SegmentStatusId  
  AND PSUT.ProjectId = PSST.ProjectId  
  AND PSUT.CustomerId = PSST.CustomerId  
 INNER JOIN ProjectUserTag PUT WITH (NOLOCK)  
  ON PSUT.UserTagId = PUT.UserTagId  
  AND PSUT.CustomerId = PUT.CustomerId  
 WHERE PSUT.ProjectId = @PProjectId  
 AND PSUT.SectionId = @PSectionId  
 AND PSUT.CustomerId = @PCustomerId  
 AND PUT.IsDeleted=0
 AND (PSST.IsDeleted IS NULL  
 OR PSST.IsDeleted = 0)  
 GROUP BY PSUT.UserTagId) AS X  
 ON RTBL.UserTagId = X.UserTagId  
  
SELECT  
 *  
FROM @ViewTagTbl  
  
SELECT  
 *  
FROM @ReportTagTbl  
END;