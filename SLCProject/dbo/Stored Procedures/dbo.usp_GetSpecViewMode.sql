CREATE PROCEDURE [dbo].[usp_GetSpecViewMode]  
(
	@ProjectId int,
	@CustomerId int
)
AS
BEGIN

	DECLARE @PProjectId int = @ProjectId;  
	DECLARE @PCustomerId int = @CustomerId;

	SELECT TOP 1 PS.SpecViewModeId
	FROM ProjectSummary PS WITH (NOLOCK)  
	WHERE PS.ProjectId = @PProjectId AND PS.CustomerId = @PCustomerId 
	OPTION (FAST 1);  
  
END;