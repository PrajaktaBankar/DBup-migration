CREATE PROC [dbo].[usp_InsertSpecDataSegmentNotes]   
(@NoteDataString NVARCHAR(MAX) ='' )       
AS       
Begin
       
CREATE TABLE #InpNoteTableVar (              
 SectionId INT NULL,          
 SegmentStatusId BIGINT NULL,          
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
	NoteText NVARCHAR(MAX) '$.NoteText',
	Title NVARCHAR(500) '$.Title',
	ProjectId INT '$.ProjectId',
	CustomerId INT '$.CustomerId'
	);
END

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


