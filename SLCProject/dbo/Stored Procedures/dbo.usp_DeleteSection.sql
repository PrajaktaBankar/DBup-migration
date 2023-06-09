CREATE PROCEDURE [dbo].[usp_DeleteSection]  
(  
@ProjectId INT NULL,  
@CustomerId INT NULL,  
@SectionId INT = NULL,  
@UserId INT  
)  
AS  
BEGIN  
  
DECLARE @PprojectId INT = @ProjectId;  
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
  
IF ((@IsLocked = 1 OR @IsLockedImportSection = 1) and @LockedBy!=@PUserId)  
BEGIN  
SET @IsSuccess = 0;  
SET @StatusCode = 'LockedImportSection';  
-- Is Locked Section then give priority to this  
IF(@IsLocked = 1)  
SET @StatusCode = 'SectionLockedByUser';  
--SELECT @IsSuccess AS IsSuccess, @StatusCode AS StatusCode  
END  
ELSE  
BEGIN  
UPDATE PS  
SET PS.IsDeleted = 1  
from ProjectSection PS WITH (NOLOCK)  
WHERE PS.ProjectId = @PprojectId  
AND PS.SectionId = @PSectionId  
AND PS.CustomerId = @PCustomerId;  
  
UPDATE PSL  
SET PSL.IsDeleted = 1  
FROM ProjectSegmentLink PSL WITH (NOLOCK)  
INNER JOIN ProjectSection PS WITH (NOLOCK)  
ON PS.CustomerId = PSL.CustomerId  
AND PS.ProjectId = PSL.ProjectId  
AND (PS.SectionCode = PSL.SourceSectionCode  
OR PS.SectionCode = PSL.TargetSectionCode)  
WHERE PS.ProjectId = @PprojectId  
AND PS.SectionId = @PSectionId  
AND PS.CustomerId = @PCustomerId;  
  
SET @IsSuccess = 1;  
SET @StatusCode = 'SectionDeleted';  
END  
  
UPDATE DocLib 
SET DocLib.isDeleted = 1,
	DocLib.ModifiedBy = @PUserId,
	DocLib.ModifiedDate = GETUTCDATE()
FROM DocLibraryMapping DocLib WITH (NOLOCK)
WHERE DocLib.CustomerId = @PCustomerId 
AND DocLib.ProjectId = @PprojectId
AND DocLib.SectionId = @PSectionId

SELECT @IsSuccess AS IsSuccess, @StatusCode AS StatusCode;  
END