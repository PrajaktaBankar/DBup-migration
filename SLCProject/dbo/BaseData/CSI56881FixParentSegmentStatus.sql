use SLCProject_SqlSlcOp004
go

/*
Customer Support 57342: Hierarchy break - Karen Aldrich with Gresham Smith - 21628
CustomerID: 2626
ProjectID: 8663

First Run FixIndentLevelOfChild script if there are children whoes level is more than 1 than the parent.
Example: Parent is at indentlevel 3 but immediate child is at 5. This is wrong. Immediate child is always 4 in this case.

Fix ParentSegmentStatusID based on Sequence Number and Indentlevel.

The script below identifies child paragraphs that has incorrect parentsegmentstatusID and updates the right one based on 
Indentlevel and sequence number.


*/

declare @CustomerID int = 3657
declare @ProjectID int = 16187
declare @Sourcetag nvarchar(20) = '260533'
declare @Author nvarchar(10) = 'VA SPEC'
declare @SectionID int = 0
declare @Fix int = 1
declare @ParentMisMatchCount int = 0 

select @SectionID = SectionID from dbo.ProjectSection where CustomerId=@CustomerID and ProjectId=@ProjectID and SourceTag like @Sourcetag and Author like @Author and isdeleted=0

select @SectionID as SectionID

if (@SectionID>0)
begin
		
	drop table if exists #tmpProjectSegmentStatus	

	create table #tmpProjectSegmentStatus (
		[SegmentStatusId] [int]  NOT NULL,
		[SectionId] [int] NOT NULL,
		[ParentSegmentStatusId] [int] NOT NULL,
		[mSegmentStatusId] [int] NULL,
		[mSegmentId] [int] NULL,
		[SegmentId] [int] NULL,
		[SegmentSource] [char](1) NULL,
		[SegmentOrigin] [char](1) NULL,
		[IndentLevel] [tinyint] NOT NULL,
		[SequenceNumber] [decimal](18, 4) NOT NULL,
		[IsDeleted] [bit] NULL
	) ON [PRIMARY] 
	
	Insert into #tmpProjectSegmentStatus
	select [SegmentStatusId]
		  ,[SectionId]
		  ,[ParentSegmentStatusId]
		  ,[mSegmentStatusId]
		  ,[mSegmentId]
		  ,[SegmentId]
		  ,[SegmentSource]
		  ,[SegmentOrigin]
		  ,[IndentLevel]
		  ,[SequenceNumber]
		  ,isdeleted
	from dbo.ProjectSegmentStatus with (Nolock) where ProjectId=@ProjectID and SectionId=@SectionID  and isnull(IsDeleted,0)=0
		
	--select * 
	--into BPMCore_Staging_SLC..ProjectSegmentStatus_2626
	--from dbo.ProjectSegmentStatus with (Nolock) where ProjectId=@ProjectID and SectionId=@SectionID  and (IsDeleted=0 or IsDeleted is NULL)

	drop table if exists #tmpFixProjectSegmentStatus

	select child.segmentstatusid
	into #tmpFixProjectSegmentStatus
	from #tmpProjectSegmentStatus Child
	cross apply (select top 1 Parent.SegmentStatusId from #tmpProjectSegmentStatus Parent 
					where Child.IndentLevel-1=Parent.IndentLevel 
						and Parent.SequenceNumber < Child.SequenceNumber 
					order by Parent.SequenceNumber desc) as X
	where x.SegmentStatusId != Child.ParentSegmentStatusId

	Set @ParentMisMatchCount = @@ROWCOUNT

	select @ParentMisMatchCount as ParentMisMatchCount
	-- output for reference (useful for testing visually)
	SELECT
		PSST.ProjectId
		,PSST.CustomerId
		,PS.SourceTag
		,PS.Author
		,(CASE
			WHEN PSST.SegmentStatusId IS NOT NULL AND
				PSST_PSG.SegmentId IS NOT NULL THEN PSST_PSG.SegmentCode
			WHEN PSST.SegmentStatusId IS NOT NULL AND
				PSST_MSG.SegmentId IS NOT NULL THEN PSST_MSG.SegmentCode
			ELSE NULL
		END) AS SegmentCode
	   ,(CASE
			WHEN PSST.SequenceNumber = 0 AND
				PSST.IndentLevel = 0 AND
				PSST.ParentSegmentStatusId = 0 THEN PS.Description
			WHEN PSST.SegmentStatusId IS NOT NULL AND
				PSST_PSG.SegmentId IS NOT NULL THEN COALESCE(PSST_PSG.BaseSegmentDescription, PSST_PSG.SegmentDescription)
			WHEN PSST.SegmentStatusId IS NOT NULL AND
				PSST_MSG.SegmentId IS NOT NULL THEN PSST_MSG.SegmentDescription
			ELSE NULL
		END) AS SegmentDescription
	   ,PSST.SequenceNumber
	   ,PSST.IndentLevel
	   , PSST.SegmentStatusId
	FROM ProjectSegmentStatus PSST WITH (NOLOCK)
	INNER JOIN #tmpFixProjectSegmentStatus PST on PST.SegmentStatusId=PSST.SegmentStatusId
	INNER JOIN ProjectSection PS WITH (NOLOCK)
		ON PSST.ProjectId = PS.ProjectId
			AND PSST.SectionId = PS.SectionId
	LEFT JOIN ProjectSegment PSST_PSG WITH (NOLOCK)
		ON PSST.SegmentId = PSST_PSG.SegmentId
			AND PSST.SegmentOrigin = 'U'
	LEFT JOIN SLCMaster..Segment PSST_MSG WITH (NOLOCK)
		ON PSST.mSegmentId = PSST_MSG.SegmentId
			AND PSST.SegmentOrigin = 'M'
	order by SequenceNumber
	

	--Actual Fix
	if (@Fix=1 and @ParentMisMatchCount>0)
	begin
		begin try

		begin tran
		--Update the parentsegmentstatuid of child paragraphs which has incorrect parentsegmentstatusid based on indentlevel and sequnce number
		Update #tmpProjectSegmentStatus set ParentSegmentStatusId=X.SegmentStatusId	
		from #tmpProjectSegmentStatus Child
		cross apply (select top 1 Parent.SegmentStatusId from #tmpProjectSegmentStatus Parent 
						where Child.IndentLevel-1=Parent.IndentLevel 
							and Parent.SequenceNumber < Child.SequenceNumber 
						order by Parent.SequenceNumber desc) as X
		where x.SegmentStatusId != Child.ParentSegmentStatusId

		Update dbo.ProjectSegmentStatus set ParentSegmentStatusId=pst.ParentSegmentStatusId
		from dbo.ProjectSegmentStatus pss
		inner join #tmpProjectSegmentStatus pst on pst.SegmentStatusId=pss.SegmentStatusId
		where pss.ParentSegmentStatusId != pst.ParentSegmentStatusId and CustomerId=@CustomerID and ProjectId=@ProjectID and pss.SectionId=@SectionID

		if @@ROWCOUNT>0 commit tran

		select @@ROWCOUNT

		end try
		begin catch

			if @@ROWCOUNT>0 rollback tran

			 SELECT  
					ERROR_NUMBER() AS ErrorNumber  
					,ERROR_MESSAGE() AS ErrorMessage
					, ERROR_LINE() as ErrorLine;
		end catch
	end

end

