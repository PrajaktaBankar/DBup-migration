ALTER TABLE [dbo].[CopyProjectHistory]
Add RequestId INT NULL

--ADD Request Id as Fk key in CopyHistory table
ALTER TABLE [dbo].[CopyProjectHistory]  WITH NOCHECK ADD CONSTRAINT [FK_CopyProjectHistory_CopyProjectRequest] FOREIGN KEY([RequestId])
REFERENCES [dbo].[CopyProjectRequest] ([RequestId])
GO


update CPH
set CPH.RequestId=cpr.RequestId
from CopyProjectHistory CPH WITH(NOLOCK)
inner join [CopyProjectRequest] cpr WITH(NOLOCK)
on cph.ProjectId=cpr.TargetProjectId
