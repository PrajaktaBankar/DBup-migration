CREATE PROCEDURE [dbo].[usp_getDisciplineSectionId]      
  @ProjectId int       
 ,@CustomerId int      
 ,@DisciplineId NVARCHAR (1024) NULL=''        
 ,@DivisionId NVARCHAR (1024) NULL=''      
 ,@UserAccessDivisionId NVARCHAR (1024) = '' ,      
  @CatalogueType NVARCHAR (1024) NULL='FS'      
 AS       
BEGIN    
      
DECLARE @PProjectId int = @ProjectId;    
DECLARE @PCustomerId int = @CustomerId;    
DECLARE @PDisciplineId NVARCHAR (1024)  = @DisciplineId;    
DECLARE @PDivisionId NVARCHAR (1024)  = @DivisionId;    
DECLARE @PUserAccessDivisionId NVARCHAR (1024) = @UserAccessDivisionId;    
DECLARE @PCatalogueType NVARCHAR (1024) = @CatalogueType;    
    
  --Declare table variables        
  DECLARE @MasterDataTypeId int    
      
  CREATE TABLE #AdminDivisionIdTbl (DivisionId INT);    
      
  CREATE TABLE  #AdminDisciplineIdTbl (DisciplineId INT);    
      
  CREATE TABLE #UserAccessDivisionIdTbl (DivisionId INT);    
    
SET @PDisciplineId = IIF(TRIM(@PDisciplineId) = 'undefined', NULL, @PDisciplineId)    
SET @PDivisionId = IIF(TRIM(@PDivisionId) = 'undefined', NULL, @PDivisionId)    
SET @PuserAccessDivisionId = IIF(TRIM(@PuserAccessDivisionId) = 'undefined', NULL, @PuserAccessDivisionId)    
    
DROP TABLE IF EXISTS #SectionTable    
CREATE TABLE #SectionTable (        
 SectionId INT PRIMARY KEY CLUSTERED    
 ,mSectionId INT        
 ,DivisionId INT        
 ,IsLastLevel BIT        
 ,IsDisciplineEnabled BIT        
 ,IsUserSection BIT );    
    
SET @MasterDataTypeId = (SELECT TOP 1    
  p.MasterDataTypeId    
 FROM Project AS p WITH (NOLOCK)    
 WHERE p.ProjectId = @PProjectId    
 AND p.CustomerId = @PCustomerId)    
    
INSERT INTO #SectionTable    
 SELECT    
  ps.SectionId    
    ,ps.mSectionId    
    ,ps.DivisionId    
    ,ps.IsLastLevel    
    ,1 AS IsDisciplineEnabled    
    ,(CASE    
   WHEN PS.IsLastLevel = 1 AND    
    (PS.mSectionId IS NULL OR    
    PS.mSectionId <= 0 OR    
    PS.Author = 'USER') THEN 1    
   ELSE 0    
  END)    
  AS IsUserSection    
 FROM ProjectSection PS WITH (NOLOCK)    
 LEFT JOIN SLCMaster..Section MS WITH (NOLOCK)    
  ON PS.mSectionId = MS.SectionId    
 WHERE PS.ProjectId = @PprojectId    
 AND PS.CustomerId = @PcustomerId    
 AND PS.IsDeleted = 0    
 AND PS.IsLastLevel = 1    
    
  
INSERT INTO #AdminDisciplineIdTbl (DisciplineId)    
 SELECT    
  *    
 FROM dbo.fn_SplitString(@PDisciplineId, ',');    
    
INSERT INTO #AdminDivisionIdTbl (DivisionId)    
 SELECT    
  *    
 FROM dbo.fn_SplitString(@PDivisionId, ',');    
    
INSERT INTO #UserAccessDivisionIdTbl (DivisionId)    
 SELECT    
  *    
 FROM dbo.fn_SplitString(@PUserAccessDivisionId, ',');    
   
--Set Discipline Disabled if not accessible to disciplines came from ADMIN      
UPDATE PS    
SET PS.IsDisciplineEnabled = 0    
FROM #SectionTable PS WITH (NOLOCK)    
INNER JOIN SLCMaster..DisciplineSection DS WITH (NOLOCK)    
 ON PS.mSectionId = DS.SectionId    
