CREATE PROCEDURE [dbo].[usp_UpdatestyleParagraphLineSpace]  --[dbo].[usp_UpdatestyleParagraphLineSpace]   
@InpSegmentJson NVARCHAR(MAX)  
AS  
    
BEGIN
  
DECLARE @PInpSegmentJson NVARCHAR(MAX) = @InpSegmentJson;
--Set Nocount On  
SET NOCOUNT ON;
  
 --DECLARE INP SEGMENT TABLE   
 DECLARE @InpSegmentTableVar TABLE(    
 StyleId INT,    
 DefaultSpacesId INT,  
 BeforeSpacesId INT,  
 AfterSpacesId INT,  
 CustomLineSpacing decimal(10,2),  
 IsExists int  
  
 );
  
 --PUT FETCHED INP RESULT IN LOCAL TABLE VARIABLE   
IF @PInpSegmentJson != ''  
BEGIN
INSERT INTO @InpSegmentTableVar
	SELECT
		*
	   ,0
	FROM OPENJSON(@PInpSegmentJson)
	WITH (
	StyleId INT '$.StyleId',
	DefaultSpacesId INT '$.DefaultSpacesId',
	BeforeSpacesId INT '$.BeforeSpacesId',
	AfterSpacesId INT '$.AfterSpacesId',
	CustomLineSpacing DECIMAL(10, 2) '$.CustomLineSpacing'
	);
END

UPDATE INPTBL
SET IsExists = 1
FROM @InpSegmentTableVar INPTBL
INNER JOIN [StyleParagraphLineSpace] STPLS WITH (NOLOCK)
	ON STPLS.StyleId = INPTBL.StyleId

INSERT INTO [StyleParagraphLineSpace] (StyleId, DefaultSpacesId, BeforeSpacesId, AfterSpacesId, CustomLineSpacing)
	SELECT
		INPTBL.StyleId
	   ,INPTBL.DefaultSpacesId
	   ,INPTBL.BeforeSpacesId
	   ,INPTBL.AfterSpacesId
	   ,INPTBL.CustomLineSpacing
	FROM @InpSegmentTableVar INPTBL
	WHERE INPTBL.IsExists = 0

UPDATE STPLS
SET STPLS.DefaultSpacesId = INPTBL.DefaultSpacesId
   ,STPLS.BeforeSpacesId = INPTBL.BeforeSpacesId
   ,STPLS.AfterSpacesId = INPTBL.AfterSpacesId
   ,STPLS.CustomLineSpacing = INPTBL.CustomLineSpacing
FROM @InpSegmentTableVar INPTBL
INNER JOIN [StyleParagraphLineSpace] STPLS WITH (NOLOCK)
	ON STPLS.StyleId = INPTBL.StyleId
WHERE INPTBL.IsExists = 1

END

GO
