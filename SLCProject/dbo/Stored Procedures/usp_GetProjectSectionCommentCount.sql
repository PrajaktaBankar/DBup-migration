CREATE PROCEDURE [dbo].[usp_GetProjectSectionCommentCount]                                       
  @ProjectId INT       
AS                                          
BEGIN

  DECLARE @PProjectId INT = @ProjectId;       
  DECLARE @PCommentStatusId INT = 1; -- (CommentstatusId  1 means OpenComment and 2 means ResolvedComments)      
  DECLARE @ParentCommentId INT = 0;


 	SELECT SC.SectionId        
 	INTO #TempSectionIdTbl        
 	FROM SegmentComment AS SC WITH(NOLOCK)        
 	JOIN ProjectSegmentStatus PS WITH (NOLOCK)      
 	ON PS.SegmentStatusId = SC.SegmentStatusId      
 	WHERE SC.ProjectId = @PProjectId AND SC.CommentStatusId = @PCommentStatusId        
 	AND SC.ParentCommentId=@ParentCommentId AND ISNULL(SC.IsDeleted, 0) = 0      
 	AND ISNULL(PS.IsDeleted, 0) = 0;

	SELECT SC.SectionId, COUNT(SC.SectionId) AS CommentCount
	FROM #TempSectionIdTbl AS SC WITH(NOLOCK)
	GROUP BY SC.SectionId;
                                                        
END