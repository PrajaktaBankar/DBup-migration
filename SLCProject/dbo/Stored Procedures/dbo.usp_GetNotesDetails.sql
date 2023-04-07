
CREATE PROCEDURE [dbo].[usp_GetNotesDetails]
(
 @ProjectId INT,
 @SectionId INT,
 @mSectionId INT,
 @CatalogueType VARCHAR(50) NULL = 'FS'
)
AS
BEGIN
	DECLARE @PmSectionId INT = @mSectionId;
	DECLARE @PSectionId INT = @SectionId;
	DECLARE @PProjectId INT = @ProjectId;
	DECLARE @PCatalogueType varchar(50) = @CatalogueType;

	-- Drop temp tables if already present
	DROP TABLE IF EXISTS #TempSectionNotes;
	DROP TABLE IF EXISTS #ImageTable;
	DROP TABLE IF EXISTS #HyperLinkTable;

	DECLARE @CatalogueTypeTbl TABLE (TagType NVARCHAR(MAX));

	--CONVERT CATALOGUE TYPE INTO TABLE
	IF @PCatalogueType IS NOT NULL AND @PCatalogueType != 'FS'
	BEGIN
		INSERT INTO @CatalogueTypeTbl (TagType)
		SELECT * FROM dbo.fn_SplitString(@PCatalogueType, ',');

		IF EXISTS (SELECT * FROM @CatalogueTypeTbl WHERE TagType = 'OL')
		BEGIN
			INSERT INTO @CatalogueTypeTbl VALUES ('UO');
		END

		IF EXISTS (SELECT * FROM @CatalogueTypeTbl WHERE TagType = 'SF')
		BEGIN
			INSERT INTO @CatalogueTypeTbl VALUES ('US');
		END
	END

	DECLARE @ImageFormat VARCHAR(50) = 'IMG#';
	DECLARE @HLFormat VARCHAR(50) = 'HL#';

	--NoteId, SegmentStatusId, NoteText, SectionId, SegmentId, MasterDataTypeId, CreateDate, ModifiedDate, PublicationDate, MasterNoteTypeId
	SELECT *
	INTO #TempSectionNotes
	FROM (SELECT
			N.NoteId
		   ,PSST.SegmentStatusId
		   ,'' AS Title
		   ,0 AS IsDeleted
		   ,dbo.ModifyNoteStringWtihNewLineAndSpaces(N.NoteText) AS NoteText
		   ,N.CreateDate
		   ,N.ModifiedDate
		   ,'System' AS CreatedUserName
		   ,'System' AS ModifiedUserName
		   ,'M' AS NoteType
		   ,PSST.SequenceNumber
		   ,'M' AS [Source]

		FROM SLCMaster..Note N WITH (NOLOCK)
		INNER JOIN ProjectSegmentStatus PSST WITH(NOLOCK)
			ON N.SegmentStatusId = PSST.mSegmentStatusId
			AND PSST.ProjectId = @PProjectId AND PSST.SectionId = @PSectionId
		LEFT OUTER JOIN SLCMaster..LuSpecTypeTag AS STT WITH (NOLOCK)
			ON PSST.SpecTypeTagId = STT.SpecTypeTagId
		WHERE N.SectionId = @PmSectionId
		AND PSST.ProjectId = @PProjectId AND PSST.SectionId = @PSectionId
		AND (@PCatalogueType = 'FS'
		OR STT.TagType IN (SELECT TagType FROM @CatalogueTypeTbl)
		)
		UNION
		SELECT
			PN.NoteId
		   ,PN.SegmentStatusId
		   ,COALESCE(PN.Title, '') AS Title
		   ,PN.IsDeleted
		   ,PN.NoteText
		   ,PN.CreateDate
		   ,PN.ModifiedDate
		   ,(CASE WHEN PN.CreatedUserName IS NOT NULL THEN PN.CreatedUserName
		   WHEN PN.CreatedUserName IS NULL AND PN.ModifiedUserName IS NOT NULL THEN PN.ModifiedUserName END) AS CreatedUserName
		   ,PN.ModifiedUserName
		   ,'U' AS NoteType
		   ,PSST.SequenceNumber
		   ,'U' AS [Source]

		FROM ProjectNote PN WITH (NOLOCK)
		INNER JOIN ProjectSegmentStatus PSST WITH(NOLOCK)
			ON PN.SegmentStatusId = PSST.SegmentStatusId
		LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK)
			ON PSST.SpecTypeTagId = STT.SpecTypeTagId

		WHERE PSST.ProjectId = @PProjectId AND PSST.SectionId = @PSectionId AND PN.SectionId = @PSectionId
		AND PN.IsDeleted = 0
		AND PN.ProjectId = @ProjectId
		AND (@PCatalogueType = 'FS'
		OR STT.TagType IN (SELECT TagType FROM @CatalogueTypeTbl)
		)) AS X
		ORDER BY SequenceNumber ASC, NoteId DESC

	DECLARE @imageNotes VARCHAR(MAX)
	SET @imageNotes = '';
		DECLARE @hlNotes VARCHAR(max)
	SET @hlNotes = '';

	--Gets all matched IMG notes
	SELECT
		@imageNotes = @imageNotes + COALESCE(TN.NoteText + ',', ' ')
	FROM #TempSectionNotes AS TN
	WHERE TN.NoteText LIKE '%{IMG%';

	--Gets all matched HL notes
	SELECT
		@hlNotes = @hlNotes + COALESCE(TN.NoteText + ',', ' ')
	FROM #TempSectionNotes AS TN
	WHERE TN.NoteText LIKE '%{HL%';

	--Gets all notes used in section
	SELECT * FROM #TempSectionNotes;

	--Gets all images used in notes
	--ImageId	ImagePath	LuImageSourceTypeId	CreateDate	ModifiedDate	PublicationDate
	DROP TABLE IF EXISTS #ImageTable;
	CREATE TABLE #ImageTable (
		ImageId INT
	   ,ImagePath NVARCHAR(MAX)
	   ,[Source] NVARCHAR(MAX)
	)

	-- Fetch Master Images 
	INSERT INTO #ImageTable
	SELECT
		ImageId AS ImageId
		,ImagePath AS ImagePath
		,'M' AS [Source]
	FROM SLCMaster..[Image] I WITH(NOLOCK)
	WHERE I.ImageId
	IN (SELECT DISTINCT CONVERT(INT, Ids) AS ImageId
		FROM dbo.fn_GetIdSegmentDescription(@imageNotes, @ImageFormat))

	INSERT INTO #ImageTable
		SELECT
			PPI.ImageId AS ImageId
		   ,ImagePath AS ImagePath
		   ,'U' AS [Source]
		FROM [ProjectImage] PPI WITH(NOLOCK)
		INNER JOIN [ProjectNoteImage] PNI WITH(NOLOCK)
			ON PPI.ImageId = PNI.ImageId
		WHERE PNI.ProjectId = @ProjectId AND PNI.SectionId = @PSectionId

	-- Fetch Master Images only if master section
	INSERT INTO #ImageTable
		SELECT
			I.ImageId AS ImageId
			,I.ImagePath AS ImagePath
			,'U' AS [Source]
		FROM SLCMaster..[Image] I WITH(NOLOCK)
		LEFT JOIN #ImageTable TIMG
			ON I.ImageId = TIMG.ImageId
				AND TIMG.[Source] = 'U'
		WHERE I.ImageId
		IN (SELECT DISTINCT CONVERT(INT, Ids) AS ImageId
			FROM dbo.fn_GetIdSegmentDescription(@imageNotes, @ImageFormat))
		AND TIMG.ImageId IS NULL

	SELECT * FROM #ImageTable;

	--Gets all hyper links used in notes
	--HyperLinkId	SectionId	SegmentId	SegmentStatusId	LinkTarget	LinkText	LuHyperLinkSourceTypeId	CreateDate	ModifiedDate

	DROP TABLE IF EXISTS #HyperLinkTable;
	CREATE TABLE #HyperLinkTable (
		HyperLinkId INT
	   ,HyperLinkCode INT
	   ,SegmentStatusId BIGINT
	   ,LinkTarget NVARCHAR(512)
	   ,LinkText NVARCHAR(MAX)
	   ,[Source] NVARCHAR(MAX)
	)

	-- Fetch Master HyperLinks only if master section
	IF(ISNULL(@mSectionId, 0) > 0)
	BEGIN
		INSERT INTO #HyperLinkTable
			SELECT
				ISNULL(HyperLinkId,0) AS HyperLinkId
				,0 AS HyperLinkCode
				,ISNULL(SegmentStatusId, 0) AS SegmentStatusId
				,COALESCE(LinkTarget,'') AS LinkTarget
				,COALESCE(LinkText,'') AS LinkText
				,'M' AS [Source]
			FROM SLCMaster..HyperLink HL WITH(NOLOCK)
			WHERE HL.SectionId = @mSectionId;
	END

	INSERT INTO #HyperLinkTable
		SELECT
			ISNULL(HL.HyperLinkId,0) AS HyperLinkId
		   ,ISNULL(HL.A_HyperLinkId,0) AS HyperLinkCode
		   ,ISNULL(HL.SegmentStatusId, 0) AS SegmentStatusId
		   ,COALESCE(LinkTarget,'') AS LinkTarget
		   ,COALESCE(LinkText,'') AS LinkText
		   ,'U' AS [Source]
		FROM ProjectHyperLink HL WITH(NOLOCK)
		WHERE HL.ProjectId = @ProjectId AND HL.SectionId = @SectionId;

	SELECT * FROM #HyperLinkTable;

	-- Drop temp tables after use
	DROP TABLE IF EXISTS #TempSectionNotes;
	DROP TABLE IF EXISTS #ImageTable;
	DROP TABLE IF EXISTS #HyperLinkTable;

END

-- EXEC usp_GetNotesDetails 10856, 9005780, NULL, 'FS'
GO


