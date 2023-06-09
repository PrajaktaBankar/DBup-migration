CREATE PROCEDURE [dbo].[usp_CheckSectionIsLocked]  
(
	@SectionId INT
)
AS    
BEGIN  
    
	DECLARE @PSectionId INT  = @SectionId;  

	SELECT
		 PS.SectionId  
		,PS.ParentSectionId  
		,PS.mSectionId  
		,PS.ProjectId  
		,PS.CustomerId  
		,PS.UserId  
		,PS.DivisionId  
		,ISNULL(PS.DivisionCode, 0) AS DivisionCode  
		,ISNULL(PS.[Description], '') AS [Description]  
		,PS.LevelId  
		,PS.IsLastLevel  
		,ISNULL(PS.SourceTag, '') AS SourceTag  
		,PS.Author  
		,PS.TemplateId  
		,PS.SectionCode  
		,ISNULL(PS.IsDeleted, 0) AS IsDeleted  
		,ISNULL(PS.IsLocked, 0) AS IsLocked  
		,PS.LockedBy  
		,ISNULL(PS.LockedByFullName, '') AS LockedByFullName  
		,PS.CreateDate  
		,PS.CreatedBy  
		,PS.ModifiedBy  
		,PS.ModifiedDate  
		,PS.FormatTypeId  
		,PS.SpecViewModeId  
		,PS.IsLockedImportSection  
	FROM ProjectSection PS WITH (NOLOCK)  
	WHERE PS.SectionId = @PSectionId
	OPTION (FAST 1);
  
END  