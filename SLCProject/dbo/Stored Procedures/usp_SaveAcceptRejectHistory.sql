CREATE PROCEDURE [dbo].[usp_SaveAcceptRejectHistory]  
(  
        @SectionId  int=0,
        @SegmentId  bigint=0,
        @ProjectId  int=0,
        @CustomerId int=0,
        @BeforEdit  nvarchar(max),
        @AfterEdit  nvarchar(max),
        @TrackActionId  int,
        @Note  nvarchar(max),
		@SegmentStatusId bigint
)  
AS  
BEGIN  
 Set @SegmentId=(SELECT TOP 1 SegmentId FROM ProjectSegment WHERE SectionId=@SectionId  AND SegmentStatusId=@SegmentStatusId AND ProjectId=@ProjectId and CustomerId=@CustomerId AND IsDeleted=0 ORDER BY ModifiedDate DESC)

 INSERT INTO TrackAcceptRejectProjectSegmentHistory(SectionId,SegmentId,ProjectId,CustomerId,BeforEdit,AfterEdit,TrackActionId,Note)
 VALUES(@SectionId,@SegmentId,@ProjectId,@CustomerId,@BeforEdit,@AfterEdit,@TrackActionId,@Note);
 
END
GO


