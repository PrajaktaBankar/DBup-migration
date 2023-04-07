USE SLCProject

ALTER TABLE Project
ADD IsIncomingProject BIT 

ALTER TABLE Project
ADD TransferredDate DATETIME2 
