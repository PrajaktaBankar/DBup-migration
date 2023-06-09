
CREATE PROCEDURE [dbo].[usp_MapSegmentStatusFromMasterToProject] @ProjectId INT NULL, @SectionId INT NULL, @CustomerId INT NULL, @UserId INT NULL , @MasterSectionId INT = NULL   
AS        
BEGIN    
SET NOCOUNT ON;    
        
 DECLARE @pMasterSectionId AS INT = @MasterSectionId;    
 DECLARE @pProjectId AS INT = @ProjectId;    
 DECLARE @pSectionId AS INT = @SectionId;    
 DECLARE @pCustomerId AS INT = @CustomerId;    
 DECLARE @pUserId AS INT = @UserId;    
 
 Declare @HasSegmentStatus as INT = 0;
 SELECT  
 @HasSegmentStatus = COUNT (1)    
 FROM [dbo].[ProjectSegmentStatus] AS PST WITH (NOLOCK)    
 WHERE PST.SectionId = @pSectionId   
 AND PST.[ProjectId] = @pProjectId    
 AND PST.CustomerId = @pCustomerId
 OPTION (FAST 1);
 
       
 IF @HasSegmentStatus = 0
BEGIN    

IF ISNULL(@pMasterSectionId,0) = 0
BEGIN
 SET @pMasterSectionId = (SELECT TOP 1    
  mSectionId    
 FROM dbo.ProjectSection WITH (NOLOCK)    
 WHERE SectionId = @pSectionId   
 AND ProjectId = @pProjectId    
 AND CustomerId = @pCustomerId    
 );  
End;  
    
INSERT INTO [dbo].ProjectSegmentStatus (SectionId, ParentSegmentStatusId,    
mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin,    
IndentLevel, SequenceNumber, SegmentStatusTypeId, IsParentSegmentStatusActive,    
ProjectId, CustomerId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy,    
SegmentStatusCode, SpecTypeTagId, IsShowAutoNumber, FormattingJson, IsRefStdParagraph,A_SegmentStatusId)    
 SELECT    
  @pSectionId    
    ,0    
    ,MST.SegmentStatusId    
    ,MST.SegmentId    
    ,NULL    
    ,MST.SegmentSource    
    ,MST.SegmentSource    
    ,MST.IndentLevel    
    ,MST.SequenceNumber    
    ,MST.SegmentStatusTypeId    
    ,IsParentSegmentStatusActive    
    ,@pProjectId    
    ,@pCustomerId    
    ,GETUTCDATE()    
    ,@pUserId    
    ,GETUTCDATE()    
    ,NULL    
    ,SegmentStatusCode    
    ,SpecTypeTagId    
    ,IsShowAutoNumber    
    ,FormattingJson    
    ,IsRefStdParagraph    
 ,MST.ParentSegmentStatusId as mParentSegmentStatusId  
 FROM SLCMaster.dbo.SegmentStatus AS MST WITH (NOLOCK)    
 WHERE MST.SectionId = @pMasterSectionId    
 AND ISNULL(MST.IsDeleted,0)=0   
 ORDER BY MST.SequenceNumber;    
    
SELECT SegmentStatusId,mSegmentStatusId,A_SegmentStatusId as mParentSegmentStatusId INTO #TMP_PSST    
FROM [dbo].ProjectSegmentStatus PSST WITH (NOLOCK)    
WHERE PSST.SectionId = @pSectionId   
AND  PSST.ProjectId = @pProjectId    
AND PSST.CustomerId = @pCustomerId    
    
UPDATE PSST    
SET PSST.ParentSegmentStatusId = t.SegmentStatusId    
FROM [dbo].ProjectSegmentStatus PSST WITH (NOLOCK) INNER JOIN #TMP_PSST t  
ON t.mSegmentStatusId=PSST.A_SegmentStatusId  
WHERE PSST.SectionId = @pSectionId     
AND PSST.ProjectId = @pProjectId     
AND PSST.CustomerId = @pCustomerId  
  
--UPDATE CPSST    
--SET CPSST.ParentSegmentStatusId = PSST.SegmentStatusId    
--FROM dbo.ProjectSegmentStatus AS CPSST WITH (NOLOCK)    
----INNER JOIN SLCMaster.dbo.SegmentStatus AS CMSST WITH (NOLOCK)    
---- ON CMSST.SegmentStatusId = CPSST.mSegmentStatusId    
--INNER JOIN #TMP_PSST AS PSST WITH (NOLOCK)    
-- ON PSST.mSegmentStatusId = CPSST.mParentSegmentStatusId    
--WHERE CPSST.SectionId = @pSectionId     
--AND CPSST.ProjectId = @pProjectId     
--AND CPSST.CustomerId = @pCustomerId  
END    
END