CREATE PROCEDURE [dbo].[usp_UpdateProjectSummaryInfo]       
(       
@SummaryInfoType INT,       
@SummaryInfoDetail NVARCHAR(MAX)       
)       
AS       
BEGIN       
      
DECLARE @PSummaryInfoType INT = @SummaryInfoType       
DECLARE @PSummaryInfoDetail NVARCHAR(MAX) = @SummaryInfoDetail       
      
CREATE TABLE #SummaryInfoTbl(       
CustomerId INT,       
ProjectId INT,       
ProjectName NVARCHAR(MAX),       
ActiveSectionsCount INT,       
TotalSectionsCount INT,       
SpecViewModeId INT,       
TrackChangesModeId TINYINT,
IsMigratedProject BIT,       
CountryId INT,       
StateProvinceId INT,       
StateProvinceName nvarchar(50),       
CityId INT,       
CityName nvarchar(50),       
ProjectTypeId INT,       
FacilityTypeId INT,       
ProjectSize INT,       
ProjectCost INT,       
ProjectSizeUOM INT,       
IsPrintReferenceEditionDate BIT,       
IsIncludeRsInSection BIT,       
IsIncludeReInSection BIT,       
IsActivateRsCitation BIT,       
SourceTagFormat NVARCHAR(MAX),       
UnitOfMeasureValueTypeId INT,       
IsNamewithHeld BIT,       
IsProjectNameExist BIT,       
IsProjectNameModified BIT,      
ProjectGlobalTermId NVARCHAR(MAX),       
IsProjectGTIdModified BIT,    
ProjectAccessTypeId INT,    
OwnerId INT    
);       
      
    
INSERT INTO #SummaryInfoTbl       
SELECT TOP 1       
*       
FROM OPENJSON(@PSummaryInfoDetail)       
WITH (       
CustomerId INT '$.CustomerId',       
ProjectId INT '$.ProjectId',       
      
ProjectName NVARCHAR(MAX) '$.ProjectName',       
ActiveSectionsCount INT '$.ActiveSectionsCount',       
TotalSectionsCount INT '$.TotalSectionsCount',       
SpecViewModeId INT '$.SpecViewModeId',   
TrackChangesModeId TINYINT '$.TrackChangesModeId',
IsMigratedProject BIT '$.IsMigratedProject',       
      
CountryId INT '$.CountryId',       
StateProvinceId INT '$.StateProvinceId',       
StateProvinceName NVARCHAR(50) '$.StateProvinceName',       
CityId INT '$.CityId',       
CityName NVARCHAR(50) '$.CityName',       
ProjectTypeId INT '$.ProjectTypeId',       
FacilityTypeId INT '$.FacilityTypeId',       
ProjectSize INT '$.ProjectSize',       
ProjectCost INT '$.ProjectCost',       
ProjectSizeUOM INT '$.ProjectSizeUOM',       
      
IsPrintReferenceEditionDate BIT '$.IsPrintReferenceEditionDate',       
IsIncludeRsInSection BIT '$.IsIncludeRsInSection',       
IsIncludeReInSection BIT '$.IsIncludeReInSection',       
IsActivateRsCitation BIT '$.IsActivateRsCitation',       
      
SourceTagFormat NVARCHAR(MAX) '$.SourceTagFormat',       
UnitOfMeasureValueTypeId INT '$.UnitOfMeasureValueTypeId',       
IsNamewithHeld BIT '$.IsNamewithHeld',       
IsProjectNameExist BIT '$.IsProjectNameExist',       
IsProjectNameModified BIT '$.IsProjectNameModified',       
ProjectGlobalTermId NVARCHAR(MAX) '$.GlobalTermProjectIdValue',      
IsProjectGTIdModified BIT '$.IsGTProjectIdValueModified'   ,    
ProjectAccessTypeId INT '$.ProjectAccessTypeId',    
OwnerId INT '$.OwnerId'    
);       
      
    
-- @PSummaryInfoType IS FOLLOWING       
DECLARE @ProjectInfo INT = 1;       
DECLARE @ProjectDetails INT = 2;       
DECLARE @ProjectHistory INT = 3;       
DECLARE @References INT = 4;       
DECLARE @SectionID INT = 5;       
DECLARE @UnitOfMeasure INT = 6;       
DECLARE @Permissions INT = 7;       
DECLARE @ProjectAccessTypeAndOwner INT=9;    
      
