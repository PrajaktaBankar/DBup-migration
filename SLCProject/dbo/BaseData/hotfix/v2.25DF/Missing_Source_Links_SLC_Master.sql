-- Execute this on SLCMaster
-- Customer Support 77401: Missing links

USE [SLCMaster]
GO
DROP TABLE IF EXISTS #SourceLinkResultTable
CREATE TABLE #SourceLinkResultTable (
	SectionId INT NOT NULL
	,SectionCode INT NULL
	,Description NVARCHAR (500)  NULL
	,SegmentId BIGINT NULL
	,SegmentCode BIGINT NULL
	,SegmentDescription NVARCHAR (MAX)  NULL
	,SegmentStatusId BIGINT NULL
	,SegmentStatusCode BIGINT NULL
	,SegmentLinkId BIGINT NULL
	,SourceSegmentCode BIGINT NULL
);

INSERT INTO #SourceLinkResultTable SELECT 
SEC.SectionId, 
SEC.SectionCode,
SEC.Description,
SGMT.SegmentId,
SGMT.SegmentCode,
SGMT.SegmentDescription,
STS.SegmentStatusId,
STS.SegmentStatusCode,
SLINK.SegmentLinkId,
SLINK.SourceSegmentCode
FROM [dbo].[Section] SEC WITH (NOLOCK) 
INNER JOIN [dbo].[SegmentStatus] STS WITH (NOLOCK) ON STS.SectionId = SEC.SectionId AND ISNULL(STS.IsDeleted, 0) = 0
INNER JOIN [dbo].[Segment] SGMT WITH (NOLOCK) ON SGMT.SegmentId = STS.SegmentId AND SGMT.SegmentStatusId = STS.SegmentStatusId AND STS.SectionId = SEC.SectionId 
INNER JOIN [dbo].[SegmentLink] SLINK WITH (NOLOCK) ON SEC.SectionCode = SLINK.SourceSectionCode AND STS.SegmentStatusCode = SLINK.SourceSegmentStatusCode AND SGMT.SegmentCode != SLINK.SourceSegmentCode AND ISNULL(SLINK.IsDeleted, 0) = 0
WHERE SEC.IsDeleted = 0;

--SELECT * from #SourceLinkResultTable

SELECT * FROM [dbo].[SegmentLink] Sl WITH (NOLOCK)
INNER JOIN #SourceLinkResultTable STS WITH (NOLOCK) ON STS.SectionCode = Sl.SourceSectionCode AND STS.SegmentStatusCode = Sl.SourceSegmentStatusCode AND STS.SegmentLinkId = Sl.SegmentLinkId 
WHERE ISNULL(Sl.IsDeleted, 0) = 0;

BEGIN TRY
	BEGIN TRANSACTION
		UPDATE Sl    
		SET Sl.SourceSegmentCode = STS.SegmentCode
		FROM [dbo].[SegmentLink] Sl WITH (NOLOCK)
		INNER JOIN #SourceLinkResultTable STS WITH (NOLOCK) ON STS.SectionCode = Sl.SourceSectionCode AND STS.SegmentStatusCode = Sl.SourceSegmentStatusCode AND STS.SegmentLinkId = Sl.SegmentLinkId 
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