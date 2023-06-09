CREATE PROCEDURE [dbo].[usp_SaveHeaderFooterDetails]    
 @ProjectId INT,    
 @CustomerId INT,    
 @UserId INT,    
 @DocumentTypeId INT,    
 @HeaderJson NVARCHAR(MAX),    
 @FooterJson NVARCHAR(MAX),    
 @GlobalTermUsageJson NVARCHAR(MAX) = ''

 AS        
 BEGIN
  
 DECLARE @PProjectId INT = @ProjectId;
 DECLARE @PCustomerId INT = @CustomerId;
 DECLARE @PUserId INT = @UserId;
 DECLARE @PHeaderJson NVARCHAR(MAX) = @HeaderJson;
 DECLARE @PFooterJson NVARCHAR(MAX) = @FooterJson;
 DECLARE @PGlobalTermUsageJson NVARCHAR(MAX) = @GlobalTermUsageJson;
    
 --DECLARE VARIABLES    
 DECLARE @HeaderTable TABLE(    
 RowId INT,    
 HeaderId INT NULL,    
 ProjectId INT NOT NULL,    
 SectionId INT NULL,     
 CustomerId INT NOT NULL,      
 TypeId INT NULL,    
 HeaderFooterCategoryId INT NULL,    
 DateFormat NVARCHAR(MAX) NULL,    
 TimeFormat NVARCHAR(MAX) NULL,    
 HeaderFooterDisplayTypeId INT NOT NULL,    
 DefaultHeader NVARCHAR(MAX) NULL,    
 FirstPageHeader NVARCHAR(MAX) NULL,    
 OddPageHeader NVARCHAR(MAX) NULL,    
 EvenPageHeader NVARCHAR(MAX) NULL  ,
 DocumentTypeId  INT NOT NULL,
 IsShowLineAboveHeader BIT,
 IsShowLineBelowHeader BIT
 );
  
 DECLARE @FooterTable TABLE(    
 RowId INT,    
 HeaderId INT NULL,    
 ProjectId INT NOT NULL,    
 SectionId INT NULL,     
 CustomerId INT NOT NULL,      
 TypeId INT NULL,    
 HeaderFooterCategoryId INT NULL,    
 DateFormat NVARCHAR(MAX) NULL,    
 TimeFormat NVARCHAR(MAX) NULL,    
 HeaderFooterDisplayTypeId INT NOT NULL,    
 DefaultFooter NVARCHAR(MAX) NULL,    
 FirstPageFooter NVARCHAR(MAX) NULL,    
 OddPageFooter NVARCHAR(MAX) NULL,    
 EvenPageFooter NVARCHAR(MAX) NULL ,
 DocumentTypeId  INT NOT NULL,
 IsShowLineAboveFooter  BIT,
 IsShowLineBelowFooter  BIT 
 );
  
DECLARE @GlobalTermUsageTable TABLE(    
 ProjectId INT NULL,    
 SectionId INT NULL,    
 CustomerId INT NULL,    
 GlobalTermCode INT NULL,    
 IsUsedInHeader BIT NULL,    
 IsUsedInFooter BIT NULL    
 );
    
 DECLARE @HeaderTableLoopCounter INT = 1;
      
 DECLARE @FooterTableLoopCounter INT = 1;
      
 DECLARE @TypeId INT = NULL;
      
 DECLARE @SectionId INT = NULL;
      
 DECLARE @IsInsertRecord BIT = NULL;
     
    
 --FETCH DETAILS FROM JSON INTO TABLE FORMAT    
 --FETCH Header INPUT DATA    
 IF @PHeaderJson != ''    
 BEGIN
