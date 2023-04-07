CREATE PROCEDURE [dbo].[usp_GlobalTermAutoSaveDetails]  
(   
 @ProjectId INT NULL,  
 @SectionId INT NULL,  
 @CustomerId INT NULL,  
 @UserId INT NULL,  
 @SegmentId BIGINT NULL,  
 @MSegmentId INT NULL,  
 @SegmentDescription NVARCHAR(MAX) NULL  
)  
AS             
BEGIN
  
 DECLARE @PProjectId INT = @ProjectId;
 DECLARE @PSectionId INT = @SectionId;
 DECLARE @PCustomerId INT = @CustomerId;
 DECLARE @PUserId INT = @UserId;
 DECLARE @PSegmentId BIGINT = @SegmentId;
 DECLARE @PMSegmentId INT = @MSegmentId;
 DECLARE @PSegmentDescription NVARCHAR(MAX) = @SegmentDescription;

 DECLARE @SegmentGT TABLE(GlobalTermCode INT NULL);
  
  
 DECLARE @UserSegmentGT TABLE(   CustomerId INT NULL,   ProjectId INT NULL,   SectionId INT NULL,   SegmentId BIGINT NULL,   mSegmentId INT NULL,   UserGlobalTermId INT NULL,   GlobalTermCode INT NULL,   IsLocked BIT NULL,   LockedByFullName INT NULL,   UserLockedId INT NULL,   CreatedDate DATETIME NULL,   CreatedBy INT NULL,    ModifiedDate DATETIME NULL,   ModifiedBy INT NULL  
 );

INSERT INTO @SegmentGT
	SELECT DISTINCT
		[value] AS GlobalTermCode
	FROM STRING_SPLIT(dbo.[udf_GetCodeFromFormat](@PSegmentDescription, '{GT#'), ',')

INSERT INTO @UserSegmentGT
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
	FROM @SegmentGT SGT
	LEFT JOIN ProjectGlobalTerm PGT  WITH (NOLOCK)
		ON PGT.GlobalTermCode = SGT.GlobalTermCode
	WHERE PGT.ProjectId = @PProjectId
	AND PGT.GlobalTermSource = 'U'

--Delete Unsed GT for Segment  
--SELECT *  
UPDATE PSGT
SET PSGT.IsDeleted = 1
FROM ProjectSegmentGlobalTerm PSGT  WITH (NOLOCK)
LEFT JOIN @UserSegmentGT UGT
	ON PSGT.GlobalTermCode = UGT.GlobalTermCode
WHERE (PSGT.ProjectId = @PProjectId
AND PSGT.SectionId = @PSectionId)
AND (PSGT.SegmentId = @PSegmentId
OR PSGT.mSegmentId = @PMSegmentId)
AND UGT.GlobalTermCode IS NULL

--Insert Used GT for Segment  
INSERT INTO ProjectSegmentGlobalTerm (CustomerId, ProjectId, SectionId, SegmentId, mSegmentId, UserGlobalTermId, GlobalTermCode, IsLocked, LockedByFullName, UserLockedId, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted)
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
	   ,0
	FROM @UserSegmentGT UGT
	LEFT JOIN ProjectSegmentGlobalTerm PSGT  WITH (NOLOCK)
		ON PSGT.GlobalTermCode = UGT.GlobalTermCode
			AND UGT.ProjectId = PSGT.ProjectId
			AND (UGT.mSegmentId = PSGT.mSegmentId
				OR UGT.SegmentId = PSGT.SegmentId)
				AND PSGT.IsDeleted = 0
	WHERE UGT.ProjectId = @PProjectId
	AND UGT.SectionId = @PSectionId
	AND PSGT.GlobalTermCode IS NULL
END
GO


