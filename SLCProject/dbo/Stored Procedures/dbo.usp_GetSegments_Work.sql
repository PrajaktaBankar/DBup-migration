CREATE PROCEDURE [dbo].[usp_GetSegments_Work]        
@ProjectId INT NULL, @SectionId INT NULL, @CustomerId INT NULL, @UserId INT NULL, @CatalogueType NVARCHAR (50) NULL='FS'        
AS        
BEGIN
SET NOCOUNT ON;

--Set mSectionId
DECLARE @MasterSectionId AS INT;
SET @MasterSectionId = (SELECT TOP 1
		mSectionId
	FROM ProjectSection WITH (NOLOCK)
	WHERE SectionId = @SectionId
	AND ProjectId = @ProjectId
	AND CustomerId = @CustomerId);
          
--FIND TEMPLATE ID FROM 
DECLARE @ProjectTemplateId AS INT = ( SELECT TOP 1
		ISNULL(TemplateId, 1)
	FROM Project WITH (NOLOCK)
	WHERE ProjectId = @ProjectId
	AND CustomerId = @CustomerId);

DECLARE @SectionTemplateId AS INT = (SELECT TOP 1
		TemplateId
	FROM ProjectSection WITH (NOLOCK)
	WHERE SectionId = @SectionId);

DECLARE @DocumentTemplateId INT = 0;

IF (@SectionTemplateId IS NOT NULL
	AND @SectionTemplateId > 0)
BEGIN
SET @DocumentTemplateId = @SectionTemplateId;
END
ELSE
BEGIN
SET @DocumentTemplateId = @ProjectTemplateId;
END
  
 DECLARE @MasterDataTypeId INT;
SET @MasterDataTypeId = (SELECT TOP 1
		MasterDataTypeId
	FROM Project
	WHERE ProjectId = @ProjectId
	AND CustomerId = @CustomerId);

EXECUTE usp_MapSegmentStatusFromMasterToProject @ProjectId = @ProjectId
															  ,@SectionId = @SectionId
															  ,@CustomerId = @CustomerId
															  ,@UserId = @UserId;
EXECUTE usp_MapSegmentChoiceFromMasterToProject @ProjectId = @ProjectId
															  ,@SectionId = @SectionId
															  ,@CustomerId = @CustomerId
															  ,@UserId = @UserId;
EXECUTE usp_MapProjectRefStands @ProjectId = @ProjectId
											  ,@SectionId = @SectionId
											  ,@CustomerId = @CustomerId
											  ,@UserId = @UserId;

EXECUTE usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @ProjectId
																	  ,@SectionId = @SectionId
																	  ,@CustomerId = @CustomerId
																	  ,@UserId = @UserId;
EXECUTE usp_MapSegmentLinkFromMasterToProject @ProjectId = @ProjectId
															,@SectionId = @SectionId
															,@CustomerId = @CustomerId
															,@UserId = @UserId;

SELECT
	PSS.SegmentStatusId
   ,PSS.SectionId
   ,PSS.ParentSegmentStatusId
   ,ISNULL(PSS.mSegmentStatusId, 0) AS mSegmentStatusId
   ,ISNULL(PSS.mSegmentId, 0) AS mSegmentId
   ,ISNULL(PSS.SegmentId, 0) AS SegmentId
   ,PSS.SegmentSource
   ,PSS.SegmentOrigin
   ,PSS.IndentLevel
   ,PSS.SequenceNumber
   ,PSS.SegmentStatusTypeId
   ,PSS.SegmentStatusCode
   ,PSS.IsParentSegmentStatusActive
   ,PSS.IsShowAutoNumber
   ,PSS.FormattingJson
   ,STT.TagType
   ,CASE
		WHEN PSS.SpecTypeTagId IS NULL THEN 0
		ELSE PSS.SpecTypeTagId
	END AS SpecTypeTagId
   ,PSS.IsRefStdParagraph
   ,PSS.IsPageBreak
   ,MSST.SpecTypeTagId AS MasterSpecTypeTagId
   ,CASE
		WHEN MSST.SegmentStatusId IS NOT NULL AND
			MSST.SpecTypeTagId = PSS.SpecTypeTagId THEN CAST(1 AS BIT)
		ELSE CAST(0 AS BIT)
	END AS IsMasterSpecTypeTag INTO #tmp_ProjectSegmentStatus
