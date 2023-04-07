CREATE PROC [dbo].[usp_getMaterialIdBySection]  
(  
 @vimId int,  
 @sectionId int  
)  
AS  
BEGIN
  
    DECLARE @PvimId int = @vimId;
	DECLARE @PsectionId int = @sectionId;
SELECT
	ProjectId
   ,SectionId
   ,VimId
   ,MaterialId
FROM [LinkedSections] WITH (NOLOCK)
WHERE VimId = @PvimId
AND SectionId = @PsectionId

END

GO
