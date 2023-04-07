CREATE PROCEDURE usp_DeleteUserDivision              
(              
@ProjectId INT,              
@CustomerId INT,              
@SectionId INT                  
)              
AS              
BEGIN  
     
DECLARE @PCustomerId INT = @CustomerId;              
DECLARE @PProjectId INT = @ProjectId;                          
DECLARE @PSectionId INT = @SectionId;  
  
 UPDATE PS SET PS.IsDeleted= 1 FROM ProjectSection PS WITH(NOLOCK)  
 where PS.CustomerId = @PCustomerId and PS.ProjectId = @PProjectId and PS.SectionId = @PSectionId  
    
 UPDATE Lib SET Lib.IsDeleted = 1 FROM DocLibraryMapping Lib WITH(NOLOCK)
 where Lib.CustomerId = @PCustomerId and Lib.ProjectId = @PProjectId and Lib.SectionId = @PSectionId  

END  
  
  