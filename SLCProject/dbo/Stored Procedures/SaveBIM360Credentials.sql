Create PROCEDURE [dbo].[usp_SaveBIM360Credentials] 
(  
@customerId INT,  
@clientId Nvarchar(255),
@clientSecret Nvarchar(255),
@IsActive Bit ,
@createdBy INT,
@ModifiedBy Int
)  
AS  
BEGIN
  
  Declare @count INT;
SELECT
	@count = (SELECT
			COUNT(1)
		FROM BIM360AccessKey WITH (NOLOCK)
		WHERE customerId = @customerId)
IF (@count = 0)
BEGIN
INSERT INTO BIM360AccessKey (customerId, clientId, clientSecret, IsActive, createdDate, createdBy, ModifiedDate, ModifiedBy)
	VALUES (@customerId, @clientId, @clientSecret, @IsActive, GETUTCDATE(), @createdBy, NULL, @ModifiedBy)

END
ELSE
BEGIN
UPDATE B
SET B.ClientId = @clientId
   ,B.ClientSecret = @clientSecret
    ,B.ISActive = @IsActive
FROM BIM360AccessKey B WITH (NOLOCK)
where customerId = @customerId
END

SELECT
	*
FROM BIM360AccessKey WITH (NOLOCK)
WHERE customerId = @customerId;

END