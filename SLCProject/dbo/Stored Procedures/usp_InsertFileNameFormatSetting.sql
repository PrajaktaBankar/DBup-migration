    
CREATE PROCEDURE [dbo].[usp_InsertFileNameFormatSetting]          
@FileFormatJson NVARCHAR(MAX) =''          
AS          
          
BEGIN          
          
DECLARE @PFileFormatJson NVARCHAR(MAX) = @FileFormatJson;          
--DECLARE INP NOTE TABLE          
CREATE TABLE #InpFileNameFormatSetting(          
RowId INT,          
FileFormatCategoryId INT DEFAULT 0 ,          
Separator NVARCHAR(6),          
FormatJsonWithPlaceHolder NVARCHAR(200),          
IncludeAutherSectionId BIT,          
ProjectId INT DEFAULT 0 ,          
CustomerId INT DEFAULT 0,    
CreatedBy INT DEFAULT 0,    
ModifiedBy INT DEFAULT 0     
);          
          
INSERT INTO #InpFileNameFormatSetting          
SELECT          
ROW_NUMBER() over(order by FileFormatCategoryId) as RowId,          
*          
FROM OPENJSON(@PFileFormatJson)          
WITH (          
FileFormatCategoryId INT '$.FileFormatCategoryId',          
Separator NVARCHAR(6) '$.Separator',          
FormatJsonWithPlaceHolder NVARCHAR(100) '$.FormatJsonWithPlaceHolder',          
IncludeAutherSectionId BIT '$.IncludeAutherSectionId',          
ProjectId INT '$.ProjectId',          
CustomerId INT '$.CustomerId',        
CreatedBy INT '$.CreatedBy',          
ModifiedBy INT '$.ModifiedBy'         
          
);          
          
declare @projectId int,@customerId INT          
select top 1 @projectId=projectId,@customerId=customerId from #InpFileNameFormatSetting          
          
if(exists(select top 1 1 from FileNameFormatSetting with(nolock) where ProjectId=@projectId and customerId=@customerId))          
BEGIN          
update ffs          
set ffs.FileFormatCategoryId=t.FileFormatCategoryId,          
ffs.IncludeAutherSectionId=t.IncludeAutherSectionId,          
ffs.Separator=t.Separator,          
ffs.FormatJsonWithPlaceHolder=t.FormatJsonWithPlaceHolder,      
ffs.ModifiedBy=t.ModifiedBy      
FROM FileNameFormatSetting ffs with(nolock) inner join #InpFileNameFormatSetting t          
ON ffs.projectId=t.projectId and ffs.CustomerId=t.customerId and ffs.FileFormatCategoryId=t.FileFormatCategoryId          
END          
ELSE          
BEGIN          
INSERT INTO FileNameFormatSetting(FileFormatCategoryId,IncludeAutherSectionId,Separator,FormatJsonWithPlaceHolder,ProjectId,CustomerId,CreatedBy,CreatedDate,ModifiedBy,ModifiedDate)          
select FileFormatCategoryId,IncludeAutherSectionId,Separator,FormatJsonWithPlaceHolder,ProjectId,CustomerId,CreatedBy,GETDATE() AS CreatedDate,ModifiedBy, GETDATE() AS ModifiedDate          
from #InpFileNameFormatSetting          
END          
          
END 