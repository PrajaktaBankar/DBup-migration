CREATE PROCEDURE [dbo].[usp_GetNotificationCount]
	@UserId int,
	@CustomerId int
AS
BEGIN
	DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())      

	DECLARE @RES AS Table(CopyProject INT,SpecApiSection INT,CreateSectionFromTemplate INT,UnArchiveProjectsCount INT)
	DECLARE @COUNT INT=0
	INSERT INTO @RES(CopyProject)
	SELECT COUNT(1) FROM CopyProjectRequest cp WITH(NOLOCK)
	WHERE cp.CreatedById=@UserId AND ISNULL(cp.IsDeleted,0)=0
	AND cp.StatusId IN(1,2)
	AND CP.CreatedDate> @DateBefore30Days   
	AND CP.CopyProjectTypeId=1


	SELECT @COUNT=COUNT(1) FROM ImportProjectRequest cp WITH(NOLOCK)
	WHERE cp.CreatedById=@UserId AND ISNULL(cp.IsDeleted,0)=0
	AND cp.StatusId IN(1,2) and Source='SpecAPI' --verify
	AND CP.CreatedDate> @DateBefore30Days   

	UPDATE @RES
	SET SpecApiSection=@COUNT

	SET @COUNT=0
	SELECT @COUNT=COUNT(1) FROM ImportProjectRequest cp WITH(NOLOCK)
	WHERE cp.CreatedById=@UserId AND ISNULL(cp.IsDeleted,0)=0
	AND cp.StatusId IN(1,2) and Source='Import from Template'
	AND CP.CreatedDate> @DateBefore30Days   

	UPDATE @RES
	SET CreateSectionFromTemplate=@COUNT

	SET @COUNT=0
	SELECT @COUNT=COUNT(1) FROM UnArchiveProjectRequest cp WITH(NOLOCK)
	WHERE cp.SLC_UserId=@UserId AND ISNULL(cp.IsDeleted,0)=0
	AND cp.StatusId IN(1,2)
	AND CP.RequestDate > @DateBefore30Days   

	UPDATE @RES
	SET UnArchiveProjectsCount=@COUNT

	SELECT * FROM @RES
END