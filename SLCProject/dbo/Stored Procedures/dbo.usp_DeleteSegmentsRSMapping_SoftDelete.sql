CREATE PROCEDURE [dbo].[usp_DeleteSegmentsRSMapping_SoftDelete]  
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
  
	 UPDATE PSRS  
	 SET PSRS.IsDeleted = 1
	 FROM ProjectSegmentReferenceStandard PSRS   WITH(NOLOCK) 
		WHERE PSRS.ProjectId = @ProjectId AND PSRS.SectionId = @SectionId  
	 AND (PSRS.SegmentId = @SegmentId OR PSRS.mSegmentId = @MSegmentId OR PSRS.SegmentId = 0)  
  
END
GO


