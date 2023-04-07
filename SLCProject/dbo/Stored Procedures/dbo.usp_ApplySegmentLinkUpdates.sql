CREATE PROCEDURE [dbo].[usp_ApplySegmentLinkUpdates]    
@SegmentStatusId BIGINT NULL, @SectionId INT NULL, @ProjectId INT NULL, @CustomerId INT NULL    
AS    
BEGIN    
SET NOCOUNT ON;    
    
DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId    
, @PSectionId INT = @SectionId    
, @PProjectId INT = @ProjectId    
, @PCustomerId INT = @CustomerId;    
    
--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
--BEGIN TRANSACTION    
    
DECLARE @MasterLinkSource NVARCHAR(MAX) = 'M'    
, @MasterLinkTarget NVARCHAR(MAX) = 'M'    
, @UserSegmentLinkSourceTypeId INT = 5    
, @MinUserSegmentLinkCode BIGINT = 10000000;    
    
Drop TABLE IF EXISTS #t_ProjectSegmentStatusView;    
    
SELECT PS.SectionCode , PSST.SegmentStatusCode
,(CASE  
  WHEN PSST.SegmentStatusId IS NOT NULL AND  
   PSST_PSG.SegmentId IS NOT NULL THEN PSST_PSG.SegmentCode  
  WHEN PSST.SegmentStatusId IS NOT NULL AND  
   PSST_MSG.SegmentId IS NOT NULL THEN PSST_MSG.SegmentCode  
  ELSE NULL  
 END) AS SegmentCode  ,PS.SectionId,PSST.SegmentStatusId ,PSST.ProjectId,PSST.CustomerId INTO #t_ProjectSegmentStatusView    
FROM ProjectSegmentStatus PSST WITH (NOLOCK)  
INNER JOIN ProjectSection PS WITH (NOLOCK)  
 ON PSST.ProjectId = PS.ProjectId  
  AND PSST.SectionId = PS.SectionId  
LEFT JOIN ProjectSegment PSST_PSG WITH (NOLOCK)  
 ON PSST.SegmentId = PSST_PSG.SegmentId  
  AND PSST.SegmentOrigin = 'U'  
LEFT JOIN SLCMaster..Segment PSST_MSG WITH (NOLOCK)  
 ON PSST.mSegmentId = PSST_MSG.SegmentId  
  AND PSST.SegmentOrigin = 'M'     
WHERE PSST.SegmentStatusId = @PSegmentStatusId AND PSST.SectionId = @PSectionId    
AND PSST.ProjectId=@PProjectId AND PSST.CustomerId=@PCustomerId     
    
--SELECT * FROM #t_ProjectSegmentStatusView;    
    
Drop TABLE IF EXISTS #t_ProjectSegmentLink;    
    
SELECT PSLNK.SegmentLinkId, PSLNK.SourceSegmentCode,PSLNK.TargetSegmentCode,PSLNK.LinkStatusTypeId ,PSLNK.IsDeleted ,SegmentLinkCode,PSLNK.SourceSectionCode,PSLNK.SourceSegmentStatusCode    
,PSLNK.TargetSectionCode,PSLNK.TargetSegmentStatusCode    
INTO #t_ProjectSegmentLink    
FROM ProjectSegmentLink PSLNK WITH (NOLOCK)   
INNER JOIN #t_ProjectSegmentStatusView PSTV WITH (NOLOCK)    
ON (PSLNK.SourceSegmentStatusCode = PSTV.SegmentStatusCode OR PSLNK.TargetSegmentStatusCode=PSTV.SegmentStatusCode)    
WHERE PSLNK.ProjectId = @PProjectId AND PSLNK.CustomerId = @PCustomerId    
 AND PSLNK.LinkSource = @MasterLinkSource  AND PSLNK.LinkTarget = @MasterLinkTarget    
 AND PSLNK.SegmentLinkSourceTypeId != @UserSegmentLinkSourceTypeId    
 AND PSLNK.IsDeleted = 0     
    
 --SELECT * FROM #t_ProjectSegmentLink;    
