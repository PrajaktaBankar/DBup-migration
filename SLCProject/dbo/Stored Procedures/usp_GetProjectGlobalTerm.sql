CREATE PROCEDURE usp_GetProjectGlobalTerm    
(  
 @ProjectId INT,    
 @CustomerId INT  
)    
AS    
BEGIN    
 SELECT    
    GlobalTermId,    
    COALESCE(mGlobalTermId, 0) AS mGlobalTermId,    
    [Name],    
    ISNULL([Value], '') AS [Value],    
    ISNULL(OldValue, '') AS OldValue,    
    CreatedDate,  
    CreatedBy,    
    COALESCE(ModifiedDate, NULL) AS ModifiedDate,    
    COALESCE(ModifiedBy, 0) AS ModifiedBy,    
    GlobalTermSource,    
    GlobalTermCode,    
    COALESCE(UserGlobalTermId, 0) AS UserGlobalTermId,    
    ISNULL(GlobalTermFieldTypeId, 1) AS GlobalTermFieldTypeId    
 FROM    
    ProjectGlobalTerm WITH (NOLOCK)    
 WHERE    
    ProjectId = @ProjectId    
    AND CustomerId = @CustomerId    
    AND isnull(IsDeleted,0) = 0     
 ORDER BY [Name]  
    
END