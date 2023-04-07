CREATE PROCEDURE [dbo].[usp_SaveBim360ToggleInfo] 
(  
  @customerId INT ,
  @IsActive BIT
)  
AS  
BEGIN  


Update B
SET B.IsActive = @IsActive
from BIM360AccessKey B WITH (NOLOCK)
where B.customerId = @customerId


SELECT IsActive As IsToggleEnable
 from BIM360AccessKey WITH (NOLOCK)
 where customerId = @customerId
END 