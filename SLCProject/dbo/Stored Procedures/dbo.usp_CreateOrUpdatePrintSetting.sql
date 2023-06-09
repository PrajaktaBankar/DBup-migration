

CREATE PROCEDURE [dbo].[usp_CreateOrUpdatePrintSetting]                         
 (                        
 @ProjectId INT,                        
 @CustomerId INT,                               
 @UserId INT ,                               
 @IsExportInMultipleFiles BIT = 0,                            
 @IsContinuousPageNumber BIT = 0,
 @IsBeginSectionOnOddPage BIT = 0,                            
 @IsIncludeAuthorInFileName BIT = 0,                            
 @TCPrintModeId INT=1,                      
 @IsIncludePageCount BIT = 0,                    
 @IsIncludeHyperLink BIT = 0,                    
 @KeepWithNext BIT = 0,                    
 @IsPrintMasterNote BIT = 0,                    
 @IsPrintProjectNote BIT = 0,                    
 @IsPrintNoteImage BIT = 0,                    
 @IsPrintIHSLogo BIT = 0  ,                  
 @IsIncludePdfBookmark BIT=0,                 
 @IsIncludeOrphanParagraph BIT=0,                 
 @BookmarkLevel INT=0,              
 @IsMarkPagesAsBlank BIT=0,              
 @IsIncludeHeaderFooterOnBlackPages BIT=0,              
 @BlankPagesText nvarchar(250)='' ,            
 @IncludeSectionIdAfterEod BIT ,          
 @SheetSpecsPrintPreviewLevel  INT ,      
 @IncludeEndOfSection BIT ,    
 @IncludeDivisionNameandNumber BIT,
 @IsIncludeAuthorForBookMark BIT=0,
 @IsIncludeAttachedDocuments BIT=0,
 @AttachSuppDocAtTheEnd BIT=1
)AS                                  
BEGIN                        
                            
  DECLARE @PProjectId INT = @ProjectId                            
  DECLARE @PCustomerId INT = @CustomerId                               
  DECLARE @PUserId INT = @UserId                               
  DECLARE @PIsExportInMultipleFiles BIT = @IsExportInMultipleFiles                            
  DECLARE @PIsContinuousPageNumber BIT = @IsContinuousPageNumber
  DECLARE @PIsBeginSectionOnOddPage BIT = @IsBeginSectionOnOddPage                            
  DECLARE @PIsIncludeAuthorInFileName BIT = @IsIncludeAuthorInFileName                            
  DECLARE @PTCPrintModeId  INT = @TCPrintModeId                        
  DECLARE @PIsIncludePageCount BIT = @IsIncludePageCount                           
  DECLARE @PIsIncludeHyperLink BIT = @IsIncludeHyperLink                      
  DECLARE @PKeepWithNext BIT = @KeepWithNext                          
  DECLARE @PIsPrintMasterNote BIT = @IsPrintMasterNote                    
  DECLARE @PIsPrintProjectNote BIT = @IsPrintProjectNote                    
  DECLARE @PIsPrintNoteImage BIT = @IsPrintNoteImage                    
  DECLARE @PIsPrintIHSLogo BIT = @IsPrintIHSLogo                     
  DECLARE @PIsIncludePdfBookmark BIT = @IsIncludePdfBookmark                 
  DECLARE @PIsIncludeOrphanParagraph BIT = @IsIncludeOrphanParagraph                     
  DECLARE @PIsMarkPagesAsBlank BIT = @IsMarkPagesAsBlank                 
  DECLARE @PIsIncludeHeaderFooterOnBlackPages BIT = @IsIncludeHeaderFooterOnBlackPages                 
  DECLARE @PBookmarkLevel INT = @BookmarkLevel                  
  DECLARE @PBlankPagesText nvarchar(250) = @BlankPagesText               
  DECLARE @PIncludeSectionIdAfterEod BIT = @IncludeSectionIdAfterEod              
  DECLARE @PSheetSpecsPrintPreviewLevel INT = @SheetSpecsPrintPreviewLevel            
  DECLARE @PIncludeEndOfSection  BIT = @IncludeEndOfSection        
  DECLARE @PIncludeDivisionNameandNumber  BIT = @IncludeDivisionNameandNumber 
  DECLARE @PIsIncludeAuthorForBookMark BIT= @IsIncludeAuthorForBookMark
  DECLARE @PIsIncludeAttachedDocuments BIT = @IsIncludeAttachedDocuments
  DECLARE @PAttachSuppDocAtTheEnd BIT = @AttachSuppDocAtTheEnd
  IF NOT EXISTS (SELECT TOP 1                        
  1                        
 FROM ProjectPrintSetting WITH (NOLOCK) WHERE ProjectId = @PProjectId                    
 AND CustomerId = @PCustomerId  )                           