INSERT INTO @HeaderTable (RowId, ProjectId, SectionId, CustomerId, TypeId, HeaderFooterCategoryId,
HeaderFooterDisplayTypeId, DefaultHeader, FirstPageHeader, OddPageHeader, EvenPageHeader, DocumentTypeId ,IsShowLineAboveHeader ,IsShowLineBelowHeader)
	SELECT
		ROW_NUMBER() OVER (ORDER BY ProjectId ASC) AS RowId
	   ,ProjectId
	   ,SectionId
	   ,CustomerId
	   ,TypeId
	   ,HeaderFooterCategoryId
	   ,HeaderFooterDisplayTypeId
	   ,DefaultHeader
	   ,FirstPageHeader
	   ,OddPageHeader
	   ,EvenPageHeader
	   ,DocumentTypeId
	   ,IsShowLineAboveHeader  
	   ,IsShowLineBelowHeader  
	FROM OPENJSON(@PHeaderJson)
	WITH (
	ProjectId INT '$.ProjectId',
	SectionId INT '$.SectionId',
	CustomerId INT '$.CustomerId',
	TypeId INT '$.TypeId',
	HeaderFooterCategoryId INT '$.HeaderFooterCategoryId',
	HeaderFooterDisplayTypeId INT '$.HeaderFooterDisplayTypeId',
	DefaultHeader NVARCHAR(MAX) '$.DefaultHeader',
	FirstPageHeader NVARCHAR(MAX) '$.FirstPageHeader',
	OddPageHeader NVARCHAR(MAX) '$.OddPageHeader',
	EvenPageHeader NVARCHAR(MAX) '$.EvenPageHeader',
	DocumentTypeId INT '$.DocumentTypeId',
	IsShowLineAboveHeader   BIT '$.IsShowLineAboveHeader',
	IsShowLineBelowHeader   BIT '$.IsShowLineBelowHeader'
	);
END

--FETCH Footer INPUT DATA    
IF @PFooterJson != ''
BEGIN
INSERT INTO @FooterTable (RowId, ProjectId, SectionId, CustomerId, TypeId, HeaderFooterCategoryId,
HeaderFooterDisplayTypeId, DefaultFooter, FirstPageFooter, OddPageFooter, EvenPageFooter, DocumentTypeId,IsShowLineAboveFooter,IsShowLineBelowFooter)
	SELECT
		ROW_NUMBER() OVER (ORDER BY ProjectId ASC) AS RowId
	   ,ProjectId
	   ,SectionId
	   ,CustomerId
	   ,TypeId
	   ,HeaderFooterCategoryId
	   ,HeaderFooterDisplayTypeId
	   ,DefaultFooter
	   ,FirstPageFooter
	   ,OddPageFooter
	   ,EvenPageFooter
	   ,DocumentTypeId
	   ,IsShowLineAboveFooter
	   ,IsShowLineBelowFooter
	FROM OPENJSON(@PFooterJson)
	WITH (
	ProjectId INT '$.ProjectId',
	SectionId INT '$.SectionId',
	CustomerId INT '$.CustomerId',
	TypeId INT '$.TypeId',
	HeaderFooterCategoryId INT '$.HeaderFooterCategoryId',
	HeaderFooterDisplayTypeId INT '$.HeaderFooterDisplayTypeId',
	DefaultFooter NVARCHAR(MAX) '$.DefaultFooter',
	FirstPageFooter NVARCHAR(MAX) '$.FirstPageFooter',
	OddPageFooter NVARCHAR(MAX) '$.OddPageFooter',
	EvenPageFooter NVARCHAR(MAX) '$.EvenPageFooter',
	DocumentTypeId INT '$.DocumentTypeId',
	IsShowLineAboveFooter BIT '$.IsShowLineAboveFooter',
	IsShowLineBelowFooter BIT '$.IsShowLineBelowFooter'
	);
END

