CREATE PROCEDURE [dbo].[usp_DeleteSegmentsGTMapping_SoftDelete]    
(    
 @SegmentStatusId BIGINT      
)    
AS    
BEGIN    
   DECLARE @CustomerId INT;    
   DECLARE @ProjectId  INT;    
   DECLARE @SectionId  INT;    
   DECLARE @SegmentId  BIGINT;    
   DECLARE @MSegmentId INT;    
   DECLARE @UserId INT;    
       
   SELECT @ProjectId = ProjectId,@SectionId = SectionId, @CustomerId = CustomerId,    
   @UserId = 0,@SegmentId = SegmentId, @MSegmentId = MSegmentId    
   FROM ProjectSegmentStatus WITH(NOLOCK) WHERE SegmentStatusId = @SegmentStatusId    
    
  UPDATE PSGT    
  SET PSGT.IsDeleted = 1  
  FROM ProjectSegmentGlobalTerm PSGT     WITH(NOLOCK)  
  WHERE PSGT.ProjectId = @ProjectId AND PSGT.SectionId = @SectionId     
  AND (PSGT.SegmentId = @SegmentId OR PSGT.mSegmentId = @MSegmentId OR PSGT.SegmentId=0)  
END
GO


