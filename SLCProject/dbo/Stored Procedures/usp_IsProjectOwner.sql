     
CREATE PROCEDURE [dbo].[usp_IsProjectOwner]  
(  
 @UserId INT,  
 @CustomerId INT  
)  
AS  
BEGIN  
 DECLARE @IsProjectOwner BIT=0;  
 SET @IsProjectOwner = (SELECT  
   COUNT(1)  
  FROM Project P WITH (NOLOCK)  
  INNER JOIN ProjectSummary PS WITH (NOLOCK)  
  ON P.ProjectId = PS.ProjectId  
  WHERE P.IsDeleted = 0  
  AND PS.OwnerId = @UserId  
  AND P.CustomerId = @CustomerId  
  )  
  
 SELECT CAST( iif(@IsProjectOwner=0,0,1) AS BIT) AS IsProjectOwner  
END  