--FETCH GlobalTermUsage INPUT DATA    
IF @PGlobalTermUsageJson != ''
BEGIN
INSERT INTO @GlobalTermUsageTable (ProjectId, SectionId, CustomerId, GlobalTermCode, IsUsedInHeader, IsUsedInFooter)
	SELECT
		COALESCE(ProjectId, 0) AS ProjectId
	   ,COALESCE(SectionId, 0) AS SectionId
	   ,COALESCE(CustomerId, 0) AS CustomerId
	   ,COALESCE(GlobalTermCode, 0) AS GlobalTermCode
	   ,COALESCE(IsUsedInHeader, 0) AS IsUsedInHeader
	   ,COALESCE(IsUsedInFooter, 0) AS IsUsedInFooter
	FROM OPENJSON(@PGlobalTermUsageJson)
	WITH (
	ProjectId INT '$.ProjectId',
	SectionId INT '$.SectionId',
	CustomerId INT '$.CustomerId',
	GlobalTermCode INT '$.GlobalTermCode',
	IsUsedInHeader BIT '$.IsUsedInHeader',
	IsUsedInFooter BIT '$.IsUsedInFooter'
	);
END

IF (@DocumentTypeId = 1)
BEGIN
--INSERT/UPDATE REQUIRED DATA FOR Header TABLE    
DECLARE @HeaderTableCounter INT = (SELECT
		COUNT(1)
	FROM @HeaderTable)

WHILE (@HeaderTableLoopCounter <= @HeaderTableCounter
)
BEGIN

UPDATE HT
SET HT.TypeId = (CASE
	WHEN HT.SectionId IS NULL OR
		ISNULL(HT.SectionId, 0) <= 0 THEN 1
	ELSE 2
END)
FROM @HeaderTable HT
WHERE HT.RowId = @HeaderTableLoopCounter

SELECT
	@TypeId = TypeId
   ,@SectionId = SectionId
FROM @HeaderTable
WHERE RowId = @HeaderTableLoopCounter;

--CHECK WHETHER INSERT/UPDATE    
IF @TypeId = 1
	AND NOT EXISTS (SELECT 
	TOP 1 1
		FROM Header WITH (NOLOCK)
		WHERE ProjectId = @PProjectId
		AND CustomerId = @PCustomerId
		AND (SectionId IS NULL
		OR ISNULL(SectionId, 0) <= 0)
		AND DocumentTypeId = 1)
BEGIN
SET @IsInsertRecord = 1
      
 END    
 ELSE IF @TypeId = 2 AND NOT EXISTS (SELECT 
 TOP 1 1
	FROM Header WITH (NOLOCK)
	WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND ISNULL(SectionId, 0) = ISNULL(@SectionId, 0)
	AND DocumentTypeId = 1)
BEGIN
SET @IsInsertRecord = 1
 END    
 ELSE    
 BEGIN
SET @IsInsertRecord = 0;
 END
     
   
 --INSERT HEADER DATA    
 IF @IsInsertRecord = 1    
 BEGIN
INSERT INTO Header (ProjectId, SectionId, CustomerId, CreatedBy, CreatedDate, TypeId, HeaderFooterCategoryId,
HeaderFooterDisplayTypeId, DefaultHeader, FirstPageHeader, OddPageHeader, EvenPageHeader, DocumentTypeId, IsShowLineAboveHeader, IsShowLineBelowHeader)
	SELECT
		@PProjectId AS ProjectId
	   ,NULLIF(@SectionId, 0) AS SectionId
	   ,@PCustomerId AS CustomerId
	   ,@PUserId AS CreatedBy
	   ,GETUTCDATE() AS CreatedDate
	   ,HTbl.TypeId AS TypeId
	   ,(CASE
			WHEN @SectionId IS NULL THEN 1
			WHEN @SectionId <= 0 THEN 1
			ELSE 4
		END) AS HeaderFooterCategoryId
	   ,HTbl.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId
	   ,HTbl.DefaultHeader AS DefaultHeader
	   ,HTbl.FirstPageHeader AS FirstPageHeader
	   ,HTbl.OddPageHeader AS OddPageHeader
	   ,HTbl.EvenPageHeader AS EvenPageHeader
	   ,HTbl.DocumentTypeId AS DocumentTypeId
	   ,HTbl.IsShowLineAboveHeader AS IsShowLineAboveHeader
	   ,HTbl.IsShowLineBelowHeader AS IsShowLineBelowHeader
	FROM @HeaderTable HTbl
	WHERE RowId = @HeaderTableLoopCounter
	AND HTbl.DocumentTypeId = @DocumentTypeId


