CREATE PROCEDURE [dbo].[spb_GetGlobalTerms]
(
@CustomerID int = 0,
@ProjectID int = NULL
)
AS
BEGIN
DECLARE @PCustomerID int = @CustomerID;
DECLARE @PProjectID int = @ProjectID;
SELECT
	GlobalTermId
   ,mGlobalTermId
   ,ProjectId
   ,CustomerId
   ,Name
   ,value
   ,GlobalTermSource
   ,GlobalTermCode
   ,CreatedDate
   ,CreatedBy
   ,ModifiedDate
   ,ModifiedBy
   ,SLE_GlobalChoiceID
   ,UserGlobalTermId
   ,IsDeleted
   ,A_GlobalTermId
   ,GlobalTermFieldTypeId
   ,OldValue
FROM ProjectGlobalTerm WITH (NOLOCK)
WHERE ProjectId = @PProjectID
AND CustomerId = @PCustomerID

END

GO