FROM ProjectSegmentStatus AS PSS WITH (NOLOCK)
LEFT JOIN SLCMaster..SegmentStatus MSST
	ON PSS.mSegmentStatusId = MSST.SegmentStatusId
LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK)
	ON PSS.SpecTypeTagId = STT.SpecTypeTagId
WHERE PSS.SectionId = @SectionId
AND PSS.ProjectId = @ProjectId
AND PSS.CustomerId = @CustomerId
AND ISNULL(PSS.IsDeleted, 0) = 0
AND (@CatalogueType = 'FS'
OR STT.TagType IN (SELECT
		*
	FROM fn_SplitString(@CatalogueType, ','))
)

SELECT
	*
FROM #tmp_ProjectSegmentStatus
ORDER BY SequenceNumber;

--SELECT* FROM (
SELECT
		PSG.SegmentId
	   ,PSST.SegmentStatusId
	   ,PSG.SectionId
	   ,ISNULL(PSG.SegmentDescription, '') AS SegmentDescription
	   ,PSG.SegmentSource
	   ,PSG.SegmentCode
	--FROM dbo.ProjectSegmentStatus AS PSST WITH (NOLOCK)
	 FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)
	INNER JOIN ProjectSegment AS PSG WITH (NOLOCK)
		ON PSST.SegmentId = PSG.SegmentId
		AND PSST.SectionId = PSG.SectionId
		 AND PSG.CustomerId= @CustomerId 
		
		--AND PSST.ProjectId = PSG.ProjectId
		--AND PSST.CustomerId = PSG.CustomerId
	WHERE
	-- PSST.ProjectId = @ProjectId 
	--AND PSST.CustomerId = @CustomerId AND
	 PSST.SectionId = @SectionId
	 AND PSG.ProjectId=@ProjectId
	UNION ALL
	SELECT
		MSG.SegmentId
	   ,PST.SegmentStatusId
	   ,PST.SectionId
	   ,CASE
			WHEN PST.ParentSegmentStatusId = 0 AND
				PST.SequenceNumber = 0 THEN PS.Description
			ELSE ISNULL(MSG.SegmentDescription, '')
		END AS SegmentDescription
	   ,MSG.SegmentSource
	   ,MSG.SegmentCode
	--FROM dbo.ProjectSegmentStatus AS PST WITH (NOLOCK)
	FROM #tmp_ProjectSegmentStatus AS PST WITH (NOLOCK)
	INNER JOIN ProjectSection AS PS WITH (NOLOCK)
		ON PST.SectionId = PS.SectionId
	INNER JOIN SLCMaster.dbo.Segment AS MSG WITH (NOLOCK)
		ON PST.mSegmentId = MSG.SegmentId
		WHERE PS.SectionId=@SectionId
	--WHERE PST.ProjectId = @ProjectId
	--AND PST.CustomerId = @CustomerId
	--AND PST.SectionId = @SectionId
	--) AS X

SELECT
	TemplateId
   ,Name
   ,TitleFormatId
   ,SequenceNumbering
   ,IsSystem
   ,IsDeleted
   ,ISNULL(@ProjectTemplateId, 0) AS ProjectTemplateId
   ,ISNULL(@SectionTemplateId, 0) AS SectionTemplateId
FROM Template WITH (NOLOCK)
WHERE TemplateId = @DocumentTemplateId;

SELECT
	TemplateStyleId
   ,TemplateId
   ,StyleId
   ,Level
FROM TemplateStyle WITH (NOLOCK)
WHERE TemplateId = @DocumentTemplateId;

SELECT
	ST.StyleId
   ,ST.Alignment
   ,ST.IsBold
   ,ST.CharAfterNumber
   ,ST.CharBeforeNumber
   ,ST.FontName
   ,ST.FontSize
   ,ST.HangingIndent
   ,ST.IncludePrevious
   ,ST.IsItalic
   ,ST.LeftIndent
   ,ST.NumberFormat
   ,ST.NumberPosition
   ,ST.PrintUpperCase
   ,ST.ShowNumber
   ,ST.StartAt
   ,ST.Strikeout
   ,ST.Name
   ,ST.TopDistance
   ,ST.Underline
   ,ST.SpaceBelowParagraph
   ,ST.IsSystem
   ,ST.IsDeleted
   ,CAST(TST.Level AS INT) AS Level
FROM Style AS ST WITH (NOLOCK)
INNER JOIN TemplateStyle AS TST WITH (NOLOCK)
	ON ST.StyleId = TST.StyleId
