CREATE Procedure [dbo].[usp_UpdateProjectSpecViewId]
(  
	@ProjectId int, @SpecViewId int  
)  
AS  
Begin  
DECLARE @PProjectId int = @ProjectId;  
DECLARE @PSpecViewId int = @SpecViewId;  
  
UPDATE PS  
SET PS.SpecViewModeId = @PspecViewId  
FROM ProjectSummary PS WITH (NOLOCK)  
WHERE PS.ProjectId = @PprojectId;  
  
END; 
