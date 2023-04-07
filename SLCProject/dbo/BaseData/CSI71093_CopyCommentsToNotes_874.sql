/*
Customer Support 71093: SLC: Converting Comments To Notes Request

Customer request to copy comments to notes

Project Name: OKC Office Master
Project ID: 15303

Total of 190 comments over 10 sections.
*/

INSERT INTO ProjectNote (SectionId
, SegmentStatusId
, NoteText
, CreateDate
, ModifiedDate
, ProjectId
, CustomerId
, Title
, CreatedBy
, ModifiedBy
, CreatedUserName
, ModifiedUserName
, IsDeleted
, A_NoteId)
select sc.SectionId
	, sc.SegmentStatusId
	, sc.CommentDescription
	, GETUTCDATE() as CreateDate
	, GETUTCDATE() as ModifiedDate
	, sc.ProjectId
	, sc.CustomerId
	, ''
	, 2771
	, 2771
	, 'GH2 Architects' 
	, 'GH2 Architects'
	,0
	,0
from dbo.SegmentComment sc with (nolock) 
where sc.CustomerId=874 and sc.ProjectId=15303 and sc.IsDeleted=0
and sc.SegmentStatusId not in (
	select SegmentStatusId from dbo.ProjectNote pn with (nolock) where CustomerId=874 and ProjectId=15303 and SegmentStatusId in (
							select SegmentStatusId from SegmentComment
							where CustomerId=874 and ProjectId=15303 and IsDeleted=0))