END
ELSE
--UPDATE HEADER DATA    
IF @IsInsertRecord = 0
BEGIN
UPDATE H
SET H.HeaderFooterCategoryId = (CASE
		WHEN H.SectionId IS NULL THEN 1
		WHEN ISNULL(H.SectionId, 0) <= 0 THEN 1
		ELSE 4
	END)
   ,H.HeaderFooterDisplayTypeId = HTbl.HeaderFooterDisplayTypeId
   ,H.DefaultHeader = HTbl.DefaultHeader
   ,H.FirstPageHeader = HTbl.FirstPageHeader
   ,H.OddPageHeader = HTbl.OddPageHeader
   ,H.EvenPageHeader = HTbl.EvenPageHeader
   ,H.IsShowLineAboveHeader = HTbl.IsShowLineAboveHeader
   ,H.IsShowLineBelowHeader = HTbl.IsShowLineBelowHeader
FROM Header H WITH (NOLOCK)
INNER JOIN @HeaderTable HTbl
	ON HTbl.RowId = @HeaderTableLoopCounter
WHERE H.ProjectId = @PProjectId
AND H.CustomerId = @PCustomerId
AND ISNULL(H.SectionId, 0) = ISNULL(@SectionId, 0)
AND H.DocumentTypeId = @DocumentTypeId
END

SET @HeaderTableLoopCounter = @HeaderTableLoopCounter + 1;
     
 END
 
 --INSERT/UPDATE REQUIRED DATA FOR Header TABLE    
 
 DECLARE @FooterTableCounter int =( SELECT
		COUNT(1)
	FROM @FooterTable)

WHILE (@FooterTableLoopCounter <= @FooterTableCounter
)
BEGIN

UPDATE FT
SET FT.TypeId = (CASE
	WHEN FT.SectionId IS NULL OR
		ISNULL(FT.SectionId, 0) <= 0 THEN 1
	ELSE 2
END)
FROM @FooterTable FT
WHERE FT.RowId = @FooterTableLoopCounter

SELECT
	@TypeId = TypeId
   ,@SectionId = SectionId
FROM @FooterTable
WHERE RowId = @FooterTableLoopCounter;

--CHECK WHETHER INSERT/UPDATE    
IF @TypeId = 1
	AND NOT EXISTS (SELECT
	TOP 1 1
		FROM Footer WITH (NOLOCK)
		WHERE ProjectId = @PProjectId
		AND CustomerId = @PCustomerId
		AND (SectionId IS NULL
		OR ISNULL(SectionId, 0) <= 0)
		AND DocumentTypeId = 1)
BEGIN
SET @IsInsertRecord = 1
  
    
 END    
 ELSE IF @TypeId = 2 AND NOT EXISTS (SELECT TOP 1
		1
	FROM Footer WITH (NOLOCK)
	WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND ISNULL(SectionId, 0) = ISNULL(@SectionId, 0)
	AND DocumentTypeId = 1)
BEGIN
SET @IsInsertRecord = 1
 END     
 ELSE    
 BEGIN
SET @IsInsertRecord = 0;
      
 END
     
    
 --INSERT HEADER DATA    
 IF @IsInsertRecord = 1    
 BEGIN
INSERT INTO Footer (ProjectId, SectionId, CustomerId, CreatedBy, CreatedDate, TypeId, HeaderFooterCategoryId,
HeaderFooterDisplayTypeId, DefaultFooter, FirstPageFooter, OddPageFooter, EvenPageFooter, DocumentTypeId,IsShowLineAboveFooter ,IsShowLineBelowFooter )
	SELECT
		@PProjectId AS ProjectId
	   ,NULLIF(@SectionId, 0) AS SectionId
	   ,@PCustomerId AS CustomerId
	   ,@PUserId AS CreatedBy
	   ,GETUTCDATE() AS CreatedDate
	   ,FTbl.TypeId AS TypeId
	   ,(CASE
			WHEN @SectionId IS NULL THEN 1
			WHEN @SectionId <= 0 THEN 1
			ELSE 4
		END) AS HeaderFooterCategoryId
	   ,FTbl.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId
	   ,FTbl.DefaultFooter AS DefaultFooter
	   ,FTbl.FirstPageFooter AS FirstPageFooter
	   ,FTbl.OddPageFooter AS OddPageFooter
	   ,FTbl.EvenPageFooter AS EvenPageFooter
	   ,FTbl.DocumentTypeId AS DocumentTypeId
	   ,FTbl.IsShowLineAboveFooter  AS IsShowLineAboveFooter 
	   ,FTbl.IsShowLineBelowFooter  AS IsShowLineBelowFooter 
	FROM @FooterTable FTbl
	WHERE RowId = @FooterTableLoopCounter
	AND FTbl.DocumentTypeId = @DocumentTypeId
