CREATE PROCEDURE [dbo].[usp_LockedUnLockedUsersSection]
@ProjectId INT NULL, @CustomerId INT NULL, @UserId INT NULL=NULL, @SectionId INT NULL=NULL, @lastSectionId INT NULL=NULL, @UserName VARCHAR (50) NULL=NULL, @opr VARCHAR (2) NULL=NULL
AS
BEGIN
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PUserId INT = @UserId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PlastSectionId INT = @lastSectionId;
DECLARE @PUserName VARCHAR (50) = @UserName;
DECLARE @Popr VARCHAR (2) = @opr;

    IF (UPPER(@Popr) = 'US')
        BEGIN
UPDATE PS
SET IsLocked = 0
   ,LockedBy = 0
   ,LockedByFullName = ''
   FROM ProjectSection PS WITH (NOLOCK)
WHERE SectionId = @PSectionId
AND ProjectId = @PProjectId
AND CustomerId = @PCustomerId
AND IsLocked = 1;
END
IF (UPPER(@Popr) = 'AL')
BEGIN
SELECT
	SectionId
   ,ProjectId
   ,CustomerId
   ,UserId
   ,IsLocked
   ,LockedBy
FROM [projectSection] WITH (NOLOCK)
WHERE SectionId = @PSectionId
AND ProjectId = @PProjectId
AND CustomerId = @PCustomerId
AND IsLocked = 1
END
IF (UPPER(@Popr) = 'LL')
BEGIN
UPDATE PS
SET IsLocked = 1
   ,LockedBy = @PUserId
   ,LockedByFullName = @PUserName
   FROM ProjectSection PS WITH (NOLOCK)
WHERE SectionId = @PSectionId
AND ProjectId = @PProjectId
AND CustomerId = @PCustomerId
END
IF (UPPER(@Popr) = 'CL')
BEGIN
UPDATE PS
SET IsLocked = 1
   ,LockedBy = @PUserId
   ,LockedByFullName = @PUserName
   FROM ProjectSection PS WITH (NOLOCK)
WHERE SectionId = @PSectionId
AND ProjectId = @PProjectId
AND CustomerId = @PCustomerId

END
END

GO
