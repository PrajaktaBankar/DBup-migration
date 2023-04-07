/*
 Server name : SLCProject_SqlSlcOp004 ( Server 04)
 Customer Support 68820: User Global Terms not showing for all projects 
*/

USE SLCProject_SqlSlcOp004
GO

DECLARE @CustomerId INT = 1812;

DECLARE @CreatedBy INT;

SELECT TOP 1 @CreatedBy = U.UserId 
FROM [Authentication].dbo.[User] U 
INNER JOIN [Authentication].dbo.[UserRole] UR  ON UR.UserId = U.UserId
WHERE U.CustomerId = @CustomerId 
AND ISNULL(U.IsDeleted, 0) = 0 AND ISNULL(U.IsActive, 0) = 1
AND ISNULL(UR.IsDeleted, 0) = 0 AND ISNULL(UR.IsActive, 0) = 1
AND UR.ModuleId = 4 -- SpecLink Cloud
AND UR.RoleTypeId = 2 -- System Manager

--SELECT @CreatedBy AS CreatedBy

-- get count of all user global terms created for given customer
DECLARE @UserGlobalTermCount INT;
SELECT @UserGlobalTermCount = COUNT(UserGlobalTermId) 
FROM UserGlobalTerm WHERe CustomerId = @CustomerId AND ISNULL(IsDeleted, 0) != 1;

IF OBJECT_ID('tempdb..#TempAffectedProjects') IS NOT NULL  
	DROP TABLE #TempAffectedProjects;

-- get all projects which dont have all user global terms i.e. < than @UserGlobalTermCount
SELECT ProjectId --, COUNT(GlobalTermId) AS Cnt 
INTO #TempAffectedProjects
FROM ProjectGlobalTerm 
WHERE CustomerId = @CustomerId
AND GlobalTermSource = 'U'
AND ISNULL(IsDeleted, 0) != 1
GROUP BY ProjectId
HAVING COUNT(GlobalTermId) < @UserGlobalTermCount
AND ProjectId IN (SELECT ProjectId FROM Project WITH(NOLOCK) WHERE CustomerId = @CustomerId AND ISNULL(IsDeleted, 0) = 0);

--SELECT COUNT(1) FROm #TempAffectedProjects

IF OBJECT_ID('tempdb..#TempUserGlobalTermCodes') IS NOT NULL  
	DROP TABLE #TempUserGlobalTermCodes;

SELECT MIN(GlobalTermCode) AS GlobalTermCode, UserGlobalTermId     
INTO #TempUserGlobalTermCodes
FROM ProjectGlobalTerm WITH (NOLOCK)    
WHERE CustomerId = @CustomerId AND ISNULL(IsDeleted,0)=0     
AND GlobalTermSource='U' AND  UserGlobalTermId IS NOT NULL
GROUP BY UserGlobalTermId;

--SELECT * FROM #TempUserGlobalTermCodes

IF OBJECT_ID('tempdb..#TempUserGlobalTermData') IS NOT NULL  
	DROP TABLE #TempUserGlobalTermData;

SELECT UGT.UserGlobalTermId, UGT.Name, UGT.Value, TGTCodes.GlobalTermCode 
INTO #TempUserGlobalTermData
FROM UserGlobalTerm UGT WITH(NOLOCK) 
INNER JOIN #TempUserGlobalTermCodes TGTCodes ON TGTCodes.UserGlobalTermId = UGT.UserGlobalTermId
WHERE UGT.CustomerId = @CustomerId AND ISNULL(UGT.IsDeleted, 0) = 0;

--SELECT * FROm #TempUserGlobalTermData

IF OBJECT_ID('tempdb..#TempRawData') IS NOT NULL  
	DROP TABLE #TempRawData;

SELECT *, @CustomerId AS CustomerId
INTO #TempRawData
FROM #TempUserGlobalTermData CROSS JOIN #TempAffectedProjects; 

INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, Name, Value,GlobalTermCode, 
			GlobalTermSource, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted)
SELECT 
NULL AS mGlobalTermId    
    ,A.ProjectId AS ProjectId    
    ,A.CustomerId AS CustomerId    
    ,A.Name    
    ,A.Value    
    ,A.GlobalTermCode    
    ,'U' AS GlobalTermSource    
    ,GETUTCDATE() AS CreatedDate    
    ,@CreatedBy AS CreatedBy    
    ,GETUTCDATE() AS ModifiedDate     
    ,@CreatedBy AS ModifiedBy    
    ,A.UserGlobalTermId AS UserGlobalTermId    
    ,0 AS IsDeleted    
FROM #TempRawData A
LEFT JOIN ProjectGlobalTerm B WITH(NOLOCK) ON B.CustomerId = A.CustomerId AND B.UserGlobalTermId = A.UserGlobalTermId  AND B.ProjectId = A.ProjectId
WHERE A.CustomerId = @CustomerId
AND B.UserGlobalTermId IS NULL






