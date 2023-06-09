CREATE PROCEDURE [dbo].[usp_ValidateReferenceStandards]          
@RefStdName NVARCHAR(max) NULL,        
@MasterDataTypeId INT,        
@CustomerId  INT         
AS                   
BEGIN          
DECLARE @PRefStdName nvarchar(max) = @RefStdName;              
DECLARE @PMasterDataTypeId INT=@MasterDataTypeId        
DECLARE @PCustomerId  INT=@CustomerId        

	DECLARE @IsNameAlreadyExist BIT = 0;

	IF EXISTS(SELECT TOP 1 1 FROM ReferenceStandard PRS WITH (NOLOCK) WHERE PRS.CustomerId=@PCustomerId 
																  AND  PRS.RefStdName = @PRefStdName 
																  AND ISNULL(PRS.IsDeleted, 0) = 0)
			BEGIN
				SET @IsNameAlreadyExist = 1;
			END
	SELECT @IsNameAlreadyExist AS IsNameAlreadyExist
END
-- EXEC usp_ValidateReferenceStandards 'NFRC 400', 1, 235