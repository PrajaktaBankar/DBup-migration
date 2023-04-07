USE SLCProject
GO

DECLARE @ProjectId INT = 4041;

--FIND MISSING ProjectSegmentChoice Entries
INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId,
SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted)
	SELECT DISTINCT
		PSST.SectionId AS SectionId
	   ,PSST.SegmentStatusId AS SegmentStatusId
	   ,PSST.SegmentId AS SegmentId
	   ,CH.ChoiceTypeId AS ChoiceTypeId
	   ,PSST.ProjectId AS ProjectId
	   ,PSST.CustomerId AS CustomerId
	   ,'U' AS SegmentChoiceSource
	   ,CH.SegmentChoiceCode AS SegmentChoiceCode
	   ,0 AS CreatedBy
	   ,GETUTCDATE() AS CreateDate
	   ,0 AS ModifiedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,0 AS IsDeleted
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN SLCMaster..SegmentChoice CH WITH (NOLOCK)
		ON PSST.mSegmentId = CH.SegmentId
	LEFT JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
		ON PSST.SegmentId = PCH.SegmentId
			AND CH.SegmentChoiceCode = PCH.SegmentChoiceCode
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.SegmentSource = 'M'
	AND PSST.SegmentOrigin = 'U'
	AND PCH.SegmentChoiceId IS NULL

--FIND MISSING ProjectChoiceOption Entries
INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId,
CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted)
	SELECT
	DISTINCT
		PCH.SegmentChoiceId AS SegmentChoiceId
	   ,CHOP.SortOrder AS SortOrder
	   ,'U' AS ChoiceOptionSource
	   ,CHOP.OptionJson AS OptionJson
	   ,PSST.ProjectId AS ProjectId
	   ,PSST.SectionId AS SectionId
	   ,PSST.CustomerId AS CustomerId
	   ,CHOP.ChoiceOptionCode AS ChoiceOptionCode
	   ,0 AS CreatedBy
	   ,GETUTCDATE() AS CreateDate
	   ,0 AS ModifiedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,ISNULL(PCH.IsDeleted, 0) AS IsDeleted
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN SLCMaster..SegmentChoice CH WITH (NOLOCK)
		ON PSST.mSegmentId = CH.SegmentId
	INNER JOIN SLCMaster..ChoiceOption CHOP WITH (NOLOCK)
		ON CH.SegmentChoiceId = CHOP.SegmentChoiceId
	INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
		ON PSST.SegmentId = PCH.SegmentId
			AND CH.SegmentChoiceCode = PCH.SegmentChoiceCode
	LEFT JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)
		ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId
			AND CHOP.ChoiceOptionCode = PCHOP.ChoiceOptionCode
			AND ISNULL(PCH.IsDeleted, 0) = ISNULL(PCHOP.IsDeleted, 0)
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.SegmentSource = 'M'
	AND PSST.SegmentOrigin = 'U'
	AND PCHOP.ChoiceOptionId IS NULL

--FIND MISSING SelectedChoiceOption Entries
INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected,
SectionId, ProjectId, CustomerId, IsDeleted)
	SELECT DISTINCT
		CH.SegmentChoiceCode AS SegmentChoiceCode
	   ,CHOP.ChoiceOptionCode AS ChoiceOptionCode
	   ,'U' AS ChoiceOptionSource
	   ,SCHOP.IsSelected AS IsSelected
	   ,PSST.SectionId AS SectionId
	   ,PSST.ProjectId AS ProjectId
	   ,PSST.CustomerId AS CustomerId
	   ,ISNULL(SCHOP.IsDeleted, 0) AS IsDeleted
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN SLCMaster..SegmentChoice CH WITH (NOLOCK)
		ON PSST.mSegmentId = CH.SegmentId
	INNER JOIN SLCMaster..ChoiceOption CHOP WITH (NOLOCK)
		ON CH.SegmentChoiceId = CHOP.SegmentChoiceId
	INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
		ON PSST.SegmentId = PCH.SegmentId
			AND CH.SegmentChoiceCode = PCH.SegmentChoiceCode
	INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)
		ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId
			AND CHOP.ChoiceOptionCode = PCHOP.ChoiceOptionCode
			AND ISNULL(PCH.IsDeleted, 0) = ISNULL(PCHOP.IsDeleted, 0)
	INNER JOIN SelectedChoiceOption SCHOP WITH (NOLOCK)
		ON PSST.SectionId = SCHOP.SectionId
			AND CH.SegmentChoiceCode = SCHOP.SegmentChoiceCode
			AND CHOP.ChoiceOptionCode = SCHOP.ChoiceOptionCode
			AND SCHOP.ChoiceOptionSource = 'M'
			AND ISNULL(PCHOP.IsDeleted, 0) = ISNULL(SCHOP.IsDeleted, 0)
	LEFT JOIN SelectedChoiceOption PSCHOP WITH (NOLOCK)
		ON PSST.SectionId = PSCHOP.SectionId
			AND CH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode
			AND CHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode
			AND PSCHOP.ChoiceOptionSource = 'U'
			AND ISNULL(SCHOP.IsDeleted, 0) = ISNULL(PSCHOP.IsDeleted, 0)
	WHERE PSST.ProjectId = @ProjectId
	AND PSST.SegmentSource = 'M'
	AND PSST.SegmentOrigin = 'U'
	AND PSCHOP.SelectedChoiceOptionId IS NULL