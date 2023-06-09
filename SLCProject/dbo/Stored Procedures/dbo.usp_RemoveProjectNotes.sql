
CREATE PROCEDURE [dbo].[usp_RemoveProjectNotes]    

@noteid INT

AS    
BEGIN
DECLARE @Pnoteid INT = @noteid;
DECLARE @PProjectId INT;
DECLARE @PSectionId INT;

SELECT @PProjectId = ProjectId, @PSectionId = SectionId FROM ProjectNote WITH (NOLOCK) WHERE NoteId = @Pnoteid;

DELETE FROM ProjectNoteImage
WHERE ProjectId = @PProjectId AND SectionId = @PSectionId AND NoteId = @Pnoteid;

UPDATE PN SET PN.IsDeleted=1 FROM ProjectNote PN
WHERE NoteId = @Pnoteid;

SELECT  
 COUNT(1) AS 'isdeleted'  
FROM ProjectNote  PN WITH (NOLOCK)  
WHERE PN.NoteId = @Pnoteid and PN.IsDeleted=0   
END
GO

