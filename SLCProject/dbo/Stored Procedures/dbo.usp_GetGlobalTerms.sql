CREATE PROCEDURE [dbo].[usp_GetGlobalTerms]     
(    
	@CustomerID INT,    
	@ProjectID INT    
)    
AS    
BEGIN  

DECLARE @PCustomerID INT = @CustomerID;  
DECLARE @PProjectID INT = @ProjectID;  
  
	SELECT
		GlobalTermId  
	   ,ProjectId  
	   ,CustomerId  
	   ,ISNULL(MGlobalTermId, 0) AS MGlobalTermId  
	   ,[Name]
	   ,ISNULL([Value], '') AS [Value]  
	   ,ISNULL(OldValue, '') AS OldValue
	   ,GlobalTermSource  
	   ,GlobalTermCode  
	   ,CreatedDate  
	   ,CreatedBy  
	   ,ISNULL(IsDeleted, 0) AS IsDeleted  
	   ,ISNULL(UserGlobalTermId, 0) AS UserGlobalTermId  
	   ,ISNULL(GlobalTermFieldTypeId, 1) AS GlobalTermFieldTypeId  
	   ,COALESCE(ModifiedDate, NULL) AS ModifiedDate  
	   ,ISNULL(ModifiedBy, 0) AS ModifiedBy  
	FROM ProjectGlobalTerm WITH (NOLOCK)  
	WHERE CustomerId = @PCustomerID
	AND ProjectId = @PProjectID
	AND ISNULL(IsDeleted, 0) = 0
	ORDER BY [Name]
END

--EXEC [usp_GetGlobalTerms] 641, 8340