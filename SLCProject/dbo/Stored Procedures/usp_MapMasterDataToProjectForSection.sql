CREATE PROCEDURE [dbo].[usp_MapMasterDataToProjectForSection]
(
	@ProjectId INT,      
	@SectionId INT,       
	@CustomerId INT,       
	@UserId INT ,
	@MSectionId INT=null
)
AS
BEGIN
	 DECLARE @PProjectId INT = @ProjectId;                             
	 DECLARE @PSectionId INT = @SectionId;                              
	 DECLARE @PCustomerId INT = @CustomerId;                              
	 DECLARE @PUserId INT = @UserId;  
	 DECLARE @PMasterSectionId INT = @MSectionId;  

	IF ISNULL(@PMasterSectionId,0) >0
	BEGIN -- Data Mapping SP's                  
	   EXECUTE usp_MapSegmentStatusFromMasterToProject @ProjectId = @PProjectId                              
	  ,@SectionId = @PSectionId                              
	  ,@CustomerId = @PCustomerId                              
	  ,@UserId = @PUserId  
	  ,@MasterSectionId =@PMasterSectionId;   

	   EXECUTE usp_MapSegmentChoiceFromMasterToProject @ProjectId = @PProjectId                    
	  ,@SectionId = @PSectionId                              
	  ,@CustomerId = @PCustomerId                              
	  ,@UserId = @PUserId  
	  ,@MasterSectionId =@PMasterSectionId;   
	  
	   EXECUTE usp_MapProjectRefStands @ProjectId = @PProjectId                   
		,@SectionId = @PSectionId                              
		,@CustomerId = @PCustomerId                              
		,@UserId = @PUserId  
		,@MasterSectionId=@PMasterSectionId;  
		
	   EXECUTE usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @PProjectId                              
		,@SectionId = @PSectionId                              
		,@CustomerId = @PCustomerId                              
		,@UserId = @PUserId  
		 ,@MasterSectionId=@PMasterSectionId;   
		 
	   EXECUTE usp_MapSegmentLinkFromMasterToProject @ProjectId = @PProjectId                            
	   ,@SectionId = @PSectionId                              
	   ,@CustomerId = @PCustomerId                              
	   ,@UserId = @PUserId;         
	   
	   EXECUTE usp_UpdateSegmentStatus_ApplyMasterUpdate @ProjectId = @PProjectId                              
		,@CustomerId = @PCustomerId                              
		,@SectionId = @PSectionId       
		-- NOT IN USE hence commented                         
	   --EXECUTE usp_DeleteSegmentRequirementTag_ApplyMasterUpdate @ProjectId = @PProjectId                              
	   --,@CustomerId = @PCustomerId                              
	   --,@SectionId = @PSectionId     
	   
	   UPDATE PS
		SET PS.DataMapDateTimeStamp=GETUTCDATE()
		FROM ProjectSection PS WITH(NOLOCK)
		WHERE SectionId = @PSectionId

	END  
END