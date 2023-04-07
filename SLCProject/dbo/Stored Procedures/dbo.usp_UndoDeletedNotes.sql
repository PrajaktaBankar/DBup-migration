
CREATE PROCEDURE [dbo].[usp_UndoDeletedNotes]    
(    
 @PreviousSegmentStatusId BIGINT,    
 @CurrentSegmentStatusId BIGINT    
)    
AS    
BEGIN  
 DECLARE @PPreviousSegmentStatusId BIGINT = @PreviousSegmentStatusId;  
 DECLARE @PCurrentSegmentStatusId BIGINT = @CurrentSegmentStatusId;  
--BEGIN TRANSACTION  
--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
--SET DEADLOCK_PRIORITY LOW  
DECLARE @ProjectId AS INT, @SectionId AS INT

SELECT @ProjectId = ProjectId, @SectionId = SectionId FROM ProjectSegmentStatus WITH (NOLOCK) WHERE SegmentStatusId = @PCurrentSegmentStatusId

IF EXISTS (select top 1 noteid from ProjectNote with(nolock) WHERE SectionId = @SectionId AND ProjectId = @ProjectId AND SegmentStatusId = @PPreviousSegmentStatusId  )
BEGIN
		UPDATE pn  
	SET pn.SegmentStatusId = @PCurrentSegmentStatusId  
	   ,pn.IsDeleted = 0  
	   from ProjectNote pn with(nolock)  
	WHERE pn.SectionId = @SectionId AND pn.ProjectId = @ProjectId AND pn.SegmentStatusId = @PPreviousSegmentStatusId  
END
--COMMIT TRANSACTION  
END
GO
