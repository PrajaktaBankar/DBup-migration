CREATE TABLE [dbo].[SegmentComment] (
    [SegmentCommentId]   INT             IDENTITY (1, 1) NOT NULL,
    [ProjectId]          INT             NOT NULL,
    [SectionId]          INT             NOT NULL,
    [SegmentStatusId]    BIGINT             NULL,
    [ParentCommentId]    INT             NULL,
    [CommentDescription] NVARCHAR (4000) NULL,
    [CustomerId]         INT             NOT NULL,
    [CreatedBy]          INT             NOT NULL,
    [CreateDate]         DATETIME2 (7)   NOT NULL,
    [ModifiedBy]         INT             NULL,
    [ModifiedDate]       DATETIME2 (7)   NULL,
    [CommentStatusId]    INT             DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT             DEFAULT ((0)) NOT NULL,
    [userFullName]       NVARCHAR (200)  NULL,
    [A_SegmentCommentId] INT             NULL
);




GO
CREATE NONCLUSTERED INDEX [IX_SegmentComment_ProjectId_SectionId_CreatedBy]
    ON [dbo].[SegmentComment]([ProjectId] ASC, [SectionId] ASC)
    INCLUDE([CreatedBy]) WITH (FILLFACTOR = 90);

