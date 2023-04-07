CREATE PROCEDURE usp_GetSortedProjectList        
 @IsDesc BIT NULL = NULL        
,@ColName NVARCHAR(255) NULL = NULL        
AS         
BEGIN        
        
IF(@ColName='customProjectId')         
BEGIN        
        
  INSERT INTO #customProj(SortOrder,ProjectId,CustomProjectId)         
  SELECT DISTINCT Row_Number() OVER (ORDER BY P.CustomProjectIdRaw ASC) AS SortOrder,              
  P.ProjectId, P.CustomProjectId AS CustomProjectId         
  FROM #filteredProjectIdList P with(nolock)              
END        
        
ELSE IF(@ColName='name')         
BEGIN        
        
  INSERT INTO #customProj(SortOrder,ProjectId,CustomProjectId)         
  SELECT DISTINCT Row_Number() OVER (ORDER BY P.ProjectNameRaw ASC) AS SortOrder,              
  P.ProjectId, P.CustomProjectId AS CustomProjectId         
  FROM #filteredProjectIdList P with(nolock)              
END        
ELSE IF(@ColName='modifiedUserFullName')        
BEGIn        
  INSERT INTO #customProj(SortOrder,ProjectId,CustomProjectId)         
   SELECT DISTINCT Row_Number() OVER (ORDER BY UF.LastAccessByFullName ASC) AS SortOrder,              
   P.ProjectId, P.CustomProjectId AS CustomProjectId         
   FROM #filteredProjectIdList P with(nolock)        
   LEFT JOIN UserFolder UF WITH (NOLOCK)            
   ON UF.ProjectId = P.ProjectId               
        
END        
ELSE IF(@ColName ='projectAccessTypeName')        
BEGIN        
 INSERT INTO #customProj(SortOrder,ProjectId,CustomProjectId)        
      SELECT DISTINCT Row_Number() OVER (ORDER BY PSM.ProjectAccessTypeId Asc) AS SortOrder,              
   P.ProjectId, P.CustomProjectId AS CustomProjectId         
   FROM #filteredProjectIdList P with(nolock)        
  INNER JOIN [dbo].[ProjectSummary] PSM WITH (NOLOCK)               
     ON PSM.ProjectId = p.ProjectId                   
END
ELSE IF(@ColName ='systemProjectId')        
BEGIN        
 INSERT INTO #customProj(SortOrder,ProjectId,CustomProjectId)        
 SELECT DISTINCT Row_Number() OVER (ORDER BY UF.ProjectId ASC) AS SortOrder,              
   P.ProjectId, P.CustomProjectId AS CustomProjectId         
   FROM #filteredProjectIdList P with(nolock)        
   LEFT JOIN UserFolder UF WITH (NOLOCK)            
   ON UF.ProjectId = P.ProjectId                    
END         
ELSE        
        
 INSERT INTO #customProj(SortOrder,ProjectId,CustomProjectId)        
 SELECT DISTINCT Row_Number() OVER (ORDER BY UF.LastAccessed ASC) AS SortOrder,              
   P.ProjectId, P.CustomProjectId AS CustomProjectId         
   FROM #filteredProjectIdList P with(nolock)        
   LEFT JOIN UserFolder UF WITH (NOLOCK)            
   ON UF.ProjectId = P.ProjectId         
        
END 