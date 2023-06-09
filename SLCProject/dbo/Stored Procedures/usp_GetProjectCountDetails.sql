
CREATE PROCEDURE [dbo].[usp_GetProjectCountDetails]        
  @CustomerId INT NULL                                
 ,@UserId INT NULL = NULL                                                          
 ,@IsOfficeMasterTab BIT NULL = false                                                                
AS                                
BEGIN 

 DECLARE @allProjectCount AS INT = 0; 
 DECLARE @PCustomerId AS INT = 0; 
 DECLARE @PIsOfficeMasterTab BIT = @IsOfficeMasterTab;                              
  DECLARE @officeMasterCount AS INT = 0; 


 SET @allProjectCount = (Select Count(*) from  Project  WITH (NOLOCK) where CustomerId =@CustomerId and IsOfficeMaster = 0 and ISNULL(IsDeleted,0) = 0 and IsArchived = 0)                              
SET @officeMasterCount = (Select Count(*) from Project  WITH (NOLOCK)  where CustomerId =@CustomerId and IsOfficeMaster = 1  and ISNULL(IsDeleted,0) = 0 and IsArchived = 0)                        
                          
 
select @allProjectCount As TotalProjectCount ,
   @officeMasterCount As OfficeMasterCount

  END 