--WORK FOR APPLY UPDATES OF SEGMENT LINKS IN PROJECT DB     
--WHERE SOURCE SEGMENT STATUS CODE MATCHES WITH CURRENTLY APPLYING SEGMENT STATUS    
UPDATE PSLNK    
SET PSLNK.SourceSegmentCode = MSLNK.SourceSegmentCode    
   ,PSLNK.TargetSegmentCode = MSLNK.TargetSegmentCode    
   ,PSLNK.LinkStatusTypeId = MSLNK.LinkStatusTypeId    
FROM #t_ProjectSegmentStatusView SrcPSSTV WITH (NOLOCK)    
INNER JOIN SLCMaster..SegmentLink MSLNK WITH (NOLOCK)    
 ON SrcPSSTV.SectionCode = MSLNK.SourceSectionCode    
 AND SrcPSSTV.SegmentStatusCode = MSLNK.SourceSegmentStatusCode    
 AND SrcPSSTV.SegmentCode = MSLNK.SourceSegmentCode    
INNER JOIN #t_ProjectSegmentStatusView TgtPSSTV WITH (NOLOCK)    
 ON MSLNK.TargetSectionCode = TgtPSSTV.SectionCode    
 AND MSLNK.TargetSegmentStatusCode = TgtPSSTV.SegmentStatusCode    
 AND MSLNK.TargetSegmentCode = TgtPSSTV.SegmentCode    
 AND TgtPSSTV.ProjectId = @PProjectId    
 AND TgtPSSTV.CustomerId = @PCustomerId    
INNER JOIN #t_ProjectSegmentLink PSLNK WITH (NOLOCK)    
 ON MSLNK.SegmentLinkCode = PSLNK.SegmentLinkCode    
WHERE SrcPSSTV.ProjectId = @PProjectId    
AND SrcPSSTV.CustomerId = @PCustomerId    
AND SrcPSSTV.SectionId = @PSectionId    
AND SrcPSSTV.SegmentStatusId = @PSegmentStatusId    
AND ((MSLNK.SourceSegmentCode != PSLNK.SourceSegmentCode)    
OR (MSLNK.TargetSegmentCode = PSLNK.TargetSegmentCode)    
OR (MSLNK.LinkStatusTypeId != PSLNK.LinkStatusTypeId))    
    
--WORK FOR APPLY UPDATES OF SEGMENT LINKS IN PROJECT DB     
--WHERE TARGET SEGMENT STATUS CODE MATCHES WITH CURRENTLY APPLYING SEGMENT STATUS    
UPDATE PSLNK    
SET PSLNK.SourceSegmentCode = MSLNK.SourceSegmentCode    
   ,PSLNK.TargetSegmentCode = MSLNK.TargetSegmentCode    
   ,PSLNK.LinkStatusTypeId = MSLNK.LinkStatusTypeId    
FROM #t_ProjectSegmentStatusView TgtPSSTV WITH (NOLOCK)    
INNER JOIN SLCMaster..SegmentLink MSLNK WITH (NOLOCK)    
 ON TgtPSSTV.SectionCode = MSLNK.TargetSectionCode    
 AND TgtPSSTV.SegmentStatusCode = MSLNK.TargetSegmentStatusCode    
 AND TgtPSSTV.SegmentCode = MSLNK.TargetSegmentCode    
INNER JOIN #t_ProjectSegmentStatusView SrcPSSTV WITH (NOLOCK)    
 ON MSLNK.SourceSectionCode = SrcPSSTV.SectionCode    
 AND MSLNK.SourceSegmentStatusCode = SrcPSSTV.SegmentStatusCode    
 AND MSLNK.SourceSegmentCode = SrcPSSTV.SegmentCode    
 AND SrcPSSTV.ProjectId = @PProjectId    
 AND SrcPSSTV.CustomerId = @PCustomerId    
INNER JOIN #t_ProjectSegmentLink PSLNK WITH (NOLOCK)    
 ON MSLNK.SegmentLinkCode = PSLNK.SegmentLinkCode    
WHERE TgtPSSTV.ProjectId = @PProjectId    
AND TgtPSSTV.CustomerId = @PCustomerId    
AND TgtPSSTV.SectionId = @PSectionId    
AND TgtPSSTV.SegmentStatusId = @PSegmentStatusId    
AND ((MSLNK.SourceSegmentCode != PSLNK.SourceSegmentCode)    
OR (MSLNK.TargetSegmentCode = PSLNK.TargetSegmentCode)    
OR (MSLNK.LinkStatusTypeId != PSLNK.LinkStatusTypeId))    
    
