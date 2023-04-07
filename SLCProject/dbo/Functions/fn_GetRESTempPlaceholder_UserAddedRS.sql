
CREATE FUNCTION [dbo].[fn_GetRESTempPlaceholder_UserAddedRS](@Description NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
	--DECLARE @Description AS NVARCHAR(MAX) = '{RSTEMP#10004741}' --'{RSTEMP#10004741}'
	DECLARE @CONST_START_CODE AS INT = 1000000

	DECLARE @ID INT = 0
	, @I INT
	, @K INT
	, @tmp VARCHAR(20) = ''
	, @OldPlaceHolder VARCHAR(20) = ''
	, @ReplaceString NVARCHAR(50)
	, @SegmentText NVARCHAR(MAX) = @Description
	, @retString NVARCHAR(MAX) = ''
	, @OldChoice VARCHAR(50) = ''
	, @OldStringTAG NVARCHAR(10) = '{RSTEMP#'
	SET @OldChoice = REPLACE(@Description, '}', '')
	IF CHARINDEX(@OldChoice,@SegmentText) > 0
	BEGIN
		SELECT @I = CHARINDEX(@OldChoice,@SegmentText)
		SELECT @K = PATINDEX('%}%',SUBSTRING(@SegmentText, @I + 1, LEN(@SegmentText)))
		SELECT @OldPlaceHolder = SUBSTRING(@SegmentText, @I, @K + 1)
		SELECT @tmp = SUBSTRING(@SegmentText, @I, @K)
		SELECT @tmp = LTRIM(RTRIM(REPLACE(@tmp, @OldStringTAG, '')))
		IF ISNUMERIC(@tmp) = 1
			SELECT @ID = @tmp
		IF CONVERT(INT, REPLACE(@ID, CHAR(0), '')) > @CONST_START_CODE
		BEGIN
			SET @retString = CAST(@ID AS VARCHAR)
		END
	END
	IF @retString = ''
	BEGIN
		SET @retString = '0'
	END
	RETURN @retString
END