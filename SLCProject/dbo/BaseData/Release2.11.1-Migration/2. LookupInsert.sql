USE SLCProject
GO

insert into LuUnArchiveRequestStatus values('Queued','Queued')
GO
insert into LuUnArchiveRequestStatus values('Running','Running')
GO
insert into LuUnArchiveRequestStatus values('Completed','Completed')
GO
insert into LuUnArchiveRequestStatus values('Failed','Failed')
GO

insert into LuUnArchiveRequestType values('Active','Active')
GO
insert into LuUnArchiveRequestType values('Restore','Restore')
GO
insert into LuUnArchiveRequestType values('UnArchive','UnArchive')