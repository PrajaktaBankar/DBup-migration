CREATE PROCEDURE [dbo].[usp_GetLockedSections]   
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
Declare @IsSectionIsLocked bit = 0;        
  
SELECT TOP 1           
   @IsSectionIsLocked = 1          
   FROM ProjectSection PS WITH (NOLOCK)          
   WHERE PS.ProjectId = @PProjectId        
   AND PS.CustomerId = @PCustomerId   
   AND PS.IsLocked=1   
   AND PS.IsDeleted=0  
   AND PS.IsLastLevel=1 
  
--SELECT * FROM ProjectSection WITH(NOLOCK) WHERE  
--IsLocked=1 and CustomerId=@CustomerId and IsDeleted=0  

        
END