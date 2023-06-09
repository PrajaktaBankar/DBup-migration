CREATE PROCEDURE usp_LogImportSectionRequest                 
 (             
 @SectionListJson NVARCHAR(MAX)    
 )              
 AS                  
BEGIN              
 DECLARE @PSectionListJson NVarChar(MAX) =@SectionListJson 
              
     DECLARE   @ImportSectionRequest TABLE  ( 
	  TargetProjectId int,  
	  TargetSectionId int, 
	  CreatedById int, 
	  CustomerId int,  
	  Source NVARCHAR(200));      
            
INSERT INTO  @ImportSectionRequest      
SELECT   TargetProjectId,   TargetSectionId, CreatedById ,CustomerId , Source
  FROM OPENJSON(@PSectionListJson)                  
  WITH (       
  TargetProjectId INT '$.TargetProjectId', 
  TargetSectionId INT '$.TargetSectionId',
   CreatedById INT '$.CreatedById',                         
   CustomerId INT '$.CustomerId',         
   Source NVARCHAR(200) '$.Source'      
  );                
              
  Insert INTO ImportProjectRequest (TargetProjectId, TargetSectionId, CreatedById, CustomerId, CreatedDate, ModifiedDate, StatusId, CompletedPercentage, Source, IsNotify)              
  SELECT  TargetProjectId,  TargetSectionId, CreatedById ,CustomerId , getutcdate() as CreateDate, null as ModifiedDate,1 AS StatusId,5 AS CompletedPercentage, Source,0 AS IsNotify    
  FROM @ImportSectionRequest       
             

DECLARE @ImportSectionCount INT;              
Select @ImportSectionCount=COUNT(1)FROM @ImportSectionRequest;              
              
SELECT TOP (@ImportSectionCount) RequestId, TargetSectionId FROM ImportProjectRequest WITH (NOLOCK) order by RequestId desc               
          
          
                  
END  