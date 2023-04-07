CREATE FUNCTION [dbo].[fn_SplitString]
(@string NVARCHAR (MAX) NULL, @delimiter CHAR (1) NULL)
RETURNS 
    @output TABLE (
        [splitdata] NVARCHAR (MAX) NULL)
AS
BEGIN
    DECLARE @start AS INT, @end AS INT;
    SELECT @start = 1,
           @end = CHARINDEX(@delimiter, @string);
    WHILE @start < LEN(@string) + 1
        BEGIN
            IF @end = 0
                SET @end = LEN(@string) + 1;
            INSERT  INTO @output (splitdata)
            VALUES              (SUBSTRING(@string, @start, @end - @start));
            SET @start = @end + 1;
            SET @end = CHARINDEX(@delimiter, @string, @start);
        END
    RETURN;
END

