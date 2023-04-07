CREATE PROCEDURE [dbo].[usp_GetImportDocLibraryCount]                                      
  @CustomerId INT  
AS                                            
BEGIN  
  
 SELECT COUNT(IDL.DocLibraryId) AS ImportDocLibraryCount
 FROM ImportDocLibrary AS IDL WITH(NOLOCK)  
 WHERE IDL.CustomerId = @CustomerId AND ISNULL(IDL.IsDeleted, 0) = 0
                                                          
END