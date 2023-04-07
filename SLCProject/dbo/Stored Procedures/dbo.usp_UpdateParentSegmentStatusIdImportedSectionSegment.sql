CREATE PROCEDURE [dbo].[usp_UpdateParentSegmentStatusIdImportedSectionSegment]      
 @InpSegmentJson NVARCHAR(MAX) =''  
AS    
      
BEGIN
  
    DECLARE @PInpSegmentJson NVARCHAR(MAX) =  @InpSegmentJson;
 --DECLARE INP NOTE TABLE     
 DECLARE @InpParentSegmentStatusidTableVar TABLE(      
 SegmentStatusId BIGINT DEFAULT 0 ,    
 ParentSegmentStatusId BIGINT DEFAULT 0  ,    
 ProjectId INT DEFAULT 0  ,    
 CustomerId INT DEFAULT 0  ,    
 SectionId INT DEFAULT 0  ,    
 SegmentId BIGINT DEFAULT 0    
 );
  
    
    
 --PUT FETCHED INP RESULT IN LOCAL TABLE VARIABLE     
IF @PInpSegmentJson != ''    
BEGIN
INSERT INTO @InpParentSegmentStatusidTableVar
	SELECT
		*
	FROM OPENJSON(@PInpSegmentJson)
	WITH (
	SegmentStatusId BIGINT '$.SegmentStatusId',
	ParentSegmentStatusId BIGINT '$.ParentSegmentStatusId',
	ProjectId INT '$.ProjectId',
	CustomerId INT '$.CustomerId',
	SectionId INT '$.SectionId',
	SegmentId BIGINT '$.SegmentId'
	);
END

UPDATE PSS
SET PSS.ParentSegmentStatusId = convert(bigint, INPT.ParentSegmentStatusId)
FROM projectSegmentStatus PSS WITH (NOLOCK)
INNER JOIN @InpParentSegmentStatusidTableVar INPT
	ON INPT.SegmentStatusId = PSS.SegmentStatusId
	AND PSS.ProjectId = INPT.ProjectId
	AND PSS.CustomerId = INPT.CustomerId
	AND pss.SectionId = INPT.SectionId
	AND PSS.SegmentId = INPT.SegmentId

END

GO


