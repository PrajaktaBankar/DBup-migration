
--One Time Script to add Template and Template Style records for System Template per customer

DECLARE @TableRows AS INT, @Record AS INT, @CustomerId AS INT
DECLARE @TemplateCount AS INT = 0


--SLCSERVER01

	DROP TABLE IF EXISTS #tmpCustomers;
	CREATE TABLE #tmpCustomers
	(
		RowNumber INT IDENTITY(1, 1) NOT NULL,
		CustomerId INT NULL
	)

	INSERT INTO #tmpCustomers
	SELECT DISTINCT CustomerId FROM [SLCSERVER01].[SLCProject].[dbo].[Project] WITH (NOLOCK)

	SELECT @TableRows = COUNT(*) FROM #tmpCustomers
	SET @Record = 1

	WHILE @Record <= @TableRows
	BEGIN
		SELECT @CustomerId = CustomerId FROM #tmpCustomers WHERE RowNumber = @Record

		SELECT @TemplateCount = COUNT(TemplateId) FROM [SLCSERVER01].[SLCProject].[dbo].[Template] WITH (NOLOCK) WHERE CustomerId = @CustomerId AND ISNULL(IsSystem, 0) = 1

		IF @TemplateCount > 0
		BEGIN
			
			DROP TABLE IF EXISTS #TmpSystemTemplates;
			--Insert System Templates into Temp table
			SELECT A_TemplateId AS OldTemplateId, T1.[Name] AS SourceTemplateName, @CustomerId AS CustomerId, T1.TemplateId AS NewTemplateId
			INTO #TmpSystemTemplates FROM [SLCSERVER01].[SLCProject].[dbo].[Template] T1 WITH (NOLOCK) WHERE T1.CustomerId = @CustomerId AND ISNULL(T1.IsSystem, 0) = 1

			--Update TemplateId with New TemplateId in Project Table
			UPDATE S SET TemplateId = T1.NewTemplateId
			FROM [SLCProject].[dbo].[Project] S WITH (NOLOCK)
			INNER JOIN #TmpSystemTemplates T1 ON S.TemplateId = T1.OldTemplateId AND S.CustomerId = T1.CustomerId
			WHERE S.CustomerId = @CustomerId AND S.TemplateId IS NOT NULL

			--Update TemplateId with New TemplateId in ProjectSection Table
			UPDATE S SET TemplateId = T1.NewTemplateId
			FROM [SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
			INNER JOIN #TmpSystemTemplates T1 ON S.TemplateId = T1.OldTemplateId AND S.CustomerId = T1.CustomerId
			WHERE S.CustomerId = @CustomerId AND S.TemplateId IS NOT NULL

		END
		 
		SET @Record = @Record + 1 ;
	END


GO


--SLCSERVER02
DECLARE @TableRows AS INT, @Record AS INT, @CustomerId AS INT
DECLARE @TemplateCount AS INT = 0

	DROP TABLE IF EXISTS #tmpCustomers;
	CREATE TABLE #tmpCustomers
	(
		RowNumber INT IDENTITY(1, 1) NOT NULL,
		CustomerId INT NULL
	)

	INSERT INTO #tmpCustomers
	SELECT DISTINCT CustomerId FROM [SLCSERVER02].[SLCProject].[dbo].[Project] WITH (NOLOCK)

	SELECT @TableRows = COUNT(*) FROM #tmpCustomers
	SET @Record = 1

	WHILE @Record <= @TableRows
	BEGIN
		SELECT @CustomerId = CustomerId FROM #tmpCustomers WHERE RowNumber = @Record

		SELECT @TemplateCount = COUNT(TemplateId) FROM [SLCSERVER02].[SLCProject].[dbo].[Template] WITH (NOLOCK) WHERE CustomerId = @CustomerId AND ISNULL(IsSystem, 0) = 1

		IF @TemplateCount > 0
		BEGIN
			
			DROP TABLE IF EXISTS #TmpSystemTemplates;
			--Insert System Templates into Temp table
			SELECT A_TemplateId AS OldTemplateId, T1.[Name] AS SourceTemplateName, @CustomerId AS CustomerId, T1.TemplateId AS NewTemplateId
			INTO #TmpSystemTemplates FROM [SLCSERVER02].[SLCProject].[dbo].[Template] T1 WITH (NOLOCK) WHERE T1.CustomerId = @CustomerId AND ISNULL(T1.IsSystem, 0) = 1

			--Update TemplateId with New TemplateId in Project Table
			UPDATE S SET TemplateId = T1.NewTemplateId
			FROM [SLCProject].[dbo].[Project] S WITH (NOLOCK)
			INNER JOIN #TmpSystemTemplates T1 ON S.TemplateId = T1.OldTemplateId AND S.CustomerId = T1.CustomerId
			WHERE S.CustomerId = @CustomerId AND S.TemplateId IS NOT NULL

			--Update TemplateId with New TemplateId in ProjectSection Table
			UPDATE S SET TemplateId = T1.NewTemplateId
			FROM [SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
			INNER JOIN #TmpSystemTemplates T1 ON S.TemplateId = T1.OldTemplateId AND S.CustomerId = T1.CustomerId
			WHERE S.CustomerId = @CustomerId AND S.TemplateId IS NOT NULL

		END
		 
		SET @Record = @Record + 1 ;
	END



go

--SLCSERVER03
DECLARE @TableRows AS INT, @Record AS INT, @CustomerId AS INT
DECLARE @TemplateCount AS INT = 0

	DROP TABLE IF EXISTS #tmpCustomers;
	CREATE TABLE #tmpCustomers
	(
		RowNumber INT IDENTITY(1, 1) NOT NULL,
		CustomerId INT NULL
	)

	INSERT INTO #tmpCustomers
	SELECT DISTINCT CustomerId FROM [SLCSERVER03].[SLCProject].[dbo].[Project] WITH (NOLOCK)

	SELECT @TableRows = COUNT(*) FROM #tmpCustomers
	SET @Record = 1

	WHILE @Record <= @TableRows
	BEGIN
		SELECT @CustomerId = CustomerId FROM #tmpCustomers WHERE RowNumber = @Record

		SELECT @TemplateCount = COUNT(TemplateId) FROM [SLCSERVER03].[SLCProject].[dbo].[Template] WITH (NOLOCK) WHERE CustomerId = @CustomerId AND ISNULL(IsSystem, 0) = 1

		IF @TemplateCount > 0
		BEGIN
			
			DROP TABLE IF EXISTS #TmpSystemTemplates;
			--Insert System Templates into Temp table
			SELECT A_TemplateId AS OldTemplateId, T1.[Name] AS SourceTemplateName, @CustomerId AS CustomerId, T1.TemplateId AS NewTemplateId
			INTO #TmpSystemTemplates FROM [SLCSERVER03].[SLCProject].[dbo].[Template] T1 WITH (NOLOCK) WHERE T1.CustomerId = @CustomerId AND ISNULL(T1.IsSystem, 0) = 1

			--Update TemplateId with New TemplateId in Project Table
			UPDATE S SET TemplateId = T1.NewTemplateId
			FROM [SLCProject].[dbo].[Project] S WITH (NOLOCK)
			INNER JOIN #TmpSystemTemplates T1 ON S.TemplateId = T1.OldTemplateId AND S.CustomerId = T1.CustomerId
			WHERE S.CustomerId = @CustomerId AND S.TemplateId IS NOT NULL

			--Update TemplateId with New TemplateId in ProjectSection Table
			UPDATE S SET TemplateId = T1.NewTemplateId
			FROM [SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
			INNER JOIN #TmpSystemTemplates T1 ON S.TemplateId = T1.OldTemplateId AND S.CustomerId = T1.CustomerId
			WHERE S.CustomerId = @CustomerId AND S.TemplateId IS NOT NULL

		END
		 
		SET @Record = @Record + 1 ;
	END


go
DECLARE @TableRows AS INT, @Record AS INT, @CustomerId AS INT
DECLARE @TemplateCount AS INT = 0

--SLCSERVER04

	DROP TABLE IF EXISTS #tmpCustomers;
	CREATE TABLE #tmpCustomers
	(
		RowNumber INT IDENTITY(1, 1) NOT NULL,
		CustomerId INT NULL
	)

	INSERT INTO #tmpCustomers
	SELECT DISTINCT CustomerId FROM [SLCSERVER04].[SLCProject].[dbo].[Project] WITH (NOLOCK)

	SELECT @TableRows = COUNT(*) FROM #tmpCustomers
	SET @Record = 1

	WHILE @Record <= @TableRows
	BEGIN
		SELECT @CustomerId = CustomerId FROM #tmpCustomers WHERE RowNumber = @Record

		SELECT @TemplateCount = COUNT(TemplateId) FROM [SLCSERVER04].[SLCProject].[dbo].[Template] WITH (NOLOCK) WHERE CustomerId = @CustomerId AND ISNULL(IsSystem, 0) = 1

		IF @TemplateCount > 0
		BEGIN
			
			DROP TABLE IF EXISTS #TmpSystemTemplates;
			--Insert System Templates into Temp table
			SELECT A_TemplateId AS OldTemplateId, T1.[Name] AS SourceTemplateName, @CustomerId AS CustomerId, T1.TemplateId AS NewTemplateId
			INTO #TmpSystemTemplates FROM [SLCSERVER04].[SLCProject].[dbo].[Template] T1 WITH (NOLOCK) WHERE T1.CustomerId = @CustomerId AND ISNULL(T1.IsSystem, 0) = 1

			--Update TemplateId with New TemplateId in Project Table
			UPDATE S SET TemplateId = T1.NewTemplateId
			FROM [SLCProject].[dbo].[Project] S WITH (NOLOCK)
			INNER JOIN #TmpSystemTemplates T1 ON S.TemplateId = T1.OldTemplateId AND S.CustomerId = T1.CustomerId
			WHERE S.CustomerId = @CustomerId AND S.TemplateId IS NOT NULL

			--Update TemplateId with New TemplateId in ProjectSection Table
			UPDATE S SET TemplateId = T1.NewTemplateId
			FROM [SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
			INNER JOIN #TmpSystemTemplates T1 ON S.TemplateId = T1.OldTemplateId AND S.CustomerId = T1.CustomerId
			WHERE S.CustomerId = @CustomerId AND S.TemplateId IS NOT NULL

		END
		 
		SET @Record = @Record + 1 ;
	END



	go

--SLCSERVER05

DECLARE @TableRows AS INT, @Record AS INT, @CustomerId AS INT
DECLARE @TemplateCount AS INT = 0

	DROP TABLE IF EXISTS #tmpCustomers;
	CREATE TABLE #tmpCustomers
	(
		RowNumber INT IDENTITY(1, 1) NOT NULL,
		CustomerId INT NULL
	)

	INSERT INTO #tmpCustomers
	SELECT DISTINCT CustomerId FROM [SLCSERVER05].[SLCProject].[dbo].[Project] WITH (NOLOCK)

	SELECT @TableRows = COUNT(*) FROM #tmpCustomers
	SET @Record = 1

	WHILE @Record <= @TableRows
	BEGIN
		SELECT @CustomerId = CustomerId FROM #tmpCustomers WHERE RowNumber = @Record

		SELECT @TemplateCount = COUNT(TemplateId) FROM [SLCSERVER05].[SLCProject].[dbo].[Template] WITH (NOLOCK) WHERE CustomerId = @CustomerId AND ISNULL(IsSystem, 0) = 1

		IF @TemplateCount > 0
		BEGIN
			
			DROP TABLE IF EXISTS #TmpSystemTemplates;
			--Insert System Templates into Temp table
			SELECT A_TemplateId AS OldTemplateId, T1.[Name] AS SourceTemplateName, @CustomerId AS CustomerId, T1.TemplateId AS NewTemplateId
			INTO #TmpSystemTemplates FROM [SLCSERVER05].[SLCProject].[dbo].[Template] T1 WITH (NOLOCK) WHERE T1.CustomerId = @CustomerId AND ISNULL(T1.IsSystem, 0) = 1

			--Update TemplateId with New TemplateId in Project Table
			UPDATE S SET TemplateId = T1.NewTemplateId
			FROM [SLCProject].[dbo].[Project] S WITH (NOLOCK)
			INNER JOIN #TmpSystemTemplates T1 ON S.TemplateId = T1.OldTemplateId AND S.CustomerId = T1.CustomerId
			WHERE S.CustomerId = @CustomerId AND S.TemplateId IS NOT NULL

			--Update TemplateId with New TemplateId in ProjectSection Table
			UPDATE S SET TemplateId = T1.NewTemplateId
			FROM [SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
			INNER JOIN #TmpSystemTemplates T1 ON S.TemplateId = T1.OldTemplateId AND S.CustomerId = T1.CustomerId
			WHERE S.CustomerId = @CustomerId AND S.TemplateId IS NOT NULL

		END
		 
		SET @Record = @Record + 1 ;
	END






--SLCSERVER07
GO

DECLARE @TableRows AS INT, @Record AS INT, @CustomerId AS INT
DECLARE @TemplateCount AS INT = 0


	DROP TABLE IF EXISTS #tmpCustomers;
	CREATE TABLE #tmpCustomers
	(
		RowNumber INT IDENTITY(1, 1) NOT NULL,
		CustomerId INT NULL
	)

	INSERT INTO #tmpCustomers
	SELECT DISTINCT CustomerId FROM [SLCSERVER07].[SLCProject].[dbo].[Project] WITH (NOLOCK)

	SELECT @TableRows = COUNT(*) FROM #tmpCustomers
	SET @Record = 1

	WHILE @Record <= @TableRows
	BEGIN
		SELECT @CustomerId = CustomerId FROM #tmpCustomers WHERE RowNumber = @Record

		SELECT @TemplateCount = COUNT(TemplateId) FROM [SLCSERVER07].[SLCProject].[dbo].[Template] WITH (NOLOCK) WHERE CustomerId = @CustomerId AND ISNULL(IsSystem, 0) = 1

		IF @TemplateCount > 0
		BEGIN
			
			DROP TABLE IF EXISTS #TmpSystemTemplates;
			--Insert System Templates into Temp table
			SELECT A_TemplateId AS OldTemplateId, T1.[Name] AS SourceTemplateName, @CustomerId AS CustomerId, T1.TemplateId AS NewTemplateId
			INTO #TmpSystemTemplates FROM [SLCSERVER07].[SLCProject].[dbo].[Template] T1 WITH (NOLOCK) WHERE T1.CustomerId = @CustomerId AND ISNULL(T1.IsSystem, 0) = 1

			--Update TemplateId with New TemplateId in Project Table
			UPDATE S SET TemplateId = T1.NewTemplateId
			FROM [SLCProject].[dbo].[Project] S WITH (NOLOCK)
			INNER JOIN #TmpSystemTemplates T1 ON S.TemplateId = T1.OldTemplateId AND S.CustomerId = T1.CustomerId
			WHERE S.CustomerId = @CustomerId AND S.TemplateId IS NOT NULL

			--Update TemplateId with New TemplateId in ProjectSection Table
			UPDATE S SET TemplateId = T1.NewTemplateId
			FROM [SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
			INNER JOIN #TmpSystemTemplates T1 ON S.TemplateId = T1.OldTemplateId AND S.CustomerId = T1.CustomerId
			WHERE S.CustomerId = @CustomerId AND S.TemplateId IS NOT NULL

		END
		 
		SET @Record = @Record + 1 ;
	END