BEGIN                        
INSERT INTO ProjectPrintSetting (ProjectId, CustomerId, CreatedBy, CreateDate, ModifiedBy,                        
ModifiedDate, IsExportInMultipleFiles, IsBeginSectionOnOddPage, IsIncludeAuthorInFileName, TCPrintModeId,IsIncludePageCount,IsIncludeHyperLink, KeepWithNext,                    
   IsPrintMasterNote, IsPrintProjectNote, IsPrintNoteImage, IsPrintIHSLogo,IsIncludePdfBookmark,IsIncludeOrphanParagraph,IsMarkPagesAsBlank,IsIncludeHeaderFooterOnBlackPages,BlankPagesText,BookmarkLevel,IncludeSectionIdAfterEod ,IncludeEndOfSection ,IncludeDivisionNameandNumber,IsIncludeAuthorForBookMark,IsContinuousPageNumber
   ,IsIncludeAttachedDocuments, AttachSuppDocAtTheEnd)         
                   
 VALUES (@PProjectId, @PCustomerId, @PUserId, GETUTCDATE(), @PUserId, GETUTCDATE(), @PIsExportInMultipleFiles, @PIsBeginSectionOnOddPage, @PIsIncludeAuthorInFileName,                     
 @PTCPrintModeId,@PIsIncludePageCount,@PIsIncludeHyperLink ,@PKeepWithNext, @PIsPrintMasterNote, @PIsPrintProjectNote, @PIsPrintNoteImage, @PIsPrintIHSLogo,@PIsIncludePdfBookmark,@PIsIncludeOrphanParagraph,@PIsMarkPagesAsBlank,@PIsIncludeHeaderFooterOnBlackPages,@PBlankPagesText,@PBookmarkLevel,@PIncludeSectionIdAfterEod,@PIncludeEndOfSection, @PIncludeDivisionNameandNumber,@PIsIncludeAuthorForBookMark,@PIsContinuousPageNumber
 ,@PIsIncludeAttachedDocuments, @PAttachSuppDocAtTheEnd)                        
