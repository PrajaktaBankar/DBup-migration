CREATE PROCEDURE [dbo].[usp_UpdatePendingUpdateCount]
@CustomerId INT,
@ProjectId INT,
@SectionIdsJson NVARCHAR(MAX),
@CatalogType NVARCHAR(100)
AS
BEGIN
	DECLARE @PCustomerId INT = @CustomerId;
	DECLARE @PProjectId INT = @ProjectId;
	DECLARE @PSectionIdArray NVARCHAR(MAX) = JSON_QUERY(@SectionIdsJson);	
	DECLARE @PCatalogType NVARCHAR(100) = @CatalogType;	
	
	DROP TABLE IF EXISTS #tmpSections
	CREATE TABLE #tmpSections (SectionIds INT)

	INSERT INTO #tmpSections (SectionIds)
	SELECT VALUE
	FROM OPENJSON( @PSectionIdArray) 
	DECLARE @sectionId INT

	WHILE EXISTS(SELECT SectionIds FROM #tmpSections)
	BEGIN
		SELECT TOP 1 @sectionId = SectionIds FROM #tmpSections
		DROP TABLE IF EXISTS #GetUpdatesCountResult;    
		CREATE TABLE #GetUpdatesCountResult (    
		 ProjectId INT NULL,
		 SectionId INT NULL,
		 CustomerId INT NULL,
		 TotalUpdateCount INT NULL
		);

		INSERT INTO #GetUpdatesCountResult
			EXEC [dbo].[usp_GetUpdatesCount]  @PProjectId, @sectionId, @PCustomerId, @PCatalogType;

		IF EXISTS (SELECT TotalUpdateCount FROM #GetUpdatesCountResult)
		BEGIN
			DECLARE @totalUpdateCount INT;
			SELECT @totalUpdateCount = ISNULL(TotalUpdateCount, 0) FROM #GetUpdatesCountResult;

			BEGIN TRY
				BEGIN TRANSACTION 
					UPDATE ProjectSection SET PendingUpdateCount = @totalUpdateCount WHERE CustomerId = @PCustomerId 
						AND ProjectId = @PProjectId AND SectionId = @sectionId;
				COMMIT TRANSACTION
			END TRY
			BEGIN CATCH
				ROLLBACK TRANSACTION
			END CATCH
		END
		DELETE #tmpSections WHERE SectionIds = @sectionId
	END
END