--DECLARE @IsNameAlreadyExist BIT = 0;       
      
IF @PSummaryInfoType = @ProjectInfo       
BEGIN      
UPDATE PS       
SET PS.SpecViewModeId = PST.SpecViewModeId, 
	PS.TrackChangesModeId = PST.TrackChangesModeId 
FROM ProjectSummary PS WITH (NOLOCK)
INNER JOIN #SummaryInfoTbl PST
ON PS.ProjectId = PST.ProjectId
      
DECLARE @ProjectCount INT = 0;       
DECLARE @CustomerId INT = 0;       
DECLARE @ProjectId INT = 0;       
DECLARE @ProjectName NVARCHAR(MAX) = '';       
      
DECLARE @IsModified BIT = 0;       
DECLARE @IsProjectGTIdModified BIT=0;      
DECLARE @ProjectGtId NVARCHAR(MAX) ='';       
      
SELECT       
@CustomerId = SIT.CustomerId       
,@ProjectName = SIT.ProjectName       
,@ProjectId = SIT.ProjectId       
,@IsModified = SIT.IsProjectNameModified       
,@IsProjectGTIdModified =SIT.IsProjectGTIdModified      
,@ProjectGtId =SIT.ProjectGlobalTermId      
FROM #SummaryInfoTbl SIT       
      
IF @IsModified = 1 -- Update only if modifed       
BEGIN       
SELECT       
@ProjectCount = COUNT([Name])       
FROM Project  WITH (NOLOCK)  
WHERE (CustomerId = @CustomerId       
AND ProjectId != @ProjectId       
AND [Name] = @ProjectName)       
AND ISNULL(IsPermanentDeleted,0)=0       
      
IF @ProjectCount > 0 -- Project Name Already Exist       
BEGIN       
UPDATE #SummaryInfoTbl       
SET IsProjectNameExist = 1;       
END       
ELSE -- Update new name for project       
BEGIN       
UPDATE P       
SET P.[Name] = @ProjectName       
,P.[Description] = @ProjectName    
FROM Project P WITH (NOLOCK)  
WHERE P.ProjectId = @ProjectId       
      
UPDATE PGT       
SET PGT.[Value] = @ProjectName   
FROM ProjectGlobalTerm PGT WITH (NOLOCK)  
WHERE PGT.ProjectId = @ProjectId       
AND PGT.[Name] = 'Project Name';       
      
UPDATE #SummaryInfoTbl       
SET IsProjectNameExist = 0       
,IsProjectNameModified = 0;       
END       
END       
IF @IsProjectGTIdModified =1      
BEGIN       
UPDATE PGT       
SET [Value] = @ProjectGtId   
FROM ProjectGlobalTerm PGT WITH (NOLOCK)  
WHERE PGT.ProjectId = @ProjectId       
AND PGT.CustomerId=@CustomerId      
AND PGT.[Name] = 'Project ID';       
END       
      
END      
      
IF @PSummaryInfoType = @ProjectDetails       
BEGIN       
UPDATE PS       
SET PS.ProjectTypeId = PST.ProjectTypeId       
,PS.FacilityTypeId = PST.FacilityTypeId       
,PS.ActualSizeId = PST.ProjectSize       
,PS.SizeUOM = PST.ProjectSizeUOM       
,PS.ActualCostId = PST.ProjectCost       
FROM ProjectSummary PS WITH (NOLOCK)       
INNER JOIN #SummaryInfoTbl PST       
ON PS.ProjectId = PST.ProjectId       
      
UPDATE PA       
SET PA.CountryId = PST.CountryId       
,PA.StateProvinceId =       
CASE       
WHEN PST.StateProvinceId = 0 THEN NULL       
ELSE PST.StateProvinceId       
END       
,PA.CityId =       
CASE       
WHEN PST.CityId = 0 THEN NULL       
ELSE PST.CityId       
END       
,PA.StateProvinceName =       
CASE       
WHEN COALESCE(PST.StateProvinceName, '') = '' OR       
PST.StateProvinceId != 0 THEN NULL       
ELSE PST.StateProvinceName       
END       
,PA.CityName =       
CASE       
WHEN COALESCE(PST.CityName, '') = '' OR       
PST.CityId != 0 THEN NULL       
ELSE PST.CityName       
END       
FROM ProjectAddress PA WITH (NOLOCK)       
INNER JOIN #SummaryInfoTbl PST       
ON PA.ProjectId = PST.ProjectId       
      
