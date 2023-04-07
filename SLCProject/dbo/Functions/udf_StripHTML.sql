
CREATE FUNCTION [dbo].[udf_StripHTML] (@HTMLText VARCHAR(MAX))
RETURNS VARCHAR(MAX) AS
BEGIN
    DECLARE @Start INT
    DECLARE @End INT
    DECLARE @Length INT
	DECLARE @newstring VARCHAR(MAX)
	DECLARE @spanstring VARCHAR(MAX)
	DECLARE @fontremove VARCHAR(MAX)
	DECLARE @styletag VARCHAR(MAX)
	DECLARE @FontWeight VARCHAR(MAX)
    SET @Start = CHARINDEX('<p',@HTMLText)
    SET @End = CHARINDEX('>',@HTMLText,CHARINDEX('<p',@HTMLText))
    SET @Length = (@End - @Start) + 1
    WHILE @Start > 0 AND @End > 0 AND @Length > 0
    BEGIN
        SET @HTMLText = STUFF(@HTMLText,@Start,@Length,'')
        SET @Start = CHARINDEX('<p',@HTMLText)
        SET @End = CHARINDEX('>',@HTMLText,CHARINDEX('<p',@HTMLText))
        SET @Length = (@End - @Start) + 1
    END
   
   SET @newstring = LTRIM(RTRIM(@HTMLText))

	  SET @Start = CHARINDEX('</p',@newstring)
    SET @End = CHARINDEX('>',@newstring,CHARINDEX('</p',@newstring))
    SET @Length = (@End - @Start) + 1
    WHILE @Start > 0 AND @End > 0 AND @Length > 0
    BEGIN
        SET @newstring = STUFF(@newstring,@Start,@Length,'')
        SET @Start = CHARINDEX('</p',@newstring)
        SET @End = CHARINDEX('>',@newstring,CHARINDEX('</p',@newstring))
        SET @Length = (@End - @Start) + 1
    END
	
	SET @spanstring=LTRIM(RTRIM(@newstring))

	 SET @Start = CHARINDEX('font-family:''Times New Roman''',@spanstring)
    SET @End = CHARINDEX(';',@spanstring,CHARINDEX('font-family:''Times New Roman''',@spanstring))
    SET @Length = (@End - @Start) + 1
    WHILE @Start > 0 AND @End > 0 AND @Length > 0
    BEGIN
        SET @spanstring = STUFF(@spanstring,@Start,@Length,'')
        SET @Start = CHARINDEX('font-family:''Times New Roman''',@spanstring)
        SET @End = CHARINDEX(';',@spanstring,CHARINDEX('font-family:''Times New Roman''',@spanstring))
        SET @Length = (@End - @Start) + 1
    END

		SET @fontremove=LTRIM(RTRIM(@spanstring))

	 SET @Start = CHARINDEX('font-size:10pt',@fontremove)
    SET @End = CHARINDEX(';',@fontremove,CHARINDEX('font-size:10pt',@fontremove))
    SET @Length = (@End - @Start) + 1
    WHILE @Start > 0 AND @End > 0 AND @Length > 0
    BEGIN
        SET @fontremove = STUFF(@fontremove,@Start,@Length,'')
        SET @Start = CHARINDEX('font-size:10pt',@fontremove)
        SET @End = CHARINDEX(';',@fontremove,CHARINDEX('font-size:10pt',@fontremove))
        SET @Length = (@End - @Start) + 1
    END
	
	SET @FontWeight=LTRIM(RTRIM(@fontremove))
	 SET @Start = CHARINDEX('font-weight:bold',@FontWeight)
    SET @End = CHARINDEX(';',@fontremove,CHARINDEX('font-weight:bold;',@FontWeight))
    SET @Length = (@End - @Start) + 1
    WHILE @Start > 0 AND @End > 0 AND @Length > 0
    BEGIN
        SET @FontWeight = STUFF(@fontremove,@Start,@Length,'')
        SET @Start = CHARINDEX('font-size:10pt',@FontWeight)
        SET @End = CHARINDEX(';',@FontWeight,CHARINDEX('font-weight:bold;',@FontWeight))
        SET @Length = (@End - @Start) + 1
    END


	SET @styletag=LTRIM(RTRIM(@FontWeight))
	SET @styletag=REPLACE(@FontWeight, 'style=""', '');
	 RETURN LTRIM(RTRIM(@styletag))
END
