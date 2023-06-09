CREATE PROCEDURE [dbo].[usp_CreateGlobalTerms]     
(  
 @Name  NVARCHAR(max) NULL,    
 @Value NVARCHAR(max) NULL,    
 @CreatedBy INT NULL,    
 @CustomerId INT NULL,    
 @ProjectId INT NULL    
)  
AS          
BEGIN    
    
 DECLARE @PName NVARCHAR(max) = @Name;    
 DECLARE @PValue NVARCHAR(max) = @Value;    
 DECLARE @PCreatedBy INT = @CreatedBy;    
 DECLARE @PCustomerId INT = @CustomerId;    
 DECLARE @PProjectId INT = @ProjectId;    
   
 SET NOCOUNT ON;    
    
  
  DECLARE @GlobalTermCode INT = 0;    
  DECLARE @UserGlobalTermId INT = NULL    
  DECLARE @MaxGlobalTermCode INT = (SELECT TOP 1 GlobalTermCode FROM ProjectGlobalTerm WITH(NOLOCK) WHERE CustomerId = @PCustomerId ORDER BY GlobalTermCode DESC);  
    
  DECLARE @MinGlobalTermCode INT = 10000000;    
  IF(@MaxGlobalTermCode < @MinGlobalTermCode)    
   BEGIN  
   SET @MaxGlobalTermCode = @MinGlobalTermCode;  
   END  
    
 INSERT INTO [UserGlobalTerm] ([Name], [Value], CreatedDate, CreatedBy, CustomerId, ProjectId, IsDeleted)    
 VALUES (@PName, @PValue, GETUTCDATE(), @PCreatedBy, @PCustomerId, @PProjectId, 0);  
 SET @UserGlobalTermId = SCOPE_IDENTITY();  
    
 SET @MaxGlobalTermCode = @MaxGlobalTermCode + 1;  
  
 INSERT INTO [ProjectGlobalTerm] (ProjectId, CustomerId, [Name], [Value], GlobalTermSource, CreatedDate, CreatedBy, UserGlobalTermId, GlobalTermCode)    
  SELECT    
   P.ProjectId  
  ,@PCustomerId AS CustomerId  
  ,@PName AS [Name]  
  ,@PValue AS [Value]  
  ,'U' AS GlobalTermSource   
  ,GETUTCDATE() AS CreatedDate  
  ,@PCreatedBy AS CreatedBy    
  ,@UserGlobalTermId AS UserGlobalTermId   
  ,@MaxGlobalTermCode AS GlobalTermCode  
  FROM Project P WITH(NOLOCK)  
  WHERE P.CustomerId = @PCustomerId AND ISNULL(P.IsDeleted, 0) = 0;  
    
 SELECT @MaxGlobalTermCode AS GlobalTermCode;  
    
END 