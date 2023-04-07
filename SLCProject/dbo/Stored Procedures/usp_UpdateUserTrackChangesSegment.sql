CREATE PROCEDURE  [dbo].[usp_UpdateUserTrackChangesSegment]
(
@SectionId INT ,
@SegmentId  BIGINT ,
@ProjectId  INT ,
@CustomerId  INT ,
@ChangedById  INT , 
@AfterEdit  NVARCHAR(max) ,
@BeforEdit NVARCHAR(max)
)
AS
BEGIN
 
--declare @JsonString nvarchar(max)
--declare @IsPresent  bit=0;
--declare @IsPresentChangedBy int=0;

--SET @IsPresent = (SELECT
--		COUNT(1)
--	FROM TrackProjectSegment WITH (NOLOCK)
--	WHERE SegmentId = @SegmentId
--	AND SectionId = @SectionId
--	AND ProjectId = @ProjectId
--	AND CustomerId = @CustomerId)
	
--	IF(@IsPresent=1)
--	BEGIN
--SET @IsPresentChangedBy = (SELECT TOP 1
--		ChangedById
--	FROM TrackProjectSegment WITH (NOLOCK)
--	WHERE SegmentId = @SegmentId
--	AND SectionId = @SectionId
--	AND ProjectId = @ProjectId
--	AND CustomerId = @CustomerId
--	ORDER BY ChangedDate DESC)
--	END
	
--IF(( @IsPresent=0 OR @IsPresentChangedBy <> @ChangedById) AND (CHARINDEX('ct="', @AfterEdit) > 0 or CHARINDEX('ct="' , @BeforEdit) > 0))
--BEGIN
--INSERT INTO TrackProjectSegment (SectionId, SegmentId, ProjectId, CustomerId, BeforEdit, AfterEdit, CreateDate, ChangedDate, ChangedById)
--	VALUES (@SectionId, @SegmentId, @ProjectId, @CustomerId, @BeforEdit, @AfterEdit, GETUTCDATE(), GETUTCDATE(), @ChangedById)
--END
--IF (CHARINDEX('ct="', @AfterEdit) > 0
--	AND CHARINDEX('cid="', @AfterEdit) > 0)
--BEGIN

--UPDATE tp
--SET tp.AfterEdit = @AfterEdit
--   ,tp.IsDeleted = 0
--FROM TrackProjectSegment tp WITH (NOLOCK)
--WHERE tp.SectionId = @SectionId
--AND tp.SegmentId = @SegmentId
--AND tp.ChangedById = @ChangedById
--AND tp.ProjectId = @ProjectId
--AND tp.CustomerId = @CustomerId
--END
--ELSE
--BEGIN
--UPDATE tp
--SET tp.IsDeleted = 1
--FROM TrackProjectSegment tp WITH (NOLOCK)
--WHERE tp.SectionId = @SectionId
--AND tp.SegmentId = @SegmentId
--AND tp.ChangedById = @ChangedById
--AND tp.ProjectId = @ProjectId
--AND tp.CustomerId = @CustomerId
--AND ISNULL(tp.IsDeleted, 0) = 0
--END
select ProjectId FROM Project WITH(NOLOCK) where ProjectId=@ProjectId
END
GO


