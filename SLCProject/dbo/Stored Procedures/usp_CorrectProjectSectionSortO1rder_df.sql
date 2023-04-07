CREATE PROC usp_CorrectProjectSectionSortO1rder_df    
(    
 @ProjectId INT,    
 @CustomerId INT,    
 @UpdateDataFlag bit=0    
)    
AS    
BEGIN    
     
 select ProjectId,SectionId,SourceTag,Author,mSectionId,[Description],SortOrder,dbo.udf_ExpandDigits(SourceTag,5,0) as xSourceTag     
 ,IsHidden,DivisionId,DivisionCode,ParentSectionId,dbo.udf_ExpandDigits(DivisionCode,5,0) AS xDivisionCode     
 into #PS from ProjectSection with(NOLOCK)     
 where projectId=@ProjectId     
 and CustomerId=@CustomerId     
 and isdeleted=0     
 and isLastLevel=1    
    
 select ROW_NUMBER() over(order by SortOrder) as RowId,* into #divisions from(    
 select *,dbo.udf_ExpandDigits(SourceTag,5,0) as xSourceTag from projectSection ps with(nolock)     
 where projectId=@ProjectId and customerId=@CustomerId    
 and LevelId=2 and ISNULL(Islastlevel,0)=0 and isnull(IsDeleted,0)=0    
 ) as ps    
 order by SortOrder    
    
 DECLARE @divCounter INT=1,@DivCount INT=(select count(1) FROM #divisions)    
 DECLARE @subDivCounter INT=1,@subDivCount INT=0    
 DECLARE @sectionCounter INT=1,@sectionCount INT=0    
 DECLARE @divSectionId INT,@subDivDectionId INT    
     
 CREATE TABLE #Result(RowId INT,SectionId INT,ParentSectionId INT,DivisionId INT,DivisionCode nvarchar(10),    
 SourceTag nvarchar(20),Author nvarchar(20),mSectionId INT,[Description] nvarchar(500),IsHidden BIT,    
 IsLastLevel BIT,SortOrder INT,    
 xSourceTag NVARCHAR(100),xAuthor NVARCHAR(100),[Type] NVARCHAR(10),DSortOrder INT,SdSortOrder INT,CurrentSortOrder INT)    
    
 --select * from #divisions    
 --select * from #subdivisions    
 DECLARE @resCounter int=1;    
 WHILE(@divCounter<=@DivCount)    
 BEGIN    
  set @divSectionId=(select SectionId From #divisions where RowId=@divCounter)    
  INSERT INTO #Result    
  SELECT @resCounter,SectionId,0,DivisionId,DivisionCode,    
  SourceTag,Author,mSectionId,[Description],IsHidden,    
  IsLastLevel,@divCounter,dbo.udf_ExpandDigits(SourceTag,5,0),dbo.udf_ExpandDigits(Author,5,0),'1Div',@divCounter,0,0    
  From #divisions where RowId=@divCounter    
    
  set @resCounter=@resCounter+1    
   --Get Sub divisions    
   drop table if EXISTS #subDivs    
    
   select ROW_NUMBER() over(order by xSourceTag,xAuthor) as RowId,* into #subDivs from(    
   select *,dbo.udf_ExpandDigits(SourceTag,5,0) as xSourceTag,    
   dbo.udf_ExpandDigits(Author,5,0) as xAuthor    
   from ProjectSection ps WITH(NOLOCK)     
   where ProjectId=@ProjectId and CustomerId=@CustomerId    
   and ParentSectionId=@divSectionId and ISNULL(IsDeleted,0)=0    
   ) as SubDiv    
   order by xSourceTag,xAuthor    
    
   set @subDivCounter=1    
   set @subDivCount=(select count(1) FROM #subDivs)    
   WHILE(@subDivCounter<=@subDivCount)    
   BEGIN    
    set @subDivDectionId=(SELECT sectionId from #subDivs where RowId=@subDivCounter)    
    
    INSERT INTO #Result    
    SELECT @resCounter,SectionId,ParentSectionId,DivisionId,DivisionCode,    
    SourceTag,Author,mSectionId,[Description],IsHidden,    
    IsLastLevel,@subDivCounter,dbo.udf_ExpandDigits(SourceTag,5,0),dbo.udf_ExpandDigits(Author,5,0),'2SubDiv',@divCounter,@subDivCounter,0     
    From #subDivs where RowId=@subDivCounter    
    
    set @resCounter=@resCounter+1    
     --Get Sections    
     drop table if EXISTS #sections    
     select ROW_NUMBER() over(order by xSourceTag,xAuthor) as RowId,* into #sections from(    
      select *,dbo.udf_ExpandDigits(Author,5,0) as xAuthor    
      from #ps ps WITH(NOLOCK)     
      where ParentSectionId=@subDivDectionId    
     ) as S    
     order by xSourceTag,xAuthor    
    
     INSERT INTO #Result    
     SELECT RowId,SectionId,ParentSectionId,DivisionId,DivisionCode,    
     SourceTag,Author,mSectionId,[Description],IsHidden,    
     1,RowId,dbo.udf_ExpandDigits(SourceTag,10,0),dbo.udf_ExpandDigits(Author,10,0),'3Leaf',@divCounter,@subDivCounter,SortOrder     
     From #sections    
    
     --update d    
     --set d.DivisionCode=s.DivisionCode,    
     -- d.DivisionId=s.DivisionId    
     --from #Divisions d inner join #sections s    
     --ON d.RowId=@divCounter AND d.DivisionId is null    
     --where s.RowId=1    
         
     update d    
     set d.DivisionCode=s.DivisionCode,    
      d.DivisionId=s.DivisionId    
     from #Result d inner join #sections s    
     ON d.DSortOrder=@divCounter AND d.Type='1Div' and d.DivisionId is null    
     where s.RowId=1    
    
    set @subDivCounter=@subDivCounter+1    
    
   END    
    
  set @divCounter=@divCounter+1    
 END    
 if(@UpdateDataFlag=0)    
 BEGIN    
  SELECT * FROM  #Result --where 1=0    
  --select * from #Divisions    
 END    
 else if(@UpdateDataFlag=1)    
 BEGIN    
  update ps    
  set ps.SortOrder=t.SortOrder    
  FROM #Result t inner join ProjectSection ps WITH(NOLOCK)    
  ON t.SectionId=ps.SectionId    
  where t.[Type]='3Leaf'    and t.SortOrder<>CurrentSortOrder
 END    
END    