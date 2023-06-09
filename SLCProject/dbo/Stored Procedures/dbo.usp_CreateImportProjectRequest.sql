CREATE PROCEDURE usp_CreateImportProjectRequest                   
 (               
 @SectionListJson NVARCHAR(MAX)      
 )      
 AS                    
BEGIN  
                
 DECLARE @PSectionListJson NVarChar(MAX) =@SectionListJson  
                
 DECLARE   @ImportProjectRequest TABLE  (SourceProjectId int, TargetProjectId int, SourceSectionId int, TargetSectionId int, CreatedById int, CustomerId int, CreateDate datetime2, ModifiedDate datetime2, StatusId TINYINT, CompletedPercentage TINYINT,   
  Source NVARCHAR(200), IsNotify bit,  DocumentFilePath nvarchar(1000), IsCreateFolderStructure bit,TargetParentSectionId int);  
  
INSERT INTO @ImportProjectRequest  
 SELECT  
  SourceProjectId  
    ,TargetProjectId  
    ,SourceSectionId  
    ,NULL AS TargetSectionId  
    ,CreatedById  
    ,CustomerId  
    ,GETUTCDATE() AS CreateDate  
    ,NULL AS ModifiedDate  
    ,StatusId  
    ,CompletedPercentage  
    ,Source  
    ,IsNotify  
    ,DocumentFilePath  
    ,IsCreateFolderStructure  
    ,TargetParentSectionId  
 FROM OPENJSON(@PSectionListJson)  
 WITH (  
 SourceProjectId INT '$.SourceProjectId',  
 TargetProjectId INT '$.TargetProjectId',  
 SourceSectionId INT '$.SourceSectionId',  
 CreatedById INT '$.CreatedById',  
 CustomerId INT '$.CustomerId',  
 StatusId TINYINT '$.StatusId',  
 CompletedPercentage TINYINT '$.CompletedPercentage',  
 Source NVARCHAR(200) '$.Source',  
 IsNotify BIT '$.IsNotify',  
 DocumentFilePath NVARCHAR(1000) '$.DocumentFilePath',  
 IsCreateFolderStructure BIT '$.IsCreateFolderStructure',  
 TargetParentSectionId INT '$.TargetParentSectionId'  
 );  
  
INSERT INTO ImportProjectRequest (SourceProjectId, TargetProjectId, SourceSectionId, TargetSectionId, CreatedById, CustomerId, CreatedDate, 
ModifiedDate, StatusId, CompletedPercentage, Source, IsNotify, DocumentFilePath, IsCreateFolderStructure, 
TargetParentSectionId)  
 SELECT  
  SourceProjectId  
    ,TargetProjectId  
    ,SourceSectionId  
    ,NULL AS TargetSectionId  
    ,CreatedById  
    ,CustomerId  
    ,GETUTCDATE() AS CreateDate  
    ,NULL AS ModifiedDate  
    ,StatusId  
    ,CompletedPercentage  
    ,Source  
    ,IsNotify  
    ,DocumentFilePath  
    ,IsCreateFolderStructure  
    ,TargetParentSectionId  
 FROM OPENJSON(@PSectionListJson)  
 WITH (  
 SourceProjectId INT '$.SourceProjectId',  
 TargetProjectId INT '$.TargetProjectId',  
 SourceSectionId INT '$.SourceSectionId',  
 CreatedById INT '$.CreatedById',  
 CustomerId INT '$.CustomerId',  
 StatusId TINYINT '$.StatusId',  
 CompletedPercentage TINYINT '$.CompletedPercentage',  
 Source NVARCHAR(200) '$.Source',  
 IsNotify BIT '$.IsNotify',  
 DocumentFilePath NVARCHAR(1000) '$.DocumentFilePath',  
 IsCreateFolderStructure BIT '$.IsCreateFolderStructure',  
 TargetParentSectionId INT '$.TargetParentSectionId'  
 );  
DECLARE @ImportProjectRequestList INT;  
SELECT  
 @ImportProjectRequestList = COUNT(1)  
FROM @ImportProjectRequest;  
  
SELECT TOP (@ImportProjectRequestList)  
 RequestId  
   ,SourceProjectId  
   ,SourceSectionId  
FROM ImportProjectRequest WITH (NOLOCK)  
ORDER BY RequestId DESC  
  
END 