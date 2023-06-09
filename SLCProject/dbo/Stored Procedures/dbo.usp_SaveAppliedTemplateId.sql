CREATE PROCEDURE [dbo].[usp_SaveAppliedTemplateId] (@ProjectId INT,  
@SectionId INT, @ProjectTemplateId INT, @SectionTemplateId INT)      
AS      
BEGIN
  
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PProjectTemplateId INT = @ProjectTemplateId;
DECLARE @PSectionTemplateId INT = @SectionTemplateId;
--CHECK IF ProjectId is given  
IF @PProjectId IS NOT NULL AND @PProjectId > 0  
BEGIN
UPDATE P
SET P.TemplateId = @PProjectTemplateId
FROM Project P WITH (NOLOCK)
WHERE P.ProjectId = @PProjectId
END

--CHECK IF SectionId is given  
IF @PSectionId IS NOT NULL
	AND @PSectionId > 0
BEGIN
UPDATE PS
SET PS.TemplateId = @PSectionTemplateId
FROM ProjectSection PS WITH (NOLOCK)
WHERE PS.SectionId = @PSectionId
END

END;

GO
