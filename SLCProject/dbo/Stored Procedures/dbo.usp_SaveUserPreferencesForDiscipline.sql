CREATE PROC usp_SaveUserPreferencesForDiscipline 
(  
 @CustomerId INT,  
 @UserId INT=0,  
 @PreferenceName NVARCHAR(100),  
 @PreferenceValue NVARCHAR(500),
 @MasterDataTypeId INT   
)  
AS  
BEGIN  
 DECLARE @UserPreferenceId INT=(SELECT TOP 1 UserPreferenceId FROM UserPreference WITH(NOLOCK) WHERE CustomerId=@CustomerId and [Name]=@PreferenceName and (UserId=@UserId or @UserId=0))  
IF(ISNULL(@UserPreferenceId,0)=0)  
 BEGIN  
   INSERT INTO UserPreference(UserId,CustomerId,Name,Value,CreatedDate)  
   VALUES(@UserId,@CustomerId,@PreferenceName,CONCAT('{"',@MasterDataTypeId,'":',@PreferenceValue,'}'),GETUTCDATE())    
 END 
  
ELSE  
 BEGIN  
  DROP TABLE IF EXISTS #t
  CREATE TABLE #t([key] NVARCHAR(10),[value] NVARCHAR(MAX))
  DECLARE @jsonValue NVARCHAR(MAX)=(SELECT [Value] FROM UserPreference WITH(NOLOCK) WHERE UserPreferenceId=@UserPreferenceId)

  INSERT INTO #t([key],[value])
  SELECT [key],[value] FROM OPENJSON(@jsonValue)
   IF EXISTS(SELECT TOP 1 1 FROM #t WHERE [key]=@MasterDataTypeId)
    BEGIN
     UPDATE #t 
     SET [VALUE]=@PreferenceValue
     WHERE [Key]=@MasterDataTypeId
   END
   ELSE
    BEGIN
     INSERT INTO #t VALUES(@MasterDataTypeId,@PreferenceValue)
    END
 DECLARE @savedResult NVARCHAR(MAX)=(SELECT ','+CONCAT('"',[key],'":',[value],'') FROM #t FOR XML PATH(''))

 SET @savedResult=STUFF(@savedResult,1,1,'{')
 SET @savedResult=@savedResult+'}'

  UPDATE pref  
  SET pref.Value=@savedResult,  
  pref.ModifiedDate=GETUTCDATE()  
  FROM UserPreference pref WITH(NOLOCK)  
  WHERE pref.UserPreferenceId=@UserPreferenceId  
END 

  SELECT UserId,CustomerId,[Name],Value FROM  UserPreference WITH (NOLOCK)
  WHERE UserId=@UserId AND CustomerId=@CustomerId
END 