END
ELSE
--UPDATE HEADER DATA    
IF @IsInsertRecord = 0
BEGIN
UPDATE F
SET F.HeaderFooterCategoryId = (CASE
		WHEN F.SectionId IS NULL THEN 1
		WHEN F.SectionId <= 0 THEN 1
		ELSE 4
	END)
   ,F.HeaderFooterDisplayTypeId = FTbl.HeaderFooterDisplayTypeId
   ,F.DefaultFooter = FTbl.DefaultFooter
   ,F.FirstPageFooter = FTbl.FirstPageFooter
   ,F.OddPageFooter = FTbl.OddPageFooter
   ,F.EvenPageFooter = FTbl.EvenPageFooter
   ,F.IsShowLineAboveFooter = FTbl.IsShowLineAboveFooter
   ,F.IsShowLineBelowFooter = FTbl.IsShowLineBelowFooter
FROM Footer F WITH (NOLOCK)
INNER JOIN @FooterTable FTbl
	ON FTbl.RowId = @FooterTableLoopCounter
WHERE F.ProjectId = @PProjectId
AND F.CustomerId = @PCustomerId
AND ISNULL(F.SectionId, 0) = ISNULL(@SectionId, 0)
AND F.DocumentTypeId = @DocumentTypeId
END


SET @FooterTableLoopCounter = @FooterTableLoopCounter + 1;
    
 END
 END
 ELSE
 BEGIN
 if EXISTS (SELECT TOP 1
		1
	FROM Header WITH (NOLOCK)
	WHERE ProjectId = @ProjectId
	AND DocumentTypeId = @DocumentTypeId)
BEGIN
UPDATE H
SET H.HeaderFooterDisplayTypeId = HTbl.HeaderFooterDisplayTypeId
   ,H.DefaultHeader = HTbl.DefaultHeader
   ,H.FirstPageHeader = HTbl.FirstPageHeader
   ,H.OddPageHeader = HTbl.OddPageHeader
   ,H.EvenPageHeader = HTbl.EvenPageHeader
   ,H.IsShowLineAboveHeader = HTbl.IsShowLineAboveHeader
   ,H.IsShowLineBelowHeader = HTbl.IsShowLineBelowHeader
FROM Header H WITH (NOLOCK)
INNER JOIN @HeaderTable HTbl
	ON HTbl.DocumentTypeId = H.DocumentTypeId
WHERE H.ProjectId = @PProjectId
AND H.CustomerId = @PCustomerId
AND H.DocumentTypeId = @DocumentTypeId
END
ELSE
BEGIN
INSERT INTO Header (ProjectId, SectionId, CustomerId, CreatedBy, CreatedDate, TypeId, HeaderFooterCategoryId,
HeaderFooterDisplayTypeId, DefaultHeader, FirstPageHeader, OddPageHeader, EvenPageHeader, DocumentTypeId, IsShowLineAboveHeader ,IsShowLineBelowHeader)
	SELECT
		@PProjectId AS ProjectId
	   ,NULLIF(@SectionId, 0) AS SectionId
	   ,@PCustomerId AS CustomerId
	   ,@PUserId AS CreatedBy
	   ,GETUTCDATE() AS CreatedDate
	   ,HTbl.TypeId AS TypeId
	   ,(CASE
			WHEN @SectionId IS NULL THEN 1
			WHEN @SectionId <= 0 THEN 1
			ELSE 4
		END) AS HeaderFooterCategoryId
	   ,HTbl.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId
	   ,HTbl.DefaultHeader AS DefaultHeader
	   ,HTbl.FirstPageHeader AS FirstPageHeader
	   ,HTbl.OddPageHeader AS OddPageHeader
	   ,HTbl.EvenPageHeader AS EvenPageHeader
	   ,HTbl.DocumentTypeId AS DocumentTypeId
	   ,HTbl.IsShowLineAboveHeader AS IsShowLineAboveHeader
	   ,HTbl.IsShowLineBelowHeader AS IsShowLineBelowHeader
	FROM @HeaderTable HTbl
	WHERE HTbl.DocumentTypeId = @DocumentTypeId


