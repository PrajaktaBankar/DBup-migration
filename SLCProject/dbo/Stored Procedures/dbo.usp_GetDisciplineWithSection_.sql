
CREATE PROCEDURE [dbo].[usp_GetDisciplineWithSection]  
(    @ProjectId INT ,            
     @MasterDataTypeid  INT            
 )            
AS                  
BEGIN              
  SELECT              
 DisciplineId AS DisciplineId              
   ,MasterDataTypeId              
   ,Name              
   ,IsActive              
   ,IsBundle              
   ,DisplayName            
   ,Initial            
   INTO #DisciplineList            
FROM SLCMaster..Discipline  WITH (NOLOCK)  WHERE  MasterDataTypeid=@MasterDataTypeid  
ORDER BY  Initial          
DECLARE @DisciplineListCSV AS TABLE (RNO INT,Txt NVARCHAR(MAX),Initial NVARCHAR(10)) 

  SELECT ROW_NUMBER() OVER(ORDER BY SectionId) AS rowId, mSectionId,SectionId ,CAST('' AS NVARCHAR(MAX)) AS DisplayName,            
  CAST('' AS NVARCHAR(MAX)) AS Initial,CAST('' AS NVARCHAR(MAX)) AS IdList            
INTO #ProjectSectionResult            
From ProjectSection  WITH (NOLOCK)           
WHERE ProjectId=@ProjectId and IsDeleted=0 and IsLastLevel=1            
        and mSectionId>0    


	SELECT A.SectionId, A.mSectionId
		,(SELECT DL.DisciplineId AS Id, Initial, DL.DisplayName
			FROM SLCMaster..DisciplineSection DS WITH (NOLOCK)
			INNER JOIN #DisciplineList DL ON DS.DisciplineId=DL.DisciplineId
			WHERE DS.SectionId=A.mSectionId ORDER BY Initial FOR JSON AUTO
		  ) AS SortList
	FROM #ProjectSectionResult A
	INNER JOIN SLCMaster..DisciplineSection DS WITH (NOLOCK) ON A.mSectionId = DS.SectionId
	INNER JOIN #DisciplineList DL ON DS.DisciplineId=DL.DisciplineId
	GROUP BY A.SectionId, A.mSectionId
	ORDER BY A.mSectionId


 --DECLARE @SectionId INT , @i INT=1 , @Count INT=(SELECT COUNT(1) FROM #ProjectSectionResult)            
            
--WHILE @i<=@Count            
-- BEGIN            
--      SET @SectionId = (SELECT mSectionId FROM  #ProjectSectionResult WHERE rowId=@i)            
            
--   INSERT INTO  @DisciplineListCSV
--    SELECT  DL.DisciplineId ,DL.DisplayName,Initial  FROM SLCMaster..DisciplineSection DS WITH (NOLOCK)            
--   INNER JOIN #DisciplineList DL ON             
--   DS.DisciplineId=DL.DisciplineId 
--   WHERE DS.SectionId=@SectionId  
--   ORDER BY Initial 
   
--   UPDATE #ProjectSectionResult             
--   SET DisplayName =(select RNO as Id,Initial ,Txt as DisplayName  from @DisciplineListCSV 
--   FOR JSON AUTO)           
--   WHERE rowId=@i 
           
--   Delete from @DisciplineListCSV
	           
         
          
--   SET @i=@i+1            
            
-- END            
-- SELECT  SectionId,mSectionId,DisplayName as SortList  FROM  #ProjectSectionResult  ORDER BY mSectionId            
END 



GO