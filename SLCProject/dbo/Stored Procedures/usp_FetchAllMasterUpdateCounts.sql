CREATE PROCEDURE usp_FetchAllMasterUpdateCounts
AS
BEGIN
	--STEP 1) Get all sections which got published today 
	DROP TABLE IF EXISTS #MasterUpdatesSections;

	SELECT DISTINCT SectionId 
	INTO #MasterUpdatesSections
	FROM SLCMaster..Section 
	WITH(NOLOCK) WHERE CONVERT(VARCHAR, PublicationDate, 23) >= CONVERT(VARCHAR, GETUTCDATE(), 23); -- NOTE: This should be today's date

	--SELECT * FROM  #MasterUpdatesSections;

	IF (SELECT COUNT(SectionId) FROM #MasterUpdatesSections) > 0
	BEGIN

		-- STEP 2) Get all active projects and thier sections with are linked to above mSectionId's
		--		NOTE: Needs to improve below query / Find alternative	
		DROP TABLE IF EXISTS #TempProjectSectiosToBeProcessed;
		DROP TABLE IF EXISTS #ProjectSectiosToBeProcessed;

		SELECT  DISTINCT PS.SectionId, PS.ProjectId, PS.CustomerId
		INTO #TempProjectSectiosToBeProcessed
		FROM ProjectSegmentStatus PSS WITH(NOLOCK) 
			INNER JOIN ProjectSection PS WITH(NOLOCK) ON PS.CustomerId = PSS.CustomerId AND PS.ProjectId = PSS.ProjectId AND PS.SectionId = PSS.SectionId
			INNER JOIN #MasterUpdatesSections MUS ON MUS.SectionId = PS.mSectionId
			INNER JOIN Project P WITH(NOLOCK) ON P.CustomerId = PS.CustomerId AND P.ProjectId = PS.ProjectId
		WHERE ISNULL(PSS.IsDeleted, 0) = 0
		AND ISNULL(P.IsDeleted, 0) = 0
		AND ISNULL(PS.IsDeleted, 0) = 0
		AND ISNULL(PS.IsLastLevel, 0) = 1;

		-- STEP 3) Add RowId column to #ProjectSectiosToBeProcessed to apply while loop
		SELECT ROW_NUMBER() OVER(ORDER BY ProjectId, SectionId ASC) AS RowId, SectionId, ProjectId, CustomerId 
		INTO #ProjectSectiosToBeProcessed
		FROM #TempProjectSectiosToBeProcessed;

		--SELECT * FROM #ProjectSectiosToBeProcessed;

		-- STEP 4) Declae table to store update counts
		DROP TABLE IF EXISTS #GetUpdatesCountResult;    
		CREATE TABLE #GetUpdatesCountResult (    
		 ProjectId INT NULL,
		 SectionId INT NULL,
		 CustomerId INT NULL,
		 TotalUpdateCount INT NULL
		);

		-- STEP 5) Apply while loop on #ProjectSectiosToBeProcessed table and get update count for each section using [usp_GetUpdatesCount] and store it in #GetUpdatesCountResult
		DECLARE @loop INT = 1;
		DECLARE @count INT = (SELECT COUNT(RowId) FROM  #ProjectSectiosToBeProcessed);

		DECLARE @customerId INT = 0;
		DECLARE @projectId INT = 0;
		DECLARE @sectionId INT = 0;

		WHILE (@loop <= @count)
		BEGIN
			SELECT @customerId = CustomerId, @projectId = ProjectId, @sectionId = SectionId 
			FROM  #ProjectSectiosToBeProcessed 
			WHERE RowId = @loop;	

			INSERT INTO #GetUpdatesCountResult
			EXEC [dbo].[usp_GetUpdatesCount]  @projectId, @sectionId, @customerId, 'FS';

			SET @loop = @loop + 1;
		END

		SELECT * FROM #GetUpdatesCountResult;

		-- STEP 6) Update project section table for pending update counts 

		--SELECT R.TotalUpdateCount, PS.* FROM ProjectSection PS WITH(NOLOCK) 
		--INNER JOIN #GetUpdatesCountResult R ON R.CustomerId = PS.CustomerId 
		--		AND R.ProjectId = PS.ProjectId AND R.SectionId = PS.SectionId;
		BEGIN TRY
			BEGIN TRANSACTION
				UPDATE  PS SET PS.PendingUpdateCount = R.TotalUpdateCount FROM ProjectSection PS WITH(NOLOCK) 
				INNER JOIN #GetUpdatesCountResult R ON R.CustomerId = PS.CustomerId 
						AND R.ProjectId = PS.ProjectId AND R.SectionId = PS.SectionId;
			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION
		END CATCH
	END
END