END

IF EXISTS (SELECT TOP 1
			1
		FROM Footer WITH (NOLOCK)
		WHERE ProjectId = @ProjectId
		AND DocumentTypeId = @DocumentTypeId)
BEGIN
UPDATE F
SET F.HeaderFooterDisplayTypeId = FTbl.HeaderFooterDisplayTypeId
   ,F.DefaultFooter = FTbl.DefaultFooter
   ,F.FirstPageFooter = FTbl.FirstPageFooter
   ,F.OddPageFooter = FTbl.OddPageFooter
   ,F.EvenPageFooter = FTbl.EvenPageFooter
   ,F.IsShowLineAboveFooter = FTbl.IsShowLineAboveFooter
   ,F.IsShowLineBelowFooter = FTbl.IsShowLineBelowFooter
FROM Footer F WITH (NOLOCK)
INNER JOIN @FooterTable FTbl
	ON FTbl.DocumentTypeId = F.DocumentTypeId
WHERE F.ProjectId = @PProjectId
AND F.CustomerId = @PCustomerId
AND F.DocumentTypeId = @DocumentTypeId
END
ELSE
BEGIN
INSERT INTO Footer (ProjectId, SectionId, CustomerId, CreatedBy, CreatedDate, TypeId, HeaderFooterCategoryId,
HeaderFooterDisplayTypeId, DefaultFooter, FirstPageFooter, OddPageFooter, EvenPageFooter, DocumentTypeId, IsShowLineAboveFooter ,IsShowLineBelowFooter)
	SELECT
		@PProjectId AS ProjectId
	   ,NULLIF(@SectionId, 0) AS SectionId
	   ,@PCustomerId AS CustomerId
	   ,@PUserId AS CreatedBy
	   ,GETUTCDATE() AS CreatedDate
	   ,FTbl.TypeId AS TypeId
	   ,(CASE
			WHEN @SectionId IS NULL THEN 1
			WHEN @SectionId <= 0 THEN 1
			ELSE 4
		END) AS HeaderFooterCategoryId
	   ,FTbl.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId
	   ,FTbl.DefaultFooter AS DefaultFooter
	   ,FTbl.FirstPageFooter AS FirstPageFooter
	   ,FTbl.OddPageFooter AS OddPageFooter
	   ,FTbl.EvenPageFooter AS EvenPageFooter
	   ,FTbl.DocumentTypeId AS DocumentTypeId
	   ,FTbl.IsShowLineAboveFooter AS  IsShowLineAboveFooter 
	   ,FTbl.IsShowLineBelowFooter AS IsShowLineBelowFooter
	FROM @FooterTable FTbl
	WHERE FTbl.DocumentTypeId = @DocumentTypeId
END

END

--INSERT/DELETE DATA IN HeaderFooterGlobalTermUsage TABLE FOR Header    
DELETE HFGT
	FROM @GlobalTermUsageTable GTUT
	INNER JOIN Header H WITH (NOLOCK)
		ON GTUT.ProjectId = ISNULL(H.ProjectId, 0)
		AND GTUT.SectionId = ISNULL(H.SectionId, 0)
		AND GTUT.CustomerId = ISNULL(H.CustomerId, 0)
	INNER JOIN HeaderFooterGlobalTermUsage HFGT WITH (NOLOCK)
		ON H.HeaderId = ISNULL(HFGT.HeaderId, 0)
