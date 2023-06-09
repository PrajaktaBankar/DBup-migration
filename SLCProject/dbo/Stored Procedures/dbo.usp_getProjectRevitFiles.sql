CREATE PROCEDURE [dbo].[usp_getProjectRevitFiles]  
@projectId INT NULL, @customerId INT NULL, @userId INT NULL=0  
AS  
BEGIN
  
DECLARE @PprojectId INT = @projectId;
DECLARE @PcustomerId INT = @customerId;
DECLARE @PuserId INT = @userId;

SELECT
	prf.RevitFileId
   ,prf.FileName
   ,prf.FileSize
   ,prf.CustomerId
   ,prf.UserId
   ,prf.ProjectId
   ,prf.UploadedDate
   ,prf.UploadedBy
   ,prf.ExtVimId
   ,prf.IsDeleted
   ,prf.UniqueId
   ,prfm.ProjectId
FROM [ProjectRevitFile] AS prf WITH (NOLOCK)
INNER JOIN [ProjectRevitFileMapping] AS prfm WITH (NOLOCK)
	ON prf.RevitFileId = prfm.RevitFileId
WHERE prfm.ProjectId = @PprojectId
AND prfm.CustomerId = @PcustomerId;
END

GO
