CREATE PROCEDURE [dbo].[usp_ValidateGlobalTerms]      
(
	@Name NVARCHAR(255),
	@CustomerId INT
)
AS         
BEGIN  
	DECLARE @PName NVARCHAR(255) = @Name;  
	DECLARE @PCustomerId INT= @CustomerId;  
	SET NOCOUNT ON;

	DECLARE @IsNameAlreadyExist BIT = 0;

	IF EXISTS(SELECT TOP 1 1 FROM [SLCMaster].dbo.GlobalTerm MGT WITH (NOLOCK) WHERE MGT.[Name] = @PName)
		BEGIN
			SET @IsNameAlreadyExist = 1;
		END

	
	IF(@IsNameAlreadyExist = 0)
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM UserGlobalTerm GT WITH (NOLOCK) WHERE GT.[Name] = @PName  
																   AND GT.CustomerId = @PCustomerId 
																   AND ISNULL(GT.IsDeleted, 0) = 0)
		BEGIN
			SET @IsNameAlreadyExist = 1;
		END
	END

	SELECT @IsNameAlreadyExist AS IsNameAlreadyExist;
END
