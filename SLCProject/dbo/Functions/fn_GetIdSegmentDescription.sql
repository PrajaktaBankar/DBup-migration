CREATE FUNCTION [dbo].[fn_GetIdSegmentDescription](@string NVARCHAR (MAX) NULL, @delimiter NVARCHAR (10) NULL)    
RETURNS     
    @output TABLE ([Ids] NVARCHAR (MAX) NULL)    
AS    
BEGIN    
    DECLARE @start AS INT, @end AS INT;    
 DECLARE @Offset AS INT = LEN(@delimiter)    
    SELECT @start = CHARINDEX(@delimiter, @string)    
 SELECT @end = CHARINDEX('}', @string, @start);    
 DECLARE @length AS INT = 0    
  WHILE @start < LEN(@string) and @start > 0    
        BEGIN    
            IF @end = 0    
                 SET @end = @end + 1;    
                
   INSERT  INTO @output (Ids) VALUES (SUBSTRING(@string, @start + @Offset, @end - @start - @Offset));    
       
   SET @start = @end     
       
            SET @start = CHARINDEX(@delimiter, @string, @start);    
            SET @end = CHARINDEX('}', @string, @start);    
       
        END    
    RETURN;    
END