CREATE PROC [dbo].[usp_UpdatePorjectSegmentNotesImportedSection]
(
	@InpSegmentJson nvarchar(max)
)
AS
BEGIN
	DECLARE @PInpSegmentJson NVARCHAR(MAX) = @InpSegmentJson;    
	 --DECLARE INP NOTE TABLE         
	 CREATE TABLE #InpSegmentStatusidTableVar(       
	 RowId INT,     
	 SegmentStatusId BIGINT DEFAULT 0 ,        
	 ProjectId INT DEFAULT 0  ,        
	 CustomerId INT DEFAULT 0  ,        
	 SectionId INT DEFAULT 0  ,        
	 SegmentId BIGINT DEFAULT 0      ,  
	 NoteList nvarchar(max) NULL  
	 );    

	 declare @customerId INT,    
	 @projectId INT,    
	 @sectionId INT,    
	 @segmentId BIGINT,    
	 @segmentStatusId BIGINT,    
	 @noteJson NVARCHAR(MAX)    
	 
	 --PUT FETCHED INP RESULT IN LOCAL TABLE VARIABLE         
	IF @PInpSegmentJson != ''        
	BEGIN    
		INSERT INTO #InpSegmentStatusidTableVar    
		SELECT    
		ROW_NUMBER() over(order by SegmentStatusId) as RowId,  
		*    
		FROM OPENJSON(@PInpSegmentJson)    
		WITH (    
		SegmentStatusId BIGINT '$.SegmentStatusId',    
		ProjectId INT '$.ProjectId',    
		CustomerId INT '$.CustomerId',    
		SectionId INT '$.SectionId',    
		SegmentId BIGINT '$.SegmentId'  ,  
		NoteList NVARCHAR(MAX) AS JSON 
		);    

		DECLARE @i int=0,@cnt INT =(select count(1) from #InpSegmentStatusidTableVar)
		WHILE(@i<=@cnt)
		BEGIN
			 select @customerId=customerId,@projectId=projectId,@sectionId=sectionId,    
			 @segmentId=segmentId,@segmentStatusId=segmentStatusId,@noteJson=NoteList   
			 from #InpSegmentStatusidTableVar    
			 where RowId=@i 
			 
			 insert into ProjectNote(SectionId,SegmentStatusId,Notetext,CreateDate,ProjectId,CustomerId,CreatedBy)
			 select @sectionId,@segmentStatusId,[description],GETUTCDATE(),@projectId,@customerId,0 from openjson(@noteJson)
			 with([Description] nvarchar(max)
			 )

			 set @i=@i+1
		END
	END    
END
GO