WHERE TST.TemplateId = @DocumentTemplateId;

--NOTE -- Need to fetch distinct SelectedChoiceOption records
SELECT DISTINCT
	SCHOP.SegmentChoiceCode
   ,SCHOP.ChoiceOptionCode
   ,SCHOP.ChoiceOptionSource
   ,SCHOP.IsSelected
   ,SCHOP.ProjectId
   ,SCHOP.SectionId
   ,SCHOP.CustomerId
   ,0 AS SelectedChoiceOptionId
   ,SCHOP.OptionJson INTO #SelectedChoiceOptionTemp
FROM SelectedChoiceOption SCHOP WITH (NOLOCK)
WHERE SCHOP.ProjectId = @ProjectId
AND SCHOP.SectionId = @SectionId
AND SCHOP.CustomerId = @CustomerId
AND SCHOP.IsDeleted = 0

--FETCH MASTER + USER CHOICES AND THEIR OPTIONS  
SELECT
	0 AS SegmentId
   ,MCH.SegmentId AS mSegmentId
   ,MCH.ChoiceTypeId
   ,'M' AS ChoiceSource
   ,ISNULL(MCH.SegmentChoiceCode, 0) AS SegmentChoiceCode
   ,ISNULL(MCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode
   ,PSCHOP.IsSelected
   ,PSCHOP.ChoiceOptionSource
   ,CASE
		WHEN PSCHOP.IsSelected = 1 AND
			PSCHOP.OptionJson IS NOT NULL THEN PSCHOP.OptionJson
		ELSE MCHOP.OptionJson
	END AS OptionJson
   ,MCHOP.SortOrder
   ,MCH.SegmentChoiceId
   ,MCHOP.ChoiceOptionId
   ,PSCHOP.SelectedChoiceOptionId
--FROM ProjectSegmentStatus PSST WITH (NOLOCK)
FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN SLCMaster..SegmentChoice MCH
	ON PSST.mSegmentId = MCH.SegmentId
INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)
	ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId
INNER JOIN #SelectedChoiceOptionTemp PSCHOP
	ON MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode
		AND PSCHOP.ChoiceOptionSource = 'M'
		AND PSCHOP.ProjectId = @ProjectId
		AND PSCHOP.SectionId = @SectionId
WHERE
-- PSST.ProjectId = @ProjectId AND
 PSST.SectionId = @SectionId
--AND PSST.CustomerId = @CustomerId
--AND PSST.IsDeleted = 0
UNION ALL
SELECT
	PCH.SegmentId
   ,0 AS mSegmentId
   ,PCH.ChoiceTypeId
   ,PCH.SegmentChoiceSource AS ChoiceSource
   ,ISNULL(PCH.SegmentChoiceCode, 0) AS SegmentChoiceCode
   ,ISNULL(PCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode
   ,PSCHOP.IsSelected
   ,PSCHOP.ChoiceOptionSource
   ,PCHOP.OptionJson
   ,PCHOP.SortOrder
   ,PCH.SegmentChoiceId
   ,PCHOP.ChoiceOptionId
   ,PSCHOP.SelectedChoiceOptionId
FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)
--FROM ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
	ON PSST.SegmentId = PCH.SegmentId
		AND PCH.IsDeleted = 0
INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)
	ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId
		AND PCHOP.IsDeleted = 0
INNER JOIN #SelectedChoiceOptionTemp PSCHOP WITH (NOLOCK)
	ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode
		AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode
		AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource
		AND PSCHOP.ProjectId = @ProjectId
		AND PSCHOP.SectionId = @SectionId
		AND PSCHOP.ChoiceOptionSource = 'U'

WHERE PSST.SectionId = @SectionId
--AND  PSST.ProjectId = @ProjectId
--AND PSST.CustomerId = @CustomerId
--AND PSST.IsDeleted = 0

SELECT
	GlobalTermId
   ,COALESCE(mGlobalTermId, 0) AS mGlobalTermId
	--  ProjectId,        
	-- CustomerId,       
   ,Name
   ,Value
   ,CreatedDate
   ,CreatedBy
   ,ModifiedDate
   ,ModifiedBy
   ,GlobalTermSource
   ,GlobalTermCode
   ,COALESCE(UserGlobalTermId, 0) AS UserGlobalTermId
FROM ProjectGlobalTerm WITH (NOLOCK)
WHERE ProjectId = @ProjectId
AND CustomerId = @CustomerId;

