
CREATE PROCEDURE [dbo].[usp_DeleteSegmentsRSMapping]    
(    
 @SegmentStatusId BIGINT      
)    
AS    
BEGIN
    
   DECLARE @PSegmentStatusId BIGINT =  @SegmentStatusId;
   DECLARE @CustomerId INT;    
   DECLARE @ProjectId  INT;    
   DECLARE @SectionId  INT;    
   DECLARE @SegmentId  BIGINT;    
   DECLARE @MSegmentId INT;
    
   DECLARE @UserId INT;

SELECT
	@ProjectId = ProjectId
   ,@SectionId = SectionId
   ,@CustomerId = CustomerId
   ,@UserId = 0
   ,@SegmentId = SegmentId
   ,@MSegmentId = MSegmentId
FROM ProjectSegmentStatus WITH (NOLOCK)
WHERE SegmentStatusId = @PSegmentStatusId

UPDATE PSRS
SET PSRS.IsDeleted = 1
FROM ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)
WHERE PSRS.ProjectId = @ProjectId AND PSRS.SectionId = @SectionId
AND (PSRS.SegmentId = @SegmentId
OR PSRS.mSegmentId = @MSegmentId
OR PSRS.SegmentId = 0)

UPDATE PRS
SET PRS.IsDeleted = 1
FROM ProjectReferenceStandard PRS WITH (NOLOCK)
LEFT JOIN ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)
	ON PSRS.ProjectId = PRS.ProjectId AND PSRS.SectionId = PRS.SectionId
	AND PSRS.RefStdCode = PRS.RefStdCode
	AND ISNULL(PSRS.IsDeleted,0)=0
WHERE PRS.ProjectId = @ProjectId AND PRS.SectionId = @SectionId
AND PRS.CustomerId = @CustomerId
AND PSRS.RefStdCode IS NULL

END
GO



