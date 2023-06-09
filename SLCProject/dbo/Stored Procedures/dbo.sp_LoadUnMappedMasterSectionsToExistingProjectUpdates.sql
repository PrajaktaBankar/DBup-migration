CREATE PROCEDURE [dbo].[sp_LoadUnMappedMasterSectionsToExistingProjectUpdates]    
@ProjectId int  
AS   
BEGIN  
DECLARE @PProjectId int = @ProjectId;  
--Set NOCOUNT ON  
SET NOCOUNT ON;  
  
--CREATE TABLE FOR UNCOPIED MASTER SECTIONS INTO PROJECT   
DECLARE @UncopiedMasterSections TABLE(ProjectId INT, mSectionId INT,SourceTag VARCHAR(10),CustomerId INT, UserId INT NULL);  
DECLARE @CustomerId INT=( SELECT TOP 1  
  customerId  
 FROM Project WITH (NOLOCK)  
 WHERE ProjectId = @PProjectId)  
--FETCH THOSE UNCOPIED MASTER SECTIONS  
INSERT INTO @UncopiedMasterSections (ProjectId, mSectionId, SourceTag, CustomerId)  
 SELECT	  
  P.ProjectId  
    ,MS.SectionId AS mSectionId  
    ,MS.SourceTag  
    ,P.CustomerId  
 FROM SLCMaster..Section MS WITH (NOLOCK)  
 INNER JOIN Project P WITH (NOLOCK)  
  ON MS.MasterDataTypeId = P.MasterDataTypeId  
 LEFT JOIN ProjectSection PS WITH (NOLOCK)  
  ON P.ProjectId = PS.ProjectId  
   AND MS.SectionId = PS.mSectionId  
 WHERE MS.MasterDataTypeId = 1  
 AND MS.IsDeleted = 0  
 AND PS.SectionId IS NULL  
 AND P.ProjectId = @PProjectId  
 AND P.CustomerId = @CustomerId  
 GROUP BY P.ProjectId  
   ,MS.SectionId  
   ,MS.SourceTag  
   ,P.CustomerId  
 ORDER BY P.ProjectId DESC;  
  
UPDATE UNCOPIED  
SET UNCOPIED.UserId = P.UserId  
FROM @UncopiedMasterSections UNCOPIED  
INNER JOIN Project P WITH (NOLOCK)  
 ON UNCOPIED.ProjectId = P.ProjectId  
WHERE p.ProjectId = @PProjectId  
AND P.CustomerId = @CustomerId  
--INSERT THOSE SECTIONS INTO SLCProject  
INSERT INTO ProjectSection (ParentSectionId, mSectionId, ProjectId,  
CustomerId, UserId, DivisionId,  
DivisionCode, Description, LevelId,  
IsLastLevel, SourceTag, Author,  
TemplateId, SectionCode, IsDeleted,  
IsLocked, LockedBy, CreateDate,  
CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId)  
 SELECT  
  0 AS ParentSectionId  
    ,MS.SectionId AS mSectionId  
    ,UNCOPIED.ProjectId  
    ,UNCOPIED.CustomerId AS CustomerId  
    ,UNCOPIED.UserId AS UserId  
    ,MS.DivisionId  
    ,MS.DivisionCode  
    ,MS.Description  
    ,MS.LevelId  
    ,MS.IsLastLevel  
    ,MS.SourceTag  
    ,MS.Author  
    ,NULL AS TemplateId  
    ,MS.SectionCode  
    ,MS.IsDeleted  
    ,0 AS IsLocked  
    ,0 AS LockedBy  
    ,GETUTCDATE() AS CreateDate  
    ,UNCOPIED.UserId AS CreatedBy  
    ,UNCOPIED.UserId AS ModifiedBy  
    ,GETUTCDATE() AS ModifiedDate  
    ,MS.FormatTypeId  
 FROM SLCMaster..Section MS (NOLOCK)  
 INNER JOIN @UncopiedMasterSections UNCOPIED  
  ON MS.SectionId = UNCOPIED.mSectionId  
  
--UPDATE PARENT SECTION ID  
UPDATE PS  
SET PS.ParentSectionId = PPS.SectionId  
   ,PS.UserId = PPS.UserId  
   ,PS.CreatedBy = PPS.CreatedBy  
   ,PS.ModifiedBy = PPS.ModifiedBy  
FROM @UncopiedMasterSections UNCOPIED  
INNER JOIN ProjectSection PS (NOLOCK)  
 ON UNCOPIED.mSectionId = PS.mSectionId  
 AND UNCOPIED.ProjectId = PS.ProjectId  
INNER JOIN SLCMaster..Section MS (NOLOCK)  
 ON MS.SectionId = UNCOPIED.mSectionId  
INNER JOIN ProjectSection PPS (NOLOCK)  
 ON MS.ParentSectionId = PPS.mSectionId  
 AND UNCOPIED.ProjectId = PPS.ProjectId  
WHERE ps.ProjectId = @PProjectId  
AND PS.CustomerId = @CustomerId;

-- UPDATE SortOrder
DROP TABLE IF EXISTS #nullSortOrderSections;

SELECT ROW_NUMBER() OVER(ORDER BY SectionId) AS RowId, SectionId into #nullSortOrderSections FROM ProjectSection WITH(NOLOCK) WHERE ProjectId = @ProjectId AND SortOrder IS NULL AND ISNULL(IsDeleted,0) = 0;

DECLARE @Cntr INT = 1, @RowCnt INT = (SELECT COUNT(1) FROM #nullSortOrderSections), @SectionId INT;

WHILE(@Cntr <= @RowCnt)
BEGIN
SET @SectionID = (SELECT SectionId FROM #nullSortOrderSections WHERE RowId = @Cntr);

EXEC usp_UpdateMasterSectionSortOrder @SectionId, @ProjectId, @CustomerId;

SET @Cntr = @Cntr +1;
END;
END  