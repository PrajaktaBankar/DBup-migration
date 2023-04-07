CREATE PROCEDURE [dbo].[usp_CreateNewSegment]      
@SectionId INT NULL, @ParentSegmentStatusId BIGINT NULL, @IndentLevel TINYINT NULL, @SpecTypeTagId INT NULL,     
@SegmentStatusTypeId INT NULL, @IsParentSegmentStatusActive BIT NULL, @ProjectId INT NULL, @CustomerId INT NULL,     
@CreatedBy INT NULL, @SegmentDescription NVARCHAR (MAX) NULL, @IsRefStdParagraph BIT NULL=0, @SequenceNumber DECIMAL (18) NULL=2      
AS      
BEGIN

DECLARE @PSectionId INT = @SectionId;
DECLARE @PParentSegmentStatusId BIGINT = @ParentSegmentStatusId;
DECLARE @PIndentLevel TINYINT = @IndentLevel;
DECLARE @PSpecTypeTagId INT = @SpecTypeTagId;
DECLARE @PSegmentStatusTypeId INT = @SegmentStatusTypeId;
DECLARE @PIsParentSegmentStatusActive BIT = @IsParentSegmentStatusActive;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PCreatedBy INT = @CreatedBy;
DECLARE @PSegmentDescription NVARCHAR (MAX) = @SegmentDescription;
DECLARE @PIsRefStdParagraph BIT = @IsRefStdParagraph;
DECLARE @PSequenceNumber DECIMAL (18) = @SequenceNumber;


INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId, IsShowAutoNumber, FormattingJson, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsRefStdParagraph)
	SELECT
		@PSectionId AS SectionId
	   ,@PParentSegmentStatusId
	   ,0 AS mSegmentStatusId
	   ,0 AS mSegmentId
	   ,0 AS SegmentId
	   ,'U' AS SegmentSource
	   ,'U' AS SegmentOrigin
	   ,@PIndentLevel AS IndentLevel
	   ,@PSequenceNumber AS SequenceNumber
	   ,(CASE
			WHEN @PSpecTypeTagId = 0 THEN NULL
			ELSE @PSpecTypeTagId
		END) AS SpecTypeTagId
	   ,@PSegmentStatusTypeId AS SegmentStatusTypeId
	   ,@PIsParentSegmentStatusActive AS IsParentSegmentStatusActive
	   ,@PProjectId AS ProjectId
	   ,@PCustomerId AS CustomerId
	   ,1 AS IsShowAutoNumber
	   ,NULL AS FormattingJson
	   ,GETUTCDATE() AS CreateDate
	   ,@PCreatedBy AS CreatedBy
	   ,NULL AS ModifiedDate
	   ,NULL AS ModifiedBy
	   ,@PIsRefStdParagraph AS IsRefStdParagraph;

DECLARE @SegmentStatusId AS BIGINT = SCOPE_IDENTITY();

INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription, SegmentSource, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)
	SELECT
		@SegmentStatusId AS SegmentStatusId
	   ,@PSectionId AS SectionId
	   ,@PProjectId AS ProjectId
	   ,@PCustomerId AS CustomerId
	   ,@PSegmentDescription AS SegmentDescription
	   ,'U' AS SegmentSource
	   ,@PCreatedBy AS CreatedBy
	   ,GETUTCDATE() AS CreateDate
	   ,NULL AS ModifiedDate
	   ,NULL AS ModifiedBy;

DECLARE @SegmentId AS BIGINT = SCOPE_IDENTITY();

UPDATE PSS
SET PSS.SegmentId = @SegmentId
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
WHERE PSS.SegmentStatusId = @SegmentStatusId;


DECLARE @SegmentStatusCode BIGINT, @SegmentCode BIGINT;
SELECT @SegmentStatusCode = PSS.SegmentStatusCode FROM ProjectSegmentStatus PSS WITH (NOLOCK) WHERE PSS.SegmentStatusId = @SegmentStatusId;
SELECT @SegmentCode = PS.SegmentCode FROM ProjectSegment PS WITH (NOLOCK) WHERE PS.SegmentId = @SegmentId

SELECT
	@SegmentStatusId AS SegmentStatusId
   ,@ParentSegmentStatusId AS ParentSegmentStatusId
   ,@SegmentId AS SegmentId
   ,@SegmentStatusCode AS SegmentStatusCode
   ,@SegmentCode AS SegmentCode;


--NOW CREATE SEGMENT REQUIREMENT TAG IF SEGMENT IS OF RS TYPE
IF ISNULL(@PIsRefStdParagraph, 0) = 1
	BEGIN
		EXEC usp_CreateSegmentRequirementTag @PCustomerId
											,@PProjectId
											,@PSectionId
											,@SegmentStatusId
											,'RS'
											,@PCreatedBy
		EXEC usp_CreateSpecialLinkForRsReTaggedSegment @PCustomerId
													  ,@PProjectId
													  ,@PSectionId
													  ,@SegmentStatusId
													  ,@PCreatedBy
--START- Added Block for Regression Bug 40872
DECLARE @RSCode INT = 0 , @RsSegmentDescription nvarchar(max)=@SegmentDescription,@PRefStandardId INT = 0 , @PRefStdCode INT = 0;    
		  
		  SELECT @RSCode = LEFT(Val, PATINDEX('%[^0-9]%', Val + 'a') - 1)     
		  FROM (SELECT SUBSTRING(@RsSegmentDescription, PATINDEX('%[0-9]%', @RsSegmentDescription), LEN(@RsSegmentDescription)) Val) RSCode

SELECT TOP 1 
@PRefStandardId = RefStdId,
@PRefStdCode = RefStdCode
FROM ReferenceStandard WITH (NOLOCK) WHERE RefStdCode=@RSCode AND CustomerId= @CustomerId

INSERT INTO ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource, mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, mSegmentId, RefStdCode)
	VALUES (@PSectionId, @SegmentId, @PRefStandardId, 'U', 0, GETUTCDATE(), @PCreatedBy, GETUTCDATE(), NULL, @PCustomerId, @PProjectId, null, @PRefStdCode)

--END Block

	END


END
GO


