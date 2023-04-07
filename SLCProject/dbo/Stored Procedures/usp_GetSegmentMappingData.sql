CREATE PROCEDURE usp_GetSegmentMappingData
(  
 @ProjectId INT,  
 @SectionId INT,   
 @CustomerId INT  
)  
AS  
BEGIN  
  
 EXEC usp_GetProjectSections @ProjectId, @SectionId, @CustomerId;
 EXEC usp_GetProjectSectionUserTag @ProjectId, @CustomerId, @SectionId;
 EXEC usp_GetProjectSectionHyperLinks @ProjectId, @SectionId;
 --EXEC usp_GetProjectSegmentImage @SectionId;
 EXEC usp_GetProjectTemplateStyle @ProjectId, @SectionId, @CustomerId;
 EXEC usp_GetProjectGlobalTerm @ProjectId, @CustomerId;
 EXEC usp_GetProjectSummary @ProjectId;
 EXEC usp_GetTrackChangesModeInfo @ProjectId, @SectionId;
  
END