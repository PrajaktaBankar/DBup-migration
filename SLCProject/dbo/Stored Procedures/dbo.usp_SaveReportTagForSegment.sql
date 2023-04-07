CREATE PROCEDURE [dbo].[usp_SaveReportTagForSegment]     
@CustomerId int, @SectionId int, @ProjectId int, @SegmentStatusId bigint, @RequirementTagId int, @UserTagId int, @IsChecked bit,@CreatedBy INT =0    
AS    
BEGIN  
    
DECLARE @PCustomerId int = @CustomerId;  
DECLARE @PSectionId int = @SectionId;  
DECLARE @PProjectId int = @ProjectId;  
DECLARE @PSegmentStatusId bigint = @SegmentStatusId;  
DECLARE @PRequirementTagId int = @RequirementTagId;  
DECLARE @PUserTagId int = @UserTagId;  
DECLARE @PIsChecked bit =@IsChecked  
DECLARE @PCreatedBy int = @CreatedBy;  
    
  --SELECT * FROM ProjectSegmentRequirementTag WHERE SegmentStatusId=@SegmentStatusId  
IF (@PRequirementTagId != 0)    
BEGIN  
    
 IF NOT EXISTS (SELECT TOP 1  
  PSRT.RequirementTagId  
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
 WHERE PSRT.ProjectId = @PProjectId  
 AND PSRT.SectionId = @PSectionId  
 AND PSRT.CustomerId = @PCustomerId  
 AND PSRT.SegmentStatusId = @PSegmentStatusId  
 AND PSRT.RequirementTagId = @PRequirementTagId)  
AND @PIsChecked = 1  
BEGIN  
INSERT INTO ProjectSegmentRequirementTag (CustomerId, ProjectId, SectionId, SegmentStatusId, RequirementTagId, CreateDate, ModifiedDate, CreatedBy, IsDeleted)  
 VALUES (@PCustomerId, @PProjectId, @PSectionId, @PSegmentStatusId, @PRequirementTagId, GETUTCDATE(), GETUTCDATE(), @PCreatedBy, 0)  
END  
ELSE  
BEGIN  
 IF(@PIsChecked = 0)  
 BEGIN  
 DELETE FROM ProjectSegmentRequirementTag  
 WHERE ProjectId = @PProjectId  
  AND SectionId = @PSectionId  
  AND CustomerId = @PCustomerId  
  AND SegmentStatusId = @PSegmentStatusId  
  AND RequirementTagId = @PRequirementTagId  
  AND mSegmentRequirementTagId IS NULL  
 END  
 END  
END  
END  
IF (@PUserTagId != 0)  
  
BEGIN  
IF NOT EXISTS (SELECT TOP 1  
   PSUT.SegmentUserTagId  
  FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)  
  WHERE PSUT.ProjectId = @PProjectId  
  AND PSUT.SectionId = @PSectionId  
  AND PSUT.CustomerId = @PCustomerId  
  AND PSUT.SegmentStatusId = @PSegmentStatusId  
  AND PSUT.UserTagId = @PUserTagId)  
 AND @PIsChecked = 1  
BEGIN  
INSERT INTO ProjectSegmentUserTag (CustomerId, ProjectId, SectionId, SegmentStatusId, UserTagId, CreateDate, CreatedBy, IsDeleted)  
 VALUES (@PCustomerId, @PProjectId, @PSectionId, @PSegmentStatusId, @PUserTagId, GETUTCDATE(), @CreatedBy, 0)  
END  
ELSE  
BEGIN  
 IF(@PIsChecked = 0)  
 BEGIN  
 DELETE FROM ProjectSegmentUserTag  
 WHERE ProjectId = @PProjectId  
  AND SectionId = @PSectionId  
  AND CustomerId = @PCustomerId  
  AND SegmentStatusId = @PSegmentStatusId  
  AND UserTagId = @PUserTagId  
 END  
 END  
END
GO


