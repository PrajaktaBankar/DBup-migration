CREATE PROCEDURE [dbo].[usp_GetDeletedSectionSeqZero]
(  
@ProjectId INT NULL,  
@CustomerId INT NULL,  
@SectionId INT = NULL,
@UserId INT  
)  
AS  
BEGIN  
  
DECLARE @PProjectId INT = @ProjectId;  
DECLARE @PCustomerId INT = @CustomerId;  
DECLARE @PSectionId INT = @SectionId;  
DECLARE @PUserId INT = @UserId;  

DECLARE @IsSuccess BIT = 1;  
DECLARE @StatusCode NVARCHAR(20) = '';  
  
DECLARE @IsLocked BIT = 0;  
DECLARE @LockedBy INT = 0;  
DECLARE @LockedByFullName NVARCHAR(100) = 'N/A';  
DECLARE @IsLockedImportSection BIT = 0;  
  
SELECT TOP 1  
@IsLocked = PS.IsLocked,  
@LockedBy = PS.LockedBy,  
@LockedByFullName = PS.LockedByFullName,  
@IsLockedImportSection = PS.IsLockedImportSection  
FROM [ProjectSection] PS WITH (NOLOCK)  
WHERE PS.IsLastLevel = 1  
AND PS.IsLocked = 1  
AND PS.SectionId = @SectionId;  
  
IF ((@IsLocked = 1 OR @IsLockedImportSection = 1) and @LockedBy! = @PUserId)  
BEGIN  
	SET @IsSuccess = 0;  
	SET @StatusCode = 'LockedImportSection';  
	-- Is Locked Section then give priority to this  
	IF(@IsLocked = 1)
	BEGIN
		SET @StatusCode = 'SectionLockedByUser';  
	END
END  
ELSE  
BEGIN   
	SET @IsSuccess = 1;  
	SET @StatusCode = 'SectionDeleted';  
END 

SELECT 
PSS.SegmentStatusId, 
PSS.SegmentSource, 
PSS.SegmentStatusCode,
PSS.SegmentStatusTypeId
FROM ProjectSegmentStatus PSS
WHERE PSS.CustomerId = @PCustomerId 
AND PSS.ProjectId = @PProjectId 
AND PSS.SectionId = @PSectionId 
AND ISNULL(PSS.IndentLevel, 0) = 0 
AND ISNULL(PSS.ParentSegmentStatusId, 0) = 0 
AND ISNULL(PSS.SequenceNumber, 0) = 0 
AND ISNULL(PSS.IsDeleted, 0) = 0 ORDER BY PSS.SequenceNumber ASC

SELECT @IsSuccess AS IsSuccess, @StatusCode AS StatusCode;  

END
