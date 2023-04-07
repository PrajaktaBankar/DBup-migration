/*
Execute on All Server.
Datatype Conversion from int to bigint of ChoiceOptionId and A_ChoiceOptionId column.
*/
USE [SLCProject]
GO

ALTER TABLE ProjectChoiceOption DROP CONSTRAINT [PK_PROJECTCHOICEOPTION]
GO
ALTER TABLE ProjectChoiceOption ALTER COLUMN ChoiceOptionId BIGINT
GO
ALTER TABLE ProjectChoiceOption ALTER COLUMN A_ChoiceOptionId BIGINT
GO
ALTER TABLE ProjectChoiceOption ADD CONSTRAINT [PK_PROJECTCHOICEOPTION] PRIMARY KEY (ChoiceOptionId);
GO