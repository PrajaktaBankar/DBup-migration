CREATE PROCEDURE [dbo].[usp_DeleteSegmentRequirementTag_ApplyMasterUpdate]     
@ProjectId INT, @CustomerId INT, @SectionId INT = NULL AS    
BEGIN    

print 'This SP is intentionally left commented'


--Note : Commented business logic to implement User Story 30400: Updates: Tags (revised implementation of 10642)
    
--DECLARE @ProjectId INT = 0;    
--DECLARE @CustomerId INT = 0;    
--DECLARE @PProjectId INT = @ProjectId;    
--DECLARE @PCustomerId INT = @CustomerId;    
--DECLARE @PSectionId INT = @SectionId;    
    
--DECLARE @MasterDataTypeId INT = ( SELECT TOP 1    
--  P.MasterDataTypeId    
-- FROM Project P WITH (NOLOCK)    
-- WHERE P.ProjectId = @PProjectId    
-- AND P.CustomerId = @PCustomerId);    
    
--DELETE RECORDS    
--NOTE:BELOW BOTH DELETE LOGIC IS SAME JUST DIFFERENT OF HANDLING ProjectWise/SectionWise    
--IF @PSectionId IS NULL    
-- OR @PSectionId <= 0    
--BEGIN    
--DELETE FROM PSRT    
-- FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)    
-- LEFT JOIN SLCMaster..SegmentRequirementTag SRT WITH (NOLOCK)    
--  ON SRT.SegmentRequirementTagId = PSRT.mSegmentRequirementTagId    
--WHERE PSRT.ProjectId = @PProjectId    
-- AND PSRT.CustomerId = @PCustomerId    
-- AND PSRT.mSegmentRequirementTagId IS NOT NULL    
-- AND SRT.SegmentRequirementTagId IS NULL    
--END    
--ELSE    
--IF @PSectionId IS NOT NULL    
-- AND @PSectionId > 0    
--BEGIN    
--DELETE FROM PSRT    
-- FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)    
-- LEFT JOIN SLCMaster..SegmentRequirementTag SRT WITH (NOLOCK)    
--  ON SRT.SegmentRequirementTagId = PSRT.mSegmentRequirementTagId    
--WHERE PSRT.ProjectId = @PProjectId    
-- AND PSRT.CustomerId = @PCustomerId    
-- AND PSRT.SectionId = @PSectionId    
-- AND PSRT.mSegmentRequirementTagId IS NOT NULL    
-- AND SRT.SegmentRequirementTagId IS NULL    
--END    
END 