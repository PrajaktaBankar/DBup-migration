

CREATE PROCEDURE [dbo].[usp_GetProjectPrintSetting]                      
 (                                  
 @ProjectId INT,                                  
 @CustomerId INT,                                         
 @UserId INT                                   
)AS                                            
BEGIN                                  
                                      
  DECLARE @PProjectId INT = @ProjectId                                  
  DECLARE @PCustomerId INT = @CustomerId                                  
  DECLARE @PUserId INT = @UserId                
  DECLARE @PFileDateFormat NVARCHAR(100);                  
  DECLARE @PSheetSpecsPrintPreviewLevel INT = 0;        
          
  IF NOT EXISTS (SELECT TOP 1                                  
  1                                  
 FROM ProjectPrintSetting WITH (NOLOCK)                                  
 WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId)                                  
BEGIN                                  
SELECT                                  
 @PProjectId AS ProjectId                                  
   ,@PCustomerId AS CustomerId                                  
   ,@PUserId AS UserId                                  
   ,IsExportInMultipleFiles                                  
   ,IsBeginSectionOnOddPage                                  
   ,IsIncludeAuthorInFileName                                  
   ,TCPrintModeId                                
   ,IsIncludePageCount                                
   ,IsIncludeHyperLink                              
   , KeepWithNext                              
   ,IsPrintMasterNote                              
   ,IsPrintProjectNote                              
   ,IsPrintNoteImage                              
   ,IsPrintIHSLogo                            
   ,BookmarkLevel                            
   ,IsIncludePdfBookmark                            
   ,IsIncludeOrphanParagraph                         
   ,IsMarkPagesAsBlank                        
   ,IsIncludeHeaderFooterOnBlackPages                        
   ,BlankPagesText,                      
   IncludeSectionIdAfterEod,      
   IncludeEndOfSection,    
   IncludeDivisionNameandNumber,
   IsIncludeAuthorForBookMark, 
   IsContinuousPageNumber,
   IsIncludeAttachedDocuments,
   ISNULL(AttachSuppDocAtTheEnd,1) AS AttachSuppDocAtTheEnd
FROM ProjectPrintSetting  WITH(NOLOCK)                                  
WHERE ProjectId IS NULL                    
AND CreatedBy IS NULL                    
AND CustomerId IS NULL                                
                                
END                                  
ELSE                                  
BEGIN                                  
SELECT                                  
 @PProjectId AS ProjectId                                  
   ,@PCustomerId AS CustomerId                                  
   ,@PUserId AS UserId                                  
   ,IsExportInMultipleFiles                                  
   ,IsBeginSectionOnOddPage                                  
   ,IsIncludeAuthorInFileName                                  
   ,TCPrintModeId                                  
   ,IsIncludePageCount                                
   ,IsIncludeHyperLink                              
   ,KeepWithNext                              
   ,IsPrintMasterNote                              
   ,IsPrintProjectNote                              
   ,IsPrintNoteImage                              
   ,IsPrintIHSLogo                               
   ,BookmarkLevel                            
   ,IsIncludePdfBookmark                           
   ,IsIncludeOrphanParagraph                          
   ,IsMarkPagesAsBlank                        
   ,IsIncludeHeaderFooterOnBlackPages                          
   ,BlankPagesText                      
   ,IncludeSectionIdAfterEod ,          
   IncludeEndOfSection  ,    
   IncludeDivisionNameandNumber,
   IsIncludeAuthorForBookMark, 
   IsContinuousPageNumber,
   IsIncludeAttachedDocuments,
   ISNULL(AttachSuppDocAtTheEnd,1) AS AttachSuppDocAtTheEnd
FROM ProjectPrintSetting WITH (NOLOCK)                                  
WHERE ProjectId = @PProjectId                                    
AND  CustomerId = @PCustomerId                             
END                  
                
IF  NOT EXISTS(select TOP 1 1 from ProjectDateFormat WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId)                  
BEGIN                  
                  
SELECT @PFileDateFormat=PDF.DateFormat FROM Project P WITH(NOLOCK) INNER JOIN ProjectDateFormat PDF WITH(NOLOCK)                
ON P.MasterDataTypeId = PDF.MasterDataTypeId AND PDF.ProjectId IS NULL                  
WHERE P.ProjectId = @PProjectId AND P.CustomerId=@PCustomerId                  
                  
END                  
ELSE                  
BEGIN                  
SELECT @PFileDateFormat=[DateFormat] from ProjectDateFormat WITH(NOLOCK) WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId                  
END                                                
                    
                    
IF NOT EXISTS (SELECT TOP 1                                
  1                                
 FROM FileNameFormatSetting WITH (NOLOCK)                                
 WHERE  ProjectId = @PProjectId AND CustomerId = @PCustomerId)                                
BEGIN                   
   select FileFormatCategoryId,IncludeAutherSectionId,Separator,  case when CHARINDEX('D:',FormatJsonWithPlaceHolder) = 0 then FormatJsonWithPlaceHolder else                
   REPLACE(FormatJsonWithPlaceHolder,SUBSTRING( FormatJsonWithPlaceHolder,( CHARINDEX('D:', FormatJsonWithPlaceHolder)+2) ,((CHARINDEX('@}', FormatJsonWithPlaceHolder))-( CHARINDEX('D:', FormatJsonWithPlaceHolder)+2) )),@PFileDateFormat)  end as         
   FormatJsonWithPlaceHolder,@PProjectId as ProjectId,@PCustomerId as CustomerId                             
   FROM FileNameFormatSetting WITH(NOLOCK)  WHERE ProjectId IS NULL  AND CustomerId IS NULL                  
                      
END                                
ELSE                                
BEGIN                 
    select FileFormatCategoryId,IncludeAutherSectionId,Separator,    case when CHARINDEX('D:',FormatJsonWithPlaceHolder) = 0 then FormatJsonWithPlaceHolder else                
   REPLACE(FormatJsonWithPlaceHolder,SUBSTRING( FormatJsonWithPlaceHolder,( CHARINDEX('D:', FormatJsonWithPlaceHolder)+2) ,((CHARINDEX('@}', FormatJsonWithPlaceHolder))-( CHARINDEX('D:', FormatJsonWithPlaceHolder)+2) )),@PFileDateFormat)  end as          
   FormatJsonWithPlaceHolder,ProjectId,CustomerId                            
   FROM FileNameFormatSetting WITH(NOLOCK)  WHERE ProjectId=@PProjectId and CustomerId=@PCustomerId                 
END                    
        
        
--//SheetSpecsPrintSettings        
IF  NOT EXISTS(select TOP 1 1 from SheetSpecsPrintSettings WITH(NOLOCK) WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId)                  
BEGIN                  
            
 INSERT INTO SheetSpecsPrintSettings (CustomerId,ProjectId,UserId,CreatedDate, CreatedBy, ModifiedDate, ModifiedBy,                        
IsDeleted,SheetSpecsPrintPreviewLevel)                        
 VALUES ( @PCustomerId, @PProjectId,@PUserId, GETUTCDATE(), @PUserId, GETUTCDATE(),@PUserId,0, @PSheetSpecsPrintPreviewLevel)                                      
                    
END                  
ELSE                  
BEGIN                  
SELECT CustomerId,ProjectId,SheetSpecsPrintPreviewLevel from SheetSpecsPrintSettings WITH(NOLOCK) WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId                  
END                                                
            
                                
END