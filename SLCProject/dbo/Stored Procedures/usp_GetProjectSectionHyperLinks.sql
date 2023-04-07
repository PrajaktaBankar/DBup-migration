CREATE PROCEDURE usp_GetProjectSectionHyperLinks
(  
	@ProjectId INT,    
	@SectionId INT    
)
AS    
BEGIN    
	SET NOCOUNT ON;  

	--FETCH HYPERLINKS FROM PROJECT DB    
	SELECT    
	   HLNK.HyperLinkId,    
	   HLNK.LinkTarget,    
	   HLNK.LinkText,    
	   'U' AS [Source]
	FROM ProjectHyperLink HLNK WITH (NOLOCK)    
	WHERE HLNK.SectionId = @SectionId AND HLNK.ProjectId = @ProjectId;

END
