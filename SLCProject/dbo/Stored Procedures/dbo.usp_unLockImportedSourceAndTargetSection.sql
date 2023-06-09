CREATE PROCEDURE [dbo].[usp_unLockImportedSourceAndTargetSection]  
 @SourceSectionId INT,  
 @TargetProjectId INT,  
 @SourceTag VARCHAR(18),  
 @Author NVARCHAR(100),  
 @IsRollBack BIT  
AS  
BEGIN  
	 DECLARE @PSourceSectionId INT = @SourceSectionId;  
	 DECLARE @PTargetProjectId INT = @TargetProjectId;  
	 DECLARE @PSourceTag VARCHAR(18) = @SourceTag;  
	 DECLARE @PAuthor NVARCHAR(100) = @Author;  
	 DECLARE @PIsRollBack BIT = @IsRollBack;  
  
	--UNLOCK Source Section  
  
	UPDATE ps 
	SET ps.IsLockedImportSection = 0  
	FROM ProjectSection ps WITH(NOLOCK)
	WHERE ps.SectionId = @PSourceSectionId;  
  
	-- UNLOCK Target Section.  
	IF @PIsRollBack = 1  
	BEGIN  
		UPDATE ps 
		SET ps.IsLockedImportSection = 0  
		from ProjectSection ps WITH(NOLOCK)
		WHERE ps.ProjectId = @PTargetProjectId  
		AND ps.IsLastLevel = 1  
		AND ps.SourceTag = @PSourceTag  
		AND ps.Author = @PAuthor  
	END  
END