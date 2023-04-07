--User Story 30943: Project Archive: Archiving a project- UI Integration and API
use SLCProject
go

ALTER TABLE Project
ADD IsArchived BIT NOT NULL CONSTRAINT [DF__Projects__IsArchived] DEFAULT  ((0));
GO