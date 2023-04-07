CREATE PROC [dbo].[usp_InsertChoicesFromWord]    
(    
 @Id INT    
)    
AS    
BEGIN    
declare @customerId INT,    
 @projectId INT,    
 @sectionId INT,    
 @segmentId BIGINT,    
 @segmentStatusId BIGINT,    
 @choiceJson NVARCHAR(MAX)    
    
    
 select @customerId=customerId,@projectId=projectId,@sectionId=sectionId,    
 @segmentId=segmentId,@segmentStatusId=segmentStatusId,@choiceJson=ChoiceList   
 from #InpSegmentStatusidTableVar    
 where RowId=@Id    
   

 select ROW_NUMBER() over(order by choiceType) as RowId,* into #choiceTemp   
 from openjson(@choiceJson)    
 with(    
 ChoiceType INT,    
 PlaceHolder NVARCHAR(10),    
 Options nvarchar(max) as JSON    
 )    
     
 create table #optionList(RowId INT,optionTypeName NVARCHAR(50),optionTypeId INT,value nvarchar(250), Id INT null,valueJson nvarchar(max))    
 declare @i int=1,@cnt INT=(select count(1) from #choiceTemp)    
 declare @optionId int=1,@Optioncnt INT=0    
 declare @choiceType int,@placeHolder nvarchar(10),@options nvarchar(max)    
 declare @NewChoiceId BIGINT,@segmentChoiceCode BIGINT=0,@InsertedChoiceOptionId BIGINT,@choiceOptionCode BIGINT    
  
 WHILE(@i<=@cnt)    
 BEGIN    
  select @choiceType=choiceType,@placeHolder=placeholder,@options=options   
  from #choiceTemp    
  where RowId=@i    
  
  insert into ProjectSegmentChoice(CustomerId,ProjectId,SectionId,SegmentId,SegmentStatusId,    
   ChoiceTypeId,CreatedBy,CreateDate,IsDeleted,SegmentChoiceSource)    
  values(@customerId,@projectId,@sectionId,@segmentId,@segmentStatusId,    
   @choiceType,0,GETUTCDATE(),0,'U')    
    
  SET @NewChoiceId = SCOPE_IDENTITY();     
  select top 1 @segmentChoiceCode=SegmentChoiceCode   
  from ProjectSegmentChoice psc with(nolock)    
  where SegmentChoiceId=@NewChoiceId    
    
  update t    
  set t.SegmentDescription=replace(t.segmentDescription,@placeHolder,concat('{CH#',@segmentChoiceCode,'}'))    
  from #InpSegmentStatusidTableVar t    
  where RowId=@Id    
    
  delete from #optionList    
    
  insert into #optionList    
  select     
  ROW_NUMBER() over(order by optionId) as RowId,    
  optionTypeName,optionTypeId,IIF(optionTypeId=4,concat('[',[value],']'),[value]) ,0, ValueJson  
  from openjson(@options)    
  with(optionTypeId int,    
   [Value] nvarchar(250),    
   optionTypeName nvarchar(250)  ,  
   optionId int,
   ValueJson nvarchar(max) --as JSON  
  )    
      
  --update None NA    
  update #optionList    
  set [value]='None - N/A'    
  where optionTypeId=8    
    
  --update GT's    
  update o    
  set o.Id=t.OptionValue,    
   o.value=0    
  from #optionList o inner join #enhanceTextMapping t    
  ON o.optionTypeId=t.optionTypeId    
  and o.value=t.OptionVar    
  where o.optionTypeId=6    
    
  set @optionId=1    
  set @Optioncnt=(select count(1) from #optionList)    
  while(@optionId<=@Optioncnt)    
  BEGIN    
   insert into ProjectChoiceOption(CustomerId,ProjectId,SectionId,SegmentChoiceId,    
   SortOrder,ChoiceOptionSource,CreatedBy,CreateDate,OptionJson)    
   select @customerId,@projectId,@sectionId,@NewChoiceId,    
   RowId,'U',0,GETUTCDATE(),concat('[{"OptionTypeId":',optionTypeId,',"OptionTypeName":"',optionTypeName,'","SortOrder":',RowId,',"Value":"',[value],'","MValue":null,"DefaultValue":null,"Id":',Id,',"ValueJson":',isnull(valueJson,'null'),',"MValueJson":null,"TempSortOrder":0.0,"IsdeletedSectionId":false,"IncludeSectionTitle":false,"PrevTrackValue":null,"PrevTrackValueJson":null}]')    
   from #optionList    
   where RowId=@optionId    
    
   SET @InsertedChoiceOptionId =SCOPE_IDENTITY();     
       
   SELECT top 1 @ChoiceOptionCode = ChoiceOptionCode      
   FROM ProjectChoiceOption WITH (NOLOCK)      
   WHERE ChoiceOptionId = @InsertedChoiceOptionId      
    
   INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId)      
   SELECT      
   @segmentChoiceCode AS SegmentChoiceCode      
   ,@ChoiceOptionCode AS ChoiceOptionCode      
   ,'U' AS ChoiceOptionSource      
   ,iif(@optionId=1,1,0) as IsSelected      
   ,@SectionId AS SectionId      
   ,@ProjectId AS ProjectId      
   ,@CustomerId AS CustomerId      
    
   set @optionId=@optionId+1    
  END    
    
    
  set @i=@i+1    
 END    
END
GO


