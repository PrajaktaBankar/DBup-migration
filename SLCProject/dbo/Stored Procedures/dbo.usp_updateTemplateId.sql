CREATE Procedure [dbo].[usp_updateTemplateId]
(
@projectId int, @templateId int
)
AS
Begin
DECLARE @PprojectId int = @projectId;
DECLARE @PtemplateId int = @templateId;

UPDATE P
SET P.TemplateId = @PtemplateId
FROM Project P WITH (NOLOCK)
WHERE P.ProjectId = @PprojectId

END;

GO
