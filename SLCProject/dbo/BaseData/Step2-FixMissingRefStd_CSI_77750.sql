use slcproject_sqlslcop005
go
-- Missing reference Standards
/*
Customer Support 77750: SLC: Missing Reference Standards (#RS Error)
Run Step1-CreateBackupTable_CSI_77750 first

Run on server 5

This is NOT a generic script.

The script maps the source and target ref stds and replaces it in RS paragraph.

*/

declare @FixTargetCustomerID int =3228 --MARTA
--declare @FixTargetprojectID int=11520 -- Parking Lot Paving Program - 90%
declare @FixTargetprojectID int=8357 -- MARTA Master 2022.02.07
declare @SourceCustomerID int =2439 --WSP
declare @NumberRecords int
declare @RowCount int
declare @RunDate datetime2 = getdate()
declare @RunFix bit = 0

drop table if exists #tmpProjectSegment

select *, dbo.udf_GetCodeFromFormat(SegmentDescription, 'RSTEMP#') as RefStdCode 
into #tmpProjectSegment
from ProjectSegment where CustomerId=@FixTargetCustomerID and ProjectId=@FixTargetprojectID
and CHARINDEX('{RSTEMP#', SegmentDescription)>0

Insert into BPMCore_Staging_SLC..projectsegment_3228 ([SegmentId]
      ,[SegmentStatusId]
      ,[SectionId]
      ,[ProjectId]
      ,[CustomerId]
      ,[SegmentDescription]
      ,[SegmentSource]
      ,[SegmentCode]
      ,[CreatedBy]
      ,[CreateDate]
      ,[ModifiedBy]
      ,[ModifiedDate]
      ,[SLE_DocID]
      ,[SLE_SegmentID]
      ,[SLE_StatusID]
      ,[A_SegmentId]
      ,[IsDeleted]
      ,[BaseSegmentDescription]
	  , [BackupRunDate])
SELECT [SegmentId]
      ,[SegmentStatusId]
      ,[SectionId]
      ,[ProjectId]
      ,[CustomerId]
      ,[SegmentDescription]
      ,[SegmentSource]
      ,[SegmentCode]
      ,[CreatedBy]
      ,[CreateDate]
      ,[ModifiedBy]
      ,[ModifiedDate]
      ,[SLE_DocID]
      ,[SLE_SegmentID]
      ,[SLE_StatusID]
      ,[A_SegmentId]
      ,[IsDeleted]
      ,[BaseSegmentDescription]
	  , @RunDate
from #tmpProjectSegment

drop table if exists #tmpRSParagraphs

select ps.*
into #tmpRSParagraphs
from dbo.ProjectSegmentStatus pst
inner join #tmpProjectSegment ps on ps.CustomerId=pst.CustomerId
								and ps.ProjectId=pst.ProjectId
								and ps.SectionId=pst.SectionId
								and ps.SegmentStatusId=pst.SegmentStatusId
inner join dbo.projectsection psec on psec.CustomerId=pst.CustomerId
									and psec.ProjectId=pst.ProjectId
									and psec.SectionId=pst.SectionId
where pst.CustomerId=@FixTargetCustomerID 
	and pst.ProjectId=@FixTargetprojectID
	and isnull(pst.IsDeleted, 0)=0
	and isnull(psec.isdeleted,0)=0


drop table if exists #tmpRefStds_Target

select * 
into #tmpRefStds_Target
from dbo.ReferenceStandard 
where CustomerId=@FixTargetCustomerID

drop table if exists #tmpRefStds_Source	

select * 
into #tmpRefStds_Source
from dbo.ReferenceStandard 
where CustomerId=@SourceCustomerID

drop table if exists #tmpSourceAndTarget
select 
	 srcref.RefStdCode as SrcRefStdCode
	, srcref.RefStdName as SrcRefStdName
	, srcref.customerid  as SrcCustomerid
	,tgtref.RefStdCode as TgtRefStdCode
	, tgtref.RefStdName as TgtRefStdName
	, tgtref.customerid as TgtCustomerId
into #tmpSourceAndTarget
from #tmpRefStds_target tgtref
	inner join #tmpRefStds_Source srcref on srcref.RefStdName=tgtref.RefStdName

--select * from #tmpRSParagraphs where CHARINDEX(',', refstdcode)>0

delete from #tmpRSParagraphs where CHARINDEX(',', refstdcode)>0
delete from #tmpRSParagraphs where RefStdCode<100000

drop table if exists #tmpRSParagraphsFix

select rs.* 
into #tmpRSParagraphsFix
from #tmpRSParagraphs rs
left outer join #tmpRefStds_Target trs on trs.RefStdCode = rs.RefStdCode
where trs.RefStdCode is null

--select * from #tmpRSParagraphsFix where RefStdCode=10000474
--select * from #tmpSourceAndTarget where SrcRefStdCode=10000474

--select REPLACE(segmentdescription, SrcRefStdCode, tgtRefStdCode), * from #tmpRSParagraphsFix rsp
--inner join #tmpSourceAndTarget rs on rs.srcRefStdCode=rsp.RefStdCode
--where RefStdCode=10000474

Update rsp set rsp.SegmentDescription = REPLACE(segmentdescription, SrcRefStdCode, TgtRefStdCode)
from #tmpRSParagraphsFix rsp
inner join #tmpSourceAndTarget rs on rs.srcRefStdCode=rsp.RefStdCode


select psec.projectid
	, psec.SourceTag + ':' + psec.Author as SectionID
	, rsp.SegmentDescription 
	, pst.SequenceNumber
	, dbo.fnGetSegmentDescriptionTextForRSAndGT(rsp.projectid, rsp.CustomerId, SegmentDescription)
from #tmpRSParagraphsFix rsp
inner join #tmpSourceAndTarget rs on rs.SrcRefStdCode=rsp.RefStdCode
inner join dbo.projectsection psec on psec.CustomerId=rsp.CustomerId
									and psec.ProjectId=rsp.ProjectId
									and psec.SectionId=rsp.SectionId
inner join dbo.ProjectSegmentStatus pst on pst.CustomerId=rsp.CustomerId
										and pst.ProjectId=rsp.ProjectId
										and pst.SectionId=rsp.SectionId
										and pst.SegmentStatusId=rsp.SegmentStatusId

order by sectionid, SequenceNumber


if (@RunFix=1)
begin
	Update dbo.ProjectSegment set SegmentDescription=fps.SegmentDescription
	from dbo.ProjectSegment ps
	inner join #tmpRSParagraphsFix fps on fps.CustomerId=ps.CustomerId
										and fps.ProjectId=ps.ProjectId
										and fps.SegmentStatusId=ps.SegmentStatusId
	where ps.CustomerId=@FixTargetCustomerID and ps.ProjectId=@FixTargetprojectID
end