WHERE GTUT.IsUsedInHeader = 1
	AND H.DocumentTypeId = @DocumentTypeId

INSERT INTO HeaderFooterGlobalTermUsage (HeaderId, FooterId, UserGlobalTermId, CustomerId,
ProjectId, HeaderFooterCategoryId, CreatedDate, CreatedById)
	SELECT
		H.HeaderId AS HeaderId
	   ,NULL AS FooterId
	   ,PGT.UserGlobalTermId AS UserGlobalTermId
	   ,GTUT.CustomerId AS CustomerId
	   ,GTUT.ProjectId AS ProjectId
	   ,H.HeaderFooterCategoryId AS HeaderFooterCategoryId
	   ,GETUTCDATE() AS CreatedDate
	   ,@PUserId AS CreatedById
	FROM @GlobalTermUsageTable GTUT
	INNER JOIN Header H WITH (NOLOCK)
		ON GTUT.ProjectId = ISNULL(H.ProjectId, 0)
			AND GTUT.SectionId = ISNULL(H.SectionId, 0)
			AND GTUT.CustomerId = ISNULL(H.CustomerId, 0)
	INNER JOIN ProjectGlobalTerm PGT WITH (NOLOCK)
		ON GTUT.GlobalTermCode = PGT.GlobalTermCode
			AND GTUT.ProjectId = PGT.ProjectId
			AND GTUT.CustomerId = PGT.CustomerId
	WHERE GTUT.IsUsedInHeader = 1
	AND PGT.UserGlobalTermId IS NOT NULL
	AND H.DocumentTypeId = @DocumentTypeId

--INSERT/DELETE DATA IN HeaderFooterGlobalTermUsage TABLE FOR Footer    
DELETE HFGT
	FROM @GlobalTermUsageTable GTUT
	INNER JOIN Footer F
		ON GTUT.ProjectId = ISNULL(F.ProjectId, 0)
		AND GTUT.SectionId = ISNULL(F.SectionId, 0)
		AND GTUT.CustomerId = ISNULL(F.CustomerId, 0)
	INNER JOIN HeaderFooterGlobalTermUsage HFGT WITH (NOLOCK)
		ON F.FooterId = ISNULL(HFGT.FooterId, 0)
WHERE GTUT.IsUsedInFooter = 1
	AND F.DocumentTypeId = @DocumentTypeId

INSERT INTO HeaderFooterGlobalTermUsage (HeaderId, FooterId, UserGlobalTermId, CustomerId,
ProjectId, HeaderFooterCategoryId, CreatedDate, CreatedById)
	SELECT
		NULL AS HeaderId
	   ,F.FooterId AS FooterId
	   ,PGT.UserGlobalTermId AS UserGlobalTermId
	   ,GTUT.CustomerId AS CustomerId
	   ,GTUT.ProjectId AS ProjectId
	   ,F.HeaderFooterCategoryId AS HeaderFooterCategoryId
	   ,GETUTCDATE() AS CreatedDate
	   ,@PUserId AS CreatedById
	FROM @GlobalTermUsageTable GTUT
	INNER JOIN Footer F WITH (NOLOCK)
		ON GTUT.ProjectId = ISNULL(F.ProjectId, 0)
			AND GTUT.SectionId = ISNULL(F.SectionId, 0)
			AND GTUT.CustomerId = ISNULL(F.CustomerId, 0)
	INNER JOIN ProjectGlobalTerm PGT WITH (NOLOCK)
		ON GTUT.GlobalTermCode = PGT.GlobalTermCode
			AND GTUT.ProjectId = PGT.ProjectId
			AND GTUT.CustomerId = PGT.CustomerId
	WHERE GTUT.IsUsedInFooter = 1
	AND PGT.UserGlobalTermId IS NOT NULL
	AND F.DocumentTypeId = @DocumentTypeId
END
GO