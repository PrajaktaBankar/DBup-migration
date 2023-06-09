
CREATE PROCEDURE [dbo].[usp_MapProjectRefStands]  @ProjectId INT NULL, @SectionId INT NULL, @CustomerId INT NULL, @UserId INT NULL, @MasterSectionId INT NULL = NULL         
         
AS              
BEGIN  
DECLARE @PProjectId INT = @ProjectId;  
DECLARE @PSectionId INT = @SectionId;  
DECLARE @PCustomerId INT = @CustomerId;  
DECLARE @PUserId INT = @UserId;  
--ALTER DATABASE [SLCProject] SET READ_COMMITTED_SNAPSHOT ON;
  
SET NOCOUNT ON;  
        
            
 DECLARE @PMasterSectionId AS INT = @MasterSectionId;
 
 IF ISNULL(@PMasterSectionId,0) = 0
Begin 
SET @PMasterSectionId = (SELECT TOP 1  
  mSectionId  
 FROM ProjectSection WITH (NOLOCK)  
 WHERE ProjectId = @PProjectId  
 AND CustomerId = @PCustomerId  
 AND SectionId = @PSectionId);  
End;

SELECT  
 rs.RefStdId  
   ,rs.MasterDataTypeId  
   ,rs.RefStdName  
   ,rs.ReplaceRefStdId  
   ,rs.IsObsolete  
   ,rs.RefStdCode  
   ,rs.CreateDate  
   ,rs.ModifiedDate  
   ,rs.PublicationDate  
   ,MAX(rse.RefStdEditionId) AS RefStdEditionId INTO #t  
FROM [SLCMaster].[dbo].ReferenceStandard AS rs WITH (NOLOCK)  
INNER JOIN [SLCMaster].[dbo].ReferenceStandardEdition AS rse WITH (NOLOCK)  
 ON rs.RefStdId = rse.RefStdId  
INNER JOIN [SLCMaster].[dbo].SegmentReferenceStandard SRS WITH (NOLOCK)  
 ON SRS.RefStandardId = rs.RefStdId  
WHERE SRS.SectionId = @PMasterSectionId  
GROUP BY rs.RefStdId  
  ,rs.MasterDataTypeId  
  ,rs.RefStdName  
  ,rs.ReplaceRefStdId  
  ,rs.IsObsolete  
  ,rs.RefStdCode  
  ,rs.CreateDate  
  ,rs.ModifiedDate  
  ,rs.PublicationDate;  
  
INSERT INTO [dbo].[ProjectReferenceStandard] (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId, IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId)  
 SELECT  
  @PProjectId  
    ,tempTable.RefStdId  
    ,'M' AS RefStdSource  
    ,tempTable.ReplaceRefStdId AS mReplaceRefStdId  
    ,tempTable.RefStdEditionId  
    ,tempTable.IsObsolete  
    ,tempTable.RefStdCode  
    ,tempTable.PublicationDate  
    ,@PSectionId  
    ,@PCustomerId  
 -- , x.CustomerId            
 FROM #t AS tempTable  
 LEFT JOIN [dbo].ProjectReferenceStandard AS PRS WITH (NOLOCK)  
  ON tempTable.RefStdId = PRS.RefStandardId  
   AND PRS.ProjectId = @PProjectId  
   AND PRS.SectionId = @PSectionId
   AND PRS.CustomerId = @PCustomerId
   AND PRS.IsDeleted = 0  
 WHERE (PRS.RefStandardId IS NULL  
 OR PRS.SectionId IS NULL  
 OR PRS.CustomerId IS NULL)  

DROP TABLE IF EXISTS #TempProjectSegmentRefStd;
-- Insert into #TempProjectSegmentRefStd
SELECT PSRS.ProjectId, PSRS.mRefStandardId
INTO #TempProjectSegmentRefStd
FROM ProjectSegmentReferenceStandard PSRS WITH (NOLOCK) 
WHERE PSRS.ProjectId = @PProjectId AND PSRS.SectionId = @PSectionId AND PSRS.RefStandardSource = 'M'
  
INSERT INTO [dbo].ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource,  
mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy,  
CustomerId, ProjectId, mSegmentId, RefStdCode)  
 SELECT  
  @PSectionId AS SectionId  
    ,NULL AS SegmentId  
    ,NULL AS RefStandardId  
    ,'M' AS RefStandardSource  
    ,MRS.RefStdId AS mRefStandardId  
    ,GETUTCDATE() AS CreateDate
    ,@PUserId AS CreatedBy
    ,GETUTCDATE() AS ModifiedDate
    ,@PUserId AS ModifiedBy  
    ,@PCustomerId AS CustomerId  
    ,@PProjectId AS ProjectId  
    ,MSRS.SegmentId AS mSegmentId  
    ,MRS.RefStdCode AS RefStdCode  
 FROM [SLCMaster].[dbo].SegmentReferenceStandard MSRS WITH (NOLOCK)  
 INNER JOIN [SLCMaster].[dbo].ReferenceStandard MRS WITH (NOLOCK)  
  ON MSRS.RefStandardId = MRS.RefStdId
 LEFT JOIN #TempProjectSegmentRefStd PSRS WITH (NOLOCK)
 ON PSRS.ProjectId = @PProjectId AND PSRS.mRefStandardId = MRS.RefStdId
WHERE MSRS.SectionId = @PMasterSectionId 
AND PSRS.mRefStandardId IS NULL

END
GO


