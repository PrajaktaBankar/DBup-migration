CREATE PROCEDURE [dbo].[usp_UpdateSection_ApplyMasterUpdate] @ProjectId INT, @CustomerId INT AS
BEGIN
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
--DECLARE @ProjectId INT = 0;
--DECLARE @CustomerId INT = 0;

DECLARE @MasterDataTypeId INT = ( SELECT TOP 1
		P.MasterDataTypeId
	FROM Project P WITH (NOLOCK)
	WHERE P.ProjectId = @PProjectId
	AND P.CustomerId = @PCustomerId);

--UPDATE FIELDS
UPDATE PS
SET PS.SourceTag = MS.SourceTag
   ,PS.Description = MS.Description
FROM ProjectSection PS WITH (NOLOCK)
INNER JOIN SLCMaster..Section MS WITH (NOLOCK)
	ON PS.mSectionId = MS.SectionId
INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)
	ON PS.ProjectId = PSST.ProjectId
	AND PS.CustomerId = PSST.CustomerId
	AND PS.SectionId = PSST.SectionId
	AND PSST.SequenceNumber = 0
	AND PSST.ParentSegmentStatusId = 0
	AND PSST.IndentLevel = 0
	AND PSST.SegmentSource = 'M'
	AND PSST.SegmentOrigin = 'M'--NOTE: It was U when implemented but it was resetting user modified section name to master
WHERE PS.ProjectId = @PProjectId
AND PS.CustomerId = @PCustomerId
AND PS.IsLastLevel = 1
AND PS.IsDeleted = 0
AND MS.IsDeleted = 0
AND (PS.SourceTag != MS.SourceTag
OR PS.Description != MS.Description)
END

GO
