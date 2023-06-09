CREATE Procedure [dbo].[usp_SaveLimitAccessProjectList]
(
@UserId INT,
@CustomerId INT,
@CreatedBy INT,
@ProjectIds NVARCHAR(max),
@RestrictedProjectIds NVARCHAR(max)
)
AS
BEGIN
	DECLARE @PUserId INT=@UserId,
			@PCreatedBy INT=@CreatedBy,
			@PCustomerId INT=@CustomerId,
			@PProjectIds NVARCHAR(max)=@ProjectIds,
			@PRestrictedProjectIds NVARCHAR(max)=@RestrictedProjectIds



	Create Table #LimitProjectAccess(ProjectId INT,IsActive BIT)

	IF(@PRestrictedProjectIds !='')
	BEGIN
		INSERT INTO #LimitProjectAccess (ProjectId,IsActive)    
		SELECT *,0 FROM dbo.fn_SplitString(@PRestrictedProjectIds, ','); 
	END

	IF(@PProjectIds  !='')
	BEGIN
		INSERT INTO #LimitProjectAccess (ProjectId,IsActive)    
		SELECT * ,1 FROM dbo.fn_SplitString(@ProjectIds, ','); 
	END

	UPDATE upam
	SET upam.IsActive=T.IsActive,
		upam.ModifiedBy=@CreatedBy,
		upam.ModifiedDate=GETUTCDATE()
	FROM UserProjectAccessMapping upam WITH(NOLOCK) INNER JOIN #LimitProjectAccess T WITH(NOLOCK)
	ON upam.ProjectId=T.ProjectId
	where upam.UserId=@UserId
	AND upam.CustomerId=@PCustomerId
		
	INSERT INTO UserProjectAccessMapping (ProjectId,UserId,CustomerId,CreatedBy,CreateDate,IsActive)
	SELECT t.ProjectId,@UserId,@PCustomerId,@CreatedBy,GETUTCDATE(),1 FROM #LimitProjectAccess t  WITH(NOLOCK)
	LEFT OUTER JOIN UserProjectAccessMapping upam WITH(NOLOCK)
	ON t.ProjectId=upam.ProjectId
	AND upam.UserId=@PUserId
	WHERE upam.ProjectId IS NULL

 END
 
 GO
 