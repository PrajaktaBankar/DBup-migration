CREATE PROCEDURE [dbo].[usp_GetDefaultDateFormat]   -- EXEC [dbo].[usp_GetDefaultDateFormat] 1977,2  
(      
 @ProjectId int,        
 @MasterDataTypeId int      
)      
AS          
BEGIN        
          
 DECLARE @PProjectId int = @ProjectId;        
 DECLARE @PMasterDataTypeId int = @MasterDataTypeId;      
      
 DROP TABLE IF EXISTS #ProjectDateFormatTemp;    
    
 SELECT TOP 1      
  PDF.ProjectDateFormatId        
  ,PDF.MasterDataTypeId        
  ,ISNULL(PDF.ProjectId, 0) AS ProjectId        
  ,ISNULL(PDF.CustomerId, 0) AS CustomerId        
  ,ISNULL(PDF.UserId, 0) AS UserId      
  ,PDF.ClockFormat        
  ,PDF.[DateFormat]        
 INTO #ProjectDateFormatTemp      
 FROM [ProjectDateFormat] PDF WITH (NOLOCK)        
 WHERE PDF.ProjectId = @PProjectId AND PDF.MasterDataTypeId = @PMasterDataTypeId;      
        
  IF NOT EXISTS(SELECT TOP 1 1 FROM #ProjectDateFormatTemp)        
  BEGIN        
   SELECT        
    PDF.ProjectDateFormatId        
    ,PDF.MasterDataTypeId        
    ,ISNULL(PDF.ProjectId, 0) AS ProjectId        
    ,ISNULL(PDF.CustomerId, 0) AS CustomerId        
    ,ISNULL(PDF.UserId, 0) AS UserId        
    ,PDF.ClockFormat        
    ,PDF.[DateFormat]        
   FROM [ProjectDateFormat] PDF WITH (NOLOCK)        
   WHERE PDF.MasterDataTypeId = @PMasterDataTypeId   
    AND PDF.ProjectId IS NULL   
    AND PDF.CustomerId IS NULL   
    AND PDF.UserId IS NULL;  
  END    
  ELSE  
  BEGIN  
   SELECT * FROM #ProjectDateFormatTemp;  
  END  
END