  CREATE PROCEDURE [dbo].[usp_CreateProjectExport] (  
  @ProjectExportId INT  
 ,@FileName NVARCHAR(500)  
 ,@ProjectId INT  
 ,@FilePath NVARCHAR(256)  
 ,@FileFormatType NVARCHAR(10)  
 ,@ProjectExportTypeId INT  
 ,@CreatedBy INT  
 ,@CreatedByFullName NVARCHAR(50)  
 ,@FileExportTypeId INT  
 ,@CustomerId INT  
 ,@ProjectName NVARCHAR(150)  
 ,@FileStatus NVARCHAR(150)  
 ,@ModifiedBy INT  
 ,@ModifiedByFullName NVARCHAR(50) = NULL  
 )  
AS  
BEGIN  
 DECLARE @ProjectExport AS TABLE (  
  ProjectExportId INT  
  ,FileName NVARCHAR(500)  
  ,ProjectId INT  
  ,FilePath NVARCHAR(256)  
  ,FileFormatType NVARCHAR(10)  
  ,ProjectExportTypeId INT  
  ,ExprityDate DATETIME  
  ,IsDeleted BIT  
  ,CreatedDate DATETIME  
  ,CreatedBy INT  
  ,CreatedByFullName NVARCHAR(50)  
  ,ModifiedDate DATETIME  
  ,ModifiedBy INT  
  ,ModifiedByFullName NVARCHAR(50)  
  ,FileExportTypeId INT  
  ,CustomerId INT  
  ,ProjectName NVARCHAR(150)  
  ,FileStatus NVARCHAR(150)  
  ,ProjectExportType NVARCHAR(50)  
  ,FileExportType NVARCHAR(50)  
  )  
  
 INSERT INTO @ProjectExport  
 VALUES (  
  @ProjectExportId  
  ,@FileName  
  ,@ProjectId  
  ,@FilePath  
  ,@FileFormatType  
  ,@ProjectExportTypeId  
  ,DATEADD(DAY, 30, GETUTCDATE())  
  ,0  
  ,GETUTCDATE()  
  ,@CreatedBy  
  ,@CreatedByFullName  
  ,GETUTCDATE()  
  ,@ModifiedBy  
  ,@ModifiedByFullName  
  ,@FileExportTypeId  
  ,@CustomerId  
  ,@ProjectName  
  ,@FileStatus  
  ,IIF(@ProjectExportTypeId = 1, 'Project', 'Branch')  
  ,IIF(@FileExportTypeId = 2, 'Multiple files', 'Single file')  
  )  
  
 UPDATE PE  
 SET PE.FileStatus = @FileStatus,  
 ModifiedBy = ModifiedBy,  
 ModifiedDate = GETUTCDATE(),  
 ModifiedByFullName = @ModifiedByFullName  
 FROM ProjectExport PE WITH (NOLOCK)  
 WHERE PE.ProjectExportId = @ProjectExportId  
  AND PE.ProjectExportTypeId = @ProjectExportTypeId and FileStatus!='Canceled';  
  
 IF NOT EXISTS(select TOP 1 1 FROM ProjectExport PE WITH (NOLOCK) WHERE PE.ProjectExportId = @ProjectExportId  AND PE.ProjectExportTypeId = @ProjectExportTypeId )  
 BEGIN  
  INSERT INTO ProjectExport (  
   FileName  
   ,ProjectId  
   ,FilePath  
   ,FileFormatType  
   ,ProjectExportTypeId  
   ,ExprityDate  
   ,IsDeleted  
   ,CreatedDate  
   ,CreatedBy  
   ,CreatedByFullName  
   ,ModifiedDate  
   ,ModifiedBy  
   ,ModifiedByFullName  
   ,FileExportTypeId  
   ,CustomerId  
   ,ProjectName  
   ,FileStatus  
   )  
  SELECT FileName  
   ,ProjectId  
   ,FilePath  
   ,FileFormatType  
   ,ProjectExportTypeId  
   ,ExprityDate  
   ,IsDeleted  
   ,CreatedDate  
   ,CreatedBy  
   ,CreatedByFullName  
   ,ModifiedDate  
   ,ModifiedBy  
   ,ModifiedByFullName  
   ,FileExportTypeId  
   ,CustomerId  
   ,ProjectName  
   ,FileStatus  
  FROM @ProjectExport  
  
  SET @ProjectExportId = SCOPE_IDENTITY()  
 END  
  
 SELECT FileName  
  ,ProjectId  
  ,FilePath  
  ,FileFormatType  
  ,ProjectExportTypeId  
  ,ExprityDate  
  ,IsDeleted  
  ,CreatedDate  
  ,CreatedBy  
  ,CreatedByFullName  
  ,ModifiedDate  
  ,ModifiedBy  
  ,ModifiedByFullName  
  ,FileExportTypeId  
  ,CustomerId  
  ,ProjectName  
  ,FileStatus  
  ,ProjectExportId  
 FROM ProjectExport WITH (NOLOCK)  
 WHERE ProjectExportId = @ProjectExportId  
END  