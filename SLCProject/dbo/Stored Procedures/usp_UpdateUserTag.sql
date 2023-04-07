CREATE Procedure usp_UpdateUserTag
(
  @CustomerId INT ,
  @UserTagId INT,
  @TagType Nvarchar(10),
  @TagName Nvarchar(50),
  @ModifiedBy INT
)
AS 
BEGIN

DECLARE @PTagType NVARCHAR(10) = @TagType;
DECLARE @PTagName NVARCHAR(50) = @TagName; 

Update PUT 
set PUT.TagType = @PTagType,
    PUT.Description = @PTagName,
	PUT.ModifiedBy=@ModifiedBy
from ProjectUserTag  PUT WITH (NOLOCK) where UserTagId = @UserTagId

select P.UserTagId, P.Description,P.TagType from ProjectUserTag P WITH (NOLOCK) where UserTagId=@UserTagId
END;