CREATE PROCEDURE [dbo].[usp_SaveImage]
(  
@ImagePath NVARCHAR(255),  
@LuImageSourceTypeId INT,  
@CustomerId INT
)  
AS  
BEGIN  
DECLARE @PImagePath NVARCHAR(255) = @ImagePath;  
DECLARE @PLuImageSourceTypeId INT = @LuImageSourceTypeId;  
DECLARE @PCustomerId INT = @CustomerId;  
  
INSERT INTO ProjectImage (ImagePath, LuImageSourceTypeId, CreateDate, ModifiedDate,CustomerId)  
VALUES (@PImagePath, @PLuImageSourceTypeId, GETUTCDATE(), GETUTCDATE(),@PCustomerId)  
  
SELECT  
CAST(SCOPE_IDENTITY() AS INT) AS projectImageId;  
  
END