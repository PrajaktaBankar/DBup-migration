CREATE PROCEDURE [dbo].[usp_getLastActivityDateOfUser]    
(    
 @UserId INT,    
 @CustomerId INT  
)    
AS    
BEGIN
    
 DECLARE @PUserId INT = @UserId;
 DECLARE @PCustomerId INT = @CustomerId;
SELECT TOP 1
	P.ModifiedDate AS LastActivityDate
FROM Project P WITH (NOLOCK)
WHERE P.CustomerId = @PCustomerId
AND P.UserId = @PUserId
ORDER BY P.ModifiedDate DESC
END

GO
