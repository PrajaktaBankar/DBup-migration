
CREATE PROC [dbo].[usp_ToggleSectionStatus]
(
	@CustomerId INT,
	@ProjectId INT,
	@SectionId INT,
	@UserStatusTypeId INT,
	@IsTrackChangesEnabled BIT,
	@IsExcludeSegmentStatus BIT,
	@UserId INT=0,
	@UserFullName NVARCHAR(100)=''
)
AS
BEGIN
	DECLARE @TRUE BIT=1
	DECLARE @FALSE BIT=0

	DECLARE @IsSegmentStatusActive BIT,@SegmentStatusTypeId INT
	DECLARE @SegmentStatusId BIGINT
	select top 1 @SegmentStatusId=SegmentStatusId FROM ProjectSegmentStatus pst WITH(NOLOCK)   
										WHERE pst.SectionId=@SectionId and pst.ProjectId=@ProjectId and 
										pst.SequenceNumber=0 and pst.CustomerId=@CustomerId 
										option (fast 1)
	
	DECLARE @mSectionId INT=(select isnull(mSectionId,0) FROM ProjectSection ps with(nolock) where sectionId=@SectionId)
	if(@mSectionId>1)
	BEGIN
		--MAP segment status
		exec usp_MapMasterDataToProjectForSection @projectId,@sectionId,@customerId,@userId,@mSectionId
	END
	--Update 0 sequence
	IF(@IsExcludeSegmentStatus=1)
	BEGIN
		UPDATE psst   
		SET psst.SegmentStatusTypeId=9  
		FROM ProjectSegmentStatus psst WITH(NOLOCK)  
		WHERE psst.SegmentStatusId=@SegmentStatusId  

		SET @IsSegmentStatusActive=@FALSE
		SET @SegmentStatusTypeId=9
		SET @UserStatusTypeId=4
	END
	ELSE
	BEGIN
		SET @UserStatusTypeId=IIF(@UserStatusTypeId=1,3,1)
		SET @SegmentStatusTypeId=IIF(@UserStatusTypeId=1,6,2)
		UPDATE psst   
		SET psst.SegmentStatusTypeId=@SegmentStatusTypeId
		FROM ProjectSegmentStatus psst WITH(NOLOCK)  
		WHERE psst.SegmentStatusId=@SegmentStatusId  

		SET @IsSegmentStatusActive=IIF(@SegmentStatusTypeId=2,@TRUE,@FALSE)
	END

	--CHILDRENS (IsParentSegmentStatusActive)
	SELECT SegmentStatusId,SequenceNumber INTO #Childrens
	FROM ProjectSegmentStatus pst WITH(NOLOCK)
	WHERE ParentSegmentStatusId=@SegmentStatusId

	UPDATE PST
	SET PST.IsParentSegmentStatusActive=@IsSegmentStatusActive
	FROM ProjectSegmentStatus pst WITH(NOLOCK)
	INNER JOIN #Childrens t
	ON pst.SegmentStatusId=t.SegmentStatusId
	
	--NPNS (SegmentStatusTypeId)
	SELECT DISTINCT SegmentStatusId into #npns 
	FROM ProjectSegmentRequirementTag WITH(NOLOCK) 
	WHERE ProjectId = @ProjectId AND SectionId=@SectionId and RequirementTagId in(2,3)

	UPDATE psst   
	SET psst.SegmentStatusTypeId=IIF(@IsSegmentStatusActive=1,1,6)  
	FROM ProjectSegmentStatus psst WITH(NOLOCK)  inner join #npns t  
	ON t.SegmentStatusId=psst.SegmentStatusId  

	--EOS (SegmentStatusTypeId)
	DECLARE @EOSParagraphSegmentStatusId BIGINT
	SELECT top 1 @EOSParagraphSegmentStatusId=SegmentStatusId FROM #Childrens
	order by SequenceNumber desc

	UPDATE psst   
	SET psst.SegmentStatusTypeId=IIF(@IsSegmentStatusActive=1,1,6)
	FROM ProjectSegmentStatus psst WITH(NOLOCK)
	WHERE psst.SegmentStatusId=@EOSParagraphSegmentStatusId  

	--Check wether any Siblings active	
	SELECT @SectionId as SectionId,@UserStatusTypeId as UserStatusTypeId,@SegmentStatusTypeId as SegmentStatusTypeId,
			@TRUE as IsParentSegmentStatusActive,@IsSegmentStatusActive as IsSegmentStatusActive
END
GO


