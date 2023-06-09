CREATE PROCEDURE [dbo].[usp_GetViewerDetails]  
@UserId INT NULL, @CustomerId INT NULL=NULL, @Id INT NULL=NULL, @Workstation NVARCHAR (50) NULL=NULL  
AS  
BEGIN
  
DECLARE @PUserId INT = @UserId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PId INT = @Id;
DECLARE @PWorkstation NVARCHAR (50) = @Workstation;

SELECT 
	Id
   ,CustomerId
   ,UserId
   ,Workstation
   ,IsActive
   ,CreatedDate
   ,CreatedBy
   ,ModifiedDate
   ,ModifiedBy
FROM [StandaloneViewerDetails] WITH (NOLOCK)
WHERE UserId = @PUserId;
END

GO
