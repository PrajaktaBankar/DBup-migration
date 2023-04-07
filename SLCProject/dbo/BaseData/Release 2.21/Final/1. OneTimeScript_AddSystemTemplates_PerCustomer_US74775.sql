
--One Time Script to add Template and Template Style records for System Template per customer

	DROP TABLE IF EXISTS #tmpCustomers;
	CREATE TABLE #tmpCustomers
	(
		RowNumber INT IDENTITY(1, 1) NOT NULL,
		CustomerId INT NULL
	)

	DECLARE @TableRows AS INT, @Record AS INT, @CustomerId AS INT
	DECLARE @TemplateCount AS INT = 0

	INSERT INTO #tmpCustomers
	SELECT DISTINCT CustomerId FROM [SLCProject].[dbo].[Project] WITH (NOLOCK)

	SELECT @TableRows = COUNT(*) FROM #tmpCustomers
	SET @Record = 1

	WHILE @Record <= @TableRows
	BEGIN
		SELECT @CustomerId = CustomerId FROM #tmpCustomers WHERE RowNumber = @Record

		SELECT @TemplateCount = COUNT(TemplateId) FROM [SLCProject].[dbo].[Template] WITH (NOLOCK) WHERE CustomerId = @CustomerId AND ISNULL(IsSystem, 0) = 1

		IF @TemplateCount <= 0
		BEGIN
			--Add System Templates for Customer
			INSERT INTO [SLCProject].[dbo].[Template]
			([Name],[TitleFormatId],[SequenceNumbering],[CustomerId],[IsSystem],[IsDeleted],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[MasterDataTypeId],[A_TemplateId]
				,[ApplyTitleStyleToEOS],[IsTransferred])
			SELECT [Name],[TitleFormatId],[SequenceNumbering],@CustomerId AS CustomerId,[IsSystem],[IsDeleted],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[MasterDataTypeId],TemplateId AS [A_TemplateId]
				,[ApplyTitleStyleToEOS],[IsTransferred]
			FROM [SLCProject].[dbo].[Template] WITH (NOLOCK) WHERE CustomerId IS NULL AND ISNULL(IsSystem, 0) = 1

			--Add TemplateStyle for System Templates
			INSERT INTO [SLCProject].[dbo].[TemplateStyle]
			([TemplateId],[StyleId],[Level],[CustomerId],[A_TemplateStyleId])
			SELECT C.TemplateId, B.StyleId, B.[Level], @CustomerId AS CustomerId, [TemplateStyleId] AS [A_TemplateStyleId]
			FROM [SLCProject].[dbo].[Template] A WITH (NOLOCK)
			INNER JOIN [SLCProject].[dbo].[TemplateStyle] B WITH (NOLOCK) ON A.TemplateId = B.TemplateId
			INNER JOIN [SLCProject].[dbo].[Template] C WITH (NOLOCK) ON C.CustomerId = @CustomerId AND ISNULL(C.IsSystem, 0) = 1 AND C.[Name] = A.[Name]
			WHERE A.CustomerId IS NULL AND ISNULL(A.IsSystem, 0) = 1
	
		END
		 
		SET @Record = @Record + 1 ;
	END

  
		
