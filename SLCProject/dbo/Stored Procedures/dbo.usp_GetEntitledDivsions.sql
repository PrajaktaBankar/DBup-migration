CREATE PROCEDURE [dbo].[usp_GetEntitledDivsions]   
(  
 @AvailableDisciplineIds NVARCHAR(MAX) = ''  
)  
AS  
BEGIN
  
 DECLARE @PAvailableDisciplineIds NVARCHAR(MAX) = @AvailableDisciplineIds;
--Fills #AvailableDisciplineIdTbl  
SELECT
	Id AS DisciplineId INTO #AvailableDisciplineIdTbl
FROM dbo.udf_GetSplittedIds(@PAvailableDisciplineIds, ',')

--Fill all Divisions under available discipline Ids  
SELECT DISTINCT
	(PS.DivisionId) AS DivisionId INTO #SelectedDivisions
FROM [SLCMaster].[dbo].[DisciplineSection] DS WITH (NOLOCK)
INNER JOIN #AvailableDisciplineIdTbl ADT
	ON DS.DisciplineId = ADT.DisciplineId
INNER JOIN [ProjectSection] PS WITH (NOLOCK)
	ON DS.SectionId = PS.mSectionId
WHERE PS.DivisionId IS NOT NULL

SELECT
	D.DivisionId
   ,D.DivisionCode
   ,D.DivisionTitle
   ,D.SortOrder
   ,D.IsActive
   ,D.MasterDataTypeId
   ,CASE
		WHEN SD.DivisionId IS NULL THEN 0
		ELSE 1
	END AS IsEntitledByAdmin
FROM [SLCMaster].[dbo].Division D WITH (NOLOCK)
LEFT JOIN #SelectedDivisions SD
	ON SD.DivisionId = D.DivisionId
WHERE D.MasterDataTypeId = 1
END

GO