DECLARE @SourceTagFromat NVARCHAR(256)='',@IsPrintReferenceEditionDate BIT=0

SELECT TOP 1 @SourceTagFromat=PS.SourceTagFormat,@IsPrintReferenceEditionDate=ISNULL(IsPrintReferenceEditionDate, 0)  FROM ProjectSummary as ps Where ps.ProjectId=@ProjectId AND 
ps.CustomerId=@CustomerId
 
SELECT
	S.Description
   ,S.Author
   ,S.SectionCode
   ,S.SourceTag
   ,@SourceTagFromat AS SourceTagFormat
   ,S.mSectionId
   ,S.SectionId
   ,S.IsDeleted
FROM ProjectSection AS S WITH (NOLOCK)
--INNER JOIN ProjectSummary PS WITH (NOLOCK)
--	ON S.ProjectId = PS.ProjectId
--		AND S.CustomerId = PS.CustomerId
WHERE S.ProjectId = @ProjectId
AND S.CustomerId = @CustomerId
UNION
SELECT
	MS.Description
   ,MS.Author
   ,MS.SectionCode
   ,MS.SourceTag
   ,@SourceTagFromat AS SourceTagFormat
   ,MS.SectionId AS mSectionId
   ,0 AS SectionId
   ,MS.IsDeleted
FROM SLCMaster..Section MS
--INNER JOIN ProjectSummary P
--	ON P.ProjectId = @ProjectId
--		AND P.CustomerId = @CustomerId
LEFT JOIN ProjectSection PS
	ON MS.SectionId = PS.mSectionId
		AND PS.ProjectId = @ProjectId
		AND PS.CustomerId = @CustomerId
WHERE MS.MasterDataTypeId = @MasterDataTypeId
AND MS.IsLastLevel = 1
AND PS.SectionId IS NULL;

--FETCH SEGMENT REQUIREMENT TAGS LIST
SELECT
	PSRT.SegmentStatusId
   ,PSRT.SegmentRequirementTagId
   ,Temp.mSegmentStatusId
   ,LPRT.RequirementTagId
   ,LPRT.TagType
   ,LPRT.Description AS TagName
   ,CASE
		WHEN PSRT.mSegmentRequirementTagId IS NULL THEN CAST(0 AS BIT)
		ELSE CAST(1 AS BIT)
	END AS IsMasterRequirementTag
FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)
INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)
	ON PSRT.RequirementTagId = LPRT.RequirementTagId
INNER JOIN #tmp_ProjectSegmentStatus AS Temp
	ON PSRT.SegmentStatusId = Temp.SegmentStatusId
WHERE PSRT.ProjectId = @ProjectId
AND PSRT.SectionId = @SectionId
AND PSRT.CustomerId = @CustomerId


--FETCH REQUIRED IMAGES FROM DB  
SELECT
	IMG.ImageId
   ,IMG.ImagePath
FROM ProjectSegmentImage PIMG
INNER JOIN ProjectImage IMG WITH (NOLOCK)
	ON PIMG.ImageId = IMG.ImageId
WHERE PIMG.SectionId = @SectionId
AND IMG.LuImageSourceTypeId = 1

--FETCH HYPERLINKS FROM PROJECT DB
SELECT
	HLNK.HyperLinkId
   ,HLNK.LinkTarget
   ,HLNK.LinkText
   ,'U' AS Source
FROM ProjectHyperLink HLNK WITH (NOLOCK)
WHERE HLNK.ProjectId = @ProjectId
AND HLNK.SectionId = @SectionId

--FETCH SEGMENT USER TAGS LIST
SELECT
	PSUT.SegmentUserTagId
   ,PSUT.SegmentStatusId
   ,PSUT.UserTagId
   ,PUT.TagType
   ,PUT.Description AS TagName
FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)
INNER JOIN ProjectUserTag PUT WITH (NOLOCK)
	ON PSUT.UserTagId = PUT.UserTagId
WHERE PSUT.ProjectId = @ProjectId
AND PSUT.SectionId = @SectionId
AND PSUT.CustomerId = @CustomerId

SELECT @IsPrintReferenceEditionDate AS IsPrintReferenceEditionDate
--SELECT
--	ISNULL(IsPrintReferenceEditionDate, 0) AS IsPrintReferenceEditionDate
--FROM ProjectSummary
--WHERE ProjectId = @ProjectId

END
GO
