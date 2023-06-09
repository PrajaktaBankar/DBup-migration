CREATE PROCEDURE [dbo].[usp_InsertNewSection_ApplyMasterUpdate] @ProjectId INT, @CustomerId INT
AS  
BEGIN  
DECLARE @PProjectId INT = @ProjectId;  
DECLARE @PCustomerId INT = @CustomerId;  
--DECLARE @PProjectId INT = 0;  
--DECLARE @CustomerId INT = 0;  
  
DECLARE @Canada_Section_CutOffDate DATETIME2(7) = '20190420';  
  
DECLARE @MasterDataTypeId INT = ( SELECT TOP 1  
  P.MasterDataTypeId  
 FROM Project P WITH (NOLOCK)  
 WHERE P.ProjectId = @PProjectId  
 AND P.CustomerId = @PCustomerId);  
  
DROP TABLE IF EXISTS #UncopiedMasterSections  
CREATE TABLE #UncopiedMasterSections (  
 ProjectId INT  
   ,mSectionId INT  
   ,SourceTag VARCHAR(10)  
   ,CustomerId INT  
   ,UserId INT  
);  
  
--FIND NEW SECTIONS TO BE COPY  
INSERT INTO #UncopiedMasterSections (ProjectId, mSectionId, SourceTag, CustomerId, UserId)  
 SELECT DISTINCT  
  P.ProjectId  
    ,MS.SectionId AS mSectionId  
    ,MS.SourceTag  
    ,P.CustomerId  
    ,P.UserId  
 FROM SLCMaster..Section MS WITH (NOLOCK)  
 INNER JOIN Project P WITH (NOLOCK)  
  ON MS.MasterDataTypeId = P.MasterDataTypeId  
 LEFT JOIN ProjectSection PS WITH (NOLOCK)  
  ON P.ProjectId = PS.ProjectId  
   AND MS.SectionId = PS.mSectionId  
 WHERE P.ProjectId = @PProjectId  
 AND P.CustomerId = @PCustomerId  
 AND MS.MasterDataTypeId = @MasterDataTypeId  
 AND MS.IsDeleted = 0  
 AND PS.SectionId IS NULL  
 AND ((MS.MasterDataTypeId != 4)  
 OR (MS.MasterDataTypeId = 4  
 AND MS.IsLastLevel = 0)  
 OR (MS.MasterDataTypeId = 4  
 AND MS.IsLastLevel = 1  
 AND MS.PublicationDate >= @Canada_Section_CutOffDate))  
 ORDER BY MS.SourceTag ASC;  
  
--INSERT INTO ProjectSection  
INSERT INTO ProjectSection (ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId,  
DivisionCode, Description, LevelId, IsLastLevel, SourceTag, Author,  
TemplateId, SectionCode, IsDeleted, IsLocked, LockedBy, CreateDate,  
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
 FROM SLCMaster..Section MS WITH (NOLOCK)  
 INNER JOIN #UncopiedMasterSections UNCOPIED WITH (NOLOCK)  
  ON MS.SectionId = UNCOPIED.mSectionId  
  
--UPDATE ParentSectionId IN ProjectSection  
UPDATE PS  
SET PS.ParentSectionId = PPS.SectionId  
FROM ProjectSection PS WITH (NOLOCK)  
INNER JOIN #UncopiedMasterSections UNCOPIED WITH (NOLOCK)  
 ON PS.mSectionId = UNCOPIED.mSectionId  
INNER JOIN SLCMaster..Section MS WITH (NOLOCK)  
 ON PS.mSectionId = MS.SectionId  
INNER JOIN SLCMaster..Section PMS WITH (NOLOCK)  
 ON MS.ParentSectionId = PMS.SectionId  
INNER JOIN ProjectSection PPS WITH (NOLOCK)  
 ON PMS.SectionId = PPS.mSectionId  
 AND PPS.ProjectId = @PProjectId  
 AND PPS.CustomerId = @PCustomerId  
WHERE PS.ProjectId = @PProjectId  
AND PS.CustomerId = @PCustomerId;

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

GO
