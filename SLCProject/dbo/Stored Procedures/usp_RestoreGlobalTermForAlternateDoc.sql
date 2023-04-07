CREATE PROCEDURE [dbo].[usp_RestoreGlobalTermForAlternateDoc]
    @UserGlobalTermCode INT NULL,
    @UserGlobalTermName VARCHAR(50) NULL,
    @ProjectId INT NULL
AS
BEGIN
    DECLARE @PUserGlobalTermCode INT = @UserGlobalTermCode;
    DECLARE @PProjectId INT = @ProjectId;
    DECLARE @PUserGlobalTermName VARCHAR(50) = @UserGlobalTermName;
    DECLARE @PUserGlobalTermId INT;
    set @PUserGlobalTermId =
    (
        select UserGlobalTermId
        from ProjectGlobalTerm WITH (NOLOCK)
        where GlobalTermcode = @PUserGlobalTermCode
		and [Name] = @PUserGlobalTermName
        and ProjectId = @PProjectId
    )

    SET NOCOUNT ON;
    UPDATE UT
    SET UT.IsDeleted = 0
    from UserGlobalTerm UT WITH (NOLOCK)
    WHERE UT.UserGlobalTermId = @PUserGlobalTermId
		AND [Name] = @PUserGlobalTermName
		AND UT.ProjectId = @PProjectId

    UPDATE PGT
    SET PGT.IsDeleted = 0
    from ProjectGlobalTerm PGT WITH (NOLOCK)
    WHERE PGT.UserGlobalTermId = @PUserGlobalTermId
		AND [Name] = @PUserGlobalTermName
		AND PGT.ProjectId = @PProjectId
		AND PGT.GlobalTermSource = 'U'

    SELECT COALESCE((select GlobalTermId
    from ProjectGlobalTerm WITH (NOLOCK)
    where GlobalTermcode = @PUserGlobalTermCode
		  AND [Name] = @PUserGlobalTermName
          AND ProjectId = @PProjectId),0);
END
GO