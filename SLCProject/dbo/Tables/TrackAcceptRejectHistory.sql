CREATE TABLE [dbo].[TrackAcceptRejectHistory](
[TrackHistoryId] [int] primary key IDENTITY(1,1) NOT NULL,
[SectionId] [int] NULL,
[ProjectId] [int] NOT NULL,
[CustomerId] [int] NOT NULL,
[UserId] [int] NOT NULL,
[TrackActionId] [int] NOT NULL,
CreateDate Datetime2 not null default getutcdate(),
FOREIGN KEY (TrackActionId) REFERENCES LuTrackingActions(TrackActionId),
FOREIGN KEY (Sectionid) REFERENCES ProjectSection(SectionId),
FOREIGN KEY (ProjectId) REFERENCES Project(ProjectId)
)