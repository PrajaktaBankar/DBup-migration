CREATE PROCEDURE [dbo].[usp_UpdateSegmentStatus_ApplyMasterUpdate] @ProjectId INT, @CustomerId INT, @SectionId INT = NULL AS        
BEGIN        
DECLARE @PProjectId INT = @ProjectId;        
DECLARE @PCustomerId INT = @CustomerId;        
DECLARE @PSectionId INT = @SectionId;        
--DECLARE @ProjectId INT = 0;        
--DECLARE @CustomerId INT = 0;        
        
DECLARE @MasterDataTypeId INT = ( SELECT TOP 1        
  P.MasterDataTypeId        
 FROM Project P WITH (NOLOCK)        
 WHERE P.ProjectId = @PProjectId        
 AND P.CustomerId = @PCustomerId);        
        
--UPDATE FIELDS        
--NOTE:BELOW BOTH UPDATE LOGIC IS SAME JUST DIFFERENT OF HANDLING ProjectWise/SectionWise        
IF @PSectionId IS NULL OR @PSectionId <= 0        
 BEGIN        
  UPDATE PSS        
  SET PSS.SpecTypeTagId = SS.SpecTypeTagId, PSS.ModifiedDate = GETUTCDATE()  
  FROM ProjectSegmentStatus PSS WITH (NOLOCK)        
  INNER JOIN SLCMaster..SegmentStatus SS WITH (NOLOCK)        
   ON PSS.mSegmentStatusId = SS.SegmentStatusId        
  WHERE PSS.ProjectId = @PProjectId        
  AND PSS.CustomerId = @PCustomerId        
  AND PSS.SegmentSource = 'M'        
  AND PSS.SegmentOrigin = 'M'        
  AND PSS.SpecTypeTagId IS NULL        
  AND SS.SpecTypeTagId IS NOT NULL    
  AND ISNULL(SS.IsDeleted,0) = 0 -- Excludes deleted master paragraphs and don't remove view tags before accepting updates
 END        
ELSE        
 IF @PSectionId IS NOT NULL AND @PSectionId > 0        
 BEGIN        
  UPDATE PSS        
  SET PSS.SpecTypeTagId = SS.SpecTypeTagId, PSS.ModifiedDate = GETUTCDATE()        
  FROM ProjectSegmentStatus PSS WITH (NOLOCK)        
  INNER JOIN SLCMaster..SegmentStatus SS WITH (NOLOCK)        
   ON PSS.mSegmentStatusId = SS.SegmentStatusId        
  WHERE PSS.ProjectId = @PProjectId        
  AND PSS.CustomerId = @PCustomerId        
  AND PSS.SectionId = @PSectionId        
  AND PSS.SegmentSource = 'M'        
  AND PSS.SegmentOrigin = 'M'        
  AND PSS.SpecTypeTagId IS NULL        
  AND SS.SpecTypeTagId IS NOT NULL       
  AND ISNULL(SS.IsDeleted,0) = 0 -- Excludes deleted master paragraphs and don't remove view tags before accepting updates
 END        
END 