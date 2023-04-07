 
CREATE VIEW [dbo].[SegmentStatusLinkView]  
AS  
SELECT  
	PS.SectionId
	,PSST.ProjectId
	,PSST.CustomerId
	,PSST.SegmentStatusId
	,PSST.ParentSegmentStatusId
	,PSST.SegmentStatusCode
	,PSST.SegmentStatusTypeId
	,PSST.IsParentSegmentStatusActive
	,PSST.SegmentOrigin
	,PSST.SegmentSource
	,PSST.SequenceNumber
	,PSST.mSegmentStatusId
	,PSST.mSegmentId
	,PSST.SegmentId
	,PSST.IndentLevel
	,PSST.IsDeleted
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId AND PSST.ProjectId = PS.ProjectId

GO


