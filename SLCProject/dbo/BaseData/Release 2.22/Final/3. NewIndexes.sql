USE SLCProject
GO

CREATE NONCLUSTERED INDEX [IX_ImportDocLibrary_CustomerId] ON [dbo].[ImportDocLibrary]([CustomerId] ASC)
INCLUDE([DocumentPath],[OriginalFileName]);
GO


CREATE NONCLUSTERED INDEX [IX_ImportDocLibrary_CustomerId] ON [dbo].[DocLibraryMapping] ([CustomerId] ASC, [ProjectId] ASC, [SectionId] ASC, [IsDeleted] ASC)
INCLUDE([DocLibraryId]);
GO

CREATE NONCLUSTERED INDEX [IX_ImportDocLibrary_DocLibraryId] ON [dbo].[DocLibraryMapping] ([CustomerId] ASC, [DocLibraryId] ASC);
GO

