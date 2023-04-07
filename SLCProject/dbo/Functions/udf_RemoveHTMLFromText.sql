CREATE FUNCTION usf_RemoveHTMLFromText (@inputString nvarchar(max))
RETURNS nvarchar(MAX)
AS
BEGIN
  /*Variables to store source fielde temporarily and to remove tags one by one*/
  DECLARE @replaceHTML nvarchar(2000), @counter int, @outputString nvarchar(max)
  set @counter = 0
  SET @outputString = @inputString
  /*This was extra case which I've added later to remove no-break space*/
  SET @outputString = REPLACE(@outputString, '&nbsp;', '')
  /*This loop searches for tags beginning with "<" and ending with ">" */
  WHILE (CHARINDEX('<', @outputString,1)>0 AND CHARINDEX('>', @outputString,1)>0)
  BEGIN
    SET @counter = @counter + 1
    /*
    Some math here... looking for tags and taking substring storing result into temporarily variable, for example "</span>"
   */
   SELECT @replaceHTML = SUBSTRING(@outputString, CHARINDEX('<', @outputString,1), CHARINDEX('>',   @outputString,1)-CHARINDEX('<', @outputString,1)+1)
   /* Replace the tag that we stored in previous step */
   SET @outputString = REPLACE(@outputString, @replaceHTML, '')
   /* Let's clear our variable just in case... */
   SET @replaceHTML = ''
   /* Let's set up maximum number of tags just for fun breaking the loop after 15 tags */
  if @counter >15
      RETURN(@outputString);
  END
  RETURN(@outputString);
END