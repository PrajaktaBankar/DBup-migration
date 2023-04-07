CREATE PROCEDURE [dbo].[usp_TrackAcceptRejectHistory]        
  @SectionId  int=0,  
        @ProjectId  int=0,  
        @CustomerId int=0,  
        @TrackActionId  int,   
  @UserId int  
AS      
 BEGIN  
 INSERT INTO TrackAcceptRejectHistory (SectionId,ProjectId,CustomerId,TrackActionId,UserId,CreateDate)  
 VALUES(@SectionId,@ProjectId,@CustomerId,@TrackActionId,@UserId,getutcdate());
END
