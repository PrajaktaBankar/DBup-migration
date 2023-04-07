
CREATE PROCEDURE [dbo].[usp_GetBIM360Credentials]   
(    
@customerId INT    
)    
AS    
BEGIN



SELECT
	CustomerId ,iif(IsActive =1,ClientId,'') As ClientId ,iif(IsActive =1,ClientSecret,'') As ClientSecret ,IsActive ,ModifiedDate ,ModifiedBy ,CreatedBy ,CreatedDate
FROM BIM360AccessKey  WITH (NOLOCK)
where customerId =@customerId


END