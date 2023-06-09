CREATE Procedure [dbo].[usp_GetSegmentRequirementTag]
@SectionId int
As
Begin
DECLARE @PSectionId int = @SectionId;

SELECT
	segTag.SegmentRequirementTagId
   ,segTag.SectionId
   ,segTag.SegmentStatusId
   ,segTag.RequirementTagId
   ,luregTag.TagType AS TagName
FROM SLCMaster.dbo.[SegmentRequirementTag] segTag WITH (NOLOCK)
INNER JOIN SLCMaster.dbo.LuRequirementTag luregTag WITH (NOLOCK)
	ON segTag.RequirementTagId = luregTag.RequirementTagId
WHERE segTag.SectionId = @PSectionId

END;

GO
