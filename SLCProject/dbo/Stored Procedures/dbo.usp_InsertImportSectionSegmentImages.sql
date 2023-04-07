CREATE PROCEDURE [dbo].[usp_InsertImportSectionSegmentImages]  --[dbo].[usp_InsertImportSectionSegmentImages] @InpSegmentJson='[{"RowId":1,"ProjectId":11788,"CustomerId":8,"SegmentId":406710,"SectionId":5210650,"ImagePath":"a8d1b1b4_a42b_4497_b9f8_6b4692989854.png","LuImageSourceTypeId":1,"SegmentStatusId":10668031,"SegmentDescription":""}]'  
@InpSegmentJson NVARCHAR(MAX)  
AS  
    
BEGIN
  
DECLARE @PInpSegmentJson NVARCHAR(MAX) = @InpSegmentJson;

DECLARE @InpSegmentImageTableVar TABLE(    
 RowId INT ,    
 SectionId INT,    
 SegmentStatusId BIGINT,  
 ProjectId INT,  
 CustomerId INT DEFAULT 0,  
 SegmentDescription NVARCHAR(200),  
 ImagePath NVARCHAR(200),  
 LuImageSourceTypeId INT,  
  SegmentId BIGINT ,  
  ImageId  INT  
 );
  
 --PUT FETCHED INP RESULT IN LOCAL TABLE VARIABLE   
IF @PInpSegmentJson != ''  
BEGIN
INSERT INTO @InpSegmentImageTableVar
	SELECT
		*
	   ,0
	FROM OPENJSON(@PInpSegmentJson)
	WITH (
	RowId INT '$.RowId',
	SectionId INT '$.SectionId',
	SegmentStatusId BIGINT '$.SegmentStatusId',
	ProjectId INT '$.ProjectId',
	CustomerId INT '$.CustomerId',
	SegmentDescription NVARCHAR(MAX) '$.SegmentDescription',
	ImagePath NVARCHAR(MAX) '$.ImagePath',
	LuImageSourceTypeId INT '$.LuImageSourceTypeId',
	SegmentId BIGINT '$.SegmentId'
	);
END

INSERT INTO ProjectImage (ImagePath
, LuImageSourceTypeId
, CreateDate
, ModifiedDate
, CustomerId)
	SELECT
		ImagePath
	   ,LuImageSourceTypeId
	   ,GETUTCDATE()
	   ,GETUTCDATE()
	   ,CustomerId
	FROM @InpSegmentImageTableVar


UPDATE INPUTB
SET INPUTB.ImageId = PIMG.ImageId
FROM ProjectImage PIMG WITH (NOLOCK)
INNER JOIN @InpSegmentImageTableVar INPUTB
	ON INPUTB.ImagePath = PIMG.ImagePath
WHERE INPUTB.ImagePath = PIMG.ImagePath

INSERT INTO ProjectSegmentImage (SectionId
, ImageId
, ProjectId
, CustomerId
, SegmentId)
	SELECT
		SectionId
	   ,ImageId
	   ,ProjectId
	   ,CustomerId
	   ,0 AS SegmentId
	FROM @InpSegmentImageTableVar

UPDATE PRJSEG
SET PRJSEG.SegmentDescription = '{IMG#' + CAST(INPUTB.ImageId AS NVARCHAR(MAX)) + '}'
FROM @InpSegmentImageTableVar INPUTB
INNER JOIN ProjectSegment PRJSEG WITH (NOLOCK)
	ON INPUTB.SegmentStatusId = PRJSEG.SegmentStatusId
WHERE INPUTB.SegmentId = PRJSEG.SegmentId
AND INPUTB.SectionId = PRJSEG.SectionId
AND INPUTB.SegmentStatusId = PRJSEG.SegmentStatusId
AND INPUTB.CustomerId = PRJSEG.CustomerId
AND PRJSEG.ProjectId = INPUTB.ProjectId

END
GO


