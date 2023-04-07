CREATE PROCEDURE [dbo].[usp_GetUnlockedAllSections]  
(      
 @ProjectId INT      
,@CustomerId INT
,@IsDeleted INT = 0 

)      
AS   
BEGIN      
SET NOCOUNT ON;      
Declare @PProjectId int = @ProjectId;      
Declare @PCustomerId int = @CustomerId;      
Declare @IsSectionIsLocked bit = 1; 
Declare @IsLockedByFullName nvarchar(500);

 
SELECT PS.SectionId,PS.LockedBy,PS.ProjectId,
PS.CustomerId,PS.LockedByFullName,PS.IsLocked 
FROM ProjectSection PS WITH(NOLOCK) 
WHERE PS.ProjectId=@ProjectId AND
PS.IsLocked=1 AND 
PS.CustomerId=@CustomerId AND 
PS.IsDeleted=0
 
    
	IF @IsSectionIsLocked=1
	BEGIN
	UPDATE PS
	SET IsLocked =0
	FROM ProjectSection PS WITH (NOLOCK)
	WHERE PS.ProjectId = @PProjectId      
	AND PS.CustomerId = @PCustomerId 	
	AND PS.IsLocked=1 
	

	END
	 
	     
END