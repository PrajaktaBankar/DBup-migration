CREATE PROCEDURE [dbo].[usp_ModifyGlobalTermAsChoice]    
 @OptionListJson NVARCHAR(MAX),
 @CustomerId INT NULL,
 @ProjectId INT NULL,
 @SectionId INT NULL,
 @SegmentId BIGINT NULL,
 @UserId INT NULL
AS       
BEGIN
 DECLARE @POptionListJson NVARCHAR(MAX) = @OptionListJson;
 DECLARE @PCustomerId INT = @CustomerId;
 DECLARE @PProjectId INT = @ProjectId;
 DECLARE @PSectionId INT = @SectionId;
 DECLARE @PSegmentId BIGINT = @SegmentId;
 DECLARE @PUserId INT = @UserId;

  DECLARE @TempInpChoiceOptionTable TABLE(
  Id INT NULL,
  OptionTypeId INT NULL,  
  [Value] NVARCHAR(MAX) NULL,
  OptionTypeName  NVARCHAR(MAX) NULL
  );

INSERT INTO @TempInpChoiceOptionTable
	SELECT
		*
	FROM OPENJSON(@POptionListJson)
	WITH (
	Id INT '$.Id',
	OptionTypeId INT '$.OptionTypeId',
	[Value] NVARCHAR(MAX) '$.Value',
	OptionTypeName NVARCHAR(MAX) '$.OptionTypeName'
	);



SELECT
	UGT.Id
   ,UGT.OptionTypeId
   ,UGT.value
   ,UGT.OptionTypeName
   ,PGT.UserGlobalTermId INTO #TempGTList
FROM @TempInpChoiceOptionTable UGT
INNER JOIN ProjectGlobalTerm PGT WITH (NOLOCK)
	ON UGT.Id = PGT.GlobalTermCode

SELECT
	*
FROM #TempGTList

UPDATE PSGT
SET PSGT.IsDeleted = 1
	FROM ProjectSegmentGlobalTerm PSGT  WITH (NOLOCK)
	LEFT JOIN #TempGTList TGT
		ON PSGT.GlobalTermCode = TGT.Id
WHERE (PSGT.ProjectId = @PProjectId
	AND PSGT.SectionId = @PSectionId)
	AND PSGT.SegmentId = @PSegmentId
	AND TGT.Id IS NULL


INSERT INTO ProjectSegmentGlobalTerm
	SELECT DISTINCT
		@PCustomerId AS CustomerId
	   ,@PProjectId AS ProjectId
	   ,@PSectionId AS SectionId
	   ,@PSegmentId AS SegmentId
	   ,NULL AS mSegmentId
	   ,TUGT.UserGlobalTermId AS UserGlobalTermId
	   ,TUGT.Id AS GlobalTermCode
	   ,NULL AS IsLocked
	   ,NULL AS LockedByFullName
	   ,NULL AS UserLockedId
	   ,GETUTCDATE() AS CreatedDate
	   ,@PUserId AS CreatedBy
	   ,GETUTCDATE() AS ModifiedDate
	   ,NULL AS ModifiedBy
	FROM #TempGTList TUGT
	LEFT JOIN ProjectSegmentGlobalTerm PSGT WITH (NOLOCK)
		ON PSGT.GlobalTermCode = TUGT.Id
			AND @PProjectId = PSGT.ProjectId
			AND @PSegmentId = PSGT.SegmentId
			AND PSGT.IsDeleted = 0
	WHERE TUGT.OptionTypeName = 'GlobalTerm'
	AND @PProjectId = @PProjectId
	AND @PSectionId = @PSectionId
	AND PSGT.GlobalTermCode IS NULL
END
GO


