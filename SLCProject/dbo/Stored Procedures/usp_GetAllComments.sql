CREATE PROCEDURE [dbo].[usp_GetAllComments]
(
	@ProjectId INT,
	@SectionId INT,
	@CustomerId INT,
	@UserId INT,
	@CommentStatusId INT,
	@CommentUserList NVARCHAR(1024) = ''
)
AS
BEGIN  
    
	DECLARE @PProjectId INT = @ProjectId, @PSectionId INT = @SectionId, @PCustomerId INT = @CustomerId;  
	DECLARE @PUserId INT = @UserId, @PCommentStatusId INT = @CommentStatusId;  
  
	DECLARE @COMMENT_USER_TBL AS TABLE(USERID INT);
	INSERT INTO @COMMENT_USER_TBL VALUES (@PUserId);
        
	CREATE TABLE #TempSegmentCommentTbl(SegmentCommentId INT,        
		ProjectId INT ,        
		SectionId INT ,        
		SegmentStatusId  BIGINT,        
		ParentCommentId INT,        
		CommentDescription  NVARCHAR(MAX),        
		CustomerId  INT,        
		CreatedBy INT,        
		CreateDate DATETIME2,        
		ModifiedBy INT,        
		ModifiedDate DATETIME2,        
		CommentStatusId  INT,        
		IsDeleted BIT,        
		UserFullName nvarchar(200),      
		CommentStatusDescription NVARCHAR(MAX)        
	)

	-- Insert all comments and replies into temp table
	 INSERT INTO #TempSegmentCommentTbl          
	 SELECT            
	   SG.SegmentCommentId            
	  ,SG.ProjectId            
	  ,SG.SectionId            
	  ,SG.SegmentStatusId            
	  ,SG.ParentCommentId            
	  ,SG.CommentDescription            
	  ,SG.CustomerId            
	  ,SG.CreatedBy            
	  ,SG.CreateDate            
	  ,SG.ModifiedBy            
	  ,SG.ModifiedDate            
	  ,SG.CommentStatusId            
	  ,SG.IsDeleted            
	  ,SG.UserFullName            
	  ,IIF(SG.CommentStatusId = 1, 'UnResolved', 'Resolved') AS CommentStatusDescription           
	  --,CS.[Description] AS CommentStatusDescription          
	 FROM SegmentComment SG WITH (NOLOCK)        
	 --INNER JOIN LuCommentStatus CS WITH (NOLOCK) ON T.CommentStatusId = CS.CommentStatusId        
	 INNER JOIN ProjectSegmentStatus PS WITH (NOLOCK)        
	 ON PS.SegmentStatusId = SG.SegmentStatusId        
	 WHERE SG.SectionId = @PSectionId            
	  AND SG.ProjectId = @PProjectId            
	  AND SG.CustomerId = @PCustomerId          
	  AND ISNULL(SG.IsDeleted, 0) = 0        
	  AND ISNULL(PS.IsDeleted, 0) = 0;
  
	-- Select Only Parent Comments
	SELECT  
	    SegmentCommentId  
	   ,ProjectId  
	   ,SectionId  
	   ,SegmentStatusId  
	   ,ParentCommentId  
	   ,CommentDescription  
	   ,CustomerId  
	   ,CreatedBy  
	   ,CreateDate  
	   ,ModifiedBy  
	   ,ModifiedDate  
	   ,CommentStatusId  
	   ,IsDeleted  
	   ,UserFullName  
	   ,CommentStatusDescription  
	   ,CASE WHEN ModifiedDate > CreateDate THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END AS IsEdited
	FROM #TempSegmentCommentTbl WITH (NOLOCK)
	WHERE ParentCommentId = 0
	ORDER BY CreateDate DESC;
  
	-- Select Only Reply Comments
	SELECT  
		SC.SegmentCommentId  
	   ,SC.ProjectId  
	   ,SC.SectionId  
	   ,SC.SegmentStatusId  
	   ,SC.ParentCommentId  
	   ,SC.CommentDescription  
	   ,SC.CustomerId  
	   ,SC.CreatedBy  
	   ,SC.CreateDate  
	   ,SC.ModifiedBy  
	   ,SC.ModifiedDate  
	   ,SC.CommentStatusId  
	   ,SC.IsDeleted  
	   ,SC.UserFullName  
	   ,IIF(SC.CommentStatusId = 1, 'UnResolve', 'Resolved') AS CommentStatusDescription  
	   ,CASE WHEN ModifiedDate > CreateDate THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END AS IsEdited
	FROM #TempSegmentCommentTbl SC WITH (NOLOCK)
	WHERE ISNULL(SC.ParentCommentId, 0) <> 0
	ORDER BY CreateDate DESC;

END  

--EXEC [usp_GetAllCommentsPrasad] 8814, 8911299, 641, 19911, 0, ''
GO


