CREATE PROCEDURE [dbo].[usp_DeleteSectionProjectPageSettings]
	@ProjectId INT,  
	@CustomerId INT,
	@SectionId INT
AS      
BEGIN
	DECLARE @PProjectId INT = @ProjectId;
	DECLARE @PCustomerId INT = @CustomerId;
    DECLARE @PSectionId INT = CASE WHEN @SectionId > 0 THEN @SectionId ELSE 0 END;  

IF(@PSectionId IS NOT NULL AND @PSectionId > 0)
	BEGIN
		DELETE FROM ProjectPageSetting 
		WHERE ProjectId = @PProjectId
			AND CustomerId = @PCustomerId
			AND SectionId = @PSectionId

		DELETE FROM ProjectPaperSetting
		WHERE ProjectId = @PProjectId
			AND CustomerId = @PCustomerId
		AND SectionId = @PSectionId
	END
END
GO