INNER JOIN SLCMaster..Discipline D WITH (NOLOCK)    
 ON DS.DisciplineId = D.DisciplineId    
LEFT JOIN #AdminDisciplineIdTbl DSTbl    
 ON D.DisciplineId = DSTbl.DisciplineId    
WHERE PS.IsLastLevel = 1    
AND PS.IsUserSection = 0    
AND DSTbl.DisciplineId IS NULL    
    
--Set discipline enabled if accessible to disciplines came from ADMIN      
UPDATE PS    
SET PS.IsDisciplineEnabled = 1    
FROM #SectionTable PS    
INNER JOIN SLCMaster..DisciplineSection DS WITH (NOLOCK)    
 ON PS.mSectionId = DS.SectionId    
INNER JOIN SLCMaster..Discipline D WITH (NOLOCK)    
 ON DS.DisciplineId = D.DisciplineId    
INNER JOIN #AdminDisciplineIdTbl DSTbl    
 ON D.DisciplineId = DSTbl.DisciplineId    
WHERE PS.IsLastLevel = 1    
AND PS.IsUserSection = 0    
    
--Set Discipline enabled if accessible to divisions came from ADMIN in case of NMS      
IF (@MasterDataTypeId = 2    
 OR @MasterDataTypeId = 3)    
BEGIN    
UPDATE PS    
SET PS.IsDisciplineEnabled = 1    
FROM #SectionTable PS    
INNER JOIN #AdminDivisionIdTbl DTbl    
 ON PS.DivisionId = DTbl.DivisionId    
WHERE PS.IsLastLevel = 1    
AND @MasterDataTypeId IN (2, 3)    
END    
    
--Set Discipline Disabled if not accessible to divisions       
IF EXISTS (SELECT TOP 1    
   *    
  FROM #UserAccessDivisionIdTbl)    
BEGIN    
    
update #SectionTable    
set IsDisciplineEnabled = 0    
WHERE mSectionId is NULL    
    
UPDATE PS    
SET PS.IsDisciplineEnabled = 0    
FROM #SectionTable PS WITH (NOLOCK)    
LEFT JOIN #UserAccessDivisionIdTbl DTbl    
 ON PS.DivisionId = DTbl.DivisionId    
WHERE PS.IsLastLevel = 1    
AND PS.IsUserSection = 0    
AND DTbl.DivisionId IS NULL    
    
UPDATE PS    
SET PS.IsDisciplineEnabled = 1    
FROM #SectionTable PS WITH (NOLOCK)    
INNER JOIN #UserAccessDivisionIdTbl DTbl    
 ON PS.DivisionId = DTbl.DivisionId    
WHERE PS.IsLastLevel = 1    
AND PS.IsUserSection = 1    
--AND DTbl.DivisionId IS NOT NULL    
    
END    
    
--Set Discipline Disabled if catalogue type is not FS and restricted by table      
IF @PCatalogueType != 'FS'    
BEGIN    
UPDATE PS    
SET PS.IsDisciplineEnabled = 0    
FROM #SectionTable PS WITH (NOLOCK)    
INNER JOIN SLCMaster..SpecTypeSectionRestriction SSR WITH (NOLOCK)    
 ON PS.mSectionId = SSR.SectionId    
WHERE PS.IsLastLevel = 1    
AND PS.IsUserSection = 0    
AND @MasterDataTypeId IN (1, 4)    
END    
   
  -- TODO : Remove this code once USER Folder division access feature implemented.   
  UPDATE PS  
  SET PS.IsDisciplineEnabled=1  
  FROM #SectionTable PS   
  INNER JOIN CustomerDivision CD WITH (NOLOCK)  
  ON PS.DivisionId = CD.DivisionId  
  AND CD.CustomerId = @PCustomerId  
  AND ISNULL(CD.IsDeleted,0) = 0;  
    
     
SELECT    
 SectionId    
   ,IsDisciplineEnabled    
FROM #SectionTable WITH (NOLOCK)    
WHERE IsDisciplineEnabled = 0;    
END 