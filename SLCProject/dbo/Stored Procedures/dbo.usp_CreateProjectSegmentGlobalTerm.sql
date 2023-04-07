CREATE PROCEDURE [dbo].[usp_CreateProjectSegmentGlobalTerm]    
@CustomerId INT NULL,  
@ProjectId INT NULL,   
@SectionId INT NULL,  
@SegmentId BIGINT NULL,  
@mSegmentId INT NULL,  
@UserGlobalTermId INT NULL,   
@GlobalTermCode INT NULL,  
@CreatedBy INT NULL  
--@IsLocked BIT NULL,    
--@LockedByFullName NVARCHAR NULL,   
--@UserLockedId INT NULL,   
  
AS        
  
BEGIN
  
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PSegmentId BIGINT = @SegmentId;
DECLARE @PmSegmentId INT = @mSegmentId;
DECLARE @PUserGlobalTermId INT = @UserGlobalTermId;
DECLARE @PGlobalTermCode INT = @GlobalTermCode;
DECLARE @PCreatedBy INT = @CreatedBy;
SET NOCOUNT ON;
  
  
    DECLARE @ProjSegmentGlobalTermCount INT = NULL

SET @ProjSegmentGlobalTermCount = (SELECT DISTINCT
		UserGlobalTermId
	FROM ProjectSegmentGlobalTerm WITH (NOLOCK)
	WHERE SectionId = @PSectionId
	AND UserGlobalTermId = @PUserGlobalTermId
	AND (SegmentId = @PSegmentId
	OR mSegmentId = @PmSegmentId)
	AND CustomerId = @PCustomerId
	AND IsDeleted = 0)
  
  
    IF @PSegmentId = 0  
        BEGIN
SET @PSegmentId = NULL;
    
        END
  
    IF @PmSegmentId = 0  
        BEGIN
SET @PmSegmentId = NULL;
    
        END
    
  
 IF(@ProjSegmentGlobalTermCount IS NULL)  
   BEGIN
INSERT INTO ProjectSegmentGlobalTerm (CustomerId, ProjectId, SectionId, SegmentId, mSegmentId, UserGlobalTermId, GlobalTermCode, CreatedDate, CreatedBy)
	VALUES (@PCustomerId, @PProjectId, @PSectionId, @PSegmentId, @PmSegmentId, @PUserGlobalTermId, @PGlobalTermCode, GETUTCDATE(), @PCreatedBy)
END
ELSE
BEGIN
PRINT 'CAN NOT INSERT GT'
END

END
GO


