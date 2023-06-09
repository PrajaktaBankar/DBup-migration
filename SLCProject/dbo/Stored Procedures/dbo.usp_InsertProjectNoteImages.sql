
CREATE PROCEDURE [dbo].[usp_InsertProjectNoteImages]    
@InpSegmentJson NVARCHAR(MAX)  
AS  
    
BEGIN
  
  DECLARE @PInpSegmentJson NVARCHAR(MAX) = @InpSegmentJson;
 --DECLARE INP SEGMENT TABLE   
 DECLARE @InpNoteImageTableVar TABLE(    
 SectionId INT,    
 NoteId INT,  
 ImageId INT,  
 ProjectId INT,  
 CustomerId INT DEFAULT 0  
 );
  
 
 --PUT FETCHED INP RESULT IN LOCAL TABLE VARIABLE   
IF @PInpSegmentJson != ''  
BEGIN
INSERT INTO @InpNoteImageTableVar
	SELECT
		*
	FROM OPENJSON(@PInpSegmentJson)
	WITH (
	SectionId INT '$.SectionId',
	NoteId INT '$.NoteId',
	ImageId INT '$.ImageId',
	ProjectId INT '$.ProjectId',
	CustomerId INT '$.CustomerId'

	);
END
INSERT INTO ProjectNoteImage (NoteId, SectionId, ImageId, ProjectId, CustomerId)
	SELECT
		NoteId
	   ,SectionId
	   ,ImageId
	   ,ProjectId
	   ,CustomerId
	FROM @InpNoteImageTableVar

SELECT
	PNI.*
FROM @InpNoteImageTableVar INPT
INNER JOIN ProjectNoteImage PNI WITH (NOLOCK)
	ON PNI.ProjectId = INPT.ProjectId AND PNI.SectionId = INPT.SectionId AND PNI.ImageId = INPT.ImageId
	AND INPT.NoteId = PNI.NoteId AND PNI.CustomerId = INPT.CustomerId

END
GO


