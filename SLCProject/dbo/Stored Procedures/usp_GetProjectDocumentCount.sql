CREATE PROCEDURE [dbo].[usp_GetProjectDocumentCount]                                   
  @ProjectId INT,
  @CustomerId INT
AS                                          
BEGIN

  	SELECT DL.SectionId, COUNT(DL.SectionId) AS DocumentCount
	FROM DocLibraryMapping AS DL WITH(NOLOCK)
	WHERE DL.CustomerId = @CustomerId AND DL.ProjectId = @ProjectId        
 	 AND ISNULL(DL.IsDeleted, 0) = 0 
	GROUP BY DL.SectionId;
                                                        
END
