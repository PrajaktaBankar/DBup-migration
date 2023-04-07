CREATE PROCEDURE [dbo].[usp_GetProjectAndSectionData]       
  ( 
  @ProjectId INT ,                               
  @SectionId INT 
  )                                                       
AS                                
BEGIN

  SELECT   
 PS.SectionId  As SectionId 
 ,PS.mSectionId  As mSectionId 
 ,PS.ParentSectionId  As ParentSectionId 
 ,PS.ProjectId  AS ProjectId 
 ,PS.CustomerId  AS CustomerId ,
 PS.TemplateId  As TemplateId
 ,PS.DivisionId  As DivisionId
 ,PS.DivisionCode  AS DivisionCode
 ,PS.Description  AS Description
 ,PS.LevelId  As LeveId
 ,PS.IsLastLevel  As IsLastLevel
 ,PS.SourceTag  As SourceTagFormat
 ,PS.Author  AS Author
 ,PS.CreatedBy As CreatedBy 
 ,PS.CreateDate  As CreateDate
 ,PS.ModifiedBy  AS ModifiedBy
 ,PS.ModifiedDate  As ModifiedDate
 ,PS.SectionCode  As SectionCode
 ,PS.IsLocked  AS IsLocked
 ,PS.LockedBy  AS LockedBy 
 ,PS.FormatTypeId AS FormatTypeId    
 INTO #ProjectSections  
 FROM ProjectSection PS WITH (NOLOCK)  
 WHERE PS.ProjectId = @ProjectId   
 ANd PS.SectionId = @SectionId 
 AND ISNULL(PS.IsDeleted,0) = 0  

 SELECT
  p.ProjectId As ProjectId,
  p.ProjectId As Id,
  P.Name As Name ,
  --P.Name As description ,
  P.Description As Description
 ,P.IsOfficeMaster As IsOfficeMaster ,
 P.TemplateId As ProjectTemplateId ,
 P.MasterDataTypeId As MasterDataTypeId ,
 P.CreateDate As ProjectCreateDate ,
 P.CreatedBy AS ProjectCreatedBy ,
 P.ModifiedBy As ProjectModifiedBy ,
 P.ModifiedDate As ProjectModifiedDate ,
 P.UserId AS UserId,
  P.CustomerId As CustomeRId 

  INTO #ProjectData
  from #ProjectSections PSS 
 INNER JOIN Project P ON
 p.ProjectId = PSS.ProjectId and 
 p.CustomerId = PSS.CustomerId 
where P.ProjectId = @ProjectId  and PSS.SectionId =  @SectionId
 
SELECT * from #ProjectSections
SELECT * from #ProjectData

END