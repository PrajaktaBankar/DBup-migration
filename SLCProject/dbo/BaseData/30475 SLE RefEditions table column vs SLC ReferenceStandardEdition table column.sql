/*
	server Name : SLCProject_SqlSlcOp001, SLCProject_SqlSlcOp002, SLCProject_SqlSlcOp003, SLCProject_SqlSlcOp004.

	Customer Support 30475: Tech: SLE RefEditions table column vs SLC ReferenceStandardEdition table column
*/

ALTER TABLE ReferenceStandardEdition ALTER COLUMN RefEdition nvarchar (255);
ALTER TABLE ReferenceStandardEdition ALTER COLUMN RefStdTitle nvarchar (1024);
ALTER TABLE ReferenceStandardEdition ALTER COLUMN LinkTarget nvarchar (1024);
