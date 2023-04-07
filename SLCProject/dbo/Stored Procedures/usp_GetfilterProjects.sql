CREATE PROCEDURE [dbo].[usp_GetfilterProjects]            
   @SearchField NVARCHAR(255) NULL = NULL             
  ,@ColName NVARCHAR(255) NULL = NULL             
AS            
BEGIN            
 SET @SearchField = REPLACE(@SearchField, '_', '[_]')                                                
 SET @SearchField = REPLACE(@SearchField, '%', '[%]')                                                
 DECLARE @isnumeric AS INT = ISNUMERIC(@SearchField);                   
 IF @SearchField = ''                   
 SET @SearchField = NULL;              
  DECLARE @IncludeProjectIdColumn BIT=1  
  select Top 1 @IncludeProjectIdColumn=isShow FROM #ProjectListColumnVisibilitySetting where [name]='customProjectId'   
  IF(@ColName in('customProjectId','name'))     
  BEGIN    
   IF(@IncludeProjectIdColumn=1)    
   BEGIN    
    INSERT INTO #filteredProjectIdList(ProjectId,CustomProjectId,CustomProjectIdRaw,ProjectNameRaw)            
      (Select DISTINCT     
     --ROW_NUMBER() OVER(ORDER BY T.ProjectId) AS RowId,     
     T.ProjectId,          
    PT.Value As CustomProjectId          
    ,dbo.udf_ExpandDigits(trim(PT.value),10,0) as CustomProjectIdRaw          
    ,dbo.udf_ExpandDigits(trim(P.Name),10,0) As ProjectNameRaw           
    FROM #accessibleProjectIds T            
    INNER JOIN Project P WITH (NOLOCK)            
    ON T.ProjectId = P.ProjectId            
    INNER JOIN ProjectGlobalTerm PT WITH (NOLOCK)             
    ON p.ProjectId=PT.ProjectId              
    AND PT.[Name]='Project Id'             
    AND isnull(PT.IsDeleted,0)=0               
      Where (@SearchField IS NULL OR p.[Name] LIKE '%' + COALESCE(@SearchField, p.[Name]) + '%')              
      OR (p.[ProjectId]   LIKE '%' +  @SearchField + '%')            
      OR  (PT.value like '%' + COALESCE(@SearchField,PT.value) + '%'))           
   END    
   ELSE    
   BEGIN    
    INSERT INTO #filteredProjectIdList(ProjectId,CustomProjectId,CustomProjectIdRaw,ProjectNameRaw)            
       Select DISTINCT     
     --ROW_NUMBER() OVER(ORDER BY T.ProjectId) AS RowId,     
     T.ProjectId,          
    '0' As CustomProjectId          
    ,'0' as CustomProjectIdRaw          
    ,dbo.udf_ExpandDigits(trim(P.Name),10,0) As ProjectNameRaw           
    FROM #accessibleProjectIds T            
    INNER JOIN Project P WITH (NOLOCK)            
    ON T.ProjectId = P.ProjectId            
    --INNER JOIN ProjectGlobalTerm PT WITH (NOLOCK)             
    Where (@SearchField IS NULL OR p.[Name] LIKE '%' + COALESCE(@SearchField, p.[Name]) + '%')              
   END    
        END    
  ELSE    
  BEGIN    
   IF(@IncludeProjectIdColumn=1)    
   BEGIN    
     INSERT INTO #filteredProjectIdList(ProjectId,CustomProjectId,CustomProjectIdRaw,ProjectNameRaw)            
       (Select DISTINCT     
     --ROW_NUMBER() OVER(ORDER BY T.ProjectId) AS RowId,     
     T.ProjectId,          
    PT.Value As CustomProjectId          
    ,PT.value as CustomProjectIdRaw          
    ,P.Name As ProjectNameRaw           
    FROM #accessibleProjectIds T            
    INNER JOIN Project P WITH (NOLOCK)            
    ON T.ProjectId = P.ProjectId            
    INNER JOIN ProjectGlobalTerm PT WITH (NOLOCK)             
    ON p.ProjectId=PT.ProjectId              
    AND PT.[Name]='Project Id'             
    AND isnull(PT.IsDeleted,0)=0               
      Where (@SearchField IS NULL OR p.[Name] LIKE '%' + COALESCE(@SearchField, p.[Name]) + '%')              
      OR (p.[ProjectId]   LIKE '%' +  @SearchField + '%')            
      OR  (PT.value like '%' + COALESCE(@SearchField,PT.value) + '%'))            
   END    
   ELSE    
   BEGIN    
    INSERT INTO #filteredProjectIdList(ProjectId,CustomProjectId,CustomProjectIdRaw,ProjectNameRaw)            
       Select DISTINCT     
     T.ProjectId,          
    '0' As CustomProjectId          
    ,'0' as CustomProjectIdRaw          
    ,P.Name As ProjectNameRaw           
    FROM #accessibleProjectIds T            
    INNER JOIN Project P WITH (NOLOCK)            
 ON T.ProjectId = P.ProjectId                      
    Where (@SearchField IS NULL OR p.[Name] LIKE '%' + COALESCE(@SearchField, p.[Name]) + '%')              
   END    
  END    
END
