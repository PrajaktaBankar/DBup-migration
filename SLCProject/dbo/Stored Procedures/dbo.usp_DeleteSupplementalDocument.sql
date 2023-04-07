﻿CREATE PROCEDURE [dbo].[usp_DeleteSupplementalDocument] (
	@UserId int,
	@DocMappingId int,
	@SectionId int,
	@ProjectId int, 
	@UserFullName nvarchar(500)
)
AS
BEGIN
DECLARE @PUserId int = @UserId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PUserFullName nvarchar(500) = @UserFullName;
DECLARE @PDocMappingId int = @DocMappingId;
DECLARE @PIsDeleted bit = 1;

UPDATE DocLibraryMapping 
SET IsDeleted = @PIsDeleted, 
	ModifiedBy = @PUserId, 
	ModifiedDate = GETUTCDATE()
WHERE DocMappingId = @PDocMappingId

--Update Last accessed date of Section
UPDATE [ProjectSection] SET ModifiedBy = @PUserId, ModifiedDate = GETUTCDATE() WHERE SectionId = @PSectionId;

--Update Last accessed date of Project

UPDATE UF
SET UF.LastAccessed = GETUTCDATE(), UF.UserId = @PUserId
   ,UF.LastAccessByFullName = @PUserFullName
FROM UserFolder UF WITH (NOLOCK)
WHERE UF.ProjectId = @PProjectId

END