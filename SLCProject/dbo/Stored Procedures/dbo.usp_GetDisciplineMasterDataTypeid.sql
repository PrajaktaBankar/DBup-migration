CREATE PROCEDURE [dbo].[usp_GetDisciplineMasterDataTypeid]   
(  
 @UserId INT=0,
 @MasterDataTypeid INT   
)      
AS
        
BEGIN 
   DECLARE @FALSE BIT =0
  SELECT    
 DisciplineId AS DisciplineId    
   ,MasterDataTypeId    
   ,Name    
   ,IsActive    
   ,IsBundle    
   ,DisplayName  
   ,Initial 
   ,@FALSE AS IsSelected 
   INTO #RESULTSET 
FROM SLCMaster..Discipline WITH (NOLOCK) WHERE MasterDataTypeid=@MasterDataTypeid  

DECLARE @UserPreferenceId INT=(SELECT TOP 1 UserPreferenceId FROM UserPreference WITH(NOLOCK) WHERE UserId=@UserId and [Name]='disciplineDetails') 

DROP TABLE IF exists #t
CREATE TABLE #t([key] NVARCHAR(10),[value] NVARCHAR(max))  
DECLARE @jsonValue NVARCHAR(max)=(SELECT [value] FROM  UserPreference WITH (NOLOCK) WHERE UserPreferenceId=@UserPreferenceId)

INSERT INTO #t([key],[value])
SELECT [key],[value] FROM OPENJSON(@jsonValue)

IF EXISTS(SELECT TOP 1 1 FROM #t WHERE [key]=@MasterDataTypeId)
BEGIN
DECLARE @disciplineIdList NVARCHAR(MAX)=(SELECT [value] FROM #t WHERE [key]=@MasterDataTypeId)

  SET @disciplineIdList= REPLACE(@disciplineIdList,'[','') 
  SET @disciplineIdList= REPLACE(@disciplineIdList,']','') 
  

  UPDATE rs
  SET isSelected=1
  FROM #RESULTSET rs
  INNER join  fn_SplitString(@disciplineIdList,',') dl
  ON rs.DisciplineId=dl.splitdata
      
END
ELSE
BEGIN
  UPDATE rs
  SET isSelected=1
  FROM #RESULTSET rs
END


SELECT * FROM #RESULTSET
    
END  


