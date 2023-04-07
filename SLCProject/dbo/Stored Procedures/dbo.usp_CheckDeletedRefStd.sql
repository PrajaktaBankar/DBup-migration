CREATE PROCEDURE [dbo].[usp_CheckDeletedRefStd]    
(
	@RefStdId INT
)     
AS
BEGIN  
    
	DECLARE @PRefStdId INT = @RefStdId;  
	SELECT TOP 1 IsDeleted
	FROM ReferenceStandard WITH (NOLOCK)  
	WHERE RefStdId = @PRefStdId
	--WHERE RefStdCode = @PRefStdCode  
	OPTION (FAST 1);
  
END;