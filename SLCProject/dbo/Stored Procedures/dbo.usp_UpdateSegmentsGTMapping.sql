
CREATE PROCEDURE [dbo].[usp_UpdateSegmentsGTMapping]  
(  
 @SegmentStatusId BIGINT NULL = 0,  
 @IsDeleted INT NULL = 0,  
 @ProjectId INT = NULL,  
 @SectionId INT = NULL,  
 @CustomerId INT = NULL,  
 @UserId INT = NULL,  
 @SegmentId BIGINT = NULL,  
 @MSegmentId INT = NULL,  
 @SegmentDescription NVARCHAR(MAX) = NULL  
)  
AS  
BEGIN
  
 DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId;
 DECLARE @PIsDeleted INT = @IsDeleted;
 DECLARE @PProjectId INT = @ProjectId;
 DECLARE @PSectionId INT = @SectionId;
 DECLARE @PCustomerId INT = @CustomerId;
 DECLARE @PUserId INT = @UserId;
 DECLARE @PSegmentId BIGINT = @SegmentId;
 DECLARE @PMSegmentId INT = @MSegmentId;
 DECLARE @PSegmentDescription NVARCHAR(MAX) = @SegmentDescription;

SET NOCOUNT ON;
  
 CREATE TABLE #SegmentGT (GlobalTermCode INT NULL);
  
 CREATE TABLE #UserSegmentGT (  
  CustomerId INT NULL,  
  ProjectId INT NULL,  
  SectionId INT NULL,  
  SegmentId BIGINT NULL,  
  mSegmentId INT NULL,  
  UserGlobalTermId INT NULL,  
  GlobalTermCode INT NULL,  
  IsLocked BIT NULL,  
  LockedByFullName INT NULL,  
  UserLockedId INT NULL,  
  CreatedDate DATETIME NULL,  
  CreatedBy INT NULL,   
  ModifiedDate DATETIME NULL,  
  ModifiedBy INT NULL  
 );
  
  
 IF @PIsDeleted = 1 AND @PSegmentStatusId > 0 -- Only proceed if SegmentStatusId is not zero  
 BEGIN
SET @PSegmentDescription = '';
SELECT
	@PProjectId = ProjectId
   ,@PSectionId = SectionId
   ,@PCustomerId = CustomerId
   ,@PUserId = 0
   ,@PSegmentId = SegmentId
   ,@PMSegmentId = MSegmentId
FROM ProjectSegmentStatus WITH (NOLOCK)
WHERE SegmentStatusId = @PSegmentStatusId
END

BEGIN TRY
INSERT INTO #SegmentGT
	SELECT
		*
	FROM (SELECT
			[value] AS GlobalTermCode
		FROM STRING_SPLIT(dbo.[udf_GetCodeFromFormat](@PSegmentDescription, '{GT#'), ',')
		UNION ALL
		SELECT
			*
		FROM dbo.[udf_GetGTUsedInChoice](@PSegmentDescription, @PProjectId, @PSectionId)) AS SegmentGTTbl
END TRY
	BEGIN CATCH
		insert into BsdLogging..AutoSaveLogging
		values('usp_UpdateSegmentsGTMapping',
		getdate(),
		ERROR_MESSAGE(),
		ERROR_NUMBER(),
		ERROR_Severity(),
		ERROR_LINE(),
		ERROR_STATE(),
		ERROR_PROCEDURE(),
		concat('SELECT dbo.[udf_GetCodeFromFormat](''',@PSegmentDescription,''',''{GT#'')'),
		@PSegmentDescription
	)
	END CATCH
--Use below variable to find global terms which are USER CREATED by checking GlobalTermCode column
DECLARE @MinUserGlobalTermCode INT = 10000000;

--Calculate count of user global terms which came from UI segment description
DECLARE @GlobalTermsCount_UI INT = (SELECT
		COUNT(1)
	FROM #SegmentGT
	WHERE GlobalTermCode > @MinUserGlobalTermCode);

--Calculate count of user global terms which are in mapping table for that segment in DB
DECLARE @GlobalTermsCount_MPTBL INT = (SELECT
		COUNT(1)
	FROM ProjectSegmentGlobalTerm WITH (NOLOCK)
	WHERE ProjectId = @ProjectId AND SectionId = @SectionId AND SegmentId = @PSegmentId
	AND GlobalTermCode > @MinUserGlobalTermCode);

--Call below logic if data is available in either UI segment's description or in mapping table
IF (@GlobalTermsCount_UI > 0
	OR @GlobalTermsCount_MPTBL > 0)
BEGIN
INSERT INTO #UserSegmentGT
	SELECT
		@PCustomerId AS CustomerId
	   ,@PProjectId AS ProjectId
	   ,@PSectionId AS SectionId
	   ,@PSegmentId AS SegmentId
	   ,@PMSegmentId AS mSegmentId
	   ,PGT.UserGlobalTermId AS UserGlobalTermId
	   ,PGT.GlobalTermCode AS GlobalTermCode
	   ,NULL AS IsLocked
	   ,NULL AS LockedByFullName
	   ,NULL AS UserLockedId
	   ,GETUTCDATE() AS CreatedDate
	   ,@PUserId AS CreatedBy
	   ,NULL AS ModifiedDate
	   ,NULL AS ModifiedBy
	FROM #SegmentGT SGT
	LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK)
		ON PGT.GlobalTermCode = SGT.GlobalTermCode
		AND PGT.ProjectId = @PProjectId
	WHERE PGT.ProjectId = @PProjectId
	AND PGT.GlobalTermSource = 'U'
	AND ISNULL(PGT.IsDeleted,0) = 0

--Delete Unsed GT for Segment  
UPDATE PSGT
SET PSGT.IsDeleted = 1
	FROM ProjectSegmentGlobalTerm PSGT  WITH (NOLOCK)
	LEFT JOIN #UserSegmentGT UGT WITH (NOLOCK)
		ON PSGT.ProjectId = UGT.ProjectId
		AND PSGT.GlobalTermCode = UGT.GlobalTermCode
WHERE PSGT.ProjectId = @PProjectId
	AND PSGT.SectionId = @PSectionId
	-- AND PSGT.SegmentId = @PSegmentId   
	AND (PSGT.SegmentId = @PSegmentId
	OR PSGT.mSegmentId = @PMSegmentId
	OR PSGT.SegmentId = 0)
	AND ISNULL(PSGT.IsDeleted,0) = 0

IF @PIsDeleted = 0--Only proceed if IsDeleted is zero  
BEGIN
--Insert Used GT for Segment  
--Insert Used GT for Segment    
INSERT INTO ProjectSegmentGlobalTerm (CustomerId
, ProjectId
, SectionId
, SegmentId
, mSegmentId
, UserGlobalTermId
, GlobalTermCode
, IsLocked
, LockedByFullName
, UserLockedId
, CreatedDate
, CreatedBy
, ModifiedDate
, ModifiedBy)
	SELECT
		UGT.CustomerId
	   ,UGT.ProjectId
	   ,UGT.SectionId
	   ,UGT.SegmentId
	   ,UGT.mSegmentId
	   ,UGT.UserGlobalTermId
	   ,UGT.GlobalTermCode
	   ,UGT.IsLocked
	   ,UGT.LockedByFullName
	   ,UGT.UserLockedId
	   ,UGT.CreatedDate
	   ,UGT.CreatedBy
	   ,UGT.ModifiedDate
	   ,UGT.ModifiedBy
	FROM #UserSegmentGT UGT WITH (NOLOCK)
	WHERE UGT.ProjectId = @PProjectId
	AND UGT.SectionId = @PSectionId
END
END
END
GO


