CREATE PROCEDURE [dbo].[usp_UpdateSegmentStatusTypeDeletedLinkFromUpdate]  
(
	@ProjectId INT, 
	@CustomerId INT,
	@SegmentStatusId BIGINT
)
AS      
BEGIN  
	DECLARE @PProjectId INT = @ProjectId;  
	
	DECLARE @PSegmentStatusId INT = @SegmentStatusId; 
	DECLARE @UserSelect_SystemNeutral INT = 2

	DROP TABLE IF EXISTS #UpdatedLinkTemp
	DROP TABLE IF EXISTS #ExistingLinkTemp
	DROP TABLE IF EXISTS #SegmentStatusCodeDelete
	
	 Select PSL.SegmentLinkId 
		  ,PSL.TargetSegmentStatusCode 
		  ,PSL.TargetSegmentCode
	 INTO  #UpdatedLinkTemp 
	 FROM ProjectSegmentStatus PSS WITH (NOLOCK)
	 INNER JOIN ProjectSegmentLink PSL WITH (NOLOCK)
	 ON PSS.ProjectId = PSL.ProjectId 
	 AND PSS.SegmentStatusCode = PSL.SourceSegmentStatusCode
	 AND PSS.mSegmentId = PSL.SourceSegmentCode
	 Where PSS.SegmentStatusId = @PSegmentStatusId
	
	 Select PSL.SegmentLinkId 
		 ,PSL.TargetSegmentStatusCode 
		 ,PSL.TargetSegmentCode
	 INTO #ExistingLinkTemp 
	 FROM ProjectSegmentStatus PSS WITH (NOLOCK) 
	 INNER JOIN ProjectSegmentLink PSL WITH (NOLOCK)
	 ON PSS.ProjectId = PSL.ProjectId 
	 AND PSS.SegmentStatusCode = PSL.SourceSegmentStatusCode
	 Where PSS.SegmentStatusId = @PSegmentStatusId
	
	 Select  Distinct Ex.TargetSegmentStatusCode   
	  INTo #SegmentStatusCodeDelete 
	 FROM #ExistingLinkTemp ex LEFT JOIn #UpdatedLinkTemp new  
	 ON EX.TargetSegmentStatusCode = new.TargetSegmentStatusCode  
	 Where new.TargetSegmentStatusCode IS NULL   

	  UPDATE PSS SET PSS.SegmentStatusTypeId = @UserSelect_SystemNeutral 
	  FROM ProjectSegmentStatus PSS WITH (NOLOCK)
	  INNER JOIN #SegmentStatusCodeDelete t WITH(NOLOCK)
	  ON PSS.SegmentStatusCode = t.TargetSegmentStatusCode
	  WHERE PSS.ProjectId = @PProjectId  
      AND PSS.CustomerId = @CustomerId 
	  AND PSS.SegmentStatusTypeId ! = @UserSelect_SystemNeutral  

END

