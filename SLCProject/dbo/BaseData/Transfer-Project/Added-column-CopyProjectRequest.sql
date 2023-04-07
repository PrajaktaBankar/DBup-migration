USE SLCProject


ALTER TABLE CopyProjectRequest
ADD CopyProjectTypeId int;

ALTER TABLE CopyProjectRequest
ADD TransferRequestId int;
