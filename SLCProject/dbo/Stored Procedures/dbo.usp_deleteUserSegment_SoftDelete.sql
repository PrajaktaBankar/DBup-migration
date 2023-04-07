CREATE PROCEDURE [dbo].[usp_deleteUserSegment_SoftDelete]                  
(                  
 @SegmentStatusId BIGINT                  
)        
AS                  
BEGIN        
 SET NOCOUNT ON;        
        
 --EXEC [dbo].[usp_UpdateSegmentsGTMapping] 6455933,1          
 EXEC [usp_DeleteSegmentsGTMapping_SoftDelete] @SegmentStatusId     
 EXEC [usp_DeleteSegmentsRSMapping_SoftDelete] @SegmentStatusId     
        
 --Default variables                  
 DECLARE @Source VARCHAR(1) = 'U';        
        
 IF EXISTS (SELECT TOP 1 1 FROM ProjectSegmentStatus WITH (NOLOCK)        
   WHERE SegmentStatusId = @SegmentStatusId        
   AND SegmentSource = @Source)        
 BEGIN        
  UPDATE SCP        
  SET SCP.IsDeleted = 1        
  FROM SelectedChoiceOption AS SCP WITH (NOLOCK)        
  INNER JOIN ProjectChoiceOption AS PCO WITH (NOLOCK)        
   ON SCP.ChoiceOptionCode = PCO.ChoiceOptionCode        
  INNER JOIN ProjectSegmentChoice AS PSC WITH (NOLOCK)        
   ON PSC.SegmentChoiceId = PCO.SegmentChoiceId        
  WHERE PSC.SegmentStatusId = @SegmentStatusId        
  AND PSC.SegmentChoiceSource = @Source        
  AND SCP.ChoiceOptionSource = @Source        
        
  UPDATE PCO        
  SET PCO.IsDeleted = 1        
  FROM ProjectChoiceOption AS PCO  WITH(NOLOCK) 
  INNER JOIN ProjectSegmentChoice AS PSC WITH (NOLOCK)        
   ON PCO.SegmentChoiceId = PSC.SegmentChoiceId        
  WHERE PSC.SegmentStatusId = @SegmentStatusId        
  AND PSC.SegmentChoiceSource = @Source        
        
  UPDATE PSC        
  SET PSC.IsDeleted = 1        
  FROM ProjectSegmentChoice PSC WITH (NOLOCK)        
  WHERE PSC.SegmentStatusId = @SegmentStatusId        
  AND PSC.SegmentChoiceSource = @Source        
        
  UPDATE PS        
  SET PS.IsDeleted = 1        
  FROM ProjectSegment PS WITH (NOLOCK)        
  WHERE PS.SegmentStatusId = @SegmentStatusId        
  AND PS.SegmentSource = @Source        
        
  --For Project Note Delete            
  UPDATE PN        
  SET PN.IsDeleted = 1        
  FROM ProjectNote PN WITH (NOLOCK)        
  WHERE PN.SegmentStatusId = @SegmentStatusId        
        
  UPDATE PSRT        
  SET PSRT.IsDeleted = 1        
  FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)        
  WHERE PSRT.SegmentStatusId = @SegmentStatusId        
        
  UPDATE PSUT        
  SET PSUT.IsDeleted = 1        
  FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)        
  WHERE PSUT.SegmentStatusId = @SegmentStatusId        
        
  --For Delete Segment Status        
  UPDATE PSS        
  SET PSS.IsDeleted = 1        
  FROM ProjectSegmentStatus PSS WITH (NOLOCK)        
  WHERE PSS.SegmentStatusId = @SegmentStatusId        
  AND PSS.SegmentSource = @Source        
 END        
        
END
GO


