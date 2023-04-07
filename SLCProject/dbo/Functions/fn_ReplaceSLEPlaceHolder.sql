
CREATE FUNCTION [dbo].[fn_ReplaceSLEPlaceHolder](@Description NVARCHAR(MAX),@OldStringTAG NVARCHAR(10),@NewStringTAG NVARCHAR(10),@OldID INT,@NewID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @ID INT = 0
	, @I INT
	, @K INT
	, @tmp VARCHAR(20) = ''
	, @OldPlaceHolder VARCHAR(20) = ''
	, @ReplaceString NVARCHAR(50)
	, @SegmentText NVARCHAR(MAX) = @Description
	, @retString NVARCHAR(MAX) = ''
	, @OldChoice VARCHAR(20) = ''

	SET @OldChoice = @OldStringTAG + CAST(@OldID AS NVARCHAR)
	IF CHARINDEX(@OldChoice,@SegmentText) > 0
	BEGIN
		SELECT @I = CHARINDEX(@OldChoice,@SegmentText)
		SELECT @K = PATINDEX('%}%',SUBSTRING(@SegmentText, @I + 1, LEN(@SegmentText)))
		SELECT @OldPlaceHolder = SUBSTRING(@SegmentText, @I, @K + 1)
		SELECT @tmp = SUBSTRING(@SegmentText, @I, @K)
		SELECT @tmp = LTRIM(RTRIM(REPLACE(@tmp, @OldStringTAG, '')))
		IF ISNUMERIC(@tmp) = 1
			SELECT @ID = @tmp

		IF @ID = @OldID
		BEGIN
			SET @ReplaceString = @NewStringTAG + CAST(@NewID AS VARCHAR) + '}'
			SELECT @retString = LTRIM(RTRIM(REPLACE(@Description, @OldPlaceHolder, @ReplaceString)))
		END
	END
	IF @retString = ''
	BEGIN
		SET @retString = @Description
	END
	RETURN @retString
END