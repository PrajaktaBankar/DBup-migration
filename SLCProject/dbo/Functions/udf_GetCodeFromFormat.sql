--User : SELECT dbo.udf_GetCodeFromFormat ('This are Global Terms {GT#10019654}{GT#10019174} {GT#10019173} ', 'GT#') AS GTCodes
CREATE FUNCTION [dbo].[udf_GetCodeFromFormat] (@desciptionString NVARCHAR(MAX), @format VARCHAR(10))  
 RETURNS NVARCHAR(MAX)  
 AS  
 BEGIN
	DECLARE @outputString NVARCHAR(MAX) = '0';

	DECLARE @output TABLE ([Ids] NVARCHAR (MAX) NULL)
	DECLARE @start AS INT, @end AS INT;  
    DECLARE @Offset AS INT = LEN(@format)  
    SELECT @start = CHARINDEX(@format, @desciptionString)  
	 SELECT @end = CHARINDEX('}', @desciptionString, @start);  
	 DECLARE @length AS INT = 0  
	WHILE @start < LEN(@desciptionString) and @start > 0  
		BEGIN  
			IF @end = 0  
				SET @end = LEN(@desciptionString) + 1;  
              
				INSERT  INTO @output (Ids) VALUES (SUBSTRING(@desciptionString, @start + @Offset, @end - @start - @Offset));  
     
				SET @start = @end   
     
				SET @start = CHARINDEX(@format, @desciptionString, @start);  
				SET @end = CHARINDEX('}', @desciptionString, @start);  
     
	END
	SELECT @outputString = STUFF((SELECT ',' + Ids FROM @output FOR XML PATH('')),1,1,'')
	RETURN @outputString;
END
