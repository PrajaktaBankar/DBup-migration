CREATE PROCEDURE [dbo].[usp_UpdatePorjectSegmentDescriptionsImportedSection]          
 @InpSegmentJson NVARCHAR(MAX) =''    ,  
 @IncludeChoices BIT=0  
AS        
          
BEGIN    
      
DECLARE @PInpSegmentJson NVARCHAR(MAX) = @InpSegmentJson;    
 --DECLARE INP NOTE TABLE         
 CREATE TABLE #InpSegmentStatusidTableVar(       
 RowId INT,     
 SegmentStatusId BIGINT DEFAULT 0 ,        
 SegmentDescription  NVARCHAR(max),        
 ProjectId INT DEFAULT 0  ,        
 CustomerId INT DEFAULT 0  ,        
 SectionId INT DEFAULT 0  ,        
 SegmentId BIGINT DEFAULT 0      ,  
 ChoiceList nvarchar(max) NULL  ,
 GTList nvarchar(max) NULL  
 );    

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
 SegmentDescription NVARCHAR(MAX) '$.SegmentDescription',    
 ProjectId INT '$.ProjectId',    
 CustomerId INT '$.CustomerId',    
 SectionId INT '$.SectionId',    
 SegmentId BIGINT '$.SegmentId'  ,  
 ChoiceList NVARCHAR(MAX) AS JSON , 
 GTList NVARCHAR(MAX) AS JSON  
 );    
END    
    
  if(@IncludeChoices=1)  
  BEGIN  
 drop table if exists #enhanceTextMapping  
 create table #enhanceTextMapping(optionTypeId INT,OptionValue nvarchar(255),OptionVar nvarchar(10))  
   
 select [name],GlobalTermCode as [value] into #t from ProjectGlobalTerm with(nolock)   
 where name in('Owner''s Spec Term','Design-Builder''s Spec Term','Design Professional''s Spec Term','Contractor''s Spec Term','Delegated Design Engineers To Be Licensed In')  and ProjectId=(select top 1 ProjectId from #InpSegmentStatusidTableVar)  
  
 insert into #enhanceTextMapping  
 select 6,[value],'#O#' from #t where [name]='Owner''s Spec Term'  
  
 insert into #enhanceTextMapping  
 select 6,[value],'#D#' from #t where name='Design-Builder''s Spec Term'  
  
 insert into #enhanceTextMapping  
 select 6,[value],'#A#' from #t where name='Design Professional''s Spec Term'  
  
 insert into #enhanceTextMapping  
 select 6,[value],'#C#' from #t where name='Contractor''s Spec Term'  
  
 insert into #enhanceTextMapping  
 select 6,[value],'#S#' from #t where name='Delegated Design Engineers To Be Licensed In'  
  
 declare @i int=1,@cnt INT=(select count(1) from #InpSegmentStatusidTableVar)  
 while(@i<=@cnt)  
 BEGIN  
  exec usp_InsertChoicesFromWord @Id=@i  
  exec usp_InsertGTForImportFromWord @Id=@i  
  set @i=@i+1  
 END  
  END  
  

UPDATE PSS    
SET PSS.SegmentDescription = INPT.SegmentDescription    
FROM projectSegment PSS WITH (NOLOCK)    
INNER JOIN #InpSegmentStatusidTableVar INPT    
 ON INPT.SegmentStatusId = PSS.SegmentStatusId    
 AND PSS.ProjectId = INPT.ProjectId    
 AND PSS.CustomerId = INPT.CustomerId    
 AND pss.SectionId = INPT.SectionId    
 AND PSS.SegmentId = INPT.SegmentId    
    
    
END
GO