END       
      
--IF @PSummaryInfoType=@ProjectHistory       
--BEGIN       
-- SELECT * FROM #SummaryInfoTbl       
--END       
      
IF @PSummaryInfoType = @References       
BEGIN       
UPDATE PS       
SET PS.IsIncludeRsInSection = PST.IsIncludeRsInSection       
,PS.IsIncludeReInSection = PST.IsIncludeReInSection       
,PS.IsPrintReferenceEditionDate = PST.IsPrintReferenceEditionDate       
,PS.IsActivateRsCitation = PST.IsActivateRsCitation       
FROM ProjectSummary PS WITH (NOLOCK)       
INNER JOIN #SummaryInfoTbl PST       
ON PS.ProjectId = PST.ProjectId       
END       
      
IF @PSummaryInfoType = @SectionID       
BEGIN       
UPDATE PS       
SET PS.SourceTagFormat = PST.SourceTagFormat       
FROM ProjectSummary PS WITH (NOLOCK)       
INNER JOIN #SummaryInfoTbl PST       
ON PS.ProjectId = PST.ProjectId       
END       
      
IF @PSummaryInfoType = @UnitOfMeasure       
BEGIN       
UPDATE PS       
SET PS.UnitOfMeasureValueTypeId = PST.UnitOfMeasureValueTypeId       
FROM ProjectSummary PS WITH (NOLOCK)       
INNER JOIN #SummaryInfoTbl PST       
ON PS.ProjectId = PST.ProjectId       
END       
      
IF @PSummaryInfoType = @Permissions       
BEGIN       
UPDATE P       
SET P.IsNameWithHeld = PST.IsNameWithHeld       
FROM Project P WITH (NOLOCK)       
INNER JOIN #SummaryInfoTbl PST       
ON P.ProjectId = PST.ProjectId       
END       
      
DECLARE @SummaryInfoGTValueTbl TABLE (       
CustomerId INT       
,ProjectId INT       
,CityName NVARCHAR(MAX)       
,StateProvinceName NVARCHAR(MAX)       
)       
      
INSERT INTO @SummaryInfoGTValueTbl     
SELECT TOP 1       
*       
FROM OPENJSON(@PSummaryInfoDetail)       
WITH (       
CustomerId INT '$.CustomerId',       
ProjectId INT '$.ProjectId',       
CityName NVARCHAR(MAX) '$.CityName',       
StateProvinceName NVARCHAR(MAX) '$.StateProvinceName'       
)       
      
UPDATE PGT       
SET value = GTTBL.StateProvinceName       
FROM ProjectGlobalTerm PGT WITH (NOLOCK)       
INNER JOIN @SummaryInfoGTValueTbl GTTBL       
ON PGT.ProjectId = GTTBL.ProjectId       
AND PGT.CustomerId = GTTBL.CustomerId       
WHERE PGT.Name = 'Project Location State'       
AND PGT.GlobalTermFieldTypeId = 3       
      
UPDATE PGT       
SET value = GTTBL.CityName       
FROM ProjectGlobalTerm PGT WITH (NOLOCK)       
INNER JOIN @SummaryInfoGTValueTbl GTTBL       
ON PGT.ProjectId = GTTBL.ProjectId       
AND PGT.CustomerId = GTTBL.CustomerId       
WHERE PGT.Name = 'Project Location City'       
AND PGT.GlobalTermFieldTypeId = 3       
      
UPDATE PGT       
SET value = GTTBL.StateProvinceName       
FROM ProjectGlobalTerm PGT WITH (NOLOCK)       
INNER JOIN @SummaryInfoGTValueTbl GTTBL       
ON PGT.ProjectId = GTTBL.ProjectId       
AND PGT.CustomerId = GTTBL.CustomerId       
WHERE PGT.Name = 'Project Location Province'       
AND PGT.GlobalTermFieldTypeId = 3       
      
     
IF @PSummaryInfoType = @ProjectAccessTypeAndOwner       
 BEGIN      
 UPDATE PS       
 SET PS.ProjectAccessTypeId = PST.ProjectAccessTypeId,    
 PS.OwnerId=PST.OwnerId       
 FROM ProjectSummary PS WITH (NOLOCK)       
 INNER JOIN #SummaryInfoTbl PST       
 ON PS.ProjectId = PST.ProjectId     
END     
    
SELECT       
*       
FROM #SummaryInfoTbl       
      
END  