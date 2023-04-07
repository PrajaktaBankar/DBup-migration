CREATE PROCEDURE [dbo].[usp_ApplyAllUpdates]  
@UpdatedId INT NULL, @PSegmentStatusId BIGINT NULL, @MSegmentStatusId INT NULL, @ProjectId INT NULL, @SectionId INT NULL,@customerId INT NULL=0,@mSectionId INT NULL  
AS  
BEGIN
  
DECLARE @PUpdatedId INT = @UpdatedId;
DECLARE @PPSegmentStatusId BIGINT = @PSegmentStatusId;
DECLARE @PMSegmentStatusId INT = @MSegmentStatusId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PcustomerId INT = @customerId;
DECLARE @PmSectionId INT = @mSectionId;
--Set Nocount On  
SET NOCOUNT ON;

UPDATE pss
SET pss.mSegmentId = @PUpdatedId
FROM dbo.ProjectSegmentStatus pss  WITH (NOLOCK)
WHERE pss.SegmentStatusId = @PPSegmentStatusId
AND pss.SectionId = @PsectionId
AND pss.mSegmentStatusId = @PMSegmentStatusId
AND pss.ProjectId = @PprojectId
and pss.customerId=@PcustomerId

--MAP CHOICES  
INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, ProjectId, CustomerId, SectionId)
	SELECT
		MCH.SegmentChoiceCode
	   ,MCHOP.ChoiceOptionCode
	   ,MSCHOP.ChoiceOptionSource
	   ,MSCHOP.IsSelected
	   ,@PProjectId
	   ,@PCustomerId
	   ,@PSectionId
	FROM SLCMaster.dbo.SegmentChoice AS MCH WITH (NOLOCK)
	INNER JOIN SLCMaster..ChoiceOption AS MCHOP WITH (NOLOCK)
		ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId
	INNER JOIN SLCMaster..SelectedChoiceOption AS MSCHOP WITH (NOLOCK)
		ON MSCHOP.SectionId=MCH.SectionId 
			AND MCHOP.ChoiceOptionCode = MSCHOP.ChoiceOptionCode
		AND MSCHOP.SegmentChoiceCode = MCH.SegmentChoiceCode
	WHERE MCH.SectionId = @PmSectionId
	AND MCH.SegmentId = @PUpdatedId;

END
GO


