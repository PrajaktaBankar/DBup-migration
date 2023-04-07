--Execute it on server 2

DECLARE @ProjectId int =3367
DECLARE @SectionId int =(select SectionId from ProjectSection where ProjectId= @ProjectId and SourceTag='092116' and IsDeleted=0)
DECLARE @SegmentId int=0


---for find segment are duplicate first table

Select COUNT(SegmentChoiceCode) as SegmentChoiceCodecount,ProjectId,SectionId,SegmentId,SegmentChoiceCode 
into #tempResult
from ProjectSegmentChoice with(nolock)
where IsDeleted=0 and ProjectId=@ProjectId 
and SectionId=@SectionId 
group by ProjectId,SectionId,SegmentChoiceCode,SegmentId
having COUNT(SegmentChoiceCode)>1

--select * from #tempResult
update ProjectSegmentChoice set IsDeleted=1 where SegmentChoiceId in(
select SegmentChoiceId from (
Select PSC.ProjectId,PSC.SegmentChoiceId, ROW_NUMBER() over  ( partition by PSC.SegmentId order by PSC.SegmentId) 'Rank' from ProjectSegmentChoice PSC with(nolock)
inner join #tempResult on PSC.ProjectId=#tempResult.ProjectId and PSC.SectionId=#tempResult.SectionId and psc.SegmentId=#tempResult.SegmentId and psc.SegmentChoiceCode=#tempResult.SegmentChoiceCode
and isnull(Psc.IsDeleted,0)=0
where psc.ProjectId=@ProjectId and psc.SectionId=@SectionId 
and #tempResult.SegmentChoiceCode not in(
59769
) 
)As Resultdata
where Resultdata.Rank>1
)

---for find segment are duplicate second table

select * into #TobeDeleteDatafromResult from (
Select PSC.ProjectId,PSC.SegmentChoiceId, ROW_NUMBER() over  ( partition by PSC.SegmentId order by PSC.SegmentId) 'Rank' 
from ProjectSegmentChoice PSC with(nolock) inner join #tempResult on PSC.ProjectId=#tempResult.ProjectId and 
PSC.SectionId=#tempResult.SectionId and 
psc.SegmentId=#tempResult.SegmentId and 
psc.SegmentChoiceCode=#tempResult.SegmentChoiceCode
and isnull(Psc.IsDeleted,0)=0
where psc.ProjectId=@ProjectId and psc.SectionId=@SectionId 
and #tempResult.SegmentChoiceCode not in(
59769
) 
)As Resultdata
where Resultdata.Rank>1

--select * from #TobeDeleteDatafromResult

update ProjectChoiceOption set IsDeleted=1 where ChoiceOptionId in( Select ChoiceOptionId from ProjectChoiceOption where ProjectId=@ProjectId and SectionId=@SectionId and SegmentChoiceId IN (
select SegmentChoiceId from #TobeDeleteDatafromResult
) and isnull(IsDeleted,0)=0)



select * into #SelectedSegmentChoiceId from(
Select PSC.ProjectId,PSC.SegmentChoiceId, ROW_NUMBER() over  ( partition by PSC.SegmentId order by PSC.SegmentId) 'Rank',isnull(PSC.IsDeleted,0) 'IsDeleted' from ProjectSegmentChoice PSC with(nolock)
inner join #tempResult on PSC.ProjectId=#tempResult.ProjectId and PSC.SectionId=#tempResult.SectionId and psc.SegmentId=#tempResult.SegmentId and psc.SegmentChoiceCode=#tempResult.SegmentChoiceCode
and isnull(Psc.IsDeleted,0)=0
where psc.ProjectId=@ProjectId and psc.SectionId=@SectionId 
and #tempResult.SegmentChoiceCode not in(
59769
) 
)As Resultdata
where Resultdata.Rank=1


update ProjectChoiceOption set IsDeleted=1 where ChoiceOptionId in(
select ChoiceOptionId from (
Select ROW_Number() over (partition by SortOrder order by choiceoptionid) 'RANK',* from ProjectChoiceOption where ProjectId=@ProjectId and SectionId=@SectionId and isnull(IsDeleted,0)=0  and SegmentChoiceId  in (
select distinct SegmentChoiceId from #SelectedSegmentChoiceId

) ) Res where Res.RANK>1
)

update ProjectChoiceOption set IsDeleted=1 where ChoiceOptionId in(
select ChoiceOptionId from ProjectChoiceOption with(nolock) where ProjectId=@ProjectId and SectionId=@SectionId and isnull(IsDeleted,0)=0  and SegmentChoiceId  in (
select distinct SegmentChoiceId from #SelectedSegmentChoiceId
) and SortOrder=0
)


drop table #SelectedSegmentChoiceId
drop table #TobeDeleteDatafromResult

drop table #tempResult

