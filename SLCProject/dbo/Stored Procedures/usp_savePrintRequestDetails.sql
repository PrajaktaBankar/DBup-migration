CREATE PROCEDURE [dbo].[usp_savePrintRequestDetails]       
(  
@FileName NVARCHAR(500),        
@CustomerId INT,        
@ProjectId INT,        
@ProjectName NVARCHAR(100),        
@SectionName NVARCHAR(100),        
@PrintTypeId INT,        
@IsExportAsSingleFile BIT,        
@IsBeginFromOddPage BIT,        
@IsIncludeAuthorName BIT,        
@TrackChangesOption INT,        
@PrintStatus NVARCHAR(20),        
@CreatedBy INT,  
@IsExternalExport  BIT=0,
@PrintRequestId INT = 0
)
AS        
BEGIN  

If NOT EXISTS(select TOP 1 1 FROM PrintRequestDetails WITH (NOLOCK) WHERE PrintRequestId = @PrintRequestId )
BEGIN 
	INSERT INTO PrintRequestDetails (FileName, CustomerId, ProjectId, ProjectName, SectionName, PrintTypeId,    
	IsExportAsSingleFile, IsBeginFromOddPage, IsIncludeAuthorName, TrackChangesOption, PrintStatus, CreatedDate, CreatedBy, IsExternalExport,    
	ModifiedDate, ModifiedBy,IsDeleted)    
	 VALUES (@FileName, @CustomerId, @ProjectId, @ProjectName, @SectionName, @PrintTypeId, @IsExportAsSingleFile, @IsBeginFromOddPage, @IsIncludeAuthorName, @TrackChangesOption, @PrintStatus, GETUTCDATE(), @CreatedBy, @IsExternalExport, NULL, NULL,0);    

	 SELECT    
 CONVERT(INT, SCOPE_IDENTITY()) AS PrintRequestId; 

END
ELSE
BEGIN
	UPDATE PRD
	SET PrintStatus = @PrintStatus,
	ModifiedDate = GETUTCDATE()
	FROM PrintRequestDetails PRD WITH (NOLOCK)
	WHERE PRD.PrintRequestId =@PrintRequestId and PRD.PrintStatus!='Canceled'

	SELECT @PrintRequestId as PrintRequestId
END;

END