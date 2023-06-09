CREATE PROCEDURE [dbo].[usp_CheckDeletedGT]
(
	@ProjectId INT, 
	@CustomerId INT,
	@GlobalTermCode INT
)
AS
BEGIN
	DECLARE @PProjectId INT = @ProjectId;
	DECLARE @PCustomerId INT = @CustomerId;
	DECLARE @PGlobalTermCode INT = @GlobalTermCode;

	SELECT TOP 1 ISNULL(PGT.IsDeleted, 0) AS IsDeleted
	FROM ProjectGlobalTerm PGT WITH (NOLOCK)
	WHERE PGT.CustomerId = @PCustomerId
	AND PGT.ProjectId = @PProjectId
	AND PGT.GlobalTermCode = @PGlobalTermCode
	OPTION (FAST 1);

END