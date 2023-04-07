CREATE PROC [dbo].[usp_SaveSpecDataProjectNote]
(@NoteDataString NVARCHAR(MAX) ='' )       
AS       
Begin
       
CREATE TABLE #InpNoteTableVar (              
 SectionId INT NULL,          
 SegmentStatusId BIGINT NULL,          
 --MSectionId INT NULL,          
 --MSegmentStatusId INT NULL,        
 NoteText NVARCHAR(MAX) NULL,            
 Title  NVARCHAR(500) NULL,          
 ProjectId INT NULL,       
 CustomerId INT NULL  
     
 );
        
      
 IF @NoteDataString != ''            
BEGIN
INSERT INTO #InpNoteTableVar
	SELECT
		*
	FROM OPENJSON(@NoteDataString)
	WITH (
	SectionId INT '$.SectionId',
	SegmentStatusId BIGINT '$.SegmentStatusId',
	--MSectionId INT '$.MSectionId',        
	--MSegmentStatusId INT '$.MSegmentStatusId',        
	NoteText NVARCHAR(MAX) '$.NoteText',
	Title NVARCHAR(500) '$.Title',
	ProjectId INT '$.ProjectId',
	CustomerId INT '$.CustomerId'
	);
END
SET STATISTICS IO ON

SELECT DISTINCT
	ProjectId
   ,0 AS SectionId
   ,CustomerId
   ,SectionId AS mSectionId INTO #SectionTBL
FROM #InpNoteTableVar

UPDATE stb
SET stb.SectionId = ps.SectionId
FROM #SectionTBL stb
INNER JOIN ProjectSection ps WITH(NOLOCK)
	ON ps.mSectionId = stb.mSectionId
	AND stb.ProjectId = ps.ProjectId
	AND stb.CustomerId = ps.CustomerId

UPDATE NTV
SET NTV.SegmentStatusId = PSS.SegmentStatusId
   ,NTV.SectionId = PSS.SectionId
FROM #SectionTBL stb
INNER JOIN ProjectSegmentStatus PSS WITH (NOLOCK)
	ON stb.SectionId = PSS.SectionId
	AND stb.ProjectId = PSS.ProjectId
	AND stb.CustomerId = PSS.CustomerId
INNER JOIN #InpNoteTableVar NTV
	ON PSS.mSegmentStatusId = NTV.SegmentStatusId
	AND PSS.ProjectId = NTV.ProjectId
	AND PSS.CustomerId = NTV.CustomerId

INSERT INTO ProjectNote (SectionId
, SegmentStatusId
, NoteText
, CreateDate
, ModifiedDate
, ProjectId
, CustomerId
, Title
, CreatedBy
, IsDeleted
, A_NoteId)

	SELECT
		SectionId
	   ,SegmentStatusId
	   ,NoteText
	   ,GETUTCDATE()
	   ,GETUTCDATE()
	   ,ProjectId
	   ,CustomerId
	   ,Title
	   ,CustomerId
	   ,0
	   ,0
	FROM #InpNoteTableVar


END
GO


