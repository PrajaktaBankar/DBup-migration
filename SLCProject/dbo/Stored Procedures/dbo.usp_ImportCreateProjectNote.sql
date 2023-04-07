CREATE PROCEDURE [dbo].[usp_ImportCreateProjectNote]      
@InpSegmentJson NVARCHAR(MAX) =''  
AS    
      
BEGIN
  
DECLARE @PInpSegmentJson NVARCHAR(MAX) = @InpSegmentJson;
    
 --DECLARE INP NOTE TABLE     
 DECLARE @InpNoteTableVar TABLE(      
 SectionId INT,  
 SegmentStatusId BIGINT NULL,    
 NoteText NVARCHAR(MAX) NULL,    
 Title  NVARCHAR(MAX) NULL,  
 ProjectId INT,    
 CustomerId INT DEFAULT 0,    
 CreatedBy INT DEFAULT 0,    
 CreatedUserName NVARCHAR(500) NULL,   
 NoteId INT DEFAULT 0    
 );
  
    
    
 --PUT FETCHED INP RESULT IN LOCAL TABLE VARIABLE     
IF @PInpSegmentJson != ''    
BEGIN
INSERT INTO @InpNoteTableVar
	SELECT
		*
	   ,0
	FROM OPENJSON(@PInpSegmentJson)
	WITH (
	SectionId INT '$.SectionId',
	SegmentStatusId BIGINT '$.SegmentStatusId',
	NoteText NVARCHAR(MAX) '$.NoteText',
	Title NVARCHAR(500) '$.Title',
	ProjectId INT '$.ProjectId',
	CustomerId NVARCHAR(MAX) '$.CustomerId',
	CreatedBy INT '$.CreatedBy',
	CreatedUserName NVARCHAR(500) '$.CreatedUserName'
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
, ModifiedBy
, CreatedUserName
, ModifiedUserName
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
	   ,CreatedBy
	   ,CreatedBy
	   ,CreatedUserName
	   ,CreatedUserName
	   ,0
	   ,0
	FROM @InpNoteTableVar

UPDATE INPT
SET INPT.NoteId = PN.NoteId
FROM ProjectNote PN WITH (NOLOCK)
INNER JOIN @InpNoteTableVar INPT
	ON PN.SegmentStatusId = INPT.SegmentStatusId
WHERE PN.SegmentStatusId = INPT.SegmentStatusId

SELECT
	PN.NoteId
   ,PN.SegmentStatusId
   ,COALESCE(PN.Title, '') AS Title
   ,PN.NoteText
   ,PN.CreateDate
   ,PN.ModifiedDate
   ,PN.CreatedUserName
   ,PN.ModifiedUserName
   ,'U' AS NoteType
   ,'U' AS Source

FROM @InpNoteTableVar INPT
INNER JOIN ProjectNote PN WITH (NOLOCK)
	ON INPT.SegmentStatusId = PN.SegmentStatusId
WHERE INPT.NoteId = PN.NoteId

END
GO


