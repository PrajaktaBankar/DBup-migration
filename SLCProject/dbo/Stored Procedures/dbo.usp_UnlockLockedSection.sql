CREATE PROCEDURE [dbo].[usp_UnlockLockedSection]
(
	@ProjectId INT, 
	@SectionId INT, 
	@CustomerId INT, 
	@UserId INT
) 
AS    
BEGIN
   
  DECLARE @PProjectId INT = @ProjectId;  
  DECLARE @PSectionId INT = @SectionId;  
  DECLARE @PCustomerId INT = @CustomerId;  
  DECLARE @PUserId INT = @UserId;  

	UPDATE PS  
	SET PS.IsLocked = 0  
	   ,PS.LockedBy = 0  
	   ,PS.LockedByFullName = ''  
	   ,PS.ModifiedBy = @PUserId  
	   ,PS.ModifiedDate = GETUTCDATE()  
	FROM ProjectSection PS WITH (NOLOCK)  
	WHERE PS.SectionId = @PSectionId AND PS.ProjectId = @PProjectId AND PS.CustomerId = @PCustomerId;
  
END