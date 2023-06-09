CREATE PROCEDURE [dbo].[usp_SetProjectSegemntNoteMappingData]   
(@ProjectId INT,    
@CustomerId INT,    
@segmentNoteMappingDataJson NVARCHAR(MAX)
)   
   
AS    
BEGIN
    
   
   IF(ISJSON(@segmentNoteMappingDataJson)>0)
	BEGIN

 DECLARE @SegmentMappingNoteTbl TABLE (    
 mSectionId INT,  
    NoteText NVARCHAR(2000),  
    Title NVARCHAR(2000),  
    mSegmentId INT,  
    mSegmentStatusId INT,  
 SectionId INT  
 )
    
    
	
 DECLARE @DistinctSectionTbl TABLE (SectionId INT)
INSERT INTO @SegmentMappingNoteTbl
	SELECT
		*
	FROM OPENJSON(@segmentNoteMappingDataJson)
	WITH (
	mSectionId INT '$.mSectionId',
	NoteText NVARCHAR(2000) '$.NoteText',
	Title NVARCHAR(2000) '$.Title',
	mSegmentId INT '$.mSegmentId',
	mSegmentStatusId INT '$.mSegmentStatusId',
	SectionId INT '$.SectionId'
	);

INSERT INTO ProjectNote (SectionId, SegmentStatusId, NoteText, CreateDate, ProjectId, CustomerId, Title, CreatedBy, IsDeleted)
	SELECT
		pss.SectionId
	   ,pss.SegmentStatusId
	   ,smnt.NoteText
	   ,GETUTCDATE()
	   ,pss.ProjectId
	   ,pss.CustomerId
	   ,smnt.Title
	   ,pss.CustomerId AS CreatedBy
	   ,0 AS IsDeleted
	FROM @SegmentMappingNoteTbl smnt
	INNER JOIN ProjectSegmentStatus pss WITH (NOLOCK)
		ON smnt.SectionId = pss.SectionId
			AND smnt.mSegmentId = pss.mSegmentId
			AND smnt.mSegmentStatusId = pss.mSegmentStatusId
	WHERE pss.ProjectId = @ProjectId
	AND pss.CustomerId = @CustomerId

END
END