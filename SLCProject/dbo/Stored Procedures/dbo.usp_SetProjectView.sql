CREATE Procedure [dbo].[usp_SetProjectView]
(
@ProjectId int , @SpecViewModeId int
)
AS
Begin
DECLARE @PProjectId int = @ProjectId;
DECLARE @PSpecViewModeId int = @SpecViewModeId;

UPDATE PS
SET PS.SpecViewModeId = @PSpecViewModeId
FROM ProjectSummary PS WITH (NOLOCK)
WHERE PS.ProjectId = @PProjectId

END;

GO
