-- Execute this on SLCMasterStaging
-- Customer Support 77401: Missing links 

USE [SLCMasterStaging]
GO
DROP TABLE IF EXISTS #TargetLinkResultTable
CREATE TABLE #TargetLinkResultTable (
	SectionId INT NOT NULL
	,SectionCode INT NULL
	,Description NVARCHAR (500)  NULL
	,SegmentId BIGINT NULL
	,SegmentCode BIGINT NULL
	,SegmentDescription NVARCHAR (MAX)  NULL
	,SegmentStatusId BIGINT NULL
	,SegmentStatusCode BIGINT NULL
	,SegmentLinkId BIGINT NULL
	,TargetSegmentCode BIGINT NULL
);

INSERT INTO #TargetLinkResultTable SELECT 
SEC.SectionId, 
SEC.SectionCode,
SEC.Description,
SGMT.SegmentId,
SGMT.SegmentCode,
SGMT.SegmentDescription,
STS.SegmentStatusId,
STS.SegmentStatusCode,
SLINK.SegmentLinkId,
SLINK.TargetSegmentCode
FROM [dbo].[SectionsStaging] SEC WITH (NOLOCK) 
INNER JOIN [dbo].[SegmentStatusStaging] STS WITH (NOLOCK) ON STS.SectionId = SEC.SectionId AND ISNULL(STS.IsDeleted, 0) = 0
INNER JOIN [dbo].[SegmentStaging] SGMT WITH (NOLOCK) ON SGMT.SegmentId = STS.SegmentId AND SGMT.SegmentStatusId = STS.SegmentStatusId AND STS.SectionId = SEC.SectionId 
INNER JOIN [dbo].[SegmentLinkStaging] SLINK WITH (NOLOCK) ON SEC.SectionCode = SLINK.TargetSectionCode AND STS.SegmentStatusCode = SLINK.TargetSegmentStatusCode AND SGMT.SegmentCode != SLINK.TargetSegmentCode AND ISNULL(SLINK.IsDeleted, 0) = 0
WHERE SEC.IsDeleted = 0;

SELECT * from #TargetLinkResultTable

SELECT * FROM [dbo].[SegmentLinkStaging] Sl WITH (NOLOCK)
INNER JOIN #TargetLinkResultTable STS WITH (NOLOCK) ON STS.SectionCode = Sl.TargetSectionCode AND STS.SegmentStatusCode = Sl.TargetSegmentStatusCode AND STS.SegmentLinkId = Sl.SegmentLinkId
WHERE ISNULL(Sl.IsDeleted, 0) = 0;

BEGIN TRY
	BEGIN TRANSACTION
		UPDATE Sl    
		SET Sl.TargetSegmentCode = STS.SegmentCode
		FROM [dbo].[SegmentLinkStaging] Sl WITH (NOLOCK)
		INNER JOIN #TargetLinkResultTable STS WITH (NOLOCK) ON STS.SectionCode = Sl.TargetSectionCode AND STS.SegmentStatusCode = Sl.TargetSegmentStatusCode AND STS.SegmentLinkId = Sl.SegmentLinkId 
		WHERE ISNULL(Sl.IsDeleted, 0) = 0;
	IF @@Trancount > 0 COMMIT TRANSACTION
END TRY
BEGIN CATCH
	IF @@Trancount > 0 ROLLBACK;
	DECLARE @ErrorMessage NVARCHAR(4000);  
	DECLARE @ErrorSeverity INT;  
	DECLARE @ErrorState INT;  

	SELECT   
	@ErrorMessage = ERROR_MESSAGE(),  
	@ErrorSeverity = ERROR_SEVERITY(),  
	@ErrorState = ERROR_STATE(); 
END CATCH
