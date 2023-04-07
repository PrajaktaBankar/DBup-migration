USE SLCProject 
GO
CREATE TABLE LuTrackChangesMode (
    TcModeId TINYINT IDENTITY (1, 1) PRIMARY KEY,
    TcModeName VARCHAR(100) NULL
);
go
INSERT INTO LuTrackChangesMode VALUES('Track Changes Off - None');
go
INSERT INTO LuTrackChangesMode VALUES('Track Changes Across All Sections');
go
INSERT INTO LuTrackChangesMode VALUES('Track Changes By Section');
go