END                        
ELSE                        
BEGIN                        
UPDATE PPS                        
SET PPS.IsExportInMultipleFiles = COALESCE(@PIsExportInMultipleFiles, PPS.IsExportInMultipleFiles)                        
   ,PPS.IsBeginSectionOnOddPage = COALESCE(@PIsBeginSectionOnOddPage, PPS.IsBeginSectionOnOddPage)                        
   ,PPS.IsIncludeAuthorInFileName = COALESCE(@IsIncludeAuthorInFileName, PPS.IsIncludeAuthorInFileName)                        
   ,PPS.TCPrintModeId = COALESCE(@PTCPrintModeId, PPS.TCPrintModeId)                        
   ,PPS.ModifiedBy = @PUserId                        
   ,PPS.ModifiedDate = GETUTCDATE()                        
   ,PPS.IsIncludePageCount=COALESCE(@PIsIncludePageCount, PPS.IsIncludePageCount)                        
   ,PPS.IsIncludeHyperLink=COALESCE(@PIsIncludeHyperLink, PPS.IsIncludeHyperLink)                    
   ,PPS.KeepWithNext=COALESCE(@PKeepWithNext, PPS.KeepWithNext)                        
   ,PPS.IsPrintMasterNote=COALESCE(@PIsPrintMasterNote, PPS.IsPrintMasterNote)                     
   ,PPS.IsPrintProjectNote=COALESCE(@PIsPrintProjectNote, PPS.IsPrintProjectNote)                     
   ,PPS.IsPrintNoteImage=COALESCE(@PIsPrintNoteImage, PPS.IsPrintNoteImage)                     
   ,PPS.IsPrintIHSLogo=COALESCE(@PIsPrintIHSLogo, PPS.IsPrintIHSLogo)                        
   ,PPS.BookmarkLevel=COALESCE(@PBookmarkLevel, PPS.BookmarkLevel)                        
   ,PPS.IsIncludePdfBookmark=COALESCE(@PIsIncludePdfBookmark, PPS.IsIncludePdfBookmark)                 
   ,PPS.IsIncludeOrphanParagraph=COALESCE(@IsIncludeOrphanParagraph, PPS.IsIncludeOrphanParagraph)                 
   ,PPS.IsMarkPagesAsBlank= COALESCE(@PIsMarkPagesAsBlank, PPS.IsMarkPagesAsBlank)              
   ,PPS.IsIncludeHeaderFooterOnBlackPages= COALESCE(@PIsIncludeHeaderFooterOnBlackPages, PPS.IsIncludeHeaderFooterOnBlackPages)              
   ,PPS.BlankPagesText=COALESCE(@PBlankPagesText, PPS.BlankPagesText)               
   ,PPS.IncludeSectionIdAfterEod = COALESCE(@PIncludeSectionIdAfterEod, PPS.IncludeSectionIdAfterEod)      
   ,PPS.IncludeEndOfSection = COALESCE(@PIncludeEndOfSection, PPS.IncludeEndOfSection)       
   ,PPS.IncludeDivisionNameandNumber = COALESCE(@PIncludeDivisionNameandNumber, PPS.IncludeDivisionNameandNumber)  
   ,PPS.IsIncludeAuthorForBookMark=COALESCE(@IsIncludeAuthorForBookMark,PPS.IsIncludeAuthorForBookMark)
   ,PPS.IsContinuousPageNumber = COALESCE(@PIsContinuousPageNumber, PPS.IsContinuousPageNumber)
   ,PPS.IsIncludeAttachedDocuments = COALESCE(@PIsIncludeAttachedDocuments, PPS.IsIncludeAttachedDocuments)
   ,PPS.AttachSuppDocAtTheEnd = COALESCE(@PAttachSuppDocAtTheEnd, PPS.AttachSuppDocAtTheEnd) 
          
                      
FROM ProjectPrintSetting PPS WITH (NOLOCK)                        
WHERE PPS.ProjectId = @PProjectId                            
AND  PPS.CustomerId = @PCustomerId                   
END             
        
--//SheetSpecsPrintLevelSettings          
        
  IF NOT EXISTS (SELECT TOP 1 1 FROM SheetSpecsPrintSettings WITH (NOLOCK)  WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId  )                           
BEGIN                        
INSERT INTO SheetSpecsPrintSettings (CustomerId,ProjectId,UserId,CreatedDate, CreatedBy, ModifiedDate, ModifiedBy,                        
IsDeleted,SheetSpecsPrintPreviewLevel)                        
 VALUES ( @PCustomerId, @PProjectId,@PUserId, GETUTCDATE(), @PUserId, GETUTCDATE(),@PUserId,0, @PSheetSpecsPrintPreviewLevel)                        
END                        
           
   ELSE        
     BEGIN        
    Update ssp        
    set ssp.SheetSpecsPrintPreviewLevel=@PSheetSpecsPrintPreviewLevel        
    from SheetSpecsPrintSettings ssp    WITH (NOLOCK)      
    WHERE ssp.ProjectId = @PProjectId  AND  ssp.CustomerId = @PCustomerId          
  END                   
END 