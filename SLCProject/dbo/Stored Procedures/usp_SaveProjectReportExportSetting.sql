CREATE PROCEDURE [dbo].[usp_SaveProjectReportExportSetting]
(
	@ProjectId INT,
	@CustomerId INT,
	@IsIncludeAuthor BIT,
	@IsIncludeParagraphText BIT,
	@UserId INT
)

AS
BEGIN

--Variable Declaration
DECLARE	@PProjectId INT = @ProjectId;
DECLARE	@PCustomerId INT = @CustomerId;
DECLARE @PIsIncludeAuthor BIT = @IsIncludeAuthor;
DECLARE @PIsIncludeParagraphText BIT = @IsIncludeParagraphText;
DECLARE @PUserId INT = @UserId;

--Insert or update into the table
IF NOT EXISTS (SELECT TOP 1 1 FROM ProjectReportExportSetting WITH (NOLOCK) 
				WHERE CustomerId = @PCustomerId 
				AND ProjectId = @PProjectId)      
 BEGIN
	 INSERT INTO ProjectReportExportSetting
	 (
 		ProjectId,
		CustomerId,
		IsIncludeAuthor,
		IsIncludeParagraphText,
		CreatedBy,
		CreatedDate,
		ModifiedBy,
		ModifiedDate
	 ) 
	 VALUES
	 (
		@PProjectId,
		@PCustomerId,
		@PIsIncludeAuthor,
		@IsIncludeParagraphText,
		@PUserId,
		GETUTCDATE(),
		@PUserId,
		GETUTCDATE()
	 )
 END

 ELSE
 BEGIN
	 UPDATE ProjectReportExportSetting
	 SET 
	 IsIncludeAuthor = @PIsIncludeAuthor,
	 IsIncludeParagraphText = @PIsIncludeParagraphText,
	 ModifiedBy = @PUserId,
	 ModifiedDate = GETUTCDATE()
	 WHERE CustomerId = @PCustomerId
	 AND ProjectId = @PProjectId
 END
END
GO


