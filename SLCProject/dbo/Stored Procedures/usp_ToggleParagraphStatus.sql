
CREATE PROCEDURE [dbo].[usp_ToggleParagraphStatus]  
(  
  @CustomerId INT,
  @ProjectId INT,
  @SectionId INT,
  @UserId INT,
  @UserFullName NVARCHAR(100),
  @SegmentStatusId BIGINT,      
  @SegmentStatusTypeId INT,      
  @SegmentUserTypeId INT,      
  @IsTrackChangesEnabled BIT,      
  @isExcludeSegmentStatus BIT,      
  @isTitleParagraph BIT=0,    
  @EOSParagraphSegmentStatusId BIGINT=0,     
  @ChildParagraphDetails NVARCHAR(max)   
)  
AS  
BEGIN 

	CREATE TABLE #SegmentStatusBackUp(RowId int IDENTITY(1,1),SegmentStatusId BIGINT,SegmentStatusTypeId INT,IsParentSegmentStatusActive BIT,IsSegmentStatusChangeBySelection BIT)
	
	SELECT Distinct SegmentStatusId,IsParentSegmentStatusActive,SegmentStatusTypeId,HasNpNs into #t FROM OPENJSON(@ChildParagraphDetails)   
	WITH(  
	  SegmentStatusId BIGINT,  
	  IsParentSegmentStatusActive BIT,  
	  SegmentStatusTypeId BIGINT,  
	  HasNpNs BIT  
	 )  

	IF(@IsTrackChangesEnabled=1)
	BEGIN
		INSERT INTO #SegmentStatusBackUp
		SELECT SegmentStatusId,SegmentStatusTypeId,IsParentSegmentStatusActive,1
		FROM ProjectSegmentStatus pst WITH(NOLOCK)
		WHERE pst.SegmentStatusId=@segmentStatusId

		INSERT INTO #SegmentStatusBackUp
		SELECT pst.SegmentStatusId,pst.SegmentStatusTypeId,pst.IsParentSegmentStatusActive ,0
		FROM ProjectSegmentStatus pst WITH(NOLOCK)
		INNER JOIN #t t
		ON pst.SegmentStatusId=t.SegmentStatusId
		WHERE pst.ProjectId = @ProjectId AND pst.SectionId=@SectionId --and 
		--t.HasNpNs=1

		IF(@isTitleParagraph=1)
		BEGIN
			INSERT INTO #SegmentStatusBackUp
			SELECT SegmentStatusId,SegmentStatusTypeId,IsParentSegmentStatusActive,0 
			FROM ProjectSegmentStatus pst WITH(NOLOCK)
			WHERE pst.SegmentStatusId=@EOSParagraphSegmentStatusId
		END
	END   
	DECLARE @ParentSegmentStatusId BIGINT
	DECLARE @IsParentSegmentStatusActive BIT=0

	IF(@isTitleParagraph=0)
	BEGIN
		select top 1 @ParentSegmentStatusId=ParentSegmentStatusId from ProjectSegmentStatus WITH(NOLOCK) where SegmentStatusId=@SegmentStatusId
		select top 1 @IsParentSegmentStatusActive=IIF(SegmentStatusTypeId<6,1,0) from ProjectSegmentStatus WITH(NOLOCK) 
		where SegmentStatusId=@ParentSegmentStatusId and IsParentSegmentStatusActive=1
	END
	ELSE
	BEGIN
		SET @IsParentSegmentStatusActive=1
	END
	
	IF(@isExcludeSegmentStatus=1)  
	 BEGIN  
		  UPDATE psst   
		  SET psst.SegmentStatusTypeId=9  
		  ,psst.IsParentSegmentStatusActive=@IsParentSegmentStatusActive
		  FROM ProjectSegmentStatus psst WITH(NOLOCK)  
		  WHERE psst.SegmentStatusId=@SegmentStatusId  
	 END  
	 ELSE  
	 BEGIN  
		  
		  UPDATE psst   
		  SET psst.SegmentStatusTypeId=@SegmentStatusTypeId
		  ,psst.IsParentSegmentStatusActive=@IsParentSegmentStatusActive
		  FROM ProjectSegmentStatus psst WITH(NOLOCK)  
		  WHERE psst.SegmentStatusId=@SegmentStatusId  
	 END  
  
	--CHILDRENS (IsParentSegmentStatusActive)
	UPDATE psst   
	 SET psst.IsParentSegmentStatusActive=t.IsParentSegmentStatusActive  
	 FROM ProjectSegmentStatus psst WITH(NOLOCK)  inner join #t t  
	 ON t.SegmentStatusId=psst.SegmentStatusId  
	
	--NPNS (SegmentStatusTypeId)
	UPDATE psst   
	 SET psst.SegmentStatusTypeId=IIF(t.SegmentStatusTypeId<6,1,6)  
	 FROM ProjectSegmentStatus psst WITH(NOLOCK)  inner join #t t  
	 ON t.SegmentStatusId=psst.SegmentStatusId  
	 WHERE t.HasNpNs=1  
  
	--EOS (SegmentStatusTypeId)
	IF(@isTitleParagraph=1)
	BEGIN
	  UPDATE psst   
	  SET psst.SegmentStatusTypeId=IIF(@SegmentStatusTypeId<6,1,6)
	  FROM ProjectSegmentStatus psst WITH(NOLOCK)
	  WHERE psst.SegmentStatusId=@EOSParagraphSegmentStatusId  
	END
  
	IF(@IsTrackChangesEnabled=1)
	BEGIN
		exec usp_TrackSegmentStatusTypeLocal @CustomerId,@ProjectId,@SectionId,@UserId,@UserFullName
	END
	
	SELECT DISTINCT SegmentStatusId,SegmentStatusTypeId,IsParentSegmentStatusActive FROM ProjectSegmentStatus WITH(NOLOCK) WHERE SegmentStatusId=@segmentStatusId  

END
GO


