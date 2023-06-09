CREATE PROCEDURE [dbo].[usp_checkSectionHasOLSF]  
  @ProjectId int   
 ,@CustomerId int  
 ,@SectionId int  
AS  
BEGIN
  
  DECLARE @PProjectId int = @ProjectId;
  DECLARE @PCustomerId int = @CustomerId;
  DECLARE @PSectionId int  = @SectionId;

	SELECT s.SegmentStatusId,SpecTypeTagId,IsDeleted INTO #Temp_PSS
		FROM ProjectSegmentStatus AS s WITH (NOLOCK)
		WHERE s.ProjectId = @PprojectId
		AND s.CustomerId = @PcustomerId
		AND s.SectionId = @PSectionId

--TODO:Check if Section is opened or not  
IF ((SELECT TOP 1
			COUNT(s.SegmentStatusId)
		from #Temp_PSS S with (nolock))
	> 0)
BEGIN
IF (EXISTS (SELECT top 1 
			1 AS StatusCount
		FROM #Temp_PSS PSST WITH (NOLOCK)
		WHERE PSST.SpecTypeTagId IN (1, 2, 3, 4)
		AND (PSST.IsDeleted IS NULL
		OR PSST.IsDeleted = 0))
	)
SELECT
	1 AS HasOLSFSegment;
ELSE
SELECT
	0 AS HasOLSFSegment;

END
ELSE
BEGIN

IF (EXISTS (SELECT top 1 1 FROM SLCMaster..SegmentStatus SST WITH (NOLOCK)
		INNER JOIN  ProjectSection AS ps WITH (NOLOCK)
		ON SST.SectionId = Ps.mSectionId
		and SST.SpecTypeTagId IN (1, 2)
		AND (SST.IsDeleted IS NULL
		OR SST.IsDeleted = 0)
		WHERE ps.ProjectId = @PprojectId
		AND ps.SectionId = @PSectionId
		AND ps.CustomerId = @PcustomerId
		)
	)
SELECT
	1 AS HasOLSFSegment;
ELSE
SELECT
	0 AS HasOLSFSegment;
END
END

GO
