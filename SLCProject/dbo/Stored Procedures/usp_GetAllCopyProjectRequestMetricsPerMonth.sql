CREATE proc usp_GetAllCopyProjectRequestMetricsPerMonth  
AS  
BEGIN  
 DECLARE @DATE_BEFORE_YEAR DATETIME=DATEADD(MONTH,-5,GETUTCDATE())  
 SELECT @DATE_BEFORE_YEAR=DATEADD(DAY,0-(DATEPART(DAY,@DATE_BEFORE_YEAR)-1),@DATE_BEFORE_YEAR)  
  
 DECLARE @TODAY DATETIME=GETUTCDATE()  
  
 DECLARE @MONTH AS TABLE(MONTH_NAME NVARCHAR(3))  
 DECLARE @FAILED AS TABLE(CNT INT)  
 DECLARE @TOTAL AS TABLE(CNT INT)  
 --DECLARE @RUNNIG AS TABLE(CNT INT)  
 DECLARE @COMPLETED AS TABLE(CNT INT)  
  
  
 WHILE(@DATE_BEFORE_YEAR<=@TODAY)  
 BEGIN  
  INSERT @MONTH  
  SELECT FORMAT(@DATE_BEFORE_YEAR, 'MMM', 'en-US')  
  
  INSERT @TOTAL  
  SELECT ISNULL(COUNT(1),0) FROM CopyProjectRequest WITH(NOLOCK)  
  WHERE Isdeleted=0 AND --StatusId=3  AND  
  MONTH(CreatedDate)=MONTH(@DATE_BEFORE_YEAR) 
   AND CopyProjectTypeId=1
  
  INSERT @COMPLETED  
  SELECT ISNULL(COUNT(1),0) FROM CopyProjectRequest WITH(NOLOCK)  
  WHERE Isdeleted=0 AND 
  StatusId=3  
  AND  MONTH(CreatedDate)=MONTH(@DATE_BEFORE_YEAR)  
   AND CopyProjectTypeId=1
  INSERT @FAILED  
  SELECT ISNULL(COUNT(1),0) FROM CopyProjectRequest WITH(NOLOCK)  
  WHERE Isdeleted=0 AND 
  StatusId IN(4,5)  
  AND  MONTH(CreatedDate)=MONTH(@DATE_BEFORE_YEAR)  
   AND CopyProjectTypeId=1
  SET @DATE_BEFORE_YEAR=DATEADD(MONTH,1,@DATE_BEFORE_YEAR)  
 END  
 SELECT   
 (SELECT MONTH_NAME FROM @MONTH FOR JSON PATH) as Months,  
 (SELECT * FROM @COMPLETED FOR JSON AUTO) as completed,  
 (SELECT * FROM @FAILED FOR JSON AUTO) as failed,  
 (SELECT * FROM @TOTAL FOR JSON AUTO) AS total  
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER   
END  
  