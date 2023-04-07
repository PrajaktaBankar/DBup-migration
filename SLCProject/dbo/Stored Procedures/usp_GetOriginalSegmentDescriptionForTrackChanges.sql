CREATE PROCEDURE [dbo].[usp_GetOriginalSegmentDescriptionForTrackChanges]  
(  
        @SectionId  int=0,
        @MSegmentId  int=0,
        @ProjectId  int=0,
        @CustomerId int=0,
		@SegmentStatusId bigint
)  
AS  
BEGIN  

 IF not exists(SELECT top 1 1 FROM ProjectSegment WITH(NOLOCK) WHERE SectionId=@SectionId AND ProjectId=@ProjectId AND SegmentStatusId=@SegmentStatusId)
 BEGIN
 SELECT SegmentDescription  FROM SLCMaster.dbo.Segment WITH(NOLOCK) WHERE SegmentId=@MSegmentId
 END
 ELSE
 BEGIN 
 SELECT
	  SegmentDescription 
FROM ProjectSegment WITH(NOLOCK)
WHERE SectionId = @SectionId
AND SegmentStatusId = @SegmentStatusId
AND ProjectId = @ProjectId
AND CustomerId = @CustomerId
 END
END
GO


