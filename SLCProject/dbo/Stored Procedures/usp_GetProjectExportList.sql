CREATE PROC [dbo].[usp_GetProjectExportList]              
(                      
 @CustomerId INT,      
 @UserId INT = 0             
)                      
AS                      
BEGIN                  
          
DECLARE @PCustomerId INT=@CustomerId,          
        @PUserId INT =@UserId  ,    
  @FileExportTypeId INT=2,    
  @FileExportType NVARCHAR(50)='Single file'    
       
Declare @temptable table (    
  ProjectExportId INT,FileName NVARCHAR(500),ProjectId INT,FilePath NVARCHAR(256),FileFormatType NVARCHAR(10),ProjectExportTypeId INT ,ExprityDate DateTime2,IsDeleted BIT ,CreatedDate DateTime2,    
CreatedBy INT ,CreatedByFullName NVARCHAR(50),ModifiedDate DateTime2,ModifiedBy INT,ModifiedByFullName NVARCHAR(50),FileExportTypeId INT,ProjectExportType NVARCHAR(50),FileExportType NVARCHAR(50)    
,CustomerId INT ,ProjectName NVARCHAR(150),FileStatus NVARCHAR(150) ,ProjectExportFlag BIT)          
       
 INSERT   INTO   @temptable     
SELECT          
 PE.ProjectExportId          
   ,COALESCE(PE.FileName,'')  FileName        
   ,PE.ProjectId          
   ,COALESCE(PE.FilePath ,'') FilePath        
   ,COALESCE(PE.FileFormatType ,'')  FileFormatType        
   ,LPET.ProjectExportTypeId           
   ,PE.ExprityDate          
   ,CAST(PE.IsDeleted AS BIT)  AS    IsDeleted      
   ,PE.CreatedDate          
   ,PE.CreatedBy          
   ,COALESCE(PE.CreatedByFullName,'') CreatedByFullName         
   ,PE.ModifiedDate          
   ,PE.ModifiedBy          
   ,COALESCE(PE.ModifiedByFullName,'')  ModifiedByFullName        
   ,LFET.FileExportTypeId          
   ,COALESCE(LPET.Name,'') AS ProjectExportType          
   ,COALESCE(LFET.Name,'') AS FileExportType          
   ,PE.CustomerId          
   ,COALESCE(PE.ProjectName,'')  ProjectName        
   ,COALESCE(PE.FileStatus ,'') FileStatus        
   ,CAST(0 AS BIT) AS ProjectExportFlag    
FROM ProjectExport PE WITH (NOLOCK)          
INNER JOIN LuProjectExportType LPET WITH (NOLOCK)          
 ON PE.ProjectExportTypeId = LPET.ProjectExportTypeId          
INNER JOIN LuFileExportType LFET WITH (NOLOCK)          
 ON PE.FileExportTypeId = LFET.FileExportTypeId          
WHERE CustomerId = @PCustomerId          
AND IsDeleted = 0 AND PE.CreatedBy = @PUserId    
AND PE.CreatedDate >  DATEADD(DAY,-30,GETUTCDATE())     
ORDER BY CreatedDate DESC                 
      
  INSERT   INTO   @temptable     
SELECT       
PrintRequestId AS ProjectExportId      
,COALESCE(FileName,'')  FileName     
,PD.ProjectId    
,'' AS FilePath    
,COALESCE('Pdf','') AS FileFormatType      
, PrintTypeId AS ProjectExportTypeId    
,DATEADD(m, 1, CreatedDate) AS ExprityDate    
,CAST(PD.IsDeleted AS BIT)  AS    IsDeleted       
,PD.CreatedDate    
,PD.CreatedBy    
,'' CreatedByFullName    
,PD.ModifiedDate    
,PD.ModifiedBy    
,'' ModifiedByFullName    
,@FileExportTypeId AS FileExportTypeId    
,COALESCE(LPET.Name,'') AS ProjectExportType     
,COALESCE(@FileExportType,'') AS FileExportType    
,PD.CustomerId    
,COALESCE(PD.ProjectName,'') AS ProjectName    
,COALESCE(PrintStatus,'') AS FileStatus      
,CAST(1 AS BIT) as ProjectExportFlag    
FROM PrintRequestDetails  PD WITH (NOLOCK)          
INNER JOIN LuProjectExportType LPET WITH (NOLOCK)       
ON PD.PrintTypeId = LPET.ProjectExportTypeId       
WHERE PD.CustomerId = @PCustomerId   AND PD.CreatedBy = @PUserId  AND IsDeleted = 0    
AND CreatedDate >  DATEADD(DAY,-30,GETUTCDATE())    
ORDER BY  CreatedDate DESC      
    
select * from @temptable ORDER BY  CreatedDate DESC      
     
END        
