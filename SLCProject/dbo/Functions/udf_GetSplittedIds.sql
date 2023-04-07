--Usage : SELECT Id FROM dbo.[udf_GetSplittedIds]('2,3,4,5,6,7,8,42,10,11,26,27',',')
CREATE FUNCTION [dbo].[udf_GetSplittedIds](
	@Ids NVARCHAR(MAX),
	@Delimiter CHAR (1) NULL
)
RETURNS @SplittedIdTbl TABLE(Id BIGINT)
AS
BEGIN
	INSERT INTO @SplittedIdTbl
	SELECT [value] FROM String_Split(@Ids, @Delimiter);

	RETURN;
END
GO