--Make ProjectSegmentLink as IsDeleted = 1    
UPDATE PSLNK    
SET PSLNK.IsDeleted = 1    
FROM #t_ProjectSegmentStatusView SrcPSSTV WITH (NOLOCK)    
INNER JOIN #t_ProjectSegmentLink PSLNK WITH (NOLOCK)    
 ON SrcPSSTV.SectionCode = PSLNK.SourceSectionCode    
 AND SrcPSSTV.SegmentStatusCode = PSLNK.SourceSegmentStatusCode    
 AND PSLNK.SegmentLinkCode < @MinUserSegmentLinkCode    
 AND PSLNK.IsDeleted = 0    
INNER JOIN #t_ProjectSegmentStatusView TgtPSSTV  WITH(NOLOCK)    
 ON PSLNK.TargetSectionCode = TgtPSSTV.SectionCode    
 AND PSLNK.TargetSegmentStatusCode = TgtPSSTV.SegmentStatusCode    
 AND PSLNK.TargetSegmentCode = TgtPSSTV.SegmentCode    
LEFT JOIN SLCMaster..SegmentLink MSLNK  WITH(NOLOCK)    
 ON PSLNK.SegmentLinkCode = MSLNK.SegmentLinkCode    
WHERE SrcPSSTV.ProjectId = @PProjectId    
AND SrcPSSTV.CustomerId = @PCustomerId    
AND SrcPSSTV.SectionId = @PSectionId    
AND SrcPSSTV.SegmentStatusId = @PSegmentStatusId    
AND (MSLNK.SegmentLinkId IS NULL    
OR MSLNK.IsDeleted = 1)    
    
--Make ProjectSegmentLink as IsDeleted = 1    
UPDATE PSLNK    
SET PSLNK.IsDeleted = 1    
FROM #t_ProjectSegmentStatusView TgtPSSTV WITH (NOLOCK)    
INNER JOIN #t_ProjectSegmentLink PSLNK WITH (NOLOCK)    
 ON TgtPSSTV.SectionCode = PSLNK.TargetSectionCode    
 AND TgtPSSTV.SegmentStatusCode = PSLNK.TargetSegmentStatusCode    
 AND PSLNK.SegmentLinkCode < @MinUserSegmentLinkCode    
 AND PSLNK.IsDeleted = 0    
INNER JOIN #t_ProjectSegmentStatusView SrcPSSTV WITH (NOLOCK)    
 ON PSLNK.SourceSectionCode = SrcPSSTV.SectionCode    
 AND PSLNK.SourceSegmentStatusCode = SrcPSSTV.SegmentStatusCode    
 AND PSLNK.SourceSegmentCode = SrcPSSTV.SegmentCode    
LEFT JOIN SLCMaster..SegmentLink MSLNK WITH (NOLOCK)    
 ON PSLNK.SegmentLinkCode = MSLNK.SegmentLinkCode    
WHERE TgtPSSTV.ProjectId = @PProjectId    
AND TgtPSSTV.CustomerId = @PCustomerId    
AND TgtPSSTV.SectionId = @PSectionId    
AND TgtPSSTV.SegmentStatusId = @PSegmentStatusId    
AND (MSLNK.SegmentLinkId IS NULL    
OR MSLNK.IsDeleted = 1)    
--COMMIT TRANSACTION    
    
UPDATE PSL    
SET     
  PSL.SourceSegmentCode = PSLNK.SourceSegmentCode    
 ,PSL.TargetSegmentCode = PSLNK.TargetSegmentCode    
 ,PSL.LinkStatusTypeId = PSLNK.LinkStatusTypeId    
 ,PSL.IsDeleted = PSLNK.IsDeleted    
FROM ProjectSegmentLink PSL WITH (NOLOCK)    
INNER JOIN #t_ProjectSegmentLink PSLNK WITH (NOLOCK)    
ON PSL.SegmentLinkId = PSLNK.SegmentLinkId    
    
END    
GO


