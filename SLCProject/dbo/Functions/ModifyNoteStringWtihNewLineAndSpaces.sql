
CREATE FUNCTION [dbo].[ModifyNoteStringWtihNewLineAndSpaces]
(
    @NoteString nvarchar(MAX)
)
RETURNS varchar(MAX) 
AS
BEGIN
 IF CHARINDEX('<p',@NoteString) = 0
 BEGIN
    set @NoteString=  REPLACE(@NoteString,char(13)+char(10),'<br>')-- Replace with br tag
    set @NoteString = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@NoteString, ' ', '*^'), '^*', '&nbsp;'), '*^', ' '),'*',''),'^','') --replace spaces with &nbsp;
 END
 
   RETURN  @NoteString
END
